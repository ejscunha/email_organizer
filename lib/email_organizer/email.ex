defmodule EmailOrganizer.Email do
  @moduledoc """
  The Email context.
  """

  import Ecto.Query, warn: false

  require Logger

  alias Ecto.Changeset
  alias EmailOrganizer.Account.User
  alias EmailOrganizer.Email.Category
  alias EmailOrganizer.Email.Email
  alias EmailOrganizer.Email.Subscription
  alias EmailOrganizer.Google.Gmail
  alias EmailOrganizer.Repo

  @doc """
  Returns the list of categories.

  ## Examples

      iex> list_categories()
      [%Category{}, ...]

  """
  def list_categories do
    Repo.all(Category)
  end

  @doc """
  Returns the list of categories for a specific user.

  ## Examples

      iex> list_categories_by_user(123)
      [%Category{}, ...]

  """
  @spec list_categories_by_user(integer()) :: [Category.t()]
  def list_categories_by_user(user_id) do
    Category
    |> where([c], c.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Gets a single category.

  Raises `Ecto.NoResultsError` if the Category does not exist.

  ## Examples

      iex> get_category!(123)
      %Category{}

      iex> get_category!(456)
      ** (Ecto.NoResultsError)

  """
  def get_category!(id), do: Repo.get!(Category, id)

  @doc """
  Creates a category.

  ## Examples

      iex> create_category(%{field: value})
      {:ok, %Category{}}

      iex> create_category(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a category.

  ## Examples

      iex> update_category(category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_category(category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a category.

  ## Examples

      iex> delete_category(category)
      {:ok, %Category{}}

      iex> delete_category(category)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(category)
      %Ecto.Changeset{data: %Category{}}

  """
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  @doc """
  Upserts a user email subscription.

  ## Examples

      iex> upsert_subscription(%{last_id: 123, expires_at: DateTime.add(DateTime.utc_now(), 7, :day), user_id: 123})
      {:ok, %Subscription{last_id: 123, user_id: 123}}

      iex> upsert_subscription(%{last_id: nil})
      {:error, %Ecto.Changeset{}}
  """
  @spec upsert_subscription(map()) :: {:ok, Subscription.t()} | {:error, Changeset.t()}
  def upsert_subscription(params) do
    params
    |> Subscription.changeset()
    |> Repo.insert(conflict_target: :user_id, on_conflict: {:replace, [:last_id, :expires_at]})
  end

  @doc """
  Gets a subscription by user id.

  ## Examples

      iex> get_subscription_by_user_id(123)
      %Subscription{}
  """
  @spec get_subscription_by_user_id(integer()) :: Subscription.t() | nil
  def get_subscription_by_user_id(user_id) do
    Repo.get_by(Subscription, user_id: user_id)
  end

  @spec update_subscription_last_id(integer(), integer()) :: :ok | {:error, any()}
  def update_subscription_last_id(subscription_id, last_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.one(:subscription, where(Subscription, id: ^subscription_id))
    |> Ecto.Multi.run(:update_last_id, fn repo, %{subscription: subscription} ->
      if subscription.last_id < last_id do
        subscription
        |> Subscription.changeset(%{last_id: last_id})
        |> repo.update()
      else
        {:ok, :no_update}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _changes} -> :ok
      {:error, _name, reason, _changes} -> {:error, reason}
    end
  end

  @spec subscribe_user_emails(User.t()) :: :ok | :error
  def subscribe_user_emails(user) do
    with {:ok, susbscribe_response} <- Gmail.subscribe_user_emails(user.auth_token),
         {:ok, _subscription} <-
           upsert_subscription(%{
             last_id: susbscribe_response.history_id,
             expires_at: susbscribe_response.expires_at,
             user_id: user.id
           }) do
      Logger.info("Subscribed to user emails", user_id: user.id)
      :ok
    else
      {:error, reason} ->
        Logger.error("Error subscribing to user emails", reason: inspect(reason))
        :error
    end
  end

  @doc """
  Upserts an email.

  ## Examples

      iex> upsert_email(%{field: value})
      {:ok, %Email{}}

      iex> upsert_email(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  @spec upsert_email(map()) :: {:ok, Email.t()} | {:error, Changeset.t()}
  def upsert_email(attrs \\ %{}) do
    %Email{}
    |> Email.changeset(attrs)
    |> Repo.insert(
      conflict_target: :external_id,
      on_conflict:
        {:replace,
         [
           :from,
           :recipients,
           :subject,
           :text,
           :date,
           :summary,
           :user_id,
           :category_id
         ]}
    )
  end

  @doc """
  Gets an email by external id.

  ## Examples

      iex> get_email_by_external_id("123")
      %Email{}

      iex> get_email_by_external_id("456")
      nil
  """
  @spec get_email_by_external_id(String.t()) :: Email.t() | nil
  def get_email_by_external_id(external_id), do: Repo.get_by(Email, external_id: external_id)

  @doc """
  Gets a single email.

  Raises `Ecto.NoResultsError` if the Email does not exist.

  ## Examples

      iex> get_email!(123)
      %Email{}

      iex> get_email!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_email!(integer()) :: Email.t()
  def get_email!(id), do: Repo.get!(Email, id)

  @doc """
  Lists emails for a specific category with pagination and sorting.

  ## Examples

      iex> list_emails_by_category(category_id, %{page: 1, per_page: 10, sort_by: :date, sort_order: :desc})
      %{entries: [%Email{}, ...], page_number: 1, page_size: 10, total_entries: 20, total_pages: 2}
  """
  @spec list_emails_by_category(integer(), map()) :: Scrivener.Page.t(Email.t())
  def list_emails_by_category(category_id, opts \\ %{}) do
    page = Map.get(opts, :page, 1)
    per_page = Map.get(opts, :per_page, 10)
    sort_by = Map.get(opts, :sort_by, :date)
    sort_order = Map.get(opts, :sort_order, :desc)

    Email
    |> where(category_id: ^category_id)
    |> order_by([{^sort_order, ^sort_by}])
    |> Repo.paginate(page: page, page_size: per_page)
  end

  @doc """
  Deletes multiple emails.

  ## Examples

      iex> delete_emails([1, 2, 3])
      {3, nil}
  """
  @spec delete_emails([integer()]) :: :ok
  def delete_emails(email_ids) when is_list(email_ids) do
    Email
    |> where([e], e.id in ^email_ids)
    |> Repo.delete_all()

    :ok
  end
end
