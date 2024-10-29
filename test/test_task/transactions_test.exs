defmodule TestTask.TransactionsTest do
  use TestTask.DataCase, async: true

  alias TestTask.Transactions

  setup do
    # Create a user for testing
    {:ok, user} = Transactions.create_balance("test_user")
    %{user: user}
  end

  describe "get_user/1" do
    test "returns user when exists", %{user: user} do
      assert Transactions.get_user("test_user").username == user.username
    end

    test "returns nil when user does not exist" do
      assert Transactions.get_user("non_existent_user") == nil
    end
  end

  describe "get_balance/1" do
    test "returns balance for existing user" do
      assert Transactions.get_balance("test_user").balance == 1000
    end

    test "creates a new user with default balance when user does not exist" do
      assert new_user = Transactions.get_balance("new_user")
      assert new_user.username == "new_user"
      assert new_user.balance == 1000
    end
  end

  describe "bet/1" do
    test "successful bet decreases balance", %{user: user} do
      attrs = %{
        "user" => user.username,
        "amount" => 100,
        "currency" => "EUR",
        "transaction_uuid" => "unique_uuid_1"
      }

      assert {:ok, _} = Transactions.bet(attrs)
      assert Transactions.get_balance(user.username).balance == 900
    end

    test "returns error when insufficient balance", %{user: user} do
      attrs = %{
        "user" => user.username,
        "amount" => 2000,
        "currency" => "EUR",
        "transaction_uuid" => "unique_uuid_2"
      }

      assert Transactions.bet(attrs) == {:error, "ERROR_NOT_ENOUGH_MONEY"}
    end

    test "returns error when duplicate transaction", %{user: user} do
      attrs = %{
        "user" => user.username,
        "amount" => 100,
        "currency" => "EUR",
        "transaction_uuid" => "duplicate_uuid"
      }

      assert {:ok, _} = Transactions.bet(attrs)
      assert Transactions.bet(attrs) == {:error, "ERROR_DUPLICATE_TRANSACTION"}
    end

    test "returns error when user does not exist" do
      attrs = %{
        "user" => "non_existent_user",
        "amount" => 100,
        "currency" => "EUR",
        "transaction_uuid" => "unique_uuid_3"
      }

      assert Transactions.bet(attrs) == {:error, "ERROR_USER_NOT_FOUND"}
    end
  end

  describe "win/1" do
    test "successful win increases balance and closes bet", %{user: user} do
      # First, we need to place a bet
      bet_attrs = %{
        "user" => user.username,
        "amount" => 100,
        "currency" => "EUR",
        "transaction_uuid" => "bet_uuid_1"
      }

      assert {:ok, _} = Transactions.bet(bet_attrs)

      win_attrs = %{
        "user" => user.username,
        "amount" => 150,
        "currency" => "EUR",
        "transaction_uuid" => "win_uuid_1",
        "reference_transaction_uuid" => "bet_uuid_1"
      }

      assert {:ok, _} = Transactions.win(win_attrs)
      assert Transactions.get_balance(user.username).balance == 1050
    end

    test "returns error when winning on a closed bet", %{user: user} do
      # Create and close a transaction
      bet_attrs = %{
        "user" => user.username,
        "amount" => 100,
        "currency" => "EUR",
        "transaction_uuid" => "bet_uuid_2"
      }

      assert {:ok, _} = Transactions.bet(bet_attrs)
      assert {:ok, _} = Transactions.close_bet_transaction("bet_uuid_2")

      win_attrs = %{
        "user" => user.username,
        "amount" => 150,
        "currency" => "EUR",
        "transaction_uuid" => "win_uuid_2",
        "reference_transaction_uuid" => "bet_uuid_2"
      }

      assert Transactions.win(win_attrs) == {:error, "ERROR_TRANSACTION_IS_CLOSED"}
    end

    test "returns error when transaction does not exist", %{user: user} do
      win_attrs = %{
        "user" => user.username,
        "amount" => 150,
        "currency" => "EUR",
        "transaction_uuid" => "win_uuid_3",
        "reference_transaction_uuid" => "non_existent_uuid"
      }

      assert Transactions.win(win_attrs) == {:error, "ERROR_TRANSACTION_DOES_NOT_EXIST"}
    end

    test "returns error when user does not exist" do
      win_attrs = %{
        "user" => "non_existent_user",
        "amount" => 150,
        "currency" => "EUR",
        "transaction_uuid" => "win_uuid_4",
        "reference_transaction_uuid" => "reference_uuid"
      }

      assert Transactions.win(win_attrs) == {:error, "ERROR_USER_NOT_FOUND"}
    end
  end
end
