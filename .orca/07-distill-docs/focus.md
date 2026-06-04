# focus 07: distill docs

intent: a single editorial pass across every prose surface — cut the cruft, keep the essential, and make the ONE idea unmistakable. orca's docs accreted build-logs and internal bookkeeping that read like a changelog, not a product. Strip that; surface what actually matters (trust = facts checked + story labeled; state = files, project-local like .git/); kill anything a reader doesn't need.
kind: finite
state: in-work
updated: 2026-06-04

## done-when
1. README.md — the internal "Status"/build-checklist section (and any changelog-ish bookkeeping) is gone; the one idea + trust model + minimal command surface lead. Reads like a product, not a worklog.
2. PRINCIPLES.md + GUIDE.md — trimmed to the load-bearing principles; redundancy with README and with each other removed; the ideology (why orca exists, what it refuses) sharpened.
3. spec/handoff.md + spec/resume.md — kept as the design rationale, but pruned of anything stale or duplicated; each says one thing well.
4. docs/index.html + docs/getstarted.html (landing) — copy audited for the same cuts; no internal jargon leaking onto the public face; bilingual RU/EN stays in sync.
5. one consistent message across ALL surfaces — no surface contradicts another on what orca is / isn't.

## Now
Scaffolded for a fresh agent — DO NOT treat as in-progress; nothing's been edited yet. The guiding cut: orca's prose grew build-log residue (e.g. README §Status = a ✓ checklist of "repo scaffold + bin/orca", "hooks installed" — internal readiness, not reader value → DELETE). Editorial rule: every surface leads with the IDEA (state is files, project-local like .git/; trust = facts checked, story labeled), states the minimal surface, names what orca is NOT, and stops. Cut: changelogs, readiness checklists, duplicated explanations, internal-process detail. Keep: the one idea, the trust model, the command surface, the use cases.

Surfaces (real paths to work): README.md · PRINCIPLES.md · GUIDE.md · spec/handoff.md · spec/resume.md · docs/index.html · docs/getstarted.html. Suggest one ark per surface (or per cluster) so cuts stay reviewable; `bin/orca` is NOT in scope — code untouched, prose only.

## arks
<!-- new agent: break down per surface, e.g. arks/readme.md, arks/principles-guide.md, arks/spec.md, arks/landing.md -->

## Trail
<!-- append-only, newest LAST -->

## Log
<!-- ark state transitions, append-only -->
