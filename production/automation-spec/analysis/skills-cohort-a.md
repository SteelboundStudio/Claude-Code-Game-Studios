# Skills Cohort A — HITL Gate Analysis

Scope: 37 skills (adopt → prototype). Each HITL touchpoint split into its own row.
"Automate" = replace human approval gate with an automated verification check — never delete the check.
Asymmetry rule applied: when unsure between AUTOMATE and KEEP, defaulted to KEEP-HITL / AMBIGUOUS.

**Director-gate note**: Many skills spawn directors (CD-PILLARS, AD-ART-BIBLE, TD-FEASIBILITY, PR-SCOPE, etc.) via `Task` — these are already AI-to-AI. The residual HUMAN touchpoint is the user-surfacing `AskUserQuestion` on CONCERNS/REJECT. Setting `solo`/`lean` mode SKIPS the gate entirely (deletes verification) and is therefore NOT a valid automation lever. The valid lever is "convert director verdict to objective pass/fail criteria the orchestrator blocks on; auto-accept only when sub-criteria pass."

| Skill | Touchpoint (quoted, trimmed) | Gate Type | Recommendation | Lever (exact edit) | Replacement Check |
|---|---|---|---|---|---|
| adopt | Fresh-project branch: `AskUserQuestion` then "stop — do not proceed with the audit" | COORDINATION | AUTOMATE | Route by detected state automatically (no artifacts → emit "run /start"); drop the stop-and-ask | artifact-presence glob check |
| adopt | "Ask before writing — always confirm before creating the adoption plan file" | MECHANICAL | AUTOMATE | Auto-write `docs/adoption-plan-[date].md`; plan is derived from objective format-compliance scan | schema/format-compliance validator must pass |
| adopt | review-mode selection `AskUserQuestion` (Lean/Full/Solo) → write `review-mode.txt` | COORDINATION | AMBIGUOUS | Could default to `lean`, but mode governs human-oversight policy itself | Owner decides default policy — flag |
| architecture-decision | "Status: ask the user — current status of this decision?" (retrofit) | MECHANICAL | AUTOMATE | New ADRs always `Proposed` (skill already states this); infer retrofit status from file location/header | status-enum schema validation |
| architecture-decision | Assumptions `AskUserQuestion` (problem framing, alternatives, GDD linkage) | CREATIVE | KEEP-HITL | — (technical framing/design intent) | — |
| architecture-decision | Schema/data design questions via separate `AskUserQuestion` | JUDGMENT | KEEP-HITL | — (design decision) | — |
| architecture-decision | "BLOCKING — do not write to architecture.yaml without explicit user approval" | MECHANICAL | AUTOMATE | Auto-append registry entries (never modify existing); registry is derived index | registry-schema validation + append-only invariant check |
| architecture-decision | Specialist blocking issue → "confirm the changes with the user before proceeding" | VERIFICATION | HYBRID | Auto-apply specialist's API/version corrections; keep user call only if decision changes | engine-reference version-compat check |
| architecture-review | Ambiguous TR match → "ask the user" | JUDGMENT | KEEP-HITL | — (intent disambiguation) | — |
| architecture-review | "May I write the full Requirements Traceability Matrix?" / write approval | MECHANICAL | AUTOMATE | Auto-write RTM + review doc; both derived from objective coverage scan | traceability-matrix-complete check |
| architecture-review | Verdict `PASS / CONCERNS / FAIL` (coverage gaps, cross-ADR conflicts) | VERIFICATION | AUTOMATE | Verdict is objective (every TR-ID maps to an ADR, no conflicts); compute, don't ask | traceability + conflict-detection pass/fail |
| art-bible | Per-section "Present art-director's draft … `AskUserQuestion`" → approve → write | CREATIVE | KEEP-HITL | — (visual identity / taste) | — |
| art-bible | Art-director vs ux-designer conflict → "Do NOT silently resolve — `AskUserQuestion`" | CREATIVE | KEEP-HITL | — (aesthetic tradeoff) | — |
| art-bible | Phase 5 Art Director Sign-Off (AD-ART-BIBLE) verdict | JUDGMENT | KEEP-HITL | — (taste verdict on visual spec) | — |
| asset-audit | Verdict `COMPLIANT / WARNINGS / NON-COMPLIANT`; read-only, no writes | VERIFICATION | AUTOMATE (already) | None needed — objective naming/size/format checks | naming + size-budget + format lint |
| asset-spec | Entity inventory `AskUserQuestion` → "May I write the entity inventory?" | MECHANICAL | HYBRID | Auto-write the derived inventory list; keep added-item descriptions human | manifest-schema validation |
| asset-spec | Per-asset spec review "Approve all — write to file" / regenerate direction | CREATIVE | KEEP-HITL | — (visual spec + generation prompt = taste) | — |
| asset-spec | "May I write the spec to specs/[target]-assets.md?" | MECHANICAL | HYBRID | Auto-write once content approved upstream; the write itself is mechanical | manifest-schema validation |
| balance-check | Closing `AskUserQuestion` after report (read-only report) | COORDINATION | AUTOMATE | Auto-emit report + next-step recommendation; no taste in the analysis | balance-outlier/progression formula checks |
| brainstorm | Concept ideation `AskUserQuestion` (fantasy, hook, pillars, loop) | CREATIVE | KEEP-HITL | — (core creative authoring) | — |
| brainstorm | "Pillar confirmation" `AskUserQuestion` + CD-PILLARS sign-off | JUDGMENT | KEEP-HITL | — (design vision verdict) | — |
| brainstorm | "Game concept is ready. May I write it to game-concept.md?" | MECHANICAL | HYBRID | Auto-write after sections approved; write is mechanical, content already gated | required-section schema check (8 sections) |
| bug-report | "Ask: May I write this to bugs/BUG-[NNNN].md?" | MECHANICAL | AUTOMATE | Auto-file; bug report is structured derived output | bug-template schema (repro/severity/context present) |
| bug-triage | "May I write this triage report?" | MECHANICAL | AUTOMATE | Auto-write triage report (priority×severity is rule-based) | priority-matrix rule validation |
| bug-triage | "Never close or mark Won't Fix without user approval" | JUDGMENT | KEEP-HITL | — (closing a bug is a judgment call) | — |
| changelog | "May I write this changelog to docs/CHANGELOG.md?" | MECHANICAL | AUTOMATE | Auto-write; changelog derived from git+sprint data | conventional-commit parse + schema check |
| code-review | Verdict `APPROVED / CHANGES REQUIRED / MAJOR REVISION`; read-only | VERIFICATION | HYBRID | Auto-flag objective violations (standards/SOLID/arch-pattern); keep human call on "major revision" judgment | lint + arch-pattern + coding-standards checks (blocking) |
| code-review | Closing `AskUserQuestion` "how would you like to proceed?" | COORDINATION | AUTOMATE | Auto-route to next skill by verdict | n/a (routing) |
| consistency-check | Verdict `PASS / CONFLICTS FOUND`; closing `AskUserQuestion` widget | VERIFICATION | AUTOMATE | Compute verdict from registry vs GDD scan; auto-write result | entity-registry cross-ref check (blocking) |
| consistency-check | "[N] conflicts need manual resolution before architecture begins" (BLOCKED) | VERIFICATION | HYBRID | Auto-detect + auto-block the gate; resolution of a real semantic conflict stays human | consistency-check PASS gate (convert advisory→blocking) |
| content-audit | "May I write the full report to content-audit-[date].md?" | MECHANICAL | AUTOMATE | Auto-write; gap table is planned-vs-built count, objective | content-count diff check |
| create-architecture | HIGH-RISK engine domain `AskUserQuestion` "how to proceed?" | VERIFICATION | AUTOMATE | Auto-flag HIGH-RISK domains in output (skill already does this); drop the pause | engine-version risk-table lookup |
| create-architecture | Per-section approval (layer map, ownership, data-flow) before write | JUDGMENT | KEEP-HITL | — (architectural design decisions) | — |
| create-architecture | "All sections approved. May I write the master architecture document?" | MECHANICAL | HYBRID | Auto-write once sections approved; write is mechanical | required-section presence check |
| create-architecture | TD Sign-Off + LP Feasibility verdict; "May I update Document Status?" | JUDGMENT | KEEP-HITL | — (feasibility verdict); status-write sub-step auto | — (status write: file-write check) |
| create-control-manifest | "Add rules — I have additional rules before writing" `AskUserQuestion` | MECHANICAL | AUTOMATE | Auto-extract rules from Accepted ADRs+prefs; manifest is mechanical projection | ADR-extraction completeness check |
| create-control-manifest | TD-MANIFEST verdict CONCERNS → `AskUserQuestion` | JUDGMENT | HYBRID | Auto-accept when objective extraction complete; keep human only on flagged rule conflict | rule-source-traceability check |
| create-control-manifest | "May I write the Control Manifest?" | MECHANICAL | AUTOMATE | Auto-write derived manifest | schema check (per-system rule coverage) |
| create-epics | Untraced requirements "warn before proceeding" `AskUserQuestion` | VERIFICATION | AUTOMATE | Auto-warn + proceed with placeholders (already documented path); block only if zero coverage | traceability (TR-ID→ADR) check |
| create-epics | PR-EPIC verdict CONCERNS/UNREALISTIC → `AskUserQuestion` | JUDGMENT | HYBRID | Auto-accept when scope metrics in-band; keep human on genuine scope judgment | epic-size heuristic + module-boundary check |
| create-epics | "May I write the epic file to EPIC.md?" (per-epic) | MECHANICAL | AUTOMATE | Auto-write epic (one per module, derived from architecture) | epic-template schema check |
| create-stories | QL-STORY-READY: revise untestable acceptance criteria before proceeding | VERIFICATION | AUTOMATE | Auto-block stories with non-testable criteria; revise loop is rule-checkable | story-readiness READY criteria check |
| create-stories | Existing QA plan → "How do you want to proceed?" `AskUserQuestion` | COORDINATION | AUTOMATE | Auto-reuse existing QA-plan specs when present | file-presence + spec-coverage check |
| create-stories | "May I write these [N] stories?" | MECHANICAL | AUTOMATE | Auto-write story set | story-template schema (TR-ID/ADR/AC/test-path) check |
| day-one-patch | Scope `AskUserQuestion` "[A] Approve scope / [B] Adjust / [C] None" | JUDGMENT | KEEP-HITL | — (what ships in a launch patch = risk judgment) | — |
| day-one-patch | "May I write this rollback plan? … do not proceed until written" | MECHANICAL | AUTOMATE | Auto-write rollback plan (template-driven); keep the must-exist gate | rollback-plan-present blocking check |
| day-one-patch | QA verdict "must be PASS / PASS WITH WARNINGS before proceeding" | VERIFICATION | AUTOMATE | Gate on automated QA result | smoke-check / team-qa PASS gate |
| day-one-patch | "Approvals Required Before Deploy" (producer sign-off) | JUDGMENT | KEEP-HITL | — (deploy-timing/go decision) | — |
| design-review | Ambiguous design issue → grouped `AskUserQuestion` design decisions | CREATIVE | KEEP-HITL | — (design authoring decisions) | — |
| design-review | creative-director synthesis Verdict `APPROVED / NEEDS REVISION / MAJOR` | JUDGMENT | KEEP-HITL | — (design quality verdict) | — |
| design-review | "May I update systems-index to mark [system] Approved?" / review-log write | MECHANICAL | AUTOMATE | Auto-write tracking updates once verdict set (multiSelect batch already mechanical) | status-enum + log-append schema check |
| design-system | Per-section "Approve — write it to file / Make changes / Start over" | CREATIVE | KEEP-HITL | — (this IS the GDD content gate) | — |
| design-system | Conflicting numbers across docs → "resolve before writing, do not silently use different numbers" | VERIFICATION | HYBRID | Auto-detect the numeric conflict; keep human resolution of which value wins | consistency-check numeric cross-ref |
| design-system | CD-GDD-ALIGN verdict | JUDGMENT | KEEP-HITL | — (design alignment verdict) | — |
| dev-story | Manifest version mismatch → "how to proceed?" `AskUserQuestion` | VERIFICATION | AUTOMATE | Auto-read current manifest rules always; log non-compliance, don't pause | manifest-version diff + rule-apply check |
| dev-story | Dependency not Complete → "Proceed anyway / …" `AskUserQuestion` | COORDINATION | AUTOMATE | Auto-block if hard dep incomplete; proceed if soft | dependency-status check |
| dev-story | Ambiguity in story/ADR → "My plan is [X]. Proceed?" | JUDGMENT | KEEP-HITL | — (under-specified design intent) | — |
| dev-story | Sub-agent "May I write to [path]?" per file | MECHANICAL | AUTOMATE | Sub-agents auto-write code/tests/evidence into delegated dirs | tests-must-pass (CI blocking) + path-allowlist |
| estimate | "If too vague to estimate, ask for clarification"; read-only | COORDINATION | AUTOMATE | Auto-emit estimate with confidence band; flag low-confidence instead of pausing | complexity/velocity heuristic |
| gate-check | Objective checklist items (artifact-exists, verdict-line not FAIL) | VERIFICATION | AUTOMATE | Compute each artifact/verdict check programmatically | artifact-presence + verdict-line parse |
| gate-check | "The core mechanic feels good … subjective check — ask the user" | JUDGMENT | KEEP-HITL | — (explicitly subjective "feel") | — |
| gate-check | Director panel (4 directors) verdicts roll up to PASS/CONCERNS/FAIL | JUDGMENT | HYBRID | Auto-roll objective sub-criteria; keep human override on subjective items | per-director objective-criteria check |
| gate-check | Adversarial self-challenge (5 questions to disprove verdict) | VERIFICATION | AUTOMATE | Run challenge as automated re-check of specific files | file re-verification pass |
| help | "For MANUAL steps, ask: has [step] been completed?"; read-only | COORDINATION | AUTOMATE | Infer completion from artifacts where detectable; flag only the truly undetectable | artifact-state detection |
| hotfix | Severity confirm `AskUserQuestion` "[A]/[B]/[C]" | JUDGMENT | KEEP-HITL | — (emergency severity = human judgment + accountability) | — |
| hotfix | "May I write this to hotfixes/…?" | MECHANICAL | AUTOMATE | Auto-write the audit-trail record | hotfix-record schema check |
| hotfix | Branch creation `AskUserQuestion` before `git checkout -b` | MECHANICAL | AUTOMATE | Auto-create branch from detected base-ref | base-ref-valid git check |
| hotfix | "All three must return APPROVE before proceeding" (lead/qa/producer sign-off) | JUDGMENT | KEEP-HITL | — (deploy approval for emergency fix) | — |
| hotfix | QA gate Smoke/Team-QA before deploy | VERIFICATION | AUTOMATE | Gate on automated QA result | smoke-check PASS / team-qa APPROVED |
| launch-checklist | "May I write this to launch-checklist-[date].md?" | MECHANICAL | AUTOMATE | Auto-write checklist (dry-run/non-dry-run flag controls) | checklist-template schema check |
| launch-checklist | Go/No-Go sign-offs (per-department) | JUDGMENT | KEEP-HITL | — (launch go decision) | — |
| localize | scan/validate/RTL modes are read-only — no writes | VERIFICATION | AUTOMATE (already) | None — hardcoded-string + locale validation objective | string-extraction + locale lint |
| localize | Multiple "May I write … brief/report/scripts?" | MECHANICAL | AUTOMATE | Auto-write derived briefs/reports | per-doc schema check |
| localize | String-freeze violations → `AskUserQuestion` / "approved freeze lift" | COORDINATION | HYBRID | Auto-detect + block violations; freeze-lift approval stays human | freeze-diff check (convert to blocking) |
| localize | Loc QA Verdict + "Producer approves shipping [Locale]" sign-off | JUDGMENT | HYBRID | Auto-compute coverage verdict; keep producer ship-decision human | coverage% + completeness check |
| map-systems | System enumeration `AskUserQuestion` "Iterate until user approves" | CREATIVE | KEEP-HITL | — (decomposing concept = design judgment; skill states "requires human judgment") | — |
| map-systems | Dependency ordering + priority `AskUserQuestion` | JUDGMENT | KEEP-HITL | — (scope/priority = product judgment) | — |
| map-systems | TD-SYSTEM-BOUNDARY / PR-SCOPE / CD-SYSTEMS verdicts | JUDGMENT | KEEP-HITL | — (boundary + scope + design verdicts) | — |
| map-systems | "May I write the systems index? … Wait for approval" | MECHANICAL | HYBRID | Auto-write once enumeration+priorities approved upstream | systems-index schema check |
| milestone-review | Producer GO/AT-RISK/OFF-TRACK → `AskUserQuestion` Go/No-Go | JUDGMENT | KEEP-HITL | — (milestone go/no-go) | — |
| milestone-review | "May I write this to milestones/[name]-review.md?" | MECHANICAL | AUTOMATE | Auto-write derived review report | metrics-completeness check |
| onboard | "May I write this to onboarding/onboard-[role]-[date].md?" | MECHANICAL | AUTOMATE | Auto-write derived onboarding doc | template schema check |
| patch-notes | "If no version, ask the user" | COORDINATION | AUTOMATE | Auto-derive version from latest tag/changelog | git-tag lookup |
| patch-notes | "May I write these patch notes to patch-notes/[version].md?" | MECHANICAL | AUTOMATE | Auto-write; derived from git+changelog | schema check |
| perf-profile | Per-item "Implement / schedule / skip" `AskUserQuestion`; read-only | JUDGMENT | HYBRID | Auto-rank candidates vs budget; keep human call on which fixes to take | budget-breach detection |
| playtest-report | CD-PLAYTEST assessment before save | JUDGMENT | KEEP-HITL | — (qualitative playtest judgment) | — |
| playtest-report | "May I write this playtest report?" | MECHANICAL | AUTOMATE | Auto-write the structured report | report-template schema check |
| project-stage-detect | "Request Approval Before Writing … May I write stage analysis? Wait for approval" | MECHANICAL | AUTOMATE | Auto-write diagnostic report (read-only analysis, objective stage detection) | artifact-presence stage-detection check |
| propagate-design-change | TD-CHANGE-IMPACT verdict APPROVE/CONCERNS/REJECT | VERIFICATION | HYBRID | Auto-compute which ADRs are stale (assumption-diff); keep human on REJECT re-analysis | ADR-assumption-vs-GDD diff check |
| propagate-design-change | Per-ADR "Needs Review / Likely Superseded — ask the user what to do" | JUDGMENT | KEEP-HITL | — (how to resolve a stale ADR = design decision) | — |
| propagate-design-change | "May I write the change impact report?" | MECHANICAL | AUTOMATE | Auto-write derived impact report | impact-report schema check |
| prototype | Intent confirm `AskUserQuestion` (Prototype / Skip) | COORDINATION | AUTOMATE | Auto-proceed to prototype when invoked in-flow; skip is rare opt-out | invocation-context check |
| prototype | Path selection (HTML/Engine/Paper) + "confirmation before building" | JUDGMENT | HYBRID | Auto-recommend path from game-type; keep build-go confirm light | path-fit heuristic |
| prototype | PROCEED/PIVOT/KILL verdict — "Their verdict is final" | JUDGMENT | KEEP-HITL | — (is-the-idea-worth-pursuing = core taste verdict) | — |
| prototype | "May I write this report to REPORT.md / PIVOT-NOTE.md?" | MECHANICAL | AUTOMATE | Auto-write the throwaway report once verdict captured | report-template schema check |

## Notes

**Already autonomous / no human gate (objective, read-only):**
- **asset-audit** — read-only, objective `COMPLIANT/WARNINGS/NON-COMPLIANT` verdict from naming/size/format rules. No human approval gate. (Has a closing widget only in some skills; this one writes nothing.)
- **localize** scan/validate/RTL sub-modes — read-only, objective; only the write-modes and freeze/ship sign-offs have gates (rows above).

**AMBIGUOUS — owner confirmation needed:**
- **adopt** review-mode selection (Lean/Full/Solo → `review-mode.txt`): this choice configures the human-oversight policy for ALL downstream skills. Automating it (picking a default) is a meta-decision about how much HITL the studio wants. Owner must set the default, since `solo`/`lean` themselves are the levers that turn other gates off — do not auto-pick.

**Cross-cutting caveat (applies to every director-gate row marked HYBRID/KEEP):**
`solo`/`lean` mode SKIPS director gates — that is dropping verification, which the task forbids as an automation lever. For any AUTOMATE on a director touchpoint, the lever is "convert verdict to objective pass/fail sub-criteria the orchestrator blocks on," NOT "set solo mode." Subjective verdicts (PROCEED/PIVOT/KILL, go/no-go, "feels good", design APPROVED) remain KEEP-HITL.
