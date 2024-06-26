defmodule Ping.HttpServer.HealthChecksController do
  alias Ping.API.HealthCheck
  alias Ping.HttpServer.ApiResponses

  require Logger

  @necessary_keys ["name", "frequency"]

  def index(conn, %{"name" => name, "frequency" => _frequency} = params) do
    try do
      case HealthCheck.upsert_ping(params) do
        :ok ->
          ApiResponses.success(conn, "Successfully recorded ping for #{name}")

        :error ->
          ApiResponses.error(conn, "A ping with an earlier timestamp has already been recorded.")
      end
    rescue
      e ->
        message = "Could not record ping with params #{inspect(params)}"
        Logger.error("[GET /ping] #{message}, error: #{inspect(e)}")
        ApiResponses.error(conn, message)
    end
  end

  def index(conn, params) do
    message =
      "Could not record ping with params #{inspect(params)}, the necessary params are: #{inspect(@necessary_keys)}"

    Logger.warning("[GET /ping] Received payload with params: #{inspect(params)}")
    ApiResponses.error(conn, message)
  end

  def delete(conn, %{"name" => name} = params) do
    try do
      {:ok, num_deleted} = HealthCheck.delete_ping(name)

      case num_deleted do
        0 ->
          message = "Could not delete ping #{inspect(name)} because it does not exist. "

          ApiResponses.error(conn, message)

        _ ->
          message = "Successfully deleted ping: #{name}"
          ApiResponses.success(conn, message)
      end
    rescue
      e ->
        message = "Could not delete ping with params #{inspect(params)}"
        Logger.error("[DELETE /ping] #{message}, error: #{inspect(e)}")
        ApiResponses.error(conn, message)
    end
  end

  def delete(conn, params) do
    message =
      "Could not delete ping with params #{inspect(params)}, this endpoint only takes a single string param which is the name of the job"

    Logger.warning("[DELETE /ping] Received payload with params: #{inspect(params)}")
    ApiResponses.error(conn, message)
  end
end
