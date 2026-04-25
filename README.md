# ExIntegrationCoveralls

[中文文档](README_CN.md)

[![Coverage Status](https://coveralls.io/repos/github/yeshan333/ex_integration_coveralls/badge.svg?branch=main)](https://coveralls.io/github/yeshan333/ex_integration_coveralls?branch=main) [![hex.pm version](https://img.shields.io/hexpm/v/ex_integration_coveralls.svg)](https://hex.pm/packages/ex_integration_coveralls) [![hex.pm downloads](https://img.shields.io/hexpm/dt/ex_integration_coveralls.svg)](https://hex.pm/packages/ex_integration_coveralls) [![hex.pm license](https://img.shields.io/hexpm/l/ex_integration_coveralls.svg)](https://github.com/yeshan333/ex_integration_coveralls/blog/main/LICENSE)

A library for run-time system code line-level coverage analysis. You can use it to evaluate the intergration test coverage.

> realistic practice:
> - [en](https://github.com/yeshan333/explore_ast_app/blob/main/examples/README.md)
> - [zh_hans 中文版](https://github.com/yeshan333/explore_ast_app/blob/main/examples/README_cn.md)

## Running Tests

To run tests with coverage data, run the following command:

```shell
mix test --cover --exclude real_cover
```

## Installation

The package can be installed by adding `ex_integration_coveralls` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_integration_coveralls, "~> 0.9.0"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/ex_integration_coveralls](https://hexdocs.pm/ex_integration_coveralls/readme.html).

## Quick Start

Once your application is release, up and running. You only need the following three steps to do run-time coverage collection:

- Step 1、Connects a shell to the running node which your application is running:

```shell
/path/bin/your_app remote_console
```

- Step 2、Specific the application start coverage collection:

```shell
ExIntegrationCoveralls.start_app_cov("your_app_name")
```

Note: the `your_app_name` must exist in the return app list of  [:application.which_applications](https://www.erlang.org/doc/man/application.html#which_applications-0).

- Step 3、Conduct external testing against the above application. Get run-time coverage or post coverage data to coverage system.

```shell
ExIntegrationCoveralls.get_app_total_cov("your_app_name")
# post coverage data
ExIntegrationCoveralls.post_app_cov_to_ci(url, extends, "your_app_name")
```

Note: Your application release package should include the source code. ExIntegrationCoveralls will use the source code to caculate coverage stats. The general structure is as follows:

```shell
.
├── bin
│   ├── explore_ast_app
│   ├── explore_ast_app.bat
│   ├── explore_ast_app_rc_exec.sh
│   ├── no_dot_erlang.boot
│   └── start_clean.boot
├── erts-12.1
│   ├── bin
│   ├── doc
│   ├── include
│   ├── info
│   ├── lib
│   └── src
├── lib
│   ├── artificery-0.4.3
│   ├── asn1-5.0.17
│   ├── certifi-2.9.0
│   ├── elixir-1.12.3
│   ├── ex_integration_coveralls-0.4.0 # your running app
│   ├── explore_ast_app-0.1.0
│   │   ├── consolidated
│   │   ├── ebin
│   │   └── lib                        # source code in here
│   └── unicode_util_compat-0.7.0
└── releases
    ├── 0.1.0
    ├── RELEASES
    └── start_erl.data
```

Note: If you use the [distillery](https://github.com/bitwalker/distillery) to get OTP release, and config `set include_src: true`, then you can get the above structure. But if you use the Elixir origin `mix release`, this situation needs to be handled manually. See the [release demo](examples/release_demo) for a working example with a custom release step that copies source files automatically.

## Multi-App Coverage (dep_apps)

In real projects, business logic often lives in custom dependency libraries. You can collect coverage across your main app **and** its dependencies in a single session by passing the `dep_apps` option:

```elixir
# Start coverage for the main app and its dependencies
ExIntegrationCoveralls.start_app_cov("my_app", dep_apps: ["shared_lib", "domain_logic"])

# Get merged total coverage across all apps
ExIntegrationCoveralls.get_app_total_cov("my_app", dep_apps: ["shared_lib", "domain_logic"])

# Post merged coverage data to CI
ExIntegrationCoveralls.post_app_cov_to_ci(url, extends, "my_app", dep_apps: ["shared_lib"])
```

The HTTP API also supports `dep_apps`:

```bash
# Start coverage with dependencies
curl -X POST http://localhost:3333/cov/start \
  -H 'Content-Type: application/json' \
  -d '{"app_name": "my_app", "dep_apps": ["shared_lib"]}'

# Get total coverage (comma-separated query param)
curl http://localhost:3333/cov/total/my_app?dep_apps=shared_lib

# Get detailed line-level report
curl http://localhost:3333/cov/report/my_app?dep_apps=shared_lib
```

## Examples

The [`examples/`](examples/) directory contains a complete working demo:

| Directory | Description |
|-----------|-------------|
| [`examples/release_demo/`](examples/release_demo/) | Main OTP app demonstrating `mix release` integration with `ex_integration_coveralls`. Includes a smoke test script exercising all HTTP endpoints. |
| [`examples/dep_lib/`](examples/dep_lib/) | A minimal dependency library used by `release_demo` to demonstrate multi-app coverage collection via `dep_apps`. |

To try it out:

```bash
cd examples/release_demo
mix deps.get
MIX_ENV=prod mix release
_build/prod/rel/release_demo/bin/release_demo daemon
bash smoke_test.sh
```

See the [release demo README](examples/release_demo/README.md) for full details.

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for more information.

## Acknowledgements

Thanks for these awesome resources that were used during the development of the **ExIntegrationCoveralls**:

- [Erlang cover](https://www.erlang.org/doc/man/cover.html#description)
- [A brief introduction to BEAM](https://www.erlang.org/blog/a-brief-beam-primer/)
- [excoveralls](https://github.com/parroty/excoveralls)
- [BeamFile - A peek into the BEAM file](https://github.com/hrzndhrn/beam_file)
- [The Elixir AST explorer - ast_ninja](https://github.com/arjan/ast_ninja)
