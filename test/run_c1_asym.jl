# =============================================================================
# C1 (asymmetric) — does forgetting help the player who does it?
#
#   julia -t 32 --project=. test/run_c1_asym.jl
#
# WHY THIS EXISTS. The first C1 sweep used a single global γ, which discounts
# BOTH players. In the self-play cell `FP_greedy` vs `FP_greedy` that makes the
# change symmetric, so the large gain it produced (+1.393 km at γ=0.5 against the
# γ=1 baseline of 4.614) cannot be attributed to the evader forgetting — both
# sides changed at once. It is a statement about mutual memory, not about whether
# discounting is a good idea for the player adopting it.
#
# C1's actual question is one-sided: holding the OPPONENT fixed, does discounting
# help ME? That needs per-player γ (`γ_fp` for P1, `γ_fp_p2` for P2), which the
# `mixed` column already gives for free (a `mixed` player never reads
# `fp_belief`, so γ there only ever affected P1) but the self-play column does not.
#
# Two directions, so the claim is symmetric and neither side is assumed:
#
#   evader forgets   FP_greedy(γ) vs FP_greedy(1.0)   — higher separation = γ helped
#   pursuer forgets  FP_greedy(1.0) vs FP_greedy(γ)   — LOWER separation = γ helped
#
# Baseline for both is the Gate B cell FP_greedy/FP_greedy at γ=1 (4.614 km), on
# the same initial conditions (CRN, seed 1), so every comparison is paired.
#
# Prediction on record: an `FP_greedy` opponent's realized distribution drifts
# systematically as its own beliefs accumulate, so this is the case where
# discounting SHOULD help the player doing it. Contrast with the `mixed` column,
# where the opponent's distribution churns unpredictably and discounting measured
# as null — the operative condition is systematic drift, not mere movement.
# =============================================================================

using trajectory_optimization_game_theory
using LinearAlgebra, Random, Statistics, Printf

const GAMMAS  = [0.5, 0.8, 0.9]
const N_GAMES = 100
const N_STEPS = 30

function main()
    @printf("C1 asymmetric γ: %d γ values x 2 directions x %d trials x %d steps, %d threads\n\n",
            length(GAMMAS), N_GAMES, N_STEPS, Threads.nthreads())

    t_all = @elapsed begin
        for γ in GAMMAS
            @printf("[evader forgets ] γ_P1=%.1f  γ_P2=1.0 ... ", γ)
            rng = MersenneTwister(1)
            t = @elapsed run_MC_games_parallel(rng, N_GAMES, N_STEPS, "FP_greedy", "FP_greedy";
                                               disperse = true, slim_save = true,
                                               γ_fp = γ, γ_fp_p2 = 1.0)
            @printf("%.1f min\n", t / 60); flush(stdout)
        end
        for γ in GAMMAS
            @printf("[pursuer forgets] γ_P1=1.0  γ_P2=%.1f ... ", γ)
            rng = MersenneTwister(1)
            t = @elapsed run_MC_games_parallel(rng, N_GAMES, N_STEPS, "FP_greedy", "FP_greedy";
                                               disperse = true, slim_save = true,
                                               γ_fp = 1.0, γ_fp_p2 = γ)
            @printf("%.1f min\n", t / 60); flush(stdout)
        end
    end
    @printf("\nC1 ASYMMETRIC SWEEP COMPLETE in %.1f min\n", t_all / 60)
end

main()
