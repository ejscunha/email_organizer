defmodule EmailOrganizer.Account.User do
  @moduledoc """
  User module schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias EmailOrganizer.Email.Category
  alias EmailOrganizer.Email.Subscription

  @type t :: %__MODULE__{}

  schema "users" do
    field :email, :string
    field :name, :string
    field :auth_token, :string
    field :auth_token_expires_at, :utc_datetime
    field :refresh_token, :string

    has_many :categories, Category
    has_one :subscription, Subscription

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t() | Changeset.t(), map()) :: Changeset.t()
  def changeset(user \\ %__MODULE__{}, attrs) do
    user
    |> cast(attrs, [:email, :name, :auth_token, :auth_token_expires_at, :refresh_token])
    |> validate_required([:email, :name])
    |> unique_constraint(:email)
  end
end
