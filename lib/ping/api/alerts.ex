defmodule Ping.API.Alerts do
  alias Ping.Types.HealthCheck

  require Logger

  @spec send_alert(HealthCheck.t()) :: term()
  def send_alert(%{name: name, last_ping_timestamp: timestamp} = _ping) do
    last_timestamp_unix =
      timestamp
      |> DateTime.to_unix()
      |> Integer.to_string()

    Task.start(fn ->
      case Req.get(alert_uri(),
             params: [name: name, last_ping: last_timestamp_unix],
             adapter: adapter()
           ) do
        {:ok, _response} ->
          :ok

        _ ->
          Logger.error("[alerts] could not connect to alerts endpoint: #{inspect(alert_uri())}")
      end
    end)

    :ok
  end

  # If the stub adapter is enabled, just prints out response otherwise uses req's default step
  defp adapter() do
    if Application.get_env(:ping, :stub_adapter, false) do
      fn request ->
        Logger.info(
          "[alerts:stub_adapater] Your alert #{inspect(request.options.params)} was successfully sent."
        )

        response = %Req.Response{status: 200, body: "Your alert was successfully sent."}
        {request, response}
      end
    else
      &Req.Steps.run_finch/1
    end
  end

  defp alert_uri(), do: Application.get_env(:ping, :alert_uri)
end
