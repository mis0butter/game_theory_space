# =============================================================================
# C2 fill-in — the missing oracle cell, and an η sweep so Hedge is not judged on
# one arbitrary learning rate.
#
#   julia -t 32 --project=. test/run_c2_fill.jl
#
# TWO GAPS in the first C2 pass.
#
# 1. `FP_greedy` vs `oracle` was never run. B6 swept fixed-vertex and `mixed`
#    evaders against the oracle, not FP, so the oracle column reads
#    mixed 5.098 > regret_matching 4.575 > hedge 4.504 with FP missing from its
#    own comparison. That column is the cleanest theoretical result C2 has —
#    against a best-responder the stage-game security strategy beats a no-regret
#    learner, because no-regret bounds the TIME-AVERAGE while minimax bounds each
#    STEP — so leaving FP out of it is not acceptable.
#
# 2. Hedge ran at η = 0.1, which was a default, not a tuned value. The textbook
#    choice for a known horizon (sqrt(8 ln n / T), n = 6, T = 30) is ~0.62, and
#    payoffs here are separations in km (O(4), not O(1)), so the effective rate
#    is η times the payoff scale. Hedge measured worse than regret matching
#    (4.923 vs 5.402 against `mixed`), but on one arbitrary η that is not a
#    finding. `regret_matching` is parameter-free, so ITS result is unconditional;
#    Hedge's is not, and the two must not be reported as equivalent evidence.
#    Sweeping η is what makes the comparison honest either way.
#
# η values span two orders of magnitude around the default, bracketing both the
# textbook value and the payoff-scale correction (0.62 / 4 km ~= 0.15).
# =============================================================================

using trajectory_optimization_game_theory
using LinearAlgebra, Random, Statistics, Printf

const N_GAMES = 100
const N_STEPS = 30
const ETAS    = [0.02, 0.5, 1.0]        # 0.1 already run; brackets ~0.15 and ~0.62

function cell(tag, p1, p2; kw...)
    @printf("%-22s %-16s vs %-10s ... ", tag, string(p1), p2)
    rng = MersenneTwister(1)
    t = @elapsed run_MC_games_parallel(rng, N_GAMES, N_STEPS, p1, p2;
                                       disperse = true, slim_save = true, kw...)
    @printf("%.1f min\n", t / 60); flush(stdout)
end

function main()
    @printf("C2 fill-in: 1 oracle cell + %d η values, %d trials x %d steps, %d threads\n\n",
            length(ETAS), N_GAMES, N_STEPS, Threads.nthreads())
    t_all = @elapsed begin
        cell("[oracle column]", "FP_greedy", "oracle")
        for η in ETAS
            cell(@sprintf("[C2 η=%.2f]", η), "hedge", "mixed"; η_hedge = η)
        end
    end
    @printf("\nC2 FILL-IN COMPLETE in %.1f min\n", t_all / 60)
end

main()
