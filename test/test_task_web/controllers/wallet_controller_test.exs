defmodule TestTaskWeb.WalletControllerTest do
  use TestTaskWeb.ConnCase, async: true

  alias TestTask.Transactions

  setup do
    # Create a user for testing
    {:ok, user} = Transactions.create_balance("test_user")
    %{user: user}
  end

  defp basic_auth(conn, username, password) do
    credentials = "#{username}:#{password}" |> Base.encode64()
    put_req_header(conn, "authorization", "Basic #{credentials}")
  end

  test "unathorized user get 401 response", %{conn: conn} do
    conn = post(conn, ~p"/api/user/balance", %{"user" => "unathorized"})
    assert response(conn, 401)
  end

  describe "post /user/balance" do
    test "returns balance for existing user", %{conn: conn, user: user} do
      conn = conn |> basic_auth("admin", "admin")
      conn = post(conn, ~p"/api/user/balance", %{"user" => user.username})

      assert json_response(conn, 200) == %{
               "user" => user.username,
               "balance" => user.balance,
               "currency" => user.currency,
               "status" => "OK"
             }
    end

    test "creates balancer for non-existing user", %{conn: conn} do
      conn = conn |> basic_auth("admin", "admin")
      conn = post(conn, ~p"/api/user/balance", %{"user" => "created_user"})
      user = Transactions.get_balance("created_user")

      assert json_response(conn, 200) == %{
               "user" => user.username,
               "balance" => user.balance,
               "currency" => user.currency,
               "status" => "OK"
             }
    end
  end

  describe "POST /transaction/bet" do
    test "successful bet decreases balance", %{conn: conn, user: user} do
      attrs = %{
        "user" => user.username,
        "amount" => 100,
        "currency" => "EUR",
        "transaction_uuid" => "bet_uuid_1"
      }
      conn = conn |> basic_auth("admin", "admin")
      conn = post(conn, ~p"/api/transaction/bet", attrs)
      assert json_response(conn, 200)["status"] == "OK"
      assert Transactions.get_balance(user.username).balance == 900
    end

    test "returns error when insufficient balance", %{conn: conn, user: user} do
      attrs = %{
        "user" => user.username,
        "amount" => 2000,
        "currency" => "EUR",
        "transaction_uuid" => "bet_uuid_2"
      }
      conn = conn |> basic_auth("admin", "admin")
      conn = post(conn, ~p"/api/transaction/bet", attrs)
      assert json_response(conn, 200) == %{"status" => "ERROR_NOT_ENOUGH_MONEY"}
    end

    test "returns error for duplicate transaction", %{conn: conn, user: user} do
      attrs = %{
        "user" => user.username,
        "amount" => 100,
        "currency" => "EUR",
        "transaction_uuid" => "duplicate_uuid"
      }
      conn = conn |> basic_auth("admin", "admin")
      # First bet
      post(conn, ~p"/api/transaction/bet", attrs)

      # Attempt duplicate bet
      conn = post(conn, ~p"/api/transaction/bet", attrs)
      assert json_response(conn, 200) == %{"status" => "ERROR_DUPLICATE_TRANSACTION"}
    end
  end

  describe "POST /transaction/win" do
    test "successful win increases balance", %{conn: conn, user: user} do
      # First, place a bet
      bet_attrs = %{
        "user" => user.username,
        "amount" => 100,
        "currency" => "EUR",
        "transaction_uuid" => "bet_uuid_3"
      }

      assert {:ok, _} = Transactions.bet(bet_attrs)

      win_attrs = %{
        "user" => user.username,
        "amount" => 150,
        "currency" => "EUR",
        "transaction_uuid" => "win_uuid_1",
        "reference_transaction_uuid" => "bet_uuid_3"
      }
      conn = conn |> basic_auth("admin", "admin")
      conn = post(conn, ~p"/api/transaction/win", win_attrs)
      assert json_response(conn, 200)["status"] == "OK"
      assert Transactions.get_balance(user.username).balance == 1050
    end

    test "returns error for closed bet", %{conn: conn, user: user} do
      # First, place a bet and close it
      bet_attrs = %{
        "user" => user.username,
        "amount" => 100,
        "currency" => "EUR",
        "transaction_uuid" => "bet_uuid_4"
      }

      assert {:ok, _} = Transactions.bet(bet_attrs)
      assert {:ok, _} = Transactions.close_bet_transaction("bet_uuid_4")

      win_attrs = %{
        "user" => user.username,
        "amount" => 150,
        "currency" => "EUR",
        "transaction_uuid" => "win_uuid_2",
        "reference_transaction_uuid" => "bet_uuid_4"
      }
      conn = conn |> basic_auth("admin", "admin")
      conn = post(conn, ~p"/api/transaction/win", win_attrs)
      assert json_response(conn, 200) == %{"status" => "ERROR_TRANSACTION_IS_CLOSED"}
    end

    test "returns error for non-existing transaction", %{conn: conn, user: user} do
      win_attrs = %{
        "user" => user.username,
        "amount" => 150,
        "currency" => "EUR",
        "transaction_uuid" => "win_uuid_3",
        "reference_transaction_uuid" => "non_existent_uuid"
      }
      conn = conn |> basic_auth("admin", "admin")
      conn = post(conn, ~p"/api/transaction/win", win_attrs)
      assert json_response(conn, 200) == %{"status" => "ERROR_TRANSACTION_DOES_NOT_EXIST"}
    end

    test "returns error when user does not exist", %{conn: conn} do
      win_attrs = %{
        "user" => "non_existent_user",
        "amount" => 150,
        "currency" => "EUR",
        "transaction_uuid" => "win_uuid_4",
        "reference_transaction_uuid" => "reference_uuid"
      }
      conn = conn |> basic_auth("admin", "admin")
      conn = post(conn, ~p"/api/transaction/win", win_attrs)
      assert json_response(conn, 200) == %{"status" => "ERROR_USER_NOT_FOUND"}
    end
  end
end
