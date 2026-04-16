module Client

using HTTP, JSON3
using ..Types: LichessClient, auth_headers, api_url

export request, request_stream

const RETRY_DELAYS = [1.0, 2.0, 4.0, 8.0]  # seconds, exponential backoff

function request(method::String, client::LichessClient, path::String;
                 query=nothing, body=nothing, headers=Dict{String,String}())
    url = api_url(client, path)
    h = merge(auth_headers(client), headers)

    if !isnothing(query)
        params = join(["$k=$(HTTP.escapeuri(string(v)))" for (k,v) in pairs(query) if !isnothing(v)], "&")
        isempty(params) || (url = "$url?$params")
    end

    for (attempt, delay) in enumerate([0.0; RETRY_DELAYS])
        attempt > 1 && sleep(delay)
        resp = if isnothing(body)
            HTTP.request(method, url, h; status_exception=false)
        elseif isa(body, String)
            # raw string body — caller is responsible for Content-Type header
            HTTP.request(method, url, h, body; status_exception=false)
        else
            # NamedTuple / Dict body — form-encode it
            form_h = haskey(h, "Content-Type") ? h :
                     merge(h, Dict("Content-Type" => "application/x-www-form-urlencoded"))
            HTTP.request(method, url, form_h,
                         HTTP.escapeuri(body); status_exception=false)
        end

        resp.status == 429 && continue
        resp.status >= 500 && attempt <= length(RETRY_DELAYS) && continue
        return resp
    end
    error("Request to $url failed after retries")
end

# Yields lines from an NDJSON stream; caller wraps in Channel.
# f is the first argument so callers can use do-block syntax:
#   request_stream(c, path; query=...) do line ... end
function request_stream(f, client::LichessClient, path::String;
                        query=nothing, headers=Dict{String,String}())
    url = api_url(client, path)
    h = merge(auth_headers(client), headers)

    if !isnothing(query)
        params = join(["$k=$(HTTP.escapeuri(string(v)))" for (k,v) in pairs(query) if !isnothing(v)], "&")
        isempty(params) || (url = "$url?$params")
    end

    # BufferStream blocks readers until data arrives; HTTP.request writes
    # to it (with decompression handled by HTTP.jl middleware).
    stream = Base.BufferStream()
    task = @async begin
        try
            HTTP.request("GET", url, h; response_stream=stream, status_exception=false)
        finally
            close(stream)
        end
    end

    for line in eachline(stream)
        isempty(strip(line)) || f(line)
    end

    wait(task)
end

function parse_response(resp::HTTP.Response, ::Type{T}) where T
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    JSON3.read(resp.body, T)
end

function parse_response(resp::HTTP.Response, ::Type{Nothing})
    resp.status >= 400 && error("HTTP $(resp.status): $(String(resp.body))")
    nothing
end

end # module
