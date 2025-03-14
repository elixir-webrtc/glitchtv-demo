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
    <div class="flex gap-4">
      <div class="flex flex-col justify-between gap-4">
        <div class="sludge-container-primary flex-1">
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
                class="sludge-input-primary"
                phx-change="validate-title"
              />
              <button class="sludge-button-primary self-start">
                Save
              </button>
            </div>
            <textarea
              name="description"
              placeholder="Description..."
              class="sludge-input-primary resize-none"
              phx-change="validate-description"
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
      Phoenix.PubSub.subscribe(Sludge.PubSub, "stream_info:viewers")
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
      |> assign(:form_data, %{:title => "", :description => ""})
      |> assign(:page_title, "Streamer Panel")
      |> assign(:viewers_count, StreamViewerLive.get_viewers_count())

    Sludge.StreamService.put_stream_metadata(%{title: "", description: ""})
    {:ok, socket}
  end

  @impl true
  def handle_event(
        "stream-config-update",
        %{"title" => title, "description" => description},
        socket
      ) do
    Sludge.StreamService.put_stream_metadata(%{title: title, description: description})

    {:noreply, socket}
  end

  def handle_event(
        "validate-title",
        %{"title" => title},
        socket
      ) do
    socket =
      socket
      |> assign(:form_data, %{socket.assigns.form_data | :title => title})

    {:noreply, socket}
  end

  def handle_event(
        "validate-description",
        %{"description" => description},
        socket
      ) do
    socket =
      socket
      |> assign(:form_data, %{socket.assigns.form_data | :description => description})

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
  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :viewers_count, StreamViewerLive.get_viewers_count())}
  end
end
