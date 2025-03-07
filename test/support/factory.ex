defmodule EmailOrganizer.Support.Factory do
  @moduledoc """
  Factory for creating test data
  """

  use ExMachina.Ecto, repo: EmailOrganizer.Repo

  alias EmailOrganizer.Account.User

  def user_factory do
    %User{
      email: sequence(:email, &"user-#{&1}@example.com"),
      name: sequence(:name, &"User #{&1}")
    }
  end
end
