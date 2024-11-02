defmodule TestTask.Transactions do
  @moduledoc """
  The Transaction context.
  """

  import Ecto.Query, warn: false
  alias TestTask.Repo

  alias TestTask.Accounts.User
  alias TestTask.Transactions.Transaction

  def get_transaction_by_uuid(transaction_uuid) do
    Transaction
    |> Repo.get_by(transaction_uuid: transaction_uuid)
  end

  def get_user(username) do
    User
    |> Repo.get_by(username: username)
  end

  def get_balance(username) do
    get_user(username)
    |> check_if_exist(username)
  end

  def update_balance(user, attrs \\ %{}) do
    user
    |> change_balance(attrs)
    |> Repo.update()
  end

  defp check_if_exist(nil, username) do
    {:ok, user} = create_balance(username)
    user
  end

  defp check_if_exist(user, _), do: user

  def create_balance(username) do
    attrs = %{username: username, balance: 100000000, currency: "EUR"}

    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def create_transaction(attrs \\ %{}) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  def close_bet_transaction(reference_uuid) do
    get_transaction_by_uuid(reference_uuid)
    |> change_transaction(%{"is_closed" => true})
    |> Repo.update()
  end

  def change_transaction(%Transaction{} = transaction, attrs \\ %{}) do
    Transaction.changeset(transaction, attrs)
  end

  def change_balance(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def bet(
        %{
          "user" => username,
          "amount" => amount,
          "currency" => currency,
          "transaction_uuid" => trans_uuid
        } = attrs \\ %{}
      ) do
    with user when not is_nil(user) <- get_user(username),
         :ok <- validate_bet(user, amount, currency, trans_uuid) do
      Repo.transaction(fn ->
        create_transaction(Map.merge(attrs, %{"is_closed" => false}))
        update_balance(user, %{balance: user.balance - amount})
      end)
    else
      nil -> {:error, "ERROR_USER_NOT_FOUND"}
      error -> error
    end
  end

  def win(
        %{
          "user" => username,
          "amount" => amount,
          "currency" => currency,
          "transaction_uuid" => trans_uuid,
          "reference_transaction_uuid" => reference_uuid
        } = attrs \\ %{}
      ) do
    with user when not is_nil(user) <- get_user(username),
         :ok <- validate_win(user, username, currency, trans_uuid, reference_uuid) do
      Repo.transaction(fn ->
        create_transaction(Map.merge(attrs, %{"is_closed" => true}))
        close_bet_transaction(reference_uuid)
        update_balance(user, %{balance: user.balance + amount})
      end)
    else
      nil -> {:error, "ERROR_USER_NOT_FOUND"}
      error -> error
    end
  end

  defp validate_bet(user, amount, currency, trans_uuid) do
    cond do
      user.currency != currency ->
        {:error, "ERROR_WRONG_CURRENCY"}

      user.balance < amount ->
        {:error, "ERROR_NOT_ENOUGH_MONEY"}

      not is_nil(get_transaction_by_uuid(trans_uuid)) ->
        {:error, "ERROR_DUPLICATE_TRANSACTION"}

      true ->
        :ok
    end
  end

  defp validate_win(user, username, currency, trans_uuid, reference_uuid) do
    cond do
      user.username != username ->
        {:error, "ERROR_WRONG_USER"}

      user.currency != currency ->
        {:error, "ERROR_WRONG_CURRENCY"}

      not is_nil(get_transaction_by_uuid(trans_uuid)) ->
        {:error, "ERROR_DUPLICATE_TRANSACTION"}

      is_nil(get_transaction_by_uuid(reference_uuid)) ->
        {:error, "ERROR_TRANSACTION_DOES_NOT_EXIST"}

      get_transaction_by_uuid(reference_uuid).is_closed ->
        {:error, "ERROR_TRANSACTION_IS_CLOSED"}

      true ->
        :ok
    end
  end
end
