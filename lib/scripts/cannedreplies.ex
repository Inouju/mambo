defmodule Cannedreplies do
  @moduledoc """
  Mambo replies when certain keywords are written in the chat.

  Examples:
    cool
    gface
    goface
    edgyface
    dface
    ggface
    chownface
  """

  use GenEvent

  @responses Map.new [{"gface", "( ≖‿≖)"},
              {"cool", "COOL LIKE SNOWMAN ☃"},
              {"chownface", "( ´· ‿ ·`)"},
              {"goface", "ʕ ◔ϖ◔ʔ"},
              {"edgyface", "(ケ≖‿≖)ケ"},
              {"dface", "ಠ_ಠ"},
              {"ggface", "G_G"},
              {"kawaiiface", "(◕.◕✿)"},
              {"shrug", "¯\\_(ツ)_/¯"},
              {".shrug", "¯\\_(ツ)_/¯"}
            ]

  def init(_) do
    {:ok, []}
  end

  def handle_event({:msg, {".help cannedreplies", _, {cid,_,_}}}, _) do
    Mambo.Bot.send_msg(<<?\n, @moduledoc>>, cid)
    {:ok, []}
  end

  def handle_event({:msg, {".help replies", _, {cid,_,_}}}, _) do
    Mambo.Bot.send_msg(<<?\n, @moduledoc>>, cid)
    {:ok, []}
  end

  def handle_event({:privmsg, {".help cannedreplies", _, {clid,_}}}, _) do
    Mambo.Bot.send_privmsg(<<?\n, @moduledoc>>, clid)
    {:ok, []}
  end

  def handle_event({:privmsg, {".help replies", _, {clid,_}}}, _) do
    Mambo.Bot.send_privmsg(<<?\n, @moduledoc>>, clid)
    {:ok, []}
  end

  def handle_event({:msg, {msg, _, {cid,_,_}}}, _) do
    case Map.get(@responses, msg) do
      nil ->
        {:ok, []}
      reply ->
        Mambo.Bot.send_msg(reply, cid)
        {:ok, []}
    end
  end

  def handle_event(_, _) do
    {:ok, []}
  end
end
