defmodule SludgeWeb.RecordingLiveTest do
  use SludgeWeb.ConnCase

  import Phoenix.LiveViewTest
  import Sludge.RecordingsFixtures

  @create_attrs %{date: "2025-02-11T12:28:00Z", link: "some link", description: "some description", title: "some title", thumbnail_link: "some thumbnail_link", length_seconds: 42, views_count: 42}
  @update_attrs %{date: "2025-02-12T12:28:00Z", link: "some updated link", description: "some updated description", title: "some updated title", thumbnail_link: "some updated thumbnail_link", length_seconds: 43, views_count: 43}
  @invalid_attrs %{date: nil, link: nil, description: nil, title: nil, thumbnail_link: nil, length_seconds: nil, views_count: nil}

  defp create_recording(_) do
    recording = recording_fixture()
    %{recording: recording}
  end

  describe "Index" do
    setup [:create_recording]

    test "lists all recordings", %{conn: conn, recording: recording} do
      {:ok, _index_live, html} = live(conn, ~p"/recordings")

      assert html =~ "Listing Recordings"
      assert html =~ recording.link
    end

    test "saves new recording", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/recordings")

      assert index_live |> element("a", "New Recording") |> render_click() =~
               "New Recording"

      assert_patch(index_live, ~p"/recordings/new")

      assert index_live
             |> form("#recording-form", recording: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#recording-form", recording: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/recordings")

      html = render(index_live)
      assert html =~ "Recording created successfully"
      assert html =~ "some link"
    end

    test "updates recording in listing", %{conn: conn, recording: recording} do
      {:ok, index_live, _html} = live(conn, ~p"/recordings")

      assert index_live |> element("#recordings-#{recording.id} a", "Edit") |> render_click() =~
               "Edit Recording"

      assert_patch(index_live, ~p"/recordings/#{recording}/edit")

      assert index_live
             |> form("#recording-form", recording: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#recording-form", recording: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/recordings")

      html = render(index_live)
      assert html =~ "Recording updated successfully"
      assert html =~ "some updated link"
    end

    test "deletes recording in listing", %{conn: conn, recording: recording} do
      {:ok, index_live, _html} = live(conn, ~p"/recordings")

      assert index_live |> element("#recordings-#{recording.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#recordings-#{recording.id}")
    end
  end

  describe "Show" do
    setup [:create_recording]

    test "displays recording", %{conn: conn, recording: recording} do
      {:ok, _show_live, html} = live(conn, ~p"/recordings/#{recording}")

      assert html =~ "Show Recording"
      assert html =~ recording.link
    end

    test "updates recording within modal", %{conn: conn, recording: recording} do
      {:ok, show_live, _html} = live(conn, ~p"/recordings/#{recording}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Recording"

      assert_patch(show_live, ~p"/recordings/#{recording}/show/edit")

      assert show_live
             |> form("#recording-form", recording: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#recording-form", recording: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/recordings/#{recording}")

      html = render(show_live)
      assert html =~ "Recording updated successfully"
      assert html =~ "some updated link"
    end
  end
end
