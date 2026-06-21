# Claude Code Game Studios -- Game Studio Agent Architecture

Indie game development managed through 49 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: [CHOOSE: Godot 4 / Unity / Unreal Engine 5]
- **Language**: [CHOOSE: GDScript / C# / C++ / Blueprint]
- **Version Control**: Git with trunk-based development
- **Build System**: [SPECIFY after choosing engine]
- **Asset Pipeline**: [SPECIFY after choosing engine]

> **Note**: Engine-specialist agents exist for Godot, Unity, and Unreal with
> dedicated sub-specialists. Use the set matching your engine.

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

@docs/engine-reference/godot/VERSION.md

## Technical Preferences

@.claude/docs/technical-preferences.md

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**Human-in-the-loop on creative judgment; automated verification on technical work.**
The boundary is set by *what the work is*, not by which agent does it. The studio runs
autonomously on technical work and pauses for the human only on taste and judgment.

### Creative & judgment work → Human-in-the-loop (unchanged)

For **creative / design / taste / judgment** artifacts, every task follows
**Question → Options → Decision → Draft → Approval**:

- Paths: `design/**`, ADR *rationale/alternatives* content, art bibles, asset specs,
  UX specs, narrative/lore, game pillars, and any verdict of quality/fun/vision
  (PROCEED·PIVOT·KILL, go/no-go, "feels good", fairness, scope cuts).
- Agents MUST ask "May I write this to [filepath]?" before Write/Edit on these paths.
- Agents MUST show drafts/options before requesting approval.
- The human owns the decision; agents recommend.

### Technical work → Autonomous, governed by automated checks (no human gate)

For **code / tests / config / data / mechanical reports / commits**, agents proceed
**without** asking, governed by automated checks instead of a human turn:

- Paths: `src/**`, `tests/**`, `tools/**`, `assets/data/**`, `*.json`, generated reports,
  status/registry updates.
- The write/commit is licensed by: rules in `.claude/rules/**` + BLOCKING unit tests +
  `/story-done` acceptance-criteria check + the blocking linter/static-analysis gate +
  CI test gate — **not** by a "May I write?" turn.
- **Verification is never dropped.** Removing the human gate only ever replaces it with an
  automated check at the *same* blocking level. Never use `solo`/`lean` review mode to skip
  a verification gate — convert the verdict to objective pass/fail and block on it instead.
- Commits are allowed once verification passes; messages use Conventional Commits + a
  `Story:`/task-ID reference. Production deploy keeps one human authorization (irreversible).

When a single change spans both (e.g., a GDD edit that drives code), the **creative** portion
takes the human-in-the-loop path and the **technical** portion follows the automated path.

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for the full protocol, the artifact-type table,
and examples.

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md
