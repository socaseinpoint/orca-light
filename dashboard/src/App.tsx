import { useEffect, useMemo, useState } from "react";

import { useOrcaState } from "./api";
import { Sidebar } from "./components/Sidebar";
import { Timeline } from "./components/Timeline";
import type { Focus } from "./types";

export function App() {
  const { state, error, loading, pulse } = useOrcaState();
  const [selectedDir, setSelectedDir] = useState<string | null>(null);

  // All focuses flattened, for selection + counts.
  const focuses = useMemo<Focus[]>(
    () => (state ? state.projects.flatMap((p) => p.focuses) : []),
    [state]
  );

  // Auto-select the freshest in-work focus once data lands (only if nothing chosen,
  // or the chosen focus disappeared after a re-scan).
  useEffect(() => {
    if (!focuses.length) return;
    const stillThere = focuses.some((f) => f.dir === selectedDir);
    if (!stillThere) {
      const firstWork = focuses.find((f) => f.state === "in-work") || focuses[0];
      setSelectedDir(firstWork.dir);
    }
  }, [focuses, selectedDir]);

  const selected = focuses.find((f) => f.dir === selectedDir) || null;
  const work = focuses.filter((f) => f.state === "in-work").length;

  return (
    <div className="app">
      <header className="bar">
        <div className="bar-l">
          <span className="bar-brand"><b>~</b> orca</span>
          <span className="bar-sub">dashboard</span>
        </div>
        <div className="bar-r">
          {state && (
            <>
              <span className="bar-stat">{state.projects.length} <span className="dim">projects</span></span>
              <span className="bar-stat">{work} <span className="dim">in-work</span></span>
              <span className="bar-root" title={state.root}>{state.root}</span>
              <span className={`live${pulse ? " live--beat" : ""}`} key={pulse}>● live</span>
            </>
          )}
        </div>
      </header>

      {loading && <div className="center dim">scanning .orca/ …</div>}
      {error && <div className="center err">scan error: {error}</div>}
      {state && state.projects.length === 0 && !loading && (
        <div className="center dim">
          No <code>.orca/</code> stores found under <code>{state.root}</code>.<br />
          Set <code>ORCA_SCAN_ROOT</code> to point elsewhere.
        </div>
      )}

      {state && state.projects.length > 0 && (
        <main className="grid">
          <aside className="pane pane-map">
            <Sidebar state={state} selectedId={selectedDir} onSelect={(f) => setSelectedDir(f.dir)} />
          </aside>
          <section className="pane pane-tl">
            {selected ? <Timeline focus={selected} /> : <div className="center dim">pick a focus →</div>}
          </section>
        </main>
      )}
    </div>
  );
}
