defmodule EmailOrganizer.Email.Jobs.ArchiveEmail do
  @moduledoc """
  Job for archiving emails.
  """

  use Oban.Worker, queue: :email_archive

  require Logger

  alias EmailOrganizer.Email
  alias EmailOrganizer.Email.Email, as: EmailRecord
  alias EmailOrganizer.Google.Gmail
  alias EmailOrganizer.Repo

  @spec enqueue!(String.t(), [String.t()]) :: Oban.Job.t()
  def enqueue!(email_id, label_ids) do
    %{email_id: email_id, label_ids: label_ids}
    |> __MODULE__.new()
    |> Oban.insert!()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"email_id" => email_id, "label_ids" => label_ids}}) do
    Logger.info("Archiving email", email_id: email_id)

    with %EmailRecord{} = email <- Email.get_email_by_external_id(email_id),
         email = Repo.preload(email, :user),
         :ok <- Gmail.archive_email(email.user.auth_token, email.external_id, label_ids) do
      Logger.info("Email archived", email_id: email_id)
      :ok
    else
      nil ->
        Logger.error("Email not found", email_id: email_id)
        {:cancel, :email_not_found}

      {:error, reason} ->
        Logger.error("Error archiving email", email_id: email_id, reason: reason)
        {:error, reason}
    end
  end
end
