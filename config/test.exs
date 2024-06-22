import Config

# Print only warnings and errors during test
config :logger, level: :warning

config :ping,
  alert_uri: "https://alert-service.com/alert",
  stub_adapter: true

config :ping, port: 4001
