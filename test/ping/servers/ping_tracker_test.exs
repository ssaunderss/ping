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

  describe "upsert_ping/2" do
    test "inserts ping to state", %{ping: ping} do
      start_supervised!({Ping.Servers.PingTracker, name: :test_ping_tracker_1})
      assert PingTracker.upsert_ping(ping, :test_ping_tracker_1) == :ok
      state = PingTracker.inspect_pings(:test_ping_tracker_1)
      %{"test_service" => inserted_ping} = state
      assert ping == inserted_ping
    end

    test "overwrites previous ping", %{ping: ping, ping2: ping2} do
      # insert the first ping that was received
      start_supervised!({Ping.Servers.PingTracker, name: :test_ping_tracker_2})
      assert PingTracker.upsert_ping(ping, :test_ping_tracker_2) == :ok
      state = PingTracker.inspect_pings(:test_ping_tracker_2)
      %{"test_service" => inserted_ping} = state
      assert ping == inserted_ping
      # insert the second ping that was received
      assert PingTracker.upsert_ping(ping2, :test_ping_tracker_2) == :ok
      state = PingTracker.inspect_pings(:test_ping_tracker_2)
      %{"test_service" => inserted_ping} = state
      assert ping2 == inserted_ping
    end

    test "returns error when upserting ping with earlier timestamp", %{ping: ping} do
      # insert the first ping that was received
      start_supervised!({Ping.Servers.PingTracker, name: :test_ping_tracker_3})
      assert PingTracker.upsert_ping(ping, :test_ping_tracker_3) == :ok
      state = PingTracker.inspect_pings(:test_ping_tracker_3)
      %{"test_service" => inserted_ping} = state
      assert ping == inserted_ping

      # attempt to upsert ping with an earlier timestamp, return :error
      earlier_ping =
        Map.update!(ping, :last_ping_timestamp, fn timestamp ->
          DateTime.add(timestamp, -1, :day)
        end)

      assert PingTracker.upsert_ping(earlier_ping, :test_ping_tracker_3) == :error
    end

    test "can update ping with later timestamp than existing", %{ping: ping} do
      # insert the first ping that was received
      start_supervised!({Ping.Servers.PingTracker, name: :test_ping_tracker_4})
      assert PingTracker.upsert_ping(ping, :test_ping_tracker_4) == :ok
      state = PingTracker.inspect_pings(:test_ping_tracker_4)
      %{"test_service" => inserted_ping} = state
      assert ping == inserted_ping

      # insert the second ping that was received
      newer_ping =
        Map.update!(ping, :last_ping_timestamp, fn timestamp ->
          DateTime.add(timestamp, 1, :day)
        end)

      assert PingTracker.upsert_ping(newer_ping, :test_ping_tracker_4) == :ok
      state = PingTracker.inspect_pings(:test_ping_tracker_4)
      %{"test_service" => inserted_ping} = state
      assert newer_ping == inserted_ping
    end
  end
end
