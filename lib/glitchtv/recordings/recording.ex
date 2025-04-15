defmodule Glitchtv.Recordings.Recording do
  use Ecto.Schema
  import Ecto.Changeset

  schema "recordings" do
    field :date, :utc_datetime
    field :link, :string
    field :description, :string
    field :title, :string
    field :thumbnail_link, :string
    field :length_seconds, :integer
    field :views_count, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(recording, attrs) do
    recording
    |> cast(attrs, [
      :title,
      :description,
      :link,
      :thumbnail_link,
      :length_seconds,
      :date,
      :views_count
    ])
    |> validate_required([
      :title,
      :description,
      :link,
      :thumbnail_link,
      :length_seconds,
      :date,
      :views_count
    ])
  end
end
