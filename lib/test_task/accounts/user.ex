defmodule TestTask.Accounts.User do
  @moduledoc """
  User balance schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :balance, :integer
    field :currency, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :balance, :currency])
    |> validate_required([:username])
    |> validate_length(:username, [min: 3])
    |> unique_constraint([:username])
  end
end
