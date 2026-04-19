# 13proof — Document Quality Audit

Run the 13proof skill on the specified file: **$ARGUMENTS**

If no file was specified, ask the user which file to review.

## Instructions

1. First, read the skill file at `.claude/skills/proofread/SKILL.md` in this plugin's directory to load the full 6-stage pipeline instructions
2. Check for `.proofreadrc.yaml` in the current project root, then in `~/.proofreadrc.yaml`
3. Execute all 6 stages on the target file
4. Generate output in configured formats (default: markdown + JSON + HTML)
5. Save corrected document as `[name]_proofread.[ext]` alongside the original

If `.proofreadrc.yaml` is found, respect its settings for:
- `language`: force report language (default: auto-detect from document)
- `severity_threshold`: minimum severity to report (default: all)
- `ignore_categories`: list of MQM categories to skip
- `output_formats`: which report formats to generate
- `output_dir`: where to save reports (default: same as source file)
