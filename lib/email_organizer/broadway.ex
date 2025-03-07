defmodule EmailOrganizer.Broadway do
  @moduledoc """
  Broadway module for handling email notifications from Google Cloud Pub/Sub.
  """

  use Broadway

  require Logger

  alias Broadway.Message
  alias EmailOrganizer.Email
  alias EmailOrganizer.Utils

  @project_id Application.compile_env(:email_organizer, :pub_sub_project_id)
  @subscription Application.compile_env(:email_organizer, :pub_sub_subscription)
  @producer_module Application.compile_env(:email_organizer, [:broadway, :producer_module])

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {@producer_module, goth: EmailOrganizer.Goth, subscription: get_subscription_name()}
      ],
      processors: [default: []],
      batchers: [
        default: [
          batch_size: 10,
          batch_timeout: 2_000
        ]
      ]
    )
  end

  @impl true
  def handle_message(_processor, %Message{data: data} = message, _context) do
    Logger.debug("Received message from Google Cloud PubSub", message: inspect(message))

    case Jason.decode(data) do
      {:ok, %{"emailAddress" => email, "historyId" => email_id}} ->
        Email.process_email_notification(email, email_id)

      {:error, reason} ->
        Logger.error("Failed to JSON decode Google Cloud PubSub message",
          data: data,
          reason: inspect(reason)
        )
    end

    message
  end

  @impl true
  def handle_batch(_batcher, messages, _batch_info, _context) do
    Logger.debug("Acknowledging batch of messages on Google Cloud PubSub: #{inspect(messages)}")
    messages
  end

  defp get_subscription_name do
    "projects/#{Utils.get_config_value(@project_id)}/subscriptions/#{Utils.get_config_value(@subscription)}"
  end
end
