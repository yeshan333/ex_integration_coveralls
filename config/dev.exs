import Config

config :husky,
  pre_commit: "mix format && mix test --cover --exclude real_cover && mix credo",
  pre_push: "mix format --check-formatted && mix credo && mix test --cover --exclude real_cover"
