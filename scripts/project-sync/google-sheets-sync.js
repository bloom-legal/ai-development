#!/usr/bin/env node

const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

async function main() {
  const args = process.argv.slice(2);

  if (args.length < 2) {
    console.error('Usage: node google-sheets-sync.js <config-path> <projects-json>');
    process.exit(1);
  }

  const configPath = args[0];
  const projectsJson = args[1];

  try {
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    const projects = JSON.parse(projectsJson);

    const auth = await authenticate(config);
    const spreadsheetId = await findOrCreateWorkbook(auth, config.workbookName, config.sheetName);
    await syncProjects(auth, spreadsheetId, config, projects);

    // Sync Stack sheet if configured
    if (config.stackSheetName) {
      await ensureSheet(auth, spreadsheetId, config.stackSheetName);
      await syncStack(auth, spreadsheetId, config, projects);
    }

    console.log(JSON.stringify({
      success: true,
      count: projects.length,
      spreadsheetId,
      sheetUrl: `https://docs.google.com/spreadsheets/d/${spreadsheetId}`
    }));
  } catch (error) {
    console.error(JSON.stringify({
      success: false,
      error: error.message
    }));
    process.exit(1);
  }
}

async function authenticate(config) {
  const credentials = JSON.parse(fs.readFileSync(config.credentialsPath, 'utf8'));
  const tokens = JSON.parse(fs.readFileSync(config.tokensPath, 'utf8'));

  const { client_id, client_secret } = credentials.installed;
  const oauth2Client = new google.auth.OAuth2(client_id, client_secret);
  oauth2Client.setCredentials(tokens);

  // Refresh token if needed
  try {
    await oauth2Client.getAccessToken();
  } catch (e) {
    throw new Error('OAuth tokens expired. Run: node /Users/joachimbrindeau/development/secrets/macos/google-auth.js');
  }

  return oauth2Client;
}

async function findOrCreateWorkbook(auth, workbookName, sheetName) {
  const drive = google.drive({ version: 'v3', auth });
  const sheets = google.sheets({ version: 'v4', auth });

  // Search for existing workbook by name (case-insensitive)
  const searchResult = await drive.files.list({
    q: `mimeType='application/vnd.google-apps.spreadsheet' and trashed=false`,
    fields: 'files(id, name)',
    spaces: 'drive'
  });

  let spreadsheetId = null;

  if (searchResult.data.files && searchResult.data.files.length > 0) {
    const match = searchResult.data.files.find(
      f => f.name.toLowerCase() === workbookName.toLowerCase()
    );
    if (match) {
      spreadsheetId = match.id;
    }
  }

  // Create workbook if not found
  if (!spreadsheetId) {
    const createResult = await sheets.spreadsheets.create({
      resource: {
        properties: { title: workbookName },
        sheets: [{
          properties: {
            title: sheetName,
            gridProperties: { frozenRowCount: 1 }
          }
        }]
      }
    });
    spreadsheetId = createResult.data.spreadsheetId;
  }

  // Ensure the sheet/tab exists within the workbook
  const metadata = await sheets.spreadsheets.get({
    spreadsheetId,
    fields: 'sheets.properties'
  });

  const existingSheet = metadata.data.sheets.find(
    s => s.properties.title.toLowerCase() === sheetName.toLowerCase()
  );

  if (!existingSheet) {
    // Add the sheet if it doesn't exist
    const addResult = await sheets.spreadsheets.batchUpdate({
      spreadsheetId,
      resource: {
        requests: [{
          addSheet: {
            properties: {
              title: sheetName,
              gridProperties: { frozenRowCount: 1 }
            }
          }
        }]
      }
    });
    const newSheetId = addResult.data.replies[0].addSheet.properties.sheetId;

    // Format header row
    await sheets.spreadsheets.batchUpdate({
      spreadsheetId,
      resource: {
        requests: [{
          repeatCell: {
            range: { sheetId: newSheetId, startRowIndex: 0, endRowIndex: 1 },
            cell: {
              userEnteredFormat: {
                backgroundColor: { red: 0.2, green: 0.4, blue: 0.8 },
                textFormat: { bold: true, foregroundColor: { red: 1, green: 1, blue: 1 } }
              }
            },
            fields: 'userEnteredFormat(backgroundColor,textFormat)'
          }
        }]
      }
    });
  }

  return spreadsheetId;
}

async function syncProjects(auth, spreadsheetId, config, projects) {
  const sheets = google.sheets({ version: 'v4', auth });
  const sheetTitle = config.sheetName;

  // Get existing data to find row numbers by name
  let existingData = [];
  try {
    const response = await sheets.spreadsheets.values.get({
      spreadsheetId,
      range: `'${sheetTitle}'!A:E`
    });
    existingData = response.data.values || [];
  } catch (e) {
    // Sheet might be empty, that's ok
  }

  // Build name -> row index map (1-indexed for Sheets API)
  const nameToRow = new Map();
  for (let i = 1; i < existingData.length; i++) {
    if (existingData[i] && existingData[i][0]) {
      nameToRow.set(existingData[i][0], i + 1);
    }
  }

  // Prepare header and data rows
  const headerRow = config.columns;
  const dataRows = projects.map(p => [
    p.name || '',
    p.description || '',
    Array.isArray(p.techStack) ? p.techStack.join(',') : (p.techStack || ''),
    p.lastUpdated || new Date().toISOString().split('T')[0],
    p.path || ''
  ]);

  // Build batch update requests
  const updates = [];

  // Always ensure header row
  updates.push({
    range: `'${sheetTitle}'!A1:E1`,
    values: [headerRow]
  });

  // Only add project rows if we have projects
  if (projects.length > 0) {
    let nextRow = existingData.length > 0 ? existingData.length + 1 : 2;

    for (let i = 0; i < projects.length; i++) {
      const project = projects[i];
      const rowData = dataRows[i];

      if (nameToRow.has(project.name)) {
        // Update existing row
        const rowNum = nameToRow.get(project.name);
        updates.push({
          range: `'${sheetTitle}'!A${rowNum}:E${rowNum}`,
          values: [rowData]
        });
      } else {
        // Append new row
        updates.push({
          range: `'${sheetTitle}'!A${nextRow}:E${nextRow}`,
          values: [rowData]
        });
        nextRow++;
      }
    }
  }

  // Execute batch update
  await sheets.spreadsheets.values.batchUpdate({
    spreadsheetId,
    resource: {
      valueInputOption: 'RAW',
      data: updates
    }
  });
}

async function ensureSheet(auth, spreadsheetId, sheetName) {
  const sheets = google.sheets({ version: 'v4', auth });

  const metadata = await sheets.spreadsheets.get({
    spreadsheetId,
    fields: 'sheets.properties'
  });

  const existingSheet = metadata.data.sheets.find(
    s => s.properties.title.toLowerCase() === sheetName.toLowerCase()
  );

  if (!existingSheet) {
    const addResult = await sheets.spreadsheets.batchUpdate({
      spreadsheetId,
      resource: {
        requests: [{
          addSheet: {
            properties: {
              title: sheetName,
              gridProperties: { frozenRowCount: 1 }
            }
          }
        }]
      }
    });
    const newSheetId = addResult.data.replies[0].addSheet.properties.sheetId;

    await sheets.spreadsheets.batchUpdate({
      spreadsheetId,
      resource: {
        requests: [{
          repeatCell: {
            range: { sheetId: newSheetId, startRowIndex: 0, endRowIndex: 1 },
            cell: {
              userEnteredFormat: {
                backgroundColor: { red: 0.2, green: 0.4, blue: 0.8 },
                textFormat: { bold: true, foregroundColor: { red: 1, green: 1, blue: 1 } }
              }
            },
            fields: 'userEnteredFormat(backgroundColor,textFormat)'
          }
        }]
      }
    });
  }
}

async function syncStack(auth, spreadsheetId, config, projects) {
  const sheets = google.sheets({ version: 'v4', auth });
  const sheetTitle = config.stackSheetName;

  // Build deduplicated tech stack map
  // Key: normalized library name, Value: { projects[] }
  const techMap = new Map();

  for (const project of projects) {
    if (!project.techStack || !Array.isArray(project.techStack)) continue;

    for (const tech of project.techStack) {
      const library = tech.trim();
      const key = library.toLowerCase();

      if (techMap.has(key)) {
        const entry = techMap.get(key);
        if (!entry.projects.includes(project.name)) {
          entry.projects.push(project.name);
        }
      } else {
        techMap.set(key, {
          library: library,
          projects: [project.name]
        });
      }
    }
  }

  // Convert to rows sorted by count (desc) then name (asc)
  const rows = Array.from(techMap.values())
    .sort((a, b) => {
      if (b.projects.length !== a.projects.length) {
        return b.projects.length - a.projects.length;
      }
      return a.library.localeCompare(b.library);
    })
    .map(entry => [
      entry.library,
      entry.projects.join(','),
      entry.projects.length
    ]);

  // Clear existing data and write new
  const headerRow = config.stackColumns || ['library', 'projects', 'count'];

  // Clear the sheet first
  await sheets.spreadsheets.values.clear({
    spreadsheetId,
    range: `'${sheetTitle}'!A:C`
  });

  // Write header + data
  const allRows = [headerRow, ...rows];
  await sheets.spreadsheets.values.update({
    spreadsheetId,
    range: `'${sheetTitle}'!A1`,
    valueInputOption: 'RAW',
    resource: { values: allRows }
  });
}

main();
