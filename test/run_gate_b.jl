# =============================================================================
# Gate B — the honest re-run.
#
#   julia -t 32 --project=. test/run_gate_b.jl
#
# What makes this different from every previous sweep:
#   * disperse=true      — real Monte Carlo over initial conditions (D2). Before
#                          this, deterministic matchups were bit-identical across
#                          all trials, i.e. N=1 in those cells.
#   * λ2 = 0             — the game payoff is separation only (note [j]); the
#                          fuel term contributed 0% of the matrix's variation.
#   * LBFGS              — 0.0156 s/solve in-pipeline vs BFGS's 0.505 s, same
#                          terminal accuracy. Affordable because with λ2 = 0 the
#                          ΔV difference never reaches a decision.
#   * slim_save          — 4.3x smaller files.
# =============================================================================

using trajectory_optimization_game_theory
using LinearAlgebra, Random, Statistics, Printf

const STRATS   = ["greedy", "mixed", "random", "FP_greedy", "FP_mixed"]
const N_GAMES  = 100
const N_STEPS  = 30

function main()
    @printf("Gate B sweep: %d strategies^2 x %d trials x %d steps, %d threads\n",
            length(STRATS), N_GAMES, N_STEPS, Threads.nthreads())
    p, _, _ = init_game(MersenneTwister(1))
    @printf("  λ2 = %.1f (separation-only payoff), Δv_max = %.1f, dispersion ON\n\n", p.λ2, p.Δv_max)

    t_all = @elapsed for (i, p1) in enumerate(STRATS), (j, p2) in enumerate(STRATS)
        n = (i - 1) * length(STRATS) + j
        @printf("[%2d/25] %-10s vs %-10s ... ", n, p1, p2)

        # Common random numbers. `run_MC_games_parallel` derives its per-game seeds from
        # the rng it is handed, so reseeding HERE — inside the loop, not once outside —
        # makes game k use identical initial conditions in all 25 cells. That is what
        # licenses the paired test B4 asks for: without it each cell draws different ICs
        # and only an unpaired test is valid, which is what the first sweep produced.
        rng = MersenneTwister(1)
        t = @elapsed run_MC_games_parallel(rng, N_GAMES, N_STEPS, p1, p2;
                                           disperse = true, slim_save = true)
        @printf("%.0f s\n", t)
        flush(stdout)
    end
    @printf("\nSWEEP COMPLETE in %.1f min\n", t_all / 60)
end

main()
