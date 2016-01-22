defmodule Mambo do
  @moduledoc """
  Entry point of the bot.
  """

  use Application

  @doc """
  Starts the bot application.
  """
  @spec start(:normal | {:takeover, node} | {:failover, node}, []) :: {:ok, pid}
  def start(_, []) do
    nodes = [node()]
    case :mnesia.create_schema(nodes) do
      :ok ->
        :ok = :application.start(:mnesia)
        mnesia_init(nodes)
      {:error, {_, {:already_exists, _}}} ->
        :ok = :application.start(:mnesia)
        :ok = :mnesia.wait_for_tables([:mquotes, :mlastfm, :mscripts], 10000)
    end
    Mambo.Supervisor.start_link()
  end

  @doc """
  Stops the bot application.
  """
  @spec stop() :: :ok
  def stop() do
    :ok
  end

  # Helpers.

  defp mnesia_init(nodes) do
    {:atomic, :ok} = :mnesia.create_table(:mquotes, attributes: [:id, :content],
      disc_copies: nodes, type: :set)
    {:atomic, :ok} = :mnesia.create_table(:mlastfm, attributes: [:id, :username],
      disc_copies: nodes, type: :set)
    {:atomic, :ok} = :mnesia.create_table(:mscripts, attributes: [:key, :value],
      disc_copies: nodes, type: :set)
  end
end
