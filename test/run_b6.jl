# =============================================================================
# B6 — oracle best-response, the exploitation ceiling.
#
#   julia -t 32 --project=. test/run_b6.jl
#
# The experiment. A fixed-vertex evader (P1 plays vertex j every step, via the
# `Int` branch) is the most exploitable opponent that exists: perfectly
# predictable, zero adaptation. Run it against three pursuers:
#
#   oracle     told P1's true decision rule, best-responds exactly. Not a
#              realistic player — a CEILING on how much any pursuer could
#              extract from this evader.
#   FP_greedy  has to LEARN the same thing online from observed play.
#   mixed      the Nash safety strategy, which declines to exploit anyone.
#
# Three numbers fall out, and all three serve the headline:
#
#   mixed - oracle   the PRICE OF SAFETY: value Nash deliberately declines to
#                    collect, measured where the gap is largest and cleanest.
#   FP vs oracle     what fraction of that available exploitation online
#                    opponent modelling actually recovers, and how fast. This
#                    is the stand-in for the MARL baseline (§5 decision).
#   oracle by vertex the per-vertex SECURITY VALUE — the geometry question with
#                    Nash's non-exploitation removed.
#
# Why the redesign (note [f]): Gate A's vertex-geometry experiment used Nash as
# the only pursuer, which is the wrong opponent for this test. Nash is a safety
# strategy that guarantees a floor and deliberately declines to exploit, so it
# left value on the table by construction and never came close to capture. The
# resulting ranking conflated vertex geometry with Nash's non-exploitation, and
# did not replicate. Same experiment, right opponents.
#
# The `mixed` evader row is beyond the plan's B6 spec and is included as a
# reference: it is the price of safety when the evader is ALSO playing safe,
# which is what shows the fixed-vertex rows are the exploitable extreme rather
# than just a generically bad place to be.
#
# CAVEAT to carry into the writing: the oracle is a STAGE-GAME best response.
# It maximises the current step's payoff against the opponent's true per-step
# distribution, not the 30-step return, so `mixed - oracle` is a lower bound on
# the true price of safety — a dynamic-programming pursuer could sacrifice now
# to set up a better capture later. State it as "greedy best response to the
# true per-step distribution", never as "the optimal pursuer".
# =============================================================================

using trajectory_optimization_game_theory
using LinearAlgebra, Random, Statistics, Printf

# Vertices 1..6 plus `mixed` as the safe-evader reference row.
const EVADERS  = Any[1, 2, 3, 4, 5, 6, "mixed"]
const PURSUERS = ["oracle", "FP_greedy", "mixed"]
const N_GAMES  = 100
const N_STEPS  = 30

function main()
    @printf("B6 oracle best-response: %d evaders x %d pursuers x %d trials x %d steps, %d threads\n",
            length(EVADERS), length(PURSUERS), N_GAMES, N_STEPS, Threads.nthreads())
    p, _, _ = init_game(MersenneTwister(1))
    @printf("  λ2 = %.1f (separation-only payoff), capture hard/soft = %.2f / %.2f km, dispersion ON\n\n",
            p.λ2, p.r_capture_hard, p.r_capture_soft)

    n = length(EVADERS) * length(PURSUERS)
    t_all = @elapsed for (i, p1) in enumerate(EVADERS), (j, p2) in enumerate(PURSUERS)
        k = (i - 1) * length(PURSUERS) + j
        @printf("[%2d/%2d] P1 %-9s vs P2 %-10s ... ", k, n, string(p1), p2)

        # Common random numbers, same as run_gate_b.jl: reseeding HERE, inside the
        # loop rather than once outside, makes game k draw bit-identical initial
        # conditions in every cell. That is what licenses the paired oracle-vs-mixed
        # contrast, which is the single most important number this sweep produces.
        # (The per-game seeds come from `rand(rng, UInt, N_games)` at play_games.jl:124,
        # and IC.jl draws all five IC variates unconditionally before anything
        # strategy-dependent touches the rng, so differing rng CONSUMPTION between
        # pursuers does not perturb the ICs.)
        rng = MersenneTwister(1)
        t = @elapsed run_MC_games_parallel(rng, N_GAMES, N_STEPS, p1, p2;
                                           disperse = true, slim_save = true)
        @printf("%.0f s\n", t)
        flush(stdout)
    end
    @printf("\nB6 SWEEP COMPLETE in %.1f min\n", t_all / 60)
end

main()
