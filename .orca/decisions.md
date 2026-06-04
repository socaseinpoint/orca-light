# decisions — orca-light

Why this repo's code is the way it is.
- 2026-06-04 — archive moves the ark to arks/archive/ instead of flipping a state: field — location is the single terminal truth (no two-store drift); live views already glob arks/*.md flat so archived arks drop out for free, and ls shows only live work
- 2026-06-04 — per-project resume is the spine; cross-project `now` is an opt-in lens on top, NOT the default. global itself was not the mistake — the mistake was putting the cross-project roll-up on the trust-critical path by default (which is what spawns ark-root/path-mangling/warn/the launch-dir seam). default resume should take the pwd repo with no mangling (no seam); the cross-project view becomes an explicit opt-in (`now --all`). keep the global binary; take the global registry off the hot path
