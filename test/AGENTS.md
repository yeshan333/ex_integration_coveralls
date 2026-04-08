# test/ — ExUnit Test Suite

## OVERVIEW
ExUnit tests for coverage analysis library. **Unique**: `:real_cover` tag excluded by default; pre-compiled BEAM fixtures.

## STRUCTURE
```
test/
├── test_helper.exs                 # ExUnit.configure: excludes :real_cover, adds junit_formatter
├── cover_test.exs                  # Cover wrapper tests (module, functions, error handling)
├── stats_test.exs                  # Largest test (9.3K) — filtering, aggregation, report format
├── path_reader_test.exs            # BEAM→source path resolution tests
├── poster_test.exs                 # HTTP poster mock tests
├── coverage_ci_poster_test.exs      # Coveralls.io integration tests
├── ex_integration_coveralls_test.exs # Public API integration tests
├── json_test.exs                   # Poison encoding verification
└── fixtures/                       # Pre-compiled BEAM fixtures + nested OTP app
    ├── test_missing.ex              # Injected into elixirc_paths(:test) — tests missing source handling
    └── hello/                       # Pre-compiled Hello module
        ├── ebin/Elixir.Hello.beam   # BEAM file (source not here)
        ├── lib/hello.ex             # Original source
        └── src/hello.app            # App resource
```

## WHERE TO LOOK
| Test File | Covers | Key Deps |
|-----------|--------|----------|
| `stats_test.exs` | Line filtering, report generation, edge cases | Meck (for PathReader) |
| `cover_test.exs` | `:cover.start/stop/analyse/analyse_to_file` wrapper | Meck (for :cover, CoverStatsWorker, Stats) |
| `coverage_ci_poster_test.exs` | Coveralls JSON format conversion | Mock (for Poster) |

## CONVENTIONS
- **`:real_cover` exclusion**: Default test run excludes tests tagged `:real_cover`. Real coverage analysis tests need `mix test --include real_cover`.
- **Mock strategy**: Both `meck` and `mock` available as test deps. `mock` wraps `meck`; don't mix both in same test module.
- **JUnit output**: `junit_formatter` writes XML to `/tmp/report_file_test.xml`.
- **Test fixture injection**: `elixirc_paths(:test)` includes `test/fixtures/test_missing.ex` — enables testing of missing-source scenarios.

## ANTI-PATTERNS (THIS DIR)
- Do NOT use both `mock` AND `meck` in the same test file — pick one.
- Pre-compiled BEAM fixtures (`fixtures/hello/ebin/`) cannot be edited as source — recompile externally.
- Tests that import `Stats`/`PathReader`/`Cover` directly depend on their internal APIs.
