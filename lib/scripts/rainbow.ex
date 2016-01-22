defmodule Rainbow do
  @moduledoc """
  Rainbow color a phrase.

  Examples:
    .r <phrase>
    .rainbow <phrase>
  """

  use GenEvent

  @colors ["#FF0000",
           "#FF8000",
           "#EAB700",
           "#008000",
           "#0000FF",
           "#4B0082",
           "#9400D3"]

  def init(_) do
    {:ok, []}
  end

  def handle_event({:msg, {".help rainbow", _, {cid,_,_}}}, _) do
    Mambo.Bot.send_msg(<<?\n, @moduledoc>>, cid)
    {:ok, []}
  end

  def handle_event({:privmsg, {".help rainbow", _, {clid,_}}}, _) do
    Mambo.Bot.send_privmsg(<<?\n, @moduledoc>>, clid)
    {:ok, []}
  end

  def handle_event({:msg, {<<".r ", msg :: binary>>, _, {cid,_,_}}}, _) do
    msg |> rainbow |> Mambo.Bot.send_msg(cid)
    {:ok, []}
  end

  def handle_event({:msg, {<<".rainbow ", msg :: binary>>, _, {cid,_,_}}}, _) do
    msg |> rainbow |> Mambo.Bot.send_msg(cid)
    {:ok, []}
  end

  def handle_event({:msg, {<<".gay ", msg :: binary>>, _, {cid,_,_}}}, _) do
    msg |> rainbow |> Mambo.Bot.send_msg(cid)
    {:ok, []}
  end

  def handle_event(_, _) do
    {:ok, []}
  end

  # Helpers

  defp rainbow(s) do
    rainbow(String.codepoints(s), @colors, [])
  end

  defp rainbow([], _, acc) do
    "#{Enum.reverse(acc)}"
  end

  defp rainbow(text, [], acc) do
    rainbow(text, @colors, acc)
  end

  defp rainbow([" " | rest], colors, acc) do
    rainbow(rest, colors, [" " | acc])
  end

  defp rainbow([h | rest], [c | nc], acc) do
    rainbow(rest, nc, [format(c, h) | acc])
  end

  defp format(color, text) do
    "[color=#{color}]#{text}[/color]"
  end
end
