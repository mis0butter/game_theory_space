# =============================================================================
# B6 analysis — the exploitation ceiling and what FP recovers of it.
#
#   julia -t 8 --project=. test/analyze_b6.jl
#
# Reads test/results/n30/p1_<j>_p2_<pursuer>/ written by run_b6.jl. Every number
# carries an interval (B4), and the headline contrasts are PAIRED: the same game
# index draws bit-identical initial conditions in every cell, verified from the
# realized params.ic before any paired number is quoted.
#
# CAVEAT (state it in the paper): the oracle is a STAGE-GAME best response — it
# maximises the current step against the opponent's true per-step distribution,
# not the 30-step return. So "price of safety" here is a LOWER BOUND on the true
# quantity. Call it a greedy best response to the true per-step distribution.
# =============================================================================

using trajectory_optimization_game_theory
using LinearAlgebra, Random, Statistics, Printf

const VERTS    = Any[1, 2, 3, 4, 5, 6]
const EVADERS  = Any[1, 2, 3, 4, 5, 6, "mixed"]
const PURSUERS = ["oracle", "FP_greedy", "mixed"]
const NG, NS   = 100, 30
const VNAME    = Dict(1=>"top", 2=>"topin", 3=>"botin", 4=>"bot", 5=>"botout", 6=>"topout")

"""
Per-game metrics. `oracle_move_rate` is the payoff of keeping `cost` in the slim
save: against an evader pinned to vertex j, the pursuer's exact best reply at a
given step is `argmin(A[j, :])` (P2 minimizes A), so we can reconstruct what the
ORACLE would have done at every state the FP and Nash runs actually visited, and
ask how often they matched it. That is a within-run convergence measure — no
cross-run state alignment needed, which would be invalid anyway since the
trajectories diverge after step 1.
"""
function game_metrics(g, j)
    sep = Float64[]
    per_step_sep = Float64[]
    for k in eachindex(g.p1_state)
        r1, r2 = g.p1_state[k].rv_chosen, g.p2_state[k].rv_chosen
        (isempty(r1) || isempty(r2)) && continue
        s = [norm(r1[i, 1:3] - r2[i, 1:3]) for i in axes(r1, 1)]
        append!(sep, s)
        push!(per_step_sep, mean(s))
    end

    # did the pursuer play the oracle's move at each step? only defined against a
    # fixed-vertex evader, where the true distribution is a known point mass.
    agree = Union{Missing,Bool}[]
    if j isa Int
        for k in eachindex(g.p2_state)
            A = g.p1_state[k].cost
            (isempty(A) || g.p2_state[k].chosen == 0) && continue
            push!(agree, g.p2_state[k].chosen == argmin(A[j, :]))
        end
    end

    cs = capture_stats(g)
    nlast = max(1, length(sep) ÷ 4)
    ic = g.params[1].ic
    (; mean_sep = mean(sep), late_sep = mean(sep[end-nlast+1:end]),
       min_sep = cs.min_sep, hard = cs.hard, soft = cs.soft,
       per_step_sep, agree,
       ic_key = (ic.a_ratio, ic.dν_E, ic.dν_P, ic.dΩ_E, ic.dΩ_P))
end

meanci(v) = (m = mean(v); (m, 1.96 * std(v) / sqrt(length(v))))
paired(a, b) = (d = a .- b; se = std(d) / sqrt(length(d)); (; diff = mean(d), h = 1.96se, t = mean(d) / se))

"Wilson 95% interval, as used for capture rates in analyze_gate_b.jl."
wilson(k, n) = wilson95(k, n)

"""
Bootstrap CI for the FP recovery fraction (sep_mixed - sep_FP) / (sep_mixed - sep_oracle):
a ratio of two random variables, so a normal-approximation SE on the ratio is not
defensible. Resampling is PAIRED (same game index drawn from all three cells at
once) because the three cells share initial conditions.
"""
function recovery_boot(sm, sf, so; B = 10_000, seed = 1)
    rng = MersenneTwister(seed)
    n = length(sm)
    point = (mean(sm) - mean(sf)) / (mean(sm) - mean(so))
    bs = Float64[]
    for _ in 1:B
        idx = rand(rng, 1:n, n)
        num = mean(sm[idx]) - mean(sf[idx])
        den = mean(sm[idx]) - mean(so[idx])
        abs(den) < 1e-9 && continue
        push!(bs, num / den)
    end
    # If the oracle never beat Nash on this evader there is no exploitable gap to
    # recover a fraction OF, and every resample was skipped. Report the point
    # estimate with a missing interval rather than throwing on an empty vector —
    # a degenerate cell should not take the whole analysis down with it.
    isempty(bs) && return (point, NaN, NaN)
    (point, quantile(bs, 0.025), quantile(bs, 0.975))
end

function main()
    @printf("Loading %d evaders x %d pursuers x %d trials ...\n", length(EVADERS), length(PURSUERS), NG)
    M = Dict{Tuple{Any,String},Vector{NamedTuple}}()
    for p1 in EVADERS, p2 in PURSUERS
        gv = load_games_vec(NG, NS, p1, p2)
        M[(p1, p2)] = [game_metrics(g, p1) for g in gv]
    end
    n = length(M[(1, "oracle")])

    ref = [x.ic_key for x in M[(1, "oracle")]]
    crn = all(([x.ic_key for x in M[(p1, p2)]] == ref) for p1 in EVADERS, p2 in PURSUERS)
    @printf("  %d games per cell.  common random numbers: %s\n\n", n, crn ? "VERIFIED" : "*** ABSENT ***")
    crn || @warn "CRN not detected — the paired contrasts below are not licensed. Quote unpaired only."

    # ------------------------------------------------ B6.3 security values
    println("="^86)
    println("MEAN SEPARATION [km], mean ± 95% CI.  Rows: P1 evader.  Cols: P2 pursuer.")
    println("Lower = pursuer did better.  The oracle column is the EXPLOITATION CEILING.")
    println("="^86)
    @printf("%-16s", "P1 \\ P2"); for p2 in PURSUERS; @printf("%18s", p2); end; println()
    for p1 in EVADERS
        lbl = p1 isa Int ? @sprintf("%d %-8s", p1, VNAME[p1]) : string(p1)
        @printf("%-16s", lbl)
        for p2 in PURSUERS
            m, h = meanci([x.mean_sep for x in M[(p1, p2)]])
            @printf("%12.2f±%-5.2f", m, h)
        end
        println()
    end

    # ------------------------------------------------ B6.1 price of safety
    println("\n" * "="^86)
    println("B6.1 — THE PRICE OF SAFETY:  (vs Nash mixed) − (vs oracle), paired, per vertex")
    println("How much separation the Nash pursuer leaves on the table by declining to exploit.")
    println("="^86)
    @printf("  %-16s %22s %9s   %s\n", "evader", "price of safety [km]", "t", "as % of the oracle value")
    for p1 in EVADERS
        sm = [x.mean_sep for x in M[(p1, "mixed")]]
        so = [x.mean_sep for x in M[(p1, "oracle")]]
        q  = paired(sm, so)
        lbl = p1 isa Int ? @sprintf("%d %s", p1, VNAME[p1]) : string(p1)
        @printf("  %-16s %+10.3f ± %-8.3f %+8.2f   %+6.1f%%  %s\n",
                lbl, q.diff, q.h, q.t, 100q.diff / mean(so), abs(q.t) > 1.96 ? "sig" : "ns")
    end

    # ------------------------------------------------ B6.2 FP recovery
    println("\n" * "="^86)
    println("B6.2 — WHAT ONLINE MODELLING RECOVERS:  (Nash − FP) / (Nash − oracle)")
    println("0% = FP exploits no better than the safety strategy;  100% = FP matches the ceiling.")
    println("Bootstrap 95% CI, paired resampling over the shared initial conditions.")
    println("="^86)
    @printf("  %-16s %12s   %-24s %s\n", "evader", "recovered", "95% CI", "FP − oracle [km], paired")
    for p1 in EVADERS
        sm = [x.mean_sep for x in M[(p1, "mixed")]]
        sf = [x.mean_sep for x in M[(p1, "FP_greedy")]]
        so = [x.mean_sep for x in M[(p1, "oracle")]]
        gap = paired(sf, so)
        lbl = p1 isa Int ? @sprintf("%d %s", p1, VNAME[p1]) : string(p1)
        # "Fraction of the available exploitation recovered" is only defined when there
        # IS available exploitation, i.e. the oracle beat Nash. Against an evader that
        # randomizes properly the oracle does NOT beat Nash (see B6.1), the denominator
        # goes non-positive, and the ratio becomes an uninterpretable large negative
        # number rather than a meaningful score. Report it as undefined and say why.
        avail = paired(sm, so)
        if avail.diff <= 0
            @printf("  %-16s %11s   %-24s      %+7.3f ± %.3f\n",
                    lbl, "n/a", "(no exploitation gap)", gap.diff, gap.h)
        else
            pt, lo, hi = recovery_boot(sm, sf, so)
            @printf("  %-16s %11.1f%%   [%6.1f%%, %6.1f%%]      %+7.3f ± %.3f\n",
                    lbl, 100pt, 100lo, 100hi, gap.diff, gap.h)
        end
    end

    # ------------------------------------- B6.2b convergence: oracle-move rate
    println("\n" * "="^86)
    println("B6.2b — HOW FAST:  fraction of steps the pursuer played the ORACLE'S move")
    println("Reconstructed post-hoc at every visited state: vs a vertex-j evader the exact")
    println("best reply is argmin(A_k[j,:]).  Averaged over the 6 fixed-vertex evaders.")
    println("="^86)
    bins = [(1, 5), (6, 10), (11, 15), (16, 20), (21, 25), (26, 30)]
    @printf("  %-12s", "pursuer"); for (a, b) in bins; @printf("%12s", "steps $a-$b"); end; println("      overall")
    for p2 in PURSUERS
        @printf("  %-12s", p2)
        allrates = Float64[]
        for (a, b) in bins
            hits, tot = 0, 0
            for j in VERTS, x in M[(j, p2)]
                for s in a:min(b, length(x.agree))
                    tot += 1; x.agree[s] && (hits += 1)
                end
            end
            @printf("%11.0f%%", 100hits / max(tot, 1))
            push!(allrates, hits / max(tot, 1))
        end
        hits, tot = 0, 0
        for j in VERTS, x in M[(j, p2)]; tot += length(x.agree); hits += count(identity, x.agree); end
        lo, hi = wilson(hits, tot)
        @printf("   %4.0f%% [%2.0f,%2.0f]\n", 100hits / tot, 100lo, 100hi)
    end
    println("\n  The oracle row is 100% by construction — it is the definition, shown as a check")
    println("  that the post-hoc reconstruction agrees with what the solver actually did.")

    # ------------------------------------------------ B6.3 vertex ranking
    println("\n" * "="^86)
    println("B6.3 — PER-VERTEX SECURITY VALUE under the oracle pursuer (the clean geometry number)")
    println("Note [f]'s ranking used Nash as the only pursuer and did not replicate. This is the")
    println("same question asked of an opponent that actually exploits.")
    println("="^86)
    rows = [(j, meanci([x.mean_sep for x in M[(j, "oracle")]])...,
                meanci([x.late_sep for x in M[(j, "oracle")]])[1]) for j in VERTS]
    sort!(rows, by = r -> -r[2])
    plane(j) = j in (1, 4) ? "out-of-plane" : "in-plane"
    @printf("  %-4s %-9s %-14s %22s %14s\n", "rank", "vertex", "plane", "security value [km]", "late-game")
    for (r, (j, m, h, lt)) in enumerate(rows)
        @printf("  %-4d %d %-7s %-14s %14.3f ± %-6.3f %13.3f\n", r, j, VNAME[j], plane(j), m, h, lt)
    end
    spread = rows[1][2] - rows[end][2]
    @printf("\n  spread best-to-worst: %.3f km (%.1f%% of the grand mean)\n",
            spread, 100spread / mean(r[2] for r in rows))
    op = mean(r[2] for r in rows if r[1] in (1, 4)); ip = mean(r[2] for r in rows if !(r[1] in (1, 4)))
    @printf("  out-of-plane mean %.3f vs in-plane mean %.3f  (note [f] claimed this axis explains the ranking)\n", op, ip)

    # ------------------------------------------------ capture
    println("\n" * "="^86)
    println("CAPTURE (B3): hard = 0.2 km (ISS keep-out sphere), soft = 1.0 km. n = $n per cell.")
    println("="^86)
    for (name, f) in (("HARD", :hard), ("SOFT", :soft))
        @printf("\n  %s capture rate [%%]\n  %-16s", name, "P1 \\ P2")
        for p2 in PURSUERS; @printf("%14s", p2); end; println()
        for p1 in EVADERS
            lbl = p1 isa Int ? @sprintf("%d %-8s", p1, VNAME[p1]) : string(p1)
            @printf("  %-16s", lbl)
            for p2 in PURSUERS
                v = M[(p1, p2)]
                k = count(x -> getfield(x, f), v); lo, hi = wilson(k, length(v))
                @printf("%7.0f%% [%2.0f,%2.0f]", 100k / length(v), 100lo, 100hi)
            end
            println()
        end
    end
end

main()
