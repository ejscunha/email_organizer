defmodule EmailOrganizer.Utils do
  @moduledoc """
  Utility functions for the EmailOrganizer application.
  """

  @spec get_config_value(String.t() | {:system, String.t()}) :: String.t()
  def get_config_value({:system, env}), do: System.get_env(env)
  def get_config_value(value) when is_binary(value), do: value
end
