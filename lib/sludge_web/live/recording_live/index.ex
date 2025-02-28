defmodule SludgeWeb.RecordingLive.Index do
  use SludgeWeb, :live_view

  alias Sludge.Recordings

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Recordings")
      |> assign(:recording, nil)
      |> stream(:recordings, Recordings.list_recordings())

    {:ok, socket}
  end

  @impl true
  def handle_info({SludgeWeb.RecordingLive.FormComponent, {:saved, recording}}, socket) do
    {:noreply, stream_insert(socket, :recordings, recording)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    recording = Recordings.get_recording!(id)
    {:ok, _} = Recordings.delete_recording(recording)

    {:noreply, stream_delete(socket, :recordings, recording)}
  end
end
