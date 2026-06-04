# ark: 01-collapse-binary

focus: 01-finish-orca
intent: make the orca binary + resume skill speak the project-local focus-dir model, and strip every cross-project concept from the surface.
state: in-work
updated: 2026-06-04

## done-when
- `orca now` reads the local `.orca/` only: shows the in-work focus's `## Now` + its open arks; when several focuses are in-work, list all (no cross-project flat list).
- `orca` writes nothing under `~/.orca` — registry, `ark-root`, and transcript path-mangling are removed from the binary and the resume skill.
- marking an ark done appends a line to its focus's `## Log`; marking a focus done moves its dir to `.orca/done/`.
- the legacy `.orca/arks/verify-resume.md` and global `.orca/decisions.md` are migrated into `01-finish-orca/` (verify-resume → a done ark, since its deliverable is done).
- `orca verify` still checks `done:` anchors in any focus/ark file (anchor types stay format-agnostic).

## Trail
### 2026-06-04
done: collapsed the binary + skill to the project-local focus-dir model — all five done-when met. [commit:d0ff769] [file:bin/orca:831] [test:bash tests/test_views.sh]
why:  one rewrite was cleaner than incremental edits since the topology change (threads+registry → focuses) was pervasive; verify scoped to the latest Trail block because an accumulating trail can't keep historical file:line anchors green, while commit anchors are immutable.
next: ark complete — finish it with `orca done`. Remaining focus work: refresh docs (README/GUIDE/PRINCIPLES/spec) to the focus model — a separate ark.
head: tooling now MATCHES the hand-written focus format; 10/10 suites green. The done-only-latest-block verify rule is the one behavior worth watching as the Trail grows across sessions.
