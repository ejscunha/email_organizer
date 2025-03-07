defmodule EmailOrganizer.Support.Mocks do
  @moduledoc """
  This module contains mocks for external dependencies.
  """

  def mimic_copy do
    Mimic.copy(EmailOrganizer.Google.Gmail, type_check: true)
    Mimic.copy(GoogleApi.Gmail.V1.Connection, type_check: true)
    Mimic.copy(GoogleApi.Gmail.V1.Api.Users, type_check: true)
  end
end
