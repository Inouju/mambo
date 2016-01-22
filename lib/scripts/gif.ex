defmodule Gif do
  @moduledoc """
  Crush gifs with the force of a thousand suns.

  Resizes a gif to the maximum teamspeak size, 300x300, and also converts it to
  a video using the [url]https://mediacru.sh/[/url] api.

  Examples
    .gif <gif_link>
  """

  use GenEvent

  def init(_) do
    {:ok, []}
  end

  def handle_event({:msg, {".help gif", _, {cid,_,_}}}, _) do
    Mambo.Bot.send_msg(<<?\n, @moduledoc>>, cid)
    {:ok, []}
  end

  def handle_event({:privmsg, {".help gif", _, {clid,_}}}, _) do
    Mambo.Bot.send_privmsg(<<?\n, @moduledoc>>, clid)
    {:ok, []}
  end

  def handle_event({:msg, {<<".gif ", msg :: binary>>, name, {cid,_,_}}}, _) do
    answer = fn(x) -> Mambo.Bot.send_msg(x, cid) end
    case Mambo.Helpers.get_url(msg) do
      nil ->
        answer.("What the fuck do you want dude?")
        {:ok, []}
      url ->
        spawn(fn -> crush(url, name, answer) end)
        {:ok, []}
    end
  end

  def handle_event({:privmsg, {<<".gif ", msg :: binary>>, name, {clid,_}}}, _) do
    answer = fn(x) -> Mambo.Bot.send_privmsg(x, clid) end
    case Mambo.Helpers.get_url(msg) do
      nil ->
        answer.("What the fuck do you want dude?")
        {:ok, []}
      url ->
        spawn(fn -> crush(url, name, answer) end)
        {:ok, []}
    end
  end

  def handle_event(_, _) do
    {:ok, []}
  end

  # Helpers.

  defp crush(url, name, answer) do
    case download_gif(url) do
      {:ok, {dir, gif}} ->
        answer.("[b]Gif:[/b] This might take a while, hang in there.")

        case resize(dir, gif) do
          {:ok, new} ->
            answer.(format_response(name, pupload(url, new)))
          :right_size ->
            original = upload_url(url)
            answer.(format_response(name, [original, original]))
          :error ->
            original = upload_url(url)
            answer.(format_response(name, [original, :error]))
        end
        File.rm_rf(dir)

      {:error, reason} ->
        answer.(reason)
    end
  end

  defp download_gif(url) do
    temp_dir = "tmp/#{:erlang.phash2(make_ref())}"
    File.mkdir_p!(temp_dir)
    case :hackney.get(url, [], <<>>, []) do
      {:ok, 200, headers, client} ->
        headers = for {m, a} <- headers, do: {String.to_atom(m),a}
        if headers[:"Content-Type"] == "image/gif" do
          {:ok, bin} = :hackney.body(client)
          path = Path.join([temp_dir, "original.gif"])
          File.write!(path, bin)
          {:ok, {temp_dir, path}}
        else
          {:error, "[b]Gif:[/b] Hey smartass that's not a gif."}
        end
      _ ->
        File.rm_rf(temp_dir)
        {:error, "[b]Gif:[/b] Download failed."}
    end
  end

  defp resize(dir, gif) do
    out = Path.join([dir, "ts.gif"])
    tmp = Path.join([dir, "#{:erlang.phash2(make_ref())}.gif"])

    case get_size(gif) do
      {w,h} when w > 290 and w <= 300 and h <= 300 -> :right_size
      {w,h} when h > 290 and h <= 300 and w <= 300 -> :right_size
      _ ->
        System.cmd("convert", ["#{gif} -coalesce #{tmp}"])
        System.cmd("convert", ["#{tmp} -resize 300x300 #{out}"])
        if File.exists?(out), do: {:ok, out}, else: :error
    end
  end

  defp upload_file(path) do
    url = "https://mediacru.sh/api/upload/file"

    case :hackney.post(url, [], {:multipart, [{:file,path}]}, []) do
      {:ok, status, _, client} when status in [200,409] ->
        {:ok, body} = :hackney.body(client)
        hash = :jsx.decode(body, [{:labels, :atom}])[:hash]
        {:ok, [{"gif","https://mediacru.sh/#{hash}.gif"}]}
      _ ->
        :error
    end
  end

  defp upload_url(gifurl) do
    url = "https://mediacru.sh/api/upload/url"
    case :hackney.post(url, [], {:form, [{"url",gifurl}]}, []) do
      {:ok, status, _, client} when status in [200,409] ->
        {:ok, body} = :hackney.body(client)
        hash = :jsx.decode(body, [{:labels, :atom}])[:hash]
        urls = Enum.map(["gif","mp4","ogv","webm"], fn(ext) ->
          {ext,"https://mediacru.sh/#{hash}.#{ext}"}
        end)
        {:ok, urls}
      _ ->
        :error
    end
  end

  defp pupload(url, file) do
    pid = self()
    ref = make_ref()
    pids = [spawn(fn -> do_fun(pid, ref, &upload_url/1, url) end),
            spawn(fn -> do_fun(pid, ref, &upload_file/1, file) end)]
    gather(pids, ref, [])
  end

  defp do_fun(pid, ref, fun, arg) do
    send(pid, {self(), ref, fun.(arg)})
  end

  defp gather([pid|t], ref, acc) do
    receive do
      {^pid, ^ref, result} -> gather(t, ref, [result | acc])
      _ -> acc
    end
  end
  defp gather([], _, acc), do: Enum.reverse(acc)

  defp get_size(gif) do
    bin = File.read!(gif)
    <<?G,?I,?F,?8,_,?a,
      w :: little - size(16),
      h :: little - size(16),
      _ :: binary>> = bin
    {w,h}
  end

  defp format_response(name, urls) do
    s = "[b]Gif: #{name}:[/b] "

    case urls do
      [{:ok, original},{:ok,ts}] ->
        <<s :: binary,
          "[url=#{original["gif"]}][original][/url] ",
          "[url=#{original["mp4"]}][mp4][/url] ",
          "[url=#{original["ogv"]}][ogv][/url] ",
          "[url=#{original["webm"]}][webm][/url] ",
          "[url=#{ts["gif"]}][teamspeak][/url]">>

      [{:ok, original},:error] ->
        <<s :: binary,
          "[url=#{original["gif"]}][original][/url] ",
          "[url=#{original["mp4"]}][mp4][/url] ",
          "[url=#{original["ogv"]}][ogv][/url] ",
          "[url=#{original["webm"]}][webm][/url]">>

      [:error,{:ok,ts}] ->
        s <> "[url=#{ts["gif"]}][teamspeak][/url]"

      [:error,:error] ->
        "[b]Gif:[/b] Upload failed."
    end
  end
end
