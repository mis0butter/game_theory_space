# =============================================================================
# Uncontended per-step compute, for the paper's real-time claim.
#
#   julia -t 1 --project=. test/bench_step.jl
#
# The sweeps run one game per thread on all cores, so the `t_solve` recorded in
# their `solve_info` includes contention from the other 31 games (memory
# bandwidth, GC). The paper's claim is about one player pair on one core, so it is
# measured here directly: single thread, mixed vs mixed, CRN seed as in Gate B.
# The first (warm-up) game is discarded so compilation does not count.
# =============================================================================

using trajectory_optimization_game_theory
using Random, Statistics, Printf

const NS, NG = 30, 5

Threads.nthreads() == 1 || @warn "run with -t 1; got $(Threads.nthreads()) threads"
redirect_stdout(devnull) do
    run_game(MersenneTwister(99), 3, "mixed", "mixed"; disperse = true)   # warm-up
end

tstep = Float64[]; tsol = Float64[]; dt = 0.0
rngs = [MersenneTwister(k) for k in 1:NG]
for k in 1:NG
    g, _ = redirect_stdout(devnull) do
        run_game(rngs[k], NS, "mixed", "mixed"; disperse = true)
    end
    global dt = g.params[1].tt_game_step
    for k in eachindex(g.p1_state)
        s1, s2 = g.p1_state[k].solve_info, g.p2_state[k].solve_info
        (isempty(s1.traj) || s1.lp === nothing) && continue
        t = s1.lp.t_lp
        for r in vcat(s1.traj, s2.traj)
            t += r.t_solve; push!(tsol, r.t_solve)
        end
        push!(tstep, t)
    end
end
@printf("%d games x %d steps, 1 thread: %d steps, %d solves\n", NG, NS, length(tstep), length(tsol))
@printf("  per solve [ms]  median %.1f  p95 %.1f\n", 1e3median(tsol), 1e3quantile(tsol, 0.95))
@printf("  per step  [s]   median %.3f  p95 %.3f  max %.3f\n", median(tstep), quantile(tstep, 0.95), maximum(tstep))
@printf("  margin vs %.0f s executed: median %.0f×  worst %.0f×\n", dt, dt / median(tstep), dt / maximum(tstep))
