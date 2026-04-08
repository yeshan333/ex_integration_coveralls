# PROJECT KNOWLEDGE BASE

**Generated:** 2026-04-08
**Commit:** 0058d1e
**Branch:** main

## OVERVIEW
Run-time integration test coverage analysis for Elixir projects. Unlike compile-time tools (excoveralls), this starts an HTTP service (`:3333`) to collect coverage stats from running OTP releases via Erlang's `:cover` module. Published as Hex package `ex_integration_coveralls`.

## STRUCTURE
```
./
├── lib/                          # Core modules (FLAT — NOT under lib/app_name/)
│   ├── ex_integration_coveralls/ # OTP runtime services only (Application, Router, Worker)
│   ├── cover.ex                  # :cover wrapper — starts/stops coverage analysis
│   ├── stats.ex                  # Coverage stats collection, filtering, aggregation (7.3K, largest)
│   ├── path_reader.ex            # Module source path resolution vs beam files
│   ├── poster.ex                 # Coverage data poster to CI services
│   ├── coverage_ci_poster.ex     # Coveralls.io integration, report format conversion
│   ├── json.ex                   # Poison JSON encoding helpers
│   └── ex_integration_coveralls.ex # Public API — main entry module
├── test/                         # ExUnit tests + fixtures
│   ├── fixtures/                 # Pre-compiled BEAM fixtures (unusual — see NOTES)
│   └── test_helper.exs           # ExUnit.configure excludes :real_cover by default
├── config/                       # env configs + husky git hooks
└── examples/release_demo/        # Embedded demo OTP app for mix release integration
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Start/stop coverage on app | `lib/cover.ex` | Wraps `:cover.start/1`, `:cover.stop/0` |
| Collect coverage stats | `lib/stats.ex` | Line-level filtering, report generation |
| Find module source paths | `lib/path_reader.ex` | Handles `.beam` → `.ex/.erl` resolution |
| Post to Coveralls.io | `lib/coverage_ci_poster.ex` | Converts internal format → Coveralls JSON |
| HTTP API endpoints | `lib/ex_integration_coveralls/cov_stats_router.ex` | Plug router on :3333 |
| GenServer worker | `lib/ex_integration_coveralls/cov_stats_worker.ex` | ETS-based stats caching |
| Application boot | `lib/ex_integration_coveralls/application.ex` | Cowboy + optional worker |

## CONVENTIONS
- **Module placement split**: Core logic modules flat in `lib/`, runtime OTP services in `lib/ex_integration_coveralls/`. Intentional — exposes core as standalone lib, isolates HTTP service components.
- **Test exclusion**: `:real_cover` tag excluded by default in `test/test_helper.exs`. Real coverage tests require explicit `--include real_cover`.
- **elixirc_paths hack**: `test/fixtures/test_missing.ex` injected into compile paths for test env only (see `mix.exs` line 52).
- **Max line length**: 120 (`.credo.exs`).
- **No type spec requirement**: Credo specs disabled (opt-in only).

## ANTI-PATTERNS (THIS PROJECT)
- **Do NOT start the HTTP server for library-only usage** — `Application.start/2` binds `:3333`, conflicts if multiple instances.
- **Do NOT mix both `mock` + `meck` in same test module** — test-only deps include both (`mock` is wrapper around `meck`), use one.
- **`mix.exs` line 47**: `application: [:httpoison]` is an unrecognized key (should be under different config). Currently ineffective.
- **Test fixtures use pre-compiled BEAM files** (`test/fixtures/hello/ebin/`) — cannot edit source directly, must recompile externally.

## COMMANDS
```bash
mix test --cover --exclude real_cover   # Standard test run with coverage
mix coveralls                           # Detailed coverage report
mix coveralls.html                      # HTML coverage report
mix credo                               # Lint
mix format                              # Format (line 120 max)
mix docs                                # Generate docs
mix release ex_integration_coveralls    # Build OTP release
```

## NOTES
- `elixirc_paths(:test)` injects `test/fixtures/test_missing.ex` into compile path.
- Husky git hooks configured: `pre_commit` auto-formats + runs tests + credo; `pre_push` checks format + credo + tests.
- Coverage requires source code in release package (`lib/<app>/` directory must exist).
- `erl_crash.dump` present in repo root — normally gitignored.
