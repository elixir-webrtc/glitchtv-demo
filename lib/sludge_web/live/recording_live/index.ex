defmodule SludgeWeb.RecordingLive.Index do
  use SludgeWeb, :live_view

  alias Sludge.Recordings

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :recordings, Recordings.list_recordings())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Recordings")
    |> assign(:recording, nil)
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

  defp seconds_to_duration_string(seconds) do
    hours = div(seconds, 3600)
    minutes = div(seconds - hours * 3600, 60)
    seconds = rem(seconds, 60)

    "#{pad_number(hours)}:#{pad_number(minutes)}:#{pad_number(seconds)}"
  end

  defp pad_number(number) when number < 10 do
    "0#{number}"
  end

  defp pad_number(number) do
    "#{number}"
  end
end
