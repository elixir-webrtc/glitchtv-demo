defmodule GlitchtvWeb.StreamerLive do
  use GlitchtvWeb, :live_view

  alias LiveExWebRTC.Publisher
  alias Phoenix.Socket.Broadcast
  alias GlitchtvWeb.ChatLive
  alias GlitchtvWeb.StreamViewerLive

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
    <div class="flex gap-4">
      <div class="flex flex-col justify-between gap-4">
        <div class="glitchtv-container-primary flex-1">
          <div class="border-b border-indigo-200 px-8 py-2 flex justify-between items-center gap-4 dark:border-zinc-800">
            <h1 class="font-medium dark:text-neutral-200">Stream details</h1>
            <.dropping class="py-1">
              <div class="flex items-center gap-2 text-xs">
                <.icon name="hero-eye" class="w-4 h-4" />
                {@viewers_count}
              </div>
            </.dropping>
          </div>
          <form phx-submit="stream-config-update" class="flex-1 flex flex-col items-stretch gap-2 p-4">
            <div class="flex gap-2">
              <input
                type="text"
                name="title"
                value={@form_data.title}
                placeholder="Title..."
                class="glitchtv-input-primary"
                phx-change="update-title"
              />
              <button class="glitchtv-button-primary self-start">
                Save
              </button>
            </div>
            <textarea
              name="description"
              placeholder="Description..."
              class="glitchtv-input-primary resize-none"
              phx-change="update-description"
            >{@form_data.description}</textarea>
          </form>
        </div>
        <div class="flex items-stretch justify-stretch *:w-full">
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
      Phoenix.PubSub.subscribe(Glitchtv.PubSub, "stream_info:viewers")
    end

    socket =
      Publisher.attach(socket,
        id: "publisher",
        pubsub: Glitchtv.PubSub,
        on_connected: &on_connected/1,
        on_disconnected: &on_disconnected/1,
        on_recording_finished: &on_recording_finished/2,
        on_recorder_message: &on_recorder_message/2,
        ice_ip_filter: Application.get_env(:glitchtv, :ice_ip_filter, fn _ -> true end),
        ice_servers: [%{urls: "stun:stun.l.google.com:19302"}],
        recorder_opts: [
          s3_upload_config: [bucket_name: Application.get_env(:glitchtv, :bucket_name)]
        ],
        video_codecs: @video_codecs,
        audio_codecs: @audio_codecs
      )
      |> assign(:form_data, %{title: "", description: ""})
      |> assign(:page_title, "Streamer Panel")
      |> assign(:viewers_count, StreamViewerLive.get_viewers_count())

    Glitchtv.StreamService.put_stream_metadata(%{title: "", description: ""})
    {:ok, socket}
  end

  @impl true
  def handle_event(
        "stream-config-update",
        %{"title" => title, "description" => description},
        socket
      ) do
    Glitchtv.StreamService.put_stream_metadata(%{title: title, description: description})

    {:noreply, socket}
  end

  def handle_event(
        "update-title",
        %{"title" => title},
        socket
      ) do
    socket =
      socket
      |> assign(:form_data, %{socket.assigns.form_data | title: title})

    {:noreply, socket}
  end

  def handle_event(
        "update-description",
        %{"description" => description},
        socket
      ) do
    socket =
      socket
      |> assign(:form_data, %{socket.assigns.form_data | description: description})

    {:noreply, socket}
  end

  defp on_connected("publisher") do
    Glitchtv.StreamService.stream_started()
  end

  defp on_disconnected("publisher") do
    Glitchtv.StreamService.stream_ended()
  end

  # Gets called before on_disconnected, so everything is OK
  defp on_recording_finished("publisher", {:ok, _manifest, ref}) do
    metadata = Glitchtv.StreamService.get_stream_metadata()

    if ref != nil do
      Glitchtv.RecordingsService.upload_started(ref, metadata)
    end
  end

  defp on_recorder_message(
         "publisher",
         {:ex_webrtc_recorder, _, {:upload_complete, ref, manifest}}
       ) do
    Glitchtv.RecordingsService.upload_complete(ref, manifest)
  end

  @impl Phoenix.LiveView
  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :viewers_count, StreamViewerLive.get_viewers_count())}
  end
end
