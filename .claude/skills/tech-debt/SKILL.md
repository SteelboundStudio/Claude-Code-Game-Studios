---
name: tech-debt
description: "Track, categorize, and prioritize technical debt across the codebase. Scans for debt indicators, maintains a debt register, and recommends repayment scheduling."
argument-hint: "[scan|add|prioritize|report]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion
model: sonnet
---

## Phase 1: Parse Subcommand

Determine the mode from the argument:

- `scan` — Scan the codebase for tech debt indicators
- `add` — Add a new tech debt entry manually
- `prioritize` — Re-prioritize the existing debt register
- `report` — Generate a summary report of current debt status

If no subcommand is provided, output usage and stop. Verdict: **FAIL** — missing required subcommand.

---

## Phase 2A: Scan Mode

Search the codebase for debt indicators:

- `TODO` comments (count and categorize)
- `FIXME` comments (these are bugs disguised as debt)
- `HACK` comments (workarounds that need proper solutions)
- `@deprecated` markers
- Duplicated code blocks (similar patterns in multiple files)
- Files over 500 lines (potential god objects)
- Functions over 50 lines (potential complexity)

Categorize each finding:

- **Architecture Debt**: Wrong abstractions, missing patterns, coupling issues
- **Code Quality Debt**: Duplication, complexity, naming, missing types
- **Test Debt**: Missing tests, flaky tests, untested edge cases
- **Documentation Debt**: Missing docs, outdated docs, undocumented APIs
- **Dependency Debt**: Outdated packages, deprecated APIs, version conflicts
- **Performance Debt**: Known slow paths, unoptimized queries, memory issues

Present the findings to the user, then auto-write them to
`docs/tech-debt-register.md` — the findings are grep-derived (TODO/FIXME/HACK,
file/function size) and categorized from a fixed taxonomy, so no approval gate is
required. Append new entries; do not overwrite existing ones. (Replacement check:
append-only — existing entries preserved; categories drawn from the fixed taxonomy.)
Verdict: **COMPLETE** — scan findings written to register.

---

## Phase 2B: Add Mode

If invoked with a description argument, auto-classify the **category** from
keywords in the description and **infer the effort** from the file scope (number
and size of affected files), rather than prompting. Map to:
- Category taxonomy: Architecture / Code Quality / Test / Documentation /
  Dependency / Performance Debt (keyword-matched).
- Effort: S (under 1 day) / M (1–3 days) / L (3–7 days) / XL (over 1 week)
  (inferred from file scope).

Present the auto-classified entry and allow a human override of the category or
effort if the user disagrees (override is optional, not a blocking gate). If no
description was provided, ask for description, affected files, and impact (plain
text prompts) before classifying.

Auto-append the entry to `docs/tech-debt-register.md`. (Replacement check: the
entry has category + effort + impact fields; manual override allowed.) Verdict:
**COMPLETE** — entry added to register.

---

## Phase 2C: Prioritize Mode

Read the debt register at `docs/tech-debt-register.md`.

Score each item by: `(impact_if_unfixed × frequency_of_encounter) / fix_effort`

Re-sort the register by priority score and recommend which items to include in the next sprint.

Present the re-prioritized register to the user, then auto-write it back to
`docs/tech-debt-register.md` — priority is the deterministic formula
`(impact × frequency) / effort`, so no approval gate is required. (Replacement
check: the re-sorted register matches the computed scores.) Verdict: **COMPLETE**
— register re-prioritized and saved.

---

## Phase 2D: Report Mode

Read the debt register. Generate summary statistics:

- Total items by category
- Total estimated fix effort
- Items added vs resolved since last report
- Trending direction (growing / stable / shrinking)

Flag any items that have been in the register for more than 3 sprints.

Output the report to the user. This mode is read-only — no files are written. Verdict: **COMPLETE** — debt report generated.

---

## Phase 3: Next Steps

- Run `/sprint-plan` to schedule high-priority debt items into the next sprint.
- Run `/tech-debt report` at the start of each sprint to track debt trends over time.

### Debt Register Format

```markdown
## Technical Debt Register
Last updated: [Date]
Total items: [N] | Estimated total effort: [T-shirt sizes summed]

| ID | Category | Description | Files | Effort | Impact | Priority | Added | Sprint |
|----|----------|-------------|-------|--------|--------|----------|-------|--------|
| TD-001 | [Cat] | [Description] | [files] | [S/M/L/XL] | [Low/Med/High/Critical] | [Score] | [Date] | [Sprint to fix or "Backlog"] |
```

### Rules
- Tech debt is not inherently bad — it is a tool. The register tracks conscious decisions.
- Every debt entry must explain WHY it was accepted (deadline, prototype, missing info)
- "Scan" should run at least once per sprint to catch new debt
- Items older than 3 sprints without action should either be fixed or consciously accepted with a documented reason
