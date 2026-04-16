module Users

using JSON3
using ..Types: LichessClient, User, UserStatus, Activity
using ..Client: request, request_stream, parse_response

export get_user, get_user_rating_history, get_users_status,
       get_leaderboard, get_user_activity, get_users_by_ids

get_user(c::LichessClient, username::String) =
    parse_response(request("GET", c, "/api/user/$username"), User)

get_user_rating_history(c::LichessClient, username::String) =
    parse_response(request("GET", c, "/api/user/$username/rating-history"), Vector{Any})

function get_users_status(c::LichessClient, ids::Vector{String};
                          withGameIds::Bool=false, withGameMeta::Bool=false)
    q = (ids=join(ids, ","), withGameIds=withGameIds, withGameMeta=withGameMeta)
    parse_response(request("GET", c, "/api/users/status"; query=q), Vector{UserStatus})
end

get_leaderboard(c::LichessClient, nb::Int, perf_type::String) =
    parse_response(request("GET", c, "/api/player/top/$nb/$perf_type"), Dict{String, Any})

function get_user_activity(c::LichessClient, username::String)
    parse_response(request("GET", c, "/api/user/$username/activity"), Vector{Any})
end

function get_users_by_ids(c::LichessClient, ids::Vector{String})
    body = join(ids, ",")
    resp = request("POST", c, "/api/users"; body=body,
                   headers=Dict("Content-Type" => "text/plain"))
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body, Vector{User})
end

end # module
