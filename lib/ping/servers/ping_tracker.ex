defmodule Ping.Servers.PingTracker do
  @moduledoc """
  Main backend server for the /ping endpoint.When a request comes in, the job is upserted
  into the server state. This server also polls itself every second to check for past due pings.

  The only time an upsert would fail is if the timestamp of the incoming ping is older than the
  timestamp currently in recorded in the state.

  If any pings are past due, an external service is alerted.
  """
  use GenServer

  require Logger

  alias Ping.Servers.RefreshLogic
  alias Ping.Types.HealthCheck

  @spec inspect_pings() :: map()
  def inspect_pings(server_name \\ __MODULE__) do
    GenServer.call(server_name, :inspect)
  end

  @spec upsert_ping(HealthCheck.t()) :: :ok | :error
  def upsert_ping(ping, server_name \\ __MODULE__) do
    GenServer.call(server_name, {:upsert, ping})
  end

  @spec delete_ping(String.t()) :: {:ok, integer()}
  def delete_ping(name, server_name \\ __MODULE__) do
    GenServer.call(server_name, {:delete, name})
  end

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, [], name: name)
  end

  @impl GenServer
  def init(_args) do
    state = %{}

    schedule_refresh()

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:upsert, ping}, _from, state) do
    existing_ping = Map.get(state, ping.name)

    if is_nil(existing_ping) do
      {:reply, :ok, Map.put(state, ping.name, ping)}
    else
      # if we get a ping with a timestamp before the existing one, toss it
      if DateTime.after?(existing_ping.last_ping_timestamp, ping.last_ping_timestamp) do
        {:reply, :error, state}
      else
        {:reply, :ok, Map.put(state, ping.name, ping)}
      end
    end
  end

  @impl GenServer
  def handle_call(:inspect, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_call({:delete, name}, _from, state) do
    num_keys_old = Map.keys(state) |> length()
    updated_state = Enum.filter(state, fn {k, _v} -> k != name end) |> Enum.into(%{})
    num_keys_new = Map.keys(updated_state) |> length()
    {:reply, {:ok, num_keys_old - num_keys_new}, updated_state}
  end

  @impl GenServer
  def handle_info(:check_past_due, state) do
    updated_state = RefreshLogic.refresh(state)

    schedule_refresh()

    {:noreply, updated_state}
  end

  @impl GenServer
  def handle_info({_ref, :ok}, state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.error("[ping tracker] received unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp ping_tracker_refresh_interval,
    do: Application.get_env(:ping, :ping_tracker_refresh_interval, 1)

  defp schedule_refresh do
    Process.send_after(self(), :check_past_due, ping_tracker_refresh_interval() * 1_000)
  end
end
