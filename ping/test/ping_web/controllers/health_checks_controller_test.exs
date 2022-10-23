defmodule PingWeb.HealthChecksControllerTest do
  use PingWeb.ConnCase, async: false

  alias Ping.Servers.PingTracker

  setup do
    conn = build_conn()
    conn = %{conn | host: "api.ping.com"}

    %{conn: conn}
  end

  describe "GET /ping" do
    test "with name and well formatted frequency returns 200 status", %{conn: conn} do
      resp =
        get(
          conn,
          Routes.health_checks_path(conn, :index, %{"name" => "test1", "frequency" => "1s"})
        )

      assert resp.status == 200
    end

    test "with name, well formatted timestamp and frequency returns 200 status", %{conn: conn} do
      now_unix = DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()

      resp =
        get(
          conn,
          Routes.health_checks_path(conn, :index, %{
            "name" => "test1",
            "frequency" => "1s",
            "timestamp" => now_unix
          })
        )

      assert resp.status == 200
    end

    test "with name, well formatted timestamp and frequency and extra, unneeded params returns 200 status",
         %{conn: conn} do
      now_unix = DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()

      resp =
        get(
          conn,
          Routes.health_checks_path(conn, :index, %{
            "name" => "test1",
            "frequency" => "1s",
            "timestamp" => now_unix,
            "hi" => "bye"
          })
        )

      assert resp.status == 200
    end

    test "with missing name param returns 400 status",
         %{conn: conn} do
      now_unix = DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()

      resp =
        get(
          conn,
          Routes.health_checks_path(conn, :index, %{
            "frequency" => "1s",
            "timestamp" => now_unix
          })
        )

      assert resp.status == 400
    end

    test "with missing frequency param returns 400 status",
         %{conn: conn} do
      now_unix = DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()

      resp =
        get(
          conn,
          Routes.health_checks_path(conn, :index, %{
            "name" => "test1",
            "timestamp" => now_unix
          })
        )

      assert resp.status == 400
    end
  end

  describe "DELETE /ping" do
    test "valid named service that's being monitored gets deleted", %{conn: conn} do
      get(
        conn,
        Routes.health_checks_path(conn, :index, %{"name" => "test2", "frequency" => "1s"})
      )

      {name, _v} =
        PingTracker.inspect_pings()
        |> Enum.filter(fn {k, _v} -> k == "test2" end)
        |> Enum.at(0)

      assert name == "test2"

      resp =
        delete(
          conn,
          Routes.health_checks_path(conn, :delete, "test2")
        )

      assert resp.status == 200

      filtered =
        PingTracker.inspect_pings()
        |> Enum.filter(fn {k, _v} -> k == "test2" end)

      assert filtered == []
    end
  end

  test "invalid named service returns 400", %{conn: conn} do
    get(
      conn,
      Routes.health_checks_path(conn, :index, %{"name" => "test2", "frequency" => "1s"})
    )

    {name, _v} =
      PingTracker.inspect_pings()
      |> Enum.filter(fn {k, _v} -> k == "test2" end)
      |> Enum.at(0)

    assert name == "test2"

    resp =
      delete(
        conn,
        Routes.health_checks_path(conn, :delete, "i dont exist")
      )

    assert resp.status == 400

    filtered_state =
      PingTracker.inspect_pings()
      |> Map.keys()
      |> Enum.filter(fn x -> x == "test2" end)

    assert filtered_state == ["test2"]
  end
end
