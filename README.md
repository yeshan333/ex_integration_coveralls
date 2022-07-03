# ExIntegrationCoveralls

[![Coverage Status](https://coveralls.io/repos/github/yeshan333/ex_integration_coveralls/badge.svg?branch=main)](https://coveralls.io/github/yeshan333/ex_integration_coveralls?branch=main) [![hex.pm version](https://img.shields.io/hexpm/v/ex_integration_coveralls.svg)](https://hex.pm/packages/ex_integration_coveralls) [![hex.pm downloads](https://img.shields.io/hexpm/dt/ex_integration_coveralls.svg)](https://hex.pm/packages/ex_integration_coveralls) [![hex.pm license](https://img.shields.io/hexpm/l/ex_integration_coveralls.svg)](https://coveralls.io/github/yeshan333/ex_integration_coveralls/blog/main/LICENSEs)

A library for run-time system code line-level coverage analysis. You can use it to evulate the intergration test coverage.

> realistic practice: https://github.com/yeshan333/explore_ast_app/blob/main/examples/README.md

## Running Tests

To run tests with coverage data, run the following command:

```shell
mix test --cover --exclude real_cover
# run all test cases
mix test
```

## Installation

The package can be installed by adding `ex_integration_coveralls` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_integration_coveralls, "~> 0.7.0"}
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

note: the `your_app_name` must exist in the return app list of  [:application.which_applications](https://www.erlang.org/doc/man/application.html#which_applications-0).

- Step 3、Conduct external testing against the above application. Get run-time coverage or post coverage data to coverage system.

```shell
ExIntegrationCoveralls.get_app_total_cov("your_app_name")
# post coverage data
ExIntegrationCoveralls.post_app_cov_to_ci(url, extends, "your_app_name")
```

Note: Your application release package should include the source code. The general structure is as follows:

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
