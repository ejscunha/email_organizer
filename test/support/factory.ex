defmodule EmailOrganizer.Support.Factory do
  @moduledoc """
  Factory for creating test data
  """

  use ExMachina.Ecto, repo: EmailOrganizer.Repo

  alias EmailOrganizer.Account.User
  alias EmailOrganizer.Email.Category

  def user_factory do
    %User{
      email: sequence(:email, &"user-#{&1}@example.com"),
      name: sequence(:name, &"User #{&1}")
    }
  end

  def category_factory do
    %Category{
      name: sequence(:name, &"Category #{&1}"),
      description: sequence(:description, &"Description #{&1}")
    }
  end
end
