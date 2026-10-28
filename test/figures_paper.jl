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
#   F0  fig_summary          advantage over minimax per strategy, paired CIs (opening results figure)
#   F2  fig_heatmap          6×6 mean separation (incl. type-based), separation AT s = 5/10/30, pursuer on y, one shared red-blue scale
#   F2b fig_heatmap_stacked  S = 10 over S = 30, pursuer on y, evader on x, one shared scale
#   F3  fig_boxplot          per-game separation by strategy, 5-step windows 1-5 / 6-10 / 26-30
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
# The type-based player (Meta_greedy, test/run_meta.jl) is the tournament's sixth strategy.
const STRATS   = ["Meta_greedy", "FP_greedy", "FP_mixed", "greedy", "mixed", "random"]
const NST      = length(STRATS)
const LABEL    = Dict("FP_greedy" => "FP-greedy", "FP_mixed" => "FP-mixed", "greedy" => "Greedy",
                      "mixed" => "Minimax", "random" => "Random", "oracle" => "Oracle",
                      "Meta_greedy" => "Type-based")
const WINDOWS  = [5, 10, 30]
const R_HARD   = 0.2
const ROOT     = pkgdir(trajectory_optimization_game_theory)
# The paper lives in Overleaf; FIG_OUTDIR redirects the PDFs away from the repo copy.
const OUTDIR   = get(ENV, "FIG_OUTDIR", joinpath(ROOT, "Game_Theory_Space_ECC_2027", "images"))
const PREVIEW  = joinpath(ROOT, "figures", "paper")
mkpath(OUTDIR); mkpath(PREVIEW)

# ---------------------------------------------------------------- style
# ieeeconf: 252 pt single column, 516 pt double. Fonts match the paper's Times.
const COL1, COL2 = 252, 516

# Reference categorical palette (dataviz skill, light mode), in its fixed order.
# One color per strategy across EVERY figure; line style is the redundant cue so
# the figures survive grayscale printing.
const C = Dict("mixed" => "#2a78d6", "FP_greedy" => "#eb6834", "oracle" => "#1baf7a",
               "greedy" => "#eda100", "random" => "#e87ba4", "FP_mixed" => "#008300",
               "Meta_greedy" => "#7d52c7")
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
# Computer Modern (Makie's bundled NewComputerModern), for figures styled to look like LaTeX.
const LATEX_FONTS = (; (k => theme_latexfonts().fonts[k][] for k in (:regular, :bold, :italic, :bolditalic))...)
title_S(S) = rich(rich("s", font = :italic), " = $S")   # AT step s (s is the step index)
title_le(S) = rich(rich("s", font = :italic), " ≤ $S")  # steps 1..S
title_rng(a, b) = rich(rich("s", font = :italic), " = $(a)–$(b)")   # steps a..b
"Mean separation over steps a..b of each trial (equal-length steps), averaged over trials."
win_step(p1, p2, a, b) = mean(mean(T[(p1, p2)].step_sep[g, a:b]) for g in axes(T[(p1, p2)].step_sep, 1))
# Separation AT step S (mean over that step's executed segments), averaged over trials.
at_step(a, b, S) = mean(T[(a, b)].step_sep[:, S])

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

"""
Crop a PDF in place to its drawn content plus `pad` pt, so the page is exactly the
figure (Makie's canvas keeps empty margins). Needs Ghostscript; skipped if absent.
"""
function crop_pdf!(path; pad = 1.0)
    gs = Sys.which("gs")
    gs === nothing && (@warn "gs not found; $path left uncropped"; return)
    err = IOBuffer()                      # the bbox device reports on stderr
    run(pipeline(`$gs -q -dNOPAUSE -dBATCH -sDEVICE=bbox $path`; stdout = devnull, stderr = err))
    m = match(r"%%HiResBoundingBox: ([\d.]+) ([\d.]+) ([\d.]+) ([\d.]+)", String(take!(err)))
    m === nothing && (@warn "no bounding box for $path"; return)
    x0, y0, x1, y1 = parse.(Float64, m.captures)
    x0, y0, x1, y1 = x0 - pad, y0 - pad, x1 + pad, y1 + pad
    tmp = path * ".crop.pdf"
    run(pipeline(`$gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -o $tmp
                  -dDEVICEWIDTHPOINTS=$(round(Int, ceil(x1 - x0))) -dDEVICEHEIGHTPOINTS=$(round(Int, ceil(y1 - y0)))
                  -dFIXEDMEDIA -c "<</PageOffset [$(-x0) $(-y0)]>> setpagedevice" -f $path`))
    mv(tmp, path; force = true)
end

function savefig(fig, name)
    save(joinpath(OUTDIR, name * ".pdf"), fig; pt_per_unit = 1)
    crop_pdf!(joinpath(OUTDIR, name * ".pdf"))
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
# Diverging red <-> blue around a gray midpoint (dataviz reference pair). The
# midpoint is minimax vs minimax: red = closer than equilibrium play (pursuer's
# favor), blue = farther (evader's favor).
const DIVERGING = ["#6b2508", "#a8431a", "#eb6834", "#f5b896", "#f0efec",     # burnt orange arm
                   "#9fb9de", "#5f87c0", "#355f9e", "#22406f"]                # steel blue arm (one step deeper)

# One sequential ramp per window, applied REVERSED (darker = closer, lighter = farther): a muted steel
# blue, a muted lavender, and the palette's orange.
const RAMP_S = Dict(
    5  => ["#e6eef8", "#c6d7ee", "#a1bde2", "#7ba0d3", "#5a84c2", "#4069a8", "#2c4f85"],   # steel blue
    10 => ["#efe9f4", "#dccfe8", "#c2aed6", "#a68bc2", "#8a6aab", "#6c4f8c", "#4d3766"],   # muted lavender
    30 => ["#fde6da", "#f9c4a8", "#f39b72", "#eb6834", "#c94f1e", "#9a3a14", "#6b2508"])   # palette orange

const WIN5 = [(1, 5), (6, 10), (26, 30)]   # trailing 5-step windows

function fig_heatmap()
    # Mean separation over a trailing 5-STEP WINDOW (steps 1-5, 6-10, 26-30), averaged
    # over trials: unlike the running mean from step 1 (fig_heatmap_alltime), later panels
    # are not diluted by the opening approach. Pursuer on y, evader on x; per-panel
    # sequential ramps (steel blue / lavender / orange), darker = closer, colour depth
    # growing with each panel's range (sqrt of the ratio). Random pursuer omitted.
    PURS = filter(!=("random"), STRATS)
    NP = length(PURS)
    println("\nF2 — mean separation over 5-step windows [km], rows pursuer, cols evader")
    fig = Figure(size = (COL2, 175), fonts = LATEX_FONTS)
    Ms = Dict(w => [win_step(a, b, w...) for a in STRATS, b in PURS] for w in WIN5)   # [evader, pursuer]
    # The two post-approach windows (6-10, 26-30) cover nearly the same range, so they
    # share ONE range: equal km get equal depth in both, despite the different hues.
    late = WIN5[2:end]
    lo_l = minimum(minimum(Ms[w]) for w in late); hi_l = maximum(maximum(Ms[w]) for w in late)
    span_max = max(hi_l - lo_l, -(reverse(extrema(Ms[WIN5[1]]))...))
    for (i, w) in enumerate(WIN5)
        M = Ms[w]
        lo, hi = w in late ? (lo_l, hi_l) : extrema(M)
        frac = sqrt((hi - lo) / span_max)
        # late windows share the orange ramp and ONE colourbar; the approach window is blue
        g = cgrad(reverse(RAMP_S[w in late ? 30 : 5]))   # dark (close) -> light (far)
        cmap = [g[t] for t in range(1 - frac, 1; length = 64)]
        @printf("  s = %d-%d   range [%.2f, %.2f]   depth %.0f%% of ramp\n", w..., lo, hi, 100frac)
        for (c, b) in enumerate(PURS)
            @printf("    P %-11s %s\n", b, join([@sprintf("%5.2f", M[r, c]) for r in 1:NST], " "))
        end
        ax = Axis(fig[1, 2i-1]; title = title_rng(w...), aspect = DataAspect(),
                  xticks = (1:NST, [LABEL[s] for s in STRATS]), yticks = (1:NP, [LABEL[s] for s in PURS]),
                  xticklabelrotation = π / 4, xticksvisible = false, yticksvisible = false,
                  yreversed = false,   # type-based at the bottom-left corner of both axes
                  xlabel = "Evader", ylabel = i == 1 ? "Pursuer" : "",
                  yticklabelsvisible = i == 1, ygridvisible = false)   # left/bottom spines only
        hm = heatmap!(ax, 1:NST, 1:NP, M; colormap = cmap, colorrange = (lo, hi))
        # one bar per panel for a balanced layout; the 6-10 and 26-30 bars are identical
        Colorbar(fig[1, 2i], hm; label = i == length(WIN5) ? "Mean separation [km]" : "",
                 width = 5, ticksize = 2, ticklabelsize = 6.5, labelsize = 7,
                 tellheight = false, height = Relative(0.62),
                 spinewidth = 0)   # no border; per-side spine flags are ignored in Makie 0.22
    end
    for i in 1:length(WIN5)
        colgap!(fig.layout, 2i - 1, 3)
    end
    savefig(fig, "fig_heatmap")
end

function fig_heatmap_alltime()
    # Mean separation over steps 1..s for s = 5/10/30 (each trial's time-average, then
    # averaged over trials), pursuer on y, evader on x. Each panel has ITS OWN sequential
    # ramp (steel blue / lavender / orange) and colourbar, darker = closer; colour depth
    # grows with the panel's range (sqrt of the ratio to the widest). The s ≤ 30 panel
    # is the whole-game mean the results text quotes. Random pursuer omitted.
    PURS = filter(!=("random"), STRATS)
    NP = length(PURS)
    println("\nF2 — mean separation over steps 1..s [km], rows pursuer, cols evader (random pursuer omitted)")
    fig = Figure(size = (COL2, 175), fonts = LATEX_FONTS)
    Ms = Dict(S => [mean(T[(a, b)].win[S]) for a in STRATS, b in PURS] for S in WINDOWS)   # [evader, pursuer]
    span_max = maximum(-(reverse(extrema(M))...) for M in values(Ms))
    for (i, S) in enumerate(WINDOWS)
        M = Ms[S]
        lo, hi = extrema(M)
        frac = sqrt((hi - lo) / span_max)
        g = cgrad(reverse(RAMP_S[S]))                 # dark (close) -> light (far)
        cmap = [g[t] for t in range(1 - frac, 1; length = 64)]
        @printf("  s ≤ %d   range [%.2f, %.2f]   depth %.0f%% of ramp\n", S, lo, hi, 100frac)
        ax = Axis(fig[1, 2i-1]; title = title_le(S), aspect = DataAspect(),
                  xticks = (1:NST, [LABEL[s] for s in STRATS]), yticks = (1:NP, [LABEL[s] for s in PURS]),
                  xticklabelrotation = π / 4, xticksvisible = false, yticksvisible = false,
                  yreversed = false,   # type-based at the bottom-left corner of both axes
                  xlabel = "Evader", ylabel = i == 1 ? "Pursuer" : "",
                  yticklabelsvisible = i == 1, ygridvisible = false)   # left/bottom spines only
        hm = heatmap!(ax, 1:NST, 1:NP, M; colormap = cmap, colorrange = (lo, hi))
        Colorbar(fig[1, 2i], hm; label = i == length(WINDOWS) ? "Mean separation [km]" : "",
                 width = 5, ticksize = 2, ticklabelsize = 6.5, labelsize = 7,
                 tellheight = false, height = Relative(0.62),
                 spinewidth = 0)   # no border; per-side spine flags are ignored in Makie 0.22
    end
    for i in 1:length(WINDOWS)
        colgap!(fig.layout, 2i - 1, 3)
    end
    savefig(fig, "fig_heatmap_alltime")
end

function fig_heatmap_at()
    # Separation AT step s = 5/10/30 (averaged over trials), pursuer on y, evader on x.
    # At-step values span similar ranges in every panel (~0.2-4.5 km; the approach from
    # ≈36 km no longer inflates the early panel), so all three share ONE colour scale and
    # one colourbar. White = minimax vs minimax (mean of the three steps): red = closer than
    # equilibrium play (pursuer's favor), blue = farther (evader's favor). Equal km from
    # white get equal colour strength on both sides; the bar spans only the data range.
    # The random PURSUER row is left out: it ignores the payoff matrix, so it is never
    # a sensible pursuer. Random stays as an evader (the unpredictable baseline).
    PURS = filter(!=("random"), STRATS)
    NP = length(PURS)
    println("\nF2 — separation AT step s [km], rows pursuer, cols evader (random pursuer omitted)")
    fig = Figure(size = (COL2, 175), fonts = LATEX_FONTS)
    Ms = Dict(S => [at_step(a, b, S) for a in STRATS, b in PURS] for S in WINDOWS)   # [evader, pursuer]
    lo = minimum(minimum.(values(Ms))); hi = maximum(maximum.(values(Ms)))
    jm, im = findfirst(==("mixed"), PURS), findfirst(==("mixed"), STRATS)
    mid = mean(Ms[S][im, jm] for S in WINDOWS)
    d = max(mid - lo, hi - mid)
    g = cgrad(DIVERGING)                              # symmetric about mid over [mid-d, mid+d]
    cmap = [g[t] for t in range((lo - mid + d) / 2d, (hi - mid + d) / 2d; length = 128)]
    @printf("  shared scale [%.2f, %.2f] km, white at minimax/minimax = %.2f km (steps: %s)\n", lo, hi, mid,
            join([@sprintf("%.2f", Ms[S][im, jm]) for S in WINDOWS], ", "))
    local hm
    for (i, S) in enumerate(WINDOWS)
        M = Ms[S]
        @printf("  s = %d\n", S)
        for (c, b) in enumerate(PURS)
            @printf("    P %-11s %s\n", b, join([@sprintf("%5.2f", M[r, c]) for r in 1:NST], " "))
        end
        ax = Axis(fig[1, i]; title = title_S(S), aspect = DataAspect(),
                  xticks = (1:NST, [LABEL[s] for s in STRATS]), yticks = (1:NP, [LABEL[s] for s in PURS]),
                  xticklabelrotation = π / 4, xticksvisible = false, yticksvisible = false,
                  yreversed = false,   # type-based at the bottom-left corner of both axes
                  xlabel = "Evader", ylabel = i == 1 ? "Pursuer" : "",
                  yticklabelsvisible = i == 1, ygridvisible = false)   # left/bottom spines only
        hm = heatmap!(ax, 1:NST, 1:NP, M; colormap = cmap, colorrange = (lo, hi))
        # no numbers in the cells (author's choice); the values print to stdout above
    end
    Colorbar(fig[1, length(WINDOWS) + 1], hm; label = "Separation [km]",
             width = 5, ticksize = 2, ticklabelsize = 6.5, labelsize = 7,
             tellheight = false, height = Relative(0.62),
             spinewidth = 0)   # no border; per-side spine flags are ignored in Makie 0.22
    colgap!(fig.layout, 8)
    savefig(fig, "fig_heatmap_at")
end

"""
F2b — S = 10 and S = 30 only, stacked (S = 10 on top), one column wide, with the
roles flipped: pursuer on y, evader on x. ONE colour scale shared by both panels
(min to max over both), so equal numbers get equal colours across panels. With no
meaningful reference value the scale is SEQUENTIAL, one hue (darker = closer),
not diverging.
Random pursuer omitted, as in F2.
"""
function fig_heatmap_stacked()
    PURS = filter(!=("random"), STRATS)
    NP = length(PURS)
    Ms = Dict(S => [at_step(a, b, S) for a in STRATS, b in PURS] for S in (10, 30))  # [evader, pursuer], AT step S
    lo = minimum(minimum.(values(Ms))); hi = maximum(maximum.(values(Ms)))
    println("\nF2b — mean separation [km], stacked S = 10 / 30, rows pursuer, cols evader")
    @printf("  shared scale [%.2f, %.2f]\n", lo, hi)
    fig = Figure(size = (COL1, 330), fonts = LATEX_FONTS)
    local hm
    for (i, S) in enumerate((10, 30))
        M = Ms[S]
        last = i == 2
        ax = Axis(fig[i, 1]; title = title_S(S), aspect = DataAspect(),
                  xticks = (1:NST, [LABEL[s] for s in STRATS]), yticks = (1:NP, [LABEL[s] for s in PURS]),
                  xticklabelrotation = π / 4, xticklabelsvisible = last,
                  xticksvisible = false, yticksvisible = false,
                  xlabel = last ? "Evader" : "", ylabel = "Pursuer",
                  yreversed = false,   # type-based in the bottom-left corner of both axes
                  ygridvisible = false)   # left/bottom spines only
        hm = heatmap!(ax, 1:NST, 1:NP, M; colormap = cgrad(reverse(BLUES)), colorrange = (lo, hi))
        # no numbers in the cells (author's choice)
    end
    Colorbar(fig[1:2, 2], hm; label = "Mean separation [km]", width = 6, ticksize = 2,
             ticklabelsize = 6.5, labelsize = 7, tellheight = false, height = Relative(0.75),
             spinewidth = 0)   # no border; per-side spine flags are ignored in Makie 0.22
    colgap!(fig.layout, 1, 5)
    rowgap!(fig.layout, 4)
    savefig(fig, "fig_heatmap_stacked")
end

# ---------------------------------------------------------------- F0 summary
"""
F0 — the results' opening figure: each strategy's ADVANTAGE over minimax play, as evader
and as pursuer, with paired 95% CIs (common random numbers: trial g has the same initial
conditions in every cell). Advantage is signed so right = better in both panels:
evader  +(sep(X, P) - sep(minimax, P)),  pursuer  -(sep(E, X) - sep(E, minimax)).
Whole-game mean separation (the metric the text quotes). Two dots per strategy: filled =
pooled over all six opponents (600 pairs), hollow = against the type-based opponent (100);
the two sit on the strategy's row, joined by a connector (dumbbell).
"""
function fig_summary()
    M = "Meta_greedy"
    ROWS = ["Meta_greedy", "FP_greedy", "FP_mixed", "greedy", "random"]   # minimax is the 0 line
    sep(e, p) = T[(e, p)].win[30]
    ci(d) = (mean(d), 1.96std(d) / sqrt(length(d)))
    adv(role, x, opps) = role == 1 ?
        vcat((sep(x, o) .- sep("mixed", o) for o in opps)...) :
        vcat((-(sep(o, x) .- sep(o, "mixed")) for o in opps)...)
    C_ALL, C_TB = "#2c4f85", "#c94f1e"
    println("\nF0 — advantage over minimax [km], paired 95% CI (right = better)")
    fig = Figure(size = (215, 235), fonts = LATEX_FONTS)
    ny = length(ROWS)
    for (k, role) in enumerate(("Evader", "Pursuer"))
        ax = Axis(fig[k, 1]; title = "($(('a','b')[k])) As $(lowercase(role))",   # stacked: evader on top
                  yticks = (1:ny, [LABEL[r] for r in ROWS]), yreversed = true,
                  yticksvisible = false, ygridvisible = false,
                  xgridvisible = true, xgridcolor = (:black, 0.07), xticksvisible = false,
                  yticklabelsize = 7, xticklabelsize = 7, titlesize = 8)   # labels below title size
        vlines!(ax, 0; color = MUTED, linewidth = 0.6)
        # minimax is the reference: its advantage over itself is 0 in every matchup
        text!(ax, 0, 0.45; text = "Minimax", align = (:right, :bottom), offset = (-2, 0), fontsize = 6.5, color = MUTED)
        for (i, x) in enumerate(ROWS)
            # dumbbell: both dots on the strategy's row, joined by a thin connector drawn first
            ests = [ci(adv(k, x, opps)) for opps in (STRATS, [M])]
            lines!(ax, [ests[1][1], ests[2][1]], [i, i]; color = (MUTED, 0.6), linewidth = 0.8)
            for (j, (col, filled)) in enumerate(((C_ALL, true), (C_TB, false)))
                m, h = ests[j]
                @printf("  %-7s %-11s %-12s %+6.3f ± %.3f\n", role, x, filled ? "all opps" : "vs type-based", m, h)
                rangebars!(ax, [i], [m - h], [m + h]; direction = :x, color = col, linewidth = 1.0, whiskerwidth = 0)
                scatter!(ax, [m], [i]; marker = :circle, markersize = 4.5, color = filled ? col : :white,
                         strokecolor = col, strokewidth = 0.9)
            end
        end
        ylims!(ax, ny + 0.6, 0.05)
        # Each panel keeps its own km scale, but x = 0 sits at the SAME fraction of the width in
        # both (pursuer: 3.6 / 5.35), so the two minimax lines line up vertically.
        xlims!(ax, k == 1 ? (-2.45, -2.45 + 2.45 * 5.35 / 3.6) : (-3.6, 1.75))
    end
    Legend(fig[0, 1],
           [MarkerElement(marker = :circle, color = C_ALL, strokecolor = C_ALL, markersize = 5),
            MarkerElement(marker = :circle, color = :white, strokecolor = C_TB, strokewidth = 0.9, markersize = 5)],
           ["All opponents", "vs. type-based opponent"]; orientation = :horizontal, tellheight = true)
    Label(fig[3, 1], "Advantage over minimax [km]  (right = better)"; fontsize = 7, tellwidth = false)
    rowgap!(fig.layout, 3)
    savefig(fig, "fig_summary")
end

# ---------------------------------------------------------------- F3 boxplot
"Per-game mean separation over steps a..b, one value per trial."
win_games(p1, p2, a, b) = [mean(r) for r in eachrow(T[(p1, p2)].step_sep[:, a:b])]

function fig_boxplot()
    # Per-game separation by strategy, pooled over all opponents, for the two post-approach
    # 5-step windows of the heatmap (6-10, 26-30), dodged side by side, on a LOG y-axis
    # (the type-based pursuer's lock-on games sit near 0.1-0.3 km, the rest at 2-10 km).
    # Steps 1-5 are left out: the approach from ≈36 km would stretch the axis to 30 km.
    WINB = WIN5[2:end]
    WCOL = ["#f39b72", "#c94f1e"]
    println("\nF3 — per-game mean separation by strategy and 5-step window (pooled over the $NST opponents)")
    fig = Figure(size = (COL1, 250), fonts = LATEX_FONTS)
    for (row, role) in enumerate(("Evader", "Pursuer"))
        ax = Axis(fig[row, 1]; ylabel = "Separation [km]", title = "($(('a','b')[row])) $role strategy",
                  xticks = (1:NST, [LABEL[s] for s in STRATS]), xticklabelrotation = π / 6,
                  yscale = log10, yticks = [0.1, 0.3, 1, 3, 10], yminorticksvisible = false)
        for (w, (a, b)) in enumerate(WINB)
            xs, ys = Float64[], Float64[]
            for (i, s) in enumerate(STRATS)
                v = role == "Evader" ? vcat((win_games(s, o, a, b) for o in STRATS)...) :
                                       vcat((win_games(o, s, a, b) for o in STRATS)...)
                append!(xs, fill(i, length(v))); append!(ys, v)
                @printf("  %-7s %-11s s=%2d-%-2d  median %5.2f  mean %5.2f  (n=%d)\n",
                        role, s, a, b, median(v), mean(v), length(v))
            end
            @printf("    min over games %.2e km; %d of %d games below the 0.05 km axis floor\n",
                    minimum(ys), count(<(0.05), ys), length(ys))
            boxplot!(ax, xs, ys; dodge = fill(w, length(xs)), n_dodge = length(WINB), color = WCOL[w],
                     width = 0.75, gap = 0.25, dodge_gap = 0.05, markersize = 1.5,
                     whiskerwidth = 0.4, whiskerlinewidth = 0.6, strokewidth = 0.4, strokecolor = INK,
                     mediancolor = :white, medianlinewidth = 0.8, outliercolor = (MUTED, 0.5))
        end
        ylims!(ax, 0.05, 15)   # a few lock-on games average < 0.01 km; they sit below the floor
        row == 1 && hidexdecorations!(ax; grid = false, ticks = false)
    end
    Legend(fig[0, 1], [PolyElement(color = c) for c in WCOL],
           [rich(rich("s", font = :italic), " = $(a)–$(b)") for (a, b) in WINB];
           orientation = :horizontal, tellheight = true)
    rowgap!(fig.layout, 4)
    savefig(fig, "fig_boxplot")
end

# ---------------------------------------------------------------- F4 ΔV vs separation
function fig_dv()
    println("\nF4 — executed ΔV per player [m/s] vs mean separation [km], one point per matchup")
    fig = Figure(size = (COL1, 190))
    ax = Axis(fig[1, 1]; xlabel = "Total executed ΔV over 30 steps [m/s]", ylabel = "Mean separation [km]")
    isfp(s) = startswith(s, "FP") || startswith(s, "Meta")      # the learners
    groups = [("Evader, learner", C_E, :circle, true), ("Evader, non-learner", C_E, :circle, false),
              ("Pursuer, learner", C_P, :utriangle, true), ("Pursuer, non-learner", C_P, :utriangle, false)]
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
fig_summary()
fig_heatmap()
fig_heatmap_alltime()
fig_heatmap_at()
fig_heatmap_stacked()
fig_boxplot()
fig_dv()
fig_price_of_safety()
fig_learning()
fig_game_step()
println("\nfont: ", FONT)
