defmodule EmailOrganizer.Browser do
  @moduledoc """
  Module for browser automation using Wallaby.
  Used for following unsubscribe links and filling out forms.
  """

  require Logger

  alias Wallaby.Element
  alias Wallaby.Browser
  alias Wallaby.Query

  @type session :: Wallaby.Session.t()

  @spec visit_link(String.t()) :: {:ok, session()} | {:error, any()}
  def visit_link(link) do
    with {:ok, session} <- Wallaby.start_session() do
      {:ok, Browser.visit(session, link)}
    end
  end

  @spec end_session(session()) :: :ok | {:error, any()}
  def end_session(session), do: Wallaby.end_session(session)

  @spec get_page_body(session()) :: String.t()
  def get_page_body(session) do
    session
    |> Browser.find(Query.css("body"))
    |> Element.attr("outerHTML")
  end

  @spec submit_form(session(), String.t()) :: :ok | {:error, any()}
  def submit_form(session, submit_css_selector) do
    query = Query.css(submit_css_selector)

    if Browser.has?(session, query) do
      Browser.click(session, query)
      :ok
    else
      {:error, :no_submit_button_found}
    end
  end

  @spec click_button(session(), String.t()) :: :ok | {:error, any()}
  def click_button(session, button_css_selector) do
    query = Query.css(button_css_selector)

    if Browser.has?(session, query) do
      Browser.click(session, query)
      :ok
    else
      {:error, :no_button_found}
    end
  end

  @spec fill_input(session(), String.t(), String.t(), String.t()) :: :ok | {:error, any()}
  def fill_input(session, input_css_selector, value, type)
      when type in ["text", "email", "textarea"] do
    query = Query.text_field(input_css_selector)

    if Browser.has?(session, query) do
      Browser.fill_in(session, query, with: value)
      :ok
    else
      {:error, :no_input_found}
    end
  end

  def fill_input(session, _input_css_selector, value, "select") do
    query = Query.option(value)

    if Browser.has?(session, query) do
      Browser.click(session, query)
      :ok
    else
      {:error, :no_input_found}
    end
  end

  def fill_input(session, input_css_selector, value, "checkbox") do
    query = Query.checkbox(input_css_selector)

    if Browser.has?(session, query) do
      cond do
        value == "true" -> {:ok, Browser.set_value(session, query, :selected)}
        value == "false" -> {:ok, Browser.set_value(session, query, :unselected)}
      end
    else
      {:error, :no_input_found}
    end
  end

  def fill_input(session, input_css_selector, _value, "radio") do
    query = Query.radio_button(input_css_selector)

    if Browser.has?(session, query) do
      Browser.set_value(session, query, :selected)
      :ok
    else
      {:error, :no_input_found}
    end
  end
end
