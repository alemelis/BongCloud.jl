module Tournaments

using JSON3
using ..Types: LichessClient, Game, ArenaResult
using ..Client: request, request_stream, parse_response

export get_arena, get_arena_games, get_arena_results,
       get_swiss, get_swiss_games,
       create_arena, join_arena, withdraw_arena,
       join_swiss, withdraw_swiss

const CHANNEL_BUFFER = 64

get_arena(c::LichessClient, tournament_id::String) =
    parse_response(request("GET", c, "/api/tournament/$tournament_id"), Dict{String,Any})

function get_arena_games(c::LichessClient, tournament_id::String;
                         player=nothing, moves=true, pgn=false,
                         tags=true, clocks=false, evals=false, opening=false)
    q = (player=player, moves=moves, pgnInJson=pgn, tags=tags,
         clocks=clocks, evals=evals, opening=opening)
    Channel{Game}(CHANNEL_BUFFER) do ch
        request_stream(c, "/api/tournament/$tournament_id/games";
                       query=q, headers=Dict("Accept" => "application/x-ndjson")) do line
            put!(ch, JSON3.read(line, Game))
        end
    end
end

function get_arena_results(c::LichessClient, tournament_id::String;
                           nb::Union{Int,Nothing}=nothing, sheet::Bool=false)
    Channel{ArenaResult}(CHANNEL_BUFFER) do ch
        request_stream(c, "/api/tournament/$tournament_id/results";
                       query=(nb=nb, sheet=sheet)) do line
            put!(ch, JSON3.read(line, ArenaResult))
        end
    end
end

get_swiss(c::LichessClient, swiss_id::String) =
    parse_response(request("GET", c, "/api/swiss/$swiss_id"), Dict{String,Any})

function get_swiss_games(c::LichessClient, swiss_id::String;
                         moves=true, pgn=false, tags=true,
                         clocks=false, evals=false, opening=false)
    q = (moves=moves, pgnInJson=pgn, tags=tags, clocks=clocks,
         evals=evals, opening=opening)
    Channel{Game}(CHANNEL_BUFFER) do ch
        request_stream(c, "/api/swiss/$swiss_id/games";
                       query=q, headers=Dict("Accept" => "application/x-ndjson")) do line
            put!(ch, JSON3.read(line, Game))
        end
    end
end

function create_arena(c::LichessClient;
                      name::Union{String,Nothing}=nothing,
                      clock_time::Int=3,
                      clock_increment::Int=0,
                      minutes::Int=45,
                      wait_minutes::Int=5,
                      start_date::Union{Int,Nothing}=nothing,
                      variant::String="standard",
                      rated::Bool=true,
                      position::Union{String,Nothing}=nothing,
                      berserkable::Bool=true,
                      streakable::Bool=true,
                      description::Union{String,Nothing}=nothing,
                      team::Union{String,Nothing}=nothing,
                      min_rating::Union{Int,Nothing}=nothing,
                      max_rating::Union{Int,Nothing}=nothing,
                      nb_rated_games::Union{Int,Nothing}=nothing)
    body = Dict{String,Any}(
        "clockTime" => clock_time,
        "clockIncrement" => clock_increment,
        "minutes" => minutes,
        "waitMinutes" => wait_minutes,
        "variant" => variant,
        "rated" => rated,
        "berserkable" => berserkable,
        "streakable" => streakable,
    )
    isnothing(name) || (body["name"] = name)
    isnothing(start_date) || (body["startDate"] = start_date)
    isnothing(position) || (body["position"] = position)
    isnothing(description) || (body["description"] = description)
    isnothing(team) || (body["conditions.teamMember.teamId"] = team)
    isnothing(min_rating) || (body["conditions.minRating.rating"] = min_rating)
    isnothing(max_rating) || (body["conditions.maxRating.rating"] = max_rating)
    isnothing(nb_rated_games) || (body["conditions.nbRatedGame.nb"] = nb_rated_games)

    resp = request("POST", c, "/api/tournament"; body=body)
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body, Dict{String,Any})
end

function join_arena(c::LichessClient, tournament_id::String;
                    password::Union{String,Nothing}=nothing,
                    team::Union{String,Nothing}=nothing)
    body = Dict{String,Any}()
    isnothing(password) || (body["password"] = password)
    isnothing(team) || (body["team"] = team)
    resp = request("POST", c, "/api/tournament/$tournament_id/join";
                   body=isempty(body) ? nothing : body)
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body)[:ok]
end

function withdraw_arena(c::LichessClient, tournament_id::String)
    resp = request("POST", c, "/api/tournament/$tournament_id/withdraw")
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    nothing
end

function join_swiss(c::LichessClient, swiss_id::String;
                    password::Union{String,Nothing}=nothing)
    body = isnothing(password) ? nothing : Dict("password" => password)
    resp = request("POST", c, "/api/swiss/$swiss_id/join"; body=body)
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body)[:ok]
end

function withdraw_swiss(c::LichessClient, swiss_id::String)
    resp = request("POST", c, "/api/swiss/$swiss_id/withdraw")
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    nothing
end

end # module
