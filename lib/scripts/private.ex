defmodule Private do
  @moduledoc """
  Starts a private chat with mambo.

  Examples:
    .private
  """

  use GenEvent

  def init(_) do
    {:ok, []}
  end

  def handle_event({:msg, {".help private", _, {cid,_,_}}}, _) do
    Mambo.Bot.send_msg(<<?\n, @moduledoc>>, cid)
    {:ok, []}
  end

  def handle_event({:privmsg, {".help private", _, {clid,_}}}, _) do
    Mambo.Bot.send_privmsg(<<?\n, @moduledoc>>, clid)
    {:ok, []}
  end

  def handle_event({:msg, {".private", _, {_,clid,_}}}, _) do
    Mambo.Bot.send_privmsg("Hello.", clid)
    {:ok, []}
  end

  def handle_event(_, _) do
    {:ok, []}
  end
end
