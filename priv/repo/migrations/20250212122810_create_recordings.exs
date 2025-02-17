defmodule Sludge.Repo.Migrations.CreateRecordings do
  use Ecto.Migration

  def change do
    create table(:recordings) do
      add :title, :string
      add :description, :string
      add :link, :string
      add :thumbnail_link, :string
      add :length_seconds, :integer
      add :date, :utc_datetime
      add :views_count, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
