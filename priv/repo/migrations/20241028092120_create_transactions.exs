defmodule TestTask.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :user, :string, null: false
      add :transaction_uuid, :string, null: false
      add :amount, :integer, null: false
      add :currency, :string, null: false
      add :is_closed, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:transactions, [:transaction_uuid])
  end
end
