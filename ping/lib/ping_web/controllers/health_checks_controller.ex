defmodule PingWeb.HealthChecksController do
  use PingWeb, :controller

  alias Ping.API.HealthCheck
  alias PingWeb.ApiResponses

  require Logger

  @necessary_keys ["name", "frequency"]

  def index(conn, %{"name" => name, "frequency" => _frequency} = params) do
    try do
      :ok = HealthCheck.insert_ping(params)
      message = "Successfully recorded ping for #{name}"
      ApiResponses.success(conn, message)
    rescue
      e ->
        message = "Could not record ping with params #{inspect(params)}"
        Logger.error("[/ping] #{message}, error: #{inspect(e)}")
        ApiResponses.error(conn, message)
    end
  end

  def index(conn, params) do
    message =
      "Could not record ping with params #{inspect(params)}, the necessary params are: #{inspect(@necessary_keys)}"

    Logger.warning("[/ping] Received payload with params: #{inspect(params)}")
    ApiResponses.error(conn, message)
  end
end
