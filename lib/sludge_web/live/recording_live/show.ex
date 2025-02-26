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
    if socket.assigns[:recording] do
      {:noreply, socket}
    else
      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action))
       |> assign(:recording, Recordings.get_and_increment_views!(id))}
    end
  end

  defp page_title(:show), do: "Show Recording"
end
