defmodule LaundryKompanyDemo.Repo do
  use Ecto.Repo,
    otp_app: :laundry_kompany_demo,
    adapter: Ecto.Adapters.Postgres
end
