defmodule TestTask.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TestTaskWeb.Telemetry,
      TestTask.Repo,
      {DNSCluster, query: Application.get_env(:test_task, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TestTask.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: TestTask.Finch},
      # Start a worker by calling: TestTask.Worker.start_link(arg)
      # {TestTask.Worker, arg},
      # Start to serve requests, typically the last entry
      TestTaskWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TestTask.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TestTaskWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
