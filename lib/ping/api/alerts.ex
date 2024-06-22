defmodule Ping.API.Alerts do
  use Tesla

  alias Ping.Types.HealthCheck

  require Logger

  plug(Tesla.Middleware.BaseUrl, alert_uri())
  plug(Tesla.Middleware.JSON)

  @spec send_alert(HealthCheck.t()) :: term()
  def send_alert(%{name: name, last_ping_timestamp: timestamp} = _ping) do
    last_timestamp_unix =
      timestamp
      |> DateTime.to_unix()
      |> Integer.to_string()

    Task.start(fn ->
      case get("?name=" <> name <> "&last_ping=" <> last_timestamp_unix) do
        {:ok, _response} ->
          :ok

        _ ->
          Logger.error("[alerts] could not connect to alerts endpoint: #{inspect(alert_uri())}")
      end
    end)

    :ok
  end

  defp alert_uri(), do: Application.get_env(:ping, :alert_uri)
end
