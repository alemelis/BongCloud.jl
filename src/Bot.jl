module Bot

using JSON3
using ..Types: LichessClient, Event, GameStateEvent, GameFull, GameState, ChatLine, UnknownGameEvent
using ..Client: request, request_stream, parse_response

export upgrade_to_bot, get_online_bots, stream_events,
    stream_game, make_move, abort_game, resign_game, send_chat

const CHANNEL_BUFFER = 64

function upgrade_to_bot(c::LichessClient)
    resp = request("POST", c, "/api/bot/account/upgrade")
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body)[:ok]
end

function get_online_bots(c::LichessClient; nb=50)
    Channel{Dict{String,Any}}(CHANNEL_BUFFER) do ch
        request_stream(c, "/api/bot/online"; query=(nb=nb,)) do line
            put!(ch, JSON3.read(line, Dict{String,Any}))
        end
    end
end

function stream_events(c::LichessClient)
    Channel{Event}(CHANNEL_BUFFER) do ch
        request_stream(c, "/api/stream/event") do line
            try
                put!(ch, JSON3.read(line, Event))
            catch e
                # Parse failed — emit a bare Event so the caller can at least see the type
                raw = try
                    JSON3.read(line)
                catch
                    nothing
                end
                t = raw !== nothing ? string(get(raw, :type, "unknown")) : "unknown"
                @warn "stream_events: failed to parse event type=$t line=$(first(line,200))" exception = e
                try
                    put!(ch, Event(t, nothing, nothing))
                catch
                end
            end
        end
    end
end

function _parse_game_event(line::String)::GameStateEvent
    obj = JSON3.read(line)
    t = get(obj, :type, nothing)
    if t == "gameFull"
        return JSON3.read(line, GameFull)
    elseif t == "gameState"
        return JSON3.read(line, GameState)
    elseif t == "chatLine"
        return JSON3.read(line, ChatLine)
    else
        @debug "Ignoring game event type=$t"
        return UnknownGameEvent(string(t), obj)
    end
end

function stream_game(c::LichessClient, game_id::String)
    Channel{GameStateEvent}(CHANNEL_BUFFER) do ch
        request_stream(c, "/api/bot/game/stream/$game_id") do line
            put!(ch, _parse_game_event(line))
        end
    end
end

function make_move(c::LichessClient, game_id::String, move::String;
    offering_draw::Bool=false)
    resp = request("POST", c, "/api/bot/game/$game_id/move/$move";
        query=(offeringDraw=offering_draw,))
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body)[:ok]
end

function abort_game(c::LichessClient, game_id::String)
    resp = request("POST", c, "/api/bot/game/$game_id/abort")
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body)[:ok]
end

function resign_game(c::LichessClient, game_id::String)
    resp = request("POST", c, "/api/bot/game/$game_id/resign")
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body)[:ok]
end

function send_chat(c::LichessClient, game_id::String, room::String, text::String)
    resp = request("POST", c, "/api/bot/game/$game_id/chat";
        body=(room=room, text=text))
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body)[:ok]
end

end # module
