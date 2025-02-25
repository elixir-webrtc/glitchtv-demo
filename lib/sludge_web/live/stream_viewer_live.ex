defmodule SludgeWeb.StreamViewerLive do
  require Logger

  use SludgeWeb, :live_view

  alias LiveExWebRTC.Player
  alias Sludge.Chat

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex">
      <div>
        <div :if={!@stream_metadata}>
          No-one is streaming... :c
        </div>
        <div :if={@stream_metadata}>
          <h1>{@stream_metadata.title}</h1>
          <p>{@stream_metadata.description}</p>
          <p>Started: {@stream_metadata.started}</p>
        </div>

        <Player.live_render socket={@socket} player={@player} />
      </div>
      <div
        id="chat"
        class="flex flex-col overflow-hidden justify-end h-full text-wrap break-words w-96 p-4 border-brand/50 border-2 rounded-xl m-20 h-[600px]"
      >
        <div id="chat-messages" phx-update="stream" class="overflow-y-scroll justify-end height-full">
          <div :for={{id, msg} <- @streams.messages} id={id} class="flex flex-col pt-4 pb-4">
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
            <form id="message-form" phx-change="validate-form" phx-submit="submit-form">
              <input
                type="text"
                id="msg-body"
                class="resize-none rounded-lg w-full border-brand/50 focus:border-brand/100 focus:outline-none focus:ring-0"
                maxlength="500"
                name="body"
                value={@msg_body}
                placeholder="type your message here..."
                disabled={is_nil(@nickname)}
              />
              <div class="flex flex-row py-2 gap-2 justify-between">
                <input
                  id="chat-nickname"
                  class="text-brand/80 font-semibold min-w-0 bg-brand/10 rounded-lg border pl-2 border-brand/50 focus:border-brand/100 focus:outline-none"
                  placeholder="Your Nickname"
                  maxlength="25"
                  name="nickname"
                  value={@nickname}
                  disabled={not is_nil(@nickname)}
                />
                <button
                  id="chat-button"
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
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Chat.subscribe()
    end

    socket =
      socket
      |> stream(:messages, [])
      |> assign(msg_body: nil)
      |> assign(nickname: nil)
      |> Player.attach(
        id: "player",
        publisher_id: "publisher",
        pubsub: Sludge.PubSub,
        ice_servers: [%{urls: "stun:stun.l.google.com:19302"}]
        # ice_ip_filter: Application.get_env(:live_broadcaster, :ice_ip_filter)
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _, socket) do
    {
      :noreply,
      socket
      # XXX make it update pubsub or event or sth dont care really
      |> assign(:stream_metadata, Sludge.StreamService.get_stream_metadata())
      # |> assign(:page_title, page_title(socket.assigns.live_action))
      # |> assign(:recording, Recordings.get_recording!(id))}
    }
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
      Chat.send_message(%{"body" => body, "nickname" => socket.assigns.nickname})
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

  # defp page_title(:show), do: "Show Recording"
end
