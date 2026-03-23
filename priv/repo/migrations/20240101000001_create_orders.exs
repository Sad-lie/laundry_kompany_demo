defmodule LaundryKompanyDemo.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:phone, :string, null: false)
      add(:service, :string, null: false)
      add(:date, :string)
      add(:time, :string)
      add(:address, :string, null: false)
      add(:status, :string, default: "pending", null: false)
      add(:kg, :integer, default: 0)
      add(:total, :decimal, precision: 10, scale: 2, default: 0)
      add(:notes, :text)

      timestamps(type: :utc_datetime)
    end

    create(index(:orders, [:phone]))
    create(index(:orders, [:status]))
  end
end
