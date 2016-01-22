defmodule Doge do
  @moduledoc """
  Dogecoin prices.

  Examples:
    .doge
    .doge <amount>
  """

  @time_fmt "~4.10.0B-~2.10.0B-~2.10.0B ~2.10.0B:~2.10.0B:~2.10.0B"

  @url_doge_btc "http://data.bter.com/api/1/ticker/doge_btc"
  @url_btc_usd  "https://coinbase.com/api/v1/prices/sell"
  @url_usd_eur  "http://api.fixer.io/latest?base=USD"

  use GenEvent

  def init(_) do
    prices = update_prices({{{1970,1,1},{0,0,0}},nil})
    {:ok, prices}
  end

  def handle_event({:msg, {".help doge", _, {cid,_,_}}}, prices) do
    Mambo.Bot.send_msg(<<?\n, @moduledoc>>, cid)
    {:ok, prices}
  end

  def handle_event({:privmsg, {".help doge", _, {clid,_}}}, prices) do
    Mambo.Bot.send_privmsg(<<?\n, @moduledoc>>, clid)
    {:ok, prices}
  end

  def handle_event({:msg, {".doge", _, {cid,_,_}}}, prices) do
    prices = update_prices(prices)
    {:ok, resp} = calc_doge(prices)
    Mambo.Bot.send_msg(resp, cid)
    {:ok, prices}
  end

  def handle_event({:msg, {<<".doge ", n :: binary>>, _, {cid,_,_}}}, prices) do
    case Float.parse(n) do
      {num,_} ->
        prices = update_prices(prices)
        case calc_doge(prices, num) do
          {:ok, resp} ->
            Mambo.Bot.send_msg(resp, cid)
          {:error, reason} ->
            Mambo.Bot.send_msg(reason, cid)
        end
      _ ->
        Mambo.Bot.send_msg("Invalid argument.", cid)
    end
    {:ok, prices}
  end

  def handle_event({:privmsg, {".doge", _, {clid,_}}}, prices) do
    prices = update_prices(prices)
    {:ok, resp} = calc_doge(prices)
    Mambo.Bot.send_privmsg(resp, clid)
    {:ok, prices}
  end

  def handle_event({:privmsg, {<<".doge ", n :: binary>>, _, {clid,_}}}, prices) do
    case Float.parse(n) do
      {num,_} ->
        prices = update_prices(prices)
        case calc_doge(prices, num) do
          {:ok, resp} ->
            Mambo.Bot.send_privmsg(resp, clid)
          {:error, reason} ->
            Mambo.Bot.send_privmsg(reason, clid)
        end
      _ ->
        Mambo.Bot.send_privmsg("Invalid argument.", clid)
    end
    {:ok, prices}
  end

  def handle_event(_, prices) do
    {:ok, prices}
  end

  # Helpers

  defp calc_doge(p) do
    calc_doge(p, 1)
  end

  defp calc_doge({time, prices}, amount) when amount > 0 do
    {{y,m,d},{h,mi,s}} = time
    time_lst = :io_lib.format(@time_fmt, [y,m,d,h,mi,s])

    btc = to_currency(amount * prices[:btc], [decimals: 8, compact: true])
    usd = to_currency(amount * prices[:usd], [decimals: 8, compact: true])
    eur = to_currency(amount * prices[:eur], [decimals: 8, compact: true])

    str = """

    #{btc} [b]BTC[/b]
    #{usd} [b]USD[/b]
    #{eur} [b]EUR[/b]
    [i][b]Last update:[/b] #{time_lst}[/i]
    """

    {:ok, str}
  end

  defp calc_doge(_, _) do
    {:error, "Invalid amount."}
  end

  # Update the dogecoin price in BTC, USD and EUR only if the prices are older
  # than 5 minutes.
  defp update_prices(prices={old, _}) do
    now = :calendar.local_time()
    case :calendar.time_difference(old, now) do
      {0,{0,min,_}} when min < 5 ->
        prices
      _ ->
        try do
          rates = fetch_rates()
          btc = Float.round(rates[:doge_btc], 8)
          usd = Float.round(btc * rates[:btc_usd], 8)
          eur = Float.round(usd * rates[:usd_eur], 8)
          {now, [{:btc, btc}, {:usd, usd}, {:eur, eur}]}
        catch
          _ -> prices
        end
    end
  end

  defp fetch_rates() do
    pid = self()
    ref = make_ref()

    spawn(fn -> fetch_doge_btc(pid, ref) end)
    spawn(fn -> fetch_btc_usd(pid, ref) end)
    spawn(fn -> fetch_usd_eur(pid, ref) end)

    wait(ref, 0, [])
  end

  defp wait(_, 3, acc), do: acc
  defp wait(ref, count, acc) do
    receive do
      {:ok, ^ref, val} ->
        wait(ref, count + 1, [val|acc])
      {:error, ^ref} ->
        wait(ref, count + 1, acc)
      _ ->
        wait(ref, count, acc)
    after
      10000 ->
        wait(ref, count + 1, acc)
    end
  end

  defp fetch_doge_btc(pid, ref) do
    case :hackney.get(@url_doge_btc, [], <<>>, []) do
      {:ok, 200, _, client} ->
        {:ok, body} = :hackney.body(client)
        rate = :jsx.decode(body, [{:labels, :atom}])[:avg]
        send(pid, {:ok, ref, {:doge_btc, bin_to_num(rate)}})
      _ ->
        send(pid, {:ok, ref, {:doge_btc, 0}})
    end
  end

  defp fetch_btc_usd(pid, ref) do
    case :hackney.get(@url_btc_usd, [], <<>>, []) do
      {:ok, 200, _, client} ->
        {:ok, body} = :hackney.body(client)
        rate = :jsx.decode(body, [{:labels, :atom}])[:amount]
        send(pid, {:ok, ref, {:btc_usd, bin_to_num(rate)}})
      _ ->
        send(pid, {:ok, ref, {:btc_usd, 0}})
    end
  end

  defp fetch_usd_eur(pid, ref) do
    case :hackney.get(@url_usd_eur, [], <<>>, []) do
      {:ok, 200, _, client} ->
        {:ok, body} = :hackney.body(client)
        rate = :jsx.decode(body, [{:labels, :atom}])[:rates][:EUR]
        send(pid, {:ok, ref, {:usd_eur, rate}})
      _ ->
        send(pid, {:ok, ref, {:usd_eur, 0}})
    end
  end

  defp bin_to_num(bin) do
    case Float.parse(bin) do
      {num, _} -> num
      _ -> 0
    end
  end

  defp to_currency(num, opts) do
    num = Float.to_char_list(num, opts)
    partition(num)
  end

  defp partition(num) do
    case Enum.split_while(num, fn(x) -> x != ?. end) do
      {_, []} ->
        num
      {c, m} ->
        partition(Enum.reverse(c), m, [])
    end
  end

  defp partition([a,b,c,d|t], m, acc) do
    partition([d|t], m, [?,,c,b,a|acc])
  end

  defp partition(lst, m, acc) do
    Enum.reverse(lst) ++ acc ++ m
  end
end
