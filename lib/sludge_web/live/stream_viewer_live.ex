defmodule SludgeWeb.StreamViewerLive do
  use SludgeWeb, :live_view

  alias LiveExWebRTC.Player
  alias Phoenix.Presence
  alias Phoenix.Socket.Broadcast
  alias SludgeWeb.ChatLive
  alias SludgeWeb.Presence

  @impl true
  def render(assigns) do
    # TODO: Better logic for this
    assigns =
      assign(
        assigns,
        :start_difference,
        if assigns.stream_metadata != nil do
          {:ok, started_datetime} =
            DateTime.from_naive(assigns.stream_metadata.started, "Etc/UTC")

          {:ok, now_datetime} = DateTime.now("Etc/UTC")

          DateTime.diff(now_datetime, started_datetime, :minute)
        else
          2
        end
      )

    ~H"""
    <div class="h-full flex gap-4">
      <div class="flex-grow flex flex-col gap-4">
        <Player.live_render socket={@socket} player={@player} class="max-h-[480px] w-full" />
        <div class="flex flex-col gap-4 flex-grow h-[0px]">
          <div class="flex gap-3 items-center justify-start">
            <span :if={@stream_metadata}>
              <.live_dropping />
            </span>
            <h1 class="text-2xl line-clamp-2">
              {if @stream_metadata, do: @stream_metadata.title, else: "The stream is offline"}
            </h1>
          </div>
          <div :if={@stream_metadata} class="flex gap-4 text-sm h-[44px] items-stretch">
            <.dropping>
              Started:&nbsp;
              <span class="text-indigo-800 font-medium">
                {@start_difference} minutes ago
              </span>
            </.dropping>
            <.dropping>
              <span class="text-indigo-800 font-medium">
                {@viewers_count} viewers
              </span>
            </.dropping>
            <.share_button />
          </div>
          <p :if={@stream_metadata} class="flex-grow overflow-y-scroll">
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
      Phoenix.PubSub.subscribe(Sludge.PubSub, "viewers")
      {:ok, _ref} = Presence.track(self(), "viewers", "count", %{})
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
  def handle_info(%Broadcast{event: "presence_diff"} = _event, socket) do
    {:noreply, assign(socket, :viewers_count, get_viewers_count())}
  end

  def get_viewers_count() do
    case Presence.list("viewers") do
      %{"count" => %{metas: list}} -> Enum.count(list)
      _other -> 0
    end
  end
end
