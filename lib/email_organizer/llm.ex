defmodule EmailOrganizer.LLM do
  @moduledoc """
  Module for interacting with LangChain.
  """

  require Logger

  alias EmailOrganizer.Browser
  alias EmailOrganizer.Email
  alias EmailOrganizer.Email.Email, as: EmailRecord
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Function
  alias LangChain.FunctionParam
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

  @unsubscribe_email_messages [
    Message.new_system!(~s|You are an email unsubscription agent.
      You will have to get the email unsubscription page body HTML and then perform all the necessary actions to unsubscribe successfully.
      If necessary, you can get the body HTML again to reevaluate the page content. However, you should try to perform all the actions in one call to get_page_body, since it is an expensive operation.

      You have access to the following tools to help you complete the task:
      1. get_page_body - Get the body HTML of the email unsubscription page.
      2. submit_form - Submit a form on the page, you need to provide the CSS selector of the form to submit
      3. click_button - Click on a button on the page, you need to provide the CSS selector of the button to click
      4. fill_input - Fill an input on the page, you need to provide the CSS selector and type of the input to fill.
         The supported types are: "text", "email", "select", "checkbox", "radio", "textarea".
         You also need to provide the value to fill the input with.
         For text, email and textarea inputs, the value should be a string.
         For select inputs, the value should be the text of the option to select.
         For checkbox and radio inputs, the value should be true if the checkbox or radio button should be checked, or false otherwise.

      Return a JSON object with the following keys:
      - `success`: boolean indicating if the unsubscription was successful
      - `message`: a description of what happened during the unsubscription process
      - `link_found`: boolean indicating if an unsubscription link was found

      Do not return any other text than the JSON object and don't use any markdown formatting.|),
    Message.new_user!("Help me unsubscribe from the email by performing all the necessary steps.")
  ]

  @spec categorize_email(EmailRecord.t()) :: {:ok, map()} | {:error, :decoding_error}
  def categorize_email(email) do
    {:ok, llm_chain} =
      %{llm: @chat_model, custom_context: %{email_id: email.external_id}}
      |> LLMChain.new!()
      |> LLMChain.add_messages(@categorize_email_messages)
      |> LLMChain.add_tools([available_categories_function(), get_email_details_function()])
      |> LLMChain.run(mode: :while_needs_response)

    process_result(llm_chain.last_message.content, email.id)
  end

  @spec unsubscribe_from_email(EmailRecord.t()) :: {:ok, map()} | {:error, :decoding_error}
  def unsubscribe_from_email(email) do
    result =
      with link when is_binary(link) <- get_unsubscribe_link(email.html),
           {:ok, session} <- Browser.visit_link(link),
           {:ok, llm_chain} <-
             %{llm: @chat_model, custom_context: %{session: session, email_id: email.id}}
             |> LLMChain.new!()
             |> LLMChain.add_messages(@unsubscribe_email_messages)
             |> LLMChain.add_tools([
               get_page_body_function(),
               submit_form_function(),
               click_button_function(),
               fill_input_function()
             ])
             |> LLMChain.run(mode: :while_needs_response) do
        Browser.end_session(session)
        llm_chain.last_message.content
      else
        nil ->
          Jason.encode!(%{
            "success" => false,
            "message" => "No unsubscribe link found",
            "link_found" => false
          })

        {:error, _reason} ->
          Jason.encode!(%{
            "success" => false,
            "message" => "Error visiting unsubscribe link",
            "link_found" => false
          })
      end

    process_result(result, email.id)
  end

  defp process_result(result, email_id) do
    case Jason.decode(result) do
      {:ok, result} ->
        {:ok, result}

      {:error, reason} ->
        Logger.error("Error decoding result",
          reason: inspect(reason),
          result: result,
          email_id: email_id
        )

        {:error, :decoding_error}
    end
  end

  defp available_categories_function do
    Function.new!(%{
      name: "available_categories",
      description: "Return JSON object of the available categories.",
      function: fn _args, _context ->
        Logger.debug("Getting available categories")

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
        Logger.debug("Getting email details", email_id: email_id)

        json_data =
          email_id
          |> Email.get_email_by_external_id()
          |> Map.take([:from, :recipients, :subject, :text, :date])
          |> Jason.encode!()

        {:ok, json_data}
      end
    })
  end

  defp get_page_body_function do
    Function.new!(%{
      name: "get_page_body",
      description: "Get the body HTML of the page",
      function: fn _args, %{session: session, email_id: email_id} ->
        Logger.debug("Getting page body", email_id: email_id)
        {:ok, Jason.encode!(%{body: Browser.get_page_body(session)})}
      end
    })
  end

  defp submit_form_function do
    Function.new!(%{
      name: "submit_form",
      description: "Submit a form on the page",
      parameters: [
        FunctionParam.new!(%{
          name: "submit_css_selector",
          type: :string,
          description: "The CSS selector of the form to submit"
        })
      ],
      function: fn %{"submit_css_selector" => submit_css_selector},
                   %{session: session, email_id: email_id} ->
        Logger.debug("Submitting form", email_id: email_id)

        case Browser.submit_form(session, submit_css_selector) do
          :ok ->
            Logger.debug("Form submitted", email_id: email_id)
            {:ok, "form submited"}

          {:error, reason} ->
            Logger.error("Error submitting form", reason: inspect(reason), email_id: email_id)
            {:ok, "Error submitting form"}
        end
      end
    })
  end

  defp click_button_function do
    Function.new!(%{
      name: "click_button",
      description: "Click on a button on the page",
      parameters: [
        FunctionParam.new!(%{
          name: "button_css_selector",
          type: :string,
          description: "The CSS selector of the button to click"
        })
      ],
      function: fn %{"button_css_selector" => button_css_selector},
                   %{session: session, email_id: email_id} ->
        Logger.debug("Clicking button", email_id: email_id)

        case Browser.click_button(session, button_css_selector) do
          :ok ->
            Logger.debug("Button clicked", email_id: email_id)

            {:ok, "button clicked"}

          {:error, reason} ->
            Logger.error("Error clicking button", reason: inspect(reason), email_id: email_id)

            {:ok, "Error clicking button"}
        end
      end
    })
  end

  defp fill_input_function do
    Function.new!(%{
      name: "fill_input",
      description: "Fill an input on the page",
      parameters: [
        FunctionParam.new!(%{
          name: "input_css_selector",
          type: :string,
          description: "The CSS selector of the input to fill"
        }),
        FunctionParam.new!(%{
          name: "value",
          type: :string,
          description: "The value to fill the input with"
        }),
        FunctionParam.new!(%{
          name: "type",
          type: :string,
          description: "The type of the input to fill"
        })
      ],
      function: fn %{"input_css_selector" => input_css_selector, "value" => value, "type" => type},
                   %{session: session, email_id: email_id} ->
        Logger.debug("Filling input", email_id: email_id)

        case Browser.fill_input(session, input_css_selector, value, type) do
          :ok ->
            Logger.debug("Input filled", email_id: email_id)
            {:ok, "input filled"}

          {:error, reason} ->
            Logger.error("Error filling input", reason: inspect(reason), email_id: email_id)
            {:ok, "Error filling input"}
        end
      end
    })
  end

  defp get_unsubscribe_link(html) when is_binary(html) do
    case Floki.parse_document(html) do
      {:ok, document} ->
        document
        |> Floki.find("a")
        |> Enum.find_value(fn link ->
          text = link |> Floki.text() |> String.downcase()
          href = link |> Floki.attribute("href") |> List.first()

          (unsubscribe_text?(text) || unsubscribe_url?(href)) && href
        end)

      _ ->
        nil
    end
  end

  defp get_unsubscribe_link(_), do: nil

  defp unsubscribe_text?(text) do
    unsubscribe_keywords = [
      "unsubscribe",
      "opt out",
      "opt-out",
      "stop receiving",
      "cancel subscription",
      "remove me",
      "remove your email",
      "cancelar subscrição"
    ]

    Enum.any?(unsubscribe_keywords, &String.contains?(text, &1))
  end

  defp unsubscribe_url?(url) do
    unsubscribe_patterns = [
      "unsubscribe",
      "opt-out",
      "opt_out",
      "optout",
      "remove",
      "cancel"
    ]

    url = String.downcase(url)
    Enum.any?(unsubscribe_patterns, &String.contains?(url, &1))
  end
end
