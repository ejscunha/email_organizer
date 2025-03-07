defmodule EmailOrganizer.Email.Category do
  @moduledoc """
  A category for an email.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias EmailOrganizer.Account.User

  @type t() :: %__MODULE__{}

  schema "categories" do
    field :name, :string
    field :description, :string

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t() | Changeset.t(), map()) :: Changeset.t()
  def changeset(category \\ %__MODULE__{}, attrs) do
    category
    |> cast(attrs, [:name, :description, :user_id])
    |> validate_required([:name, :description, :user_id])
    |> assoc_constraint(:user)
  end
end
