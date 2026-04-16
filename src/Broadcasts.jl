module Broadcasts

using JSON3
using ..Types: LichessClient
using ..Client: request, parse_response

export get_official_broadcasts, create_broadcast, push_broadcast_pgn

function get_official_broadcasts(c::LichessClient; nb::Int=20)
    parse_response(request("GET", c, "/api/broadcast"; query=(nb=nb,)), Dict{String,Any})
end

function create_broadcast(c::LichessClient;
                           name::String,
                           description::String,
                           markup::Union{String,Nothing}=nothing,
                           official::Bool=false)
    body = Dict{String,Any}("name" => name, "description" => description,
                             "official" => official)
    isnothing(markup) || (body["markup"] = markup)
    resp = request("POST", c, "/api/broadcast/new"; body=body)
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body, Dict{String,Any})
end

function push_broadcast_pgn(c::LichessClient, round_id::String, pgn::String)
    resp = request("POST", c, "/api/broadcast/round/$round_id/push";
                   body=pgn,
                   headers=Dict("Content-Type" => "text/plain"))
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body, Dict{String,Any})
end

end # module
