defmodule Ping.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Ping.Router,
        options: [
          port: Application.fetch_env!(:ping, :port)
        ]
      ),
      {Ping.Servers.PingTracker, []}
    ]

    opts = [strategy: :one_for_one, name: Ping.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
