defmodule EmailOrganizer.EmailUnsubscribeTest do
  @moduledoc """
  Test the Email.unsubscribe_from_emails/2 function.
  """

  use EmailOrganizer.DataCase, async: false
  use Mimic

  alias EmailOrganizer.Email
  alias EmailOrganizer.LLM

  setup :set_mimic_global

  describe "unsubscribe_from_emails/2" do
    test "successfully unsubscribes from emails" do
      email = insert(:email)

      expect(LLM, :unsubscribe_from_email, fn ^email ->
        {:ok, %{"success" => true}}
      end)

      assert :ok = Email.unsubscribe_from_emails([email.id])
    end

    test "handles case when no unsubscribe link is found" do
      email = insert(:email)

      expect(LLM, :unsubscribe_from_email, fn ^email ->
        {:ok, %{"success" => false, "link_found" => false}}
      end)

      assert :ok = Email.unsubscribe_from_emails([email.id])
    end

    test "handles failure to unsubscribe" do
      email = insert(:email)

      expect(LLM, :unsubscribe_from_email, fn ^email ->
        {:ok, %{"success" => false, "message" => "Failed to unsubscribe"}}
      end)

      assert :ok = Email.unsubscribe_from_emails([email.id])
    end

    test "handles error from LLM" do
      email = insert(:email)

      expect(LLM, :unsubscribe_from_email, fn ^email ->
        {:error, :some_error}
      end)

      assert :ok = Email.unsubscribe_from_emails([email.id])
    end

    test "notifies the caller when unsubscribe is successful" do
      email = insert(:email)

      expect(LLM, :unsubscribe_from_email, fn ^email ->
        {:ok, %{"success" => true}}
      end)

      Email.unsubscribe_from_emails([email.id], self())

      assert_receive {:unsubscribed, ^email}
    end

    test "notifies the caller when no unsubscribe link is found" do
      email = insert(:email)

      expect(LLM, :unsubscribe_from_email, fn ^email ->
        {:ok, %{"success" => false, "link_found" => false}}
      end)

      Email.unsubscribe_from_emails([email.id], self())

      assert_receive {:no_unsubscribe_link_found, ^email}
    end

    test "notifies the caller when unsubscribe fails" do
      email = insert(:email)

      expect(LLM, :unsubscribe_from_email, fn ^email ->
        {:ok, %{"success" => false, "message" => "Failed to unsubscribe"}}
      end)

      Email.unsubscribe_from_emails([email.id], self())

      assert_receive {:failed_to_unsubscribe, ^email}
    end

    test "notifies the caller when there's an error" do
      email = insert(:email)

      expect(LLM, :unsubscribe_from_email, fn ^email ->
        {:error, :decoding_error}
      end)

      Email.unsubscribe_from_emails([email.id], self())

      assert_receive {:failed_to_unsubscribe, ^email}, 1_000
    end

    test "processes multiple emails" do
      email1 = insert(:email)
      email2 = insert(:email)

      expect(LLM, :unsubscribe_from_email, 2, fn email ->
        case email.id do
          id when id == email1.id -> {:ok, %{"success" => true}}
          id when id == email2.id -> {:ok, %{"success" => false, "link_found" => false}}
        end
      end)

      Email.unsubscribe_from_emails([email1.id, email2.id], self())

      assert_receive {:unsubscribed, ^email1}
      assert_receive {:no_unsubscribe_link_found, ^email2}
    end

    test "handles empty email list" do
      assert :ok = Email.unsubscribe_from_emails([])
    end
  end
end
