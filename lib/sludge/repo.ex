defmodule Sludge.Repo do
  use Ecto.Repo,
    otp_app: :sludge,
    adapter: Ecto.Adapters.SQLite3
end
