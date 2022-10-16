defmodule PingWeb.Router do
  use PingWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PingWeb do
    pipe_through :api

    get "/ping", HealthChecksController, :index
  end
end
