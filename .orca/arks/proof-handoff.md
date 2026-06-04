# ark: proof-handoff

thread: build-orca-light
intent: make session handoffs trustworthy, then build the lightest continuity layer on top
done-when: verify catches every fabrication mode; views render from files; hooks wired
state: active
updated: 2026-06-04

## decisions
- Trust core is a verifier, not generated prose: the model writes the handoff, a
  deterministic check rejects fake anchors. Confabulation is caught, not trusted.
- Python (not bash) for the CLI — old orca died on a bash heredoc bug; parsing is safer.
- Now/Open/Trail are derived (freshness / not-archived / merged handoffs), never stored
  fields — so there is nothing to flip, desync, or lock. Partition + derivation.
- Hooks warn, never hard-block; CLI never writes config. Config is tuning, not architecture.

## handoff
- Scaffolded standalone repo with git init; first commit is the trust core. [commit:7706ebc]
- Self-hosting ark added in the second commit. [commit:b6439c1]
- `orca verify` parses inline anchors and checks each against reality. [file:bin/orca:36]
- File anchors verify the path exists and the line is in range. [file:bin/orca:83]
- Bare handoff bullets (prose with no anchor) are flagged and fail the run. [file:bin/orca:131]
- `orca init` scaffolds meta-tier ~/.orca + project .orca. [file:bin/orca:271]
- `orca day/glance/report` compute views from arks and threads on read. [file:bin/orca:317]
- Handoff + thread formats and the anchor-durability caveat are specified. [file:spec/handoff.md:1]
- The verifier proof passes every fabrication case. [test:bash tests/test_verify.sh]
- The views proof renders correctly from files with no stored state. [test:bash tests/test_views.sh]
