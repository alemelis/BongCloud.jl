## Integration tests against the live Lichess API.
##
## Run with:
##   julia --project=. test/integration.jl
##
## All tests use public, unauthenticated endpoints so no token is needed.
## Tests that require a token are skipped unless LICHESS_TOKEN is set.
##
## Design: fetch shared fixtures once, reuse across testsets to minimise API hits.

using BongCloud
using Test

const CLIENT = LichessClient()
const AUTH_CLIENT = let t = get(ENV, "LICHESS_TOKEN", nothing)
    isnothing(t) ? nothing : LichessClient(token=t)
end

println("Running BongCloud.jl integration tests against lichess.org…")
println("Auth client: ", isnothing(AUTH_CLIENT) ? "not available (set LICHESS_TOKEN)" : "available")
println()

# ── Shared fixtures (fetched once) ───────────────────────────────────────────

# Drain a Channel into a Vector, taking at most `n` items.
function take_n(ch::Channel, n::Int)
    out = []
    for item in ch
        push!(out, item)
        length(out) >= n && break
    end
    out
end

println("Fetching shared fixtures…")
const SAMPLE_USER = get_user(CLIENT, "DrNykterstein")
const SAMPLE_GAMES = take_n(export_user_games(CLIENT, "DrNykterstein"; max=3, perfType="blitz"), 3)
const DAILY_PUZZLE = get_daily_puzzle(CLIENT)
println("Fixtures ready. game IDs: ", [g.id for g in SAMPLE_GAMES])
println()

# ── Users ─────────────────────────────────────────────────────────────────────

@testset "Users" begin
    @testset "get_user" begin
        @test SAMPLE_USER.username == "DrNykterstein"
        @test SAMPLE_USER.id == "drnykterstein"
        @test !isnothing(SAMPLE_USER.perfs)
    end

    @testset "get_users_status" begin
        statuses = get_users_status(CLIENT, ["DrNykterstein", "MagnusCarlsen"])
        @test length(statuses) >= 1
        ids = [s.id for s in statuses]
        @test "drnykterstein" in ids || "magnuscarlsen" in ids
    end

    @testset "get_leaderboard" begin
        lb = get_leaderboard(CLIENT, 5, "bullet")
        @test haskey(lb, "users")
        @test length(lb["users"]) == 5
    end

    @testset "get_user_rating_history" begin
        hist = get_user_rating_history(CLIENT, "DrNykterstein")
        @test isa(hist, Vector)
        @test length(hist) >= 1
        @test haskey(hist[1], "name")
        @test haskey(hist[1], "points")
    end

    @testset "get_users_by_ids" begin
        users = get_users_by_ids(CLIENT, ["DrNykterstein", "MagnusCarlsen"])
        @test length(users) == 2
        ids = [u.id for u in users]
        @test "drnykterstein" in ids
        @test "magnuscarlsen" in ids
    end
end

# ── Games ─────────────────────────────────────────────────────────────────────

@testset "Games" begin
    @testset "export_user_games streaming" begin
        @test length(SAMPLE_GAMES) >= 1
        @test all(g -> !isnothing(g.id), SAMPLE_GAMES)
    end

    @testset "export_game" begin
        gid = SAMPLE_GAMES[1].id
        g = export_game(CLIENT, gid; moves=true)
        @test g.id == gid
        @test !isnothing(g.moves)
        @test !isempty(g.moves)
    end

    @testset "export_games_by_ids" begin
        gid = SAMPLE_GAMES[1].id
        ch = export_games_by_ids(CLIENT, [gid]; moves=false)
        games = take_n(ch, 5)
        @test length(games) == 1
        @test games[1].id == gid
    end

    @testset "get_tv_games" begin
        tv = get_tv_games(CLIENT)
        @test isa(tv, Dict)
        @test any(k -> k in ("bullet", "blitz", "best", "classical", "chess960"), keys(tv))
    end
end

# ── Puzzles ───────────────────────────────────────────────────────────────────

@testset "Puzzles" begin
    @testset "get_daily_puzzle" begin
        @test isa(DAILY_PUZZLE.puzzle.id, String)
        @test !isempty(DAILY_PUZZLE.puzzle.id)
        @test DAILY_PUZZLE.puzzle.rating > 0
        @test length(DAILY_PUZZLE.puzzle.solution) >= 1
    end

    @testset "get_puzzle by id" begin
        p = get_puzzle(CLIENT, DAILY_PUZZLE.puzzle.id)
        @test p.puzzle.id == DAILY_PUZZLE.puzzle.id
    end
end

# ── Analysis ──────────────────────────────────────────────────────────────────

@testset "Analysis" begin
    @testset "get_cloud_eval" begin
        fen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1"
        result = get_cloud_eval(CLIENT, fen; multi_pv=2)
        @test isa(result, Dict)
        @test haskey(result, "pvs") || haskey(result, "error")
    end
end

# ── Opening Explorer ──────────────────────────────────────────────────────────

@testset "Explorer" begin
    # explorer.lichess.ovh requires a valid token as of 2026
    if !isnothing(AUTH_CLIENT)
        fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

        @testset "get_masters_db" begin
            r = get_masters_db(AUTH_CLIENT, fen; moves=5)
            @test haskey(r, "moves")
            @test length(r["moves"]) >= 1
        end

        @testset "get_lichess_db" begin
            r = get_lichess_db(AUTH_CLIENT, fen; speeds=["bullet", "blitz"], moves=5)
            @test haskey(r, "moves")
            @test length(r["moves"]) >= 1
        end

        @testset "get_player_db" begin
            r = get_player_db(AUTH_CLIENT, fen, "DrNykterstein"; color="white", moves=5)
            @test haskey(r, "moves")
        end
    else
        @test_skip "LICHESS_TOKEN not set — skipping explorer tests"
    end
end

# ── Account (auth required) ───────────────────────────────────────────────────

@testset "Account" begin
    if !isnothing(AUTH_CLIENT)
        @testset "get_profile" begin
            p = get_profile(AUTH_CLIENT)
            @test isa(p, Dict)
            @test haskey(p, "id")
        end

        @testset "get_email" begin
            email = get_email(AUTH_CLIENT)
            @test isa(email, String)
            @test occursin("@", email)
        end

        @testset "get_preferences" begin
            prefs = get_preferences(AUTH_CLIENT)
            @test isa(prefs, Dict)
        end

        @testset "get_kid_mode" begin
            kid = get_kid_mode(AUTH_CLIENT)
            @test isa(kid, Bool)
        end
    else
        @test_skip "LICHESS_TOKEN not set — skipping account tests"
    end
end

println("\nDone.")
