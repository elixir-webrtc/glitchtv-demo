defmodule Glitchtv.RecordingsTest do
  use Glitchtv.DataCase

  alias Glitchtv.Recordings

  describe "recordings" do
    alias Glitchtv.Recordings.Recording

    import Glitchtv.RecordingsFixtures

    @invalid_attrs %{
      date: nil,
      link: nil,
      description: nil,
      title: nil,
      thumbnail_link: nil,
      length_seconds: nil,
      views_count: nil
    }

    test "list_recordings/0 returns all recordings" do
      recording = recording_fixture()
      assert Recordings.list_recordings() == [recording]
    end

    test "get_recording!/1 returns the recording with given id" do
      recording = recording_fixture()
      assert Recordings.get_recording!(recording.id) == recording
    end

    test "create_recording/1 with valid data creates a recording" do
      valid_attrs = %{
        date: ~U[2025-02-11 12:28:00Z],
        link: "some link",
        description: "some description",
        title: "some title",
        thumbnail_link: "some thumbnail_link",
        length_seconds: 42,
        views_count: 42
      }

      assert {:ok, %Recording{} = recording} = Recordings.create_recording(valid_attrs)
      assert recording.date == ~U[2025-02-11 12:28:00Z]
      assert recording.link == "some link"
      assert recording.description == "some description"
      assert recording.title == "some title"
      assert recording.thumbnail_link == "some thumbnail_link"
      assert recording.length_seconds == 42
      assert recording.views_count == 42
    end

    test "create_recording/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Recordings.create_recording(@invalid_attrs)
    end

    test "update_recording/2 with valid data updates the recording" do
      recording = recording_fixture()

      update_attrs = %{
        date: ~U[2025-02-12 12:28:00Z],
        link: "some updated link",
        description: "some updated description",
        title: "some updated title",
        thumbnail_link: "some updated thumbnail_link",
        length_seconds: 43,
        views_count: 43
      }

      assert {:ok, %Recording{} = recording} =
               Recordings.update_recording(recording, update_attrs)

      assert recording.date == ~U[2025-02-12 12:28:00Z]
      assert recording.link == "some updated link"
      assert recording.description == "some updated description"
      assert recording.title == "some updated title"
      assert recording.thumbnail_link == "some updated thumbnail_link"
      assert recording.length_seconds == 43
      assert recording.views_count == 43
    end

    test "update_recording/2 with invalid data returns error changeset" do
      recording = recording_fixture()
      assert {:error, %Ecto.Changeset{}} = Recordings.update_recording(recording, @invalid_attrs)
      assert recording == Recordings.get_recording!(recording.id)
    end

    test "delete_recording/1 deletes the recording" do
      recording = recording_fixture()
      assert {:ok, %Recording{}} = Recordings.delete_recording(recording)
      assert_raise Ecto.NoResultsError, fn -> Recordings.get_recording!(recording.id) end
    end

    test "change_recording/1 returns a recording changeset" do
      recording = recording_fixture()
      assert %Ecto.Changeset{} = Recordings.change_recording(recording)
    end
  end
end
