# orca principles

The standing lenses that **generate** decisions. A principle is timeless and reusable;
a decision (see `.orca/decisions.md`) is a dated, point choice justified *by* these.
Keep them separate — mixing chronology into principles dilutes both.

This is a living doc. Add a principle only once it has earned its keep (ideally it
already settled 2+ decisions). State the principle, then *why*, then its *test*.

---

## 1. Files are state; views are derived on read

Nothing computed is stored. `orca now`, `trail`, `report` are *rendered* from the
files when asked. **Why:** stored-derived data desyncs; recomputing can't. **Test:**
if a feature caches a view, it's wrong — derive it instead.

## 2. One writer per file

Each ark owns its own file. **Why:** no shared write → no races → no locks, no
scheduler, no lifecycle machine. That stack is what killed the previous orca.
**Test:** if two actors must write the same file, redesign so each owns its own.

## 3. Meaning lives in directory + content, never in the filename

Kind is encoded by **location** (`arks/*.md`, `arks/archive/*.md`, `threads/*.md`);
attributes by **fields** in the file. The filename is the **slug** — a stable
identity, nothing more. **Why:** commands address by `<slug>`; encoding date/type/
suffix into the name forces either indirection (slug ≠ filename) or ugly slugs, and
duplicates what the dir already says. **Test:** before putting metadata in a
filename, ask "does the directory or a field already carry this?" — it almost always
does. *(Settled the date-prefix, the type-tag, and the `.orca.md`-suffix questions.)*

> **Corollary for tooling (dashboards, exporters):** consume orca's *structure*, not
> filename patterns — registry (`~/.orca/`) → project roots → `.orca/` topology →
> parse the schema (header fields, `## sessions`, anchors). The registry is a better
> index than any glob, and a tool must understand the schema regardless of filename,
> so a suffix buys nothing on the hard part and breaks the moment a slug has a dot.
> A filename glob is what you reach for when you lack a structured index; orca has one.

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
**Why:** keeps the session from bloating, and it's load-bearing — a session maps to
exactly one ark by construction, which defines away the cross-ark attribution/demux
problem instead of solving it with machinery. **Test:** "is this the current ark's
work?" If no → park it, don't do it now. *(A strong default, not a hard lock: an
urgent interrupt may switch — but switching is named, not silent.)*

---

## Parking lot (principle candidates — not yet earned)

- *(none yet — promote here only after a candidate has shaped real decisions)*
