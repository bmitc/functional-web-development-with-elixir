defmodule IslandsEngine.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: IslandsEngine.Worker.start_link(arg)
      # {IslandsEngine.Worker, arg}
      {Registry, keys: :unique, name: Registry.Game},
      IslandsEngine.GameSupervisor
    ]

    # Create an ETS table to store game states in, keyed
    # by player 1's name
    :ets.new(:game_state, [:public, :named_table])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: IslandsEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
