defmodule Ping.HttpServer.ApiResponses do
  import Plug.Conn

  def success(conn, message) do
    conn
    |> put_resp_content_type("application/json")
    |> resp(200, message)
    |> send_resp()
  end

  def error(conn, message) do
    conn
    |> put_resp_content_type("application/json")
    |> resp(400, message)
    |> send_resp()
  end
end
