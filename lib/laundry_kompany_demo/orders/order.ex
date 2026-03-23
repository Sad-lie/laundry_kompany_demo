defmodule LaundryKompanyDemo.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, []}
  schema "orders" do
    field(:phone, :string)
    field(:service, :string)
    field(:date, :string)
    field(:time, :string)
    field(:address, :string)
    field(:status, :string, default: "pending")
    field(:kg, :integer, default: 0)
    field(:total, :decimal, default: 0)
    field(:notes, :string)

    timestamps(type: :utc_datetime)
  end

  def changeset(order, attrs) do
    order
    |> cast(attrs, [:id, :phone, :service, :date, :time, :address, :status, :kg, :total, :notes])
    |> validate_required([:phone, :service, :address])
    |> validate_inclusion(:status, ["pending", "picked_up", "washing", "ready", "delivered"])
  end
end
