# decisions — orca-light

Why this repo's code is the way it is.
- 2026-06-04 — archive moves the ark to arks/archive/ instead of flipping a state: field — location is the single terminal truth (no two-store drift); live views already glob arks/*.md flat so archived arks drop out for free, and ls shows only live work
