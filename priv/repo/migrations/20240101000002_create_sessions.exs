defmodule LaundryKompanyDemo.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions, primary_key: false) do
      add(:phone, :string, primary_key: true)
      add(:state, :string, default: "idle", null: false)
      add(:data, :map, default: %{})

      timestamps(type: :utc_datetime)
    end
  end
end
