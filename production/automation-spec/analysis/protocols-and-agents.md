# HITL Source Analysis — Global Protocols & Agent Definitions

**Scope:** Highest-leverage sources of human-in-the-loop (HITL) gating that apply globally across all agents/skills.
**Owner axis:** KEEP humans for CREATIVE / TASTE / JUDGMENT. AUTOMATE everything purely TECHNICAL / MECHANICAL / VERIFICATION / COORDINATION. "Automate" = replace the human gate with an automated check — **never drop verification.**

---

## Two HITL Layers (read this first)

The gating splits into two distinct mechanisms. Do not conflate them — the fix is different for each.

- **Layer 1 — Blanket, unconditional.** `CLAUDE.md` Collaboration Protocol + the 3 protocol templates' "Get approval before writing files" + the per-agent copies of those templates. Fires on **every** Write/Edit/commit. **No dial exists.** This is where the leverage is.
- **Layer 2 — Conditional, already half-automated.** `director-gates.md`. Already has `production/review-mode.txt` (`full`/`lean`/`solo`) and returns `APPROVE`/`CONCERNS`/`REJECT`. The only human touchpoint is **verdict handling** (`CONCERNS` → `AskUserQuestion` to the user), not the check itself.

**Key consequence:** Layer 2 is the *replacement mechanism* for Layer 1, not a thing to gut. AUTOMATE recommendations for Layer 1 point **at** Layer 2 + tests + `/story-done` + CI. Layer 2's own gates split: VERIFICATION gates → make the verdict auto-blocking (fail = block, no human); CREATIVE gates → keep the human in the verdict loop.

A verification that drops from **BLOCKING** to **ADVISORY** (per `coding-standards.md`) *is* dropping verification. Every AUTOMATE row preserves the existing blocking level.

---

## Global Switches (highest leverage)

| Source (file:section) | Gate quote | Gate Type | Recommendation | Exact edit | Replacement Check |
|---|---|---|---|---|---|
| `CLAUDE.md` › ## Collaboration Protocol (intro) | "These instructions OVERRIDE any default behavior… Every task follows: Question → Options → Decision → Draft → Approval" | MIXED (blanket override) | **HYBRID — scope by artifact type** | Replace the unconditional override with an artifact-typed rule: creative/design docs (`design/**`, `docs/architecture/**` ADR *content*) keep Question→…→Approval; code/tests/config/commits (`src/**`, `tests/**`, `assets/data/**`, `*.json`) governed by rules + tests + `/story-done` + CI instead. | Per-type: design = HITL; code = gameplay-code rules/hooks + BLOCKING unit tests + `/story-done` AC check + LP-CODE-REVIEW + CI test gate |
| `CLAUDE.md` › ## Collaboration Protocol | "Agents MUST ask 'May I write this to [filepath]?' before using Write/Edit tools" | MECHANICAL (for code) / JUDGMENT (for design) | **HYBRID** | Narrow "MUST ask" to creative-doc paths only. For code/test/config paths, remove the ask; gate on automated checks instead. | Code: rule/hook pass + tests green + `/story-done`. Design docs: keep the ask. |
| `CLAUDE.md` › ## Collaboration Protocol | "Multi-file changes require explicit approval for the full changeset" | COORDINATION | **AUTOMATE** | Drop explicit-approval requirement for code changesets; replace with atomic-commit + CI gate. Keep for cross-GDD design changesets (`propagate-design-change` already coordinates those). | CI test suite on PR/push (coding-standards.md CI/CD rules) + `/story-done` + LP-CODE-REVIEW |
| `CLAUDE.md` › ## Collaboration Protocol | "No commits without user instruction" | MECHANICAL | **AUTOMATE** | Remove blanket commit prohibition; allow commits once verification passes. | Conventional-commit format check + story-ID-in-body check + CI green (all already mandated in `coding-standards.md`) |
| `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` › 📄 File Writing Protocol | "NEVER Write Files Without Explicit Approval… Explicitly ask: 'May I write this to [filepath]?' … Wait for 'yes'" | MECHANICAL (code) / JUDGMENT (design) | **HYBRID** | Same artifact-type split. This doc is the long-form source CLAUDE.md links to; edit both together so they don't drift. | Same as CLAUDE.md rows |
| `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` › 💻 Coding Tasks ("WRONG/RIGHT") | "Implemented and committed" listed as ❌ WRONG autonomous behavior | VERIFICATION/MECHANICAL | **AUTOMATE** | Reframe the "RIGHT" coding example so verification (tests + rules + `/story-done`), not a human approval turn, is what licenses the write/commit. | gameplay-code rule + BLOCKING unit test + `/story-done` |
| `.claude/docs/review-workflow.md` (entire file) | "Code changes require review by the relevant department lead agent" | VERIFICATION (technical) | **AUTOMATE** | Keep the review, remove the human as the *gate*: lead review runs as an automated `LP-CODE-REVIEW` Task whose REJECT auto-blocks merge. | `LP-CODE-REVIEW` (Layer 2) auto-blocking + CI |
| `.claude/docs/review-workflow.md` | "Design changes require sign-off from game-designer and creative-director" | CREATIVE | **KEEP-HITL** | No change. | n/a — taste call |
| `.claude/docs/review-workflow.md` | "Architecture changes require sign-off from technical-director" | JUDGMENT (technical) | **HYBRID** | Keep human for novel/cross-cutting ADRs; auto-run `TD-ADR` for routine ones and let APPROVE proceed without a human turn. | `TD-ADR` + `/architecture-review` traceability |
| `.claude/docs/review-workflow.md` | "Cross-domain changes require sign-off from producer" | COORDINATION | **AUTOMATE** | Replace producer sign-off with automated coordination skill output; escalate to human only on conflict. | `propagate-design-change` impact report + `producer` Task (advisory) |
| `.claude/docs/director-gates.md` › Standard Verdict Format | "CONCERNS → Surface to user via AskUserQuestion" | depends on gate | **HYBRID** | Split verdict handling by gate prefix: `QL-*`/`TD-ENGINE-RISK`/`LP-CODE-REVIEW` CONCERNS+REJECT auto-block (no human); `CD-*`/`AD-*`/`PR-*` keep surfacing to user. | Auto-block for verification gates; keep HITL for creative/strategic |
| `.claude/docs/director-gates.md` › Review Modes | `review-mode.txt` = full/lean/solo (Layer 2 dial) | n/a (this is the dial) | **KEEP — extend** | Do NOT remove. This is the model for what Layer 1 lacks. Optionally add a fourth axis or document that `solo` = full automation path. | n/a — already the replacement infrastructure |

---

## Per-Protocol Analysis (the 3 templates)

Path: `.claude/docs/templates/collaborative-protocols/`

### 1. `design-agent-protocol.md` → CREATIVE/TASTE → **KEEP-HITL**

- **What it gates:** Question-first design, 2–4 options with theory reasoning, iterative section drafting, "May I write this to [filepath]?" before file writes.
- **Carried by:** `game-designer`, `art-director` (and design-class specialists: systems-designer, level-designer, economy-designer, writer, etc.).
- **Recommendation:** KEEP-HITL. These gates are pure taste/vision — the owner explicitly wants humans here. The "May I write" is genuinely a creative checkpoint because the *content* is a creative artifact.
- **Exact edits:** None to the creative core. Only edit: the file-write approval may stay, but ensure it is NOT counted as a "blanket Layer 1 override" — it is in-scope HITL by design here.

### 2. `implementation-agent-protocol.md` → TECHNICAL → **AUTOMATE (with one HYBRID step)**

- **What it gates:** (step 2–3) architecture questions + propose-architecture-before-implementing; (step 5) "May I write this to [filepath(s)]?"; (step 6) `/story-done` to close.
- **Carried by:** `gameplay-programmer`, `lead-programmer`, `qa-lead`, and all programmer specialists (engine-, ai-, network-, tools-, ui-programmer).
- **Recommendation:** AUTOMATE the file-write approval (step 5) and reframe completion around verification, not a human turn. **HYBRID** for steps 2–3.
- **Exact edits:**
  - **Step 5** ("Get approval before writing files… Wait for 'yes'"): remove the human gate. Replace with: write proceeds when gameplay-code rules/hooks pass + BLOCKING unit tests green. Keep the *summary* output for transparency, drop the *wait*.
  - **Steps 2–3** (architecture questions like "static utility vs singleton", "where should data live"): HYBRID. Mechanical forks already answered by `control-manifest.md` → follow it automatically, no human. Genuine novel forks → route to `TD-ADR` (Layer 2), not a blanket human gate.
  - **Step 6** (`/story-done`): KEEP and make mandatory — this is the *automated* AC-verification replacement, not a human gate. It already verifies acceptance criteria, checks GDD/ADR deviations, prompts code review, updates status.
- **Replacement checks:** gameplay-code rules + BLOCKING unit tests (coding-standards.md) + `/story-done` AC verification + `LP-CODE-REVIEW` + CI test gate.

### 3. `leadership-agent-protocol.md` → MIXED → **HYBRID (split by decision content)**

- **What it gates:** Strategic decision workflow (understand context → frame → 2–3 options → recommend → "But this is your call" → "May I proceed with documentation?").
- **Carried by:** `creative-director`, `technical-director`, `producer` (all three carry this identical protocol — confirmed verbatim).
- **Recommendation:** HYBRID — classify by the *content* of each decision, not the protocol label.
  - **Vision / pillar / creative-scope tradeoffs** (creative-director's domain; "which pillar wins", "does this serve the fantasy") → KEEP-HITL.
  - **Production coordination** (producer's domain; scheduling, dependency ordering, cross-domain propagation) → AUTOMATE; escalate to human only on genuine conflict.
  - **Technical architecture** (technical-director's domain) → HYBRID; routine → `TD-ADR`/`TD-ARCHITECTURE` auto, novel → human.
- **Exact edits:**
  - Keep the full Strategic Decision Workflow for `creative-director`.
  - For `producer`: downgrade "May I proceed with documentation?" + sign-off turns to advisory; let coordination skills (`propagate-design-change`, `sprint-plan`) produce the artifact and proceed unless conflict detected.
  - For `technical-director`: tie its decisions to `TD-ADR` / `/architecture-review`; APPROVE verdict proceeds without a human turn.

---

## Agent Classification

**Note: gate type ≠ protocol label.** An agent's *real* HITL leverage is the gate TYPE it owns, which can diverge from the protocol template it embeds. `qa-lead` carries the *implementation* protocol but owns pure VERIFICATION gates → strongest AUTOMATE case. `lead-programmer` carries implementation but also owns `LP-CODE-REVIEW` (technical judgment).

| Agent | Protocol carried (verbatim) | Real gate type | Creative / Technical / Mixed | Recommendation |
|---|---|---|---|---|
| `creative-director` | leadership ("highest-level consultant… final strategic decisions") | Pillars, vision, player-experience taste (`CD-*` gates) | Creative | **KEEP-HITL** |
| `art-director` | design ("collaborative consultant… all creative decisions") | Visual identity, art-bible taste (`AD-*` gates) | Creative | **KEEP-HITL** |
| `game-designer` | design ("collaborative consultant") | Mechanic/GDD design taste | Creative | **KEEP-HITL** |
| `technical-director` | leadership ("highest-level consultant") | Architecture soundness, engine risk (`TD-*` gates) | Technical (judgment) | **HYBRID** — routine ADRs auto via `TD-ADR`/`/architecture-review`; novel → human |
| `producer` | leadership ("highest-level consultant") | Scope/schedule/dependency coordination (`PR-*` gates) | Mixed → mostly coordination | **AUTOMATE** coordination; escalate to human only on conflict |
| `lead-programmer` | implementation ("collaborative implementer") | Code review + impl feasibility (`LP-CODE-REVIEW`, `LP-FEASIBILITY`) | Technical | **AUTOMATE** the write-approval; **HYBRID** keep `LP-CODE-REVIEW` as auto-blocking technical judgment |
| `gameplay-programmer` | implementation ("collaborative implementer") | Code write-gate, tests | Technical / mechanical | **AUTOMATE** — replace "May I write" with rules + tests + `/story-done` |
| `qa-lead` | implementation ("collaborative implementer") | **Test coverage verification** (`QL-STORY-READY`, `QL-TEST-COVERAGE`) | Technical / verification | **AUTOMATE (strongest case)** — coverage gates auto-block on fail, no human turn |

---

## Notes

### AMBIGUOUS cases

1. **Implementation protocol steps 2–3 (architecture questions).** Genuinely HYBRID: "where should data live / static vs singleton" is mechanical when `control-manifest.md` already answers it (automate: follow manifest), but a real fork when it doesn't (route to `TD-ADR`, not a blanket human gate). Same logic applies to **every `AskUserQuestion` point** across the docs — classify by the decision's *content*: vision/taste = KEEP, "where does code live" = AUTOMATE/HYBRID. The protocol label alone never decides it.

2. **technical-director sign-off (review-workflow.md + leadership protocol).** Architecture review is judgment, not pure verification — some ADRs are novel design calls (keep human), most are routine application of existing patterns (auto via `TD-ADR` APPROVE). No clean line; recommend a "novel vs routine" trigger rather than blanket either way.

3. **director-gates CONCERNS handling.** Whether `CONCERNS` surfaces to a human depends entirely on gate prefix (verification → auto-block; creative → human). This is one rule that must be edited per-prefix, not globally.

4. **The "May I write" inside the design protocol vs. the blanket Layer-1 override.** Same sentence, opposite verdicts depending on artifact type. The design-doc one is legitimate creative HITL (keep); the code one is the override to scope down. Editing CLAUDE.md must distinguish them or it will either over-automate creative work or under-automate code.

### Single most important edit

**`CLAUDE.md` › "## Collaboration Protocol".** It is the only *unconditional, declared OVERRIDE* in the whole system ("These instructions OVERRIDE any default behavior and you MUST follow them exactly") and — unlike Layer 2's `director-gates.md` — **it has no dial.** Layer 2 already has `review-mode.txt`; Layer 1 (this block) does not, so it neuters automation everywhere regardless of mode.

**Scope this one block by artifact type** — creative docs (`design/**`, ADR content) keep "May I write" and Question→Options→Decision→Draft→Approval; code/tests/config/commits become governed by gameplay-code rules + BLOCKING tests + `/story-done` + `LP-CODE-REVIEW` + CI. The exact-edit must **scope, never delete** — verification stays, only the *human* gate on technical artifacts is replaced by an *automated* one at the same blocking level. Editing this single block changes behavior across all 49 agents and every skill that writes files.
