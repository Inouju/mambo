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

  @options [
    {:Admin, "admin"},
    {:Benis, "benis"},
    {:Brainfuck, "brainfuck"},
    {:Cannedreplies, "replies"},
    {:Doge, "doge"},
    {:Eightball, "8ball"},
    {:Gif, "gif"},
    {:Google, "google"},
    {:Lastfm, "np"},
    {:Private, "private"},
    {:Quotes, "quote"},
    {:Rainbow, "rainbow"},
    {:Random, "random"},
    {:Sux, "sux"},
    {:Title, "title"},
    {:Translate, "translate"},
    {:Twitter, "twitter"},
    {:Urban, "urban"},
    {:Utils, "utils"},
    {:Whatthecommit, "wtc"},
    {:Wolframalpha, "wolframalpha"},
    {:Youtube, "youtube"}
  ]

  def init(_) do
    {:ok, []}
  end

  def handle_event({:msg, {".help", _, {cid,_,_}}}, _) do
    options = Enum.map(Mambo.Bot.scripts(), &(@options[&1]))
      |> Enum.filter(&(&1 != nil))
    Mambo.Bot.send_msg("#{@helpmsg}#{Enum.join(options, " [b]|[/b] ")}", cid)
    {:ok, []}
  end

  def handle_event({:privmsg, {".help", _, {clid,_}}}, _) do
    IO.puts("Got to help.ex priv msg")
    options = Enum.map(Mambo.Bot.scripts(), &(@options[&1]))
      |> Enum.filter(&(&1 != nil))
    Mambo.Bot.send_privmsg("#{@helpmsg}#{Enum.join(options, " [b]|[/b] ")}", clid)
    {:ok, []}
  end

  def handle_event(_, _) do
    {:ok, []}
  end
end
