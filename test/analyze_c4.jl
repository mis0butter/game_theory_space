# =============================================================================
# C4 — vertex ablation: does the lifted value converge as the action set refines?
#
#   julia -t 8 --project=. test/analyze_c4.jl
#
# The paper's supporting lemma is that the LIFTING is faithful: we replace a
# continuous trajectory game with a finite one over M vertices, and the safety
# claim is worth exactly as much as that replacement is. C5 supplies the bound
#
#       |V_M - V_cont|  <=  L * h_M
#
# with h_M the covering radius of the vertex set on the polygon's circumcircle.
# For M equally spaced vertices at circumradius R, the worst-case point sits at
# the midpoint of an arc, so
#
#       h_M = 2 R sin(pi / 2M)
#
# which halves each time M doubles. C4 supplies the empirical half: V_M measured
# at M = 6, 12, 24. If |V_M - V_cont| really is O(h_M), successive differences
# should shrink by ~2x per doubling, and Richardson extrapolation on that model
# gives both an estimate of V_cont and an empirical Lipschitz constant.
#
# n=6 comes from the Gate B cells (its code path is bitwise-preserved, so it was
# not re-run); 12 and 24 come from test/results/n30_v{12,24}/.
# =============================================================================

using trajectory_optimization_game_theory
using LinearAlgebra, Random, Statistics, Printf

const NG, NS    = 100, 30
const ARITIES   = [6, 12, 24]
const MATCHUPS  = [("mixed", "mixed"), ("FP_greedy", "mixed")]
const R_POLYGON = 6.378

"Covering radius of M equally spaced vertices on a circle of radius R."
covering_radius(M, R = R_POLYGON) = 2R * sin(pi / (2M))

"Per-step LP values and per-game mean separation from a saved cell."
function cell_stats(n, p1, p2)
    gv = load_games_vec(NG, NS, p1, p2; n_vertices = n)
    V   = Float64[]
    sep = Float64[]
    cert = Float64[]
    Vg  = Float64[]                     # per-game mean LP value, for pairing across arities
    ic  = Any[]                         # realized IC draw, to verify CRN before pairing
    for g in gv
        s = Float64[]
        vg = Float64[]
        for k in eachindex(g.p1_state)
            si = g.p1_state[k].solve_info
            if !isempty(g.p1_state[k].cost) && hasproperty(si, :lp) && si.lp !== nothing
                push!(V, si.lp.V)
                push!(vg, si.lp.V)
                push!(cert, si.lp.cert_violation)
            end
            r1, r2 = g.p1_state[k].rv_chosen, g.p2_state[k].rv_chosen
            (isempty(r1) || isempty(r2)) && continue
            append!(s, [norm(r1[i, 1:3] - r2[i, 1:3]) for i in axes(r1, 1)])
        end
        isempty(s) || push!(sep, mean(s))
        push!(Vg, mean(vg))
        push!(ic, g.params[1].ic)
    end
    (; V, sep, cert, Vg, ic, n_games = length(gv))
end

meanci(v) = (mean(v), 1.96 * std(v) / sqrt(length(v)))

function main()
    avail = [n for n in ARITIES if all(isfile(joinpath(results_folder(NS, p1, p2, n),
                                                       "games_$(NG).jld2")) for (p1, p2) in MATCHUPS)]
    @printf("Arities with complete data: %s\n", string(avail))
    length(avail) < 2 && (println("Need at least two arities; C4 sweep still running."); return)

    S = Dict((n, m) => cell_stats(n, m...) for n in avail, m in MATCHUPS)

    println("\n" * "="^84)
    println("C4 — LIFTED VALUE vs ACTION-SET SIZE")
    println("V_M is the per-step LP value of the lifted stage game, averaged over all steps")
    println("and games. h_M = 2R sin(pi/2M) is the covering radius the C5 bound scales with.")
    println("="^84)
    @printf("  %-4s %-10s %22s %14s %14s\n", "M", "h_M [km]", "V_M [km] (mean ± CI)", "mean sep", "max LP cert")
    for n in avail
        st = S[(n, ("mixed", "mixed"))]
        v, h = meanci(st.V)
        s, sh = meanci(st.sep)
        @printf("  %-4d %-10.4f %14.4f ± %-5.4f %8.3f±%-5.3f %14.1e\n",
                n, covering_radius(n), v, h, s, sh, maximum(st.cert))
    end

    # ---- convergence of the value, and the C5 bound's empirical constant
    println("\n" * "="^84)
    println("CONVERGENCE — successive differences, and what they imply for |V_M - V_cont|")
    println("="^84)
    Vs = Dict(n => mean(S[(n, ("mixed", "mixed"))].V) for n in avail)
    for i in 1:length(avail)-1
        a, b = avail[i], avail[i+1]
        dV = Vs[b] - Vs[a]
        dh = covering_radius(a) - covering_radius(b)
        @printf("  V_%-2d -> V_%-2d : ΔV = %+8.4f km   Δh = %6.4f km   |ΔV|/Δh = %.4f\n",
                a, b, dV, dh, abs(dV) / dh)
    end
    if length(avail) >= 3
        a, b, c = avail[end-2], avail[end-1], avail[end]
        d1, d2 = Vs[b] - Vs[a], Vs[c] - Vs[b]
        @printf("\n  ratio of successive differences: %.2f", abs(d2) / abs(d1))
        println("   (O(h_M) predicts ~0.50 as M doubles)")
        # Richardson on the model V_M = V_cont + C h_M
        hb, hc = covering_radius(b), covering_radius(c)
        V_cont = Vs[c] + (Vs[c] - Vs[b]) * hc / (hb - hc)
        L̂ = abs(Vs[c] - Vs[b]) / (hb - hc)
        @printf("  extrapolated V_cont ≈ %.4f km   (V_%d is within %.4f km of it, %.2f%%)\n",
                V_cont, c, abs(Vs[c] - V_cont), 100abs(Vs[c] - V_cont) / abs(V_cont))
        @printf("  implied Lipschitz constant L ≈ %.4f  (bound: |V_M - V_cont| <= L h_M)\n", L̂)
    else
        println("\n  (a third arity is needed before the ratio and Richardson extrapolation)")
    end

    # ---- paired intervals on the value differences
    # The table's ± treats all 3,000 step values as independent; steps within a game
    # are correlated, so it understates the uncertainty. The honest unit is the game:
    # under CRN, game k shares its ICs across arities, so per-game mean values pair.
    println("\n" * "="^84)
    println("PAIRED VALUE DIFFERENCES (unit = game; CRN pairs game k across arities)")
    println("="^84)
    st = Dict(n => S[(n, ("mixed", "mixed"))] for n in avail)
    for n in avail
        @printf("  CRN check M=%-2d vs M=%-2d: %s\n", n, avail[1], st[n].ic == st[avail[1]].ic ? "ICs identical" : "ICs DIFFER — pairing invalid")
    end
    for n in avail
        v, h = meanci(st[n].Vg)
        @printf("  V_%-2d per-game: %.4f ± %.4f   (per-step ± was %.4f)\n", n, v, h, meanci(st[n].V)[2])
    end
    for (a, b) in [(avail[i], avail[j]) for i in eachindex(avail) for j in i+1:length(avail)]
        d = st[a].Vg .- st[b].Vg
        se = std(d) / sqrt(length(d))
        @printf("  V_%-2d - V_%-2d = %+.4f ± %.4f  (t = %+.1f; %.2f%% of V_%d; unpaired ± would be %.4f)\n",
                a, b, mean(d), 1.96se, mean(d) / se, 100mean(d) / mean(st[b].Vg), b,
                1.96sqrt(var(st[a].Vg) / length(d) + var(st[b].Vg) / length(d)))
    end
    if length(avail) >= 3
        # bootstrap over games (jointly across arities, preserving the pairing)
        a, b, c = avail[end-2], avail[end-1], avail[end]
        hb, hc = covering_radius(b), covering_radius(c)
        rng = MersenneTwister(2026)
        N = length(st[a].Vg)
        Vc = Float64[]; dist = Float64[]; ratio = Float64[]
        for _ in 1:10_000
            ix = rand(rng, 1:N, N)
            va, vb, vc = mean(st[a].Vg[ix]), mean(st[b].Vg[ix]), mean(st[c].Vg[ix])
            vcont = vc + (vc - vb) * hc / (hb - hc)
            push!(Vc, vcont); push!(dist, 100abs(va - vcont) / abs(vcont))
            push!(ratio, abs(vc - vb) / abs(vb - va))
        end
        qq(v) = (quantile(v, 0.025), quantile(v, 0.975))
        @printf("\n  bootstrap (10,000 resamples of games):\n")
        @printf("    V_cont            [%.4f, %.4f]\n", qq(Vc)...)
        @printf("    V_%d to V_cont    [%.2f%%, %.2f%%]\n", a, qq(dist)...)
        @printf("    diff ratio        [%.2f, %.2f]   (O(h_M) predicts 0.50)\n", qq(ratio)...)
    end

    # ---- does the headline survive refinement?
    println("\n" * "="^84)
    println("DOES THE EXPLOITATION RESULT SURVIVE REFINEMENT?")
    println("If FP_greedy's edge over the Nash evader is an artifact of a coarse 6-vertex")
    println("action set, it should shrink as M grows. A reviewer will ask.")
    println("="^84)
    @printf("  %-4s %18s %18s %18s\n", "M", "mixed vs mixed", "FP_greedy vs mixed", "FP edge [km]")
    for n in avail
        a = S[(n, ("mixed", "mixed"))].sep
        b = S[(n, ("FP_greedy", "mixed"))].sep
        ma, ha = meanci(a); mb, hb = meanci(b)
        d = b .- a                      # paired: CRN means game k shares ICs across cells
        se = std(d) / sqrt(length(d))
        @printf("  %-4d %11.3f±%-5.3f %11.3f±%-5.3f %+11.3f ± %-5.3f  t=%+.1f\n",
                n, ma, ha, mb, hb, mean(d), 1.96se, mean(d) / se)
    end
end

main()
