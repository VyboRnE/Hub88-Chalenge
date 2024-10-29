defmodule TestTaskWeb.Router do
  use TestTaskWeb, :router
  import Plug.BasicAuth

  pipeline :api do
    plug :accepts, ["json"]
    plug :basic_auth, Application.compile_env(:test_task, :basic_auth)
  end

  scope "/api", TestTaskWeb do
    pipe_through :api

    post "/user/balance", WalletController, :balance
    post "/transaction/bet", WalletController, :bet
    post "/transaction/win", WalletController, :win
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:test_task, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: TestTaskWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
