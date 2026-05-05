module Types

using JSON3, StructTypes

export LichessClient, auth_headers, api_url, explorer_url
export User, RatingPerf, UserStatus, Activity
export Game, Players, GamePlayer, Clock
export Event, ChallengeInfo, GameEventInfo
export GameStateEvent, GameFull, GameState, ChatLine, UnknownGameEvent
export Puzzle, PuzzleData
export ArenaResult

struct LichessClient
    token::Union{String,Nothing}
    base_url::String
    explorer_url::String
end

LichessClient(; token=nothing,
    base_url="https://lichess.org",
    explorer_url="https://explorer.lichess.ovh") =
    LichessClient(token, base_url, explorer_url)

function auth_headers(c::LichessClient)
    isnothing(c.token) && return Dict{String,String}()
    Dict("Authorization" => "Bearer $(c.token)")
end

api_url(c::LichessClient, path::String) = c.base_url * path
explorer_url(c::LichessClient, path::String) = c.explorer_url * path

# ── Users ──────────────────────────────────────────────────────────────────

struct RatingPerf
    games::Int
    rating::Int
    rd::Int
    prog::Int
    prov::Union{Bool,Nothing}
end
StructTypes.StructType(::Type{RatingPerf}) = StructTypes.Struct()

struct User
    id::String
    username::String
    perfs::Union{Dict{String,RatingPerf},Nothing}
    createdAt::Union{Int,Nothing}
    seenAt::Union{Int,Nothing}
    playTime::Union{Dict{String,Int},Nothing}
    online::Union{Bool,Nothing}
    title::Union{String,Nothing}
    patron::Union{Bool,Nothing}
    disabled::Union{Bool,Nothing}
    tosViolation::Union{Bool,Nothing}
    url::Union{String,Nothing}
    nbFollowing::Union{Int,Nothing}
    nbFollowers::Union{Int,Nothing}
    completionRate::Union{Int,Nothing}
    count::Union{Dict{String,Int},Nothing}
    streaming::Union{Bool,Nothing}
    followable::Union{Bool,Nothing}
    following::Union{Bool,Nothing}
    blocking::Union{Bool,Nothing}
    followsYou::Union{Bool,Nothing}
end
StructTypes.StructType(::Type{User}) = StructTypes.Struct()

struct UserStatus
    id::String
    name::String
    online::Union{Bool,Nothing}
    playing::Union{Bool,Nothing}
    streaming::Union{Bool,Nothing}
    patron::Union{Bool,Nothing}
end
StructTypes.StructType(::Type{UserStatus}) = StructTypes.Struct()

struct ActivityGame
    win::Union{Int,Nothing}
    loss::Union{Int,Nothing}
    draw::Union{Int,Nothing}
    rp::Union{Dict{String,Int},Nothing}
end
StructTypes.StructType(::Type{ActivityGame}) = StructTypes.Struct()

struct Activity
    interval::Union{Dict{String,Int},Nothing}
    games::Union{Dict{String,ActivityGame},Nothing}
    puzzles::Union{Dict{String,Any},Nothing}
    tournaments::Union{Dict{String,Any},Nothing}
    practice::Union{Vector{Any},Nothing}
    correspondenceMoves::Union{Dict{String,Any},Nothing}
    correspondenceEnds::Union{Dict{String,Any},Nothing}
end
StructTypes.StructType(::Type{Activity}) = StructTypes.Struct()

# ── Games ──────────────────────────────────────────────────────────────────

struct Clock
    initial::Int
    increment::Int
    totalTime::Union{Int,Nothing}
end
StructTypes.StructType(::Type{Clock}) = StructTypes.Struct()

struct GamePlayer
    user::Union{Dict{String,Any},Nothing}
    rating::Union{Int,Nothing}
    ratingDiff::Union{Int,Nothing}
    aiLevel::Union{Int,Nothing}
    analysis::Union{Dict{String,Any},Nothing}
end
StructTypes.StructType(::Type{GamePlayer}) = StructTypes.Struct()

struct Players
    white::GamePlayer
    black::GamePlayer
end
StructTypes.StructType(::Type{Players}) = StructTypes.Struct()

struct Game
    id::String
    rated::Union{Bool,Nothing}
    variant::Union{String,Nothing}
    speed::Union{String,Nothing}
    perf::Union{String,Nothing}
    createdAt::Union{Int,Nothing}
    lastMoveAt::Union{Int,Nothing}
    status::Union{String,Nothing}
    players::Union{Players,Nothing}
    winner::Union{String,Nothing}
    moves::Union{String,Nothing}
    pgn::Union{String,Nothing}
    clocks::Union{Vector{Int},Nothing}
    clock::Union{Clock,Nothing}
    opening::Union{Dict{String,Any},Nothing}
    analysis::Union{Vector{Any},Nothing}
    tournament::Union{String,Nothing}
    swiss::Union{String,Nothing}
end
StructTypes.StructType(::Type{Game}) = StructTypes.Struct()

# ── Events (Bot/Board stream) ───────────────────────────────────────────────

struct ChallengeInfo
    id::String
    url::Union{String,Nothing}
    status::Union{String,Nothing}
    challenger::Union{Dict{String,Any},Nothing}
    destUser::Union{Dict{String,Any},Nothing}
    variant::Union{Dict{String,Any},Nothing}
    rated::Union{Bool,Nothing}
    speed::Union{String,Nothing}
    timeControl::Union{Dict{String,Any},Nothing}
    color::Union{String,Nothing}
    finalColor::Union{String,Nothing}
    perf::Union{Dict{String,Any},Nothing}
    direction::Union{String,Nothing}
    initialFen::Union{String,Nothing}
    declineReason::Union{String,Nothing}
    declineReasonKey::Union{String,Nothing}
end
StructTypes.StructType(::Type{ChallengeInfo}) = StructTypes.Struct()

struct GameEventInfo
    gameId::Union{String,Nothing}
    id::Union{String,Nothing}
    fullId::Union{String,Nothing}
    color::Union{String,Nothing}
    fen::Union{String,Nothing}
    hasMoved::Union{Bool,Nothing}
    isMyTurn::Union{Bool,Nothing}
    lastMove::Union{String,Nothing}
    opponent::Union{Dict{String,Any},Nothing}
    perf::Union{String,Nothing}
    rated::Union{Bool,Nothing}
    secondsLeft::Union{Int,Nothing}
    source::Union{String,Nothing}
    speed::Union{String,Nothing}
    variant::Union{Dict{String,Any},Nothing}
    compat::Union{Dict{String,Any},Nothing}
end
StructTypes.StructType(::Type{GameEventInfo}) = StructTypes.Struct()

struct Event
    type::String
    challenge::Union{ChallengeInfo,Nothing}
    game::Union{GameEventInfo,Nothing}
end
StructTypes.StructType(::Type{Event}) = StructTypes.Struct()

# ── Game state events (bot/board game stream) ───────────────────────────────

abstract type GameStateEvent end

struct GameFull <: GameStateEvent
    id::String
    variant::Union{Dict{String,Any},Nothing}
    clock::Union{Dict{String,Any},Nothing}
    speed::Union{String,Nothing}
    perf::Union{Dict{String,Any},Nothing}
    rated::Union{Bool,Nothing}
    createdAt::Union{Int,Nothing}
    white::Union{Dict{String,Any},Nothing}
    black::Union{Dict{String,Any},Nothing}
    initialFen::Union{String,Nothing}
    state::Union{Dict{String,Any},Nothing}
    tournamentId::Union{String,Nothing}
end
StructTypes.StructType(::Type{GameFull}) = StructTypes.Struct()

struct GameState <: GameStateEvent
    moves::String
    wtime::Int
    btime::Int
    winc::Int
    binc::Int
    status::String
    winner::Union{String,Nothing}
    wdraw::Union{Bool,Nothing}
    bdraw::Union{Bool,Nothing}
    wtakeback::Union{Bool,Nothing}
    btakeback::Union{Bool,Nothing}
end
StructTypes.StructType(::Type{GameState}) = StructTypes.Struct()

struct ChatLine <: GameStateEvent
    room::String
    username::String
    text::String
end
StructTypes.StructType(::Type{ChatLine}) = StructTypes.Struct()

struct UnknownGameEvent <: GameStateEvent
    type::String
    raw::Any
end

# ── Puzzles ────────────────────────────────────────────────────────────────

struct PuzzleData
    id::String
    rating::Int
    plays::Int
    solution::Vector{String}
    themes::Vector{String}
    initialPly::Union{Int,Nothing}
    gameId::Union{String,Nothing}
end
StructTypes.StructType(::Type{PuzzleData}) = StructTypes.Struct()

struct Puzzle
    game::Union{Dict{String,Any},Nothing}
    puzzle::PuzzleData
end
StructTypes.StructType(::Type{Puzzle}) = StructTypes.Struct()

# ── Tournaments ────────────────────────────────────────────────────────────

struct ArenaResult
    rank::Int
    score::Int
    rating::Union{Int,Nothing}
    username::String
    title::Union{String,Nothing}
    performance::Union{Int,Nothing}
    team::Union{String,Nothing}
end
StructTypes.StructType(::Type{ArenaResult}) = StructTypes.Struct()

end # module
