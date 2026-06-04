import type { Anchor, State } from "../types";

export function StateBadge({ state }: { state: State }) {
  return <span className={`badge badge--${state === "in-work" ? "work" : "done"}`}>{state}</span>;
}

const ICON: Record<string, string> = { commit: "◆", file: "▤", test: "▷", unknown: "•" };

export function AnchorPill({ a }: { a: Anchor }) {
  const cls = a.ok === true ? "ok" : a.ok === false ? "bad" : "na";
  return (
    <span className={`anchor anchor--${cls}`} title={a.ok === null ? "not checked (test)" : a.ok ? "verified" : "broken"}>
      <span className="anchor-i">{ICON[a.type] || "•"}</span>
      {a.type}:{a.value}
    </span>
  );
}
