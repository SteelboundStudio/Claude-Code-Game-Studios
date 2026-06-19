# Studio Autonomy Spec — Removing Human-in-the-Loop From Technical Work

**Status:** Implemented on branch `feature/studio-autonomy` (2026-06-19). One item blocked (permissions, §7).
**Date:** 2026-06-19

## Implementation Status (this session)

| Phase | Item | Status |
|---|---|---|
| A | CLAUDE.md Collaboration Protocol scoped by artifact type | ✅ done |
| A | COLLABORATIVE-DESIGN-PRINCIPLE.md scope banner + technical examples flipped | ✅ done |
| A | implementation-agent-protocol → autonomous; leadership-agent-protocol → split; design-agent-protocol untouched | ✅ done |
| C | 30 technical agents → autonomous; 6 leadership/mixed split; 13 creative agents preserved (verified) | ✅ done |
| C | 66 skills edited per classification (creative gates preserved verbatim) | ✅ done |
| D | director-gates.md — verification gates auto-block & mode-independent; creative surface to human; CONCERNS auto-proceeds-with-log | ✅ done |
| B | Replacement-check hooks: protected-branch block, pre-push test gate, design-section blocking, gameplay hardcoded blocking, asset-naming blocking, commit-format warn (all degrade gracefully on empty template) | ✅ done |
| — | `/skill-test` linter Check 4 updated to artifact-typed write-gate policy | ✅ done |
| B | **settings.json permission allow-list (§7)** — git/test/format mutation commands | ⛔ **BLOCKED** — auto-mode classifier denied the edit as permission-machinery self-modification; **needs your explicit approval** (see §7) |
| E | Adversarial verification: 0 CRITICAL, 0 HIGH — no creative gate mis-automated, no verification dropped | ✅ PASS |

**The one thing left for you:** apply the §7 permission additions to `.claude/settings.json` yourself
(or authorize me to). Without it, autonomous git commits/tests still hit a permission prompt — the
last de-facto human gate on the technical pipeline. The deny-list stays intact regardless.

---

**Goal:** Make the studio *mostly autonomous*. Keep the human in CREATIVE / TASTE / JUDGMENT
decisions. Replace every purely TECHNICAL / MECHANICAL / VERIFICATION / COORDINATION human
gate with an **automated check** — never by deleting the check.

> **The one rule that governs this whole spec:**
> *"Automate" ≠ "remove the gate." It = "replace the human approval gate with an automated check."*
> Autonomy must never drop verification. Every gate marked AUTOMATE below names the automated
> check that stands in for the human. A verification that drops from BLOCKING to ADVISORY is
> dropping verification, and is forbidden.

---

## 1. Executive Summary

### Current state
- **One global override neuters all automation.** `CLAUDE.md` › "## Collaboration Protocol"
  declares *"These instructions OVERRIDE any default behavior"* and mandates
  *"Agents MUST ask 'May I write this to [filepath]?'"*, *"show drafts before approval"*,
  *"No commits without user instruction"*. This fires on **every** Write/Edit/commit, for code
  and creative work alike. It has **no dial**.
- **Almost no automated enforcement exists to stand in.** Of 12 wired hooks, exactly **one**
  real automated gate exists today: invalid JSON blocks a commit (`validate-commit.sh exit 2`)
  and an asset Write (`validate-assets.sh exit 1`). Everything else — design-section checks,
  hardcoded-value checks, protected-branch push, naming — is **advisory** (the push-block code
  is literally commented out). The four "quality" reference hooks (test gate, lint, design check,
  asset budgets) are **stubbed and unwired**. All 11 rule files are model-context only.
- **Permissions grant zero mutation.** The allow-list permits reading git state and running
  `pytest`, but no `git add`/`commit`/`push`, no formatters, no build. Every commit falls
  through to a permission prompt — a de-facto human gate on the most basic pipeline step.

**Net:** the studio is fully manual not because the technical gates are valuable, but because
(a) a blanket override forces a human turn everywhere and (b) there is no automated check ready
to replace that human turn safely.

### Target state
- The blanket override is **scoped by artifact type**: creative artifacts keep
  Question→Options→Decision→Draft→Approval; technical artifacts are governed by rules + tests +
  `/story-done` + CI.
- A **replacement-check layer** (hooks + permissions) exists so removing a human gate never
  removes verification.
- Skills drop their mechanical "May I write?" pauses but keep their creative/judgment gates.
- Director gates split: verification verdicts auto-block on fail; creative verdicts still surface
  to the human.

### Approach (3 moves, in dependency order)
1. **Build the replacement checks first** (Phase B). You cannot safely remove a human gate before
   the automated stand-in exists.
2. **Scope the override** (Phase A) and split the protocols by artifact type.
3. **Flip the skill-level + director-gate switches** (Phases C–D) that now have automated backing.

---

## 2. The Classification Principle

Every place the system pauses for a human is a **gate**. Classify each gate by **type**, not by
which skill or protocol it sits in:

| Gate type | Definition | Default verdict |
|---|---|---|
| **CREATIVE** | Taste / aesthetic / design-authoring content (mechanics, art, UX, narrative, lore) | **KEEP-HITL** |
| **JUDGMENT** | Quality / fun / vision verdict (PROCEED·PIVOT·KILL, go/no-go, "feels good", fairness) | **KEEP-HITL** |
| **VERIFICATION** | Objective pass/fail (tests, traceability, coverage, lint, schema, naming, budgets) | **AUTOMATE** |
| **MECHANICAL** | File write / format / status update / commit of already-decided content | **AUTOMATE** |
| **COORDINATION** | Sprint/milestone/dependency/routing logistics | **AUTOMATE** |

**Two errors are not symmetric.** Wrongly automating a taste decision is far worse than wrongly
keeping a technical step manual. **When a gate genuinely straddles two types, keep the human**
(HYBRID = automate the mechanical sub-steps, keep the human on the creative/judgment call).

**Gate type ≠ protocol label.** `qa-lead` carries the *implementation* protocol but owns pure
VERIFICATION gates — it is the strongest AUTOMATE case. Always classify by what the gate decides.

**The `solo`/`lean` trap.** Setting `review-mode.txt` to `solo`/`lean` *skips* director gates —
that is *deleting verification*, which this spec forbids as an automation lever. The valid lever
is always "convert the verdict to objective pass/fail sub-criteria the orchestrator blocks on,"
never "turn the gate off."

---

## 3. Two Layers of HITL (the fix differs per layer)

### Layer 1 — Blanket, unconditional. **No dial. This is where the leverage is.**
Sources (a single edit here changes behavior across all 48 agents and every skill):
- `CLAUDE.md` › "## Collaboration Protocol" — the only declared *OVERRIDE*.
- `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` — the long-form source CLAUDE.md links to.
- `.claude/docs/templates/collaborative-protocols/{design,implementation,leadership}-agent-protocol.md`
- The per-agent copies of those protocols embedded in `.claude/agents/*.md`.

**Fix:** scope by artifact type — do **not** delete. Creative paths (`design/**`, ADR *content*,
art/narrative/UX docs) keep the protocol. Technical paths (`src/**`, `tests/**`, `assets/data/**`,
`*.json`, config, commits) are governed by the replacement-check layer.

### Layer 2 — Conditional, already half-built. **The replacement mechanism, not a thing to gut.**
- `.claude/docs/director-gates.md` already has `production/review-mode.txt` (`full`/`lean`/`solo`)
  and returns `APPROVE`/`CONCERNS`/`REJECT`. The only residual human touchpoint is **verdict
  handling** (`CONCERNS` → `AskUserQuestion`).

**Fix:** split verdict handling by gate prefix. Verification gates (`QL-*`, `TD-ENGINE-RISK`,
`LP-CODE-REVIEW`'s objective half) → fail auto-blocks, no human. Creative/strategic gates
(`CD-*`, `AD-*`, `PR-*` scope) → keep surfacing to the human.

---

## 4. What Stays Human (the explicit KEEP-HITL list)

These are the studio's taste and judgment. **Never automate these. The verify pass at the end of
implementation specifically hunts for any of these accidentally flipped to AUTOMATE.**

### Creative authoring (the approval IS the taste checkpoint)
- `brainstorm` — fantasy, hook, pillars, core loop
- `map-systems` — system decomposition, dependency/priority judgment
- `design-system`, `quick-design` — GDD mechanic content + canonical GDD edits
- `art-bible`, `asset-spec` — visual identity, per-asset specs & generation prompts
- `ux-design` — layout, hierarchy, HUD philosophy, interaction feel
- `reverse-document` — design *intent* behind code (cannot be inferred; must ask the author)
- `architecture-decision` — problem framing, alternatives, schema/data *design* (not the file write)
- `create-architecture` — layer map, ownership, data-flow design decisions
- `team-narrative` (story/lore/dialogue), `team-audio` (sonic identity/tone),
  `team-level` (layout/arc/theme), `team-live-ops` (season design/flavor/fairness),
  `team-combat` (mechanic design), `team-polish`/`team-ui` (visual juice, mix, layout feel)
- `setup-engine` — the engine/language *choice* and performance-budget targets
- `start` — onboarding routing (depends on the user's own creative situation)

### Judgment verdicts (quality / fun / vision / risk / ship)
- `prototype`, `vertical-slice` — **PROCEED / PIVOT / KILL**
- `gate-check` — the subjective "core mechanic feels good" check
- `soak-test` — fun-fatigue + observed-stability verdict
- `milestone-review`, `release-checklist`, `team-release`, `launch-checklist` — **go / no-go**, sign-offs
- `day-one-patch`, `hotfix` — what ships in an emergency patch + deploy approval
- `playtest-report` — qualitative playtest assessment (CD-PLAYTEST)
- `review-all-gdds`, `design-review` — which GDD "wins", design-quality verdict
- `team-live-ops` — "is the reward track fair / non-predatory" (ethics + feel)
- `bug-triage` — closing a bug / marking Won't Fix
- `creative-director` and `art-director` strategic/creative gates everywhere

---

## 5. What Gets Automated (with its replacement check)

Full per-touchpoint detail is in the appendix analysis files. Summary of the categories and the
automated check that replaces the human gate:

| Category (examples) | Replacement check (must exist before the flip) |
|---|---|
| **Mechanical "May I write?"** on derived reports — `changelog`, `patch-notes`, `bug-report`, `bug-triage` report, `content-audit`, `security-audit` report, `milestone-review`, `onboard`, `retrospective`, `tech-debt` scan, `test-evidence-review`, `playtest-report`, `propagate-design-change` impact report, `launch-checklist`, `soak-test` protocol, `release-checklist` | Per-doc **schema/section-completeness validator**; append-only diff guard where the doc is a register |
| **Mechanical write of approved creative content** — `brainstorm`/`map-systems`/`create-architecture`/`asset-spec` final write *after sections are approved* | Required-section presence check (the creative content was already gated upstream — only the keystroke is automated) |
| **Verification verdicts** — `architecture-review` RTM, `consistency-check`, `scope-check`, `asset-audit`, `localize` scan, `skill-test`, `story-readiness`, `sprint-status`, `balance-check`, `gate-check` objective items | The verdict is *computed* from objective inputs; emit it, don't ask. Convert advisory→blocking where it gates a phase |
| **Test gates** — `smoke-check`, `story-done` test-evidence, `team-qa` automated portion, `team-combat`/`team-polish` test phases, `dev-story` write→test | **Automated test suite pass/fail** (wired hook, §6) + test-evidence-presence check |
| **Coordination / routing** — `qa-plan` scope, `regression-suite` mode, `dev-story` deps, `estimate`, `help`, `prototype` intent, `code-review` next-step, `sprint-plan` capacity | Deterministic default-inference from project state; auto-block only on hard-dependency-incomplete |
| **Config writes after a human decision** — `setup-engine` derived CLAUDE.md/VERSION.md/routing | Post-write validation: placeholders replaced, risk level computed from cutoff table, routing matches chosen language |
| **Commits** | Conventional-commit format + story-ID-in-body + CI-green checks |

---

## 6. The Replacement-Check Layer (build this FIRST — Phase B)

Removing a human gate is only safe where an automated check stands in. Today most do not exist.
This is the highest-risk part of autonomy and **must precede** the skill-level flips that depend
on it. Ordered by payoff:

| # | Build | Replaces the human gate on | Status today |
|---|---|---|---|
| B1 | **Wire a pre-push test gate** — run `godot --headless --script tests/gdunit4_runner.gd` (+ integration/smoke on develop/main); `exit 2` on failure | "Is it tested?" | Reference hook stubbed/unwired |
| B2 | **Make protected-branch push blocking** — uncomment `validate-push.sh` `exit 2` | Push to main/develop | Block code commented out |
| B3 | **Pre-commit lint + unit-test gate** — `gdlint` + touched-system unit tests; escalate hardcoded-value warning to blocking for `src/gameplay/**` | Human code review for *objective* defects | Advisory grep only |
| B4 | **Test-evidence gate keyed to story completion** — for a story marked Done, assert the required evidence file exists & passes per the coding-standards matrix (Logic→unit test BLOCKING) | "Does this story actually have test evidence?" | **No automated check at all (highest-risk gap)** |
| B5 | **Design-section completeness → blocking** for `design/gdd/**` (escalate existing `validate-commit.sh` check to `exit 2`) | Human design-review for *completeness* (keep `/design-review` for semantic quality) | Advisory |
| B6 | **Asset budget enforcement** — naming `exit 1`, power-of-2 + size budgets (wire `post-merge-asset-validation`) | Manual asset audit | Stubbed |
| B7 | **Commit-format + story-ID check** in `validate-commit.sh` | Manual commit review | Unenforced |
| B8 | **Permission allow-list additions** (see §7) | The implicit prompt-gate on every mutation | Zero mutation allowed |

**Gaps with no sound automated proxy (these stay human until a harness exists):**
manual smoke / manual QA that requires a human *observing the running game* (`smoke-check` Phase 4,
`team-qa` Phase 5) — automatable only by investing in scripted e2e/integration smoke tests.
This is a roadmap recommendation, not a gate to remove.

---

## 7. Permissions (additive — deny-list stays intact)

Deny entries override allow, so adding safe `git push origin *` does **not** re-enable force-push.
**Add** (do not touch the deny-list):

```
Bash(git add*)            Bash(git commit*)          Bash(git checkout -b *)
Bash(git switch -c *)     Bash(git push origin *)    Bash(git fetch*)   Bash(git stash*)
Bash(godot --headless*)   Bash(python3 -m pytest*)   Bash(dotnet test*)  Bash(dotnet build*)
Bash(npm test*)           Bash(npm run *)
Bash(gdformat*)  Bash(gdlint*)  Bash(dotnet format*)  Bash(clang-format*)  Bash(black*)  Bash(ruff*)
```
**Keep denied (unchanged):** `rm -rf`, `git push --force`/`-f`, `git reset --hard`, `git clean -f`,
`sudo`, `chmod 777`, `*>.env*`, `cat/type *.env*`, `Read(**/.env*)`. Do **not** add a broad `Bash(git*)`.

---

## 8. Implementation Plan (phased, dependency-ordered)

- **Phase A — Scope the override (Layer 1).**
  Edit `CLAUDE.md` "## Collaboration Protocol" + `COLLABORATIVE-DESIGN-PRINCIPLE.md` together so they
  don't drift: split the "MUST ask / no commits" rule by artifact path (creative = HITL, technical =
  replacement-check-governed). Edit the **implementation-agent-protocol** (drop step-5 write-wait,
  keep `/story-done`) and the **leadership-agent-protocol** (producer coordination → advisory).
  Leave **design-agent-protocol** untouched.
- **Phase B — Build the replacement-check layer.** B1–B8 from §6. *Must land before Phase C flips
  that depend on a given check.*
- **Phase C — Flip skill-level mechanical gates.** Remove "May I write?" pauses on the AUTOMATE rows
  in the appendix tables; keep KEEP-HITL rows verbatim. (~40 skills have at least one mechanical
  write-gate to drop; ~20 keep a creative/judgment gate.)
- **Phase D — Split director-gate verdict handling** (Layer 2). Verification prefixes auto-block;
  creative prefixes keep surfacing.
- **Phase E — Verify** (§10).

**This session:** Phases A + B + the permission change (the high-leverage, low-risk structural core),
then a representative slice of Phase C/D, gated on the owner-boundary answers in §9. Remaining
bulk skill edits proceed after the pattern is confirmed on the slice.

---

## 9. Open Boundary Decisions (owner's call — these define the taste line)

The classification above applies the owner's stated rule to the clear majority. These few genuinely
straddle the line — they configure *how much* autonomy, which is itself the taste call reserved for
the owner:

1. **Default review-mode / oversight posture** (`adopt`, `review-mode.txt`). `solo`/`lean` skip
   director gates entirely. What is the default oversight level for a "mostly autonomous" studio?
2. **Code-review automation depth** (`story-done` Phase 5, `team-combat` arch gate, `code-review`).
   Replace the objective half of code review with a *blocking linter/static-analysis ruleset* and
   reserve the human only for design-intent concerns — or keep human code review?
3. **Production deploy** (`team-release` Phase 6). Tag/changelog/staging auto on GO. Production push
   is irreversible — keep a human authorization on the final production deploy, or full auto-deploy?
4. **CONCERNS-branch default** (`sprint-plan`, `story-done` Phase 4b, director gates). The objective
   branches (UNREALISTIC/INADEQUATE capacity/coverage math) auto-resolve. On a *CONCERNS* (risk-
   tolerance) verdict, default to auto-proceed-with-log, or always surface to the human?

---

## 10. Verification Plan (the loop's exit condition)

A flip is only "done" when:
1. **Coverage** — every touchpoint across all 73 skills / 3 protocols / CLAUDE.md / director gates is
   accounted for as AUTOMATE / KEEP-HITL / HYBRID (the appendix tables are the coverage ledger).
2. **No taste mis-automation** — a dedicated re-read confirms *zero* CREATIVE/JUDGMENT gate from §4
   was flipped to AUTOMATE. This is the dangerous error direction; hunt it specifically.
3. **No dropped verification** — every AUTOMATE row has a live replacement check at the *same blocking
   level* it had before; no gate was downgraded to advisory or skipped via `solo`/`lean`.
4. **Replacement checks actually run** — B1–B8 land before the skills that rely on them are flipped;
   smoke-test the test gate by pushing a deliberately failing test and confirming `exit 2`.

---

## 11. Risks & Safeguards

- **Mis-automating taste** → §4 keep-list + the §10.2 verify pass.
- **Dropping verification while "automating"** → the §1 rule; §10.3; never use `solo`/`lean` as a lever.
- **Removing a gate before its check exists** → Phase B precedes the dependent Phase C flips.
- **Irreversible/outward actions** → production deploy keeps a human authorization (pending §9.3).
- **CLAUDE.md / COLLABORATIVE-DESIGN-PRINCIPLE drift** → edit both in the same change.

---

## Appendices (full per-touchpoint analysis)

- `analysis/skills-cohort-a.md` — skills adopt → prototype (37), every touchpoint classified.
- `analysis/skills-cohort-b.md` — skills qa-plan → vertical-slice (36), every touchpoint classified.
- `analysis/protocols-and-agents.md` — CLAUDE.md, the 3 protocols, agent classification, global switches.
- `analysis/infrastructure.md` — hooks, settings, rules; existing enforcement + replacement-check gaps.
