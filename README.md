# Sawmills Skills

Public agent skills for Sawmills workflows.

This repo is the canonical public source for skills that are useful outside a
single app repository. App-specific code and release artifacts should link here
instead of vendoring skill copies.

## Included Skills

- `customer-knowledge-curation`: use customer knowledge to build or maintain
  early-detection coverage.

## Install

```sh
npx skills add Sawmills/skills -y
```

Install only one skill:

```sh
npx skills add Sawmills/skills/customer-knowledge-curation -y
```

## Layout

```text
skills/
  customer-knowledge-curation/
    SKILL.md
    references/
scripts/
  validate-skills
```

## Validate

Run this after edits:

```sh
scripts/validate-skills
ruby scripts/validate-skills.test.rb
```

The validator checks skill layout, frontmatter, required fields, and common
public-repo privacy hazards.
