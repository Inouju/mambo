# Mambo

Mambo is an extensible teamspeak 3 chat bot. If you're using the bot, or have written
some scripts for it, please let me know, I'd love to hear what your doing if you don't
mind sharing it.

This project was originally written by MrShankly, and is being updated by Inouju.

## Getting Started

### Requirements
* Erlang (18.0 or later) - there are pre built packages in the [Erlang Solutions Downloads page](http://www.erlang.org/downloads)
* Elixir 1.2
* Server query login credentials
* The script `gif.ex` also requires [ImageMagick](http://www.imagemagick.org/script/binary-releases.php) to be installed.

Some plugins require access to certain APIs:
* [Twitter](https://dev.twitter.com/) for `twitter.ex`
* [WolframAlpha](http://products.wolframalpha.com/api/) for `wolframalpha.ex`
* [YouTube](https://developers.google.com/youtube/) for `youtube.ex`
* [LastFM](http://www.last.fm/api) for `lastfm.ex`

Use the above links to register an account and get your API credentials. If you
don't plan to use the above plugins you can skip this.

### Compile and run

When you have a working installation of elixir and the bot is properly configured,
download the [source code](https://github.com/Inouju/mambo/releases) and extract it to a directory of your choosing.
Open a terminal window and do the following:

```sh
$ cd path/to/mambo
$ mix do deps.get, compile
```

If everything went ok you now have compiled the bot, next step is to actually
get it running, you have 2 choices:

To run the bot without a shell and in the background do:

```sh
$ elixir --detached --no-halt -S mix
```

To run the bot with an elixir shell do:

```sh
$ iex -S mix
```

I recommend running the bot with an elixir shell, this way you can have some
feedback and easily manage the bot without turning it off (see [Managing the bot](https://github.com/inouju/mambo#managing-the-bot)
for more info). In Linux (and Mac OS X too I guess) you can use [tmux](https://tmux.github.io/)
or [screen](https://www.gnu.org/software/screen/) to keep the shell running.
I don't know about Windows, google is your friend here.

### Settings

Once you have sorted the dependencies you can start configuring the bot. Everything
related to configuration is done in the `settings.json` file.

#### `settings.json`

* `name`: Nickname that will appear in the chat
* `user`: Server query username
* `pass`: Server query password
* `host`: Server ip address
* `port`: Server query port
* `bot_id`: Bot unique id, it's important that this value is right or the bot will not work properly
* `admins`: List of admins unique id, required if you plan to use the `admin.ex` script
* `channels`: List of the channels the bot will join, this can be either a list of channel ids or the string "all" to join all the channels
* `scripts`: List of scripts that the bot will use, put only the scripts you want to use

Use the file [`settings.sample.json`](https://raw.github.com/inouju/mambo/master/settings.json.sample) as a guide, edit the values that you don't like,
remove the scripts you don't want to use from the list and when you're happy
rename it to `settings.json`.

## Scripts

Mambo by itself doesn't do much, but don't worry, it's extensible via scripting, you can add
new functionalities by writting your own scripts and/or using the provided scripts.

**Note:** Type `.help` in the chat to know more about the running scripts.

Here's the full list of provided scripts:

| Script | Commands |
|--------|----------|
| [`admin.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/admin.ex#L2-L10) | `.mute`,`.unmute`,`.gm <message>`,`.rename <name>` |
| [`benis.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/benis.ex#L2-L7) | `.benis <expression>` |
| [`brainfuck.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/brainfuck.ex#L2-L7) | `.bf <brainfuck_expression>` |
| [`cannedreplies.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/cannedreplies.ex#L2-L13) | `cool`,`gface`,`goface`,`edgyface`,`dface`,`ggface`,`chownface` |
| [`doge.ex`](https://github.com/Inouju/mambo/blob/master/lib/scripts/doge.ex) | `.doge`, `.doge <amount>` |
| [`eightball.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/eightball.ex#L2-L7) | `.8ball <question>` |
| [`gif.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/gif.ex#L2-L10) | `.gif <gif_link>` |
| [`google.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/google.ex#L2-L11) | `.g <phrase>`,`.google <phrase>`,`.img <phrase>`,`.image <phrase>`,`.images <phrase>` |
| [`help.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/help.ex#L2-L7) | `.help` |
| [`lastfm.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/lastfm.ex#L2-L9) | `.np`,`.np <last.fm user>`,`.np set <last.fm user>` |
| [`private.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/private.ex#L2-L7) | `.private` |
| [`quotes.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/quotes.ex#L2-L11) | `.quote`,`.quote <id>`,`.quote add <quote>`,`.quote find <search query>`,`.quote rm <id` |
| [`rainbow.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/rainbow.ex#L2-L8) | `.r <expression>`,`.rainbow <expression>` |
| [`random.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/random.ex#L2-L10) | `.roll`,`.rock`,`.paper`,`.scissors` |
| [`sux.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/sux.ex#L2-L7) | `.sux <expression>` |
| [`title.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/title.ex#L2-L8) | **none** |
| [`translate.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/translate.ex#L2-L8) |  `.tl <phrase>`,`.translate <phrase>`,`.translate <input language> <target language> <phrase>` |
| [`twitter.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/twitter.ex#L2-L4) | **none** |
| [`urban.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/urban.ex#L2-L8) | `.ud <term>`,`.urban <term>` |
| [`utils.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/utils.ex#L2-L11) | `.ping`,`.date`,`.time`,`.uptime`,`.version` |
| [`whatthecommit.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/whatthecommit.ex#L2-L7) | `.wtc` |
| [`wolframalpha.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/wolframalpha.ex#L2-L9) | `.wa <expression>`,`.calc <expression>`,`.convert <expression> to <units>` |
| [`youtube.ex`](https://github.com/inouju/mambo/blob/master/lib/scripts/youtube.ex#L2-L8) | `.yt <phrase>`,`.youtube <phrase>` |

### Scripting

Scripts can either be written in elixir or erlang, they all are gen_event handlers, see [[1]](http://www.erlang.org/doc/man/gen_event.html)
and [[2]](http://elixir-lang.org/docs.html#master) for more info. Look at already written scripts to
know how to write your own.

Once you have written your script place it in the `lib/scripts` folder and add it to the `scripts` list in
the `settings.json` file.

#### Events

Scripts will receive notifications of the following events:

| Event                | Notification message                    |
|----------------------|-----------------------------------------|
| chat message         | `{:msg, {msg, name, {cid, clid, uid}}}` |
| private chat message | `{:privmsg, {msg, name, {clid, uid}}}`  |
| moved into channel   | `{:move_in, {tcid, reasonid, clid}} `   |
| moved out of channel | `{:move_out, {tcid, reasonid, clid}}`   |
| left the channel     | `:left`                                 |
| entered the channel  | `{:enter, name}`                        |

##### Types

* `msg = String.t()` - message written in the chat
* `cid = integer()` - channel id (channel were the event happened)
* `tcid = integer()` - target channel id (the client moved to channel with id `tcid`)
* `clid = integer()` - client id (client that triggered the event)
* `reasonid = integer()`
* `name = String.t()` - username of the client that triggered the event

#### Exports

The modules `Mambo.Bot` and `Mambo.Brain` implement various functions meant to be used by the scripts:

#### [`Mambo.Bot`](https://github.com/inouju/mambo/blob/master/lib/mambo/bot.ex)

* [`id/0`](https://github.com/inouju/mambo/blob/master/lib/mambo/bot.ex#L37)
* [`admins/0`](https://github.com/inouju/mambo/blob/master/lib/mambo/bot.ex#L45)
* [`scripts/0`](https://github.com/inouju/mambo/blob/master/lib/mambo/bot.ex#L53)
* [`send_msg/2`](https://github.com/inouju/mambo/blob/master/lib/mambo/bot.ex#L61)
* [`send_privmsg/2`](https://github.com/inouju/mambo/blob/master/lib/mambo/bot.ex#L69)
* [`send_gm/1`](https://github.com/inouju/mambo/blob/master/lib/mambo/bot.ex#L77)
* [`kick/2`](https://github.com/inouju/mambo/blob/master/lib/mambo/bot.ex#L85)
* [`ban/3`](https://github.com/inouju/mambo/blob/master/lib/mambo/bot.ex#L93)
* [`move/2`](https://github.com/inouju/mambo/blob/master/lib/mambo/bot.ex#L101)
* [`move/3`](https://github.com/inouju/mambo/blob/master/lib/mambo/bot.ex#L113)
* [`mute/1`](https://github.com/inouju/mambo/blob/master/lib/mambo/bot.ex#L124)
* [`unmute/1`](https://github.com/inouju/mambo/blob/master/lib/mambo/bot.ex#L132)
* [`rename/1`](https://github.com/inouju/mambo/blob/master/lib/mambo/bot.ex#L140)
* [`add_watcher/1`](https://github.com/inouju/mambo/blob/master/lib/mambo/bot.ex#L148)
* [`remove_watcher/1`](https://github.com/inouju/mambo/blob/master/lib/mambo/bot.ex#L156)

#### [`Mambo.Brain`](https://github.com/inouju/mambo/blob/master/lib/mambo/brain.ex) - bot's memory

* [`add_quote/2`](https://github.com/inouju/mambo/blob/master/lib/mambo/brain.ex#L13)
* [`find_quotes/1`](https://github.com/inouju/mambo/blob/master/lib/mambo/brain.ex#L19)
* [`remove_quote/1`](https://github.com/inouju/mambo/blob/master/lib/mambo/brain.ex#L36)
* [`get_quote/1`](https://github.com/inouju/mambo/blob/master/lib/mambo/brain.ex#L41)
* [`get_random_quote/0`](https://github.com/inouju/mambo/blob/master/lib/mambo/brain.ex#L51)
* [`quotes_max/0`](https://github.com/inouju/mambo/blob/master/lib/mambo/brain.ex#L60)
* [`add_lastfm_user/2`](https://github.com/inouju/mambo/blob/master/lib/mambo/brain.ex#L69)
* [`get_lastfm_user/1`](https://github.com/inouju/mambo/blob/master/lib/mambo/brain.ex#L74)
* [`remove_lastfm_user/1`](https://github.com/inouju/mambo/blob/master/lib/mambo/brain.ex#L84)
* [`put/2`](https://github.com/inouju/mambo/blob/master/lib/mambo/brain.ex#L91)
* [`get/1`](https://github.com/inouju/mambo/blob/master/lib/mambo/brain.ex#L96)
* [`remove/1`](https://github.com/inouju/mambo/blob/master/lib/mambo/brain.ex#L106)

If you need an http client in your script use [`hackney`](https://github.com/benoitc/hackney).
If you need to decode or encode json use [`jsx`](https://github.com/talentdeficit/jsx).
They will both be installed when you do `mix deps.get` during the installation procedure.

## Managing the bot

**Note:** This requires to start the bot with `iex -S mix`.

All the functions mentioned in [exports](https://github.com/inouju/mambo#exports) are available for you to use in an
elixir shell.

To manage scripts, load, unload, notify or get a list of the running scripts, use the
API from the module [`Mambo.EventManager`](https://github.com/inouju/mambo/blob/master/lib/mambo/event_manager.ex).

This should be enough to manage the bot without ever shutting it down, even adding
new plugins.

## Getting help

You can get help by [making an issue](https://github.com/inouju/mambo/issues) on GitHub, or going
to the [official thread](http://forum.teamspeak.com/showthread.php/93066-Chat-bot-Mambo-IRC-style-bot-for-teamspeak-3)
in the teamspeak forums. If you are already knowledgable about Mambo, please
consider contributing for the sake of others.

## License

All files under this repository fall under the MIT License. Check
[LICENSE](https://github.com/inouju/mambo/blob/master/LICENSE) for more details.
