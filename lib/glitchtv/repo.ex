defmodule Glitchtv.Repo do
  use Ecto.Repo,
    otp_app: :glitchtv,
    adapter: Ecto.Adapters.SQLite3
end
