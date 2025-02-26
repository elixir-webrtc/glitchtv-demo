defmodule SludgeWeb.StreamViewerLive do
  require Logger

  use SludgeWeb, :live_view

  alias LiveExWebRTC.Player
  alias SludgeWeb.ChatLive

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
      <ChatLive.live_render socket={@socket} id="livechat" />
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
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

  # defp page_title(:show), do: "Show Recording"
end
