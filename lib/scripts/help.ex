defmodule Help do
  @moduledoc """
  Shows mambo help message.

  Examples:
    .help
  """

  use GenEvent

  @helpmsg """

  Mambo is an extensible irc-style teamspeak 3 bot.
  See '.help <option>' for more information on a specific script.

  Options:
  """
  
  def init(_) do
    {:ok, []}
  end

  def handle_event({:msg, {".help help", _, {cid,_,_}}}, _) do
    Mambo.Bot.send_msg(<<?\n, @moduledoc>>, cid)
    {:ok, []}
  end

  def handle_event({:msg, {".help", _, {cid,_,_}}}, _) do
    options = Enum.map(Mambo.Bot.scripts(), fn(x) ->
      String.downcase(Atom.to_string(x)) end)
    Mambo.Bot.send_msg("#{@helpmsg}#{Enum.join(options, " [b]|[/b] ")}", cid)
    {:ok, []}
  end

  def handle_event({:privmsg, {".help help", _, {clid,_}}}, _) do
    Mambo.Bot.send_privmsg(<<?\n, @moduledoc>>, clid)
    {:ok, []}
  end

  def handle_event({:privmsg, {".help", _, {clid,_}}}, _) do
    options = Enum.map(Mambo.Bot.scripts(), fn(x) ->
      String.downcase(Atom.to_string(x)) end)
    Mambo.Bot.send_privmsg("#{@helpmsg}#{Enum.join(options, " [b]|[/b] ")}", clid)
    {:ok, []}
  end

  def handle_event(_, _) do
    {:ok, []}
  end
end
