module Board

using JSON3
using ..Types: LichessClient, Event, GameStateEvent, GameFull, GameState, ChatLine
using ..Client: request, request_stream
using ..Bot: _parse_game_event

export stream_board_events, stream_board_game,
       board_make_move, board_seek, board_abort, board_resign, board_chat

const CHANNEL_BUFFER = 64

function stream_board_events(c::LichessClient)
    Channel{Event}(CHANNEL_BUFFER) do ch
        request_stream(c, "/api/stream/event") do line
            put!(ch, JSON3.read(line, Event))
        end
    end
end

function stream_board_game(c::LichessClient, game_id::String)
    Channel{GameStateEvent}(CHANNEL_BUFFER) do ch
        request_stream(c, "/api/board/game/stream/$game_id") do line
            put!(ch, _parse_game_event(line))
        end
    end
end

function board_make_move(c::LichessClient, game_id::String, move::String;
                         offering_draw::Bool=false)
    resp = request("POST", c, "/api/board/game/$game_id/move/$move";
                   query=(offeringDraw=offering_draw,))
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body)[:ok]
end

function board_seek(c::LichessClient;
                    rated::Bool=false, time::Int=10, increment::Int=0,
                    color::String="random", variant::String="standard",
                    ratingRange::Union{String,Nothing}=nothing)
    q = (rated=rated, time=time, increment=increment, color=color,
         variant=variant, ratingRange=ratingRange)
    resp = request("POST", c, "/api/board/seek"; query=q)
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    nothing
end

function board_abort(c::LichessClient, game_id::String)
    resp = request("POST", c, "/api/board/game/$game_id/abort")
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body)[:ok]
end

function board_resign(c::LichessClient, game_id::String)
    resp = request("POST", c, "/api/board/game/$game_id/resign")
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body)[:ok]
end

function board_chat(c::LichessClient, game_id::String, room::String, text::String)
    resp = request("POST", c, "/api/board/game/$game_id/chat";
                   body=(room=room, text=text))
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body)[:ok]
end

end # module
