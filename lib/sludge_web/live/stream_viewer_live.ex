defmodule SludgeWeb.StreamViewerLive do
  use SludgeWeb, :live_view

  alias LiveExWebRTC.Player
  alias SludgeWeb.Chat

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
        class="flex flex-col overflow-hidden justify-end h-full text-wrap break-words w-96 p-4 border-brand/50 border-2 rounded-xl m-20"
      >
        <div id="chat-messages" class="overflow-y-scroll justify-end"></div>
        <div class="flex flex-col pt-4 pb-4">
          <div class="w-100% flex">
            <div class="font-semibold">
              nickname
            </div>
          </div>
          <div class="message-body">
            some very long message
          </div>
        </div>
        <div class="flex flex-col justify-end py-2">
          <div class="w-full py-2">
            <textarea
              id="chat-input"
              class="resize-none rounded-lg w-full border-brand/50 focus:border-brand/100 focus:outline-none focus:ring-0"
              maxlength="500"
              disabled
            ></textarea>
          </div>
          <div class="flex flex-row py-2 gap-2 justify-between">
            <input
              id="chat-nickname"
              class="text-brand/80 font-semibold min-w-0 bg-brand/10 rounded-lg border pl-2 border-brand/50 focus:border-brand/100 focus:outline-none"
              placeholder="Your Nickname"
              maxlength="25"
            />
            <button
              id="chat-button"
              class="py-2 px-4 rounded-lg bg-brand/10 text-brand/80 font-semibold"
            >
              Join
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      Player.attach(socket,
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

  # defp page_title(:show), do: "Show Recording"
end
