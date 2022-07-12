defmodule IslandsInterfaceWeb.GameChannelTest do
  use IslandsInterfaceWeb.ChannelCase

  setup do
    {:ok, _, socket} =
      IslandsInterfaceWeb.UserSocket
      |> socket("user_id", %{some: :assign})
      |> subscribe_and_join(IslandsInterfaceWeb.GameChannel, "game:lobby")

    %{socket: socket}
  end

  test "reply_hello replies with status ok", %{socket: socket} do
    ref = push(socket, "reply_hello", %{"hello" => "there"})
    assert_reply(ref, :ok, %{"hello" => "there"})
  end

  test "push_hello broadcasts to game:lobby", %{socket: socket} do
    push(socket, "push_hello", %{"hello" => "all"})
    assert_push("pushed_hello", %{"hello" => "all"})
  end

  test "broadcast_hello pushes to the client", %{socket: socket} do
    push(socket, "broadcast_hello", %{"some" => "data"})
    assert_broadcast("broadcasted_hello", %{"some" => "data"})
  end
end
