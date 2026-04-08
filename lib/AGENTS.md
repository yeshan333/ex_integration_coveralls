# lib/ — Core Coverage Analysis Modules

## OVERVIEW
All coverage analysis logic lives here. **Non-standard**: core modules flat in `lib/` root, only runtime OTP services in `lib/ex_integration_coveralls/`.

## WHERE TO LOOK
| Module | Purpose |
|--------|---------|
| `ex_integration_coveralls.ex` | Public API entry — `start_app_cov`, `get_app_total_cov`, `post_app_cov_to_ci` |
| `cover.ex` | `:cover` Erlang module wrapper — start/stop coverage per app |
| `stats.ex` | Largest file (7.3K) — line-level filtering, aggregation, report generation |
| `path_reader.ex` | `.beam` → `.ex/.erl` source path resolution for released modules |
| `poster.ex` | Generic HTTP poster for CI service uploads |
| `coverage_ci_poster.ex` | Coveralls.io integration — converts internal format → Coveralls JSON |
| `json.ex` | Poison encoding helpers (Elixir.Hello, CoverageCIExCoveralls, etc.) |

## STRUCTURE
```
lib/
├── ex_integration_coveralls/     # OTP runtime (Application, Router, Worker)
│   ├── application.ex            # mod:{} entry, starts Cowboy + optional worker
│   ├── cov_stats_router.ex       # Plug router — :3333 API endpoints
│   └── cov_stats_worker.ex       # GenServer — ETS stats cache
├── cover.ex                      # :cover.start/ :cover.stop/ wrapper
├── stats.ex                      # Coverage filtering + report builder
├── path_reader.ex                # BEAM → source path resolver
├── poster.ex                     # HTTP POST wrapper
├── coverage_ci_poster.ex         # Coveralls JSON converter
├── json.ex                       # Poison encoding
└── ex_integration_coveralls.ex   # Public API facade
```

## CONVENTIONS
- **Flat module split**: Domain logic (cover/stats/path/poster) flat at `lib/` root. OTP boot/runtime (app/router/worker) namespaced under `lib/ex_integration_coveralls/`.
- All public API exposed via `ExIntegrationCoveralls` module — `cover.ex`/`stats.ex`/`poster.ex` are internal, not for direct consumption.

## ANTI-PATTERNS (THIS DIR)
- Do NOT mix runtime OTP modules with standalone logic modules.
- `path_reader.ex` assumes source code exists in release package — fails silently otherwise.
