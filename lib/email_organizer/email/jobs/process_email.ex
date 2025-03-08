defmodule EmailOrganizer.Email.Jobs.ProcessEmail do
  @moduledoc """
  A worker that processes an email.
  """

  use Oban.Worker, queue: :email_process

  require Logger

  alias EmailOrganizer.Account
  alias EmailOrganizer.Account.User
  alias EmailOrganizer.Google.Gmail

  @spec enqueue!(User.t(), String.t()) :: Oban.Job.t()
  def enqueue!(user, email_id) do
    %{user_id: user.id, email_id: email_id}
    |> __MODULE__.new()
    |> Oban.insert!()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id, "email_id" => email_id} = _args}) do
    Logger.info("Processing email", user_id: user_id, email_id: email_id)

    with %User{} = user <- Account.get_user(user_id),
         {:ok, message} <- Gmail.get_message(user.auth_token, email_id) do
      Logger.debug("Email to be processed", email: inspect(message))
      :ok
    else
      nil ->
        Logger.error("User not found", user_id: user_id)
        {:cancel, :user_not_found}

      {:error, {:parsing_error, reason}} ->
        Logger.error("Error parsing email message",
          user_id: user_id,
          email_id: email_id,
          reason: inspect(reason)
        )

        {:cancel, :parsing_error}

      {:error, reason} ->
        Logger.error("Error processing email",
          user_id: user_id,
          email_id: email_id,
          reason: inspect(reason)
        )

        {:error, reason}
    end
  end
end
