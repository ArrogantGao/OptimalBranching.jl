using OptimalBranchingMIS, EliminateGraphs, EliminateGraphs.Graphs
using OptimalBranchingCore
using Test

@testset "mis" begin
    for n in [40]
        for d in [3,4]
            g = random_regular_graph(n, d)

            mis_exact = mis2(EliminateGraph(g))
            p = MISProblem(g)

            for solver in [IPSolver(10, false), LPSolver(10, false)], measure in [D3Measure(), NumOfVertices()], reducer in [MISReducer(), XiaoReducer()], prune_by_env in [true, false]
                bs = BranchingStrategy(TensorNetworkSolver(prune_by_env), solver, MinBoundarySelector(2), measure)

                cfg = SolverConfig(reducer, bs, Int)

                cfg_count = SolverConfig(reducer, bs, MISCount)

                res = reduce_and_branch(p, cfg)
                res_count = reduce_and_branch(p, cfg_count)

                @test res == res_count.mis_size == mis_exact
            end
        end
    end
end