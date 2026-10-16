# =============================================================================
# C1 + C2 — the γ sweep and the no-regret tournament, in one driver.
#
#   julia -t 32 --project=. test/run_c1c2.jl
#
# Two experiments that share a setup, run together so the machine is used once.
#
# ---- C1: does discounting stale observations help? --------------------------
#
# Recency-weighted FP is f_s = γ·f_{s-1} + g_{s-1}; γ = 1 is plain FP. C3
# measured why one might discount: the payoff matrix moves 18.5% of its norm per
# step and the stage equilibrium's mixture moves 1.36 in L1 (of a maximum 2.0),
# with the modal vertex changing 82% of the time. Uniform pooling averages
# observations across games that have little to do with each other.
#
# But C3 also found that FP's success is NOT equilibrium tracking — empirical
# play holds a flat ~0.25 km exploitability gap and never closes it. FP works by
# learning the opponent's DECISION RULE, which is stable for a stationary
# opponent no matter how the matrix moves. So the logged prediction is:
#
#   * γ < 1 should do little or nothing against a STATIONARY opponent
#     (`mixed`, `greedy`) — there is nothing to forget.
#   * γ < 1 should help most against a DRIFTING opponent (`FP_greedy`), whose
#     rule genuinely changes as its own beliefs accumulate.
#
# If γ < 1 helps against a fixed-vertex evader, that is a bug, not a result.
# The fixed-vertex row is included precisely as that falsification check.
#
# ---- C2: how does a no-regret learner compare? -------------------------------
#
# `regret_matching` (parameter-free) and `hedge` as evaders against the same
# three pursuers used everywhere else. Logged prediction: because the
# equilibrium reshuffles 82% of steps, a no-regret bound on the TIME-AVERAGE is
# the wrong object here, so expect competitive-but-not-dominant mean separation,
# with any real difference showing up in worst-case exploitability instead. If a
# learner wins big on mean separation, suspect an implementation edge rather
# than a theoretical one.
#
# CRN throughout: reseeding inside the loop means every cell below shares initial
# conditions with every other AND with Gate B, so all of these are paired
# comparisons against the existing table.
# =============================================================================

using trajectory_optimization_game_theory
using LinearAlgebra, Random, Statistics, Printf

const N_GAMES = 100
const N_STEPS = 30

# C1: γ x opponent. γ = 1.0 against `mixed` and `FP_greedy` already exists in Gate B
# (FP_greedy/mixed and FP_greedy/FP_greedy), so those two are skipped.
const GAMMAS    = [0.5, 0.8, 0.9]
const C1_OPPS   = ["mixed", "FP_greedy"]
# the falsification check: a stationary, maximally predictable opponent
const C1_FIXED  = 3

# C2: learner evaders against the standard pursuer set
const LEARNERS  = ["regret_matching", "hedge"]
const C2_OPPS   = ["mixed", "FP_greedy", "oracle"]

function run_cell(tag, p1, p2; kw...)
    @printf("%-28s %-16s vs %-12s ... ", tag, string(p1), p2)
    rng = MersenneTwister(1)          # CRN with every other sweep in the project
    t = @elapsed run_MC_games_parallel(rng, N_GAMES, N_STEPS, p1, p2;
                                       disperse = true, slim_save = true, kw...)
    @printf("%.1f min\n", t / 60)
    flush(stdout)
end

function main()
    @printf("C1 γ sweep + C2 no-regret tournament, %d trials x %d steps, %d threads\n\n",
            N_GAMES, N_STEPS, Threads.nthreads())

    t_all = @elapsed begin
        # ---- C1 -------------------------------------------------------------
        for γ in GAMMAS, opp in C1_OPPS
            run_cell(@sprintf("[C1 γ=%.1f]", γ), "FP_greedy", opp; γ_fp = γ)
        end
        # falsification: discounting must NOT help against a stationary opponent
        for γ in GAMMAS
            run_cell(@sprintf("[C1 γ=%.1f fixed-v]", γ), C1_FIXED, "FP_greedy"; γ_fp = γ)
        end

        # ---- C2 -------------------------------------------------------------
        for L in LEARNERS, opp in C2_OPPS
            run_cell("[C2]", L, opp)
        end
    end
    @printf("\nC1+C2 SWEEP COMPLETE in %.1f min\n", t_all / 60)
end

main()
