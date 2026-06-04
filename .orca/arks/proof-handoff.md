# ark: proof-handoff

thread: build-orca-light
intent: make session handoffs trustworthy before building anything on top of them
done-when: `orca verify` catches every fabrication mode and passes on a real ark
state: active
updated: 2026-06-04

## decisions
- Trust core is a verifier, not generated prose: the model writes the handoff, a
  deterministic check rejects fake anchors. Confabulation is caught, not trusted.
- Python (not bash) for the CLI — old orca died on a bash heredoc bug; parsing is safer.
- `[test:]` anchors re-run by default (that is the whole point of proving "tests green");
  `--no-tests` for the fast file/commit-only path.

## handoff
- Scaffolded standalone repo `orca-light` with `git init`; first commit is the trust core. [commit:7706ebc]
- `orca verify` parses inline anchors and checks each against reality. [file:bin/orca:26]
- File anchors verify the path exists and the line is in range. [file:bin/orca:88]
- Bare handoff bullets (prose with no anchor) are flagged and fail the run. [file:bin/orca:154]
- Handoff format is specified for future sessions. [file:spec/handoff.md:1]
- The verifier proof passes all cases, so the layer is trustworthy. [test:bash tests/test_verify.sh]
