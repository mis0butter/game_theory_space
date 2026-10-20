# =============================================================================
# ECC 2027 paper figures, from the 32-core Gate B / B6 data. No new sweep
# except F1, which re-runs ONE 10-step game unslimmed (slim files drop the
# candidate trajectories it draws).
#
#   julia -t 8 --project=. test/figures_paper.jl
#
# Writes vector PDFs at true size to Game_Theory_Space_ECC_2027/images/fig_*.pdf
# and PNG previews to figures/paper/. Prints every number it plots, so each
# figure can be cross-checked against LOG.md before it goes in the paper.
#
#   F1  fig_game_step        one game step, steps 2/5/10 (regenerates k_replan_*)
#   F2  fig_heatmap          5×5 mean separation, windows S = 5/10/30 (regenerates heatmap)
#   F3  fig_boxplot          per-game separation by strategy and window (regenerates boxplot)
#   F4  fig_dv_vs_sep        executed ΔV vs separation per matchup (regenerates ΔV scatter)
#   F5  fig_price_of_safety  separation vs step: oracle / FP / minimax pursuers (new)
#   F6  fig_learning         separation vs step and paired FP − minimax gap (new)
#
# Truncating to a window S is exact, not an approximation: the game is causal
# and nothing in a step depends on the total length, so the first S steps of a
# 30-step game are the S-step game.
# =============================================================================

using trajectory_optimization_game_theory
# CairoMakie MUST be loaded after the package (src/ pulls in GLMakie; the backend
# activated last owns `save`).
using CairoMakie
CairoMakie.activate!(type = "pdf")
using LinearAlgebra, Random, Statistics, Printf

const NG, NS   = 100, 30
const STRATS   = ["FP_greedy", "FP_mixed", "greedy", "mixed", "random"]
const LABEL    = Dict("FP_greedy" => "FP-greedy", "FP_mixed" => "FP-mixed", "greedy" => "Greedy",
                      "mixed" => "Minimax", "random" => "Random", "oracle" => "Oracle")
const WINDOWS  = [5, 10, 30]
const R_HARD   = 0.2
const ROOT     = pkgdir(trajectory_optimization_game_theory)
const OUTDIR   = joinpath(ROOT, "Game_Theory_Space_ECC_2027", "images")
const PREVIEW  = joinpath(ROOT, "figures", "paper")
mkpath(OUTDIR); mkpath(PREVIEW)

# ---------------------------------------------------------------- style
# ieeeconf: 252 pt single column, 516 pt double. Fonts match the paper's Times.
const COL1, COL2 = 252, 516

# Reference categorical palette (dataviz skill, light mode), in its fixed order.
# One color per strategy across EVERY figure; line style is the redundant cue so
# the figures survive grayscale printing.
const C = Dict("mixed" => "#2a78d6", "FP_greedy" => "#eb6834", "oracle" => "#1baf7a",
               "greedy" => "#eda100", "random" => "#e87ba4", "FP_mixed" => "#008300")
const C_E, C_P = "#2a78d6", "#eb6834"          # evader / pursuer (F1, F4)
const INK, MUTED = "#1a1a19", "#6b6a63"
const BLUES = ["#cde2fb", "#9ec5f4", "#6da7ec", "#3987e5", "#256abf", "#184f95", "#0d366b"]
const WIN_C = ["#86b6ef", "#2a78d6", "#104281"]  # ordinal window S = 5/10/30

function pick_font()
    # to_font never throws: an unknown name silently falls back, so check what resolved
    for f in ("TeX Gyre Termes", "Nimbus Roman", "Times New Roman")
        fam = CairoMakie.Makie.to_font(f).family_name
        lowercase(fam) == lowercase(f) && return f
    end
    @warn "no Times-like font found; using Makie's default sans"
    "TeX Gyre Heros"
end
const FONT = pick_font()

set_theme!(Theme(
    fontsize = 8, figure_padding = (2, 6, 2, 2),
    fonts = (; regular = FONT, bold = FONT * " Bold", italic = FONT * " Italic"),
    textcolor = INK,
    Axis = (xgridvisible = false, ygridvisible = true, ygridcolor = (:black, 0.07),
            ygridwidth = 0.5, spinewidth = 0.6, xtickwidth = 0.6, ytickwidth = 0.6,
            xticksize = 3, yticksize = 3, titlesize = 8, titlefont = :regular,
            titlealign = :left, topspinevisible = false, rightspinevisible = false),
    Legend = (framevisible = false, labelsize = 7, patchsize = (14, 6), rowgap = 0,
              colgap = 6, padding = (0, 0, 0, 0)),
))

function savefig(fig, name)
    save(joinpath(OUTDIR, name * ".pdf"), fig; pt_per_unit = 1)
    save(joinpath(PREVIEW, name * ".png"), fig; px_per_unit = 4)
    println("  wrote images/$name.pdf")
end

meanci(v) = (m = mean(v); (m, 1.96std(v) / sqrt(length(v))))

# ---------------------------------------------------------------- data
"Per-step mean separation (NG × NS), whole-window mean separations, executed ΔV."
function cell(p1, p2)
    gv = load_games_vec(NG, NS, p1, p2)
    step_sep = fill(NaN, length(gv), NS)
    win = Dict(S => Float64[] for S in WINDOWS)
    dv1, dv2 = Float64[], Float64[]
    for (gi, g) in enumerate(gv)
        s = separation_series(g)
        for k in 1:NS
            step_sep[gi, k] = mean(s.d[s.k .== k])
        end
        for S in WINDOWS
            push!(win[S], mean(s.d[s.k .<= S]))
        end
        push!(dv1, sum(sum(norm, eachrow(st.U_chosen)) for st in g.p1_state if !isempty(st.U_chosen)))
        push!(dv2, sum(sum(norm, eachrow(st.U_chosen)) for st in g.p2_state if !isempty(st.U_chosen)))
    end
    (; step_sep, win, dv1, dv2)
end

println("Loading cells ...")
const T = Dict((a, b) => cell(a, b) for a in STRATS, b in STRATS)
const B6 = Dict{Tuple{Any,String},Any}((v, p) => cell(string(v), p) for v in 1:6, p in ("oracle", "FP_greedy", "mixed"))
B6[("mixed", "oracle")] = cell("mixed", "oracle")

# ---------------------------------------------------------------- F2 heatmap
function fig_heatmap()
    println("\nF2 — mean separation [km], rows evader, cols pursuer")
    # Each window gets its own colour scale: the windows differ by ~3x in level
    # (the approach from ≈36 km dominates short windows), so a shared scale washes
    # out the S = 30 panel. Colour shows the ranking WITHIN a window; the printed
    # numbers carry the values, so no colourbar.
    fig = Figure(size = (COL2, 170))
    Ms = Dict(S => [mean(T[(a, b)].win[S]) for a in STRATS, b in STRATS] for S in WINDOWS)
    labs = [LABEL[s] for s in STRATS]
    for (i, S) in enumerate(WINDOWS)
        M = Ms[S]
        lo, hi = extrema(M)
        @printf("  S = %d\n", S)
        for (r, a) in enumerate(STRATS)
            @printf("    %-10s %s\n", a, join([@sprintf("%5.2f", M[r, c]) for c in 1:5], " "))
        end
        ax = Axis(fig[1, i]; title = "First S = $S steps [km]", aspect = DataAspect(),
                  xticks = (1:5, labs), yticks = (1:5, labs), xticklabelrotation = π / 4,
                  yreversed = true, xlabel = "Pursuer", ylabel = i == 1 ? "Evader" : "",
                  yticklabelsvisible = i == 1, ygridvisible = false,
                  topspinevisible = true, rightspinevisible = true)
        heatmap!(ax, 1:5, 1:5, permutedims(M); colormap = BLUES[1:6], colorrange = (lo, hi))
        for r in 1:5, c in 1:5
            v = M[r, c]
            text!(ax, c, r; text = @sprintf("%.2f", v), align = (:center, :center), fontsize = 6.5,
                  color = v > lo + 0.6(hi - lo) ? :white : INK)
        end
    end
    colgap!(fig.layout, 6)
    savefig(fig, "fig_heatmap")
end

# ---------------------------------------------------------------- F3 boxplot
function fig_boxplot()
    println("\nF3 — per-game mean separation by strategy (pooled over the 5 opponents)")
    fig = Figure(size = (COL1, 250))
    for (row, role) in enumerate(("Evader", "Pursuer"))
        ax = Axis(fig[row, 1]; ylabel = "Separation [km]", title = "($(('a','b')[row])) $role strategy",
                  xticks = (1:5, [LABEL[s] for s in STRATS]))
        for (w, S) in enumerate(WINDOWS)
            xs, ys = Float64[], Float64[]
            for (i, s) in enumerate(STRATS)
                v = role == "Evader" ? vcat((T[(s, o)].win[S] for o in STRATS)...) :
                                       vcat((T[(o, s)].win[S] for o in STRATS)...)
                append!(xs, fill(i, length(v))); append!(ys, v)
                S == 30 && @printf("  %-7s %-10s S=30  median %.2f  mean %.2f  (n=%d)\n", role, s, median(v), mean(v), length(v))
            end
            boxplot!(ax, xs, ys; dodge = fill(w, length(xs)), n_dodge = 3, color = WIN_C[w],
                     width = 0.75, gap = 0.25, dodge_gap = 0.05, markersize = 1.5, whiskerwidth = 0.4, whiskerlinewidth = 0.6,
                     strokewidth = 0.4, strokecolor = INK, mediancolor = :white, medianlinewidth = 0.8,
                     outliercolor = (MUTED, 0.5))
        end
        row == 1 && hidexdecorations!(ax; grid = false, ticks = false)
    end
    Legend(fig[0, 1], [PolyElement(color = c) for c in WIN_C], ["S = $S" for S in WINDOWS];
           orientation = :horizontal, tellheight = true)
    rowgap!(fig.layout, 4)
    savefig(fig, "fig_boxplot")
end

# ---------------------------------------------------------------- F4 ΔV vs separation
function fig_dv()
    println("\nF4 — executed ΔV per player [m/s] vs mean separation [km], one point per matchup")
    fig = Figure(size = (COL1, 190))
    ax = Axis(fig[1, 1]; xlabel = "Total executed ΔV over 30 steps [m/s]", ylabel = "Mean separation [km]")
    isfp(s) = startswith(s, "FP")
    groups = [("Evader, FP", C_E, :circle, true), ("Evader, non-FP", C_E, :circle, false),
              ("Pursuer, FP", C_P, :utriangle, true), ("Pursuer, non-FP", C_P, :utriangle, false)]
    for (lab, col, mk, fp) in groups
        xs, ys = Float64[], Float64[]
        for a in STRATS, b in STRATS
            s, dv = startswith(lab, "Evader") ? (a, T[(a, b)].dv1) : (b, T[(a, b)].dv2)
            isfp(s) == fp || continue
            push!(xs, 1e3mean(dv)); push!(ys, mean(T[(a, b)].win[30]))
        end
        scatter!(ax, xs, ys; marker = mk, markersize = 6, color = fp ? col : :white,
                 strokecolor = col, strokewidth = 1.0, label = lab)
    end
    for a in STRATS
        @printf("  evader %-10s ΔV %s\n", a, join([@sprintf("%6.1f", 1e3mean(T[(a, b)].dv1)) for b in STRATS], " "))
    end
    for b in STRATS
        @printf("  pursuer %-9s ΔV %s\n", b, join([@sprintf("%6.1f", 1e3mean(T[(a, b)].dv2)) for a in STRATS], " "))
    end
    Legend(fig[0, 1], ax; orientation = :horizontal, nbanks = 2, tellheight = true)
    rowgap!(fig.layout, 2)
    savefig(fig, "fig_dv_vs_sep")
end

# ---------------------------------------------------------------- step curves
function meanband!(ax, M, col; ls = :solid, label = nothing, logy = false)
    m = vec(mean(M; dims = 1))
    h = vec(1.96std(M; dims = 1) ./ sqrt(size(M, 1)))
    lo = logy ? max.(m .- h, 1e-3) : m .- h
    band!(ax, 1:NS, lo, m .+ h; color = (col, 0.18))
    lines!(ax, 1:NS, m; color = col, linewidth = 1.3, linestyle = ls, label = label)
    m
end

const LS = Dict("mixed" => :solid, "FP_greedy" => :dash, "oracle" => :dot)

# ---------------------------------------------------------------- F5 price of safety
function fig_price_of_safety()
    println("\nF5 — per-step mean separation [km] (steps 1, 5, 10, 20, 30)")
    fig = Figure(size = (COL1, 250))
    yt = ([0.1, 0.3, 1, 3, 10, 30], ["0.1", "0.3", "1", "3", "10", "30"])
    axs = [Axis(fig[r, 1]; yscale = log10, yticks = yt, ylabel = "Separation [km]",
                title = r == 1 ? "(a) vs. fixed-vertex evaders (pooled, 600 games)" :
                                 "(b) vs. minimax evader (100 games)") for r in 1:2]
    linkyaxes!(axs...)
    for p in ("mixed", "FP_greedy", "oracle")
        Ma = vcat((B6[(v, p)].step_sep for v in 1:6)...)
        Mb = p == "mixed" ? T[("mixed", "mixed")].step_sep :
             p == "FP_greedy" ? T[("mixed", "FP_greedy")].step_sep : B6[("mixed", "oracle")].step_sep
        for (ax, M, tag) in ((axs[1], Ma, "fixed"), (axs[2], Mb, "minimax"))
            m = meanband!(ax, M, C[p]; ls = LS[p], label = LABEL[p], logy = true)
            @printf("  vs %-7s %-10s %s\n", tag, p, join([@sprintf("%7.3f", m[k]) for k in (1, 5, 10, 20, 30)], " "))
        end
    end
    for ax in axs
        hlines!(ax, R_HARD; color = MUTED, linewidth = 0.6, linestyle = :dashdot)
        text!(ax, NS, R_HARD; text = "hard capture 0.2 km", align = (:right, :bottom),
              fontsize = 6.5, color = MUTED, offset = (0, 1))
        xlims!(ax, 1, NS)
    end
    axs[2].xlabel = "Game step"
    hidexdecorations!(axs[1]; grid = false, ticks = false)
    Legend(fig[0, 1], axs[1], "Pursuer:"; orientation = :horizontal, tellheight = true,
           titleposition = :left, titlefont = :regular, titlesize = 7)
    rowgap!(fig.layout, 4)
    savefig(fig, "fig_price_of_safety")
end

# ---------------------------------------------------------------- F6 learning vs minimax
function fig_learning()
    println("\nF6 — evader FP-greedy vs minimax, per step")
    fig = Figure(size = (COL1, 250))
    ax1 = Axis(fig[1, 1]; ylabel = "Separation [km]",
               title = "(a) Mean separation (steps 1–3: approach from ≈36 km)")
    ax2 = Axis(fig[2, 1]; ylabel = "FP − minimax [km]", xlabel = "Game step",
               title = "(b) Paired gain of the FP-greedy evader")
    for e in ("mixed", "FP_greedy"), p in ("mixed", "FP_greedy")
        meanband!(ax1, T[(e, p)].step_sep, C[e]; ls = p == "mixed" ? :solid : :dash,
              label = "$(LABEL[e]) E vs $(LABEL[p]) P")
    end
    hlines!(ax2, 0; color = MUTED, linewidth = 0.6)
    for p in ("mixed", "FP_greedy")
        D = T[("FP_greedy", p)].step_sep .- T[("mixed", p)].step_sep   # CRN: row k pairs
        m = meanband!(ax2, D, C[p]; ls = LS[p], label = "vs $(LABEL[p]) pursuer")
        whole = mean(T[("FP_greedy", p)].win[30] .- T[("mixed", p)].win[30])
        @printf("  vs %-10s pursuer: steps 1,5,10,20,30 %s   whole-game %+.3f\n", p,
                join([@sprintf("%+6.3f", m[k]) for k in (1, 5, 10, 20, 30)], " "), whole)
    end
    for ax in (ax1, ax2); xlims!(ax, 1, NS); end
    ylims!(ax1, 0, 6.5)
    ylims!(ax2, -1.6, 2.3)
    hidexdecorations!(ax1; grid = false, ticks = false)
    Legend(fig[0, 1], ax1; orientation = :horizontal, nbanks = 2, tellheight = true)
    axislegend(ax2; position = :lt, labelsize = 7, framevisible = false, padding = (2, 2, 0, 0))
    rowgap!(fig.layout, 4)
    savefig(fig, "fig_learning")
end

# ---------------------------------------------------------------- F1 game step
"Rotate the relative position into the reference's local frame: (in-track, cross-track, radial) km."
function ric(r, ref)
    rr, vv = ref[1:3], ref[4:6]
    r̂ = rr / norm(rr); ĉ = cross(rr, vv); ĉ /= norm(ĉ); î = cross(ĉ, r̂)
    d = r[1:3] - rr
    (dot(d, î), dot(d, ĉ), dot(d, r̂))
end

function fig_game_step(; steps = (2, 5, 10), p1 = "mixed", p2 = "mixed", seed = 1)
    println("\nF1 — one game, $p1 vs $p2, rendered at steps $steps (local frame of the evader's reference)")
    g, prm = redirect_stdout(devnull) do
        run_game(MersenneTwister(seed), maximum(steps), p1, p2; disperse = true)
    end
    # sanity: candidate endpoints sit on the hexagon around the reference endpoint
    for k in steps
        ref = g.rv_ref_E[k]
        miss = maximum(abs(norm(X[end, 1:3] - ref[end, 1:3]) - prm.R_polygon)
                       for X in vcat(g.p1_state[k].X, g.p2_state[k].X))
        @printf("  step %2d: max |‖candidate end − hexagon centre‖ − R| = %.1e km\n", k, miss)
    end
    fig = Figure(size = (COL2, 205), figure_padding = (2, 0, 6, 2))
    for (col, k) in enumerate(steps)
        ax = Axis3(fig[1, col]; title = "Game step s = $k", titlesize = 8, titlefont = :regular,
                   xlabel = "in-track [km]", ylabel = "cross [km]", zlabel = "radial [km]",
                   xlabelsize = 7, ylabelsize = 7, zlabelsize = 7, xticklabelsize = 6,
                   yticklabelsize = 6, zticklabelsize = 6, azimuth = 1.32π, elevation = 0.10π, aspect = :data,
                   protrusions = (14, 0, 16, 16), xlabeloffset = 14, ylabeloffset = 14, zlabeloffset = 26,
                   xticks = col == 1 ? (-30:10:0) : (-10:5:5), yticks = -5:5:5,
                   zticks = col == 1 ? (0:10:30) : (-5:5:10))
        # panel 1 shows the whole approach; later panels zoom onto the hexagon, where
        # the game is played once the pursuer arrives (clipped to the axis box)
        col > 1 && limits!(ax, -12, 6, -8, 8, -8, 10)
        ref = g.rv_ref_E[k]
        # traveled paths (previous executed segments), relative to the reference at each time
        for j in 1:k-1, (st, col_) in ((g.p1_state[j], C_E), (g.p2_state[j], C_P))
            rj = g.rv_ref_E[j]
            P = [ric(st.rv_chosen[i, :], rj[i, :]) for i in axes(st.rv_chosen, 1)]
            lines!(ax, first.(P), getindex.(P, 2), last.(P); color = col_, linewidth = 1.4)
        end
        # current candidates: dashed, width ∝ the player's Nash weight
        for (st, col_) in ((g.p1_state[k], C_E), (g.p2_state[k], C_P))
            for (j, X) in enumerate(st.X)
                P = [ric(X[i, :], ref[i, :]) for i in axes(X, 1)]
                w = st.weights[j]
                lines!(ax, first.(P), getindex.(P, 2), last.(P); color = (col_, 0.35 + 0.65w),
                       linewidth = 0.4 + 3.0w, linestyle = (:dash, :dense))
            end
            X = st.X[st.chosen]
            P = ric(X[1, :], ref[1, :])
            scatter!(ax, [P[1]], [P[2]], [P[3]]; color = col_, markersize = 6, strokecolor = :white, strokewidth = 0.6)
        end
        # hexagon at the end of the horizon
        H = [ric(g.p1_state[k].X[j][end, :], ref[end, :]) for j in 1:6]
        H = vcat(H, H[1:1])
        lines!(ax, first.(H), getindex.(H, 2), last.(H); color = MUTED, linewidth = 0.7)
        @printf("  step %2d: evader weights %s  chose %d | pursuer weights %s  chose %d\n", k,
                join([@sprintf("%.2f", w) for w in g.p1_state[k].weights], " "), g.p1_state[k].chosen,
                join([@sprintf("%.2f", w) for w in g.p2_state[k].weights], " "), g.p2_state[k].chosen)
    end
    Legend(fig[0, 1:length(steps)],
           [LineElement(color = C_E, linewidth = 1.4), LineElement(color = C_P, linewidth = 1.4),
            LineElement(color = INK, linestyle = (:dash, :dense), linewidth = 1.2),
            LineElement(color = MUTED, linewidth = 0.7)],
           ["Evader", "Pursuer", "Candidates (width ∝ Nash weight)", "Hexagon of targets"];
           orientation = :horizontal, tellheight = true)
    rowgap!(fig.layout, 0); colgap!(fig.layout, 0)
    savefig(fig, "fig_game_step")
end

# ---------------------------------------------------------------- run
fig_heatmap()
fig_boxplot()
fig_dv()
fig_price_of_safety()
fig_learning()
fig_game_step()
println("\nfont: ", FONT)
