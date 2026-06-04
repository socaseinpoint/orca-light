# Wiring orca-light hooks

Three hooks, all read-only, none hard-block, none mutate state. They are **additive**
to whatever ECC / other hooks you already run — append to the arrays, don't replace.

| Hook | Script | Effect |
|---|---|---|
| SessionStart | `session-start.sh` | injects `orca now` as context |
| Stop | `stop.sh` | `orca verify --no-tests`, warns if the handoff's anchors don't hold |
| PreCompact | `pre-compact.sh` | flushes `orca now` so the "why" survives compaction |

`--no-tests` keeps Stop latency low (no test re-runs on every stop). Run full
`orca verify` by hand when trust matters.

## settings.json snippet

Paste into `~/.claude/settings.json` (via `/config`), merging into existing hook
arrays. Replace `ORCA_LIGHT` with this repo's absolute path.

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "ORCA_LIGHT/hooks/session-start.sh" } ] }
    ],
    "Stop": [
      { "hooks": [ { "type": "command", "command": "ORCA_LIGHT/hooks/stop.sh" } ] }
    ],
    "PreCompact": [
      { "hooks": [ { "type": "command", "command": "ORCA_LIGHT/hooks/pre-compact.sh" } ] }
    ]
  }
}
```

Or put `ORCA_LIGHT/bin` on PATH and the scripts resolve `orca` from there.

The CLI itself never writes config. Wiring is a human step (`/config`), by design:
config is tuning, not architecture.
