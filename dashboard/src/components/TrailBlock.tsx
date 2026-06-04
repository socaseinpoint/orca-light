import type { TrailBlock as Block } from "../types";
import { AnchorPill } from "./Badge";

// "2026-06-04T12:01:33+02:00" -> "12:01" in the viewer's local zone.
function hhmm(iso: string): string {
  const d = new Date(iso);
  return Number.isNaN(d.getTime())
    ? ""
    : d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", hour12: false });
}

// One node in the session chain: the 4-layer handoff block.
export function TrailBlock({ block, last }: { block: Block; last: boolean }) {
  return (
    <div className={`tb${last ? " is-last" : ""}`}>
      <div className="tb-rail">
        <span className="tb-dot" />
      </div>
      <div className="tb-body">
        <div className="tb-head">
          <span className="tb-date">{block.date}</span>
          {block.time && <span className="tb-time">{hhmm(block.time)}</span>}
          {block.title && <span className="tb-title">{block.title}</span>}
        </div>

        {block.done && (
          <div className="tb-layer proven">
            <span className="tb-k">done</span>
            <span className="tb-v">{block.done.replace(/\s*\[[^\]]+\]/g, "").trim()}</span>
          </div>
        )}
        {block.anchors.length > 0 && (
          <div className="tb-anchors">
            {block.anchors.map((a, i) => (
              <AnchorPill key={i} a={a} />
            ))}
          </div>
        )}
        {block.why && <Layer k="why" v={block.why} />}
        {block.next && <Layer k="next" v={block.next} />}
        {block.head && <Layer k="head" v={block.head} />}
      </div>
    </div>
  );
}

function Layer({ k, v }: { k: string; v: string }) {
  return (
    <div className="tb-layer orient">
      <span className="tb-k">{k}</span>
      <span className="tb-v dim">{v}</span>
    </div>
  );
}
