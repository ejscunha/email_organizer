defmodule EmailOrganizer.Account do
  @moduledoc """
  The Account context.
  """

  import Ecto.Query, warn: false

  alias EmailOrganizer.Account.User
  alias EmailOrganizer.Repo

  @doc """
  Gets a single user.

  ## Examples

      iex> get_user(123)
      %User{}

      iex> get_user(456)
      nil

  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("test@example.com")
      %User{}

      iex> get_user_by_email("nonexistent@example.com")
      nil

  """
  def get_user_by_email(email), do: Repo.get_by(User, email: email)

  @doc """
  Upserts a user.

  ## Examples

      iex> upsert_user(%{name: "name", email: "email@example.com"})
      {:ok, %User{name: "name", email: "email@example.com"}}

      iex> upsert_user(%{email: nil})
      {:error, %Ecto.Changeset{}}
  """
  @spec upsert_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def upsert_user(params) do
    params
    |> User.changeset()
    |> Repo.insert(
      conflict_target: :email,
      on_conflict: {:replace, [:name, :auth_token, :auth_token_expires_at, :refresh_token]}
    )
  end
end
