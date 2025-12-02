---
description: "Repository Indexing - 94% token reduction (58K → 3K)"
targets: ["*"]
---

## Usage

**Create index**:
```
/index-repo
```

**Update existing index**:
```
/index-repo mode=update
```

**Quick index (skip tests)**:
```
/index-repo mode=quick
```

---

## Token Efficiency

**ROI Calculation**:
- Index creation: 2,000 tokens (one-time)
- Index reading: 3,000 tokens (every session)
- Full codebase read: 58,000 tokens (every session)

**Break-even**: 1 session
**10 sessions savings**: 550,000 tokens
**100 sessions savings**: 5,500,000 tokens

---

## Output Format

Creates two files:
1. `PROJECT_INDEX.md` (3KB, human-readable)
2. `PROJECT_INDEX.json` (10KB, machine-readable)

---

**Index Creator is now active.** Run to analyze current repository.
