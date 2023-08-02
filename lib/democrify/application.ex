defmodule Democrify.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      DemocrifyWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Democrify.PubSub},
      # Start Finch
      {Finch, name: Democrify.Finch},
      # Start the Session Worker Supervisor
      Democrify.Session.Supervisor,
      # Start the Session Worker Registry
      Democrify.Session.Registry,
      # Start the Endpoint (http/https)
      DemocrifyWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Democrify.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DemocrifyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
