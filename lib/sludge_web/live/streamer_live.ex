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
    <div class="flex gap-2 h-full p-4">
      <div class="flex flex-col gap-4 flex-grow justify-between">
        <div class="border border-violet-200 rounded-lg">
          <div class="py-4 p-8 border-b border-violet-200">
            <h1 class="font-medium">Stream settings</h1>
          </div>
          <form
            phx-submit="stream-config-update"
            class="grid grid-rows-[repeat(2, auto-fill)] grid-cols-[1fr_auto] gap-4 p-8"
          >
            <div class="flex flex-col">
              <label for="title" class="text-sm">Title:</label>
              <input
                class="flex-grow border border-violet-200 rounded-lg px-4 py-2 text-[13px]"
                placeholder="Stream title..."
                id="title"
              />
            </div>
            <div>
              <label for="audio-select">Audio device:</label>
              <select id="audio-select">
                <option>Audio 1</option>
                <option>Audio 2</option>
              </select>
            </div>
            <div class="flex flex-col">
              <label for="description" class="text-sm">Description:</label>
              <textarea
                class="border border-violet-200 rounded-lg resize-none h-[128px] text-[13px]"
                placeholder="Short description of the stream..."
                id="description"
              />
            </div>
            <div class="flex flex-col justify-between">
              <div>
                <label for="video-select">Video device:</label>
                <select id="video-select">
                  <option>Video 1</option>
                  <option>Video 2</option>
                </select>
              </div>
              <div>
                <label>Record stream:</label>
                <.button class="rounded-lg bg-brand/100 text-white py-2.5 max-w-36 hover:bg-brand/90">
                  Save
                </.button>
              </div>
            </div>
          </form>
        </div>
        <%!-- <Publisher.live_render socket={@socket} publisher={@publisher} /> --%>
        <div class="flex gap-4 flex-grow">
          <div class="flex flex-col gap-2 flex-1">
            <div class="flex-grow">
              <video
                src="https://videos.pexels.com/video-files/3195394/3195394-uhd_2560_1440_25fps.mp4"
                controls
                class="rounded-xl object-cover max-w-full h-full w-full"
              />
            </div>
            <button class="p-4 bg-red-500 rounded-lg">Start streaming</button>
          </div>
          <div class="rounded-lg border border-violet-200 flex-1">
            <div class="px-8 py-4 border-b border-violet-200">
              <h1 class="font-medium">Statistics</h1>
            </div>
            <div class="p-4 text-sm divide-y divide-violet-200 *:p-4 flex flex-col items-stretch">
              <div class="flex justify-between items-center">
                <p>Audio bitrate (kbps):</p>
                <p>0</p>
              </div>
              <div class="flex justify-between items-center">
                <p>Video bitrate (kbps):</p>
                <p>0</p>
              </div>
              <div class="flex justify-between items-center">
                <p>Packet loss (%):</p>
                <p>0</p>
              </div>
              <div class="flex justify-between items-center">
                <p>Time:</p>
                <p>00:00:00</p>
              </div>
              <div class="flex justify-center">
                <svg
                  width="24"
                  height="23"
                  viewBox="0 0 24 23"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    d="M16.9409 15.4559C16.5391 15.0976 16.474 14.5111 16.7563 14.055C17.321 13.1645 17.6251 12.122 17.6251 11.0577C17.6251 9.83055 17.2341 8.67941 16.5283 7.71289C16.2025 7.27849 16.235 6.69207 16.6043 6.30111C17.0604 5.82328 17.8423 5.85586 18.2332 6.37713C19.2432 7.71289 19.7971 9.34186 19.7971 11.0577C19.7971 12.5455 19.3735 14.0007 18.5699 15.2387C18.2115 15.7926 17.4405 15.8795 16.9409 15.4451V15.4559Z"
                    fill="#E15B5B"
                  />
                  <path
                    d="M7.28653 15.7059C6.81956 16.1621 6.03765 16.1295 5.65756 15.5973C4.71276 14.2833 4.20234 12.7195 4.20234 11.0688C4.20234 9.29866 4.82135 7.57195 5.91819 6.19275C6.33087 5.68234 7.11277 5.67148 7.55803 6.16017C7.9164 6.56199 7.92726 7.14842 7.59061 7.57195C6.79784 8.56019 6.36345 9.77649 6.36345 11.0688C6.36345 12.2525 6.72182 13.3819 7.39513 14.3159C7.6992 14.7503 7.65577 15.3367 7.27567 15.7059H7.28653Z"
                    fill="#E15B5B"
                  />
                  <path
                    d="M19.971 18.4315C19.5692 18.0623 19.4932 17.4433 19.8298 17.0089C21.1222 15.3039 21.828 13.2297 21.828 11.0686C21.828 8.71201 21.0136 6.49661 19.504 4.72646C19.1457 4.30293 19.1782 3.68392 19.5692 3.29296C20.0145 2.83685 20.7746 2.85857 21.1873 3.34726C22.99 5.4975 24 8.24504 24 11.0686C24 13.6858 23.1529 16.2053 21.5891 18.2795C21.1982 18.8008 20.4488 18.8659 19.971 18.4315Z"
                    fill="#E15B5B"
                  />
                  <path
                    d="M4.28963 18.7247C3.83351 19.1808 3.07333 19.1374 2.67151 18.627C0.933944 16.4985 0 13.8487 0 11.0686C0 8.28845 1.06426 5.34544 2.95387 3.18434C3.3774 2.69565 4.12673 2.68479 4.57198 3.16262C4.94121 3.56443 4.97379 4.18344 4.60456 4.59612C3.05161 6.36627 2.17196 8.67941 2.17196 11.0686C2.17196 13.4577 2.95387 15.5428 4.38736 17.2912C4.73488 17.7148 4.69144 18.3338 4.30049 18.7247H4.28963Z"
                    fill="#E15B5B"
                  />
                  <path
                    d="M11.9997 13.6641C13.4332 13.6641 14.5952 12.502 14.5952 11.0686C14.5952 9.63514 13.4332 8.47309 11.9997 8.47309C10.5663 8.47309 9.40424 9.63514 9.40424 11.0686C9.40424 12.502 10.5663 13.6641 11.9997 13.6641Z"
                    fill="#E15B5B"
                  />
                  <path
                    d="M2.78572 0.318077C2.36162 -0.106026 1.67402 -0.106026 1.24992 0.318077C0.825813 0.742179 0.825813 1.42978 1.24992 1.85389L21.2078 21.8117C21.6319 22.2358 22.3195 22.2358 22.7436 21.8117C23.1677 21.3876 23.1677 20.7 22.7436 20.2759L2.78572 0.318077Z"
                    fill="#E15B5B"
                  />
                </svg>
              </div>
            </div>
          </div>
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
