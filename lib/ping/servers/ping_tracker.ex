defmodule Ping.Servers.PingTracker do
  @moduledoc """
  Main backend server for the /ping endpoint.
  When a request comes in, the job is upserted
  into the server state. This server also polls
  itself every second to check for past due pings.

  If any pings are past due, alerts external service
  """
  use GenServer

  require Logger

  alias Ping.Servers.RefreshLogic
  alias Ping.Types.HealthCheck

  @spec inspect_pings() :: map()
  def inspect_pings(server_name \\ __MODULE__) do
    GenServer.call(server_name, :inspect)
  end

  @spec insert_ping(HealthCheck.t()) :: term()
  def insert_ping(ping, server_name \\ __MODULE__) do
    GenServer.call(server_name, {:insert, ping})
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
  def handle_call({:insert, ping}, _from, state) do
    updated_state = Map.put(state, ping.name, ping)
    {:reply, :ok, updated_state}
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
