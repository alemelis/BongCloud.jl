module Account

using JSON3
using ..Types: LichessClient
using ..Client: request, parse_response

export get_profile, get_email, get_preferences, get_kid_mode, set_kid_mode

get_profile(c::LichessClient) =
    parse_response(request("GET", c, "/api/account"), Dict{String, Any})

get_email(c::LichessClient) =
    JSON3.read(request("GET", c, "/api/account/email").body)[:email]

get_preferences(c::LichessClient) =
    parse_response(request("GET", c, "/api/account/preferences"), Dict{String, Any})

get_kid_mode(c::LichessClient) =
    JSON3.read(request("GET", c, "/api/account/kid").body)[:kid]

function set_kid_mode(c::LichessClient, enabled::Bool)
    resp = request("POST", c, "/api/account/kid"; query=(v=enabled,))
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body)[:ok]
end

end # module
