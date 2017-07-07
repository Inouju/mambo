defmodule Eightball do
  @moduledoc """
  Ask the magic 8 ball.

  Examples:
    .8ball <question>
  """

  use GenEvent

   @options ["It is certain.", "It is decidedly so.", "Without a doubt.",
     "Yes, definitely.", "You may rely on it.", "As I see it, yes.",
     "Most likely.", "Outlook good.", "Yes.", "Signs point to yes.",
     "Reply hazy, try again.", "Ask again later.", "Better not tell you now.",
     "Cannot predict now.", "Concentrate and ask again.",
     "Don't count on it.", "My reply is no.", "My sources say no.",
     "Outlook not so good.", "Very doubtful."]

  def init(_) do
    {:ok, []}
  end

  def handle_event({:msg, {".help eightball", _, {cid,_,_}}}, _) do
    Mambo.Bot.send_msg(<<?\n, @moduledoc>>, cid)
    {:ok, []}
  end

  def handle_event({:msg, {".help 8ball", _, {cid,_,_}}}, _) do
    Mambo.Bot.send_msg(<<?\n, @moduledoc>>, cid)
    {:ok, []}
  end

  def handle_event({:privmsg, {".help eightball", _, {clid,_}}}, _) do
    Mambo.Bot.send_privmsg(<<?\n, @moduledoc>>, clid)
    {:ok, []}
  end

  def handle_event({:privmsg, {".help 8ball", _, {clid,_}}}, _) do
    Mambo.Bot.send_privmsg(<<?\n, @moduledoc>>, clid)
    {:ok, []}
  end

  def handle_event({:msg, {<<".8ball ", _ :: binary>>, _, {cid,_,_}}}, _) do
    Mambo.Bot.send_msg(shake, cid)
    {:ok, []}
  end

  def handle_event({:privmsg, {<<".8ball ", _ :: binary>>, _, {clid,_}}}, _) do
    Mambo.Bot.send_privmsg(shake, clid)
    {:ok, []}
  end

  def handle_event(_, _) do
    {:ok, []}
  end

  # Helpers

  defp shake() do
    :random.seed(:os.timestamp)
    Enum.random(@options)
  end
end
