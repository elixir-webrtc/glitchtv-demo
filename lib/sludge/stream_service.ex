defmodule Sludge.StreamService do
  @moduledoc false

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__,  args, name: __MODULE__)
  end

  def get_stream_metadata do
    GenServer.call(__MODULE__, :get_stream_metadata)
  end

  def stream_started do
    GenServer.call(__MODULE__, :stream_started)
  end

  def stream_ended do
    GenServer.call(__MODULE__, :stream_ended)
  end

  def put_stream_metadata(metadata) do
    GenServer.call(__MODULE__, {:put_stream_metadata, metadata})
  end

  @impl true
  def init(_arg) do
    state = %{
      streaming?: false,
      title: nil,
      description: nil,
      started: nil
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:get_stream_metadata, _from, %{streaming?: true} = state) do
    resp = %{
      title: state.title || "",
      description: state.description || "",
      started: state.started
    }
    
    {:reply, resp, state}
  end

  @impl true
  def handle_call(:get_stream_metadata, _from, state) do
    {:reply, nil, state}
  end

  @impl true
  def handle_call({:put_stream_metadata, metadata}, _from, state) do
    state = %{state |
      title: metadata.title || "",
      description: metadata.description || "",
    }

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:stream_started, _from, state) do
    state = %{ state |
      streaming?: true,
      started: DateTime.utc_now()
    }

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:stream_ended, _from, state) do
    state = %{ state |
      streaming?: false,
      title: nil,
      description: nil,
      started: nil
    }

    {:reply, :ok, state}
  end
end
