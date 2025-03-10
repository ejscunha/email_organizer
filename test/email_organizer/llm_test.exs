defmodule EmailOrganizer.LLMTest do
  @moduledoc """
  Test suite for the LLM module
  """

  use EmailOrganizer.DataCase, async: true
  use Mimic

  alias EmailOrganizer.Browser
  alias EmailOrganizer.LLM
  alias LangChain.Chains.LLMChain
  alias LangChain.Message

  describe "categorize_email/1" do
    test "successfully categorizes an email" do
      email = insert(:email)

      expect(LLMChain, :run, fn _chain, [mode: :while_needs_response] ->
        {:ok,
         %LLMChain{
           last_message: %Message{
             content: ~s({"category_id": 1, "summary": "A test email summary"})
           }
         }}
      end)

      result = LLM.categorize_email(email)

      assert {:ok, %{"category_id" => 1, "summary" => "A test email summary"}} = result
    end

    test "handles decoding error" do
      email = insert(:email)

      expect(LLMChain, :run, fn _chain, [mode: :while_needs_response] ->
        {:ok,
         %LLMChain{
           last_message: %Message{
             content: "Invalid JSON response"
           }
         }}
      end)

      result = LLM.categorize_email(email)

      assert {:error, :decoding_error} = result
    end
  end

  describe "unsubscribe_from_email/1" do
    test "successfully unsubscribes from an email" do
      link = "https://example.com/unsubscribe"
      email = insert(:email, html: ~s(<a href="#{link}">Unsubscribe</a>))

      expect(Browser, :visit_link, fn ^link ->
        {:ok,
         %Wallaby.Session{
           id: "session-123",
           url: "http://localhost:4444/wd/hub",
           session_url: "http://localhost:4444/wd/hub/session/session-123",
           driver: Wallaby.Selenium,
           capabilities: %{},
           server: :none,
           screenshots: []
         }}
      end)

      expect(LLMChain, :run, fn _chain, [mode: :while_needs_response] ->
        {:ok,
         %LLMChain{
           last_message: %Message{
             content:
               ~s({"success": true, "message": "Successfully unsubscribed", "link_found": true})
           }
         }}
      end)

      expect(Browser, :end_session, fn _session -> :ok end)

      result = LLM.unsubscribe_from_email(email)

      assert {:ok,
              %{"success" => true, "message" => "Successfully unsubscribed", "link_found" => true}} =
               result
    end

    test "handles case when no unsubscribe link is found" do
      email = insert(:email)

      result = LLM.unsubscribe_from_email(email)

      assert {:ok,
              %{
                "success" => false,
                "message" => "No unsubscribe link found",
                "link_found" => false
              }} = result
    end

    test "handles error when visiting unsubscribe link" do
      link = "https://example.com/unsubscribe"
      email = insert(:email, html: ~s(<a href="#{link}">Unsubscribe</a>))

      expect(Browser, :visit_link, fn ^link ->
        {:error, "Failed to visit link"}
      end)

      result = LLM.unsubscribe_from_email(email)

      assert {:ok,
              %{
                "success" => false,
                "message" => "Error visiting unsubscribe link",
                "link_found" => false
              }} = result
    end
  end
end
