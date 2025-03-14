defmodule SludgeWeb.StreamViewerLive do
  use SludgeWeb, :live_view

  alias LiveExWebRTC.Player
  alias Phoenix.Presence
  alias Phoenix.Socket.Broadcast
  alias SludgeWeb.ChatLive
  alias SludgeWeb.Presence

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full flex gap-4">
      <div class="flex-grow flex flex-col gap-4">
        <div class="relative">
          <Player.live_render socket={@socket} player={@player} class="max-h-[504px] w-full" />
          <img src="/images/swm-white-logo.svg" class="absolute top-6 right-6 pointer-events-none" />
        </div>
        <div class="flex flex-col gap-4 flex-grow h-[0px]">
          <div class="flex gap-3 items-center justify-start">
            <%= if @stream_metadata.streaming? do %>
              <.live_dropping />
            <% end %>
            <h1 class="text-xl line-clamp-2 dark:text-neutral-200 break-all">
              {if @stream_metadata, do: @stream_metadata.title, else: "The stream is offline"}
            </h1>
          </div>
          <div class="flex gap-4">
            <.dropping>
              <%= if @stream_metadata.streaming? do %>
                Started:&nbsp;
                <span class="sludge-dropping-featured-text">
                  {@stream_duration} minutes ago
                </span>
              <% else %>
                Stream is offline
              <% end %>
            </.dropping>
            <.dropping>
              <span class="sludge-dropping-featured-text">
                {@viewers_count} viewers
              </span>
            </.dropping>
            <.share_button />
          </div>
          <p
            :if={@stream_metadata.streaming?}
            class="flex-grow overflow-y-scroll text-sm dark:text-neutral-400 break-all"
          >
            {@stream_metadata.description}
          </p>
        </div>
      </div>
      <div class="flex justify-stretch">
        <ChatLive.live_render socket={@socket} id="livechat" />
      </div>
    </div>
    """
  end

  defp live_dropping(assigns) do
    ~H"""
    <p class="sludge-live-dropping-container">
      live
    </p>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Sludge.PubSub, "stream_info:status")
      Phoenix.PubSub.subscribe(Sludge.PubSub, "stream_info:viewers")
      {:ok, _ref} = Presence.track(self(), "stream_info:viewers", inspect(self()), %{})
    end

    socket =
      Player.attach(socket,
        id: "player",
        publisher_id: "publisher",
        pubsub: Sludge.PubSub,
        ice_servers: [%{urls: "stun:stun.l.google.com:19302"}]
        # ice_ip_filter: Application.get_env(:live_broadcaster, :ice_ip_filter)
      )
      |> assign(:page_title, "Stream")
      |> assign(:stream_metadata, Sludge.StreamService.get_stream_metadata())
      |> assign(:viewers_count, get_viewers_count())
      |> assign(:stream_duration, 0)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:started, started}, socket) do
    metadata = %{socket.assigns.stream_metadata | streaming?: true, started: started}
    {:noreply, assign(socket, :stream_metadata, metadata)}
  end

  def handle_info({:changed, {title, description}}, socket) do
    metadata = %{socket.assigns.stream_metadata | title: title, description: description}
    {:noreply, assign(socket, :stream_metadata, metadata)}
  end

  def handle_info(:finished, socket) do
    metadata = %{socket.assigns.stream_metadata | streaming?: false, started: nil}
    {:noreply, assign(socket, :stream_metadata, metadata)}
  end

  def handle_info(:tick, socket) do
    socket =
      socket
      |> assign(
        :stream_duration,
        DateTime.utc_now()
        |> DateTime.diff(socket.assigns.stream_metadata.started, :minute)
      )

    {:noreply, socket}
  end

  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :viewers_count, get_viewers_count())}
  end

  def get_viewers_count() do
    map_size(Presence.list("stream_info:viewers"))
  end
end
