import type { SideEffect } from "../types";

// The reachable side-effect index: every anchor this focus produced — across its
// own Trail AND its arks' Trails — deduped and grouped by type. Anchors buried in
// a closed ark surface here, so a shipped outcome is never out of reach.
const ICON: Record<string, string> = { commit: "◆", file: "▤", test: "▷", unknown: "•" };
const TYPE_ORDER: SideEffect["type"][] = ["commit", "file", "test", "unknown"];

export function SideEffects({ items }: { items: SideEffect[] }) {
  if (items.length === 0) return null;
  const groups = TYPE_ORDER.map((t) => ({ type: t, list: items.filter((s) => s.type === t) })).filter(
    (g) => g.list.length > 0,
  );

  return (
    <section className="sfx">
      <div className="tl-section-k">side-effects · {items.length}</div>
      {groups.map((g) => (
        <div className="sfx-group" key={g.type}>
          <span className="sfx-type">
            {ICON[g.type]} {g.type} · {g.list.length}
          </span>
          <div className="sfx-list">
            {g.list.map((s) => (
              <Effect key={s.raw} s={s} />
            ))}
          </div>
        </div>
      ))}
    </section>
  );
}

function Effect({ s }: { s: SideEffect }) {
  const cls = s.ok === true ? "ok" : s.ok === false ? "bad" : "na";
  const title = s.ok === null ? "not checked (test)" : s.ok ? "verified" : "broken";
  return (
    <div className="sfx-row">
      <span className={`anchor anchor--${cls}`} title={title}>
        <span className="anchor-i">{ICON[s.type] || "•"}</span>
        {s.value}
      </span>
      <span className="sfx-src">{s.sources.join("  ·  ")}</span>
    </div>
  );
}
