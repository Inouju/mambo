defmodule Mambo.WatcherSup do
  @moduledoc false

  use Supervisor

  # Types.
  @type error :: :not_found | :simple_one_for_one

  @watcher_sup __MODULE__

  # API.

  @spec start_link() :: {:ok, pid()}
  def start_link() do
    :supervisor.start_link({:local, @watcher_sup}, __MODULE__, [])
  end

  @spec add_watcher([any()]) :: {:ok, pid()}
  def add_watcher(args) do
    :supervisor.start_child(@watcher_sup, args)
  end

  @spec remove_watcher(pid()) :: :ok | {:error, error()}
  def remove_watcher(watcher_pid) do
    :supervisor.terminate_child(@watcher_sup, watcher_pid)
  end
  # Supervisor callbacks.

  def init([]) do
    supervise([worker(Mambo.Watcher, [])], strategy: :simple_one_for_one)
  end
end
