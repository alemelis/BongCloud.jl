module Analysis

using JSON3
using ..Types: LichessClient
using ..Client: request, parse_response

export get_cloud_eval

function get_cloud_eval(c::LichessClient, fen::String;
                        multi_pv::Int=1,
                        variant::String="standard")
    q = (fen=fen, multiPv=multi_pv, variant=variant)
    parse_response(request("GET", c, "/api/cloud-eval"; query=q), Dict{String,Any})
end

end # module
