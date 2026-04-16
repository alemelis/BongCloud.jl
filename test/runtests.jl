using BongCloud
using Test

@testset "BongCloud.jl" begin

    @testset "LichessClient" begin
        c = LichessClient()
        @test isnothing(c.token)
        @test c.base_url == "https://lichess.org"
        @test c.explorer_url == "https://explorer.lichess.ovh"

        c2 = LichessClient(token="lip_test")
        @test c2.token == "lip_test"

        h = BongCloud.Types.auth_headers(c2)
        @test h["Authorization"] == "Bearer lip_test"

        h_anon = BongCloud.Types.auth_headers(c)
        @test isempty(h_anon)
    end

end
