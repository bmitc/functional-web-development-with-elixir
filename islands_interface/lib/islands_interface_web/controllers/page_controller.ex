defmodule IslandsInterfaceWeb.PageController do
  use IslandsInterfaceWeb, :controller

  alias IslandsEngine.GameSupervisor

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def test(conn, %{"name" => player1_name}) do
    {:ok, _game_pid} = GameSupervisor.start_game(player1_name)

    conn
    |> put_flash(:info, "You entered the name: #{player1_name}")
    |> render("index.html")
  end
end
