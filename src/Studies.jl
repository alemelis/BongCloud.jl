module Studies

using ..Types: LichessClient
using ..Client: request

export export_study, export_study_chapter

function export_study(c::LichessClient, study_id::String;
                      clocks::Bool=true, comments::Bool=true,
                      variations::Bool=true, source::Bool=false,
                      orientation::Bool=false)
    q = (clocks=clocks, comments=comments, variations=variations,
         source=source, orientation=orientation)
    resp = request("GET", c, "/api/study/$study_id.pgn"; query=q)
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    String(resp.body)
end

function export_study_chapter(c::LichessClient, study_id::String, chapter_id::String;
                               clocks::Bool=true, comments::Bool=true,
                               variations::Bool=true, source::Bool=false,
                               orientation::Bool=false)
    q = (clocks=clocks, comments=comments, variations=variations,
         source=source, orientation=orientation)
    resp = request("GET", c, "/api/study/$study_id/$chapter_id.pgn"; query=q)
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    String(resp.body)
end

end # module
