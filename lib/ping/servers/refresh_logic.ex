defmodule Ping.Servers.RefreshLogic do
  def refresh(state) do
    past_due = get_past_due(state)

    processed =
      case past_due do
        %{} -> %{}
        vals -> process_past_due(vals)
      end

    _updated_state =
      Enum.reduce(processed, state, fn {k, v}, acc ->
        Map.put(acc, k, v)
      end)
  end

  defp get_past_due(state) when state == %{}, do: %{}

  defp get_past_due(state) do
    now = DateTime.utc_now()

    Enum.filter(state, fn {_k, v} ->
      %{next_ping_timestamp: timestamp} = v
      DateTime.compare(now, timestamp) == :gt
    end)
  end

  defp process_past_due(past_due) do
    past_due
    |> alert()
    |> update_next_ping()
  end

  defp alert(past_due) do
    Enum.map(past_due, fn {k, v} ->
      Ping.API.Alerts.send_alert(v)
      {k, v}
    end)
  end

  defp update_next_ping(past_due) do
    Enum.map(past_due, fn {k, v} ->
      current_timestamp = v.next_ping_timestamp
      updated_timestamp = DateTime.add(current_timestamp, reset_next_ping_offset(), :second)
      {k, Map.put(v, :next_ping_timestamp, updated_timestamp)}
    end)
  end

  defp reset_next_ping_offset(), do: Application.get_env(:ping, :next_ping_offset, 60)
end
