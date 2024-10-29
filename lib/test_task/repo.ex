defmodule TestTask.Repo do
  use Ecto.Repo,
    otp_app: :test_task,
    adapter: Ecto.Adapters.Postgres
end
