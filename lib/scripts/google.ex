defmodule Google do
  @moduledoc """
  Search google and images.

  Examples:
    .google <phrase>
    .images <phrase>
  """

  use GenEvent.Behaviour

  def init([]) do
    {:ok, []}
  end

  def handle_event({:msg, {".help google", _, {cid,_,_}}}, []) do
    Mambo.Bot.send_msg(<<?\n, @moduledoc>>, cid)
    {:ok, []}
  end

  def handle_event({:privmsg, {".help google", _, {clid,_}}}, []) do
    Mambo.Bot.send_privmsg(<<?\n, @moduledoc>>, clid)
    {:ok, []}
  end

  def handle_event({:msg, {msg, _, {cid,_,_}}}, []) do
    answer = fn(x) -> Mambo.Bot.send_msg(x, cid) end
    spawn(fn -> parse_msg(msg, answer) end)
    {:ok, []}
  end

  def handle_event({:privmsg, {msg, _, {clid,_}}}, []) do
    answer = fn(x) -> Mambo.Bot.send_privmsg(x, clid) end
    spawn(fn -> parse_msg(msg, answer) end)
    {:ok, []}
  end

  def handle_event(_, []) do
    {:ok, []}
  end

  # Helpers

  defp parse_msg(msg, answer) do
    case Regex.run(%r/^(\.g|\.google|\.img|\.image(?:s)?) (.*)/i, msg) do
      [_, <<".g", _ :: binary>>, query] ->
        url = "https://ajax.googleapis.com/ajax/services/search/" <>
          "web?safe=off&v=1.0&q=#{URI.encode(query)}"
        google(url, answer)
      [_, <<".i", _ :: binary>>, query] ->
        url = "http://ajax.googleapis.com/ajax/services/search/" <>
              "images?safe=off&v=1.0&q=#{URI.encode(query)}"
        google(url, answer)
      _ ->
        :ok
    end
  end

  defp google(url, answer) do
    case :hackney.get(url, [], <<>>, []) do
      {:ok, 200, _, client} ->
        {:ok, body, _} = :hackney.body(client)
        {:ok, data}  = JSEX.decode(body)
        rdata = data["responseData"]
        case rdata["results"] do
          [] ->
            answer.("[b]Google:[/b] No result.")
          [r | _] ->
            result = r["unescapedUrl"]
            spawn(Title, :get_title, [result, answer])
            answer.("[b]Google:[/b] #{Mambo.Helpers.format_url(result)}")
        end
      _ ->
        answer.("Something went wrong.")
    end
  end
end
