defmodule LaundryKompanyDemo.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    run_migrations()

    children = [
      LaundryKompanyDemoWeb.Telemetry,
      LaundryKompanyDemo.Repo,
      {DNSCluster,
       query: Application.get_env(:laundry_kompany_demo, :dns_cluster_query) || :ignore},
      {LaundryKompanyDemo.OrderStore, []},
      {Phoenix.PubSub, name: LaundryKompanyDemo.PubSub},
      {Finch, name: LaundryKompanyDemo.Finch},
      {Bandit, plug: LaundryKompanyDemoWeb.Router, port: 4000}
    ]

    opts = [strategy: :one_for_one, name: LaundryKompanyDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp run_migrations do
    IO.puts("Starting migrations...")

    try do
      {:ok, _} = LaundryKompanyDemo.Repo.start_link(pool_size: 1)
      Ecto.Migrator.run(LaundryKompanyDemo.Repo, :up, pool_size: 1)
      IO.puts("Migrations complete!")
    rescue
      e ->
        IO.puts("Migration error (this is normal on first run): #{inspect(e)}")
    end
  end
end
