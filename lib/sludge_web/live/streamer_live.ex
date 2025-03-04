defmodule SludgeWeb.StreamerLive do
  use SludgeWeb, :live_view

  alias LiveExWebRTC.Publisher
  alias Phoenix.Socket.Broadcast
  alias SludgeWeb.ChatLive
  alias SludgeWeb.StreamViewerLive

  # XXX add this as defaults in live_ex_webrtc, so that recordings work by default?
  @video_codecs [
    %ExWebRTC.RTPCodecParameters{
      payload_type: 96,
      mime_type: "video/VP8",
      clock_rate: 90_000
    }
  ]

  @audio_codecs [
    %ExWebRTC.RTPCodecParameters{
      payload_type: 111,
      mime_type: "audio/opus",
      clock_rate: 48_000,
      channels: 2
    }
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex gap-4 h-full p-4">
      <div class="flex-grow flex flex-col">
        <form phx-submit="stream-config-update" class="flex items-start gap-2 mb-4">
          <input type="text" name="title" placeholder="Title..." class="rounded-lg border-indigo-200" />
          <textarea
            name="description"
            placeholder="Description..."
            class="rounded-lg flex-1 resize-none border-indigo-200 self-stretch"
          />

          <button class="rounded-lg bg-indigo-800 text-white py-2 px-4 max-w-36 self-stretch hover:bg-indigo-900">
            Save
          </button>
        </form>
        <div class="flex-grow flex items-stretch justify-stretch">
          <Publisher.live_render socket={@socket} publisher={@publisher} />
        </div>
      </div>
      <ChatLive.live_render socket={@socket} id="livechat" />
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Sludge.PubSub, "viewers")
    end

    socket =
      Publisher.attach(socket,
        id: "publisher",
        pubsub: Sludge.PubSub,
        on_connected: &on_connected/1,
        on_disconnected: &on_disconnected/1,
        on_recording_finished: &on_recording_finished/2,
        ice_servers: [%{urls: "stun:stun.l.google.com:19302"}],
        # ice_ip_filter: Application.get_env(:live_broadcaster, :ice_ip_filter),
        video_codecs: @video_codecs,
        audio_codecs: @audio_codecs
      )
      |> assign(:form, %{"title" => "", "description" => ""} |> to_form())
      |> assign(:page_title, "Streamer Panel")
      |> assign(:viewers_count, StreamViewerLive.get_viewers_count())

    {:ok, socket}
  end

  @impl true

  @impl true
  def handle_event(
        "stream-config-update",
        %{"title" => title, "description" => description},
        socket
      ) do
    Sludge.StreamService.put_stream_metadata(%{title: title, description: description})

    {:noreply, socket}
  end

  defp on_connected("publisher") do
    Sludge.StreamService.stream_started()
  end

  defp on_disconnected("publisher") do
    Sludge.StreamService.stream_ended()
  end

  # Gets called before on_disconnected, so everything is OK
  defp on_recording_finished("publisher", {:ok, manifest, nil}) do
    # XXX terrible name
    metadata = Sludge.StreamService.get_stream_metadata()
    Sludge.RecordingsService.recording_complete(manifest, metadata)
  end

  @impl Phoenix.LiveView
  def handle_info(%Broadcast{event: "presence_diff"} = _event, socket) do
    {:noreply, assign(socket, :viewers_count, StreamViewerLive.get_viewers_count())}
  end
end
