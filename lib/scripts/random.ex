defmodule Random do
  @moduledoc """
  Luck games.

  Examples:
    .roll
    .rock
    .paper
    .scissors
  """

  use GenEvent

  def init(_) do
    {:ok, []}
  end

  def handle_event({:msg, {".help random", _, {cid,_,_}}}, _) do
    Mambo.Bot.send_msg(<<?\n, @moduledoc>>, cid)
    {:ok, []}
  end

  def handle_event({:privmsg, {".help random", _, {clid,_}}}, _) do
    Mambo.Bot.send_privmsg(<<?\n, @moduledoc>>, clid)
    {:ok, []}
  end

  def handle_event({:msg, {".roll", _, {cid,_,_}}}, _) do
    Mambo.Bot.send_msg(roll, cid)
    {:ok, []}
  end

  def handle_event({:privmsg, {".roll", _, {clid,_}}}, _) do
    Mambo.Bot.send_privmsg(roll, clid)
    {:ok, []}
  end

  def handle_event({:msg, {".rock", _, {cid,_,_}}}, _) do
    rps("rock", attack) |> Mambo.Bot.send_msg(cid)
    {:ok, []}
  end

  def handle_event({:privmsg, {".rock", _, {clid,_}}}, _) do
    rps("rock", attack) |> Mambo.Bot.send_privmsg(clid)
    {:ok, []}
  end

  def handle_event({:msg, {".paper", _, {cid,_,_}}}, _) do
    rps("paper", attack) |> Mambo.Bot.send_msg(cid)
    {:ok, []}
  end

  def handle_event({:privmsg, {".paper", _, {clid,_}}}, _) do
    rps("paper", attack) |> Mambo.Bot.send_privmsg(clid)
    {:ok, []}
  end

  def handle_event({:msg, {".scissors", _, {cid,_,_}}}, _) do
    rps("scissors", attack) |> Mambo.Bot.send_msg(cid)
    {:ok, []}
  end

  def handle_event({:privmsg, {".scissors", _, {clid,_}}}, _) do
    rps("scissors", attack) |> Mambo.Bot.send_privmsg(clid)
    {:ok, []}
  end

  def handle_event(_, _) do
    {:ok, []}
  end

  # Helpers

  defp roll() do
    :random.seed(:os.timestamp())
    Integer.to_string(:random.uniform(100))
  end

  defp rps(p1, p2) do
    case winner({p1, p2}) do
      :win  -> "I choose #{p2}. You win!"
      :draw -> "I choose #{p2}. It's a draw."
      :lose -> "I choose #{p2}. I WIN!"
    end
  end

  defp winner(moves) do
    case moves do
      {"rock", "scissors"} -> :win
      {"paper", "rock"} -> :win
      {"scissors", "paper"} -> :win
      {same, same} -> :draw
      {_, _} -> :lose
    end
  end

  defp attack() do
    :random.seed(:erlang.timestamp())
    Enum.at(["rock", "paper", "scissors"], :random.uniform(3) - 1)
  end
end
