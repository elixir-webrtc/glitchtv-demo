defmodule Glitchtv.RecordingsService do
  @moduledoc false

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def upload_started(ref, metadata) do
    GenServer.cast(__MODULE__, {:upload_started, ref, metadata})
  end

  def upload_complete(ref, manifest) do
    GenServer.cast(__MODULE__, {:upload_complete, ref, manifest})
  end

  @impl true
  def init(_arg) do
    s3_config = Application.fetch_env!(:ex_aws, :s3)

    state = %{
      upload_tasks: %{},
      s3_config: s3_config
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:upload_started, ref, metadata}, state) do
    state = put_in(state[:upload_tasks][ref], metadata)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:upload_complete, ref, manifest}, state) do
    {metadata, state} = pop_in(state[:upload_tasks][ref])

    if metadata == nil, do: raise("uh oh")

    result_manifest =
      ExWebRTC.Recorder.Converter.convert!(manifest,
        thumbnails_ctx: %{},
        s3_upload_config: [bucket_name: Application.get_env(:glitchtv, :bucket_name)],
        only_rids: ["h", nil]
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
      Glitchtv.Recordings.create_recording(%{
        title: title,
        description: description,
        link: result_manifest.location |> rewrite_location(state),
        thumbnail_link: result_manifest.thumbnail_location |> rewrite_location(state),
        length_seconds: result_manifest.duration_seconds,
        date: metadata.started,
        views_count: 0
      })

    {:noreply, state}
  end

  defp rewrite_location(location, state) do
    # FIXME this is workaround. Converter should return either correct url or separate parts of the url.
    # https://stackoverflow.com/questions/7933458/how-to-format-a-url-to-get-a-file-from-amazon-s3
    [bucket_name, file] =
      location
      |> String.trim_leading("s3://")
      |> String.split("/")

    "#{state.s3_config[:scheme]}#{bucket_name}.#{state.s3_config[:host]}/#{file}"
  end
end
