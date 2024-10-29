defmodule TestTaskWeb.WalletController do
  use TestTaskWeb, :controller

  alias TestTask.Transactions
  action_fallback TestTaskWeb.FallbackController

  def balance(conn, %{"user" => username}) do
    case Transactions.get_balance(username) do
      nil ->
        json(conn, %{
          status: "ERROR_UNKNOWN"
        })

      user ->
        render_balance(conn, user)
    end
  end

  def bet(conn, %{"user" => username} = attrs) do
    case Transactions.bet(attrs) do
      {:ok, _} ->
        render_balance(conn, Transactions.get_balance(username))

      {:error, reason} ->
        json(conn, %{status: reason})
    end
  end

  def win(conn, %{"user" => username} = attrs) do
    case Transactions.win(attrs) do
      {:ok, _} ->
        render_balance(conn, Transactions.get_balance(username))

      {:error, reason} ->
        json(conn, %{status: reason})
    end
  end

  defp render_balance(conn, user) do
    json(conn, %{
      user: user.username,
      balance: user.balance,
      currency: user.currency,
      status: "OK"
    })
  end
end
