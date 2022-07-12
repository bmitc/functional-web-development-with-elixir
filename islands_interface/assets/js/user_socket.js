// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// Bring in Phoenix channels client library:
import { Socket } from "phoenix"

// And connect to the path in "lib/islands_interface_web/endpoint.ex". We pass the
// token for authentication. Read below how it should be used.
let socket = new Socket("/socket", { params: { token: window.userToken } })

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/islands_interface_web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/islands_interface_web/templates/layout/app.html.heex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/3" function
// in "lib/islands_interface_web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket, _connect_info) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1_209_600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, connect to the socket:
socket.connect()

// Now that you are connected, you can join channels with a topic.
// Let's assume you have a channel with a topic named `room` and the
// subtopic is its id - in this case 42:
// let channel = socket.channel("room:42", {})
// channel.join()
//   .receive("ok", resp => { console.log("Joined successfully", resp) })
//   .receive("error", resp => { console.log("Unable to join", resp) })

window.new_channel = (subtopic, screen_name) => {
  return socket.channel("game:" + subtopic, { screen_name: screen_name });
}

window.join = (channel) => {
  channel.join()
    .receive("ok", response => {
      console.log("Joined successfully", response)
    })
    .receive("error", response => {
      console.log("Unable to join", response)
    })
}

window.leave = (channel) => {
  channel.leave()
    .receive("ok", response => {
      console.log("Left successfully", response)
    })
    .receive("error", response => {
      console.log("Unable to leave", response)
    })
}

window.say_hello = (channel, greeting) => {
  channel.push("reply_hello", { "message": greeting })
    .receive("ok", response => {
      console.log("Hello", response.message)
    })
    .receive("error", response => {
      console.log("Unable to say hello to the channel.", response.message)
    })
}

window.push_hello = (channel, greeting) => {
  channel.push("push_hello", { "message": greeting })
    .receive("ok", response => {
      console.log("Hello", response.message)
    })
    .receive("error", response => {
      console.log("Unable to say hello to the channel.", response.message)
    })
}

window.broadcast_hello = (channel, greeting) => {
  channel.push("broadcast_hello", { "message": greeting })
    .receive("ok", response => {
      console.log("Hello", response.message)
    })
    .receive("error", response => {
      console.log("Unable to say hello to the channel.", response.message)
    })
}

window.set_push_event_listener = (channel) => {
  channel.on("pushed_hello", response => {
    console.log("Returned Pushed Greeting:", response.message)
  })
}

window.set_broadcast_event_listener = (channel) => {
  channel.on("broadcasted_hello", response => {
    console.log("Returned Broadcasted Greeting:", response.message)
  })
}

// var game_channel = new_channel("moon", "moon")
// join(game_channel)

export default socket
