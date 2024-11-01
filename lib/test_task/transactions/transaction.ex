defmodule TestTask.Transactions.Transaction do
  @moduledoc """
  Transaction schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :user, :string
    field :transaction_uuid, :string
    field :amount, :integer
    field :currency, :string
    field :is_closed, :boolean

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:user, :transaction_uuid, :amount, :currency, :is_closed])
    |> validate_required([:transaction_uuid])
    |> unique_constraint([:transaction_uuid])
    |> validate_number(:amount, greater_than_or_equal_to: 0)
  end
end
