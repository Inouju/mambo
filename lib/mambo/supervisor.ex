defmodule Mambo.Supervisor do
  @moduledoc """
  Main bot supervisor, it supervises the processes `Mambo.WatcherSup`, `Mambo.Bot`
  and `Mambo.EventManager`.
  """

  use Supervisor

  @supervisor __MODULE__

  # API.

  @spec start_link() :: {:ok, pid}
  def start_link() do
    :supervisor.start_link({:local, @supervisor}, __MODULE__, [])
  end

  # Supervisor callbacks.

  def init([]) do
    children = [supervisor(Mambo.WatcherSup, []),
                worker(Mambo.EventManager, [], modules: :dynamic),
                worker(Mambo.Bot, [])]
    supervise(children, strategy: :one_for_all, max_restarts: 10, max_seconds: 60)
  end
end
