# =============================================================================
# Type-based reasoning sweep (D13 closed 2026-10-20): Meta_greedy with the FP
# learner type in its hypothesis set. Predictions are in LOG.md, written first.
#
#   julia -t 32 --project=. test/run_meta.jl
#
# Same protocol as Gate B / B6: CRN (MersenneTwister(1) reseeded per cell, so
# trial k shares its initial conditions with every other cell), dispersed ICs,
# 100 trials x 30 steps, slim saves. All cells are new paths; nothing existing
# is overwritten.
# =============================================================================

using trajectory_optimization_game_theory
using Random, Printf

const N_GAMES, N_STEPS = 100, 30
const M = "Meta_greedy"
const TOUR = ["greedy", "mixed", "random", "FP_greedy", "FP_mixed"]

cells = vcat([(M, p) for p in TOUR],              # type-based evader
             [(e, M) for e in TOUR],              # type-based pursuer
             [(v, M) for v in 1:6],               # vs fixed-vertex evaders (B6 comparison)
             [(M, M), ("hedge", M)])              # self-play; out-of-set learner

for (a, b) in cells
    isfile(joinpath(results_folder(N_STEPS, a, b), "games_$(N_GAMES).jld2")) &&
        error("refusing to overwrite existing cell $a / $b")
end

@printf("Meta sweep: %d cells x %d trials x %d steps, %d threads\n",
        length(cells), N_GAMES, N_STEPS, Threads.nthreads())
t_all = @elapsed for (i, (a, b)) in enumerate(cells)
    @printf("[%2d/%d] %-11s vs %-11s ... ", i, length(cells), a, b); flush(stdout)
    rng = MersenneTwister(1)                      # CRN: reseed inside the loop
    t = redirect_stdout(devnull) do
        @elapsed run_MC_games_parallel(rng, N_GAMES, N_STEPS, a, b; disperse = true, slim_save = true)
    end
    @printf("%.0f s\n", t); flush(stdout)
end
@printf("\nSWEEP COMPLETE in %.1f min\n", t_all / 60)
