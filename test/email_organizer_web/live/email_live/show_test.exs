defmodule EmailOrganizerWeb.EmailLive.ShowTest do
  @moduledoc """
  Test suite for the Show email page.
  """

  use EmailOrganizerWeb.LiveViewCase, async: true
  use Mimic

  alias EmailOrganizer.Email

  describe "Show email page" do
    setup %{user: user} do
      category =
        insert(:category, user: user, name: "Test Category", description: "Test Description")

      email =
        insert(:email,
          user: user,
          category: category,
          subject: "Test Email Subject",
          from: "sender@example.com",
          recipients: ["recipient1@example.com", "recipient2@example.com"],
          text: "This is the email content.\nIt has multiple lines.\nFor testing purposes.",
          date: ~U[2023-01-01 12:00:00Z],
          summary: "Test Email Summary"
        )

      %{email: email, category: category}
    end

    test "displays email details", %{conn: conn, email: email} do
      {:ok, view, _html} = live(conn, ~p"/emails/#{email.id}")

      assert has_element?(view, "h1", email.subject)
      assert has_element?(view, "p", email.from)
      assert has_element?(view, "p", "recipient1@example.com, recipient2@example.com")
      assert has_element?(view, "pre", email.text)
      assert has_element?(view, "p", "Sun, Jan 01 2023, 12:00 PM")
    end

    test "has link to go back to category", %{conn: conn, email: email, category: category} do
      {:ok, view, _html} = live(conn, ~p"/emails/#{email.id}")

      {:ok, _view, html} =
        view
        |> element("a", "Back to category")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ category.name
      assert html =~ "Emails in this category"
    end

    test "can delete email", %{conn: conn, email: email, category: category} do
      {:ok, view, _html} = live(conn, ~p"/emails/#{email.id}")

      {:ok, _view, html} =
        view
        |> element("button", "Delete")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Email deleted successfully"
      assert html =~ category.name
    end

    test "can request to unsubscribe from email", %{conn: conn, email: email} do
      email_id = email.id

      {:ok, view, _html} = live(conn, ~p"/emails/#{email_id}")

      view_pid = view.pid

      expect(Email, :unsubscribe_from_emails, fn [^email_id], ^view_pid -> :ok end)

      view
      |> element("button", "Unsubscribe")
      |> render_click()

      assert has_element?(view, "div", "Email will be unsubscribed in the background")
    end

    test "handles successful unsubscribe notification", %{conn: conn, email: email} do
      {:ok, view, _html} = live(conn, ~p"/emails/#{email.id}")

      send(view.pid, {:unsubscribed, email})

      assert has_element?(
               view,
               "div",
               "Email with subject #{email.subject} unsubscribed successfully"
             )
    end

    test "handles no unsubscribe link found notification", %{conn: conn, email: email} do
      {:ok, view, _html} = live(conn, ~p"/emails/#{email.id}")

      send(view.pid, {:no_unsubscribe_link_found, email})

      assert has_element?(
               view,
               "div",
               "No unsubscribe link found for email with subject #{email.subject}"
             )
    end

    test "handles failed unsubscribe notification", %{conn: conn, email: email} do
      {:ok, view, _html} = live(conn, ~p"/emails/#{email.id}")

      send(view.pid, {:failed_to_unsubscribe, email})

      assert has_element?(
               view,
               "div",
               "Failed to unsubscribe from email with subject #{email.subject}"
             )
    end
  end
end
