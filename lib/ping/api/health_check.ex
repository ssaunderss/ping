defmodule Ping.API.HealthCheck do
  alias Ping.Servers.PingTracker
  alias Ping.Types.HealthCheck

  @type params :: %{
          frequency: String.t(),
          name: String.t(),
          timestamp: String.t() | nil
        }

  @spec upsert_ping(params()) :: :ok | :error
  def upsert_ping(params, server_name) do
    params
    |> format_ping()
    |> PingTracker.upsert_ping(server_name)
  end

  def upsert_ping(params) do
    params
    |> format_ping()
    |> PingTracker.upsert_ping()
  end

  @spec delete_ping(String.t()) :: term()
  def delete_ping(name) do
    name
    |> PingTracker.delete_ping()
  end

  @spec format_ping(map()) :: HealthCheck.t()
  def format_ping(%{"frequency" => frequency, "name" => name} = params) do
    formatted_frequency = format_frequency(frequency)

    timestamp =
      case Map.get(params, "timestamp") do
        nil -> DateTime.utc_now()
        val -> String.to_integer(val) |> DateTime.from_unix!()
      end

    next_ping = DateTime.add(timestamp, formatted_frequency, :second)

    %HealthCheck{
      name: name,
      frequency: frequency,
      last_ping_timestamp: timestamp,
      next_ping_timestamp: next_ping
    }
  end

  defp format_frequency(time) do
    {:ok, {time, unit}} = parse_time_string(time)
    format_as_seconds(time, unit)
  end

  defp parse_time_string(time_string) do
    length = String.length(time_string)

    case length > 1 do
      true ->
        {:ok, String.split_at(time_string, length - 1)}

      false ->
        {:error, :invalid_time}
    end
  end

  defp format_as_seconds(time, "W"), do: 7 * format_as_seconds(time, "D")
  defp format_as_seconds(time, "D"), do: 24 * format_as_seconds(time, "h")
  defp format_as_seconds(time, "h"), do: 60 * format_as_seconds(time, "m")
  defp format_as_seconds(time, "m"), do: 60 * format_as_seconds(time, "s")
  defp format_as_seconds(time, "s"), do: String.to_integer(time)
  defp format_as_seconds(_time, _unit), do: {:error, :invalid_format}
end
