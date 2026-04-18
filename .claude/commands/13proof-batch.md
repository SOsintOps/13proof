# Proofreader Audit — Batch Mode

Run the 13proof on all markdown files in the current project.

## Instructions

1. Read the skill at `.claude/skills/proofread/SKILL.md` for the full pipeline
2. Find all `.md` files in the project (exclude `node_modules/`, `.git/`, `_proofread.md`, `_audit_report.md`)
3. List the files found and ask the user to confirm
4. For each file, execute the 6-stage audit pipeline
5. After all files are processed, generate a **summary report** (`batch_audit_summary.md`) with:
   - Per-file scores
   - Total findings by severity
   - Overall project documentation health score
   - Top 5 most common issues across all files

Arguments: **$ARGUMENTS**

If arguments contain a path, use that as the root directory instead of the project root.
