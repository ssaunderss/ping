defmodule Ping.Servers.PingTrackerTest do
  use ExUnit.Case, async: true

  alias Ping.API.HealthCheck
  alias Ping.Servers.PingTracker

  setup do
    ping =
      %{"name" => "test_service", "frequency" => "1W"}
      |> HealthCheck.format_ping()

    ping2 =
      %{"name" => "test_service", "frequency" => "1h"}
      |> HealthCheck.format_ping()

    %{
      ping: ping,
      ping2: ping2
    }
  end

  describe "insert_ping/2" do
    test "inserts ping to state", %{ping: ping} do
      start_supervised!({Ping.Servers.PingTracker, name: :test_ping_tracker_1})
      assert PingTracker.insert_ping(ping, :test_ping_tracker_1) == :ok
      state = PingTracker.inspect_pings(:test_ping_tracker_1)
      %{"test_service" => inserted_ping} = state
      assert ping == inserted_ping
    end

    test "overwrites previous ping", %{ping: ping, ping2: ping2} do
      # insert the first ping that was received
      start_supervised!({Ping.Servers.PingTracker, name: :test_ping_tracker_2})
      assert PingTracker.insert_ping(ping, :test_ping_tracker_2) == :ok
      state = PingTracker.inspect_pings(:test_ping_tracker_2)
      %{"test_service" => inserted_ping} = state
      assert ping == inserted_ping
      # insert the second ping that was received
      assert PingTracker.insert_ping(ping2, :test_ping_tracker_2) == :ok
      state = PingTracker.inspect_pings(:test_ping_tracker_2)
      %{"test_service" => inserted_ping} = state
      assert ping2 == inserted_ping
    end
  end
end
