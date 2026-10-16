# =============================================================================
# C4 — vertex ablation: does the lifted value stabilize as the action set refines?
#
#   julia -t 32 --project=. test/run_c4.jl
#
# The supporting lemma of the paper is the LIFTING: we replace a continuous
# trajectory game with a finite one over M hexagon vertices, and the safety claim
# is worth exactly as much as that replacement is faithful. C5 gives the bound
# (|V_M - V_cont| <= L h_M, with h_M the covering radius); C4 supplies the
# empirical half — the value as a function of M.
#
# Arities 6 / 12 / 24. n=6 already exists from Gate B and is NOT re-run: the
# n=6 code path is bitwise-preserved (see polygon_vertices), so re-running it
# would produce identical files at full cost. Results land in
# test/results/n30_v12/ and n30_v24/ — the `_v<n>` component keeps them away
# from the 6-vertex trees (`results_folder` in Utils.jl).
#
# Two matchups, for two different questions:
#   mixed/mixed       the EQUILIBRIUM value V_M. This is the quantity C5's
#                     proposition is about and the one that must converge.
#   FP_greedy/mixed   does the headline exploitation result survive refinement,
#                     or was it an artifact of a coarse action set? A reviewer
#                     will ask, and the answer belongs in the paper either way.
#
# Cost scales with arity: each vertex is one more trajectory optimization per
# player per step, so n=12 is ~2x and n=24 ~4x the n=6 sweep per matchup.
# Measured basis: Gate B ran 141 solves/sec aggregate on 32 threads.
#   n=12: 100 games x 30 steps x 24 solves = 72,000 solves  ~=  9 min/matchup
#   n=24: 100 games x 30 steps x 48 solves = 144,000 solves ~= 17 min/matchup
#   total for 2 matchups x 2 arities                        ~= 52 min
#
# CRN as everywhere else: reseed inside the loop so game k draws identical ICs
# across arities AND matchups. Comparing V_6 to V_12 on the same initial
# conditions is what makes the convergence curve a paired measurement rather
# than two independent samples.
# =============================================================================

using trajectory_optimization_game_theory
using LinearAlgebra, Random, Statistics, Printf

const ARITIES  = [12, 24]                              # 6 already exists from Gate B
const MATCHUPS = [("mixed", "mixed"), ("FP_greedy", "mixed")]
const N_GAMES  = 100
const N_STEPS  = 30

function main()
    @printf("C4 vertex ablation: %d arities x %d matchups x %d trials x %d steps, %d threads\n",
            length(ARITIES), length(MATCHUPS), N_GAMES, N_STEPS, Threads.nthreads())
    println("  n=6 is NOT re-run — it exists from Gate B and its code path is bitwise-preserved.\n")

    t_all = @elapsed for n in ARITIES, (p1, p2) in MATCHUPS
        @printf("[n=%2d] %-10s vs %-10s ... ", n, p1, p2)
        rng = MersenneTwister(1)          # CRN: identical ICs across arities and matchups
        t = @elapsed run_MC_games_parallel(rng, N_GAMES, N_STEPS, p1, p2;
                                           disperse = true, slim_save = true, n_vertices = n)
        @printf("%.1f min  -> %s\n", t / 60, results_folder(N_STEPS, p1, p2, n))
        flush(stdout)
    end
    @printf("\nC4 SWEEP COMPLETE in %.1f min\n", t_all / 60)
end

main()
