defmodule Sludge.RecordingsService do
  @moduledoc false

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def recording_complete(manifest, metadata) do
    GenServer.call(__MODULE__, {:recording_complete, manifest, metadata})
  end

  @impl true
  def init(_arg) do
    state = %{
      assets_path: File.cwd!() |> Path.join("priv/static")
    }

    # ExWebRTC.Recorder.controlling_process(Sludge.Recorder, self())

    {:ok, state}
  end

  @impl true
  def handle_call({:recording_complete, manifest, metadata}, _from, state) do
    # XXX SHOULD RECORDER EXPAND PATHS?
    # XXX MAYBE ADD OPTION PATH_PREFIX OR SOME SUCH?
    result_manifest =
      ExWebRTC.Recorder.Converter.convert!(manifest,
        thumbnails_ctx: %{},
        output_path: "./priv/static/content/"
      )
      |> Map.values()
      |> List.first()

    title =
      if metadata.title == nil or metadata.title == "",
        do: "Untitled recording",
        else: metadata.title

    description =
      if metadata.description == nil or metadata.description == "",
        do: "No description provided",
        else: metadata.description

    {:ok, _} =
      Sludge.Recordings.create_recording(%{
        title: title,
        description: description,
        link: result_manifest.location |> rewrite_location(state),
        thumbnail_link: result_manifest.thumbnail_location |> rewrite_location(state),
        length_seconds: result_manifest.duration_seconds,
        date: metadata.started,
        views_count: 0
      })

    {:reply, :ok, state}
  end

  defp rewrite_location(location, state) do
    "/#{Path.relative_to(location, state.assets_path)}"
  end

  # JEST I SIE POJAWIŁO, ale nie ma autorefresh
  #     a może jest? chyba jednak jest z marszu

  # @impl true
  # def handle_info({:ex_webrtc_recorder, _pid, {upload_result, ref, manifest}}, state) do
  #   IO.inspect(manifest, label: :ULOAD_COMPLETE_MANIFEST)

  #   # trzeba coś z tą refką zrobić
  #   if upload_result == :upload_complete do
  #     Sludge.Recordings.create_recording(%{
  #       title: "#{inspect(ref)}",
  #       description: "guwno z dupy",
  #       link: manifest |> Map.values() |> List.first() |> Map.get(:location),
  #       thumbnail_link: manifest |> Map.values() |> List.first() |> Map.get(:thumbnail_location),
  #       length_seconds: 2137,
  #       date: DateTime.utc_now(),
  #       views_count: 0
  #     })
  #   end

  #   {:noreply, state}
  # end
end
