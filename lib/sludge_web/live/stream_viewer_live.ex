defmodule SludgeWeb.StreamViewerLive do
  use SludgeWeb, :live_view

  alias LiveExWebRTC.Player
  alias Phoenix.Presence
  alias Phoenix.Socket.Broadcast
  alias SludgeWeb.ChatLive
  alias SludgeWeb.Presence

  @impl true
  def render(assigns) do
    assigns =
      assign(
        assigns,
        :start_difference,
        if assigns.stream_metadata[:started] != nil do
          DateTime.utc_now()
          |> DateTime.diff(assigns.stream_metadata.started, :minute)
        else
          0
        end
      )

    ~H"""
    <div class="h-full flex gap-4">
      <div class="flex-grow flex flex-col gap-4">
        <div class="relative">
          <Player.live_render socket={@socket} player={@player} class="max-h-[502px] w-full" />
          <img src="/images/swm-white-logo.svg" class="absolute top-6 right-6" />
        </div>
        <div class="flex flex-col gap-4 flex-grow h-[0px]">
          <div class="flex gap-3 items-center justify-start">
            <%= if @stream_metadata.streaming? do %>
              <.live_dropping />
            <% end %>
            <h1 class="text-2xl line-clamp-2 dark:text-neutral-200">
              {if @stream_metadata, do: @stream_metadata.title, else: "The stream is offline"}
            </h1>
          </div>
          <div class="flex gap-4 text-sm">
            <.dropping>
              <%= if @stream_metadata.streaming? do %>
                Started:&nbsp;
                <span class="text-indigo-800 font-medium dark:text-neutral-200">
                  {@start_difference} minutes ago
                </span>
              <% else %>
                Stream is offline
              <% end %>
            </.dropping>
            <.dropping>
              <span class="text-indigo-800 font-medium dark:text-neutral-200">
                {@viewers_count} viewers
              </span>
            </.dropping>
            <.share_button />
          </div>
          <p
            :if={@stream_metadata.streaming?}
            class="flex-grow overflow-y-scroll dark:text-neutral-400"
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
    <p class="uppercase inline text-sm bg-[#FF0011] p-1 px-2 text-xs text-white rounded-md font-medium tracking-[8%]">
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

  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :viewers_count, get_viewers_count())}
  end

  def get_viewers_count() do
    map_size(Presence.list("stream_info:viewers"))
  end
end
