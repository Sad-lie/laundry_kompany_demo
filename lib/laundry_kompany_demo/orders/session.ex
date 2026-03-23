defmodule LaundryKompanyDemo.Orders.Session do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:phone, :string, []}
  schema "sessions" do
    field(:state, :string, default: "idle")
    field(:data, :map, default: %{})

    timestamps(type: :utc_datetime)
  end

  def changeset(session, attrs) do
    session
    |> cast(attrs, [:phone, :state, :data])
    |> validate_required([:phone])
  end
end
