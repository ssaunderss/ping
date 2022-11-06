defmodule Ping.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(
        scheme: :http,
        plug: Ping.Router,
        options: [port: Application.fetch_env!(:ping, :port)]
      ),
      {Ping.Servers.PingTracker, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ping.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
