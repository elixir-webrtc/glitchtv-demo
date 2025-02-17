defmodule Sludge.Recordings do
  @moduledoc """
  The Recordings context.
  """

  import Ecto.Query, warn: false
  alias Sludge.Repo

  alias Sludge.Recordings.Recording

  @doc """
  Returns the list of recordings.

  ## Examples

      iex> list_recordings()
      [%Recording{}, ...]

  """
  def list_recordings do
    Repo.all(Recording)
  end

  @doc """
  Gets a single recording.

  Raises `Ecto.NoResultsError` if the Recording does not exist.

  ## Examples

      iex> get_recording!(123)
      %Recording{}

      iex> get_recording!(456)
      ** (Ecto.NoResultsError)

  """
  def get_recording!(id), do: Repo.get!(Recording, id)

  def get_and_increment_views!(id) do
    {1, [recording]} =
      from(r in Recording,
        select: r,
        update: [inc: [views_count: 1]],
        where: r.id == ^id
      )
      |> Repo.update_all([])

    recording
  end

  @doc """
  Creates a recording.

  ## Examples

      iex> create_recording(%{field: value})
      {:ok, %Recording{}}

      iex> create_recording(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_recording(attrs \\ %{}) do
    %Recording{}
    |> Recording.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a recording.

  ## Examples

      iex> update_recording(recording, %{field: new_value})
      {:ok, %Recording{}}

      iex> update_recording(recording, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_recording(%Recording{} = recording, attrs) do
    recording
    |> Recording.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a recording.

  ## Examples

      iex> delete_recording(recording)
      {:ok, %Recording{}}

      iex> delete_recording(recording)
      {:error, %Ecto.Changeset{}}

  """
  def delete_recording(%Recording{} = recording) do
    Repo.delete(recording)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking recording changes.

  ## Examples

      iex> change_recording(recording)
      %Ecto.Changeset{data: %Recording{}}

  """
  def change_recording(%Recording{} = recording, attrs \\ %{}) do
    Recording.changeset(recording, attrs)
  end
end
