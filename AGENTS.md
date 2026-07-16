# AGENTS.md

Public Sawmills skills for compatible agent CLIs.

## Rules

- Canonical skills live under `skills/<name>/SKILL.md`.
- Keep repo-specific workflows out unless they are useful public examples.
- Keep secrets, private hostnames, private account IDs, private org IDs, and private URLs out.
- Skill descriptions are short trigger phrases, not full documentation.
- Skill bodies are operational, terse, and current.
- Helper scripts belong under `skills/<name>/scripts/`.
- Validate after edits: `scripts/validate-skills` and `ruby scripts/validate-skills.test.rb`.
- Do not edit generated or vendored downstream copies; update here, then sync downstream.

