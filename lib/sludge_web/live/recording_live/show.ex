defmodule SludgeWeb.RecordingLive.Show do
  use SludgeWeb, :live_view

  alias Sludge.Recordings

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:recordings, Recordings.list_five_recordings())

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
