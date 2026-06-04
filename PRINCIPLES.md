# orca principles

The standing lenses that **generate** decisions. A principle is timeless and reusable;
a decision (see `.orca/decisions.md`) is a dated, point choice justified *by* these.
Keep them separate — mixing chronology into principles dilutes both.

This is a living doc. Add a principle only once it has earned its keep (ideally it
already settled 2+ decisions). State the principle, then *why*, then its *test*.

---

## 1. Files are state; views are derived on read

Nothing computed is stored. `orca now`, `trail`, `gate` are *rendered* from the
files when asked. **Why:** stored-derived data desyncs; recomputing can't. **Test:**
if a feature caches a view, it's wrong — derive it instead.

## 2. One writer per file

Each ark owns its own file. **Why:** no shared write → no races → no locks, no
scheduler, no lifecycle machine. That stack is what killed the previous orca.
**Test:** if two actors must write the same file, redesign so each owns its own.

## 3. Meaning lives in directory + content, never in the filename

State is encoded by **location** (in-work `.orca/<focus>/` and `<focus>/arks/*.md`;
done `.orca/done/<focus>/` and `<focus>/arks/done/*.md`); attributes by **fields**
in the file. The filename is the **slug** — a stable
identity, nothing more. **Why:** commands address by `<slug>`; encoding date/type/
suffix into the name forces either indirection (slug ≠ filename) or ugly slugs, and
duplicates what the dir already says. **Test:** before putting metadata in a
filename, ask "does the directory or a field already carry this?" — it almost always
does. *(Settled the date-prefix, the type-tag, and the `.orca.md`-suffix questions.)*

> **Corollary for tooling (dashboards, exporters):** consume orca's *structure*, not
> filename patterns — scan `.orca/` topology (focus dirs → `arks/` → done/ subdirs) →
> parse the schema (header fields, `## Trail` blocks, anchors). A tool must understand
> the schema regardless of filename, so a suffix buys nothing on the hard part and
> breaks the moment a slug has a dot. A filename glob is what you reach for when you
> lack a structured index; orca's directory layout *is* the index. (A cross-project
> overview is one such external tool — it scans many repos' `.orca/` dirs; orca core
> stays project-local and never learns it exists.)

## 4. Trust before convenience

A handoff is claims + checkable anchors, re-verified against reality; fabrication
goes red. Nothing is extended until the verify core is trustworthy. **Why:**
continuity you can't trust is worse than none — it misleads confidently. **Test:**
the proven zone (`done:`) must carry anchors; narrative (`why/next/head`) is labeled,
never pretended to be proven.

## 5. Serve the user's goal — convenient and clear — on the least machinery that works

The measure of any design call is "does it make the user's goal reachable,
conveniently and clearly," held in productive tension with "the lightest thing that
works." **Why:** "convenient" alone licenses bloat; "light" alone ships a clever tool
nobody can use. **Test:** does this make the goal reachable with the *fewest* moving
parts? If a primitive already covers it, don't add structure.

## 6. Human-initiated, no background

orca runs because a human invoked it — no timers, no daemon, no unattended agents.
**Why:** the prior transcript on disk is the durable source, so a hard exit can't
lose it; and a present human is the integration point (can confirm fuzzy inferences
instead of orca needing perfect recorded state). **Test:** if a feature needs to run
while nobody's watching, it doesn't belong — *until* this principle is deliberately
revisited (the explicit trigger for an inbox / questions-queue).

## 7. One session, one task (one ark)

A session works one ark. Tangents that surface are **parked** (a bare ark — intent +
done-when, no sessions), not pursued mid-session. Switching tasks is an *explicit*
act (new ark / new session), the path of least resistance is to stay focused.
**Why:** three reinforcing reasons. (1) keeps the session from bloating. (2)
load-bearing — a session maps to exactly one ark by construction, which defines away
the cross-ark attribution/demux problem instead of solving it with machinery. (3)
**compression fidelity** — a small session is a small transcript, so resume's
reconstruction has less to compress and drops less; bloated sessions lose detail at
the squeeze. The close→open loop sharpens this further: every session is *bracketed*
— an intro (the open-time where-you-stopped) and an outro (the close-time
summary/runway), both deposited in the transcript. They give the compressor a *frame*
(intent at start, claims at end) instead of inferring from the messy middle, and a
*self-check* (the reconstructed block must agree with both brackets). The outro is a
context-fresh summary the compressor **lifts and anchors** rather than reinventing
cold — so the close-nudge summary should be shaped like a handoff (done/why/next/head
+ candidate anchors), a clean seed in the transcript, not a hand-written block. Not
circular: the brackets are self-stated, but `orca verify` grounds their anchors
against git/files (#4), so a session that overclaims at its outro still goes red. **Test:** "is this the current ark's work?" If no → park it, don't do it
now. *(A strong default, not a hard lock: an urgent interrupt may switch — but
switching is named, not silent.)* **Mechanism:** orca *nudges* (never forces, per #6)
"looks done — finish it (`orca done`) and start fresh" when the ark's `done-when` is checkable and
green; stays silent when `done-when` can't be checked (no false nags, per #5). The
nudge **bundles the runway**: alongside "close the session" it surfaces where to pick
up next — the other open arks, parked (not-started) arks, and any residual `next:` —
so closing is never a dead end. You close *because* you can see the restart point.

## 8. orca teaches its own model — nudge correct use, don't just store files

orca understands its own idea and gently steers the user toward it. Its surfaces are
didactic by design: the fork (continue / finish+new / new) teaches the lifecycle;
`now`'s "where you stopped" models correct continuation; a red `verify` teaches
trust-before-convenience; the done-when nudge teaches one-session-one-task. A passive
filestore lets the user drift; orca makes the right move the obvious one. **Why:** the
principles only pay off if they're actually followed, and a human won't memorize them
— the tool should embody them at the moment of use. **Test:** at each invocation
checkpoint, does the output make the correct next move *obvious*? **Riders (or it
becomes a nag, breaking #5/#6):** nudges are *earned* — high precision, low frequency,
**reactive** (surfaced only when orca is invoked: `now` / `gate` / Stop-hook /
resume — never proactive, per #6), and silent when unsure. A nudge that fires wrong or
too often trains the user to ignore every nudge.

> **The close→open self-check loop.** The close-time runway ("next you'll continue
> with X") and the next session's where-you-stopped reminder ("you stopped at X") are
> derived from the *same files* (#1), so they agree **by construction** — orca isn't
> remembering a promise that could drift, both renders read one source. Close is a
> *prediction*, open is its *fulfillment*; the user watching them match earns trust
> and forms the habit, exactly as `orca verify` earns trust on anchors (#4). This is
> an emergent property of #1 + the nudge, not new machinery (#5).

---

## Parking lot (principle candidates — not yet earned)

- *(none yet — promote here only after a candidate has shaped real decisions)*
