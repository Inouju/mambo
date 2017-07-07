defmodule Google do
  @moduledoc """
  Search google and images.

  Examples:
    .g <phrase>
    .google <phrase>
    .img <phrase>
    .image <phrase>
    .images <phrase>
  """

  use GenEvent

  def init([key, cx]) do
    {:ok, [key, cx]}
  end

  def handle_event({:msg, {".help google", _, {cid,_,_}}}, [key, cx]) do
    Mambo.Bot.send_msg(<<?\n, @moduledoc>>, cid)
    {:ok, [key, cx]}
  end

  def handle_event({:privmsg, {".help google", _, {clid,_}}}, [key, cx]) do
    Mambo.Bot.send_privmsg(<<?\n, @moduledoc>>, clid)
    {:ok, [key, cx]}
  end

  def handle_event({:msg, {msg, _, {cid,_,_}}}, [key, cx]) do
    answer = fn(x) -> Mambo.Bot.send_msg(x, cid) end
    spawn(fn -> parse_msg(msg, key, cx, answer) end)
    {:ok, [key, cx]}
  end

  def handle_event({:privmsg, {msg, _, {clid,_}}}, [key, cx]) do
    answer = fn(x) -> Mambo.Bot.send_privmsg(x, clid) end
    spawn(fn -> parse_msg(msg, key, cx, answer) end)
    {:ok, [key, cx]}
  end

  def handle_event(_, [key, cx]) do
    {:ok, [key, cx]}
  end

  # Helpers

  defp parse_msg(msg, key, cx, answer) do
    case Regex.run(~r/^(\.g|\.google|\.img|\.image(?:s)?) (.*)/i, msg) do
      [_, <<".g", _ :: binary>>, query] ->
        url = "https://www.googleapis.com/customsearch/v1" <>
          "?q=#{URI.encode(query)}&cx=#{cx}&key=#{key}"
        google(url, answer)
      [_, <<".i", _ :: binary>>, query] ->
        url = "https://www.googleapis.com/customsearch/v1" <>
              "?q=#{URI.encode(query)}&searchType=image&cx=#{cx}&key=#{key}"
        google(url, answer)
      _ ->
        :ok
    end
  end

  defp google(url, answer) do
    case :hackney.get(url, [], <<>>, []) do
      {:ok, 200, _, client} ->
        {:ok, body} = :hackney.body(client)
        case :jsx.decode(body, [{:labels, :atom}])[:items] do
          nil ->
            answer.("[b]Google:[/b] No result.")
          r ->
            result = hd(r)[:link]
            answer.("[b]Google:[/b] #{Mambo.Helpers.format_url(result)}")
        end
      _ ->
        answer.("Something went wrong.")
    end
  end
end
