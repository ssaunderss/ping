defmodule Ping.Servers.RefreshLogic do
  @moduledoc """
  Houses all the core logic for `Ping.Servers.PingTracker`
  """

  @type job_name :: String.t()
  @type server_state :: %{job_name() => Ping.Types.HealthCheck.t()}
  @type past_due_pings :: [{job_name(), Ping.Types.HealthCheck.t()}, ...] | []

  @doc """
  Given the current state of `Ping.Servers.PingTracker`, finds all pings that are
  past due, creates alerts for them and returns an updated state.
  """
  @spec refresh(server_state()) :: server_state()
  def refresh(state) do
    past_due =
      state
      |> get_past_due()
      |> process_past_due()
      |> Map.new()

    Map.merge(state, past_due)
  end

  @spec get_past_due(server_state()) :: past_due_pings()
  defp get_past_due(state) do
    now = DateTime.utc_now()

    Enum.filter(state, fn {_k, %{next_ping_timestamp: next_ping_timestamp}} ->
      DateTime.after?(now, next_ping_timestamp)
    end)
  end

  @spec process_past_due(past_due_pings()) :: past_due_pings()
  defp process_past_due(past_due_pings) do
    past_due_pings
    |> send_alerts()
    |> update_next_ping()
  end

  @spec send_alerts(past_due_pings()) :: past_due_pings()
  defp send_alerts(past_due) do
    Enum.map(past_due, fn {_k, v} = job ->
      Ping.API.Alerts.send_alert(v)
      job
    end)
  end

  @spec update_next_ping(past_due_pings()) :: past_due_pings()
  defp update_next_ping(past_due) do
    Enum.map(past_due, fn {k, v} ->
      updated_timestamp = DateTime.add(DateTime.utc_now(), reset_next_ping_offset(), :second)
      {k, Map.put(v, :next_ping_timestamp, updated_timestamp)}
    end)
  end

  defp reset_next_ping_offset(), do: Application.get_env(:ping, :next_ping_offset, 60)
end
