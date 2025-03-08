defmodule EmailOrganizerWeb.LiveViewCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a LiveView.
  """

  use ExUnit.CaseTemplate

  alias EmailOrganizer.DataCase

  using do
    quote do
      # The default endpoint for testing
      @endpoint EmailOrganizerWeb.Endpoint

      use EmailOrganizerWeb, :verified_routes

      import Phoenix.LiveViewTest
      import Phoenix.ConnTest
      import EmailOrganizer.Support.Factory
      import EmailOrganizerWeb.LiveViewCase
    end
  end

  setup tags do
    DataCase.setup_sandbox(tags)

    user = EmailOrganizer.Support.Factory.insert(:user)

    {:ok,
     conn:
       Phoenix.ConnTest.build_conn()
       |> Phoenix.ConnTest.init_test_session(%{user_id: user.id}),
     user: user}
  end

  @doc """
  Setup helper that registers and logs in users.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = EmailOrganizer.Support.Factory.insert(:user)
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Logs in the given user into the given conn.
  """
  def log_in_user(conn, user) do
    Phoenix.ConnTest.init_test_session(conn, %{user_id: user.id})
  end
end
