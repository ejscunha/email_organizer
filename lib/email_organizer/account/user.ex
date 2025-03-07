defmodule EmailOrganizer.Account.User do
  @moduledoc """
  User module schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "users" do
    field :email, :string
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t() | Changeset.t(), map()) :: Changeset.t()
  def changeset(user \\ %__MODULE__{}, attrs) do
    user
    |> cast(attrs, [:email, :name])
    |> validate_required([:email, :name])
    |> unique_constraint(:email)
  end
end
