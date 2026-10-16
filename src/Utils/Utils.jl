include("plotting.jl")
include("IC.jl")
include("structs.jl")

## ====================================================================

"Convert vector of vectors into matrix"
function vv2m(vec_vec)

    out = mapreduce(permutedims, vcat, vec_vec)

    return out
end

export vv2m

## ====================================================================

"Return index that matches val"
function get_index(
    A,      # array (or vector)  
    val,    # value to find 
)

    ind = findall(x -> x == val, A)[1]

    return ind
end

export get_index

## ====================================================================

"Convert matrix into vector of vectors"
function m2vv(M)

    N = size(M, 1)
    vec_vec = []
    for i = 1:N
        push!(vec_vec, M[i, :])
    end

    return vec_vec
end

export m2vv

## ====================================================================

"Compute Δv from desired inclination change"
function computeInclinationChange(
    rv,     # initial state vector 
    Δi,     # desired inclination change 
    mu,     # gravitational parameter 
)

    v = rv[4:6]
    kep2 = cart2kep(rv, mu)

    kep2[3] += Δi
    v_des = kep2cart(kep2, mu)[4:6]

    # compute Δv from geometry 
    Δi_mag = sqrt(norm(v)^2 + norm(v_des)^2 - 2 * norm(v) * norm(v_des) * cos(Δi))
    Δv = Δi_mag * (v_des - v)

    return Δv
end

export computeInclinationChange

## ====================================================================

""" 
Get orthogonal axes of local frame at given state vector: 
    axis_1: along velocity vector 
    axis_2: along radius vector 
    axis_3: normal to orbit plane 
"""
function axis_123(rv_vec)

    # center of polygon 
    r_f = rv_vec[1:3]
    axis_2 = -r_f / norm(r_f)
    v_f = rv_vec[4:6]
    axis_1 = v_f / norm(v_f)

    # define vector normal to orbit plane 
    axis_3 = cross(axis_1, axis_2)
    axis_3 = axis_3 / norm(axis_3)

    return axis_1, axis_2, axis_3
end

export axis_123

## ====================================================================

"""
    polygon_vertices(rv_state, parameters)

Vertices of the regular polygon inscribed around `rv_state`, as a `Vector` of position
vectors, ordered counter-clockwise starting from the `+ê₃` ("top") direction. Vertex `k`
sits at angle `360°·(k-1)/n` in the local **ê₂–ê₃ (radial/normal) plane** — *not* the plane
normal to velocity; `axis_123` is not orthonormal (`a₁·a₂ ≈ -e`), and the two planes differ
by ~0.57° at e = 0.01.

Arity comes from `parameters.n_vertices`, defaulting to **6** — this is C4's ablation knob.
At n = 6 the order is the historical `(top, topin, botin, bot, botout, topout)`.

**Why n = 6 is a separate branch.** The general formula and the original hardcoded
expressions differ in the last bits: `cosd(120)` is not bitwise `-cosd(60)`, which moves
vertex positions by ~2e-12 km. That is physically nothing, but every Gate A/B number was
produced by the expressions below, and exact reproducibility is used as a verification tool
in this project (it is what proved the B6 re-run of Gate B's cells was schema-only). So
n = 6 keeps the original arithmetic verbatim and only other arities take the general path.
Verified bitwise-identical to the pre-C4 implementation over 20,000 random states.
"""
function polygon_vertices(
    rv_state,                 # [N,6] state vector
    parameters,    # radius of polygon
)

    dist = parameters.R_polygon
    n    = hasproperty(parameters, :n_vertices) ? parameters.n_vertices : 6

    # center of polygon
    r_vec = rv_state[1:3]
    _, axis_2, axis_3 = axis_123(rv_state)

    if n != 6
        return [r_vec + cosd(360 * (k - 1) / n) * axis_3 * dist +
                        sind(360 * (k - 1) / n) * axis_2 * dist for k in 1:n]
    end

    # --- n = 6: the original expressions, preserved verbatim (see docstring) ---

    # top vertex: move up from r_f along axis 3
    r_top = r_vec + axis_3 * dist

    # top-inner vertex: move up from r_f along axis 3 and left along axis 2, 60 degrees
    vec = cosd(60) * axis_3 * dist + sind(60) * axis_2 * dist
    r_topin = r_vec + vec

    # bottom-inner vertex: move down from r_f along axis 3 and left along axis 2, 60 degrees
    vec = -cosd(60) * axis_3 * dist + sind(60) * axis_2 * dist
    r_botin = r_vec + vec

    # bottom vertex: move down from r_f along axis 3
    r_bot = r_vec - axis_3 * dist

    # bottom-outer vertex: move down from r_f along axis 3 and right along axis 2, 60 degrees
    vec = -cosd(60) * axis_3 * dist - sind(60) * axis_2 * dist
    r_botout = r_vec + vec

    # top-outer vertex: move up from r_f along axis 3 and right along axis 2, 60 degrees
    vec = cosd(60) * axis_3 * dist - sind(60) * axis_2 * dist
    r_topout = r_vec + vec

    return [r_top, r_topin, r_botin, r_bot, r_botout, r_topout]
end

export polygon_vertices

## ====================================================================

"Generate uniformly distributed random point(s) within a circle of radius R"

function unif_random_points_circle(
    R,      # parameters struct 
    rng,    # random number generator 
    N=1,  # number of points 
)

    θ = 2 * pi * rand(rng, N)
    r = R * sqrt.(rand(rng, N))

    x = r .* cos.(θ)
    y = r .* sin.(θ)

    return x, y
end

export unif_random_points_circle

## ====================================================================

"Generate uniformly distributed random point(s) within a circle of radius R around given state vector"

function rand_IC(
    rv_reference,   # [N,6] state vector 
    R_polygon,      # parameters struct 
    rng,            # random number generator 
    N=1,          # number of points 
)

    # reference vector and frame  
    r_reference = rv_reference[1:3]
    _, axis_2, axis_3 = axis_123(rv_reference)

    # generate random points 
    x_random, y_random = unif_random_points_circle(R_polygon, rng, N)

    random_vector = x_random[1] .* axis_2 + y_random[1] .* axis_3
    r_IC = r_reference + random_vector

    return r_IC
end

export rand_IC

## ====================================================================

"Compute norm of U vectors for both players"
function p1_p2_u_hist(game, params=game.params[1])

    n_seg_per_game_step = params.n_seg_per_game_step
    k_max = game.i_game_step[end]

    p1_U_hist = []
    p2_U_hist = []
    for kk = 1:k_max

        # propagate SC state forward 
        p1 = game.p1_state[kk]
        p2 = game.p2_state[kk]
        p1_chosen = p1.chosen
        p2_chosen = p2.chosen

        p1_U = game.p1_state[kk].U[p1_chosen][1:n_seg_per_game_step, :]
        p2_U = game.p2_state[kk].U[p2_chosen][1:n_seg_per_game_step, :]

        push!(p1_U_hist, p1_U)
        push!(p2_U_hist, p2_U)
    end

    p1_U_hist = mapreduce(permutedims, hcat, p1_U_hist)'
    p2_U_hist = mapreduce(permutedims, hcat, p2_U_hist)'

    return p1_U_hist, p2_U_hist
end

export p1_p2_u_hist


## ====================================================================

"Compute norm of U vectors for both players"
function U_norm(game, params=game.params[1])

    n_seg_per_game_step = params.n_seg_per_game_step
    k_max = game.i_game_step[end]

    p1_U_hist = []
    p2_U_hist = []
    for kk = 1:k_max

        # propagate SC state forward 
        p1 = game.p1_state[kk]
        p2 = game.p2_state[kk]
        p1_chosen = p1.chosen
        p2_chosen = p2.chosen

        p1_U = game.p1_state[kk].U[p1_chosen][1:n_seg_per_game_step, :]
        p2_U = game.p2_state[kk].U[p2_chosen][1:n_seg_per_game_step, :]

        push!(p1_U_hist, p1_U)
        push!(p2_U_hist, p2_U)
    end

    p1_U_hist = mapreduce(permutedims, hcat, p1_U_hist)'
    p2_U_hist = mapreduce(permutedims, hcat, p2_U_hist)'

    p1_U_norm = [norm(p1_U_hist[ii, :]) for ii in 1:size(p1_U_hist, 1)]
    p2_U_norm = [norm(p2_U_hist[ii, :]) for ii in 1:size(p2_U_hist, 1)]

    return p1_U_norm, p2_U_norm
end

export U_norm


## ====================================================================

# tt_hist, p1_rv_hist, p2_rv_hist, rv_ref_hist = p_rv_ref_hist( game, params ) 
function p_rv_ref_hist(game, params=game.params[1])

    n_seg_per_game_step = params.n_seg_per_game_step
    k_max = game.i_game_step[end]

    tt_hist = []
    p1_rv_hist = []
    p2_rv_hist = []
    rv_ref_hist = []
    for kk = 1:k_max

        # propagate SC state forward 
        p1 = game.p1_state[kk]
        p2 = game.p2_state[kk]
        p1_chosen = p1.chosen
        p2_chosen = p2.chosen

        # get traveled trajectory 
        tt = game.t_ref_E[kk][1:n_seg_per_game_step]
        p1_r = game.p1_state[kk].X[p1_chosen][1:n_seg_per_game_step, :]
        p2_r = game.p2_state[kk].X[p2_chosen][1:n_seg_per_game_step, :]
        rv_ref = game.rv_ref_E[kk][1:n_seg_per_game_step, :]
        if kk == k_max
            tt = game.t_ref_E[kk][1:n_seg_per_game_step+1]
            p1_r = game.p1_state[kk].X[p1_chosen][1:n_seg_per_game_step+1, :]
            p2_r = game.p2_state[kk].X[p2_chosen][1:n_seg_per_game_step+1, :]
            rv_ref = game.rv_ref_E[kk][1:n_seg_per_game_step+1, :]
        end

        push!(tt_hist, tt)
        push!(p1_rv_hist, p1_r)
        push!(p2_rv_hist, p2_r)
        push!(rv_ref_hist, rv_ref)

    end

    tt_hist = float.(mapreduce(permutedims, hcat, tt_hist)')[:]
    p1_rv_hist = float.(mapreduce(permutedims, hcat, p1_rv_hist)')
    p2_rv_hist = float.(mapreduce(permutedims, hcat, p2_rv_hist)')
    rv_ref_hist = float.(mapreduce(permutedims, hcat, rv_ref_hist)')

    return tt_hist, p1_rv_hist, p2_rv_hist, rv_ref_hist
end

export p_rv_ref_hist


## ==================================================================== 

function dist_ref_norm(game, params)

    _, p1_rv_hist, p2_rv_hist, rv_ref_hist = p_rv_ref_hist(game, params)

    p1_r_diff = p1_rv_hist[:, 1:3] - rv_ref_hist[:, 1:3]
    p2_r_diff = p2_rv_hist[:, 1:3] - rv_ref_hist[:, 1:3]

    p1_ref_norm = [norm(p1_r_diff[ii, :]) for ii in 1:size(p1_r_diff, 1)]
    p2_ref_norm = [norm(p2_r_diff[ii, :]) for ii in 1:size(p2_r_diff, 1)]

    return p1_ref_norm, p2_ref_norm
end

export dist_ref_norm


## ==================================================================== 

function dist_norm(game, params)

    _, p1_rv_hist, p2_rv_hist, _ = p_rv_ref_hist(game, params)

    r_diff = p1_rv_hist[:, 1:3] - p2_rv_hist[:, 1:3]
    r_norm = [norm(r_diff[ii, :]) for ii in 1:size(r_diff, 1)]

    return r_norm
end

export dist_norm


## ====================================================================

using JLD2

"""
    slim_player(p) / slim_game(g) / slim(games_vec)

Strip the per-vertex candidate sets from a finished game (B2).

`X`, `U`, `t` hold all six candidate trajectories per player per step — the bulk of a saved
file — but the analysis only ever reads the *executed* trajectory, which is already in
`rv_chosen` / `U_chosen` / `t_chosen`. `rv_0_hist` goes too, for the same reason.

Everything the analysis does read is kept: `cost` (A_k), both weight vectors, `chosen`, the
belief fields, `solve_info` (which now carries the terminal-miss and convergence diagnostics
that used to require `X`), and `params` (including the realized `ic`).

**Caveat:** `test/analyze_late_game.jl` still indexes `p.X[p.chosen]` and `p.U[p.chosen]`, so it
must be switched to `rv_chosen`/`U_chosen` before it can read slim files.
"""
slim_player(p) = player_struct(;
    cost               = p.cost,
    weights            = p.weights,
    chosen             = p.chosen,
    t_chosen           = p.t_chosen,
    rv_chosen          = p.rv_chosen,
    U_chosen           = p.U_chosen,
    fp_belief          = p.fp_belief,
    strategy_belief    = p.strategy_belief,
    tracked_strategies = p.tracked_strategies,
    solve_info         = p.solve_info,
    learner_state      = p.learner_state,
)

slim_game(g) = game_struct(g.tt, g.i_game_step, g.rv_E, g.rv_P, g.t_ref_E, g.rv_ref_E,
                           slim_player.(g.p1_state), slim_player.(g.p2_state), g.params)

slim(games_vec) = slim_game.(games_vec)

export slim_player, slim_game, slim

## ====================================================================

"""
    separation_series(game)

Inter-player separation at every executed segment boundary, with absolute times and the game
step each sample belongs to. Sample `i` of step `k` sits at `tt[k] + (i-1)·dt_seg`, with
`dt_seg = t_horizon / n_seg_horizon` (≈117 s at the nominal orbit) — that spacing is the
*resolution* of any closest-approach number, so a true minimum between boundaries can be
missed by up to half a sample.

Slim-compatible by construction: reads only `rv_chosen`, never `X[chosen]` (which
`slim_player` strips — the old `dist_norm` path cannot run on slim files).
"""
function separation_series(game, params=game.params[1])
    dt_seg = params.t_horizon / params.n_seg_horizon
    t, d, kstep = Float64[], Float64[], Int[]
    for k in eachindex(game.p1_state)
        r1, r2 = game.p1_state[k].rv_chosen, game.p2_state[k].rv_chosen
        (isempty(r1) || isempty(r2)) && continue
        for i in axes(r1, 1)
            push!(t, game.tt[k] + (i - 1) * dt_seg)
            push!(d, norm(r1[i, 1:3] - r2[i, 1:3]))
            push!(kstep, k)
        end
    end
    (; t, d, k = kstep)
end

"""
    min_separation(game)

Closest approach between the two craft over a whole game, in km, using every executed segment
boundary rather than only the game-step endpoints. Same value as the old `dist_norm`-based
minimum (consecutive steps share their boundary sample), but works on slim files.
"""
min_separation(game, params=game.params[1]) = minimum(separation_series(game, params).d)

"""
    capture_stats(game; r_hard, r_soft)

**The capture condition (B3), decided 2026-09-16 from the measured capture curve:**

  * `r_capture_hard = 0.2 km` — the ISS keep-out-sphere radius, the citable proximity-ops
    "last safety barrier". The smallest radius still statistically resolvable at 100
    games/cell (80 events across the CRN sweep; pooled per-evader Wilson CIs separate).
  * `r_capture_soft = 1.0 km` — proximity-operations scale, and the most discriminating
    radius on the measured curve (per-cell rates span 13–100%; 1.5 km saturates).

Capture is **post-hoc first passage below the radius — games are never terminated.**
Terminating would censor the separation metrics and break the comparability that common
random numbers buy, so capture is an event flag on a completed game, and time-to-capture
comes from the same first passage. Defaults read `params.r_capture_hard` / `r_capture_soft`
when present (with the values above as fallback, so pre-B3 saved games still analyze).

Returns `(; min_sep, r_hard, r_soft, hard, soft, t_hard, t_soft, k_hard, k_soft)` — the
booleans, first-passage absolute times (`NaN` if never) and game steps (`0` if never).
"""
function capture_stats(game, params=game.params[1];
                       r_hard = get(params, :r_capture_hard, 0.2),
                       r_soft = get(params, :r_capture_soft, 1.0))
    s = separation_series(game, params)
    function first_pass(r)
        i = findfirst(<=(r), s.d)
        isnothing(i) ? (false, NaN, 0) : (true, s.t[i], s.k[i])
    end
    hard, t_hard, k_hard = first_pass(r_hard)
    soft, t_soft, k_soft = first_pass(r_soft)
    (; min_sep = minimum(s.d), r_hard, r_soft, hard, soft, t_hard, t_soft, k_hard, k_soft)
end

"""
    capture_curve(games_vec, radii)

Capture rate as a FUNCTION of the capture radius: for each radius, the fraction of games whose
closest approach fell inside it.

The named thresholds live in `capture_stats` (hard 0.2 km / soft 1.0 km, B3); the curve is
still reported alongside them because the 0.5–1.0 km interval is where the rate is steepest —
showing the whole curve is the honest answer to "why these radii" and to the pursuit-evasion
reviewer who will ask what capture means.
"""
function capture_curve(games_vec, radii)
    d = [min_separation(g) for g in games_vec]
    (; radii, rate = [count(<=(r), d) / length(d) for r in radii], min_sep = d)
end

"""
    wilson95(k, n)

Wilson 95% interval `(lo, hi)` for a binomial proportion `k/n` — the interval to use for
capture rates, which sit near 0 (hard) or near 1 (soft) where the normal approximation fails.
"""
function wilson95(k, n)
    z = 1.959963984540054
    p = k / n
    c = (p + z^2 / (2n)) / (1 + z^2 / n)
    h = z * sqrt(p * (1 - p) / n + z^2 / (4n^2)) / (1 + z^2 / n)
    # at k == 0 (k == n) the true bound is exactly 0 (exactly 1); c - h only reaches it
    # up to a last-ulp residue, so pin the degenerate endpoints rather than clamp them
    (k == 0 ? 0.0 : max(c - h, 0.0), k == n ? 1.0 : min(c + h, 1.0))
end

export separation_series, min_separation, capture_stats, capture_curve, wilson95

## ====================================================================

"""
    results_folder(k_max, p1, p2, n_vertices = 6; γ_fp = 1.0, η_hedge = 0.1)

The on-disk layout, in ONE place so the writer and reader cannot drift:

    test/results/n<k_max>[_v<n>][_g<γ>][_e<η>]/p1_<P1>_p2_<P2>/games_<N>.jld2

**Every knob that changes the numbers must appear in the path, or runs silently overwrite
each other.** The optional components appear only at non-default values, so every path
written before Gate C stays valid and all Gate A/B/B6 data still loads unchanged.

This has already prevented two data-loss bugs. Without `_v<n>`, a 12-vertex ablation run
would have overwritten the 6-vertex Gate B cells (the path keys on game *steps*, not vertex
count). Without `_g<γ>`, the three γ values of the C1 sweep would have overwritten each
other **and** the Gate B `FP_greedy` cells. If you add another swept knob, add it here in
the same breath.
"""
function results_folder(k_max, p1, p2, n_vertices = 6;
                        γ_fp = 1.0, γ_fp_p2 = γ_fp, η_hedge = 0.1)
    tag = string("n", k_max)
    n_vertices == 6 || (tag *= string("_v", n_vertices))
    γ_fp == 1.0     || (tag *= string("_g", γ_fp))
    γ_fp_p2 == γ_fp || (tag *= string("_g2", γ_fp_p2))   # asymmetric discount
    η_hedge == 0.1  || (tag *= string("_e", η_hedge))
    string("test/results/", tag, "/p1_", p1, "_p2_", p2, "/")
end

export results_folder

function save_games_vec(games_vec, params=games_vec[1].params[1])

    k_max = games_vec[1].i_game_step[end]
    getp(name, dflt) = hasproperty(params, name) ? getproperty(params, name) : dflt
    γ1 = getp(:γ_fp, 1.0)
    save_folder = results_folder(k_max, params.strategy, params.p2_strategy,
                                 getp(:n_vertices, 6);
                                 γ_fp = γ1, γ_fp_p2 = getp(:γ_fp_p2, γ1),
                                 η_hedge = getp(:η_hedge, 0.1))

    mkpath(save_folder)

    N_games = length(games_vec)

    filename = string("games_", N_games, ".jld2")
    full_filename = string(save_folder, filename)

    @save full_filename games_vec

end

export save_games_vec


## ====================================================================

"""
    load_games_vec(N_games, n_game_steps, p1_strategy, p2_strategy)

Inverse of `save_games_vec`. The layout below must stay in sync with the one
written there: `test/results/n<k_max>/p1_<P1>_p2_<P2>/games_<N>.jld2`.

(Previously this read `test/results/p1_X_p2_Y/...` — missing the `n<k_max>`
level — so it could never load anything `save_games_vec` wrote. It had no call
sites, which is why the breakage went unnoticed.)
"""
function load_games_vec(N_games, n_game_steps, p1_strategy="mixed", p2_strategy="mixed";
                        n_vertices::Int=6, γ_fp::Float64=1.0, γ_fp_p2::Float64=γ_fp,
                        η_hedge::Float64=0.1)

    save_folder = results_folder(n_game_steps, p1_strategy, p2_strategy, n_vertices;
                                 γ_fp, γ_fp_p2, η_hedge)

    filename = string("games_", N_games, ".jld2")
    full_filename = string(save_folder, filename)

    isfile(full_filename) || error("no saved games at $full_filename")

    @load full_filename games_vec

    return games_vec
end

export load_games_vec


## ====================================================================

function MC_stats(games_vec, params=games_vec[1].params[1])

    dist_rnorm_all = []
    p1_Unorm_sum_all = []
    p2_Unorm_sum_all = []
    p1_ref_norm_all = []
    p2_ref_norm_all = []

    for ii in eachindex(games_vec)

        game = games_vec[ii]

        # compute norm of U and distance vectors 
        dist_rnorm = dist_norm(game, params)
        p1_U_norm, p2_U_norm = U_norm(game, params)
        p1_Unorm_sum = cumsum(p1_U_norm)
        p2_Unorm_sum = cumsum(p2_U_norm)

        p1_ref_norm, p2_ref_norm = dist_ref_norm(game, params)

        push!(dist_rnorm_all, dist_rnorm)
        push!(p1_Unorm_sum_all, p1_Unorm_sum)
        push!(p2_Unorm_sum_all, p2_Unorm_sum)
        push!(p1_ref_norm_all, p1_ref_norm)
        push!(p2_ref_norm_all, p2_ref_norm)

    end

    dist_rnorm_all = vv2m(dist_rnorm_all)
    p1_Unorm_sum_all = vv2m(p1_Unorm_sum_all)
    p2_Unorm_sum_all = vv2m(p2_Unorm_sum_all)
    p1_ref_norm_all = vv2m(p1_ref_norm_all)
    p2_ref_norm_all = vv2m(p2_ref_norm_all)

    dist_norm_mean = mean(dist_rnorm_all, dims=1)[:]
    p1_Unorm_sum_mean = mean(p1_Unorm_sum_all, dims=1)[:]
    p2_Unorm_sum_mean = mean(p2_Unorm_sum_all, dims=1)[:]
    p1_ref_norm_mean = mean(p1_ref_norm_all, dims=1)[:]
    p2_ref_norm_mean = mean(p2_ref_norm_all, dims=1)[:]

    dist_norm_std = std(dist_rnorm_all, dims=1)[:]
    p1_Unorm_sum_std = std(p1_Unorm_sum_all, dims=1)[:]
    p2_Unorm_sum_std = std(p2_Unorm_sum_all, dims=1)[:]
    p1_ref_norm_std = std(p1_ref_norm_all, dims=1)[:]
    p2_ref_norm_std = std(p2_ref_norm_all, dims=1)[:]

    stats = (dist_rnorm_all=dist_rnorm_all,
        p1_Unorm_sum_all=p1_Unorm_sum_all,
        p2_Unorm_sum_all=p2_Unorm_sum_all,
        p1_ref_norm_all=p1_ref_norm_all,
        p2_ref_norm_all=p2_ref_norm_all,
        dist_norm_mean=dist_norm_mean,
        p1_Unorm_sum_mean=p1_Unorm_sum_mean,
        p2_Unorm_sum_mean=p2_Unorm_sum_mean,
        p1_ref_norm_mean=p1_ref_norm_mean,
        p2_ref_norm_mean=p2_ref_norm_mean,
        dist_norm_std=dist_norm_std,
        p1_Unorm_sum_std=p1_Unorm_sum_std,
        p2_Unorm_sum_std=p2_Unorm_sum_std,
        p1_ref_norm_std=p1_ref_norm_std,
        p2_ref_norm_std=p2_ref_norm_std)

    return stats
end

export MC_stats


## ====================================================================

function print_MC_stats(
    games_vec,
    params=games_vec[1].params[1],
    print_stats=true
)

    stats = MC_stats(games_vec, params)

    dist_norm_mean_mean = @sprintf "%.3g" mean(stats.dist_norm_mean)
    p1_Unorm_mean_end = @sprintf "%.3g" stats.p1_Unorm_sum_mean[end]
    p2_Unorm_mean_end = @sprintf "%.3g" stats.p2_Unorm_sum_mean[end]
    p1_ref_norm_mean_mean = @sprintf "%.3g" mean(stats.p1_ref_norm_mean)
    p2_ref_norm_mean_mean = @sprintf "%.3g" mean(stats.p2_ref_norm_mean)

    sprintf_stats = (dist_norm_mean_mean=dist_norm_mean_mean,
        p1_Unorm_mean_end=p1_Unorm_mean_end,
        p2_Unorm_mean_end=p2_Unorm_mean_end,
        p1_ref_norm_mean_mean=p1_ref_norm_mean_mean,
        p2_ref_norm_mean_mean=p2_ref_norm_mean_mean)

    if print_stats == true

        println("games = ", length(games_vec))
        println("p1 strategy = ", params.strategy, ", p2 strategy = ", params.p2_strategy)
        println("mean player distance: ", dist_norm_mean_mean)
        println("mean cumsum norm of U vectors: p1 = ", p1_Unorm_mean_end, ", p2 = ", p2_Unorm_mean_end)
        println("mean player distance from reference orbit: p1 = ", p1_ref_norm_mean_mean, ", p2 = ", p2_ref_norm_mean_mean)

    end

    return sprintf_stats
end

export print_MC_stats







