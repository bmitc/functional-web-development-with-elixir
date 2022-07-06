defmodule IslandsInterface.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      IslandsInterfaceWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: IslandsInterface.PubSub},
      # Start the Endpoint (http/https)
      IslandsInterfaceWeb.Endpoint
      # Start a worker by calling: IslandsInterface.Worker.start_link(arg)
      # {IslandsInterface.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: IslandsInterface.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    IslandsInterfaceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
