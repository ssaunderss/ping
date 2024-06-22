defmodule Ping.Types.HealthCheck do
  @moduledoc """
  Type representing the parameters passed to /ping health check endpoint
  """

  @type t :: %__MODULE__{
          name: String.t(),
          frequency: String.t(),
          last_ping_timestamp: DateTime.t(),
          next_ping_timestamp: DateTime.t()
        }

  @enforce_keys [:name, :frequency]
  defstruct [
    :name,
    :frequency,
    :next_ping_timestamp,
    last_ping_timestamp: DateTime.utc_now()
  ]
end
