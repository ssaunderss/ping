import Config

if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  # secret_key_base =
  #   System.get_env("SECRET_KEY_BASE") ||
  #     raise """
  #     environment variable SECRET_KEY_BASE is missing.
  #     You can generate one by calling: mix phx.gen.secret
  #     """

  # host = System.get_env("PHX_HOST") || "example.com"
  # port = String.to_integer(System.get_env("PORT") || "4000")

  # config :ping, PingWeb.Endpoint,
  #   url: [host: host, port: 443, scheme: "https"],
  #   http: [
  #     # Enable IPv6 and bind on all interfaces.
  #     # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
  #     # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
  #     # for details about using IPv6 vs IPv4 and loopback vs public addresses.
  #     ip: {0, 0, 0, 0, 0, 0, 0, 0},
  #     port: port
  #   ],
  #   secret_key_base: secret_key_base
end

if config_env() in [:dev, :prod] do
  alert_uri =
    System.get_env("PING_ALERT_URI") ||
      raise """
      PING_ALERT_URI is missing. If you do not have one, you can set one up on https://webhook.site
      """

  config :ping,
    # how often tracking server should poll for downed services (seconds)
    ping_tracker_refresh_interval: 1,
    # if ping isn't received how many seconds to wait until re-alerting Alert Service
    next_ping_offset: 60,
    alert_uri: alert_uri
end
