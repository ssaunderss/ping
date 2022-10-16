defmodule PingWeb.HealthChecksControllerTest do
  use PingWeb.ConnCase, async: false

  setup do
    conn = build_conn()
    conn = %{conn | host: "api.ping.com"}

    %{conn: conn}
  end

  describe "/ping" do
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
end
