defmodule Sludge.Chat do
  def subscribe() do
    Phoenix.PubSub.subscribe(Sludge.PubSub, "chatroom")
  end

  def send_message(%{"body" => body, "nickname" => nickname}) do
    msg = %{nickname: nickname, body: body, id: System.unique_integer()}
    Phoenix.PubSub.broadcast(Sludge.PubSub, "chatroom", {:new_msg, msg})
  end
end
