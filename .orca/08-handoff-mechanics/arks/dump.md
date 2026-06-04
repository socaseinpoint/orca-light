# ark: dump

focus: 08-handoff-mechanics
intent: make the handoff VISIBLE so "is everything important transferred?" stops being faith-based. Two inspectable views — what offload writes, what load reads.
state: in-work
updated: 2026-06-04

## done-when
- dump-offload: a dry-run that renders the Trail block flush/recovery WOULD write (from transcript + git since last anchor) WITHOUT committing — so a human can read/edit before it lands.
- dump-load: one artifact serializing the full payload the next agent will READ — every in-work focus + its Now + open arks + last Trail blocks + pending sessions. ("everything being transferred" in one view; today partly = `now` + `trail`, but assembled whole.)
- read-only / derived — touches no anchor grammar, runs `bin/orca` not at all or as a derived view only (flag the call: keep out of core, or argue it in as a pure read view like `now`).

## context
The keystone worry it answers: a verified handoff still might omit a nuance — verify checks anchors (facts), not narrative completeness. dump can't prove completeness either, but it makes the payload READABLE so a human can judge it in one glance instead of trusting a black box.

## Trail
<!-- append-only, newest LAST -->
