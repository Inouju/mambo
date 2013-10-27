defmodule Mambo.Brain do
  @moduledoc """
  Implements the Mambo memory using mnesia, 3 tables are available:
    1 - {:mquotes, :id, :content}
    2 - {:mlastfm, :id, :username}
    3 - {:mscripts, :key, :value}
  """

  # API.

  # Quotes.

  def add_quote(id, content) do
    f = fn() -> :mnesia.write({:mquotes, id, content}) end
    :mnesia.activity(:transaction, f)
    id
  end

  def find_quotes(query) do
    keywords = String.replace(query, %r/(\.|:|,|;|\?|!)/, "")
      |> String.downcase
      |> String.split(["\n","\s","\t","\r"], trim: true)

    f = fn() ->
      :mnesia.foldl(fn({:mquotes, id, content}, acc) ->
        if String.contains?(String.downcase(content),  keywords) do
          [id | acc]
        else
          acc
        end
      end, [], :mquotes)
    end
    :mnesia.activity(:transaction, f)
  end

  def remove_quote(id) do
    f = fn() -> :mnesia.delete({:mquotes, id}) end
    :mnesia.activity(:transaction, f)
  end

  def get_quote(id) do
    f = fn() ->
      case :mnesia.read({:mquotes, id}) do
        [{:mquotes, ^id, content}] -> {id, content}
        [] -> :not_found
      end
    end
    :mnesia.activity(:transaction, f)
  end

  def get_random_quote() do
    :random.seed(:erlang.now())
    ids = :mnesia.dirty_all_keys(:mquotes)
    id = Enum.at(ids, :random.uniform(length(ids)) - 1)
    get_quote(id)
  end

  def quotes_max() do
    ids = :mnesia.dirty_all_keys(:mquotes)
    Enum.max(ids)
  end

  # Lastfm.

  def add_lastfm_user(id, username) do
    f = fn() -> :mnesia.write({:mlastfm, id, username}) end
    :mnesia.activity(:transaction, f)
  end

  def get_lastfm_user(id) do
    f = fn() ->
      case :mnesia.read({:mlastfm, id}) do
        [{:mlastfm, ^id, username}] -> username
        [] -> :not_found
      end
    end
    :mnesia.activity(:transaction, f)
  end

  def remove_lastfm_user(id) do
    f = fn() -> :mnesia.delete({:mlastfm, id}) end
    :mnesia.activity(:transaction, f)
  end

  # Scripts.

  def put(key, value) do
    f = fn() -> :mnesia.write({:mscripts, key, value}) end
    :mnesia.activity(:transaction, f)
  end

  def get(key) do
    f = fn() ->
      case :mnesia.read({:mscripts, key}) do
        [{:mscripts, ^key, value}] -> value
        [] -> :not_found
      end
    end
    :mnesia.activity(:transaction, f)
  end

  def remove(key) do
    f = fn() -> :mnesia.delete({:mscripts, key}) end
    :mnesia.activity(:transaction, f)
  end
end
