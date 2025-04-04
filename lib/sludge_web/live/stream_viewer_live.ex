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
    <div class="max-h-full h-full flex gap-4 flex-col lg:flex-row *:flex-1">
      <div class="flex flex-col gap-4 justify-stretch w-full">
        <div class="flex-grow relative min-h-[0px] max-h-fit">
          <div class="h-full *:flex *:max-h-full *:w-full *:h-full">
            <Player.live_render socket={@socket} player={@player} class="w-full" />
          </div>
          <img src="/images/swm-white-logo.svg" class="absolute top-6 right-6 pointer-events-none" />
        </div>
        <div class="flex flex-col gap-4 flex-shrink px-4 sm:p-0">
          <div class="flex gap-3 items-center justify-start">
            <%= if @stream_metadata.streaming? do %>
              <.live_dropping />
            <% end %>
            <h1 class="text-2xl line-clamp-2 dark:text-neutral-200 break-all">
              {if @stream_metadata, do: @stream_metadata.title, else: "The stream is offline"}
            </h1>
          </div>
          <div class="flex flex-wrap gap-4 text-sm">
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
          <p class="flex-shrink overflow-y-scroll dark:text-neutral-400 break-all min-h-8 h-32">
            {@stream_metadata.description}
          </p>
        </div>
      </div>
      <div class="flex justify-stretch *:w-full lg:max-w-[440px] flex-1 p-4 sm:p-0">
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

    metadata = Sludge.StreamService.get_stream_metadata()

    socket =
      Player.attach(socket,
        id: "player",
        publisher_id: "publisher",
        pubsub: Sludge.PubSub,
        ice_servers: [%{urls: "stun:stun.l.google.com:19302"}]
        # ice_ip_filter: Application.get_env(:live_broadcaster, :ice_ip_filter)
      )
      |> assign(:page_title, "Stream")
      |> assign(:stream_metadata, metadata)
      |> assign(:viewers_count, get_viewers_count())
      |> assign(:stream_duration, measure_duration(metadata.started))

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
        measure_duration(socket.assigns.stream_metadata.started)
      )

    {:noreply, socket}
  end

  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :viewers_count, get_viewers_count())}
  end

  def get_viewers_count() do
    map_size(Presence.list("stream_info:viewers"))
  end

  defp measure_duration(started_timestamp) do
    case started_timestamp do
      nil ->
        0

      t ->
        DateTime.utc_now()
        |> DateTime.diff(t, :minute)
    end
  end
end
