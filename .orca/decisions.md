# decisions — orca-light

Why this repo's code is the way it is.
- 2026-06-04 — archive moves the ark to arks/archive/ instead of flipping a state: field — location is the single terminal truth (no two-store drift); live views already glob arks/*.md flat so archived arks drop out for free, and ls shows only live work
- 2026-06-04 — per-project resume — это позвоночник, cross-project now — опциональная линза сверху, НЕ дефолт. global сам по себе не ошибка; ошибка была что ролл-ап стоит дефолтом на критичном-к-доверию пути (отсюда ark-root/мангление/warn/шов). дефолтный resume должен брать pwd-репо без мангления (шва нет); кросс-проектный вид — явный опт-ин (now --all). global бинарь оставить, global реестр снять с горячего пути
