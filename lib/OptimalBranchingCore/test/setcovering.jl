using OptimalBranchingCore, GenericTensorNetworks
using Test

@testset "bisect_solve" begin
    f(x) = x^2 - 2
    @test OptimalBranchingCore.bisect_solve(f, 1.0, f(1.0), 2.0, f(2.0)) ≈ sqrt(2)
end

@testset "setcover by JuMP - StaticBitVector type" begin
    tbl = BranchingTable(5, [
        [StaticBitVector([0, 0, 1, 0, 0]), StaticBitVector([0, 1, 0, 0, 0])],
        [StaticBitVector([1, 0, 0, 1, 0])],
        [StaticBitVector([0, 0, 1, 0, 1])]
    ])
    clauses = collect(OptimalBranchingCore.candidate_clauses(tbl))
    Δρ = [count_ones(c.mask) for c in clauses]
    opt_ip, cx_ip = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, IPSolver(; max_itr = 10, verbose = false))
    opt_lp, cx_lp = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, LPSolver(; max_itr = 10, verbose = false))
    @test opt_ip == opt_lp
    @test cx_ip ≈ cx_lp ≈ 1.0

    tbl = BranchingTable(5, [
        [StaticBitVector([0, 1, 0, 1, 0]), StaticBitVector([0, 1, 1, 0, 0])],
        [StaticBitVector([1, 1, 0, 1, 0])],
        [StaticBitVector([0, 0, 1, 0, 1])]
    ])
    clauses = collect(OptimalBranchingCore.candidate_clauses(tbl))
    Δρ = [count_ones(c.mask) for c in clauses]
    result_ip = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, IPSolver(; max_itr = 10, verbose = false))
    result_lp = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, LPSolver(; max_itr = 10, verbose = false))
    @test result_ip.selected_ids == result_lp.selected_ids
    @test result_ip.branching_vector ≈ result_lp.branching_vector
    @test result_ip.γ ≈ result_lp.γ ≈ 1.1673039782614185
end

@testset "setcover by JuMP - normal vector type" begin
    tbl = BranchingTable(5, [
        [[0, 1, 0, 1, 0], [0, 1, 1, 0, 0]],
        [[1, 1, 0, 1, 0]],
        [[0, 0, 1, 0, 1]]
    ])
    clauses = collect(OptimalBranchingCore.candidate_clauses(tbl))
    Δρ = [count_ones(c.mask) for c in clauses]
    result_ip = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, IPSolver(max_itr = 10, verbose = false))
    result_lp = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, LPSolver(max_itr = 10, verbose = false))
    @test result_ip.selected_ids == result_lp.selected_ids
    @test result_ip.branching_vector ≈ result_lp.branching_vector
    @test OptimalBranchingCore.covered_by(tbl, result_ip.optimal_rule)
    @test OptimalBranchingCore.covered_by(tbl, result_lp.optimal_rule)
    @test result_ip.γ ≈ result_lp.γ ≈ 1.1673039782614185
end

@testset "setcover - the corner case (exist a clause that covers all items)" begin
    tbl = BranchingTable(5, [
        [[0, 1, 0, 1, 0], [0, 1, 1, 0, 0]],
        [[1, 1, 0, 1, 0]],
        [[0, 0, 1, 1, 1]]
    ])
    clauses = collect(OptimalBranchingCore.candidate_clauses(tbl))
    Δρ = [count_ones(c.mask) for c in clauses]
    result_ip = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, IPSolver(max_itr = 10, verbose = false))
    @test OptimalBranchingCore.covered_by(tbl, result_ip.optimal_rule)
    @test result_ip.γ ≈ 1.0
end
