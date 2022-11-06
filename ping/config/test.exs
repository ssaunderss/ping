import Config

# Print only warnings and errors during test
config :logger, level: :warn

# Use the Mock for Tests
config :tesla, Ping.API.Alerts, adapter: Tesla.Mock

config :ping,
  alert_uri: "https://alert-service.com/alert"

config :ping, port: 4001
