defmodule Wolframalpha do
  @moduledoc """
  I'm a mathemagician yo! Wolframalpha script.

  Examples
    .wa <expression>
    .calc <expression>
    .convert <expression> to <units>
  """

  use GenEvent

  def init(key) do
    {:ok, key}
  end

  def handle_event({:msg, {".help wolframalpha", _, {cid,_,_}}}, key) do
    Mambo.Bot.send_msg(<<?\n, @moduledoc>>, cid)
    {:ok, key}
  end

  def handle_event({:privmsg, {".help wolframalpha", _, {clid,_}}}, key) do
    Mambo.Bot.send_privmsg(<<?\n, @moduledoc>>, clid)
    {:ok, key}
  end

  def handle_event({:msg, {msg, _, {cid,_,_}}}, key) do
    answer = fn(x) -> Mambo.Bot.send_msg(x, cid) end
    spawn(fn -> parse_msg(msg, key, answer) end)
    {:ok, key}
  end

  def handle_event({:privmsg, {msg, _, {clid,_}}}, key) do
    answer = fn(x) -> Mambo.Bot.send_privmsg(x, clid) end
    spawn(fn -> parse_msg(msg, key, answer) end)
    {:ok, key}
  end

  def handle_event(_, key) do
    {:ok, key}
  end

  # Helpers

  defp parse_msg(msg, key, answer) do
    case Regex.run(~r/^(?:\.wa|\.calc|\.convert) (.*)/i, msg) do
      [_, query] ->
        wolframalpha(query, key, answer)
      _ ->
        :ok
    end
  end

  defp wolframalpha(query, key, answer) do
    url = "http://api.wolframalpha.com/v2/query?" <>
      URI.encode_query([input: query, appid: key, podindex: 2, format: "plaintext"])

    case :hackney.get(url, [], <<>>, []) do
      {:ok, 200, _, client} ->
        {:ok, body} = :hackney.body(client)
        case parse_resp(body) do
          {:done, _, result, _, _} ->
            answer.("[b]Wolfram|Alpha:[/b] #{format(result)}")
          {:no_result, _, result, _, _} ->
            answer.("[b]Wolfram|Alpha:[/b] #{result}")
        end
      _ ->
        answer.("Something went wrong.")
    end
  end

  defp parse_resp(xml) do
    :xmerl_sax_parser.stream(xml, event_fun: &event/3, event_state: "")
  end

  defp event({:startElement, _, 'queryresult', _, [h | _]}, _, state) do
    if elem(h, 3) == 'true' do
      state
    else
      throw {:no_result, "No result."}
    end
  end

  defp event({:characters, chars}, _, _) do
    chars
  end

  defp event({:endElement, _, 'plaintext', _}, _, state) do
    case to_string(state) do
      "" -> throw {:no_result, "No result."}
      result -> throw {:done, result}
    end
  end

  defp event(_, _, state) do
    state
  end

  defp format(result) do
    result
      |> String.replace(" \n ", " ")
      |> String.replace(" | ", ": ")
      |> String.replace("  ", " ")
      |> String.split("\n")
      |> Enum.join(" | ")
  end
end
