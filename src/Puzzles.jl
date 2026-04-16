module Puzzles

using JSON3
using ..Types: LichessClient, Puzzle
using ..Client: request, request_stream, parse_response

export get_daily_puzzle, get_puzzle, get_puzzle_activity, get_puzzle_dashboard

const CHANNEL_BUFFER = 64

get_daily_puzzle(c::LichessClient) =
    parse_response(request("GET", c, "/api/puzzle/daily"), Puzzle)

get_puzzle(c::LichessClient, puzzle_id::String) =
    parse_response(request("GET", c, "/api/puzzle/$puzzle_id"), Puzzle)

function get_puzzle_activity(c::LichessClient; max::Union{Int,Nothing}=nothing,
                              before::Union{Int,Nothing}=nothing)
    Channel{Dict{String,Any}}(CHANNEL_BUFFER) do ch
        request_stream(c, "/api/puzzle/activity"; query=(max=max, before=before)) do line
            put!(ch, JSON3.read(line, Dict{String,Any}))
        end
    end
end

get_puzzle_dashboard(c::LichessClient, days::Int) =
    parse_response(request("GET", c, "/api/puzzle/dashboard/$days"), Dict{String,Any})

end # module
