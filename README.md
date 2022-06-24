# ExIntegrationCoveralls

A library for integration test code line-level coverage analysis.

## Running Tests

To run tests with coverage data, run the following command:

```shell
mix test --cover --exclude real_cover
# run all test cases
mix test
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_integration_coveralls` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_integration_coveralls, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_integration_coveralls](https://hexdocs.pm/ex_integration_coveralls).

