# Automation Infrastructure Analysis — Hooks, Settings, Rules

Scope: `.claude/settings.json`, `.claude/hooks/*.sh`, `.claude/rules/*.md`,
`.claude/docs/hooks-reference*`. Goal: inventory existing AUTOMATED enforcement and
identify NEW automated checks needed to safely replace HUMAN approval gates as the
studio moves toward autonomy.

Key framing: the collaboration protocol (`CLAUDE.md`) currently requires a human
"May I write this?" + approval gate on essentially every Write/Edit and every commit.
Removing those gates is only safe where an AUTOMATED check can stand in. This doc maps
where that coverage exists and where it does not.

---

## Existing Automated Enforcement

Hooks wired live in `settings.json`. "Blocking" = hook can return a non-zero exit that
stops the tool call (PreToolUse exit 2 blocks; PostToolUse exit 1 surfaces a blocking
error). "Advisory" = prints to stderr, always exits 0/allows.

| Mechanism (hook/rule) | What it checks | Blocking or Advisory? | Trigger |
|---|---|---|---|
| `validate-commit.sh` — JSON validity | `assets/data/**.json` staged files parse as valid JSON | **BLOCKING** (`exit 2`, line 62) | PreToolUse Bash, `git commit*` |
| `validate-commit.sh` — design sections | GDD has the 8 required sections | Advisory (warn, exit 0) | PreToolUse Bash, `git commit*` |
| `validate-commit.sh` — hardcoded values | `src/gameplay/**` numeric literals (damage/health/speed…) | Advisory | PreToolUse Bash, `git commit*` |
| `validate-commit.sh` — TODO format | `src/**` TODO/FIXME/HACK without `TODO(name)` owner | Advisory | PreToolUse Bash, `git commit*` |
| `validate-push.sh` | Push to protected branch (develop/main/master) | **Advisory** (block code present but COMMENTED OUT, lines 44–45) | PreToolUse Bash, `git push*` |
| `validate-assets.sh` — JSON validity | `assets/data/**.json` valid JSON | **BLOCKING** (`exit 1`, line 69) | PostToolUse Write/Edit |
| `validate-assets.sh` — naming | asset filename lowercase+underscores (no caps/space/dash) | Advisory | PostToolUse Write/Edit |
| `validate-skill-change.sh` | Advises `/skill-test` after `.claude/skills/**` edit | Advisory only | PostToolUse Write/Edit |
| `detect-gaps.sh` | Fresh-project / missing-docs detection, suggests skills | Advisory (informational) | SessionStart |
| `session-start.sh` | Loads sprint/milestone/git context, previews `active.md` | Advisory (informational) | SessionStart |
| `session-stop.sh` | Summarizes session, updates session log | Advisory (audit) | Stop |
| `pre-compact.sh` | Dumps state into convo before compaction | Advisory (state-preservation) | PreCompact |
| `post-compact.sh` | Reminds to restore `active.md` | Advisory | PostCompact |
| `log-agent.sh` / `log-agent-stop.sh` | Subagent audit trail start/stop | Advisory (audit) | SubagentStart / SubagentStop |
| `notify.sh` | Windows toast notification | Advisory (UX) | Notification |
| Rules `gameplay-code.md` … `shader-code.md` (11 files) | Path-scoped coding/design standards (data-driven values, dep direction, server-authoritative net, GDD 8 sections, test naming, etc.) | **Advisory — NOT mechanically enforced** (loaded as context to guide the model; no hook parses them) | Editing matching paths |

### Reference-only hooks (NOT wired — examples in `.claude/docs/hooks-reference/`)

These are documented templates with implementation bodies STUBBED OUT (build/test/lint
lines commented). They are NOT in `settings.json` and do nothing today:

| Reference hook | Would check | Designed exit |
|---|---|---|
| `pre-push-test-gate` | build + unit tests (+ integration/smoke on develop/main) | blocking (`exit 1`) — but all commands commented |
| `pre-commit-code-quality` | `src/**` linter, hardcoded values, TODO owner, unit tests | `exit $EXIT_CODE` — linter/test lines commented; warnings only |
| `pre-commit-design-check` | `design/**` + `assets/data/**` sections/refs/JSON | blocking — stubbed |
| `post-merge-asset-validation` | merged asset naming / power-of-2 / size budgets | `exit $EXIT_CODE` (naming + 4MB texture budget would block) — stubbed, post-merge only |
| `post-sprint-retrospective` | sprint retro generation | manual trigger, non-gating |

### Advisory hooks that could become BLOCKING to replace a human gate

- **`validate-push.sh`** → uncomment the `exit 2` block to make protected-branch push a
  real gate (currently pure reminder).
- **`validate-commit.sh` design-section + hardcoded-value warnings** → could escalate
  from warn to `exit 2` to enforce GDD completeness / data-driven values at commit time.
- **`validate-assets.sh` naming warning** → could escalate to `exit 1` to enforce naming.

---

## Permission Posture

### Current `settings.json`

**allow** (read-only / safe-test only):
`Bash(git status*)`, `Bash(git diff*)`, `Bash(git log*)`, `Bash(git branch*)`,
`Bash(git rev-parse*)`, `Bash(ls *)`, `Bash(dir *)`, `Bash(python -m json.tool*)`,
`Bash(python -m pytest*)`, `Bash(py -m pytest*)`.

**deny** (destructive / secret-exposing — KEEP INTACT):
`Bash(rm -rf *)`, `Bash(git push --force*)`, `Bash(git push -f *)`,
`Bash(git reset --hard*)`, `Bash(git clean -f*)`, `Bash(sudo *)`, `Bash(chmod 777*)`,
`Bash(*>.env*)`, `Bash(cat *.env*)`, `Bash(type *.env*)`, `Read(**/.env*)`.

### Gap for an autonomous pipeline

The allow-list grants READING git state and RUNNING tests, but grants NO mutation:
no `git add`, no `git commit`, no `git push`, no branch creation, no formatters, no
build. Every commit therefore falls through to a permission prompt — i.e. a de-facto
human gate on the most basic pipeline step. To automate the technical loop, mutation
commands must be allow-listed while keeping the destructive denies.

### Recommended allow-list additions (do NOT touch deny-list)

Git mutation (safe forms only; force/hard-reset/clean stay denied):
- `Bash(git add*)`
- `Bash(git commit*)`
- `Bash(git checkout -b *)` and `Bash(git switch -c *)` (feature branches)
- `Bash(git push origin *)` — note: keep `--force`/`-f` denied; deny entries override allow
- `Bash(git stash*)`, `Bash(git fetch*)`, `Bash(git merge --no-ff *)` (optional)

Test / verify runners (engine-agnostic + Godot per VERSION.md):
- `Bash(godot --headless*)` (covers `--script tests/gdunit4_runner.gd`)
- `Bash(python3 -m pytest*)` (alongside existing `python -m pytest*` / `py -m pytest*`)
- `Bash(dotnet test*)`, `Bash(dotnet build*)` (if Unity/C#)
- `Bash(npm test*)`, `Bash(npm run *)` (HTML/tooling prototypes)

Formatters / linters (mechanical, idempotent):
- `Bash(gdformat*)`, `Bash(gdlint*)` (GDScript)
- `Bash(dotnet format*)`, `Bash(clang-format*)`
- `Bash(black*)`, `Bash(ruff*)` (Python tooling)

Build / pipeline:
- `Bash(make *)` (if a Makefile drives build)

Hardening note: deny entries already override allow, so adding `Bash(git push origin *)`
does NOT re-enable force-push (still denied by `git push --force*` / `git push -f *`).
Consider tightening `Bash(ls *)`/`Bash(dir *)` are fine; leave them. Do NOT add a broad
`Bash(git*)` — that would shadow nothing but invites scope creep; prefer the specific
verbs above.

---

## Replacement-Check Inventory (key deliverable)

For each human approval gate, the automated check that can stand in — and whether it
exists today.

### Code correctness
- **Available today:** `validate-commit.sh` hardcoded-value + TODO warnings (ADVISORY,
  not blocking); rules `gameplay-code.md`/`engine-code.md`/etc. (model-context only).
- **Should exist:** active pre-commit/pre-push **lint + unit-test gate**. The
  `pre-commit-code-quality` and `pre-push-test-gate` reference hooks are the intended
  mechanism but are **stubbed and unwired**.
- **Command to enforce:** `godot --headless --script tests/gdunit4_runner.gd` (per
  coding-standards.md CI rule) + `gdlint`. **GAP:** no wired hook runs either.

### Design-doc completeness
- **Available today:** `validate-commit.sh` checks the 8 GDD sections — but **ADVISORY**.
  `design-docs.md` rule states the requirement (model-context only).
- **Replacement:** escalate that section check to `exit 2`, or wire
  `pre-commit-design-check`. Skills `/design-review`, `/story-readiness` do deeper
  checks but are model-invoked, not automatic gates.
- **GAP (partial):** completeness is *checked* but not *enforced*; semantic quality
  (formula correctness, internal consistency) has NO automated check — only
  model-judgment skills.

### Asset compliance
- **Available today:** `validate-assets.sh` — JSON validity BLOCKING; naming ADVISORY.
- **Replacement for naming/size/format:** `post-merge-asset-validation` reference hook
  (naming + power-of-2 + 4MB/512KB budgets) — **stubbed, unwired**. `/asset-audit` skill
  is model-invoked.
- **GAP:** texture size, power-of-2, and file-size-budget enforcement do NOT run
  automatically anywhere. Naming is detected but not blocked.

### Commit / push safety
- **Available today:** invalid-JSON blocks commit (`validate-commit.sh exit 2`).
  Deny-list blocks force-push / hard-reset / clean. `validate-push.sh` warns on
  protected-branch push.
- **GAP:** protected-branch push is **advisory only** (block commented out). No
  build/test precondition on push. No conventional-commit-format check (coding-standards
  requires `feat:`/`fix:` etc. — unenforced). No "commit references story/task ID" check
  (required by coding-standards — unenforced).

### Test evidence
- **Available today:** NONE automated. coding-standards.md defines a test-evidence matrix
  (Logic→unit test BLOCKING, Integration→test/playtest BLOCKING, Visual/UI→ADVISORY) and
  `/smoke-check`, `/story-done`, `/test-evidence-review` skills enforce it — but all are
  **model-invoked**, not hooks.
- **GAP (highest-risk):** the single most important gate for autonomy — "does this story
  have passing test evidence before it's marked Done / merged" — has **no automated hook**.
  Today it relies on a model following a skill, which is exactly the human-judgment
  substitute we must not trust blindly when removing gates.

### Summary of GAPS (risky-to-automate without new checks)
1. **Test gate** — no hook runs the test suite before commit/push/merge. (Critical.)
2. **Test-evidence presence** — no automated link from a "Done" story to a passing test.
3. **Lint / format** — no automated style/lint gate; advisory grep only.
4. **Protected-branch push** — block is commented out; advisory only.
5. **Asset size/format budgets** — not run automatically (reference hook stubbed).
6. **Commit message format + story-ID reference** — required by standards, unenforced.
7. **Rule enforcement** — all 11 rule files are model-context, not mechanically checked.
8. **Design semantic quality** — only completeness is auto-checked, not correctness.

---

## Recommendations

Ordered by autonomy payoff vs. safety. Each replaces a human gate with an automated one.

1. **Wire a real pre-push test gate.** Promote `pre-push-test-gate` from reference to an
   active `validate-push.sh` extension (or new hook): run
   `godot --headless --script tests/gdunit4_runner.gd` (and integration/smoke on
   develop/main) and `exit 2` on failure. This is the keystone replacement for the
   human "is it tested?" gate.

2. **Make protected-branch push blocking.** Uncomment the `exit 2` block in
   `validate-push.sh` (lines 44–45) so develop/main pushes require the test gate to pass.

3. **Add a pre-commit lint + test gate.** Wire `pre-commit-code-quality`: run `gdlint`
   and `tests/unit/` for touched systems; `exit 2` on failure. Escalate the existing
   hardcoded-value warning to blocking for `src/gameplay/**`.

4. **Add a test-evidence gate keyed to story completion.** New hook (PreToolUse Bash on
   commit, or a `/story-done` blocking check) that, for a story being marked Done,
   verifies the required evidence file exists per the coding-standards matrix
   (`tests/unit/...` passing for Logic stories). Closes the highest-risk gap.

5. **Escalate `validate-commit.sh` design-section check to blocking** (`exit 2`) for
   `design/gdd/**`, replacing the human design-review approval for *completeness*
   (keep `/design-review` for semantic quality).

6. **Wire asset budget enforcement.** Activate `post-merge-asset-validation` (or fold
   size/power-of-2/budget checks into `validate-assets.sh`); escalate naming to `exit 1`.

7. **Add commit-format + story-ID check** to `validate-commit.sh`: block commits whose
   message lacks Conventional-Commits prefix or a `Story:`/task-ID reference.

8. **Permissions:** add the allow-list entries in the Permission Posture section
   (`git add*`, `git commit*`, `git checkout -b *`, `git push origin *`, test runners,
   formatters). Leave the entire deny-list unchanged — deny overrides allow, so safe
   forms are enabled without re-enabling force-push / hard-reset / `.env` exposure.

9. **Keep human-only on CREATIVE/TASTE gates.** Do NOT automate away: art-bible/visual
   sign-off, game-feel/playtest verdicts, narrative canon, PROCEED/PIVOT/KILL gates
   (`/prototype`, `/vertical-slice`), and balance "fun" judgments. These map to the
   ADVISORY-tier evidence in the standards matrix and have no sound automated proxy.

> Net: today only invalid-JSON is a true automated gate. Autonomy safety hinges on
> activating the four stubbed reference hooks (test gate is #1) plus a test-evidence
> presence check, then opening the permission allow-list to mutation/test commands.
