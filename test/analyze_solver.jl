# =============================================================================
# Solver and LP reliability for the paper (CDC Reviewer 7 #1, AE "tractability").
#
#   julia -t 32 --project=. test/analyze_solver.jl
#
# Reads the per-solve diagnostics every game step records in `solve_info`:
# trajectory convergence, terminal miss vs the hexagon radius, max per-segment ΔV vs
# the cap, wall time per solve, and the LP saddle-point certificate. No new sweep.
#
# Timing caveat: games run in parallel (one per thread), so per-solve wall times
# include contention from the other threads. Per-step compute is the sum of one
# game's 12 trajectory solves plus its LP, i.e. what one player-pair needs serially.
# =============================================================================

using trajectory_optimization_game_theory
using Statistics, Printf

const NG, NS = 100, 30
const TOURNAMENT = ("greedy", "mixed", "random", "FP_greedy", "FP_mixed")   # Gate B 5×5

# Every 6-vertex, default-parameter cell on disk (Gate B tournament, B6, C2 at default η).
# Folder names are p1_<s1>_p2_<s2>; no strategy name contains "_p2_".
function all_cells(dir = "test/results/n$(NS)")
    cells = Tuple{String,String}[]
    for d in sort(readdir(dir))
        isfile(joinpath(dir, d, "games_$(NG).jld2")) || continue
        a, b = split(d[4:end], "_p2_")
        push!(cells, (String(a), String(b)))
    end
    cells
end

q(v, p) = quantile(v, p)

function collect_cell(p1, p2)
    conv = Bool[]; miss = Float64[]; maxdv = Float64[]; tsol = Float64[]
    iters = Int[]; esc = Bool[]; cert = Float64[]; fb = Bool[]; tlp = Float64[]
    tstep = Float64[]
    gv = load_games_vec(NG, NS, p1, p2)
    prm = gv[1].params[1]
    for g in gv, k in eachindex(g.p1_state)
        s1, s2 = g.p1_state[k].solve_info, g.p2_state[k].solve_info
        (isempty(s1.traj) || s1.lp === nothing) && continue
        t_this = s1.lp.t_lp
        for r in vcat(s1.traj, s2.traj)
            push!(conv, r.converged); push!(miss, r.miss); push!(maxdv, r.max_Δv)
            push!(tsol, r.t_solve);   push!(iters, r.iters); push!(esc, r.escalated)
            t_this += r.t_solve
        end
        push!(cert, s1.lp.cert_violation); push!(fb, s1.lp.fallback)
        push!(tlp, s1.lp.t_lp); push!(tstep, t_this)
    end
    (; conv, miss, maxdv, tsol, iters, esc, cert, fb, tlp, tstep,
       R = prm.R_polygon, Δv_max = prm.Δv_max, dt_exec = prm.tt_game_step)
end

"Wilson 95% lower bound for k successes of n."
function wilson_lo(k, n)
    p, z = k / n, 1.96
    (p + z^2 / 2n - z * sqrt(p * (1 - p) / n + z^2 / 4n^2)) / (1 + z^2 / n)
end

function main()
    cells = all_cells()
    data  = Dict(c => collect_cell(c...) for c in cells)
    tour  = [c for c in cells if c[1] in TOURNAMENT && c[2] in TOURNAMENT]
    @printf("Found %d cells; %d are the Gate B tournament.\n", length(cells), length(tour))
    report("GATE B TOURNAMENT (5×5)", tour, data)
    report("ALL 6-VERTEX CELLS", cells, data)
end

function report(title, cells, data)
    cat(f) = reduce(vcat, (getfield(data[c], f) for c in cells))
    conv, miss, maxdv, tsol = cat(:conv), cat(:miss), cat(:maxdv), cat(:tsol)
    iters, esc, cert, fb, tlp, tstep = cat(:iters), cat(:esc), cat(:cert), cat(:fb), cat(:tlp), cat(:tstep)
    d1 = data[cells[1]]
    R, Δv_max, dt_exec = d1.R, d1.Δv_max, d1.dt_exec

    n = length(conv)
    println("\n" * "="^84)
    @printf("%s — %d cells   (%d trajectory solves, %d LPs)\n", title, length(cells), n, length(cert))
    println("="^84)
    @printf("Trajectory NLP\n")
    @printf("  converged                 %d / %d = %.3f%%  (Wilson 95%% lower bound %.4f%%)\n",
            count(conv), n, 100count(conv) / n, 100wilson_lo(count(conv), n))
    @printf("  escalated to AL (cap hit) %d\n", count(esc))
    @printf("  terminal miss [km]        median %.2e  p95 %.2e  max %.2e   (R = %.3f km; max/R = %.1e)\n",
            median(miss), q(miss, 0.95), maximum(miss), R, maximum(miss) / R)
    @printf("  max per-segment ΔV [km/s] max %.4f vs cap %.1f  (cap / max = %.0f×)\n",
            maximum(maxdv), Δv_max, Δv_max / maximum(maxdv))
    @printf("  iterations                median %d  p95 %d\n", round(Int, median(iters)), round(Int, q(iters, 0.95)))
    @printf("  wall time per solve [ms]  median %.1f  p95 %.1f\n", 1e3median(tsol), 1e3q(tsol, 0.95))
    @printf("\nMatrix-game LP\n")
    @printf("  certificate violation     median %.1e  max %.1e  (> 1e-8: %d)\n",
            median(cert), maximum(cert), count(>(1e-8), cert))
    @printf("  fallbacks                 %d\n", count(fb))
    @printf("  wall time per LP [ms]     median %.1f  p95 %.1f\n", 1e3median(tlp), 1e3q(tlp, 0.95))
    @printf("\nPer game step (12 solves + 1 LP, serial)\n")
    @printf("  compute [s]               median %.2f  p95 %.2f  max %.2f\n", median(tstep), q(tstep, 0.95), maximum(tstep))
    @printf("  trajectory executed [s]   %.0f\n", dt_exec)
    @printf("  margin (executed/compute) median %.0f×  worst %.0f×\n", dt_exec / median(tstep), dt_exec / maximum(tstep))
end

main()
