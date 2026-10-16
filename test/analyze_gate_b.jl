# =============================================================================
# Gate B analysis — B4 (intervals + significance) and B5 (EGTA meta-game).
#
#   julia -t 8 --project=. test/analyze_gate_b.jl
#
# Reads the slim sweep in test/results/n30/. Every reported number carries an
# interval: B4's rule is "no number enters a table without one", and this is the
# first sweep in the project where trials are actually independent (D2/B1), so
# it is the first where an interval means anything.
# =============================================================================

using trajectory_optimization_game_theory
using LinearAlgebra, Random, Statistics, Printf

const STRATS  = ["greedy", "mixed", "random", "FP_greedy", "FP_mixed"]
const NG, NS  = 100, 30
const SHORT   = Dict("greedy"=>"grdy", "mixed"=>"mixed", "random"=>"rand",
                     "FP_greedy"=>"FPg", "FP_mixed"=>"FPm")

"Per-game metrics, computed only from fields that survive slim persistence."
function game_metrics(g)
    ks  = eachindex(g.p1_state)
    sep = Float64[]
    for k in ks
        r1, r2 = g.p1_state[k].rv_chosen, g.p2_state[k].rv_chosen
        (isempty(r1) || isempty(r2)) && continue
        append!(sep, [norm(r1[i, 1:3] - r2[i, 1:3]) for i in axes(r1, 1)])
    end
    dv1 = sum(sum(norm.(eachrow(g.p1_state[k].U_chosen))) for k in ks if !isempty(g.p1_state[k].U_chosen))
    dv2 = sum(sum(norm.(eachrow(g.p2_state[k].U_chosen))) for k in ks if !isempty(g.p2_state[k].U_chosen))
    nlast = max(1, length(sep) ÷ 4)
    # Capture per B3: hard 0.2 km / soft 1.0 km, post-hoc first passage, no termination.
    # capture_stats falls back to those values when params predates the radii, so this
    # reads pre-B3 sweeps (like the Gate B data itself) unchanged.
    cs = capture_stats(g)
    # `ic_key` fingerprints the realized initial condition (slim persistence keeps
    # params.ic). Identical fingerprints at the same game index across cells is what
    # common random numbers means, and it is what licenses the paired test.
    ic = g.params[1].ic
    (; mean_sep = mean(sep), late_sep = mean(sep[end-nlast+1:end]),
       min_sep = cs.min_sep, hard = cs.hard, soft = cs.soft,
       k_hard = cs.k_hard, k_soft = cs.k_soft, dv1, dv2,
       ic_key = (ic.a_ratio, ic.dν_E, ic.dν_P, ic.dΩ_E, ic.dΩ_P))
end

"""
Did the sweep use common random numbers? True iff game `k` drew the same initial
condition in every one of the 25 cells. Detected from the data rather than assumed,
because the difference is invisible in the results and silently invalidates B4's
paired test — which is exactly how the first Gate B sweep went wrong.
"""
function crn_ok(M, strats)
    ref = [x.ic_key for x in M[(strats[1], strats[1])]]
    all(([x.ic_key for x in M[(p1, p2)]] == ref) for p1 in strats, p2 in strats)
end

"mean with a 95% CI (normal approximation; n = 100 per cell)."
meanci(v) = (m = mean(v); h = 1.96 * std(v) / sqrt(length(v)); (m, h))

function main()
    @printf("Loading 25 matchups x %d trials x %d steps ...\n", NG, NS)
    M = Dict{Tuple{String,String},Vector{NamedTuple}}()
    for p1 in STRATS, p2 in STRATS
        gv = load_games_vec(NG, NS, p1, p2)
        M[(p1, p2)] = [game_metrics(g) for g in gv]
    end
    n = length(M[(STRATS[1], STRATS[1])])
    @printf("  %d games per cell\n\n", n)

    # ---------------------------------------------------------------- B4 table
    println("="^78)
    println("MEAN SEPARATION [km], mean ± 95% CI     rows = P1 (evader), cols = P2 (pursuer)")
    println("P1 maximizes separation; P2 minimizes it.")
    println("="^78)
    @printf("%-10s", "P1 \\ P2"); for p2 in STRATS; @printf("%16s", SHORT[p2]); end; println()
    for p1 in STRATS
        @printf("%-10s", SHORT[p1])
        for p2 in STRATS
            m, h = meanci([x.mean_sep for x in M[(p1, p2)]])
            @printf("%11.2f±%-4.2f", m, h)
        end
        println()
    end

    println("\n" * "="^78)
    println("ROW MEANS (how each evader does on average) and COLUMN MEANS (each pursuer)")
    println("="^78)
    for p1 in STRATS
        v = vcat([[x.mean_sep for x in M[(p1, p2)]] for p2 in STRATS]...)
        m, h = meanci(v); @printf("  P1 %-10s %6.2f ± %.2f km\n", SHORT[p1], m, h)
    end
    println()
    for p2 in STRATS
        v = vcat([[x.mean_sep for x in M[(p1, p2)]] for p1 in STRATS]...)
        m, h = meanci(v); @printf("  P2 %-10s %6.2f ± %.2f km  (lower is better for the pursuer)\n", SHORT[p2], m, h)
    end

    # --------------------------------------------------- significance, B4
    #
    # Both tests are reported. Which one is *valid* depends on how the sweep was
    # seeded, and that is not something the analysis can detect from the saved
    # games — so it is asserted below rather than assumed.
    #
    #   unpaired (Welch)  always valid
    #   paired            valid ONLY under common random numbers, i.e. game k drew
    #                     identical initial conditions in every cell. That holds iff
    #                     run_gate_b.jl reseeds its rng INSIDE the matchup loop.
    #                     With one rng threaded through all 25 calls, each cell draws
    #                     different ICs, the pairing is meaningless, and the paired
    #                     t is not interpretable even though it computes fine.
    #
    # The CRN check below is the guard: under CRN the per-cell IC draws coincide, so
    # paired differences have visibly smaller spread than the unpaired SE predicts.
    println("\n" * "="^78)
    println("HEADLINE COMPARISONS — FP_greedy vs mixed as the evader, by pursuer")
    println("="^78)
    function welch(a, b)
        ma, mb = mean(a), mean(b); va, vb = var(a)/length(a), var(b)/length(b)
        (; diff = ma - mb, t = (ma - mb) / sqrt(va + vb), se = sqrt(va + vb))
    end
    function paired(a, b)
        d = a .- b; se = std(d) / sqrt(length(d))
        (; diff = mean(d), t = mean(d) / se, se)
    end

    crn = crn_ok(M, STRATS)
    println(crn ? "  Common random numbers DETECTED — the paired test is the one to quote.\n" :
                  "  NO common random numbers — quote the UNPAIRED column; the paired\n" *
                  "  column is shown only to make the seeding defect visible.\n")
    @printf("  %-8s %22s   %22s  %s\n", "P2", "unpaired (Welch)", "paired", "SE ratio")
    for p2 in STRATS
        a = [x.mean_sep for x in M[("FP_greedy", p2)]]
        b = [x.mean_sep for x in M[("mixed", p2)]]
        w, q = welch(a, b), paired(a, b)
        @printf("  %-8s %+7.3f ± %.3f t=%+6.2f   %+7.3f ± %.3f t=%+6.2f  %5.2fx %s\n",
                SHORT[p2], w.diff, 1.96w.se, w.t, q.diff, 1.96q.se, q.t, w.se / q.se,
                abs(q.t) > 1.96 ? "sig" : "ns")
    end
    println("\n  SE ratio > 1 is the variance reduction pairing buys. Under CRN it should")
    println("  exceed 1 wherever the two cells share IC-driven variance; ~1.0 across the")
    println("  board means the pairing bought nothing, which is itself diagnostic.")

    # ------------------------------------------------------------ capture (B3)
    #
    # The capture condition: HARD = first passage below 0.2 km (ISS keep-out-sphere
    # radius), SOFT = below 1.0 km (proximity-ops scale; the most discriminating radius
    # on the measured curve). Post-hoc, no termination — see capture_stats. The curve is
    # still shown so the thresholds don't read as cherry-picked.
    println("\n" * "="^78)
    println("B3 — CAPTURE.  hard = 0.2 km (ISS keep-out sphere), soft = 1.0 km.")
    println("Post-hoc first passage; games are never terminated. n=$n per cell.")
    println("="^78)
    for (name, field) in (("HARD (0.2 km)", :hard), ("SOFT (1.0 km)", :soft))
        @printf("\n%s capture count per cell:\n", name)
        @printf("%-8s", "P1 \\ P2"); for p2 in STRATS; @printf("%7s", SHORT[p2]); end; println()
        for p1 in STRATS
            @printf("%-8s", SHORT[p1])
            for p2 in STRATS; @printf("%7d", count(x -> getfield(x, field), M[(p1, p2)])); end
            println()
        end
    end

    println("\nPooled capture rate, Wilson 95% CI  (per evader / per pursuer, n = $(5n)):")
    for (name, field) in (("hard", :hard), ("soft", :soft))
        @printf("  %-5s evader : ", name)
        for p1 in STRATS
            v = vcat([M[(p1, p2)] for p2 in STRATS]...)
            k = count(x -> getfield(x, field), v); lo, hi = wilson95(k, length(v))
            @printf("%s %4.1f%% [%4.1f,%4.1f]  ", SHORT[p1], 100k/length(v), 100lo, 100hi)
        end
        println()
        @printf("  %-5s pursuer: ", name)
        for p2 in STRATS
            v = vcat([M[(p1, p2)] for p1 in STRATS]...)
            k = count(x -> getfield(x, field), v); lo, hi = wilson95(k, length(v))
            @printf("%s %4.1f%% [%4.1f,%4.1f]  ", SHORT[p2], 100k/length(v), 100lo, 100hi)
        end
        println()
    end

    # time-to-soft-capture, among games that were soft-captured: how FAST a pursuer
    # penetrates the 1 km zone, not just whether it ever does
    println("\nMedian game step (of $NS) of first SOFT capture, captured games only:")
    @printf("%-8s", "P1 \\ P2"); for p2 in STRATS; @printf("%7s", SHORT[p2]); end; println()
    for p1 in STRATS
        @printf("%-8s", SHORT[p1])
        for p2 in STRATS
            ks = [x.k_soft for x in M[(p1, p2)] if x.soft]
            isempty(ks) ? @printf("%7s", "-") : @printf("%7.1f", median(ks))
        end
        println()
    end

    println("\nCapture rate vs radius (the sensitivity curve behind the thresholds):")
    radii = [0.1, 0.2, 0.25, 0.5, 1.0, 2.0]
    @printf("%-22s", "matchup"); for r in radii; @printf("%9.2f", r); end; println("  km")
    for p1 in STRATS, p2 in STRATS
        p1 in ("mixed", "FP_greedy") || continue
        d = [x.min_sep for x in M[(p1, p2)]]
        @printf("%-22s", "$(SHORT[p1]) vs $(SHORT[p2])")
        for r in radii; @printf("%8.0f%%", 100count(<=(r), d)/length(d)); end
        @printf("   (min %.3f km)\n", minimum(d))
    end

    # ------------------------------------------------------------ B5 EGTA
    println("\n" * "="^78)
    println("B5 — EGTA META-GAME: the 5x5 strategy table treated as a normal-form game")
    println("="^78)
    A = [mean(x.mean_sep for x in M[(p1, p2)]) for p1 in STRATS, p2 in STRATS]
    s = solve_mixed_nash(A)
    @printf("meta-game value V = %.4f km   (certificate %.1e)\n\n", s.V, s.cert_violation)
    println("  strategy      P1 weight   P2 weight")
    for (i, st) in enumerate(STRATS)
        @printf("  %-12s %9.4f %11.4f %s\n", SHORT[st], s.x[i], s.y[i],
                (s.x[i] > 1e-4 || s.y[i] > 1e-4) ? " <- in support" : "")
    end
    println()
    dom1 = [all(A[i, :] .>= A[k, :]) for i in eachindex(STRATS), k in eachindex(STRATS)]
    for (i, st) in enumerate(STRATS)
        others = [k for k in eachindex(STRATS) if k != i]
        @printf("  P1 %-10s dominates %d/%d other strategies -> %s\n", SHORT[st],
                count(dom1[i, others]), length(others),
                all(dom1[i, others]) ? "DOMINANT" : "not dominant")
    end
    println("\n  Reviewer 8 objected that \"dominant strategy\" was misused. The line above is")
    println("  the precise statement: a strategy is dominant only if its row weakly dominates")
    println("  every other row. Otherwise the honest claim is support membership, shown above.")
end

main()
