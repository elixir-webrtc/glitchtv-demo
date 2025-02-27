defmodule SludgeWeb.StreamViewerLive do
  use SludgeWeb, :live_view

  alias LiveExWebRTC.Player
  alias SludgeWeb.ChatLive

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
    <div class="h-full flex gap-4 p-6">
      <div class="flex-grow flex flex-col gap-4">
        <Player.live_render socket={@socket} player={@player} />
        <div class="flex flex-col gap-4 flex-grow h-[0px]">
          <div class="flex gap-3 items-center justify-start">
            <span :if={@stream_metadata}>
              <.live_dropping />
            </span>
            <h1 class="text-2xl">
              {if @stream_metadata, do: @stream_metadata.title, else: "The stream is offline"}
            </h1>
          </div>
          <div :if={@stream_metadata} class="flex gap-4 text-sm">
            <.dropping>
              Started:&nbsp;
              <span class="text-indigo-800 font-medium">
                {@start_difference} minutes ago
              </span>
            </.dropping>
            <.dropping>
              <span class="text-indigo-800 font-medium">
                435 viewers
              </span>
            </.dropping>
            <button class="border border-indigo-200 text-indigo-800 font-medium rounded-lg px-6 py-3 flex gap-2 items-center">
              Share <.icon name="hero-share" class="fill-indigo-800" />
            </button>
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
