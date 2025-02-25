defmodule SludgeWeb.ChatLive do
  require Logger

  use Phoenix.LiveView

  attr(:socket, Phoenix.LiveView.Socket, required: true, doc: "Parent live view socket")
  attr(:id, :string, required: true, doc: "Component id")
  # attr(:pubsub, Phoenix.PubSub, required: true, doc: "PubSub for chat messages")

  def live_render(assigns) do
    ~H"""
    {live_render(@socket, __MODULE__, id: @id)}
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="#{@id}:chat"
      class="flex flex-col overflow-hidden justify-end h-full text-wrap break-words w-96 p-4 border-brand/50 border-2 rounded-xl m-20 h-[600px]"
    >
      <div
        id="#{@id}:chat-messages"
        phx-update="stream"
        class="overflow-y-scroll justify-end height-full"
      >
        <div
          :for={{id, msg} <- @streams.messages}
          id="#{@id}:msg:#{id}"
          class="flex flex-col pt-4 pb-4"
        >
          <div class="w-full flex">
            <div class="font-semibold">
              {msg.nickname}
            </div>
          </div>
          <div class="message-body">
            {msg.body}
          </div>
        </div>
      </div>

      <div class="flex flex-col justify-end py-2">
        <div class="w-full py-2">
          <form id="#{@id}:message-form" phx-change="validate-form" phx-submit="submit-form">
            <input
              type="text"
              id="#{@id}:msg-body"
              class="resize-none rounded-lg w-full border-brand/50 focus:border-brand/100 focus:outline-none focus:ring-0"
              maxlength="500"
              name="body"
              value={@msg_body}
              placeholder="type your message here..."
              disabled={is_nil(@nickname)}
            />
            <div class="flex flex-row py-2 gap-2 justify-between">
              <input
                id="#{@id}:chat-nickname"
                class="text-brand/80 font-semibold min-w-0 bg-brand/10 rounded-lg border pl-2 border-brand/50 focus:border-brand/100 focus:outline-none"
                placeholder="Your Nickname"
                maxlength="25"
                name="nickname"
                value={@nickname}
                disabled={not is_nil(@nickname)}
              />
              <button
                id="#{@id}:chat-button"
                type="submit"
                class="py-2 px-4 rounded-lg bg-brand/10 text-brand/80 font-semibold"
              >
                <%= if is_nil(@nickname) do %>
                  Join
                <% else %>
                  Send
                <% end %>
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      subscribe()
    end

    socket =
      socket
      |> stream(:messages, [])
      |> assign(msg_body: nil)
      |> assign(nickname: nil)

    {:ok, socket}
  end

  @impl true
  def handle_info({:new_msg, msg}, socket) do
    {:noreply, stream(socket, :messages, [msg])}
  end

  @impl true
  def handle_event("validate-form", %{"nickname" => _nickname}, socket) do
    {:noreply, socket}
  end

  def handle_event("validate-form", %{"body" => body}, socket) do
    {:noreply, assign(socket, msg_body: body)}
  end

  def handle_event("submit-form", %{"body" => body}, socket) do
    if body != "" do
      send_message(%{"body" => body, "nickname" => socket.assigns.nickname})
    end

    {:noreply, assign(socket, msg_body: nil)}
  end

  def handle_event("submit-form", %{"nickname" => nickname}, socket) do
    nickname =
      case nickname do
        "" -> nil
        n -> n
      end

    {:noreply, assign(socket, nickname: nickname)}
  end

  defp subscribe() do
    Phoenix.PubSub.subscribe(Sludge.PubSub, "chatroom")
  end

  defp send_message(%{"body" => body, "nickname" => nickname}) do
    msg = %{nickname: nickname, body: body, id: System.unique_integer()}
    Phoenix.PubSub.broadcast(Sludge.PubSub, "chatroom", {:new_msg, msg})
  end
end
