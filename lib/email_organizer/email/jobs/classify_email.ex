defmodule EmailOrganizer.Email.Jobs.ClassifyEmail do
  @moduledoc """
  Job for classifying emails.
  """

  use Oban.Worker, queue: :email_classify

  require Logger

  alias EmailOrganizer.Email
  alias EmailOrganizer.Email.Email, as: EmailRecord
  alias EmailOrganizer.Email.Jobs.ArchiveEmail
  alias EmailOrganizer.LLM

  @spec enqueue!(String.t()) :: Oban.Job.t()
  def enqueue!(email_id) do
    %{email_id: email_id}
    |> __MODULE__.new()
    |> Oban.insert!()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"email_id" => email_id}}) do
    Logger.info("Classifying email", email_id: email_id)

    with %EmailRecord{} = email <- Email.get_email_by_external_id(email_id),
         {:ok, result} <- LLM.categorize_email(email),
         %Oban.Job{} <- ArchiveEmail.enqueue!(email_id),
         {:ok, _email} <-
           email
           |> Map.from_struct()
           |> Map.merge(%{
             summary: result["summary"],
             category_id: result["category_id"]
           })
           |> Email.upsert_email() do
      Logger.info("Email classified", email_id: email_id)
      :ok
    else
      nil ->
        Logger.error("Email not found", email_id: email_id)
        {:cancel, :email_not_found}

      {:error, reason} ->
        Logger.error("Error classifying email", email_id: email_id, reason: reason)
        {:error, reason}
    end
  end
end
