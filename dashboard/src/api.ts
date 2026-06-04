import { useEffect, useState } from "react";

import type { OrcaState } from "./types";

async function fetchState(): Promise<OrcaState> {
  const r = await fetch("/api/state");
  if (!r.ok) throw new Error("scan failed: " + r.status);
  return r.json();
}

export interface Live {
  state: OrcaState | null;
  error: string | null;
  loading: boolean;
  pulse: number; // bumps on every live refresh, for a visual heartbeat
}

// Loads state once, then re-fetches whenever the SSE stream reports a change.
export function useOrcaState(): Live {
  const [state, setState] = useState<OrcaState | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [pulse, setPulse] = useState(0);

  useEffect(() => {
    let alive = true;
    const refresh = (bump: boolean) =>
      fetchState()
        .then((s) => {
          if (!alive) return;
          setState(s);
          setError(null);
          setLoading(false);
          if (bump) setPulse((p) => p + 1);
        })
        .catch((e) => {
          if (!alive) return;
          setError(String(e));
          setLoading(false);
        });

    refresh(false);
    const es = new EventSource("/api/stream");
    es.addEventListener("change", () => refresh(true));
    es.onerror = () => {
      /* EventSource auto-reconnects */
    };
    return () => {
      alive = false;
      es.close();
    };
  }, []);

  return { state, error, loading, pulse };
}
