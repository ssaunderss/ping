import Config

# Do not print debug messages in production
config :logger, level: :info

config :ping, port: 8085

config :ping, stub_adapter: false
