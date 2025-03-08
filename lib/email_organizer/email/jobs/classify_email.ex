defmodule EmailOrganizer.Email.Jobs.ClassifyEmail do
  @moduledoc """
  Job for classifying emails.
  """

  use Oban.Worker, queue: :email_classify

  require Logger

  alias EmailOrganizer.Email
  alias EmailOrganizer.Email.Email, as: EmailRecord

  @spec enqueue!(String.t()) :: Oban.Job.t()
  def enqueue!(email_id) do
    %{email_id: email_id}
    |> __MODULE__.new()
    |> Oban.insert!()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"email_id" => email_id}}) do
    Logger.info("Classifying email", email_id: email_id)

    with %EmailRecord{} = _email <- Email.get_email_by_external_id(email_id) do
      Logger.info("Email to beclassified", email_id: email_id)
    end
  end
end
