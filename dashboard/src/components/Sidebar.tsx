import type { Focus, OrcaState } from "../types";
import { StateBadge } from "./Badge";

interface Props {
  state: OrcaState;
  selectedId: string | null;
  onSelect: (focus: Focus) => void;
}

// The MAP view: projects → focuses → arks, in-work above done.
export function Sidebar({ state, selectedId, onSelect }: Props) {
  return (
    <nav className="map">
      {state.projects.map((p) => {
        const work = p.focuses.filter((f) => f.state === "in-work");
        const done = p.focuses.filter((f) => f.state === "done");
        return (
          <div className="map-proj" key={p.path}>
            <div className="map-proj-h">
              <span className="map-proj-name">{p.name}</span>
              <span className="map-proj-meta">
                {work.length}<span className="dim"> · {done.length} done</span>
              </span>
            </div>
            {[...work, ...done].map((f) => (
              <button
                key={f.dir}
                className={`map-focus${f.dir === selectedId ? " is-sel" : ""}${f.state === "done" ? " is-done" : ""}`}
                onClick={() => onSelect(f)}
              >
                <div className="map-focus-top">
                  <span className="map-focus-id">{f.id}</span>
                  <StateBadge state={f.state} />
                </div>
                <div className="map-focus-name">{f.name}</div>
                {f.arks.length > 0 && (
                  <div className="map-arks">
                    {f.arks.map((a) => (
                      <span key={a.slug} className={`map-ark map-ark--${a.state === "done" ? "done" : "work"}`}>
                        {a.state === "done" ? "✓" : "▸"} {a.slug}
                      </span>
                    ))}
                  </div>
                )}
              </button>
            ))}
          </div>
        );
      })}
    </nav>
  );
}
