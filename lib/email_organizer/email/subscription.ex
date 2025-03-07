defmodule EmailOrganizer.Email.Subscription do
  @moduledoc """
  A schema to track user email subscriptions.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias EmailOrganizer.Account.User

  @type t() :: %__MODULE__{}

  schema "subscriptions" do
    field :last_id, :integer
    field :expires_at, :utc_datetime_usec

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t() | Changeset.t(), map()) :: Changeset.t()
  def changeset(subscription \\ %__MODULE__{}, attrs) do
    subscription
    |> cast(attrs, [:last_id, :expires_at, :user_id])
    |> validate_required([:user_id])
    |> assoc_constraint(:user)
  end
end
