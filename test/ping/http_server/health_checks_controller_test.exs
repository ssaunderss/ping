defmodule PingWeb.HealthChecksControllerTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Ping.Servers.PingTracker

  require Logger

  @opts Ping.Router.init([])

  describe "GET /ping" do
    test "with name and well formatted frequency returns 200 status" do
      # creates test connection
      conn = conn(:get, "/ping", %{name: "test1", frequency: "1s"})

      # invoke plug
      conn = Ping.Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "Successfully recorded ping for test1"
    end

    test "with name, well formatted timestamp and frequency returns 200 status" do
      now_unix = DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()

      conn =
        conn(:get, "/ping", %{name: "test2", frequency: "1s", timestamp: now_unix})
        |> Ping.Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "Successfully recorded ping for test2"
    end

    test "with name, well formatted timestamp and frequency and extra, unneeded params returns 200 status" do
      now_unix = DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()

      conn =
        conn(:get, "/ping", %{name: "test3", frequency: "1s", timestamp: now_unix, hi: "bye"})
        |> Ping.Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "Successfully recorded ping for test3"
    end

    test "with missing name param returns 400 status" do
      now_unix = DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()

      conn =
        conn(:get, "/ping", %{frequency: "1s", timestamp: now_unix})
        |> Ping.Router.call(@opts)

      assert conn.status == 400
    end

    test "with missing frequency param returns 400 status" do
      now_unix = DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()

      conn =
        conn(:get, "/ping", %{name: "test4", timestamp: now_unix})
        |> Ping.Router.call(@opts)

      assert conn.status == 400
    end
  end

  describe "DELETE /ping" do
    test "valid named service that's being monitored gets deleted" do
      conn(:get, "/ping", %{name: "test5", frequency: "1s"})
      |> Ping.Router.call(@opts)

      {name, _v} =
        PingTracker.inspect_pings()
        |> Enum.filter(fn {k, _v} -> k == "test5" end)
        |> Enum.at(0)

      assert name == "test5"

      conn =
        conn(:delete, "/ping/test5")
        |> Ping.Router.call(@opts)

      assert conn.status == 200

      filtered =
        PingTracker.inspect_pings()
        |> Enum.filter(fn {k, _v} -> k == "test5" end)

      assert filtered == []
    end

    test "invalid named service returns 400" do
      conn(:get, "/ping", %{name: "test6", frequency: "1s"})
      |> Ping.Router.call(@opts)

      {name, _v} =
        PingTracker.inspect_pings()
        |> Enum.filter(fn {k, _v} -> k == "test6" end)
        |> Enum.at(0)

      assert name == "test6"

      conn =
        conn(:delete, "/ping/test1000000000")
        |> Ping.Router.call(@opts)

      assert conn.status == 400

      filtered_state =
        PingTracker.inspect_pings()
        |> Map.keys()
        |> Enum.filter(fn x -> x == "test6" end)

      assert filtered_state == ["test6"]
    end
  end
end
