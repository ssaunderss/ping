import Config

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

config :ping, port: 4000

config :ping, stub_adapter: true
