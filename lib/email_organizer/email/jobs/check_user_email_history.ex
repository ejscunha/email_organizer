defmodule EmailOrganizer.Email.Jobs.CheckUserEmailHistory do
  @moduledoc """
  A worker that checks the user's email history.
  """

  use Oban.Worker, queue: :email_history

  require Logger

  alias EmailOrganizer.Account
  alias EmailOrganizer.Account.User
  alias EmailOrganizer.Email
  alias EmailOrganizer.Email.Jobs.FetchEmail
  alias EmailOrganizer.Email.Subscription
  alias EmailOrganizer.Google.Gmail

  @spec enqueue!(User.t()) :: Oban.Job.t()
  def enqueue!(email) do
    %{email: email}
    |> __MODULE__.new()
    |> Oban.insert!()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"email" => email} = _args}) do
    Logger.info("Checking user emails history", email: email)

    with {:user, %User{} = user} <- {:user, Account.get_user_by_email(email)},
         {:subscription, %Subscription{} = subscription} <-
           {:subscription, Email.get_subscription_by_user_id(user.id)},
         Logger.info("Fetching user email history",
           user_id: user.id,
           email_id: subscription.last_id
         ),
         {:ok, history} <- Gmail.list_history(user, subscription.last_id),
         Logger.info("Found #{Enum.count(history.message_ids)} new email changes",
           user_id: user.id
         ),
         :ok <- Enum.each(history.message_ids, &FetchEmail.enqueue!(user, &1)),
         :ok <- Email.update_subscription_last_id(subscription.id, history.new_history_id) do
      :ok
    else
      {:user, nil} ->
        Logger.error("User not found", email: email)
        {:cancel, :user_not_found}

      {:subscription, nil} ->
        Logger.error("Subscription not found", email: email)
        {:cancel, :subscription_not_found}

      {:error, reason} ->
        Logger.error("Error checking user emails history", reason: inspect(reason))
        {:error, reason}
    end
  end
end
