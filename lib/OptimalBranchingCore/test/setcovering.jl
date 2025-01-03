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
    clauses = OptimalBranchingCore.candidate_clauses(tbl)
    Δρ = [count_ones(c.mask) for c in clauses]
    result_ip = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, IPSolver(; max_itr = 10, verbose = false))
    result_lp = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, LPSolver(; max_itr = 10, verbose = false))
    @test result_ip.selected_ids == result_lp.selected_ids
    @test result_ip.branching_vector ≈ result_lp.branching_vector
    @test result_ip.γ ≈ result_lp.γ ≈ 1.0

    tbl = BranchingTable(5, [
        [StaticBitVector([0, 1, 0, 1, 0]), StaticBitVector([0, 1, 1, 0, 0])],
        [StaticBitVector([1, 1, 0, 1, 0])],
        [StaticBitVector([0, 0, 1, 0, 1])]
    ])
    clauses = OptimalBranchingCore.candidate_clauses(tbl)
    Δρ = [count_ones(c.mask) for c in clauses]
    result_ip = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, IPSolver(; max_itr = 10, verbose = false))
    result_lp = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, LPSolver(; max_itr = 10, verbose = false))
    @test result_ip.selected_ids == result_lp.selected_ids
    @test result_ip.branching_vector ≈ result_lp.branching_vector
    @test result_ip.γ ≈ result_lp.γ ≈ 1.1673039782614185

    println(result_ip)
    println(result_lp)
end

@testset "setcover by JuMP - normal vector type" begin
    tbl = BranchingTable(5, [
        [[0, 1, 0, 1, 0], [0, 1, 1, 0, 0]],
        [[1, 1, 0, 1, 0]],
        [[0, 0, 1, 0, 1]]
    ])
    clauses = OptimalBranchingCore.candidate_clauses(tbl)
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
    clauses = OptimalBranchingCore.candidate_clauses(tbl)
    Δρ = [count_ones(c.mask) for c in clauses]
    result_ip = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, IPSolver(max_itr = 10, verbose = false))
    @test OptimalBranchingCore.covered_by(tbl, result_ip.optimal_rule)
    @test result_ip.γ ≈ 1.0
end

@testset "covered_by" begin
    tbl = BranchingTable(9, [
        [[0,0,0,0,0,1,1,0,0], [0,0,0,0,0,0,1,1,0]],
        [[0,0,0,0,1,1,1,0,0]],
        [[0,0,1,1,0,0,0,0,1], [0,0,1,1,0,1,0,0,0], [0,0,1,1,0,0,0,1,0]],
        [[0,0,1,1,1,0,0,0,1], [0,0,1,1,1,1,0,0,0]],
        [[0,1,0,0,0,0,1,1,0]],
        [[0,1,0,1,1,0,0,0,1]],
        [[0,1,1,0,1,0,0,0,1]],
        [[0,1,1,1,0,0,0,0,1], [0,1,1,1,0,0,0,1,0]],
        [[0,1,1,1,1,0,0,0,1]],
        [[1,0,0,0,0,0,1,1,0]],
        [[1,0,0,1,1,0,0,0,1]],
        [[1,0,1,0,1,0,0,0,1]],
        [[1,0,1,1,0,0,0,0,1], [1,0,1,1,0,0,0,1,0]],
        [[1,0,1,1,1,0,0,0,1]],
        [[1,1,0,0,0,0,1,1,0]],
        [[1,1,0,1,1,0,0,0,1]],
        [[1,1,1,0,1,0,0,0,1]],
        [[1,1,1,1,0,0,0,0,1], [1,1,1,1,0,0,0,1,0]],
        [[1,1,1,1,1,0,0,0,1]]
    ])
    clauses = OptimalBranchingCore.candidate_clauses(tbl)
    Δρ = [count_ones(c.mask) for c in clauses]
    result_ip = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, IPSolver(max_itr = 10, verbose = false))
    @test OptimalBranchingCore.covered_by(tbl, result_ip.optimal_rule)

    cls = OptimalBranchingCore.bit_clauses(tbl)
    clsf = OptimalBranchingCore.greedymerge(cls, p, [1, 2, 3, 4, 5], D3Measure())
    @test OptimalBranchingCore.covered_by(tbl, DNF(clsf))
end
