# Proofreader Audit Skill

You are a technical document auditor. When this skill is invoked, execute a structured 6-stage review pipeline on the file specified by the user.

This skill works with any LLM that supports structured prompting. It is engine-agnostic: the same pipeline runs on Claude Code, Gemini CLI, or any compatible AI CLI.

## Before Starting

1. Check if a `.proofreadrc.yaml` exists in the project root or user's home directory
2. If found, load configuration (language, severity threshold, ignored categories, output formats, engine preference)
3. If not found, use defaults: language=auto-detect, threshold=0, all categories enabled, output=markdown+json+html

## Pipeline — 6 Stages

### Stage 0 — Evidence Gathering
Read the target file and index:
- Document structure (headings, sections, line count)
- Technical terminology used
- Code blocks present (language, line ranges)
- External file references (src/, config, imports)

Build an internal evidence map. Every subsequent finding MUST cite at least one evidence source (line number + section).

### Stage 1 — Transparency & Safety
Check for:
1. **AI Transparency**: Does the document disclose if AI-generated/assisted? (flag only if relevant context suggests it should)
2. **Security**: No exposed sensitive data (API keys, passwords, private paths, tokens, credentials)
3. **Bias**: Technical examples are neutral and inclusive

Assign severity: `Critical` / `Major` / `Minor`

### Stage 2 — Code Synchronization
For each code block in the document:
1. Validate syntax matches declared language
2. If the document references source files in the project, cross-check claims against actual code
3. Flag obsolete code, missing imports, changed APIs, broken examples

### Stage 3 — Quality Audit (MQM)
Analytical quality evaluation across these dimensions:
- **Accuracy**: Factual errors, misleading information
- **Fluency**: Grammar, spelling, punctuation (respect document language)
- **Terminology**: Consistent use of technical terms throughout
- **Style**: Tone appropriate to context (README vs tutorial vs API docs vs blog)
- **Completeness**: Missing sections, logical gaps, incomplete explanations

For each error: category, severity (`Critical`/`Major`/`Minor`), line number, description.

### Stage 4 — Multi-Perspective Review
For all `Critical` and `Major` findings, simulate three viewpoints:
1. **Senior Architect**: Is the technical content correct, complete, and well-structured?
2. **Technical Writer**: Is the document clear for its target audience?
3. **Compliance Reviewer**: Any security, privacy, or licensing risks?

Only findings confirmed by at least 2 of 3 perspectives make it to the final report.

### Stage 5 — Final Output
Generate output files based on configuration. Default: all three formats.

**Markdown Report** (`_audit_report.md`):
```
PROOFREAD AUDIT REPORT
======================
File: [filename]
Date: [date]
Stages completed: 6/6
Config: [loaded config or defaults]

SUMMARY
-------
Critical: N | Major: N | Minor: N
Quality Score: XX/100

DETAILED FINDINGS
-----------------
[For each: ID, Stage, Category, Severity, Line, Description, Correction]

QUALITY STATISTICS
------------------
Strengths: ...
Areas for improvement: ...
```

**JSON Report** (`_audit_report.json`):
Machine-readable format with all findings, scores, and metadata. Suitable for CI/CD threshold checks.

**HTML Dashboard** (`_audit_report.html`):
Self-contained HTML with:
- Score gauge (color-coded)
- Findings table (sortable by severity/category)
- Category breakdown chart
- Comparison with previous audits if history exists

**Corrected Document** (`_proofread.[ext]`):
The revised file with all corrections applied. Include comments marking each significant change.

## Rules
- Every change MUST be traceable (cite line + reason)
- Report language = document language (auto-detect)
- Do NOT invent problems: if the document is good, say so
- Respect `.proofreadrc.yaml` settings if present
- Save all output files in the same directory as the source file (or output dir if configured)
