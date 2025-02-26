defmodule SludgeWeb.StreamViewerLive do
  use SludgeWeb, :live_view

  alias LiveExWebRTC.Player

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
      <div class="flex-grow">
        <Player.live_render socket={@socket} player={@player} />
        <div class="flex flex-col gap-4 mt-4">
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
          <p :if={@stream_metadata}>
            {@stream_metadata.description}
          </p>
        </div>
      </div>
      <div class="flex flex-col justify-between border border-indigo-200 rounded-lg">
        <ul
          class="w-[448px] h-[0px] overflow-y-scroll flex-grow flex flex-col gap-6 p-6"
          phx-hook="ScrollDownHook"
          id="message_box"
        >
          <li :for={comment <- @comments} class="flex flex-col gap-1">
            <p class="text-indigo-800 text-[13px] text-medium">
              {comment.author}
            </p>
            <p>
              {comment.text}
            </p>
          </li>
        </ul>
        <form class="flex flex-col gap-2 border-t border-indigo-200 p-6">
          <textarea
            class="border border-indigo-200 rounded-lg resize-none h-[128px] text-[13px]"
            placeholder="Your message"
          />
          <div class="flex gap-2">
            <input
              class="flex-grow border border-indigo-200 rounded-lg px-4 text-[13px]"
              placeholder="Your Nickname"
            />
            <button class="bg-indigo-800 text-white px-12 py-2 rounded-lg text-[13px] font-medium">
              Send
            </button>
          </div>
        </form>
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
      |> assign(
        :comments,
        Enum.map(1..20, fn _ ->
          %{
            author: "AnthonyBrookeWood",
            text:
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas nec ante ac nulla vulputate ultricies."
          }
        end)
      )
      # |> assign(:page_title, page_title(socket.assigns.live_action))
      # |> assign(:recording, Recordings.get_recording!(id))}
    }
  end

  # defp page_title(:show), do: "Show Recording"
end
