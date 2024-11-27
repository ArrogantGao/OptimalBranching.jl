using EliminateGraphs, EliminateGraphs.Graphs
using Test

using OptimalBranchingMIS: find_children, unconfined_vertices, is_line_graph, first_twin, twin_filter!, short_funnel_filter!, desk_filter!, effective_vertex, all_three_funnel, all_four_funnel, rho, optimal_four_cycle, optimal_vertex, has_fine_structure, count_o_path, closed_neighbors, is_complete_graph

function graph_from_edges(edges)
    return SimpleGraph(Graphs.SimpleEdge.(edges))
end

@testset "find_children" begin
    g = graph_from_edges([(1,2),(2,3), (1,4), (2,5), (3,5)])
    @test find_children(g, [1]) == [2, 4]
    @test find_children(g, [1,2,3]) == [4]
end

@testset "line graph" begin
    edges = [(1,2),(1,4),(1,5),(2,3),(2,4),(2,5),(3,4),(3,5)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    @test is_lg = is_line_graph(example_g) == true

    edges = [(1,2),(1,4),(1,5),(2,3),(2,4),(2,5),(3,4),(3,5),(4,5)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    @test is_lg = is_line_graph(example_g) == false
end


@testset "confined set and unconfined vertices" begin
    # via dominated rule
    g = graph_from_edges([(1,2),(1,3),(1, 4), (2, 3), (2, 4), (2, 6), (3, 5), (4, 5)])
    @test unconfined_vertices(g) == [2]
    
    # via roof
    g = graph_from_edges([(1, 2), (1, 5), (1, 6), (2, 5), (2, 3), (4, 5), (3, 4), (3, 7), (4, 7)])
    @test in(1, unconfined_vertices(g))
end


@testset "twin" begin
    # xiao2013 fig.2(a)
    edges = [(1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (4, 5), (3, 6), (3, 7), (4, 8), (5, 9), (5, 10)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    @test first_twin(example_g) == (1, 2)
    @test twin_filter!(example_g)
    @test ne(example_g) == 0
    @test nv(example_g) == 5

    #xiao2013 fig.2(b)
    edges = [(1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 6), (3, 7), (4, 8), (5, 9), (5, 10)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    @test first_twin(example_g) == (1, 2)
    @test twin_filter!(example_g)
    @test ne(example_g) == 5
    @test nv(example_g) == 6
end



@testset "short funnel" begin
    edges = [(1, 2), (1, 4), (1, 5), (2, 3), (2, 6), (3, 6), (4, 6)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    @test short_funnel_filter!(example_g)
    @test example_g == SimpleGraph{Int64}(5, [[2, 3, 4], [1, 3], [1, 2, 4], [1, 3]])

    # xiao2013 fig.2(c)
    edges = [(1, 2), (1, 3), (1, 4), (2, 5), (2, 6), (3, 4), (3, 7), (4, 5), (4, 8), (5, 10), (6, 9)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    @test short_funnel_filter!(example_g)
    @test nv(example_g) == 8
    @test ne(example_g) == 9
end


@testset "desk" begin
    edges = [(1, 2), (1, 4), (1, 8), (2, 3), (2, 7), (3, 8), (5, 7), (6, 8), (7, 8)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    @test desk_filter!(example_g)
    @test example_g == SimpleGraph{Int64}(4, [[2, 4], [1, 3], [2, 4], [1, 3]])

    #xiao2013 fig.2(d)
    edges = [(1, 2), (1, 4), (1, 5), (2, 3), (2, 6), (3, 4), (3, 5), (3, 7), (4, 8), (5, 9), (6, 10), (7, 11), (8, 12)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    @test desk_filter!(example_g)
    @test nv(example_g) == 8
    @test ne(example_g) == 8
end


@testset "effective vertex" begin
    function is_effective_vertex(g::SimpleGraph, a::Int, S_a::Vector{Int})
        g_copy = copy(g)
        rem_vertices!(g_copy, closed_neighbors(g, S_a))
        degree(g,a) == 3 && all(degree(g,n) == 3 for n in neighbors(g,a)) && rho(g) - rho(g_copy) >= 20
    end

    g = random_regular_graph(1000, 3)
    a, S_a = effective_vertex(g)
    @test is_effective_vertex(g, a, S_a)
end

@testset "funnel" begin
    function is_n_funnel(g::SimpleGraph, n::Int, a::Int, b::Int)
        degree(g,a) == n && is_complete_graph(g, setdiff(neighbors(g,a), [b]))
    end

    edges = [(1, 2), (1, 3), (1, 4), (3, 4)]
    g = SimpleGraph(Graphs.SimpleEdge.(edges))
    three_funnels = all_three_funnel(g)
    @test three_funnels == [(1, 2)]
    @test is_n_funnel(g, 3, 1, 2)

    edges = [(1, 2), (1, 3), (1, 4), (1, 5), (3, 4), (3, 5), (4, 5)]
    g = SimpleGraph(Graphs.SimpleEdge.(edges))
    four_funnels = all_four_funnel(g)
    @test four_funnels == [(1, 2)]
    @test is_n_funnel(g, 4, 1, 2)
end

@testset "o_path" begin
    edges = [(1, 2), (2, 3), (3, 4), (1, 5), (1, 6), (3, 7)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    o_path_num = count_o_path(example_g)
    @test o_path_num == 1

    edges = [(1, 2), (2, 3), (3, 4), (1, 5), (1, 6), (4, 7),(4, 8)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    o_path_num = count_o_path(example_g)
    @test o_path_num == 0
end

@testset "fine_structure" begin
    edges = [(1, 2), (2, 3), (3, 4), (1, 5), (1, 6), (3, 7)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    @test has_fine_structure(example_g) == true

    edges = [(1, 2), (1, 3), (1, 4), (2, 3), (2, 7), (3, 8), (4, 5), (4, 6)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    @test has_fine_structure(example_g) == true

    edges = [(1, 2), (2, 3), (3, 4), (1, 5), (1, 6), (4, 7),(4, 8)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    @test has_fine_structure(example_g) == false
end

@testset "four_cycle" begin
    edges = [(1, 2), (2, 3), (3, 4), (4, 1), (1, 5)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    opt_quad = optimal_four_cycle(example_g)
    @test opt_quad == [1, 2, 3, 4]

    edges = [(1, 2), (2, 3), (3, 4), (4, 1), (3, 5), (4, 6), (5, 6), (1, 7)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    opt_quad = optimal_four_cycle(example_g)
    @test opt_quad == [1, 2, 3, 4]
end

@testset "optimal vertex" begin
    edges = [(1, 2), (2, 6), (1, 3), (3, 7), (1, 4), (4, 8), (1, 5), (5, 9)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    v = optimal_vertex(example_g)
    @test v == 1
end

@testset "xiao2013" begin
    for seed in 10:2:100
        g = random_regular_graph(seed, 3)
        eg = EliminateGraph(g)
        mis_size_standard = mis2(eg)
        mis_size = counting_xiao2013(g).mis_size
        @test mis_size_standard == mis_size
    end
end