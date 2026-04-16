module Explorer

using JSON3
using ..Types: LichessClient, explorer_url, auth_headers
import HTTP

export get_masters_db, get_lichess_db, get_player_db

function _explorer_request(c::LichessClient, path::String; query=nothing)
    url = explorer_url(c, path)
    h = auth_headers(c)

    if !isnothing(query)
        params = join(["$k=$(HTTP.escapeuri(string(v)))"
                       for (k,v) in pairs(query) if !isnothing(v)], "&")
        isempty(params) || (url = "$url?$params")
    end

    resp = HTTP.request("GET", url, h; status_exception=false)
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body, Dict{String,Any})
end

function get_masters_db(c::LichessClient, fen::String;
                        play::Union{String,Nothing}=nothing,
                        since::Union{Int,Nothing}=nothing,
                        until::Union{Int,Nothing}=nothing,
                        moves::Int=12,
                        top_games::Int=15)
    _explorer_request(c, "/masters";
                      query=(fen=fen, play=play, since=since, until=until,
                             moves=moves, topGames=top_games))
end

function get_lichess_db(c::LichessClient, fen::String;
                        play::Union{String,Nothing}=nothing,
                        since::Union{String,Nothing}=nothing,
                        until::Union{String,Nothing}=nothing,
                        moves::Int=12,
                        top_games::Int=4,
                        recent_games::Int=4,
                        ratings::Union{Vector{Int},Nothing}=nothing,
                        speeds::Union{Vector{String},Nothing}=nothing,
                        variant::String="standard")
    q = Dict{Symbol,Any}(
        :fen => fen, :play => play, :since => since, :until => until,
        :moves => moves, :topGames => top_games, :recentGames => recent_games,
        :variant => variant,
    )
    isnothing(ratings) || (q[:ratings] = join(ratings, ","))
    isnothing(speeds) || (q[:speeds] = join(speeds, ","))
    _explorer_request(c, "/lichess"; query=q)
end

function get_player_db(c::LichessClient, fen::String, username::String;
                       play::Union{String,Nothing}=nothing,
                       since::Union{String,Nothing}=nothing,
                       until::Union{String,Nothing}=nothing,
                       moves::Int=12,
                       recent_games::Int=8,
                       color::String="white",
                       speeds::Union{Vector{String},Nothing}=nothing,
                       modes::Union{Vector{String},Nothing}=nothing,
                       variant::String="standard")
    q = Dict{Symbol,Any}(
        :fen => fen, :player => username, :play => play,
        :since => since, :until => until, :moves => moves,
        :recentGames => recent_games, :color => color, :variant => variant,
    )
    isnothing(speeds) || (q[:speeds] = join(speeds, ","))
    isnothing(modes) || (q[:modes] = join(modes, ","))
    _explorer_request(c, "/player"; query=q)
end

end # module
