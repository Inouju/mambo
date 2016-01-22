defmodule Admin do
  @moduledoc """
  Admin script.

  Examples
    .mute
    .unmute
    .gm <message>
    .rename <name>
  """

  use GenEvent

  def init(_) do
    {:ok, []}
  end

  def handle_event({:msg, {".help admin", _, {cid,_,_}}}, _) do
    Mambo.Bot.send_msg(<<?\n, @moduledoc>>, cid)
    {:ok, []}
  end

  def handle_event({:privmsg, {".help admin", _, {clid,_}}}, _) do
    Mambo.Bot.send_privmsg(<<?\n, @moduledoc>>, clid)
    {:ok, []}
  end

  def handle_event({:msg, {".mute", _, {cid,_,uid}}}, _) do
    if uid in Mambo.Bot.admins() do
      Mambo.Bot.mute(cid)
      Mambo.Bot.send_msg("Muted.", cid)
    end
    {:ok, []}
  end

  def handle_event({:msg, {".unmute", _, {cid,_,uid}}}, _) do
    if uid in Mambo.Bot.admins() do
      Mambo.Bot.unmute(cid)
      Mambo.Bot.send_msg("Unmuted.", cid)
    end
    {:ok, []}
  end

  def handle_event({type, {<<".gm ", msg :: binary>>, _, ids}}, _) do
    uid = case type do
      :msg -> elem(ids, 2)
      :privmsg -> elem(ids, 1)
    end
    if uid in Mambo.Bot.admins() do
      Mambo.Bot.send_gm(msg)
    end
    {:ok, []}
  end

  def handle_event({:msg, {<<".rename ", name :: binary>>, _, {cid,_,uid}}}, _) do
    if uid in Mambo.Bot.admins() do
      Mambo.Bot.rename(name, cid)
    end
    {:ok, []}
  end

  def handle_event(_, _) do
    {:ok, []}
  end
end
