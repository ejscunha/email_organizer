defmodule EmailOrganizer.LLM do
  @moduledoc """
  Module for interacting with LangChain.
  """

  require Logger

  alias EmailOrganizer.Email
  alias EmailOrganizer.Email.Email, as: EmailRecord
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Function
  alias LangChain.Message

  @chat_model ChatOpenAI.new!(%{model: "gpt-4o", temperature: 0, stream: false})

  @categorize_email_messages [
    Message.new_system!(~s(You are a helpful email classifier.
      You will be given an email and you will need to categorize it into one of the categories available, according to their name and description.
      You should use the email details which contain the following fields: from, recipients, subject, text, html, date.
      You should return the category id and also make a summary of the email and return it as a string.
      The summary should be a short description of the email content.
      The summary should be in the same language as the email.
      The summary should be no more than 100 characters.
      You should return the category id and the summary as a JSON object with the keys `category_id` and `summary` respectively.
      If there are no categories that fit the email, you should return `null` for category id and a summary of the email.
      Do not return any other text than the JSON object and don't use any markdown formatting.
      )),
    Message.new_user!("Classify and summarize the email.")
  ]

  @spec categorize_email(EmailRecord.t()) :: {:ok, map()} | {:error, :decoding_error}
  def categorize_email(email) do
    {:ok, updated_chain} =
      %{llm: @chat_model, custom_context: %{email_id: email.external_id}}
      |> LLMChain.new!()
      |> LLMChain.add_messages(@categorize_email_messages)
      |> LLMChain.add_tools([available_categories_function(), get_email_details_function()])
      |> LLMChain.run(mode: :while_needs_response)

    case Jason.decode(updated_chain.last_message.content) do
      {:ok, result} ->
        {:ok, result}

      {:error, reason} ->
        Logger.error("Error decoding email classification result",
          reason: inspect(reason),
          result: updated_chain.last_message.content
        )

        {:error, :decoding_error}
    end
  end

  defp available_categories_function do
    Function.new!(%{
      name: "available_categories",
      description: "Return JSON object of the available categories.",
      function: fn _args, _context ->
        json_data =
          Email.list_categories()
          |> Enum.map(&Map.take(&1, [:id, :name, :description]))
          |> Jason.encode!()

        {:ok, json_data}
      end
    })
  end

  defp get_email_details_function do
    Function.new!(%{
      name: "email_details",
      description: "Return JSON object of the email details.",
      function: fn _args, %{email_id: email_id} ->
        json_data =
          email_id
          |> Email.get_email_by_external_id()
          |> Map.take([:from, :recipients, :subject, :text, :date])
          |> Jason.encode!()

        {:ok, json_data}
      end
    })
  end
end
