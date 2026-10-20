# =============================================================================
# Type-based reasoning (Meta_greedy with the FP learner type) — analysis.
#
#   julia -t 8 --project=. test/analyze_meta.jl
#
# Reads test/run_meta.jl's cells plus the Gate B and B6 cells they are paired
# with. Checks the LOG 2026-10-20 predictions in order:
#   1-3  Meta evader vs each pursuer: paired gain over the minimax and FP evaders
#   4    Meta pursuer vs fixed-vertex evaders: oracle recovery and identification speed
#   5    out-of-set opponents (FP_mixed, hedge)
#   6    Meta vs Meta
# plus posterior identification of the true type, and capture rates.
# =============================================================================

using trajectory_optimization_game_theory
using LinearAlgebra, Statistics, Printf

const NG, NS = 100, 30
const M = "Meta_greedy"
const TOUR = ["greedy", "mixed", "random", "FP_greedy", "FP_mixed"]

"Per-game mean separation, capture flags, IC fingerprint, and per-step state for one cell."
function load_cell(a, b)
    gv = load_games_vec(NG, NS, a, b)
    sep = [mean(separation_series(g).d) for g in gv]
    cs  = [capture_stats(g) for g in gv]
    (; gv, sep, hard = [c.hard for c in cs], soft = [c.soft for c in cs],
       ic = [g.params[1].ic for g in gv])
end

const CACHE = Dict{Tuple{Any,Any},Any}()
cell(a, b) = get!(() -> load_cell(a, b), CACHE, (a, b))

function paired(x, y)                       # mean(x - y) ± 95% CI, t
    d = x .- y
    m, se = mean(d), std(d) / sqrt(length(d))
    (m, 1.96se, m / se)
end
fmt(t) = @sprintf("%+.3f ± %.3f (t = %+.1f)", t...)
ci(v) = @sprintf("%.2f ± %.2f", mean(v), 1.96std(v) / sqrt(length(v)))
function rate(b)
    k = count(b); lo, hi = wilson95(k, length(b))
    @sprintf("%3d%% [%.0f, %.0f]", round(Int, 100k / length(b)), 100lo, 100hi)
end

"CRN check: every compared cell must share trial k's initial conditions."
function crn!(cells)
    ref = cell(cells[1]...).ic
    for c in cells
        cell(c...).ic == ref || error("CRN broken for $(c): pairing invalid")
    end
end

"Mean posterior on `truth` across games at the given steps (`truth` = a tracked type)."
function posterior_on(gv, role, truth, steps)
    st(g) = role == 1 ? g.p1_state : g.p2_state
    i = findfirst(==(truth), st(gv[1])[1].tracked_strategies)
    i === nothing && return fill(NaN, length(steps))
    [mean(st(g)[k].strategy_belief[i] for g in gv) for k in steps]
end

"Distribution of the final-step MAP type across games."
function map_types(gv, role)
    st(g) = role == 1 ? g.p1_state : g.p2_state
    types = st(gv[1])[1].tracked_strategies
    c = Dict{Any,Int}()
    for g in gv
        t = types[argmax(st(g)[end].strategy_belief)]
        c[t] = get(c, t, 0) + 1
    end
    join(["$(k)=$(v)" for (k, v) in sort(collect(c); by = x -> -x[2])], ", ")
end

const STEPS = [1, 2, 3, 5, 10, 30]

function main()
    crn!(vcat([(M, p) for p in TOUR], [(e, M) for e in TOUR], [("mixed", p) for p in TOUR],
              [("FP_greedy", p) for p in TOUR], [(v, M) for v in 1:6], [(v, "oracle") for v in 1:6],
              [(M, M), ("hedge", M), ("hedge", "mixed")]))
    println("CRN verified across all compared cells.\n")

    # ---------------------------------------------------------------- 1-3, 5
    println("="^92)
    println("EVADER: Meta_greedy vs the minimax and FP-greedy evaders, same pursuer (paired)")
    println("="^92)
    @printf("  %-10s %13s %13s %13s   %-32s %-32s\n", "pursuer", "Meta", "minimax", "FP-greedy",
            "Meta − minimax", "Meta − FP-greedy")
    for p in TOUR
        m, n, f = cell(M, p).sep, cell("mixed", p).sep, cell("FP_greedy", p).sep
        @printf("  %-10s %13s %13s %13s   %-32s %-32s\n", p, ci(m), ci(n), ci(f),
                fmt(paired(m, n)), fmt(paired(m, f)))
    end

    println("\n" * "="^92)
    println("PURSUER: Meta_greedy vs the minimax and FP-greedy pursuers, same evader (lower is better)")
    println("="^92)
    @printf("  %-10s %13s %13s %13s   %-32s %-32s\n", "evader", "Meta", "minimax", "FP-greedy",
            "Meta − minimax", "Meta − FP-greedy")
    for e in TOUR
        m, n, f = cell(e, M).sep, cell(e, "mixed").sep, cell(e, "FP_greedy").sep
        @printf("  %-10s %13s %13s %13s   %-32s %-32s\n", e, ci(m), ci(n), ci(f),
                fmt(paired(m, n)), fmt(paired(m, f)))
    end
    @printf("\n  Meta row mean as evader (over the 5 tournament pursuers): %.2f km\n",
            mean(mean(cell(M, p).sep) for p in TOUR))
    @printf("  Meta column mean as pursuer (over the 5 tournament evaders): %.2f km\n",
            mean(mean(cell(e, M).sep) for e in TOUR))

    # ---------------------------------------------------------------- identification
    println("\n" * "="^92)
    println("IDENTIFICATION: mean posterior on the opponent's TRUE type, at steps $(STEPS)")
    println("="^92)
    for p in TOUR
        p == "FP_mixed" && continue              # out of set
        v = posterior_on(cell(M, p).gv, 1, p, STEPS)
        @printf("  Meta evader  vs %-10s %s\n", p, join([@sprintf("%.3f", x) for x in v], "  "))
    end
    for e in TOUR
        e == "FP_mixed" && continue
        v = posterior_on(cell(e, M).gv, 2, e, STEPS)
        @printf("  Meta pursuer vs %-10s %s\n", e, join([@sprintf("%.3f", x) for x in v], "  "))
    end
    for k in 1:6
        v = posterior_on(cell(k, M).gv, 2, k, STEPS)
        @printf("  Meta pursuer vs vertex %d   %s\n", k, join([@sprintf("%.3f", x) for x in v], "  "))
    end
    println("\n  Out-of-set and self-play — final-step MAP type (count of 100 games):")
    @printf("    Meta evader  vs FP_mixed : %s\n", map_types(cell(M, "FP_mixed").gv, 1))
    @printf("    Meta pursuer vs FP_mixed : %s\n", map_types(cell("FP_mixed", M).gv, 2))
    @printf("    Meta pursuer vs hedge    : %s\n", map_types(cell("hedge", M).gv, 2))
    @printf("    Meta vs Meta, evader     : %s\n", map_types(cell(M, M).gv, 1))
    @printf("    Meta vs Meta, pursuer    : %s\n", map_types(cell(M, M).gv, 2))

    # ---------------------------------------------------------------- 4
    println("\n" * "="^92)
    println("FIXED-VERTEX EVADERS: Meta pursuer vs oracle / FP-greedy / minimax (B6)")
    println("="^92)
    @printf("  %-6s %10s %10s %10s %10s   %-12s %-12s   %s\n", "vertex", "oracle", "Meta", "FP",
            "minimax", "Meta recov", "FP recov", "Meta hard-capture")
    for k in 1:6
        o, m, f, n = cell(k, "oracle").sep, cell(k, M).sep, cell(k, "FP_greedy").sep, cell(k, "mixed").sep
        rec(x) = 100(mean(n) - mean(x)) / (mean(n) - mean(o))
        @printf("  %-6d %10.3f %10.3f %10.3f %10.3f   %10.1f%%  %10.1f%%   %s\n", k, mean(o), mean(m),
                mean(f), mean(n), rec(m), rec(f), rate(cell(k, M).hard))
    end
    # per-step agreement with the oracle's move (argmin of A[v, :] for a fixed evader v)
    agree(gv, k, s) = mean(argmin(g.p1_state[s].cost[k, :]) == g.p2_state[s].chosen for g in gv)
    for (name, pur) in (("Meta", M), ("FP", "FP_greedy"))
        a = [mean(agree(cell(k, pur).gv, k, s) for k in 1:6) for s in 1:NS]
        @printf("  %-4s plays the oracle's move: steps 1-5 %s | steps 6-30 mean %.3f\n", name,
                join([@sprintf("%.2f", x) for x in a[1:5]], " "), mean(a[6:end]))
    end

    # ---------------------------------------------------------------- 6 + capture
    println("\n" * "="^92)
    println("SELF-PLAY AND CAPTURE (hard 0.2 km / soft 1.0 km, Wilson 95%)")
    println("="^92)
    for (a, b) in [(M, M), ("FP_greedy", "FP_greedy"), ("mixed", "mixed"), (M, "FP_greedy"),
                   ("FP_greedy", M), ("hedge", M), ("hedge", "mixed")]
        c = cell(a, b)
        @printf("  %-11s vs %-11s  sep %s   hard %s   soft %s\n", a, b, ci(c.sep), rate(c.hard), rate(c.soft))
    end
    @printf("\n  hedge evader: Meta pursuer − minimax pursuer  %s\n",
            fmt(paired(cell("hedge", M).sep, cell("hedge", "mixed").sep)))
end

main()
