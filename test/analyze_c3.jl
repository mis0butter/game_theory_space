# =============================================================================
# C3 — FP convergence, split into the two claims that must not be conflated.
#
#   julia -t 8 --project=. test/analyze_c3.jl
#
# Runs entirely on existing Gate B data — no new sweep.
#
# PART 1 (frozen matrix). Robinson (1951) guarantees that fictitious play's
# empirical frequencies converge to equilibrium in a zero-sum game with a FIXED
# payoff matrix. That is the ONLY setting where the classical theorem applies, so
# we verify it in exactly that setting, on REAL payoff matrices lifted out of the
# sweep rather than on random ones. Doing so validates the FP implementation and
# the LP jointly: FP converging to the LP's answer is evidence for both.
#
# PART 2 (how fast does the game actually move?). Our matrix does NOT stand
# still — at step 30 the players are three orbits from step 1. Quantify the
# variation budget: how much A_k, its equilibrium value, and its equilibrium
# STRATEGY move from step to step. The last is the one that matters for the
# paper's honesty, because cross-step belief pooling only means something if the
# thing being pooled toward is roughly stable.
#
# PART 3 (tracking, not convergence). Per-step exploitability of the empirical
# play actually realized in FP matchups. The honest claim is a TRACKING result:
# empirical play follows the moving stage-game equilibrium with a gap related to
# the variation budget. DO NOT claim Robinson applies here.
# =============================================================================

using trajectory_optimization_game_theory
using LinearAlgebra, Random, Statistics, Printf

const NG, NS = 100, 30

"""
Fictitious play on a frozen matrix, in the same convention as `update_beliefs!`
and the frozen-matrix testset: `f1` is P1's belief-count over P2's actions,
`f2` is P2's belief-count over P1's actions. Both start at `ones(n)`, matching
`IC.jl`. Returns exploitability of the empirical pair at each checkpoint.
"""
function frozen_fp(A, checkpoints)
    n = size(A, 1)
    f1, f2 = ones(n), ones(n)
    out = Float64[]
    T = maximum(checkpoints)
    for t in 1:T
        i = argmax(A  * (f1 ./ sum(f1)))     # P1 maximizes
        j = argmin(A' * (f2 ./ sum(f2)))     # P2 minimizes
        f2[i] += 1
        f1[j] += 1
        if t in checkpoints
            push!(out, exploitability(A, f2 ./ sum(f2), f1 ./ sum(f1)).nashconv)
        end
    end
    out
end

"Payoff matrices A_k from a loaded cell, skipping any empty step."
matrices(gv) = [g.p1_state[k].cost for g in gv for k in eachindex(g.p1_state)
                if !isempty(g.p1_state[k].cost)]

function main()
    @printf("Loading Gate B cells (no new sweep) ...\n")
    mm = load_games_vec(NG, NS, "mixed", "mixed")
    ff = load_games_vec(NG, NS, "FP_greedy", "FP_greedy")
    A_all = matrices(mm)
    @printf("  %d games, %d payoff matrices\n\n", length(mm), length(A_all))

    # ------------------------------------------------------- PART 1
    println("="^80)
    println("C3.1 — FROZEN MATRIX: Robinson's setting, on real payoff matrices")
    println("FP empirical play must converge to the LP equilibrium. This is the only")
    println("regime where the classical theorem applies.")
    println("="^80)
    rng = MersenneTwister(1)
    sample = A_all[rand(rng, 1:length(A_all), 200)]
    cps = [10, 100, 1_000, 10_000]
    curves = [frozen_fp(A, cps) for A in sample]
    @printf("  %-12s %14s %14s %14s\n", "iterations", "median NashConv", "p90", "max")
    for (c, T) in enumerate(cps)
        v = [cu[c] for cu in curves]
        @printf("  %-12d %14.3e %14.3e %14.3e\n", T, median(v), quantile(v, 0.9), maximum(v))
    end
    rate(stat) = log(stat([cu[end] for cu in curves]) / stat([cu[1] for cu in curves])) /
                 log(cps[end] / cps[1])
    @printf("\n  empirical rate over 10 -> 10,000 iterations: NashConv ~ T^%.2f (median)\n",
            rate(median))
    # The tail is what a reviewer asks about: does FP converge on EVERY sampled matrix?
    @printf("  tail rates: p90 ~ T^%.2f, max ~ T^%.2f\n",
            rate(v -> quantile(v, 0.9)), rate(maximum))
    println("  (FP in zero-sum games converges; the rate is known to be slow and")
    println("   problem-dependent, which is itself an argument for C2's no-regret learner,")
    println("   whose O(1/sqrt(T)) bound is uniform.)")

    # ------------------------------------------------------- PART 2
    println("\n" * "="^80)
    println("C3.2 — HOW FAST DOES THE GAME MOVE? the variation budget")
    println("If the stage game barely moves, pooling beliefs across steps is defensible.")
    println("If it moves a lot, it is not. This measures which.")
    println("="^80)
    dA, dV, dP, relA = Float64[], Float64[], Float64[], Float64[]
    for g in mm
        ks = [k for k in eachindex(g.p1_state) if !isempty(g.p1_state[k].cost)]
        for idx in 1:length(ks)-1
            A1, A2 = g.p1_state[ks[idx]].cost, g.p1_state[ks[idx+1]].cost
            size(A1) == size(A2) || continue
            push!(dA, norm(A2 - A1))
            push!(relA, norm(A2 - A1) / norm(A1))
            s1, s2 = solve_mixed_nash(A1), solve_mixed_nash(A2)
            push!(dV, abs(s2.V - s1.V))
            push!(dP, norm(normalize_simplex(s1.x) - normalize_simplex(s2.x), 1))
        end
    end
    @printf("  %-42s median %10.4f   p90 %10.4f\n", "||A_{k+1} - A_k||_F", median(dA), quantile(dA, 0.9))
    @printf("  %-42s median %9.2f%%   p90 %9.2f%%\n", "  as a fraction of ||A_k||",
            100median(relA), 100quantile(relA, 0.9))
    @printf("  %-42s median %10.4f   p90 %10.4f\n", "|V_{k+1} - V_k|  (game value, km)",
            median(dV), quantile(dV, 0.9))
    @printf("  %-42s median %10.4f   p90 %10.4f\n", "||p*_{k+1} - p*_k||_1  (equilibrium mix)",
            median(dP), quantile(dP, 0.9))
    @printf("\n  The value moves %.1f%% as much as the matrix does, but the equilibrium\n",
            100 * median(dV) / max(median(dA), eps()))
    @printf("  STRATEGY moves by %.3f in L1 per step (max possible 2.0) — that is the\n", median(dP))
    println("  number the cross-step-pooling assumption actually rests on.")

    # ------------------------------------------------------- PART 3
    println("\n" * "="^80)
    println("C3.3 — TRACKING, NOT CONVERGENCE: exploitability of realized empirical play")
    println("FP_greedy vs FP_greedy. Robinson does NOT apply — the matrix moves between")
    println("steps. The honest claim is that empirical play tracks the moving equilibrium.")
    println("="^80)
    bins = [(1, 5), (6, 10), (11, 15), (16, 20), (21, 25), (26, 30)]
    @printf("  %-22s", "steps"); for (a, b) in bins; @printf("%12s", "$a-$b"); end; println()
    emp, nash = Dict{Int,Vector{Float64}}(), Dict{Int,Vector{Float64}}()
    for g in ff, k in eachindex(g.p1_state)
        p1, p2 = g.p1_state[k], g.p2_state[k]
        isempty(p1.cost) && continue
        # empirical frequencies each player has actually accumulated about the other
        push!(get!(emp, k, Float64[]),
              exploitability(p1.cost, normalize_simplex(p2.fp_belief),
                                      normalize_simplex(p1.fp_belief)).nashconv)
        # the stage-game equilibrium at the same step, as the floor
        s = solve_mixed_nash(p1.cost)
        push!(get!(nash, k, Float64[]), exploitability(p1.cost, s.x, s.y).nashconv)
    end
    for (label, D) in (("empirical play NashConv", emp), ("stage Nash NashConv", nash))
        @printf("  %-22s", label)
        for (a, b) in bins
            v = vcat([get(D, k, Float64[]) for k in a:b]...)
            isempty(v) ? @printf("%12s", "-") : @printf("%12.2e", median(v))
        end
        println()
    end
    allemp = vcat(values(emp)...)
    @printf("\n  Empirical play is exploitable by a median of %.3f km across all steps;\n", median(allemp))
    @printf("  the stage equilibrium by %.1e (that is the LP's own residual, i.e. zero).\n",
            median(vcat(values(nash)...)))
    println("  Report this as a TRACKING gap against the variation budget in C3.2 —")
    println("  never as Robinson convergence, which the moving matrix forbids.")
end

main()
