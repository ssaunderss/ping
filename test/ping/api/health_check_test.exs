defmodule Ping.API.HealthCheckTest do
  use ExUnit.Case, async: true

  alias Ping.API.HealthCheck
  alias Ping.Servers.PingTracker

  describe "format_ping/1" do
    test "successfully formats second frequency" do
      now_datetime = DateTime.utc_now() |> DateTime.truncate(:second)
      now_unix = now_datetime |> DateTime.to_unix() |> Integer.to_string()
      ping = %{"name" => "test_service", "frequency" => "1s", "timestamp" => now_unix}
      formatted = HealthCheck.format_ping(ping)
      assert formatted.name == "test_service"
      assert formatted.frequency == "1s"
      assert formatted.last_ping_timestamp == now_datetime

      assert formatted.next_ping_timestamp ==
               DateTime.add(now_datetime, 1, :second)
    end

    test "successfully formats minute frequency" do
      now_datetime = DateTime.utc_now() |> DateTime.truncate(:second)
      now_unix = now_datetime |> DateTime.to_unix() |> Integer.to_string()
      ping = %{"name" => "test_service", "frequency" => "1m", "timestamp" => now_unix}
      formatted = HealthCheck.format_ping(ping)
      assert formatted.name == "test_service"
      assert formatted.frequency == "1m"
      assert formatted.last_ping_timestamp == now_datetime

      assert formatted.next_ping_timestamp ==
               DateTime.add(now_datetime, 60 * 1, :second)
    end

    test "successfully formats hour frequency" do
      now_datetime = DateTime.utc_now() |> DateTime.truncate(:second)
      now_unix = now_datetime |> DateTime.to_unix() |> Integer.to_string()
      ping = %{"name" => "test_service", "frequency" => "1h", "timestamp" => now_unix}
      formatted = HealthCheck.format_ping(ping)
      assert formatted.name == "test_service"
      assert formatted.frequency == "1h"
      assert formatted.last_ping_timestamp == now_datetime

      assert formatted.next_ping_timestamp ==
               DateTime.add(now_datetime, 60 * 60 * 1, :second)
    end

    test "successfully formats daily frequency" do
      now_datetime = DateTime.utc_now() |> DateTime.truncate(:second)
      now_unix = now_datetime |> DateTime.to_unix() |> Integer.to_string()
      ping = %{"name" => "test_service", "frequency" => "1D", "timestamp" => now_unix}
      formatted = HealthCheck.format_ping(ping)
      assert formatted.name == "test_service"
      assert formatted.frequency == "1D"
      assert formatted.last_ping_timestamp == now_datetime

      assert formatted.next_ping_timestamp ==
               DateTime.add(now_datetime, 24 * 60 * 60 * 1, :second)
    end

    test "successfully formats weekly frequency" do
      now_datetime = DateTime.utc_now() |> DateTime.truncate(:second)
      now_unix = now_datetime |> DateTime.to_unix() |> Integer.to_string()
      ping = %{"name" => "test_service", "frequency" => "2W", "timestamp" => now_unix}
      formatted = HealthCheck.format_ping(ping)
      assert formatted.name == "test_service"
      assert formatted.frequency == "2W"
      assert formatted.last_ping_timestamp == now_datetime

      assert formatted.next_ping_timestamp ==
               DateTime.add(now_datetime, 2 * 7 * 24 * 60 * 60 * 1, :second)
    end

    test "raises function clause error on unsupported frequency type" do
      now_datetime = DateTime.utc_now() |> DateTime.truncate(:second)
      now_unix = now_datetime |> DateTime.to_unix() |> Integer.to_string()
      ping = %{"name" => "test_service", "frequency" => "1M", "timestamp" => now_unix}
      assert_raise FunctionClauseError, fn -> HealthCheck.format_ping(ping) end
    end
  end

  describe "insert_ping/1" do
    test "Successfully inserts well formatted ping" do
      now_unix = DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()
      ping = %{"name" => "test_service", "frequency" => "2W", "timestamp" => now_unix}
      start_supervised!({Ping.Servers.PingTracker, name: :test_ping_tracker})
      assert HealthCheck.insert_ping(ping, :test_ping_tracker) == :ok
      ping_tracker_state = PingTracker.inspect_pings(:test_ping_tracker)
      assert ["test_service"] = Map.keys(ping_tracker_state)
    end
  end
end
