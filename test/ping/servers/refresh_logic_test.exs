defmodule Ping.Servers.RefreshLogicTest do
  use ExUnit.Case, async: true

  import Tesla.Mock

  alias Ping.API.HealthCheck
  alias Ping.Servers.RefreshLogic

  setup do
    mock(fn
      %{method: :get} ->
        %Tesla.Env{status: 200, body: "Successfully Alerted"}
    end)

    now_unix_past =
      DateTime.utc_now() |> DateTime.add(-1, :minute) |> DateTime.to_unix() |> Integer.to_string()

    now_unix = DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()
    ping_1 = %{"name" => "test_service_1", "frequency" => "1s", "timestamp" => now_unix_past}
    ping_2 = %{"name" => "test_service_2", "frequency" => "1W", "timestamp" => now_unix}

    formatted_ping_1 = HealthCheck.format_ping(ping_1)
    formatted_ping_2 = HealthCheck.format_ping(ping_2)

    state = %{
      "test_service_1" => formatted_ping_1,
      "test_service_2" => formatted_ping_2
    }

    %{
      formatted_ping_1: formatted_ping_1,
      formatted_ping_2: formatted_ping_2,
      state: state
    }
  end

  test "refresh/1 only updates past due pings", %{
    formatted_ping_1: formatted_ping_1,
    formatted_ping_2: formatted_ping_2,
    state: state
  } do
    updated_state = RefreshLogic.refresh(state)

    %{"test_service_1" => updated_ping_1, "test_service_2" => updated_ping_2} = updated_state

    assert updated_ping_1.next_ping_timestamp != formatted_ping_1.next_ping_timestamp
    assert updated_ping_2.next_ping_timestamp == formatted_ping_2.next_ping_timestamp

    assert DateTime.diff(
             updated_ping_1.next_ping_timestamp,
             formatted_ping_1.next_ping_timestamp,
             :minute
           ) == 1
  end
end
