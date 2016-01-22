defmodule Youtube do
  @moduledoc """
  Search youtube videos.

  Examples:
    .yt <phrase>
    .youtube <phrase>
  """

  use GenEvent

  def init(key) do
    {:ok, key}
  end

  def handle_event({:msg, {".help youtube", _, {cid,_,_}}}, key) do
    Mambo.Bot.send_msg(<<?\n, @moduledoc>>, cid)
    {:ok, key}
  end

  def handle_event({:privmsg, {".help youtube", _, {clid,_}}}, key) do
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
    case Regex.run(~r/^(?:\.yt|\.youtube) (.*)/i, msg) do
      [_, query] ->
        youtube(query, key, answer)
      _ ->
        :ok
    end
  end

  defp youtube(query, key, answer) do
    url = "https://www.googleapis.com/youtube/v3/search?" <>
      URI.encode_query([q: query, key: key, part: "id"])
    case :hackney.get(url, [], <<>>, []) do
    {:ok, 200, _, client} ->
      {:ok, body} = :hackney.body(client)
      case :jsx.decode(body, [{:labels, :atom}])[:items] do
        [] ->
          answer.("[b]YouTube:[/b] No result.")
        videos ->
          case Enum.find(videos, fn(v) -> v[:id][:kind] == "youtube#video" end) do
            nil ->
              answer.("[b]YouTube:[/b] No result.")
            video ->
              v_url = "https://www.youtube.com/watch?v=#{video[:id][:videoId]}"
              answer.("[b]YouTube:[/b] #{Mambo.Helpers.format_url(v_url)}")
          end
      end
    _ ->
      answer.("Something went wrong.")
    end
  end
end
