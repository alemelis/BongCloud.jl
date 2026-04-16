module Games

using JSON3
using ..Types: LichessClient, Game
using ..Client: request, request_stream, parse_response

export export_game, export_user_games, export_games_by_ids,
       get_playing, stream_users_games, get_tv_games

const CHANNEL_BUFFER = 64

function export_game(c::LichessClient, game_id::String;
                     moves=true, pgn=false, tags=true, clocks=false,
                     evals=false, opening=false, literate=false)
    q = (moves=moves, pgnInJson=pgn, tags=tags, clocks=clocks,
         evals=evals, opening=opening, literate=literate)
    parse_response(request("GET", c, "/game/export/$game_id"; query=q,
                           headers=Dict("Accept" => "application/json")), Game)
end

function export_user_games(c::LichessClient, username::String;
                           since=nothing, until=nothing, max=nothing,
                           vs=nothing, rated=nothing, perfType=nothing,
                           color=nothing, analysed=nothing,
                           moves=true, pgn=false, tags=true, clocks=false,
                           evals=false, opening=false, ongoing=false, finished=true)
    q = (since=since, until=until, max=max, vs=vs, rated=rated,
         perfType=perfType, color=color, analysed=analysed,
         moves=moves, pgnInJson=pgn, tags=tags, clocks=clocks,
         evals=evals, opening=opening, ongoing=ongoing, finished=finished)
    Channel{Game}(CHANNEL_BUFFER) do ch
        request_stream(c, "/api/games/user/$username"; query=q,
                       headers=Dict("Accept" => "application/x-ndjson")) do line
            put!(ch, JSON3.read(line, Game))
        end
    end
end

function export_games_by_ids(c::LichessClient, ids::Vector{String};
                              moves=true, pgn=false, tags=true, clocks=false,
                              evals=false, opening=false)
    q = (moves=moves, pgnInJson=pgn, tags=tags, clocks=clocks,
         evals=evals, opening=opening)
    Channel{Game}(CHANNEL_BUFFER) do ch
        # POST with newline-separated IDs
        url_path = "/api/games/export/_ids"
        body_str = join(ids, ",")
        resp = request("POST", c, url_path;
                       query=q,
                       body=body_str,
                       headers=Dict("Content-Type" => "text/plain",
                                    "Accept" => "application/x-ndjson"))
        resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
        for line in split(String(resp.body), "\n")
            isempty(strip(line)) && continue
            put!(ch, JSON3.read(line, Game))
        end
    end
end

function get_playing(c::LichessClient, users::Vector{String})
    ids = join(users, ",")
    parse_response(request("GET", c, "/api/users/playing"; query=(ids=ids,)),
                   Dict{String, Any})
end

function stream_users_games(c::LichessClient, users::Vector{String})
    ids = join(users, ",")
    Channel{Game}(CHANNEL_BUFFER) do ch
        request_stream(c, "/api/stream/games-by-users";
                       headers=Dict("Accept" => "application/x-ndjson")) do line
            put!(ch, JSON3.read(line, Game))
        end
    end
end

get_tv_games(c::LichessClient) =
    parse_response(request("GET", c, "/api/tv/channels"), Dict{String, Any})

end # module
