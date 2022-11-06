defmodule Ping.Router do
  use Plug.Router
  use Plug.Debugger

  alias Ping.HttpServer.HealthChecksController

  require Logger

  plug(Plug.Logger, log: :debug)
  plug(:match)
  plug(:dispatch)

  get "/ping" do
    params = decode_params(conn)
    HealthChecksController.index(conn, params)
  end

  delete "/ping/:name" do
    HealthChecksController.delete(conn, conn.params)
  end

  match _ do
    send_resp(conn, 404, "This is not the endpoint you are looking for ~0.0~")
  end

  defp decode_params(conn), do: Plug.Conn.Query.decode(conn.query_string)
end
