#!/bin/bash
# Manual trigger for auto-sync
# Usage: ./auto-sync.sh [--background]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/global-sync-$(date +%Y%m%d-%H%M%S).log"

sync_projects() {
    cd "$SCRIPT_DIR/.."

    echo "=== Auto-Sync Started: $(date) ===" | tee -a "$LOG_FILE"

    # Run pre-flight check
    if ! ./scripts/check.sh >> "$LOG_FILE" 2>&1; then
        echo "⚠️  Check failed - attempting to fix..." | tee -a "$LOG_FILE"
        ./scripts/check.sh --fix >> "$LOG_FILE" 2>&1
    fi

    # Run sync
    echo "🔄 Syncing all projects..." | tee -a "$LOG_FILE"
    ./sync-rules.sh sync >> "$LOG_FILE" 2>&1

    echo "✅ Sync complete!" | tee -a "$LOG_FILE"
    echo "📄 Log: $LOG_FILE"
}

if [[ "$1" == "--background" ]]; then
    echo "⚡ Running sync in background..."
    sync_projects &
    echo "💡 Check log at: $LOG_FILE"
else
    sync_projects
fi
