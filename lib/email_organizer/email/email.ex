defmodule EmailOrganizer.Email.Email do
  @moduledoc """
  Module for managing email notifications.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias EmailOrganizer.Account.User
  alias EmailOrganizer.Email.Category

  @type t :: %__MODULE__{}

  schema "emails" do
    field :external_id, :string
    field :from, :string
    field :recipients, {:array, :string}
    field :subject, :string
    field :text, :string
    field :date, :utc_datetime_usec
    field :summary, :string

    belongs_to :category, Category
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), map()) :: Changeset.t()
  def changeset(email \\ %__MODULE__{}, attrs) do
    email
    |> cast(attrs, [
      :external_id,
      :from,
      :recipients,
      :subject,
      :text,
      :date,
      :summary,
      :user_id,
      :category_id
    ])
    |> validate_required([:external_id, :from, :recipients, :subject, :text, :date, :user_id])
    |> assoc_constraint(:user)
    |> assoc_constraint(:category)
  end
end
