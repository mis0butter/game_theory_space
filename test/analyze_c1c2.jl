# =============================================================================
# C1 + C2 analysis — discounted FP, and the no-regret baseline.
#
#   julia -t 8 --project=. test/analyze_c1c2.jl
#
# Every cell here shares initial conditions with Gate B (CRN, seed 1 reseeded per
# cell), so every comparison against the existing table is PAIRED.
#
# ---- what C1 should do, stated precisely before looking -----------------------
#
# Discounting stale observations can only help when the opponent's REALIZED
# ACTION DISTRIBUTION drifts. That is a sharper condition than "the opponent
# adapts", and it cuts across the strategy names:
#
#   fixed vertex j  distribution is a constant point mass. Nothing to forget.
#                   γ < 1 must do NOTHING here — this row is the falsification
#                   check, and a gain here is a bug, not a result.
#   mixed           the RULE is stationary ("play the stage Nash mixture"), but
#                   C3 measured that mixture reshuffling by 1.36 in L1 per step
#                   with the modal vertex changing 82% of the time. So the
#                   realized distribution drifts hard, and discounting SHOULD help.
#   FP_greedy       drifts as its own beliefs accumulate. Should help.
#
# ---- what C2 should do --------------------------------------------------------
#
# A no-regret bound is about the TIME-AVERAGE of play. C3 showed the stage
# equilibrium reshuffles almost completely each step, so the time-average is not
# the object that matters here. Prediction: competitive but not dominant on mean
# separation, with any real difference showing up in realized regret rather than
# in the outcome. A large win on mean separation would suggest an implementation
# edge rather than a theoretical one.
# =============================================================================

using trajectory_optimization_game_theory
using LinearAlgebra, Random, Statistics, Printf

const NG, NS   = 100, 30
const GAMMAS   = [0.5, 0.8, 0.9]
const C1_OPPS  = ["mixed", "FP_greedy"]
const LEARNERS = ["regret_matching", "hedge"]
const C2_OPPS  = ["mixed", "FP_greedy", "oracle"]

sepof(g) = begin
    s = Float64[]
    for k in eachindex(g.p1_state)
        r1, r2 = g.p1_state[k].rv_chosen, g.p2_state[k].rv_chosen
        (isempty(r1) || isempty(r2)) && continue
        append!(s, [norm(r1[i, 1:3] - r2[i, 1:3]) for i in axes(r1, 1)])
    end
    mean(s)
end

ickey(g) = (ic = g.params[1].ic; (ic.a_ratio, ic.dν_E, ic.dν_P, ic.dΩ_E, ic.dΩ_P))
meanci(v) = (mean(v), 1.96 * std(v) / sqrt(length(v)))
paired(a, b) = (d = a .- b; se = std(d) / sqrt(length(d)); (; diff = mean(d), h = 1.96se, t = mean(d) / se))

"load a cell, returning nothing (with a note) if the sweep has not written it yet"
function tryload(p1, p2; kw...)
    try
        return load_games_vec(NG, NS, p1, p2; kw...)
    catch
        return nothing
    end
end

function main()
    # ---------------------------------------------------------------- C1
    println("="^88)
    println("C1 — RECENCY-WEIGHTED FP.  Evader is FP_greedy with discount γ; γ=1 is plain FP.")
    println("Separation is the evader's payoff, so HIGHER is better for it.")
    println("="^88)
    @printf("  %-12s", "opponent")
    for γ in [1.0; GAMMAS]; @printf("%20s", γ == 1.0 ? "γ=1.0 (Gate B)" : "γ=$γ"); end
    println()
    for opp in C1_OPPS
        base = tryload("FP_greedy", opp)
        base === nothing && continue
        b = sepof.(base)
        @printf("  %-12s", opp)
        @printf("%13.3f±%-5.3f", meanci(b)...)
        for γ in GAMMAS
            gv = tryload("FP_greedy", opp; γ_fp = γ)
            if gv === nothing; @printf("%20s", "(pending)"); continue; end
            @assert ickey.(gv) == ickey.(base) "CRN broken between γ cells"
            @printf("%13.3f±%-5.3f", meanci(sepof.(gv))...)
        end
        println()
        # paired deltas against plain FP
        @printf("  %-12s", "  Δ vs γ=1")
        @printf("%20s", "—")
        for γ in GAMMAS
            gv = tryload("FP_greedy", opp; γ_fp = γ)
            if gv === nothing; @printf("%20s", ""); continue; end
            q = paired(sepof.(gv), b)
            @printf("%12s%+.3f%s", "", q.diff, abs(q.t) > 1.96 ? "*" : " ")
        end
        println()
    end

    println("\n  FALSIFICATION CHECK — γ against a FIXED-VERTEX evader (vertex 3).")
    println("  The evader's distribution is a constant point mass, so there is nothing to")
    println("  forget. A significant gain here would mean the implementation is wrong.")
    base3 = tryload(3, "FP_greedy")
    if base3 !== nothing
        b3 = sepof.(base3)
        @printf("    γ=1.0 (Gate B/B6): %.3f ± %.3f km\n", meanci(b3)...)
        for γ in GAMMAS
            gv = tryload(3, "FP_greedy"; γ_fp = γ)
            gv === nothing && continue
            q = paired(sepof.(gv), b3)
            m, h = meanci(sepof.(gv))
            @printf("    γ=%.1f: %.3f ± %.3f km   paired Δ = %+.3f ± %.3f  t=%+5.2f  %s\n",
                    γ, m, h, q.diff, q.h, q.t,
                    abs(q.t) > 1.96 ? "*** SIGNIFICANT — investigate, this should be null" : "null, as predicted")
        end
    end

    # ------------------------------------------------- C1 asymmetric decomposition
    println("\n" * "="^88)
    println("C1 (ASYMMETRIC) — does forgetting help the player who DOES it?")
    println("The symmetric FP-vs-FP column discounts both players at once, so its gain cannot")
    println("be attributed to either. Per-player γ splits it. Baseline is the γ=1 cell (4.614).")
    println("Evader forgets: higher separation = γ helped it. Pursuer forgets: LOWER = γ helped it.")
    println("="^88)
    ffbase = tryload("FP_greedy", "FP_greedy")
    if ffbase !== nothing
        b = sepof.(ffbase)
        @printf("  %-6s %14s %16s %16s %12s %12s\n",
                "γ", "symmetric Δ", "evader-only Δ", "pursuer-only Δ", "sum of the", "interaction")
        @printf("  %-6s %14s %16s %16s %12s %12s\n", "", "(both)", "(P1 only)", "(P2 only)", "two", "sym − sum")
        for γ in GAMMAS
            sym = tryload("FP_greedy", "FP_greedy"; γ_fp = γ)
            ev  = tryload("FP_greedy", "FP_greedy"; γ_fp = γ, γ_fp_p2 = 1.0)
            pu  = tryload("FP_greedy", "FP_greedy"; γ_fp = 1.0, γ_fp_p2 = γ)
            @printf("  %-6.1f", γ)
            ds = Float64[]
            for gv in (sym, ev, pu)
                if gv === nothing
                    @printf("%16s", "(pending)"); push!(ds, NaN); continue
                end
                q = paired(sepof.(gv), b)
                push!(ds, q.diff)
                @printf("%11.3f%-5s", q.diff, abs(q.t) > 1.96 ? " *" : "")
            end
            if all(!isnan, ds)
                @printf("%12.3f %12.3f", ds[2] + ds[3], ds[1] - (ds[2] + ds[3]))
            end
            println()
        end
        println("\n  A large positive evader-only Δ means discounting is INDIVIDUALLY rational for")
        println("  the evader. A near-zero one with a large symmetric Δ would mean the symmetric")
        println("  gain is about mutual lock-in only — a different and more interesting claim.")
    else
        println("  (FP_greedy/FP_greedy baseline not found)")
    end

    # ---------------------------------------------------------------- C2
    println("\n" * "="^88)
    println("C2 — NO-REGRET LEARNERS as the evader, against the standard pursuer set.")
    println("Baselines are Gate B's FP_greedy and mixed evaders on the same initial conditions.")
    println("="^88)
    @printf("  %-18s", "evader")
    for opp in C2_OPPS; @printf("%18s", "vs $opp"); end; println()
    for p1 in ["FP_greedy", "mixed", LEARNERS...]
        @printf("  %-18s", p1 in LEARNERS ? p1 : "$p1 (baseline)")
        for opp in C2_OPPS
            gv = tryload(p1, opp)
            if gv === nothing; @printf("%18s", "(pending)"); continue; end
            @printf("%11.3f±%-5.3f", meanci(sepof.(gv))...)
        end
        println()
    end

    println("\n  Paired Δ against the FP_greedy baseline (positive = learner evades better):")
    for L in LEARNERS, opp in C2_OPPS
        a, b = tryload(L, opp), tryload("FP_greedy", opp)
        (a === nothing || b === nothing) && continue
        q = paired(sepof.(a), sepof.(b))
        @printf("    %-16s vs %-10s  %+7.3f ± %.3f km   t=%+6.2f  %s\n",
                L, opp, q.diff, q.h, q.t, abs(q.t) > 1.96 ? "sig" : "ns")
    end

    # Hedge's learning rate was a default, not a tuned value. Regret matching is
    # parameter-free, so its result is unconditional; Hedge's is not, and reporting the
    # two as equivalent evidence without sweeping η would be over-claiming.
    println("\n  HEDGE vs LEARNING RATE (against a `mixed` pursuer).")
    println("  η=0.1 was a default. Textbook sqrt(8 ln n / T) at n=6, T=30 is ~0.62; payoffs")
    println("  here are O(4 km) not O(1), so the effective rate is η times the payoff scale.")
    rmref = tryload("regret_matching", "mixed")
    for η in (0.02, 0.1, 0.5, 1.0)
        gv = η == 0.1 ? tryload("hedge", "mixed") : tryload("hedge", "mixed"; η_hedge = η)
        if gv === nothing; @printf("    η=%.2f  (pending)\n", η); continue; end
        m, h = meanci(sepof.(gv))
        extra = ""
        if rmref !== nothing
            q = paired(sepof.(gv), sepof.(rmref))
            extra = @sprintf("   vs regret_matching: %+.3f ± %.3f %s", q.diff, q.h,
                             abs(q.t) > 1.96 ? "sig" : "ns")
        end
        @printf("    η=%.2f  %.3f ± %.3f km%s\n", η, m, h, extra)
    end

    println("\n  REALIZED EXTERNAL REGRET at the end of a 30-step game (max_i R_i / T).")
    println("  This is the quantity the no-regret guarantee is actually about.")
    for L in LEARNERS, opp in C2_OPPS
        gv = tryload(L, opp)
        gv === nothing && continue
        r = Float64[]
        for g in gv
            st = g.p1_state[end].learner_state
            st === nothing && continue
            push!(r, maximum(st.regret) / length(g.p1_state))
        end
        isempty(r) && continue
        @printf("    %-16s vs %-10s  median %.4f   p90 %.4f\n", L, opp, median(r), quantile(r, 0.9))
    end
end

main()
