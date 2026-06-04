# ark: 02-docs-refresh

focus: 01-finish-orca
intent: rewrite the user-facing docs to the project-local focus-dir model — README, GUIDE, PRINCIPLES, spec/handoff, spec/resume, bench — so nothing still describes threads / ~/.orca / archive / cross-project.
state: in-work
updated: 2026-06-04

## done-when
- no doc references the cut concepts: threads, `~/.orca`, registry, `ark-root`, `report`, `now --all`, or `orca archive` (the command is `orca done`).
- README + GUIDE describe the live surface (`init · now · verify · decide · trail · done · gate`) and the focus-dir topology (`.orca/NN-name/{focus.md,decisions.md,arks/}`, done at `.orca/done/`).
- spec/handoff + spec/resume describe the `## Trail` block (done/why/next/head) and the latest-block verify rule.
- the test suite stays green (docs don't touch code, but resume-skill assertions must still hold).

## Trail
<!-- append-only, newest LAST -->
### 2026-06-04
done: Rewrote all six docs to the focus-dir model — README/GUIDE/PRINCIPLES/spec(handoff,resume)/bench. No doc references threads/~/.orca/registry/ark-root/report/archive except to say they're gone. [commit:1bebfeb] [test:bash bench/run.sh]
why: Four prose docs went to parallel subagents with one shared authoritative model brief (consistent vocabulary, no drift); PRINCIPLES + bench done by hand since principles are timeless (only location/command examples changed) and bench needed real fixtures. bench B2/B4/B5 all green prove the rewrite's commands actually run.
next: ark done. Focus 01-finish-orca's done-when 1–4 are all met + docs current — the focus itself is a candidate for `orca done` (user's call on whether orca is "finished").
head: all 10 test suites + bench green on the new model end to end.

## Log
