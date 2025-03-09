defmodule EmailOrganizer.BrowserTest do
  @moduledoc """
  Test the Browser module.
  """

  use ExUnit.Case
  use Mimic

  alias EmailOrganizer.Browser
  alias Wallaby.Element
  alias Wallaby.Session

  @mock_session %Session{
    id: "session-123",
    url: "http://localhost:4444/wd/hub",
    session_url: "http://localhost:4444/wd/hub/session/session-123",
    driver: Wallaby.Selenium,
    capabilities: %{},
    server: :none,
    screenshots: []
  }

  @mock_element %Element{
    id: "element-123",
    url: "http://localhost:4444/wd/hub",
    session_url: "http://localhost:4444/wd/hub/session/session-123",
    parent: "parent-123",
    driver: Wallaby.Selenium,
    screenshots: []
  }

  describe "visit_link/1" do
    test "successfully visits a link" do
      expect(Wallaby, :start_session, fn -> {:ok, @mock_session} end)
      expect(Wallaby.Browser, :visit, fn _session, "https://example.com" -> @mock_session end)

      assert {:ok, %Session{}} = Browser.visit_link("https://example.com")
    end

    test "returns error when session cannot be started" do
      expect(Wallaby, :start_session, fn -> {:error, :session_error} end)

      assert {:error, :session_error} = Browser.visit_link("https://example.com")
    end
  end

  describe "end_session/1" do
    test "successfully ends a session" do
      expect(Wallaby, :end_session, fn @mock_session -> :ok end)

      assert :ok = Browser.end_session(@mock_session)
    end

    test "returns error when session cannot be ended" do
      expect(Wallaby, :end_session, fn @mock_session -> {:error, :session_error} end)

      assert {:error, :session_error} = Browser.end_session(@mock_session)
    end
  end

  describe "get_page_body/1" do
    test "returns the HTML body of the page" do
      expect(Wallaby.Browser, :find, fn @mock_session, _query -> @mock_element end)

      expect(Element, :attr, fn @mock_element, "outerHTML" -> "<html><body>Test</body></html>" end)

      assert "<html><body>Test</body></html>" = Browser.get_page_body(@mock_session)
    end
  end

  describe "submit_form/2" do
    test "successfully submits a form when button exists" do
      Wallaby.Browser
      |> expect(:has?, fn @mock_session, _query -> true end)
      |> expect(:click, fn @mock_session, _query -> @mock_session end)

      assert :ok = Browser.submit_form(@mock_session, "button[type='submit']")
    end

    test "returns error when submit button not found" do
      expect(Wallaby.Browser, :has?, fn @mock_session, _query -> false end)

      assert {:error, :no_submit_button_found} =
               Browser.submit_form(@mock_session, "button[type='submit']")
    end
  end

  describe "click_button/2" do
    test "successfully clicks a button when it exists" do
      Wallaby.Browser
      |> expect(:has?, fn @mock_session, _query -> true end)
      |> expect(:click, fn @mock_session, _query -> @mock_session end)

      assert :ok = Browser.click_button(@mock_session, ".button-class")
    end

    test "returns error when button not found" do
      expect(Wallaby.Browser, :has?, fn @mock_session, _query -> false end)

      assert {:error, :no_button_found} = Browser.click_button(@mock_session, ".button-class")
    end
  end

  describe "fill_input/4 for text, email, and textarea" do
    test "successfully fills a text input" do
      Wallaby.Browser
      |> expect(:has?, fn @mock_session, _query -> true end)
      |> expect(:fill_in, fn @mock_session, _query, [with: "test value"] ->
        @mock_session
      end)

      assert :ok = Browser.fill_input(@mock_session, "#text-input", "test value", "text")
    end

    test "successfully fills an email input" do
      Wallaby.Browser
      |> expect(:has?, fn @mock_session, _query -> true end)
      |> expect(:fill_in, fn @mock_session, _query, [with: "test@example.com"] ->
        @mock_session
      end)

      assert :ok = Browser.fill_input(@mock_session, "#email-input", "test@example.com", "email")
    end

    test "successfully fills a textarea" do
      Wallaby.Browser
      |> expect(:has?, fn @mock_session, _query -> true end)
      |> expect(:fill_in, fn @mock_session, _query, [with: "long text"] ->
        @mock_session
      end)

      assert :ok = Browser.fill_input(@mock_session, "textarea", "long text", "textarea")
    end

    test "returns error when text input not found" do
      expect(Wallaby.Browser, :has?, fn @mock_session, _query -> false end)

      assert {:error, :no_input_found} =
               Browser.fill_input(@mock_session, "#text-input", "test value", "text")
    end
  end

  describe "fill_input/4 for select" do
    test "successfully selects an option" do
      Wallaby.Browser
      |> expect(:has?, fn @mock_session, _query -> true end)
      |> expect(:click, fn @mock_session, _query -> @mock_session end)

      assert :ok = Browser.fill_input(@mock_session, "select", "Option 1", "select")
    end

    test "returns error when option not found" do
      expect(Wallaby.Browser, :has?, fn @mock_session, _query -> false end)

      assert {:error, :no_input_found} =
               Browser.fill_input(@mock_session, "select", "Option 1", "select")
    end
  end

  describe "fill_input/4 for checkbox" do
    test "successfully checks a checkbox" do
      Wallaby.Browser
      |> expect(:has?, fn @mock_session, _query -> true end)
      |> expect(:set_value, fn @mock_session, _query, :selected -> @mock_session end)

      assert {:ok, @mock_session} =
               Browser.fill_input(@mock_session, "#checkbox", "true", "checkbox")
    end

    test "successfully unchecks a checkbox" do
      Wallaby.Browser
      |> expect(:has?, fn @mock_session, _query -> true end)
      |> expect(:set_value, fn @mock_session, _query, :unselected ->
        @mock_session
      end)

      assert {:ok, @mock_session} =
               Browser.fill_input(@mock_session, "#checkbox", "false", "checkbox")
    end

    test "returns error when checkbox not found" do
      expect(Wallaby.Browser, :has?, fn @mock_session, _query -> false end)

      assert {:error, :no_input_found} =
               Browser.fill_input(@mock_session, "#checkbox", "true", "checkbox")
    end
  end

  describe "fill_input/4 for radio" do
    test "successfully selects a radio button" do
      Wallaby.Browser
      |> expect(:has?, fn @mock_session, _query -> true end)
      |> expect(:set_value, fn @mock_session, _query, :selected -> @mock_session end)

      assert :ok = Browser.fill_input(@mock_session, "#radio", "any-value", "radio")
    end

    test "returns error when radio button not found" do
      expect(Wallaby.Browser, :has?, fn @mock_session, _query -> false end)

      assert {:error, :no_input_found} =
               Browser.fill_input(@mock_session, "#radio", "any-value", "radio")
    end
  end
end
