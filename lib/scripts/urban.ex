defmodule Urban do
  @moduledoc """
  Define terms via urban dictionary.

  Examples
    .ud <term>
    .urban <term>
  """

  use GenEvent

  def init(_) do
    {:ok, []}
  end

  def handle_event({:msg, {".help urban", _, {cid,_,_}}}, _) do
    Mambo.Bot.send_msg(<<?\n, @moduledoc>>, cid)
    {:ok, []}
  end

  def handle_event({:privmsg, {".help urban", _, {clid,_}}}, _) do
    Mambo.Bot.send_privmsg(<<?\n, @moduledoc>>, clid)
    {:ok, []}
  end

  def handle_event({:msg, {msg, _, {cid,_,_}}}, _) do
    answer = fn(x) -> Mambo.Bot.send_msg(x, cid) end
    spawn(fn -> parse_msg(msg, answer) end)
    {:ok, []}
  end

  def handle_event({:privmsg, {msg, _, {clid,_}}}, _) do
    answer = fn(x) -> Mambo.Bot.send_privmsg(x, clid) end
    spawn(fn -> parse_msg(msg, answer) end)
    {:ok, []}
  end

  def handle_event(_, _) do
    {:ok, []}
  end

  # Helpers

  defp parse_msg(msg, answer) do
    case Regex.run(~r/^(?:\.ud|\.urban) (.*)/i, msg) do
      [_, query] ->
        urban(query, answer)
      _ ->
        :ok
    end
  end

  defp urban(query, answer) do
    url = "http://api.urbandictionary.com/v0/define?term=#{URI.encode(query)}"
    case :hackney.get(url, [], <<>>, []) do
      {:ok, 200, _, client} ->
        {:ok, body} = :hackney.body(client)
        case :jsx.decode(body, [{:labels, :atom}])[:list] do
          [first|_] ->
            answer.("[b]Urban Dictionary:[/b] #{format(first[:definition])}.")
          [] ->
            answer.("[b]Urban Dictionary:[/b] No result.")
        end
      _ ->
        answer.("Something went wrong.")
    end
  end

  defp format(result) do
    result
      |> String.split(["\n","\r","\t","."], trim: true)
      |> Enum.map(&String.strip/1)
      |> Enum.filter(&(&1 != ""))
      |> Enum.join(". ")
  end
end
