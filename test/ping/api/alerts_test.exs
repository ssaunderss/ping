defmodule Ping.API.AlertsTest do
  use ExUnit.Case, async: true

  alias Ping.API.Alerts
  alias Ping.API.HealthCheck

  test "send_alert/1 can send alerts externally" do
    sample_ping =
      %{"name" => "test_service", "frequency" => "10m"}
      |> HealthCheck.format_ping()

    assert :ok == Alerts.send_alert(sample_ping)
  end
end
