module Challenges

using JSON3
using ..Types: LichessClient, ChallengeInfo
using ..Client: request, parse_response

export create_challenge, create_open_challenge, list_challenges,
       accept_challenge, decline_challenge, cancel_challenge

function create_challenge(c::LichessClient, username::String;
                          rated::Bool=false,
                          clock_limit::Union{Int,Nothing}=nothing,
                          clock_increment::Int=0,
                          days::Union{Int,Nothing}=nothing,
                          color::String="random",
                          variant::String="standard",
                          fen::Union{String,Nothing}=nothing)
    body = Dict{String,Any}(
        "rated" => rated,
        "color" => color,
        "variant" => variant,
    )
    if !isnothing(clock_limit)
        body["clock.limit"] = clock_limit
        body["clock.increment"] = clock_increment
    elseif !isnothing(days)
        body["days"] = days
    end
    isnothing(fen) || (body["fen"] = fen)

    resp = request("POST", c, "/api/challenge/$username"; body=body)
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body, Dict{String,Any})
end

function create_open_challenge(c::LichessClient;
                               rated::Bool=false,
                               clock_limit::Union{Int,Nothing}=nothing,
                               clock_increment::Int=0,
                               days::Union{Int,Nothing}=nothing,
                               variant::String="standard",
                               fen::Union{String,Nothing}=nothing,
                               name::Union{String,Nothing}=nothing)
    body = Dict{String,Any}("rated" => rated, "variant" => variant)
    if !isnothing(clock_limit)
        body["clock.limit"] = clock_limit
        body["clock.increment"] = clock_increment
    elseif !isnothing(days)
        body["days"] = days
    end
    isnothing(fen) || (body["fen"] = fen)
    isnothing(name) || (body["name"] = name)

    resp = request("POST", c, "/api/challenge/open"; body=body)
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body, Dict{String,Any})
end

function list_challenges(c::LichessClient)
    parse_response(request("GET", c, "/api/challenge"), Dict{String,Any})
end

function accept_challenge(c::LichessClient, challenge_id::String)
    resp = request("POST", c, "/api/challenge/$challenge_id/accept")
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body)[:ok]
end

function decline_challenge(c::LichessClient, challenge_id::String;
                           reason::String="generic")
    resp = request("POST", c, "/api/challenge/$challenge_id/decline";
                   body=Dict("reason" => reason))
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body)[:ok]
end

function cancel_challenge(c::LichessClient, challenge_id::String)
    resp = request("POST", c, "/api/challenge/$challenge_id/cancel")
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body)[:ok]
end

end # module
