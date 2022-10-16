defmodule Ping.PingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ping.Pings` context.
  """

  @doc """
  Generate a health_checks.
  """
  def health_checks_fixture(attrs \\ %{}) do
    {:ok, health_checks} =
      attrs
      |> Enum.into(%{
        frequency: "some frequency",
        name: "some name",
        timestamp: ~U[2022-09-30 17:42:00.000000Z]
      })
      |> Ping.Pings.create_health_checks()

    health_checks
  end
end
