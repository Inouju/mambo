defmodule Twitter do
  @moduledoc """
  Print tweets to chat when a tweet link is posted.
  """

  require Record
  use GenEvent

  Record.defrecord :tweet, [
    user: {nil, nil},
    text: nil,
    entities: []
  ]

  def init([key, secret]) do
    {:ok, get_token(key, secret)}
  end

  def handle_event({:msg, {".help twitter", _, {cid,_,_}}}, token) do
    Mambo.Bot.send_msg(<<?\n, @moduledoc>>, cid)
    {:ok, token}
  end

  def handle_event({:privmsg, {".help twitter", _, {clid,_}}}, token) do
    Mambo.Bot.send_privmsg(<<?\n, @moduledoc>>, clid)
    {:ok, token}
  end

  def handle_event({:msg, {msg, _, {cid,_,_}}}, token) do
    if id = Mambo.Helpers.get_tweet_id(msg) do
      answer = fn(x) -> Mambo.Bot.send_msg(x, cid) end
      spawn(fn -> print_tweets(id, token, answer) end)
      {:ok, token}
    else
      {:ok, token}
    end
  end

  def handle_event(_, token) do
    {:ok, token}
  end

  # Helpers

  defp get_token(key, secret) do
    url = "https://api.twitter.com/oauth2/token"
    body = "grant_type=client_credentials"
    headers = [{"Authorization", "Basic #{:base64.encode("#{key}:#{secret}")}"},
               {"Content-Type", "application/x-www-form-urlencoded;charset=UTF-8"}]
    {:ok, 200, _, client} = :hackney.post(url, headers, body, [])
    {:ok, body} = :hackney.body(client)
    :jsx.decode(body, [{:labels, :atom}])[:access_token]
  end

  defp print_tweets(id, token, answer) do
    case get_tweets(id, token, []) do
      [] -> :ok
      [tweet] ->
        answer.("[b]Twitter:[/b] #{format_tweet(tweet)}")
      tweets ->
        Enum.map(tweets, &format_tweet/1)
          |> Enum.each(fn(tweet) -> answer.("[b]Twitter:[/b] #{tweet}") end)
    end
  end

  defp get_tweets(id, token, acc) do
    url = "https://api.twitter.com/1.1/statuses/show.json?id=#{id}"
    headers = [{"Authorization", "Bearer #{token}"}]
    case :hackney.get(url, headers, <<>>, []) do
      {:ok, 200, _, client} ->
        {:ok, body} = :hackney.body(client)
        json = :jsx.decode(body, [{:labels, :atom}])
        uscreen_name = json[:user][:screen_name]
        tweet = tweet(
          user: {uscreen_name, "https://twitter.com/#{uscreen_name}"},
          text: json[:text],
          entities: json[:entities]
        )
        case json[:in_reply_to_status_id_str] do
          :null -> [tweet | acc]
          reply -> get_tweets(reply, token, [tweet | acc])
        end
      _ ->
        []
    end
  end

  # replaces entities and returns the formatted tweet text.
  defp format_tweet(tweet(user: {user,user_link}, text: text, entities: entities)) do
    # Hashtags.
    text = Enum.reduce(entities[:hashtags], text, fn(tag, old_text) ->
      ttag = tag[:text]
      replacement = "[url=https://twitter.com/search?q=%23#{ttag}][color=#00557f]##{ttag}[/color][/url]"
      String.replace(old_text, "##{ttag}", replacement)
    end)

    # Mentions.
    text = Enum.reduce(entities[:user_mentions], text, fn(mention, old_text) ->
      name = mention[:screen_name]
      replacement = "[url=https://twitter.com/#{name}][color=#00557f]@#{name}[/color][/url]"
      String.replace(old_text, "@#{name}", replacement)
    end)

    # Media.
    if entities[:media] do
      text = Enum.reduce(entities[:media], text, fn(media, old_text) ->
        if media[:type] != "photo" do
          text
        else
          replacement = "[url=#{media[:media_url]}][color=#00557f][i]pic.twitter.com[/i][/color][/url]"
          String.replace(old_text, media[:url], replacement)
        end
      end)
    end

    # URLs.
    text = Enum.reduce(entities[:urls], text, fn(url, old_text) ->
      expanded_url = url[:expanded_url]
      uri = URI.parse(expanded_url)
      canonical_url = String.replace(uri.host, "www.", "")
      replacement = "[url=#{expanded_url}][color=#00557f][i]#{canonical_url}[/i][/color][/url]"
      String.replace(old_text, url[:url], replacement)
    end)

    "[url=#{user_link}][color=#00557f][b]@#{user}[/b][/color][/url]"<>
    "[color=#00557f][b]:[/b][/color] #{text}"
  end
end
