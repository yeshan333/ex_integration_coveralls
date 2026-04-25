# Release Demo

[中文文档](README_CN.md)

Demonstrates `ex_integration_coveralls` in a `mix release` context, including multi-app coverage collection via `dep_apps`.

## Project Structure

```
examples/
├── dep_lib/          # A small dependency library (coverage target)
│   ├── mix.exs
│   └── lib/dep_lib.ex
└── release_demo/     # Main OTP app
    ├── mix.exs       # depends on ex_integration_coveralls + dep_lib
    ├── smoke_test.sh # end-to-end HTTP API smoke tests
    ├── config/
    └── lib/
```

`release_demo` depends on `dep_lib` via `path: "../dep_lib"`. Both are packaged into the same release and can be instrumented for coverage together.

## Quick Start

```bash
cd examples/release_demo

# Install dependencies
mix deps.get

# Build the release
MIX_ENV=prod mix release

# Start the release (background)
_build/prod/rel/release_demo/bin/release_demo daemon

# Run the smoke tests
bash smoke_test.sh

# Stop the release
_build/prod/rel/release_demo/bin/release_demo stop
```

## HTTP API

### Single-App Coverage

```bash
# Start coverage for release_demo only
curl -X POST http://localhost:3333/cov/start \
  -H 'Content-Type: application/json' \
  -d '{"app_name": "release_demo"}'

# Get total coverage
curl http://localhost:3333/cov/total/release_demo
```

### Multi-App Coverage (dep_apps)

Collect coverage across `release_demo` and its dependency `dep_lib` in a single session:

```bash
# Start coverage for release_demo + dep_lib
curl -X POST http://localhost:3333/cov/start \
  -H 'Content-Type: application/json' \
  -d '{"app_name": "release_demo", "dep_apps": ["dep_lib"]}'

# Get merged total coverage (query param: comma-separated)
curl http://localhost:3333/cov/total/release_demo?dep_apps=dep_lib

# Get detailed report with files from both apps
curl http://localhost:3333/cov/report/release_demo?dep_apps=dep_lib
```

### Other Endpoints

```bash
# Health check
curl http://localhost:3333/ping

# Cover server status
curl http://localhost:3333/cov/status
```

## Elixir API (via remote console)

```bash
_build/prod/rel/release_demo/bin/release_demo remote
```

```elixir
# Single app
ExIntegrationCoveralls.start_app_cov("release_demo")
ExIntegrationCoveralls.get_app_total_cov("release_demo")

# Multi-app with dep_apps
ExIntegrationCoveralls.start_app_cov("release_demo", dep_apps: ["dep_lib"])
ExIntegrationCoveralls.get_app_total_cov("release_demo", dep_apps: ["dep_lib"])
```

## Release Configuration Notes

### Source Files Must Be Included

`ex_integration_coveralls` reads source files at runtime to compute line-level coverage. In a `mix release`, source files are **not** included by default — only compiled `.beam` files are packaged.

This demo solves it with a custom release step in `mix.exs`:

```elixir
releases: [
  release_demo: [
    strip_beams: [keep: ["Docs", "Dbgi"]],
    steps: [:assemble, &copy_app_sources/1]
  ]
]

defp copy_app_sources(release) do
  release_lib = Path.join(release.path, "lib")
  for {app, src} <- [{:release_demo, "lib"}, {:dep_lib, "../dep_lib/lib"}] do
    [target] = Path.wildcard(Path.join(release_lib, "#{app}-*"))
    File.cp_r!(src, Path.join(target, "lib"))
  end
  release
end
```

### Debug Info Must Be Preserved

The `strip_beams: [keep: ["Docs", "Dbgi"]]` option preserves the `Dbgi` chunk in beam files. This is required for `ex_integration_coveralls` to resolve compile-time source paths in release environments where `module_info(:compile)` is stripped.

### Configuration

Port can be set via `COV_PORT` environment variable (default: 3333):

```bash
COV_PORT=4000 _build/prod/rel/release_demo/bin/release_demo start
```
