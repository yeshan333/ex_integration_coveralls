import Config

config :cov_worker, :http, %{
  listen_ip: {0, 0, 0, 0},
  listen_port: String.to_integer(System.get_env("COV_PORT") || "3333")
}

config :cov_worker, :enable_cov_worker, true
