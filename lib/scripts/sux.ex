defmodule Sux do
  @moduledoc """
  Curse something.

  Examples:
    .sux <word> | <phrase>
  """

  use GenEvent

  def init(_) do
    {:ok, []}
  end

  def handle_event({:msg, {".help sux", _, {cid,_,_}}}, _) do
    Mambo.Bot.send_msg(<<?\n, @moduledoc>>, cid)
    {:ok, []}
  end

  def handle_event({:privmsg, {".help sux", _, {clid,_}}}, _) do
    Mambo.Bot.send_privmsg(<<?\n, @moduledoc>>, clid)
    {:ok, []}
  end

  def handle_event({:msg, {<<".sux ", msg :: binary>>, _, {cid,_,_}}}, _) do
    msg |> sux |> Mambo.Bot.send_msg(cid)
    {:ok, []}
  end

  def handle_event(_, _) do
    {:ok, []}
  end

  # Helpers

  defp sux(what) do
    "fuck #{what}; #{what} sucks; #{what} is dying;" <>
    "#{what} is dead to me; #{what} hit wtc;"
  end
end
