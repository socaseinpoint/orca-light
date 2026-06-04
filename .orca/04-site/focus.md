# focus 04: site

intent: the public face of orca — a bilingual RU/EN landing page + get-started walkthrough, published via GitHub Pages from `docs/`. Distinct from the internal dashboard (03) and orca-core (02); this is the share-on-GitHub surface.
kind: finite
state: in-work
updated: 2026-06-04

## done-when
1. Bilingual RU/EN landing (`docs/index.html`) + get-started (`docs/getstarted.html`) exist and render.
2. Served by GitHub Pages from the `docs/` branch source (the `site/`→`docs/` move).
3. No mobile viewport overflow (the `pre`-block break is fixed and reaches clients).
4. Published Pages URL verified rendering on a real device.

## Now
Backfilled from the prior session that built it but recorded it in no focus. The landing + get-started pages are built, committed, and moved to `docs/` for Pages. Mobile overflow fixed + cache-busted. Open: confirm the live Pages URL renders on a real phone (done-when 4) and that the repo's Pages source is set to `docs/`.

## arks
<!-- - arks/<slug>.md — in-work — <one line> -->

## Trail
<!-- append-only, newest LAST -->

### 2026-06-04 — landing + get-started shipped to docs/ (backfilled)
done: Built a bilingual RU/EN orca landing page + get-started page, then moved `site/` → `docs/` so GitHub Pages serves from the branch source; fixed a mobile `pre`-block viewport overflow (min-width:0 grid children + wrap `pre` ≤640px) and cache-busted `style.css?v=2` so the fix reached clients. [commit:658876d] [commit:c3eb737] [commit:66f49e1] [commit:c4b7adf] [file:docs/index.html:1] [file:docs/getstarted.html:1]
why: The user wanted a public face for orca to share on GitHub — a clean bilingual landing + setup walkthrough, published via Pages (branch source = `docs/`), not the internal dashboard or orca-core. Mobile fixes + cache-bust followed from a real on-phone layout break the user flagged. Recorded here because this work belonged to no existing focus; resume backfilled it into a new `04-site` rather than losing the narrative.
next: verify the published Pages URL https://socaseinpoint.github.io/orca-light/ renders correctly on a real device (done-when 4); confirm repo Pages source points at `docs/`.
head: Tree clean, all four site commits on main. This work predated the dashboard anchor (22ec4c2) yet sat in neither flushed Trail block until now. Watch: GitHub Pages branch-source must point at `docs/` for the move to take effect.

## Log
<!-- ark state transitions, append-only -->
