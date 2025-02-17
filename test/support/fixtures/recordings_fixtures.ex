defmodule Sludge.RecordingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Sludge.Recordings` context.
  """

  @doc """
  Generate a recording.
  """
  def recording_fixture(attrs \\ %{}) do
    {:ok, recording} =
      attrs
      |> Enum.into(%{
        date: ~U[2025-02-11 12:28:00Z],
        description: "some description",
        length_seconds: 42,
        link: "some link",
        thumbnail_link: "some thumbnail_link",
        title: "some title",
        views_count: 42
      })
      |> Sludge.Recordings.create_recording()

    recording
  end
end
