defmodule SludgeWeb.StreamerLive do
  use SludgeWeb, :live_view

  alias LiveExWebRTC.Publisher

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
    <div class="text-[#606060] flex flex-col gap-6 py-2.5">
      <.simple_form for={@form} phx-submit="stream-config-update">
        <.input
          type="textarea"
          field={@form[:title]}
          class="max-w-2xl rounded-lg h-12"
          placeholder="Title"
        />
        <.input
          type="textarea"
          field={@form[:description]}
          class="max-w-2xl rounded-lg h-40"
          placeholder="Description"
        />
        <:actions>
          <.button class="rounded-lg bg-brand/100 text-white py-2.5 max-w-36 hover:bg-brand/90">
            Save
          </.button>
        </:actions>
      </.simple_form>
    </div>

    <Publisher.live_render socket={@socket} publisher={@publisher} />
    """
  end

  @impl true
  def mount(_params, _session, socket) do
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
end
