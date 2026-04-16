module Ke2

include("Types.jl")
include("Client.jl")
include("Account.jl")
include("Users.jl")
include("Games.jl")
include("Bot.jl")
include("Board.jl")
include("Challenges.jl")
include("Puzzles.jl")
include("Tournaments.jl")
include("Analysis.jl")
include("Explorer.jl")
include("Broadcasts.jl")
include("Studies.jl")

using .Types
using .Account
using .Users
using .Games
using .Bot
using .Board
using .Challenges
using .Puzzles
using .Tournaments
using .Analysis
using .Explorer
using .Broadcasts
using .Studies

export LichessClient

# Account
export get_profile, get_email, get_preferences, get_kid_mode, set_kid_mode

# Users
export get_user, get_user_rating_history, get_users_status,
       get_leaderboard, get_user_activity, get_users_by_ids

# Games
export export_game, export_user_games, export_games_by_ids,
       get_playing, stream_users_games, get_tv_games

# Bot
export upgrade_to_bot, get_online_bots, stream_events,
       stream_game, make_move, abort_game, resign_game, send_chat

# Board
export stream_board_events, stream_board_game,
       board_make_move, board_seek, board_abort, board_resign, board_chat

# Challenges
export create_challenge, create_open_challenge, list_challenges,
       accept_challenge, decline_challenge, cancel_challenge

# Puzzles
export get_daily_puzzle, get_puzzle, get_puzzle_activity, get_puzzle_dashboard

# Tournaments
export get_arena, get_arena_games, get_arena_results,
       get_swiss, get_swiss_games,
       create_arena, join_arena, withdraw_arena,
       join_swiss, withdraw_swiss

# Analysis
export get_cloud_eval

# Explorer
export get_masters_db, get_lichess_db, get_player_db

# Broadcasts
export get_official_broadcasts, create_broadcast, push_broadcast_pgn

# Studies
export export_study, export_study_chapter

end # module
