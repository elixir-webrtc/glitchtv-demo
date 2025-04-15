defmodule GlitchtvWeb.RecordingLive.Show do
  use GlitchtvWeb, :live_view

  alias Glitchtv.Recordings

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :recordings, Recordings.list_five_recordings())
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    recording =
      if connected?(socket) do
        Recordings.get_and_increment_views!(id)
      else
        Recordings.get_recording!(id)
      end

    socket =
      socket
      |> assign(:page_title, recording.title)
      |> assign(:recording, recording)

    {:noreply, socket}
  end
end
