defmodule EmailOrganizer.Email do
  @moduledoc """
  The Email context.
  """

  import Ecto.Query, warn: false

  require Logger

  alias EmailOrganizer.Account.User
  alias EmailOrganizer.Email.Category
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
  @spec upsert_subscription(map()) :: {:ok, Subscription.t()} | {:error, Ecto.Changeset.t()}
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

  @spec subscribe_user_emails(User.t(), String.t()) :: :ok | :error
  def subscribe_user_emails(user, auth_token) do
    with %Subscription{} = subscription <- get_subscription_by_user_id(user.id),
         true <- DateTime.after?(subscription.expires_at, DateTime.utc_now()) do
      Logger.debug("User subscription is still active", user_id: user.id)
      :ok
    else
      _other -> do_subscribe_user_emails(user, auth_token)
    end
  end

  defp do_subscribe_user_emails(user, auth_token) do
    with {:ok, susbscribe_response} <- Gmail.subscribe_user_emails(auth_token),
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

  @spec process_email_notification(String.t(), String.t()) :: :ok | :error
  def process_email_notification(email, email_id) do
    Logger.info("Processing email notification", email: email, email_id: email_id)
    :ok
  end
end
