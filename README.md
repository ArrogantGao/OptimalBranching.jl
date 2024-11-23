# OptimalBranching.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ArrogantGao.github.io/OptimalBranching.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ArrogantGao.github.io/OptimalBranching.jl/dev/)
[![Build Status](https://github.com/ArrogantGao/OptimalBranching.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ArrogantGao/OptimalBranching.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/ArrogantGao/OptimalBranching.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/ArrogantGao/OptimalBranching.jl)


`OptimalBranching.jl` is a Julia package for automatic generation of optimal branching rule for the branch-and-bound algorithm.
This package only supply an interface for the core algorithm, and the actual implementation of the core algorithm is in `OptimalBranchingCore.jl` and `OptimalBranchingMIS.jl`, which can be found in the `lib` directory of this repository.

## Installation

This package has not been registered yet, so you need to add this repository manually.

```bash
git clone https://github.com/ArrogantGao/OptimalBranching.jl
cd OptimalBranching.jl
make
```

This will add the submodules `OptimalBranchingCore.jl` and `OptimalBranchingMIS.jl` and install the dependencies, the tests will be run automatically to ensure everything is fine.

## Example

This package currently provides an implementation of the branching algorithm for the Maximum Independent Set (MIS) problem, an example is shown below:
```julia
julia> using OptimalBranching, Graphs

# define a problem, for MIS the problem is just a graph
julia> g = random_regular_graph(20, 3)
{20, 30} undirected simple Int64 graph

julia> problem = MISProblem(g)
MISProblem(20)

# select the branching strategy
julia> branching_strategy = OptBranchingStrategy(TensorNetworkSolver(), IPSolver(), EnvFilter(), MinBoundarySelector(2), D3Measure())
OptBranchingStrategy{TensorNetworkSolver, IPSolver, EnvFilter, MinBoundarySelector, D3Measure}(TensorNetworkSolver(), IPSolver(10), EnvFilter(), MinBoundarySelector(2), D3Measure())

julia> config = SolverConfig(MISReducer(), branching_strategy, MISSize)
SolverConfig{MISReducer, OptBranchingStrategy{TensorNetworkSolver, IPSolver, EnvFilter, MinBoundarySelector, D3Measure}, MISSize}(MISReducer(), OptBranchingStrategy{TensorNetworkSolver, IPSolver, EnvFilter, MinBoundarySelector, D3Measure}(TensorNetworkSolver(), IPSolver(10), EnvFilter(), MinBoundarySelector(2), D3Measure()), MISSize)

# the result shows that the size of the maximum independent set is 9
julia> branch(problem, config)
MISSize(9)

# we can also use the EliminateGraphs package to verify the result
julia> using OptimalBranchingMIS.EliminateGraphs

julia> mis2(EliminateGraph(g))
9
```

Furthermore, one can check the count of branches in the following way:
```julia
julia> config = SolverConfig(MISReducer(), branching_strategy, MISCount)
SolverConfig{MISReducer, OptBranchingStrategy{TensorNetworkSolver, IPSolver, EnvFilter, MinBoundarySelector, D3Measure}, MISCount}(MISReducer(), OptBranchingStrategy{TensorNetworkSolver, IPSolver, EnvFilter, MinBoundarySelector, D3Measure}(TensorNetworkSolver(), IPSolver(10), EnvFilter(), MinBoundarySelector(2), D3Measure()), MISCount)

julia> branch(problem, config)
MISCount(9, 1)
```
which shows that it takes only one branch to find the maximum independent set of size 9.
