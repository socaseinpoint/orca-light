# ark: external-pointers

focus: 06-design-backlog
intent: surface published/external artifacts (a Pages URL, a deployment, a SaaS link) as side-effects in the dashboard — the "result, outside" the landing promises but the 3 checkable anchor types can't hold. Derived-only; core anchor grammar frozen.
state: in-work
updated: 2026-06-04

## done-when
- dashboard `scan.ts` harvests `http(s)://` links from each Trail block's text (done/why/next/head), across focus + arks, deduped, as a `link`-type side-effect.
- the SideEffects panel renders links with their own icon; links carry no verify status (pointer, ok=null) — never run, never break verify.
- `bin/orca` has zero diff (no ANCHOR_RE change).
- 04-site Trail backfilled with the live Pages URL so it shows up.

## Trail
<!-- append-only, newest LAST -->

### 2026-06-04 — published URLs surface as link side-effects
done: Dashboard `scan.ts` now harvests `http(s)://` URLs from every Trail block's text (done/why/next/head), across focus + arks, deduped into `link`-type side-effects (ok=null pointer, never verified, never breaks anything). The SideEffects panel renders them with a ↗ icon as clickable `<a>`. Backfilled 04-site's Pages URL — verified live: 04-site shows 1 link side-effect `https://socaseinpoint.github.io/orca-light/`. `bin/orca` diff is EMPTY — core anchor grammar frozen. [commit:eff5ab2] [file:dashboard/server/scan.ts:79]
why: Chose a derived dashboard harvest over a new core anchor type — adding `[url:...]` to ANCHOR_RE would let an unverifiable pointer into the verify path and dilute "fake anchor → verify fails." A bare URL in prose stays prose; the dashboard (network-allowed, derived) surfaces it. Pointer-type carries no verify status by design — it's the "labeled, not proven" kind.
next: ark done. Pages URL still needs a real-device render check (that's 04-site's done-when 4, not this ark).
head: core untouched across the whole feature — the disciplined call held. Watch: URL_RE trims trailing punctuation so "see https://x/." drops the dot.
