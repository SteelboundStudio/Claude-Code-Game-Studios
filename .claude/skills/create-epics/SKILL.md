---
name: create-epics
description: "Translate approved GDDs + architecture into epics — one epic per architectural module. Defines scope, governing ADRs, engine risk, and untraced requirements. Does NOT break into stories — run /create-stories [epic-slug] after each epic is created."
argument-hint: "[system-name | layer: foundation|core|feature|presentation | all] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
model: sonnet
agent: technical-director
---

# Create Epics

An epic is a named, bounded body of work that maps to one architectural module.
It defines **what** needs to be built and **who owns it architecturally**. It
does not prescribe implementation steps — that is the job of stories.

**Run this skill once per layer** as you approach that layer in development.
Do not create Feature layer epics until Core is nearly complete — the design
will have changed.

**Output:** `production/epics/[epic-slug]/EPIC.md` + `production/epics/index.md`

**Next step after each epic:** `/create-stories [epic-slug]`

**When to run:** After `/create-control-manifest` and `/architecture-review` pass.

---

## 1. Parse Arguments

Resolve the review mode (once, store for all gate spawns this run):
1. If `--review [full|lean|solo]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

See `.claude/docs/director-gates.md` for the full check pattern.

**Modes:**
- `/create-epics all` — process all systems in layer order
- `/create-epics layer: foundation` — Foundation layer only
- `/create-epics layer: core` — Core layer only
- `/create-epics layer: feature` — Feature layer only
- `/create-epics layer: presentation` — Presentation layer only
- `/create-epics [system-name]` — one specific system
- No argument — ask: "Which layer or system would you like to create epics for?"

---

## 2. Load Inputs

### Step 2a — Summary scan (fast)

Grep all GDDs for their `## Summary` sections before reading anything fully:

```
Grep pattern="## Summary" glob="design/gdd/*.md" output_mode="content" -A 5
```

For `layer:` or `[system-name]` modes: filter to only in-scope GDDs based on
the Summary quick-reference. Skip full-reading anything out of scope.

### Step 2b — Full document load (in-scope systems only)

Using the Step 2a grep results, identify which systems are in scope. Read full documents **only for in-scope systems** — do not read GDDs or ADRs for out-of-scope systems or layers.

Read for in-scope systems:

- `design/gdd/systems-index.md` — authoritative system list, layers, priority
- In-scope GDDs only (Approved or Designed status, filtered by Step 2a results)
- `docs/architecture/architecture.md` — module ownership and API boundaries
- Accepted ADRs **whose domains cover in-scope systems only** — read the "GDD Requirements Addressed", "Decision", and "Engine Compatibility" sections; skip ADRs for unrelated domains
- `docs/architecture/control-manifest.md` — manifest version date from header
- `docs/architecture/tr-registry.yaml` — for tracing requirements to ADR coverage
- `docs/engine-reference/[engine]/VERSION.md` — engine name, version, risk levels

Report: "Loaded [N] GDDs, [M] ADRs, engine: [name + version]."

---

## 3. Processing Order

Process in dependency-safe layer order:
1. **Foundation** (no dependencies)
2. **Core** (depends on Foundation)
3. **Feature** (depends on Core)
4. **Presentation** (depends on Feature + Core)

Within each layer, use the order from `systems-index.md`.

---

## 4. Define Each Epic

For each system, map it to an architectural module from `architecture.md`.

Check ADR coverage against the TR registry:
- **Traced requirements**: TR-IDs that have an Accepted ADR covering them
- **Untraced requirements**: TR-IDs with no ADR — warn before proceeding

Present to user before writing anything:

```
## Epic: [System Name]

**Layer**: [Foundation / Core / Feature / Presentation]
**GDD**: design/gdd/[filename].md
**Architecture Module**: [module name from architecture.md]
**Governing ADRs**: [ADR-NNNN, ADR-MMMM]
**Engine Risk**: [LOW / MEDIUM / HIGH — highest risk among governing ADRs]
**GDD Requirements Covered by ADRs**: [N / total]
**Untraced Requirements**: [list TR-IDs with no ADR, or "None"]
```

If there are untraced requirements, auto-warn and proceed with placeholders
(traceability check: TR-ID → ADR) — do not pause:
> "⚠️ [N] requirements in [system] have no ADR. The epic is created with placeholder
> entries; stories for these requirements will be marked Blocked until ADRs exist.
> Run `/architecture-decision` to fill the gaps."

**Block only on zero coverage**: if NO requirement in the system has any ADR coverage,
stop and report — the epic cannot be meaningfully defined yet:
> "BLOCKED: [system] has zero ADR coverage. Run `/architecture-decision` before creating
> this epic." Then skip this epic.

Otherwise the epic is created automatically (partial coverage is the documented placeholder path).

---

## 4b. Producer Epic Structure Gate

**Review mode check** — apply before spawning PR-EPIC:
- `solo` → skip. Note: "PR-EPIC skipped — Solo mode." Proceed to Step 5 (write epic files).
- `lean` → skip (not a PHASE-GATE). Note: "PR-EPIC skipped — Lean mode." Proceed to Step 5 (write epic files).
- `full` → spawn as normal.

After all epics for the current layer are defined (Step 4 completed for all in-scope systems), and before writing any files, spawn `producer` via Task using gate **PR-EPIC** (`.claude/docs/director-gates.md`).

Pass: the full epic structure summary (all epics, their scope summaries, governing ADR counts), the layer being processed, milestone timeline and team capacity.

Present the producer's assessment.

If UNREALISTIC: offer to revise epic boundaries (split overscoped or merge underscoped epics). Revise and re-run the gate before writing.

If CONCERNS (epic-size heuristic + module-boundary check): if every epic's scope metrics
are in-band (epic size within the heuristic range, module boundaries align 1:1 with
architecture modules), auto-accept and proceed to Step 5, noting the producer's concerns
inline. Only surface via `AskUserQuestion` when the concern is a genuine scope-judgment
call (an epic the metrics flag as over/under-scoped that needs a human decision to split,
merge, or accept):
- Prompt: "Producer raised a scope-judgment concern about the epic structure. How do you want to proceed?"
- Options:
  - `[A] Proceed as planned — I accept the producer's concerns`
  - `[B] Revise epic boundaries — split or merge as recommended`
  - `[C] Stop — I want to reconsider the scope`

If [A]: proceed to Step 5.
If [B]: revise epic definitions from Step 4 and re-run the producer gate.
If [C]: stop. Verdict: **BLOCKED** — user wants to reconsider epic scope.

Do not write epic files until the producer gate resolves.

---

## 5. Write Epic Files

Auto-write each epic file to `production/epics/[epic-slug]/EPIC.md` (epic-template schema
check — one epic per module, derived from architecture). The epic content is derived from
the GDDs, ADRs, and architecture docs, so the write is mechanical; no write-approval
keystroke needed.

Write:

### `production/epics/[epic-slug]/EPIC.md`

```markdown
# Epic: [System Name]

> **Layer**: [Foundation / Core / Feature / Presentation]
> **GDD**: design/gdd/[filename].md
> **Architecture Module**: [module name]
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories [epic-slug]`

## Overview

[1 paragraph describing what this epic implements, derived from the GDD Overview
and the architecture module's stated responsibilities]

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-NNNN: [title] | [1-line summary] | LOW/MEDIUM/HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-[system]-001 | [requirement text from registry] | ADR-NNNN ✅ |
| TR-[system]-002 | [requirement text] | ❌ No ADR |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/[filename].md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories [epic-slug]` to break this epic into implementable stories.
```

### Update `production/epics/index.md`

Create or update the master index:

```markdown
# Epics Index

Last Updated: [date]
Engine: [name + version]

| Epic | Layer | System | GDD | Stories | Status |
|------|-------|--------|-----|---------|--------|
| [name] | Foundation | [system] | [file] | Not yet created | Ready |
```

---

## 6. Gate-Check Reminder

After writing all epics for the requested scope:

- **Foundation + Core complete**: These are required for the Pre-Production →
  Production gate. Run `/gate-check production` to check readiness.
- **Reminder**: Epics define scope. Stories define implementation steps. Run
  `/create-stories [epic-slug]` for each epic before developers can pick up work.

---

## Collaborative Protocol

1. **One epic at a time** — present each epic definition before writing it
2. **Warn on gaps** — auto-warn on untraced requirements and proceed with placeholders;
   block only on zero ADR coverage (traceability check)
3. **Auto-write derived epics** — the epic file is derived from GDDs, ADRs, and
   architecture docs, so the write is mechanical and automatic (epic-template schema check)
4. **No invention** — all content comes from GDDs, ADRs, and architecture docs
5. **Never create stories** — this skill stops at the epic level

After all requested epics are processed:

- **Verdict: COMPLETE** — [N] epic(s) written. Run `/create-stories [epic-slug]` per epic.
- **Verdict: BLOCKED** — no eligible systems found, or all in-scope systems have zero ADR coverage.
