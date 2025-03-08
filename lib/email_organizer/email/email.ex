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
    field :html, :string
    field :date, :utc_datetime_usec
    field :summary, :string
    field :label_ids, {:array, :string}

    belongs_to :category, Category
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), map()) :: Changeset.t()
  def changeset(email \\ %__MODULE__{}, attrs) do
    attrs = process_attributes(attrs)

    email
    |> cast(attrs, [
      :external_id,
      :from,
      :recipients,
      :subject,
      :text,
      :html,
      :date,
      :summary,
      :label_ids,
      :user_id,
      :category_id
    ])
    |> validate_required([:external_id, :from, :recipients, :subject, :date, :user_id])
    |> assoc_constraint(:user)
    |> assoc_constraint(:category)
  end

  defp process_attributes(attrs), do: Enum.into(attrs, %{}, &process_attribute/1)

  defp process_attribute({:from, value}) do
    {:from, process_recipient(value)}
  end

  defp process_attribute({:recipients, recipients}) when is_list(recipients) do
    {:recipients, Enum.map(recipients, &process_recipient/1)}
  end

  defp process_attribute(other), do: other

  defp process_recipient({name, email}), do: "#{name} <#{email}>"
  defp process_recipient(email), do: email
end
