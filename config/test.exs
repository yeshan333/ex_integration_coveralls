import Config

config :junit_formatter,
  report_file: "report_file_test.xml",
  report_dir: "/tmp",
  print_report_file: true,
  prepend_project_name?: true,
  include_filename?: true,
  include_file_line?: true

config :husky,
  pre_commit: "mix format && mix test --cover --exclude real_cover && mix credo",
  pre_push: "mix format --check-formatted && mix credo && mix test --cover --exclude real_cover"
