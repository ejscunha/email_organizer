defmodule EmailOrganizer.Support.Mocks do
  @moduledoc """
  This module contains mocks for external dependencies.
  """

  def mimic_copy do
    Mimic.copy(GoogleApi.Gmail.V1.Connection)
    Mimic.copy(GoogleApi.Gmail.V1.Api.Users)
  end
end
