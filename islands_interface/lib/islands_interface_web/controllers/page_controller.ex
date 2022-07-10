defmodule IslandsInterfaceWeb.PageController do
  use IslandsInterfaceWeb, :controller

  alias IslandsEngine.GameSupervisor

  @doc """
  Phoenix generated function
  """
  @spec index(Plug.Conn.t(), any()) :: any()
  def index(conn, _params) do
    render(conn, "index.html")
  end

  @doc """
  Phoenix generated function
  """
  @spec test(Plug.Conn.t(), map()) :: any()
  def test(conn, %{"name" => player1_name}) do
    {:ok, _game_pid} = GameSupervisor.start_game(player1_name)

    conn
    |> put_flash(:info, "You entered the name: #{player1_name}")
    |> render("index.html")
  end
end
