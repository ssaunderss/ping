defmodule PingWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      # import Plug.Conn
      # import Phoenix.ConnTest
      # import PingWeb.ConnCase
      use Plug.Test

      # alias PingWeb.Router.Helpers, as: Routes

      # # The default endpoint for testing
      # @endpoint PingWeb.Endpoint
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
