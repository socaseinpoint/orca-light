import type { Focus } from "../types";
import { StateBadge } from "./Badge";
import { TrailBlock } from "./TrailBlock";

// The TIMELINE view: a focus's intent + done-when, then the session chain
// (Trail blocks rendered newest-first) and the ark-transition Log.
export function Timeline({ focus }: { focus: Focus }) {
  return (
    <div className="tl">
      <header className="tl-head">
        <div className="tl-kicker">{focus.id} · {focus.dir.split("/").slice(-3, -1).join("/")}</div>
        <h1 className="tl-title">
          {focus.name} <StateBadge state={focus.state} />
        </h1>
        {focus.intent && <p className="tl-intent">{focus.intent}</p>}

        <div className="tl-meta">
          {focus.doneWhen.length > 0 && (
            <div className="tl-dw">
              <span className="tl-meta-k">done-when</span>
              <ol>
                {focus.doneWhen.map((d, i) => (
                  <li key={i}>{d}</li>
                ))}
              </ol>
            </div>
          )}
          {focus.arks.length > 0 && (
            <div className="tl-dw">
              <span className="tl-meta-k">arks</span>
              <ul className="tl-arks">
                {focus.arks.map((a) => (
                  <li key={a.slug} className={a.state === "done" ? "done" : "work"}>
                    <span className="tl-ark-mark">{a.state === "done" ? "✓" : "▸"}</span>
                    <b>{a.slug}</b> {a.note && <span className="dim">— {a.note}</span>}
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>

        {focus.now && (
          <div className="tl-now">
            <span className="tl-meta-k">now</span>
            <p>{focus.now}</p>
          </div>
        )}
      </header>

      <section className="tl-chain">
        <div className="tl-section-k">session chain · {focus.trail.length}</div>
        {focus.trail.length === 0 ? (
          <p className="tl-empty">No Trail blocks yet — this focus hasn't been handed off.</p>
        ) : (
          // Newest first: reverse the file-order (append-only, newest last) for display.
          [...focus.trail].reverse().map((b, i, arr) => (
            <TrailBlock key={arr.length - 1 - i} block={b} last={i === arr.length - 1} />
          ))
        )}
      </section>

      {focus.log.length > 0 && (
        <section className="tl-log">
          <div className="tl-section-k">ark log</div>
          {focus.log.map((l, i) => (
            <div className="tl-log-row" key={i}>
              <span className="tl-log-date">{l.date}</span>
              <span className="tl-log-text">{l.text}</span>
            </div>
          ))}
        </section>
      )}

      {focus.decisions.length > 0 && (
        <section className="tl-log">
          <div className="tl-section-k">decisions · {focus.decisions.length}</div>
          {focus.decisions.map((d, i) => (
            <div className="tl-dec" key={i}>{d}</div>
          ))}
        </section>
      )}
    </div>
  );
}
