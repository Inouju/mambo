defmodule Mambo.Bot do
  @moduledoc """
  Responsible for connecting to the teamspeak server, also acts as a bridge
  between the teamspeak server and the plugins. Supervised by `Mambo.Supervisor`.
  """
  
  require Record
  use GenServer
  @bot __MODULE__

  @notify_msg "notifytextmessage"

  Record.defrecord :settings, [
    name:     "mambo",
    user:     "username",
    pass:     "password",
    host:     "localhost",
    port:     10011,
    bot_id:   "",
    admins:   [],
    channels: [],
    scripts:  [],
    default_channel: 1
  ]

  # API.

  @spec start_link() :: {:ok, pid}
  def start_link() do
    s = Mambo.Helpers.get_settings()
    s = settings(s)
    {:ok, _} = :gen_server.start_link({:local, @bot}, __MODULE__, s, [])
  end

  @doc """
  Returns the bot id.
  """
  @spec id() :: String.t
  def id() do
    :gen_server.call(@bot, :id)
  end

  @doc """
  Returns a list of the bot admins uid.
  """
  @spec admins() :: [String.t]
  def admins() do
    :gen_server.call(@bot, :admins)
  end

  @doc """
  Returns a list of the bot scripts.
  """
  @spec scripts() :: [atom()]
  def scripts() do
    :gen_server.call(@bot, :scripts)
  end

  @doc """
  Sends a chat message to the teamspeak server.
  """
  @spec send_msg(String.t, integer) :: :ok
  def send_msg(msg, cid) do
    :gen_server.cast(@bot, {:send_msg, {msg, cid}})
  end

  @doc """
  Sends a private message to the teamspeak client with the id `cid`.
  """
  @spec send_privmsg(String.t, integer) :: :ok
  def send_privmsg(msg, cid) do
    :gen_server.cast(@bot, {:send_privmsg, {msg, cid}})
  end

  @doc """
  Sends a global chat message to the teamspeak server.
  """
  @spec send_gm(String.t) :: :ok
  def send_gm(msg) do
    :gen_server.cast(@bot, {:send_gm, msg})
  end

  @doc """
  Kick a client from the teamspeak server.
  """
  @spec kick(integer, String.t) :: :ok
  def kick(cid, msg \\ "Smells bad!") do
    :gen_server.cast(@bot, {:kick, {cid, msg}})
  end

  @doc """
  Bans a client from the teamspeak server.
  """
  @spec ban(integer, integer, String.t) :: :ok
  def ban(cid, time, msg \\ "Smells bad!") do
    :gen_server.cast(@bot, {:ban, {cid, time, msg}})
  end

  @doc """
  Move the clients with id `clid` to the channel with id `cid`.
  """
  @spec move(integer | [integer], integer) :: :ok
  def move(clids, cid) when is_list(clids) do
    :gen_server.cast(@bot, {:move, {clids, cid, ""}})
  end
  def move(clid, cid) do
    :gen_server.cast(@bot, {:move, {[clid], cid, ""}})
  end

  @doc """
  Move the clients with id `clid` to the channel with id `cid` protected
  with a password.
  """
  @spec move(integer | [integer], integer, String.t) :: :ok
  def move(clids, cid, password) when is_list(clids) do
    :gen_server.cast(@bot, {:move, {clids, cid, password}})
  end
  def move(clid, cid, password) do
    :gen_server.cast(@bot, {:move, {[clid], cid, password}})
  end

  @doc """
  Mutes the watcher process in the channel with id `cid`.
  """
  @spec mute(integer) :: :ok
  def mute(cid) do
    :gen_server.cast(@bot, {:mute, cid})
  end

  @doc """
  Unmutes the watcher process in the channel with id `cid`.
  """
  @spec unmute(integer) :: :ok
  def unmute(cid) do
    :gen_server.cast(@bot, {:unmute, cid})
  end

  @doc """
  Renames the watcher process in the channel with id `cid`.
  """
  @spec rename(String.t, integer) :: :ok
  def rename(name, cid) do
    :gen_server.cast(@bot, {:rename, {name, cid}})
  end

  @doc """
  Creates a watcher process in the channel `cid`.
  """
  @spec add_watcher(integer()) :: :ok
  def add_watcher(cid) do
    :gen_server.cast(@bot, {:add_watcher, cid})
  end

  @doc """
  Terminates a watcher process in the channel `cid`.
  """
  @spec remove_watcher(integer()) :: :ok
  def remove_watcher(cid) do
    :gen_server.cast(@bot, {:remove_watcher, cid})
  end

  # Helpers.

  defp send_to_server(socket, msg) do
    :ok = :gen_tcp.send(socket, "#{msg}\n")
  end

  defp login(socket, name, user, pass) do
    ["login #{user} #{pass}", "use sid=1",
     "servernotifyregister event=textprivate",
     "clientupdate client_nickname=#{Mambo.Helpers.escape(name)}",
     "channellist -flags"]
    |> Enum.each(fn(x) -> send_to_server(socket, x) end)
  end

  defp parse_channellist(channellist) do
    String.split(channellist, "|")
      |> Enum.map(&Regex.run(~r/cid=(\d*).*?channel_flag_default=([0-1])/, &1))
      |> Enum.map_reduce(1, fn
        ([_,id,"0"], dc) -> {String.to_integer(id), dc}
        ([_,id,"1"], _) -> id = String.to_integer(id); {id, id}
        (_, _) -> {[], 1}
      end)
  end

  defp add_watchers(ids, s) do
    start_watcher = fn(id, count) ->
      {:ok, pid} = Mambo.WatcherSup.add_watcher([{id, s[:default_channel], s[:bot_id],
        {"#{s[:name]}_#{count}", s[:host], s[:port], s[:user], s[:pass]}}])
      pid
    end

    {watchers, _} = case s[:channels] do
      "all" ->
        Enum.map_reduce(ids, 0, fn(id, count) ->
          {{id, start_watcher.(id, Mambo.Helpers.get_extra(count))}, count + 1}
        end)
      l when is_list(l) ->
        Enum.map_reduce(l, 0, fn(id, count) ->
          if id in ids do
            {{id, start_watcher.(id, Mambo.Helpers.get_extra(count))}, count + 1}
          else
            {nil, count}
          end
        end)
      _ ->
        []
    end

    watchers
  end

  # gen_sever callbacks.

  def init(s) do
    case :gen_tcp.connect(String.to_char_list(s[:host]), s[:port], [:binary]) do
      {:ok, socket} ->
        for {m, a} <- s[:scripts], do: Mambo.EventManager.install_script(String.to_atom("Elixir.#{m}"), a)
        :ok = login(socket, s[:name], s[:user], s[:pass])
        :erlang.send_after(300000, self(), :keep_alive)
        {:ok, {socket, s, [], ""}}
      _ ->
        IO.puts("Could not connect to server.")
    end
  end

  def handle_call(:id, _, {_, s, _} = state) do
    {:reply, s[:bot_id], state}
  end

  def handle_call(:admins, _, {_, s, _} = state) do
    {:reply, s[:admins], state}
  end

  def handle_call(:scripts, _, {_, s, _} = state) do
    scripts = Enum.map(s[:scripts], fn({name,_}) -> name end)
    {:reply, scripts, state}
  end

  def handle_call(_, _, state) do
    {:noreply, state}
  end

  def handle_cast({:send_msg, {msg, cid}}, {socket, s, watchers} = state) do
    if cid === s[:default_channel] do
      cmd = "sendtextmessage targetmode=2 target=1 msg=#{Mambo.Helpers.escape(msg)}"
      send_to_server(socket, cmd)
      {:noreply, state}
    else
      :gen_server.cast(elem(List.keyfind(watchers, cid, 0),1), {:send_msg, msg})
      {:noreply, state}
    end
  end

  def handle_cast({:send_privmsg, {msg, cid}}, {socket, _, _} = state) do
    cmd = "sendtextmessage targetmode=1 target=#{cid} msg=#{Mambo.Helpers.escape(msg)}"
    :ok = send_to_server(socket, cmd)
    {:noreply, state}
  end

  def handle_cast({:send_gm, msg}, {socket, s, watchers} = state) do
    msg = "[b][color=#AA0000][GM] #{msg}[/color][/b]"
    cmd = "sendtextmessage targetmode=2 target=1 msg=#{Mambo.Helpers.escape(msg)}"
    Enum.each(watchers, fn({cid,pid}) ->
      if cid === s[:default_channel] do
        send_to_server(socket, cmd)
      else
        :gen_server.cast(pid, {:send_msg, msg})
      end
    end)
    :ok = send_to_server(socket, "gm msg=#{Mambo.Helpers.escape(msg)}")
    {:noreply, state}
  end

  def handle_cast({:kick, {cid, msg}}, {socket, _, _} = state) do
    cmd = "clientkick clid=#{cid} reasonid=5 reasonmsg=#{Mambo.Helpers.escape(msg)}"
    :ok = send_to_server(socket, cmd)
    {:noreply, state}
  end

  def handle_cast({:ban, {cid, time, msg}}, {socket, _, _} = state) do
    cmd = "banclient clid=#{cid} time=#{time} reasonmsg=#{Mambo.Helpers.escape(msg)}"
    :ok = send_to_server(socket, cmd)
    {:noreply, state}
  end

  def handle_cast({:move, {clids, cid, password}}, {socket, _, _} = state) do
    clients = Enum.map(clids, fn(clid) -> "clid=#{clid}" end) |> Enum.join("|")
    cmd = "clientmove #{clients} cid=#{cid} cpw=#{password}"
    :ok = send_to_server(socket, cmd)
    {:noreply, state}
  end

  def handle_cast({:mute, cid}, {_, _, watchers} = state) do
    :gen_server.cast(elem(List.keyfind(watchers, cid, 0),1), :mute)
    {:noreply, state}
  end

  def handle_cast({:unmute, cid}, {_, _, watchers} = state) do
    :gen_server.cast(elem(List.keyfind(watchers, cid, 0),1), :unmute)
    {:noreply, state}
  end

  def handle_cast({:rename, {name, cid}}, {socket, s, watchers} = state) do
    if cid === s[:default_channel] do
      cmd = "clientupdate client_nickname=#{Mambo.Helpers.escape(name)}"
      send_to_server(socket, cmd)
      {:noreply, state}
    else
      :gen_server.cast(elem(List.keyfind(watchers, cid, 0),1), {:rename, name})
      {:noreply, state}
    end
  end

  def handle_cast({:add_watcher, cid}, {socket, s, watchers}) do
    num = length(watchers) + 1
    args = [{cid, s[:bot_id], {"#{s[:name]}_#{num}", s[:host], s[:port], s[:user], s[:pass]}}]
    {:ok, pid} = Mambo.WatcherSup.add_watcher(args)
    {:noreply, {socket, s, Dict.put_new(watchers, cid, pid)}}
  end

  def handle_cast({:remove_watcher, cid}, {socket, s, watchers}) do
    :ok = Mambo.WatcherSup.remove_watcher(watchers[cid])
    {:noreply, {socket, s, Dict.delete(watchers, cid)}}
  end

  def handle_cast(_, state) do
    {:noreply, state}
  end

  def handle_info({:tcp, _, <<@notify_msg, r :: binary>>}, {_, s, _} = state) do
    {:ok, re} = Regex.compile("targetmode=([1-2]) msg=(\\S*)(?: target=\\d*)? " <>
      "invokerid=(\\d*) invokername=(.*) invokeruid=(.*)", "i")
    bid = s[:bot_id]
    case Regex.run(re, r) do
      [_, _, _, _, _, ^bid] ->
        {:noreply, state}

      [_, "1", msg, clid, name, uid] ->
        msg = Mambo.Helpers.unescape(msg)
        name = Mambo.Helpers.unescape(name)
        Mambo.EventManager.notify({:privmsg, {msg, name, {clid, uid}}})
        {:noreply, state}

      _ ->
        {:noreply, state}
    end
  end

  # Catch server query error messages and print them.
  def handle_info({:tcp, _, <<"error id=", c, rest :: binary>>}, {socket,_,_} = state) when c != ?0 do
    case Regex.run(~r/^(\d*) msg=(.*)/i, <<c, rest :: binary>>) do
      # give feedback when using the .rename command and nickname is already in use
      [_, "513", msg] ->
        emsg = Mambo.Helpers.escape("[color=#AA0000][b]nickname is already in use[/b][/color]")
        send_to_server(socket, "sendtextmessage targetmode=2 target=1 msg=#{emsg}")
        IO.puts("Error(513): #{Mambo.Helpers.unescape(msg)}")
        {:noreply, state}

      [_, id, msg] ->
        IO.puts("Error(#{id}): #{Mambo.Helpers.unescape(msg)}")
        {:noreply, state}

      _ ->
        {:noreply, state}
    end
  end

  def handle_info({:tcp, _, channellist}, {socket, s, [], ""} = state) do
    if String.contains?(channellist, "cid=") do
      if String.ends_with?(channellist, "error id=0 msg=ok\n\r") do
        {ids, dc} = parse_channellist(channellist)
        watchers = add_watchers(ids, s)
        {:noreply, {socket, List.keyreplace(s, :default_channel, 0, {:default_channel, dc}), watchers}}
      else
        {:noreply, {socket, s, [], channellist}}
      end
    else
      {:noreply, state}
    end
  end

  def handle_info({:tcp, _, <<"error id=0", _ :: binary>>}, {socket, s, [], channellist}) do
    {ids, dc} = parse_channellist(channellist)
    watchers = add_watchers(ids, s)
    {:noreply, {socket, List.keyreplace(s, :default_channel, 0, {:default_channel, dc}), watchers}}
  end

  # If the channellist is too long the server query will answer in chuncks, this
  # will match the rest of the chuncks and join them together will the content
  # already received. Notice the state is a 4 element tuple, this is to make
  # sure that we haven't already receive the channellist.
  def handle_info({:tcp, _, data}, {socket, s, [], channellist}) do
    if String.ends_with?(data, "error id=0 msg=ok\n\r") do
      {ids, dc} = parse_channellist(channellist <> data)
      watchers = add_watchers(ids, s)
      {:noreply, {socket, List.keyreplace(s, :default_channel, 0, {:default_channel, dc}), watchers}}
    else
      {:noreply, {socket, s, [], channellist <> data}}
    end
  end

  def handle_info({:tcp_closed, _}, state) do
    {:stop, :normal, state}
  end

  def handle_info(:keep_alive, {socket, _, _} = state) do
    send_to_server(socket, "version")
    :erlang.send_after(300000, self(), :keep_alive)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
