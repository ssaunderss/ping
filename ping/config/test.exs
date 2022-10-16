import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ping, PingWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "g9gYPfa8vmGGBVTavQnwlWXx8/SIBlv9Uyd4q8qRYE5vGGyWU4Sg4X/DOxGmJT+z",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Use the Mock for Tests
config :tesla, Ping.API.Alerts, adapter: Tesla.Mock

config :ping,
  alert_uri: "https://alert-service.com/alert"
