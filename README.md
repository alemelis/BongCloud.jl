# Ke2.jl

A general-purpose Julia client for the [Lichess API](https://lichess.org/api). Chess-agnostic — it speaks HTTP and JSON, not bitboards. Anyone in the Julia ecosystem can use it: bot builders, game scrapers, ML researchers, puzzle nerds.

**Ke2 knows nothing about chess.** It sends strings and receives structs. Dependencies: `HTTP.jl` + `JSON3.jl`.

## Installation

```julia
using Pkg
Pkg.add("Ke2")
```

## Quick start

```julia
using Ke2

# anonymous client (read-only endpoints)
c = LichessClient()

# authenticated client
c = LichessClient(token=ENV["LICHESS_TOKEN"])

# look up a user
user = get_user(c, "DrNykterstein")
println(user.username)  # "DrNykterstein"

# stream games for ML research
for game in export_user_games(c, "DrNykterstein"; max=100, perfType="blitz")
    println(game.moves)
end

# daily puzzle
puzzle = get_daily_puzzle(c)
println(puzzle.puzzle.solution)
```

## API reference

### Client

```julia
LichessClient()                            # anonymous
LichessClient(token="lip_...")             # authenticated
LichessClient(token=ENV["LICHESS_TOKEN"])  # from env
```

### Account

```julia
get_profile(c)                # GET /api/account
get_email(c)                  # GET /api/account/email
get_preferences(c)            # GET /api/account/preferences
get_kid_mode(c)               # GET /api/account/kid → Bool
set_kid_mode(c, true)         # POST /api/account/kid
```

### Users

```julia
get_user(c, "username")
get_user_rating_history(c, "username")
get_users_status(c, ["alice", "bob"])
get_leaderboard(c, 10, "blitz")
get_user_activity(c, "username")
get_users_by_ids(c, ["alice", "bob", "carol"])
```

### Games

Streaming endpoints return `Channel{Game}` — iterate with `for ... in`.

```julia
# single game
export_game(c, "gameId"; moves=true, clocks=true, evals=true)

# user games (streaming)
for game in export_user_games(c, "DrNykterstein"; max=50, perfType="bullet")
    println(game.id, " ", game.moves)
end

# batch by IDs (streaming)
for game in export_games_by_ids(c, ["abc123", "def456"]; clocks=true)
    println(game.id)
end

get_playing(c, ["alice", "bob"])   # current games
get_tv_games(c)                    # TV channels
```

### Bot API

```julia
upgrade_to_bot(c)
get_online_bots(c; nb=50)          # Channel{Dict}

# main event loop
for event in stream_events(c)      # Channel{Event}
    if event.type == "challenge"
        accept_challenge(c, event.challenge.id)
    elseif event.type == "gameStart"
        handle_game(c, event.game.gameId)
    end
end

# game stream — returns Channel{GameStateEvent}
# each event is a GameFull, GameState, or ChatLine
for event in stream_game(c, gameId)
    if event isa GameState
        make_move(c, gameId, pick_move(event.moves))
    end
end

make_move(c, gameId, "e2e4")
make_move(c, gameId, "e2e4"; offering_draw=true)
abort_game(c, gameId)
resign_game(c, gameId)
send_chat(c, gameId, "player", "Good luck!")
```

### Board API

For human accounts playing programmatically.

```julia
stream_board_events(c)                        # Channel{Event}
stream_board_game(c, gameId)                  # Channel{GameStateEvent}
board_make_move(c, gameId, "e2e4")
board_seek(c; rated=false, time=10, increment=0)
board_abort(c, gameId)
board_resign(c, gameId)
board_chat(c, gameId, "player", "gg")
```

### Challenges

```julia
create_challenge(c, "username";
    rated=true, clock_limit=300, clock_increment=3)
create_open_challenge(c; clock_limit=600, clock_increment=0)
list_challenges(c)
accept_challenge(c, challengeId)
decline_challenge(c, challengeId; reason="tooFast")
cancel_challenge(c, challengeId)
```

### Puzzles

```julia
get_daily_puzzle(c)
get_puzzle(c, "puzzleId")
get_puzzle_dashboard(c, 30)       # last 30 days

for activity in get_puzzle_activity(c; max=50)  # Channel{Dict}
    println(activity)
end
```

### Tournaments

```julia
get_arena(c, tournamentId)
get_swiss(c, swissId)

for game in get_arena_games(c, tournamentId)    # Channel{Game}
    println(game.id)
end
for result in get_arena_results(c, tournamentId)  # Channel{ArenaResult}
    println(result.rank, " ", result.username)
end
for game in get_swiss_games(c, swissId)         # Channel{Game}
    println(game.id)
end

create_arena(c; clock_time=3, clock_increment=0, minutes=45)
join_arena(c, tournamentId)
withdraw_arena(c, tournamentId)
join_swiss(c, swissId)
withdraw_swiss(c, swissId)
```

### Analysis

```julia
eval = get_cloud_eval(c, "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1"; multi_pv=3)
```

### Opening Explorer

Uses `explorer.lichess.ovh` — no separate client needed.

```julia
get_masters_db(c, fen)
get_lichess_db(c, fen; ratings=[2000, 2200, 2500], speeds=["blitz", "rapid"])
get_player_db(c, fen, "username"; color="white")
```

### Broadcasts

```julia
get_official_broadcasts(c; nb=20)
create_broadcast(c; name="My event", description="Round 1")
push_broadcast_pgn(c, roundId, pgn_string)
```

### Studies

```julia
pgn = export_study(c, studyId)
pgn = export_study_chapter(c, studyId, chapterId)
```

## Streaming pattern

Lichess streams NDJSON. Ke2 wraps every streaming endpoint in a `Channel{T}` with a buffer of 64, so you consume it with a plain `for` loop:

```julia
for event in stream_events(c)
    # runs until the stream closes or you break
end
```

To stop early, `break` out of the loop. The channel and underlying HTTP connection are cleaned up automatically.

## Error handling

HTTP errors (4xx, 5xx) raise a Julia `ErrorException` with the status code and response body. 429 rate-limit responses are retried automatically with exponential backoff (1s → 2s → 4s → 8s) before giving up.

## Type hierarchy

```
GameStateEvent (abstract)
├── GameFull    — first event on a game stream
├── GameState   — subsequent move/time updates
└── ChatLine    — chat messages

Event           — from /api/stream/event
├── .type       — "challenge" | "gameStart" | "gameFinish" | ...
├── .challenge  — ChallengeInfo (when type == "challenge")
└── .game       — GameEventInfo (when type == "gameStart" etc.)
```

## Ecosystem

Ke2.jl is a pure API client. It pairs naturally with:

- A chess rules engine (move generation, validation)
- A search/AI engine (choosing which move to play)

But it's also perfectly useful standalone — download games, scrape puzzles, monitor tournaments, all without touching chess logic.
