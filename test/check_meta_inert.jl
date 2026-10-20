# =============================================================================
# Value preservation for the FP opponent type (D13, 2026-10-20).
#
#   julia -t 8 --project=. test/check_meta_inert.jl
#
# Adding "FP_greedy" to `tracked_strategies` changes `strategy_belief` for every
# player, but only Meta_* strategies READ it. So every non-Meta game must replay
# bitwise: same chosen vertices, same executed states, same payoff matrices.
# Re-runs the first NCHK games of three Gate B cells with the sweep's exact seeds
# and compares against the saved files (made on this machine).
# =============================================================================

using trajectory_optimization_game_theory
using Random

const NG, NS, NCHK = 100, 30, 8
const CELLS = (("mixed", "mixed"), ("FP_greedy", "FP_greedy"), ("FP_greedy", "mixed"))

seeds = rand(MersenneTwister(1), UInt, NG)        # what run_MC_games_parallel draws
ok = true
for (p1, p2) in CELLS
    saved = load_games_vec(NG, NS, p1, p2)
    fresh = Vector{Any}(undef, NCHK)
    # stdout is global: redirect ONCE around the threaded block, never inside it
    redirect_stdout(devnull) do
        Threads.@threads for i in 1:NCHK
            rng = MersenneTwister(seeds[i])
            params, _, game = init_game(rng, p1, p2; disperse = true)
            for _ in 1:NS-1
                game = prop_game_step(game, params, rng)
            end
            fresh[i] = game
        end
    end
    for i in 1:NCHK, k in 1:NS, (a, b) in ((fresh[i].p1_state[k], saved[i].p1_state[k]),
                                           (fresh[i].p2_state[k], saved[i].p2_state[k]))
        same = a.chosen == b.chosen && a.rv_chosen == b.rv_chosen && a.cost == b.cost &&
               a.fp_belief == b.fp_belief
        same || (global ok = false; println("MISMATCH $p1/$p2 game $i step $k"))
    end
    println("$p1 / $p2: games 1-$NCHK x $NS steps checked")
end
println(ok ? "BITWISE IDENTICAL" : "VALUES MOVED")
