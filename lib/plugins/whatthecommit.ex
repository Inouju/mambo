defmodule Whatthecommit do
  use GenEvent.Behaviour

  def wtc(callback) do
    url = 'http://whatthecommit.com/index.txt'
    case :httpc.request(:get, {url, []}, [], body_format: :binary) do
      {:ok, {{_, 200, _}, _, body}} ->
        callback.("[b]WhatTheCommit:[/b] #{String.strip(body, ?\n)}")
      _ ->
        callback.("Well shit, something went wrong. I blame you.")
    end
  end

  def init(_args) do
    {:ok, []}
  end

  def handle_event({gen_server, msg, _user}, state) do
    case msg do
      ["!wtc"] ->
        callback = fn(x) ->
                     :gen_server.cast(gen_server, {:send_text, x})
                   end
        spawn(fn() -> wtc(callback) end)
        {:ok, state}
      _->
        {:ok, state}
    end
  end
end
