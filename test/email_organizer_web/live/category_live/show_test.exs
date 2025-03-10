defmodule EmailOrganizerWeb.CategoryLive.ShowTest do
  @moduledoc """
  Test suite for the Show category page.
  """

  use EmailOrganizerWeb.LiveViewCase, async: true
  use Mimic

  alias EmailOrganizer.Email

  describe "Show category page" do
    setup %{user: user} do
      category =
        insert(:category, user: user, name: "Test Category", description: "Test Description")

      %{category: category}
    end

    test "displays category details", %{conn: conn, category: category} do
      {:ok, _view, html} = live(conn, ~p"/categories/#{category.id}")

      assert html =~ category.name
      assert html =~ category.description
      assert html =~ "Emails in this category"
    end

    test "has link to edit category", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}")

      {:ok, _view, html} =
        view
        |> element("a", "Edit Category")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Edit Category"
    end

    test "can navigate back to index page", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}")

      {:ok, _view, html} =
        view
        |> element("a", "Back to index")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Your Categories"
    end

    test "shows message when no emails in category", %{conn: conn, category: category} do
      {:ok, _view, html} = live(conn, ~p"/categories/#{category.id}")

      assert html =~ "No emails found in this category."
    end
  end

  describe "Email table display" do
    setup %{user: user} do
      category = insert(:category, user: user)

      emails =
        for i <- 1..15 do
          insert(:email,
            user: user,
            category: category,
            subject: "Email #{i}",
            from: "sender#{i}@example.com",
            date: DateTime.add(~U[2023-01-01 00:00:00Z], i, :day),
            summary: "Summary for email #{i}"
          )
        end

      %{category: category, emails: emails}
    end

    test "displays emails in a table with proper styling", %{
      conn: conn,
      category: category,
      emails: emails
    } do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}")

      assert has_element?(view, "table th", "Summary")
      assert has_element?(view, "table th", "From")
      assert has_element?(view, "table th", "Date")
      assert has_element?(view, "table th", "Actions")

      assert emails
             |> Enum.reverse()
             |> Enum.take(10)
             |> Enum.all?(fn email ->
               assert has_element?(view, "table td", email.summary)
               assert has_element?(view, "table td", email.from)

               assert has_element?(
                        view,
                        "table td",
                        Calendar.strftime(email.date, "%a, %b %d %Y, %I:%M %p")
                      )
             end)
    end

    test "displays pagination controls", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}")

      assert has_element?(view, "div#pagination div", "Showing")
      assert has_element?(view, "div#pagination div span", "1")
      assert has_element?(view, "div#pagination div", "to")
      assert has_element?(view, "div#pagination div span", "10")
      assert has_element?(view, "div#pagination div", "of")
      assert has_element?(view, "div#pagination div span", "15")
      assert has_element?(view, "div#pagination div", "emails")

      assert has_element?(view, "div#pagination button[disabled]", "Previous")
      assert has_element?(view, "div#pagination a", "Next")
    end

    test "can navigate to next page", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}")

      view
      |> element("a", "Next")
      |> render_click()

      assert_patch(
        view,
        ~p"/categories/#{category.id}?page=2&page_size=10&sort_by=date&sort_order=desc"
      )

      assert has_element?(view, "div#pagination div", "Showing")
      assert has_element?(view, "div#pagination div span", "11")
      assert has_element?(view, "div#pagination div", "to")
      assert has_element?(view, "div#pagination div span", "15")
      assert has_element?(view, "div#pagination div", "of")
      assert has_element?(view, "div#pagination div span", "15")
      assert has_element?(view, "div#pagination div", "emails")

      assert has_element?(view, "div#pagination a", "Previous")
      assert has_element?(view, "div#pagination button[disabled]", "Next")
    end

    test "can navigate to previous page", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}?page=2")

      view
      |> element("a", "Previous")
      |> render_click()

      assert_patch(
        view,
        ~p"/categories/#{category.id}?page=1&page_size=10&sort_by=date&sort_order=desc"
      )

      assert has_element?(view, "div#pagination div", "Showing")
      assert has_element?(view, "div#pagination div span", "1")
      assert has_element?(view, "div#pagination div", "to")
      assert has_element?(view, "div#pagination div span", "10")
      assert has_element?(view, "div#pagination div", "of")
      assert has_element?(view, "div#pagination div span", "15")
      assert has_element?(view, "div#pagination div", "emails")

      assert has_element?(view, "div#pagination button[disabled]", "Previous")
      assert has_element?(view, "div#pagination a", "Next")
    end

    test "can sort emails by different columns", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}")

      view
      |> element("button", "Summary")
      |> render_click()

      assert_patch(
        view,
        ~p"/categories/#{category.id}?page=1&page_size=10&sort_by=summary&sort_order=asc"
      )
    end

    test "can select individual emails", %{conn: conn, category: category, emails: emails} do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}")

      assert has_element?(view, "button[phx-click='delete_selected'][disabled]")

      email_id = List.last(emails).id

      view
      |> element("td[phx-click='select_email'][phx-value-id='#{email_id}']")
      |> render_click()

      assert has_element?(view, "button", "Delete")
      assert has_element?(view, "button", "Unsubscribe")
      refute has_element?(view, "button[phx-click='delete_selected'][disabled]")
      assert has_element?(view, "button[phx-click='delete_selected']")
    end

    test "can select all emails", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}")

      view
      |> element("input#select-all")
      |> render_click()

      assert has_element?(view, "button", "Delete")
      assert has_element?(view, "button", "Unsubscribe")
      assert has_element?(view, "input#select-all[checked]")
    end

    test "can delete selected emails", %{conn: conn, category: category, emails: emails} do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}")

      email_id = List.last(emails).id

      view
      |> element("td[phx-click='select_email'][phx-value-id='#{email_id}']")
      |> render_click()

      view
      |> element("button", "Delete")
      |> render_click()

      assert_patch(
        view,
        ~p"/categories/#{category.id}?page=1&page_size=10&sort_by=date&sort_order=desc"
      )

      assert has_element?(view, "div", "Emails deleted successfully")
    end

    test "can delete individual emails", %{conn: conn, category: category, emails: emails} do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}")

      email_id = List.last(emails).id

      view
      |> element("button[phx-click='delete_email'][phx-value-id='#{email_id}']")
      |> render_click()

      assert has_element?(view, "div", "Email deleted successfully")

      assert_patch(
        view,
        ~p"/categories/#{category.id}?page=1&page_size=10&sort_by=date&sort_order=desc"
      )
    end

    test "can unsubscribe from selected emails", %{conn: conn, category: category, emails: emails} do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}")

      email_id = List.last(emails).id
      view_pid = view.pid

      expect(Email, :unsubscribe_from_emails, fn [^email_id], ^view_pid -> :ok end)

      view
      |> element("td[phx-click='select_email'][phx-value-id='#{email_id}']")
      |> render_click()

      view
      |> element("button", "Unsubscribe")
      |> render_click()

      assert has_element?(view, "div", "Emails will be unsubscribed in the background")
    end

    test "can unsubscribe from individual emails", %{
      conn: conn,
      category: category,
      emails: emails
    } do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}")

      email_id = List.last(emails).id
      view_pid = view.pid
      expect(Email, :unsubscribe_from_emails, fn [^email_id], ^view_pid -> :ok end)

      view
      |> element("button[phx-click='unsubscribe_email'][phx-value-id='#{email_id}']")
      |> render_click()

      assert has_element?(view, "div", "Email will be unsubscribed in the background")
    end

    test "handles successful unsubscribe notification", %{
      conn: conn,
      category: category,
      emails: emails
    } do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}")

      email = List.last(emails)
      send(view.pid, {:unsubscribed, email})

      assert has_element?(
               view,
               "div",
               "Email with subject #{email.subject} unsubscribed successfully"
             )
    end

    test "handles no unsubscribe link found notification", %{
      conn: conn,
      category: category,
      emails: emails
    } do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}")

      email = List.last(emails)
      send(view.pid, {:no_unsubscribe_link_found, email})

      assert has_element?(
               view,
               "div",
               "No unsubscribe link found for email with subject #{email.subject}"
             )
    end

    test "handles failed unsubscribe notification", %{
      conn: conn,
      category: category,
      emails: emails
    } do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}")

      email = List.last(emails)
      send(view.pid, {:failed_to_unsubscribe, email})

      assert has_element?(
               view,
               "div",
               "Failed to unsubscribe from email with subject #{email.subject}"
             )
    end

    test "can navigate to email details by clicking on a row", %{
      conn: conn,
      category: category,
      emails: emails
    } do
      email = List.last(emails)
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}")

      {:ok, _view, html} =
        view
        |> element("tr[phx-click]", email.summary)
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ email.subject
      assert html =~ email.from
      assert html =~ "Email Content"
    end
  end
end
