defmodule EmailOrganizer.Email.Jobs.FetchEmail do
  @moduledoc """
  A worker that fetches an email.
  """

  use Oban.Worker, queue: :email_fetch, unique: [period: :infinity, keys: [:user_id, :email_id]]

  require Logger

  alias EmailOrganizer.Account
  alias EmailOrganizer.Account.User
  alias EmailOrganizer.Email
  alias EmailOrganizer.Email.Jobs.ClassifyEmail
  alias EmailOrganizer.Google.Gmail

  @spec enqueue!(User.t(), String.t()) :: Oban.Job.t()
  def enqueue!(user, email_id) do
    %{user_id: user.id, email_id: email_id}
    |> __MODULE__.new()
    |> Oban.insert!()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id, "email_id" => email_id} = _args}) do
    Logger.info("Fetching email", user_id: user_id, email_id: email_id)

    with %User{} = user <- Account.get_user(user_id),
         {:ok, message} <- Gmail.get_message(user.auth_token, email_id),
         Logger.info("Fetched email message", user_id: user_id, email_id: email_id),
         email_attrs = Map.merge(message, %{user_id: user_id, external_id: email_id}),
         {:ok, _email} <- Email.upsert_email(email_attrs) do
      ClassifyEmail.enqueue!(email_id)
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
        Logger.error("Error fetching email",
          user_id: user_id,
          email_id: email_id,
          reason: inspect(reason)
        )

        {:error, reason}
    end
  end
end
