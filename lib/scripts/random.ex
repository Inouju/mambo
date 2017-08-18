defmodule Random do
  @moduledoc """
  Luck games.

  Examples:
    .roll
    .roll <max number>
    .roll 2d6+11 - rolls 2 6-sided die and adds 11
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

  def handle_event({:msg, {<<".roll", dice :: binary>>, _, {cid,_,_}}}, _) do
    handle_roll(dice) |> Mambo.Bot.send_msg(cid)
    {:ok, []}
  end

  def handle_event({:privmsg, {<<".roll", dice :: binary>>,  _, {clid,_}}}, _) do
    handle_roll(dice) |> Mambo.Bot.send_privmsg(clid)
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

  defp handle_roll(dice) do
    dice = String.replace(dice, " ", "")
    case String.split(dice, "d", trim: true) do
      [d, s] ->
      	case Integer.parse(d) do
          {dnum, _} ->
      	    case Integer.parse(s) do
              {snum, ""} ->
                roll_s(dnum, dnum * snum)
              {snum, mod} ->
                roll_s(dnum, dnum * snum, parse_mods(mod))
              :error ->
                "Please use an integer."
            end
          :error ->
            "Please use an integer."
        end
      [d] ->
      	case Integer.parse(d) do
          {num, _} ->
            roll_s(1, num)
          :error ->
            "Please use an integer."
        end
      [] ->
        roll_s(1, 100)
    end
  end

  defp parse_mods(mods) do
    sign = 1
    if String.starts_with?(mods, "-") do
      sign = -1
    end
    next_num = String.slice(mods, 1..String.length(mods))
    case Integer.parse(next_num) do
      {num, ""} ->
        num * sign
      {num, _} ->
        (num * sign) + parse_mods(String.slice(next_num, 1..String.length(next_num)))
      :error ->
        0
    end
  end

  defp roll(min, max) do
    min = abs(min)
    max = abs(max)
    if min > :math.pow(10, 256) do
      min = :math.pow(10, 256)
    end    
    if max > :math.pow(10, 256) do
      max = :math.pow(10, 256)
    end    
    :rand.uniform * (max - min + 1) + min |> trunc
  end

  defp roll_s(min, max, mod) do
    roll(min, max) + mod |> Integer.to_string
  end

  defp roll_s(min, max) do
    roll(min, max) |> Integer.to_string
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
    Enum.at(["rock", "paper", "scissors"], :rand.uniform(3) - 1)
  end
end
