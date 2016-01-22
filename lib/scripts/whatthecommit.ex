defmodule Whatthecommit do
  @moduledoc """
  Prints a commit from http://whatthecommit.com/.

  Examples:
    .wtc
  """

  use GenEvent

  def init(_) do
    {:ok, []}
  end

  def handle_event({:msg, {".help wtc", _, {cid,_,_}}}, _) do
    Mambo.Bot.send_msg(<<?\n, @moduledoc>>, cid)
    {:ok, []}
  end

  def handle_event({:privmsg, {".help wtc", _, {clid,_}}}, _) do
    Mambo.Bot.send_privmsg(<<?\n, @moduledoc>>, clid)
    {:ok, []}
  end

  def handle_event({:msg, {".wtc", _, {cid,_,_}}}, _) do
    answer = fn(x) -> Mambo.Bot.send_msg(x, cid) end
    spawn(fn -> wtc(answer) end)
    {:ok, []}
  end

  def handle_event({:privmsg, {".wtc", _, {clid,_}}}, _) do
    answer = fn(x) -> Mambo.Bot.send_privmsg(x, clid) end
    spawn(fn -> wtc(answer) end)
    {:ok, []}
  end

  def handle_event(_, _) do
    {:ok, []}
  end

  # Helpers

  defp wtc(answer) do
    url = "http://whatthecommit.com/index.txt"
    case :hackney.get(url, [], <<>>, []) do
      {:ok, 200, _, client} ->
        {:ok, body} = :hackney.body(client)
        answer.("#{String.strip(body)}")
      _ ->
        answer.("Something went wrong!")
    end
  end
end
