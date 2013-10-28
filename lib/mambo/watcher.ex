defmodule Mambo.Watcher do
  @moduledoc """
  Responsible for watching the chat of a channel and notifying the scripts when
  a chat message comes up.
  """

  use GenServer.Behaviour

  @nmsg     "notifytextmessage"
  @nmove    "notifyclientmoved"
  @nleft    "notifyclientleftview"
  @nenter   "notifycliententerview"
  @login_ok "error id=0 msg=ok\n\r"
  @admin    "\.mute|\.unmute|\.ban|\.kick|\.move|\.promote|\.demote|\.gm"

  # API.

  @spec start_link(any()) :: {:ok, pid}
  def start_link(args) do
    {:ok, _} = :gen_server.start_link(__MODULE__, args, [])
  end

  # Helpers.

  defp send_to_server(socket, msg) do
    :ok = :gen_tcp.send(socket, "#{msg}\n")
  end

  defp login(socket, id, name, user, pass) do
    [ "login #{user} #{pass}", "use sid=1",
      "servernotifyregister event=channel id=#{id}",
      "servernotifyregister event=textchannel id=#{id}",
      "clientupdate client_nickname=#{Mambo.Helpers.escape(name)}", "whoami" ]
    |> Enum.each(fn(x) -> send_to_server(socket, x) end)
  end

  # gen_server callbacks

  def init({cid, bot_id, {name, host, port, user, pass}}) do
    {:ok, socket} = :gen_tcp.connect(String.to_char_list!(host), port, [:binary])
    login(socket, cid, name, user, pass)
    :erlang.send_after(300000, self(), :keep_alive)
    {:ok, {:unmute, socket, cid, bot_id}}
  end

  def handle_cast(:mute, {_, socket, ids}) do
    {:noreply, {:mute, socket, ids}}
  end

  def handle_cast(:unmute, {_, socket, ids}) do
    {:noreply, {:unmute, socket, ids}}
  end

  def handle_cast({:send_msg, msg}, {_, socket, _} = state) do
    cmd = "sendtextmessage targetmode=2 target=1 msg=#{Mambo.Helpers.escape(msg)}"
    send_to_server(socket, cmd)
    {:noreply, state}
  end

  def handle_cast(_, state) do
    {:noreply, state}
  end

  # If login went ok, move watcher to channel with id `cid`.
  def handle_info({:tcp, _, <<@login_ok, r :: binary>>}, {_, socket, cid, bid} = state) do
    case Regex.run(%r/client_id=(\d*)/, r) do
      [_, clid] ->
        send_to_server(socket, "clientmove clid=#{clid} cid=#{cid}")
        {:noreply, {:unmute, socket, {binary_to_integer(clid), cid, bid}}}
      _ ->
        {:noreply, state}
    end
  end

  def handle_info({:tcp, _, <<@nmsg, r :: binary>>}, {status, _, {_,cid,bid}} = state) do
    {:ok, re} = Regex.compile("targetmode=([1-2]) msg=(\\S*)(?: target=\\d*)? " <>
      "invokerid=(\\d*) invokername=(.*) invokeruid=(.*)", "i")

    case Regex.run(re, r) do
      [_, _, _, _, _, ^bid] -> {:noreply, state}

      [_, "2", msg, clid, name, uid] ->
        msg = Mambo.Helpers.unescape(msg)
        name = Mambo.Helpers.unescape(name)
        cond do
          status == :unmute ->
            Mambo.EventManager.notify({:msg, {msg, name, {cid, clid, uid}}})
            {:noreply, state}
          # don't mute admin script
          status == :mute and Regex.match?(%r/^(#{@admin})/i, msg) ->
            Mambo.EventManager.notify({:msg, {msg, name, {cid, clid, uid}}})
            {:noreply, state}
          true ->
            {:noreply, state}
        end

      _ -> {:noreply, state}
    end
  end

  def handle_info({:tcp, _, <<@nmove, r :: binary>>}, {:unmute, _, {clid,cid,_}} = state) do
    scid = integer_to_binary(cid)
    sclid = integer_to_binary(clid)
    case Regex.run(%r/ctid=(\d*) reasonid=(\d*).*?clid=(\d*)/i, r) do
      [_, _, "4", ^sclid] ->
        Mambo.Bot.remove_watcher(cid)
        {:noreply, state}

      [_, ^scid, reasonid, iclid] ->
        Mambo.EventManager.notify({:move_in, {cid, reasonid, iclid}})
        {:noreply, state}

      [_, ocid, reasonid, oclid] ->
        Mambo.EventManager.notify({:move_out, {ocid, reasonid, oclid}})
        {:noreply, state}

      _ ->
        {:noreply, state}
    end
  end

  def handle_info({:tcp, _, <<@nleft, _ :: binary>>}, {:unmute, _, _} = state) do
    Mambo.EventManager.notify(:left)
    {:noreply, state}
  end

  def handle_info({:tcp, _, <<@nenter, r :: binary>>}, {:unmute, _, _} = state) do
    case Regex.run(%r/client_nickname=(.*) client_input_muted=/i, r) do
      [_, name] ->
        Mambo.EventManager.notify({:enter, name})
        {:noreply, state}
      _ ->
        {:noreply, state}
    end
  end

  # Catch server query error messages and print them.
  def handle_info({:tcp, _, <<"error id=", c, rest :: binary>>}, state) when c != ?0 do
    case Regex.run(%r/^(\d*) msg=(.*)/i, <<c, rest :: binary>>) do
      [_, id, msg] ->
        IO.puts("Error(#{id}): #{Mambo.Helpers.unescape(msg)}")
        {:noreply, state}
      _ ->
        {:noreply, state}
    end
  end

  def handle_info({:tcp_closed, _}, state) do
    {:stop, :normal, state}
  end

  def handle_info(:keep_alive, {_, socket, _} = state) do
    send_to_server(socket, "version")
    :erlang.send_after(300000, self(), :keep_alive)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
