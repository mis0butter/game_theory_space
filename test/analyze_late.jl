# =============================================================================
# Paper numbers on the late-game metric: mean separation over steps 10–30 (6–30 before 2026-10-29), i.e.
# after the opening approach (≈36 km → ≈4 km by step 4). Steps 1–30 are printed
# alongside as a value check against LOG, and steps 15–30 as a robustness check.
#
#   julia -t 8 --project=. test/analyze_late.jl
#
# Reads the 6×6 tournament (Gate B + Meta cells), B6 (fixed-vertex evaders,
# oracle) and C4 (M = 12, 24 vertices). No new games.
# =============================================================================

using trajectory_optimization_game_theory
using Statistics, Printf

const NG, NS = 100, 30
const ALL = ["greedy", "mixed", "random", "FP_greedy", "FP_mixed", "Meta_greedy"]
const AB = Dict("greedy" => "Gr", "mixed" => "MM", "random" => "Rnd", "FP_greedy" => "FPg",
                "FP_mixed" => "FPm", "Meta_greedy" => "TB", "oracle" => "Orc")
const WINS = [("1-30", 1:30), ("6-30", 6:30), ("10-30", 10:30), ("15-30", 15:30)]
const TB, MM, FPG = "Meta_greedy", "mixed", "FP_greedy"

"Per-game per-step separation (NG × NS), min separation in steps 1–5, IC fingerprint."
function load_cell(a, b; n = 6)
    gv = load_games_vec(NG, NS, a, b; n_vertices = n)
    S = fill(NaN, length(gv), NS)
    early_min = Float64[]
    for (gi, g) in enumerate(gv)
        s = separation_series(g)
        for k in 1:NS
            S[gi, k] = mean(s.d[s.k .== k])
        end
        push!(early_min, minimum(s.d[s.k .<= 5]))
    end
    (; S, early_min, ic = [g.params[1].ic for g in gv])
end
const CACHE = Dict{Any,Any}()
cell(a, b; n = 6) = get!(() -> load_cell(a, b; n), CACHE, (a, b, n))
sep(a, b, r; n = 6) = vec(mean(cell(a, b; n).S[:, r]; dims = 2))

ci(v) = (mean(v), 1.96std(v) / sqrt(length(v)))
function paired(x, y)
    d = x .- y; m, se = mean(d), std(d) / sqrt(length(d))
    (m, 1.96se, m / se)
end
fp(t) = @sprintf("%+.3f ± %.3f (t = %+.1f)", t...)
fc(v) = @sprintf("%.2f ± %.2f", ci(v)...)

# pooled over opponents: x as evader (role 1) or pursuer (role 2)
ev(x, r, opps = ALL) = vcat((sep(x, o, r) for o in opps)...)
pu(x, r, opps = ALL) = vcat((sep(o, x, r) for o in opps)...)

function crn_check()
    ref = cell(MM, MM).ic
    cells = vcat([(a, b) for a in ALL for b in ALL],
                 [(string(v), p) for v in 1:6 for p in ("oracle", FPG, MM, TB)], [(MM, "oracle")])
    for c in cells
        cell(c...).ic == ref || error("CRN broken for $c")
    end
    println("CRN verified across $(length(cells)) cells.")
end

function tournament(wname, r)
    println("\n", "="^90, "\nWINDOW steps $wname\n", "="^90)
    println("6×6 mean separation [km] (rows evader, cols pursuer), ± 95% CI")
    @printf("%-5s %s %13s\n", "", join([@sprintf("%13s", AB[p]) for p in ALL]), "avg")
    for e in ALL
        @printf("%-5s %s %13s\n", AB[e], join([@sprintf("%13s", fc(sep(e, p, r))) for p in ALL]), fc(ev(e, r)))
    end
    @printf("%-5s %s\n", "avg", join([@sprintf("%13s", fc(pu(p, r))) for p in ALL]))
    lo, hi = extrema(1.96std(sep(e, p, r)) / sqrt(NG) for e in ALL, p in ALL)
    lo2, hi2 = extrema(vcat([ci(ev(x, r))[2] for x in ALL], [ci(pu(x, r))[2] for x in ALL]))
    @printf("CI half-widths: cells %.2f–%.2f, averages %.2f–%.2f\n", lo, hi, lo2, hi2)

    # meta-game (EGTA) on the cell means; P1 (evader) maximizes
    A = [mean(sep(e, p, r)) for e in ALL, p in ALL]
    s = solve_mixed_nash(A)
    @printf("\nmeta-game value %.3f km (cert %.1e)\n", s.V, s.cert_violation)
    for (i, x) in enumerate(ALL)
        (s.x[i] > 1e-4 || s.y[i] > 1e-4) && @printf("  %-4s evader %.3f  pursuer %.3f\n", AB[x], s.x[i], s.y[i])
    end
    for (j, p) in enumerate(ALL)
        all(all(A[:, j] .<= A[:, k]) for k in eachindex(ALL)) &&
            println("  pursuer $(AB[p]) has the lowest entry in every row (weakly dominant)")
    end
    for (i, e) in enumerate(ALL)
        all(all(A[i, :] .>= A[k, :]) for k in eachindex(ALL)) && println("  evader $(AB[e]) weakly dominant")
    end

    println("\nFP-greedy − minimax evader, by pursuer (paired)")
    for p in ALL
        @printf("  vs %-4s %s\n", AB[p], fp(paired(sep(FPG, p, r), sep(MM, p, r))))
    end

    println("\nAdvantage over minimax (right = better): all six opponents | vs type-based")
    for x in ("Meta_greedy", "FP_greedy", "FP_mixed", "greedy", "random")
        @printf("  evader  %-4s %s | %s\n", AB[x], fp(paired(ev(x, r), ev(MM, r))),
                fp(paired(sep(x, TB, r), sep(MM, TB, r))))
    end
    for x in ("Meta_greedy", "FP_greedy", "FP_mixed", "greedy", "random")
        @printf("  pursuer %-4s %s | %s\n", AB[x], fp(paired(pu(MM, r), pu(x, r))),
                fp(paired(sep(TB, MM, r), sep(TB, x, r))))
    end

    five = filter(!=(TB), ALL)
    println("\nType-based vs FP-greedy, pooled")
    @printf("  evader  TB − FPg, six pursuers   %s\n", fp(paired(ev(TB, r), ev(FPG, r))))
    @printf("  evader  TB − FPg, five (no TB)   %s\n", fp(paired(ev(TB, r, five), ev(FPG, r, five))))
    @printf("  evader  TB − FPm, six pursuers   %s\n", fp(paired(ev(TB, r), ev("FP_mixed", r))))
    @printf("  pursuer TB − FPg, six evaders    %s\n", fp(paired(pu(TB, r), pu(FPG, r))))

    println("\nType-based pursuer − minimax pursuer, by evader (negative = TB closer)")
    for e in ALL
        @printf("  vs %-4s %s\n", AB[e], fp(paired(sep(e, TB, r), sep(e, MM, r))))
    end
    @printf("  TB − FPg pursuer vs FPg evader %s\n", fp(paired(sep(FPG, TB, r), sep(FPG, FPG, r))))

    println("\nType-based evader − minimax evader, by pursuer")
    for p in ALL
        @printf("  vs %-4s %s\n", AB[p], fp(paired(sep(TB, p, r), sep(MM, p, r))))
    end
    @printf("  TB − FPg evader vs FPg pursuer %s\n", fp(paired(sep(TB, FPG, r), sep(FPG, FPG, r))))

    println("\nAgainst the type-based pursuer: minimax evader minus ...")
    for x in ("Meta_greedy", "random", "FP_mixed", "FP_greedy", "greedy")
        @printf("  %-4s %s\n", AB[x], fp(paired(sep(MM, TB, r), sep(x, TB, r))))
    end
    println("\nSelf-play: TB/TB $(fc(sep(TB, TB, r)))  FPg/FPg $(fc(sep(FPG, FPG, r)))  MM/MM $(fc(sep(MM, MM, r)))")
    return A
end

function price_of_safety(wname, r)
    println("\n--- price of safety, steps $wname ---")
    @printf("  %-3s %18s %26s %8s %8s %8s %8s %7s %7s\n", "v", "MM − oracle", "", "oracle", "FPg", "TB", "MM",
            "FPrec", "TBrec")
    for k in 1:6
        v = string(k)
        o, f, t, n = sep(v, "oracle", r), sep(v, FPG, r), sep(v, TB, r), sep(v, MM, r)
        rec(x) = 100(mean(n) - mean(x)) / (mean(n) - mean(o))
        @printf("  %-3d %s %8.3f %8.3f %8.3f %8.3f %6.1f%% %6.1f%%\n", k, fp(paired(n, o)), mean(o), mean(f),
                mean(t), mean(n), rec(f), rec(t))
    end
    o, n, f, t = sep(MM, "oracle", r), sep(MM, MM, r), sep(MM, FPG, r), sep(MM, TB, r)
    @printf("  vs minimax evader: oracle − MM pursuer %s\n", fp(paired(o, n)))
    @printf("                     FPg − MM pursuer    %s\n", fp(paired(f, n)))
    @printf("                     TB − MM pursuer     %s\n", fp(paired(t, n)))
    @printf("  means: oracle %.2f  MM %.2f  FPg %.2f  TB %.2f\n", mean(o), mean(n), mean(f), mean(t))
end

function vertices(wname, r)
    println("\n--- FP-greedy − minimax evader vs a minimax pursuer, by vertex count, steps $wname ---")
    for n in (6, 12, 24)
        cell(FPG, MM; n).ic == cell(MM, MM; n).ic || error("CRN broken at M = $n")
        @printf("  M = %2d  %s\n", n, fp(paired(sep(FPG, MM, r; n), sep(MM, MM, r; n))))
    end
end

function main()
    crn_check()
    for (w, r) in WINS
        tournament(w, r)
        price_of_safety(w, r)
        vertices(w, r)
    end
    # capture uses the whole game; check that none happens during the approach
    allc = vcat([(a, b) for a in ALL for b in ALL], [(string(v), p) for v in 1:6 for p in ("oracle", FPG, MM, TB)])
    em = vcat((cell(c...).early_min for c in allc)...)
    @printf("\nmin separation in steps 1–5 over %d games: %.2f km; below 1 km in %d, below 0.2 km in %d\n",
            length(em), minimum(em), count(<(1.0), em), count(<(0.2), em))
end

main()
