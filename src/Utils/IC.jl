using LinearAlgebra

## ====================================================================

"""
    init_game(rng, p1_strategy, p2_strategy; disperse=false, ...)

Build the initial game state.

**`disperse` is defect D2's fix.** With `disperse = false` (the default) both orbits are the
hardcoded nominal, so *only the vertex-sampling RNG* varies between trials — which made every
deterministic matchup (greedy/greedy, greedy/FP_greedy, FP_greedy/FP_greedy) bit-identical
across all 50 "trials". Those table cells were N = 1 while `results.md` claimed "independent
initial conditions."

With `disperse = true` the initial conditions are drawn from `rng`:

  * pursuer semi-major-axis ratio `a_P/a_E`, uniform over `a_ratio_range` (nominal 1.005)
  * true-anomaly offset on each craft, normal with sd `σ_ν` — this is phase along the orbit,
    the dispersion the geometry is most sensitive to
  * RAAN offset on each craft, normal with sd `σ_Ω`

Deliberately *not* `rand_IC` (`Utils.jl:164`), even though it exists: it drops the `a_P = 1.005a`
drift and hands the pursuer the evader's velocity, which is a different scenario, not a
dispersion of this one.

The realized elements are stored in `params.ic` so any analysis can recover exactly which
initial condition produced a given game.
"""
function init_game(
    rng,
    p1_strategy="mixed",
    p2_strategy="mixed"
    ;
    disperse::Bool  = false,
    # Scales chosen in PHYSICAL units, then converted. On a ~6998 km orbit at i = 20 deg:
    #     1 deg of true anomaly ~= a*pi/180            ~= 122 km along-track
    #     1 deg of RAAN         ~= a*sin(i)*pi/180     ~=  42 km cross-track
    # so the obvious-looking "2 deg of phase jitter" is a ~244 km displacement — seven
    # times the nominal 34.7 km initial separation, i.e. a different scenario rather
    # than a dispersion of this one. These defaults give ~5 km perturbations, which is
    # the right scale against a 6.378 km hexagon and ~4 km late-game separations.
    a_ratio_range   = (1.0045, 1.0055),   # nominal 1.005; +/-10% on the 35 km drift offset
    σ_ν             = 0.04 * pi / 180,    # ~5 km along-track, both craft
    σ_Ω             = 0.12 * pi / 180,    # ~5 km cross-track, both craft
    # C4 vertex ablation: the size of the lifted action set. 6 is the historical hexagon
    # and is bitwise-preserved (see polygon_vertices); 12 and 24 refine it. Cost scales
    # roughly linearly -- each vertex is one more trajectory optimization per player per
    # step -- and the LP becomes n x n.
    n_vertices::Int = 6,
    # C1 recency-weighted FP: f_s = γ·f_{s-1} + g_{s-1}. γ = 1 is plain fictitious play and
    # is the default, so this changes no existing number. Effective memory 1/(1-γ) steps.
    # See `update_beliefs!` for why uniform pooling is questionable here (C3's variation
    # budget) and for what discounting should and should not be expected to fix.
    γ_fp::Float64 = 1.0,
    # Per-player discount. Defaults to γ_fp, so passing a single γ still discounts both
    # players exactly as before. Set this separately to run the asymmetric experiment C1
    # actually needs in a self-play cell: with both players discounting, FP vs FP is a
    # symmetric perturbation and cannot say whether forgetting helps the evader.
    γ_fp_p2::Float64 = γ_fp,
    # C2 Hedge learning rate. The textbook choice for a known horizon T over n actions is
    # sqrt(8 ln n / T); at T = 30, n = 6 that is ~0.62. Left at 0.1 by default because the
    # payoffs here are separations in km (O(4), not O(1)), so the effective rate is η times
    # the payoff scale. Sweep it rather than trusting the default. `regret_matching` takes
    # no parameter at all, which is why it is the primary no-regret baseline.
    η_hedge::Float64 = 0.1,
)

    # orbit params
    mu = 398600.4415   # gravitational parameter
    r = 6378.0        # Earth radius [km]

    # radius of polygon circle!!!!
    R_polygon = 6378.0 / 1000

    # --- initial conditions -------------------------------------------------
    # Nominal: both craft on the same orbit but for the pursuer's semi-major axis.
    a = r + 620.0
    a_ratio = 1.005
    dν_E = dν_P = dΩ_E = dΩ_P = 0.0

    if disperse
        lo, hi  = a_ratio_range
        a_ratio = lo + (hi - lo) * rand(rng)
        dν_E, dν_P = σ_ν * randn(rng), σ_ν * randn(rng)
        dΩ_E, dΩ_P = σ_Ω * randn(rng), σ_Ω * randn(rng)
    end

    kep0_E = [a, 0.01, 20 * pi / 180, 10.0 * pi / 180 + dΩ_E, 20.0 * pi / 180, 25.0 * pi / 180 + dν_E]
    rv_0_E = kep2cart(kep0_E, mu)

    kep0_P = [a * a_ratio, 0.01, 20 * pi / 180, 10.0 * pi / 180 + dΩ_P, 20.0 * pi / 180, 25.0 * pi / 180 + dν_P]
    rv_0_P = kep2cart(kep0_P, mu)

    # keep the realized draw so a game can be traced back to its initial condition
    ic = (; disperse, a, a_ratio, dν_E, dν_P, dΩ_E, dΩ_P,
            kep0_E = copy(kep0_E), kep0_P = copy(kep0_P))

    # get period of orbit 
    T = 2 * pi * sqrt(a^3 / mu)

    # --- orbit discretization ---
    n_seg_orbit         = 50    # total segments per orbit
    n_seg_horizon       = 10    # segments per optimization window
    n_seg_per_game_step = 5     # segments executed per game step

    # --- derived time quantities ---
    dt_seg        = T / n_seg_orbit
    t_horizon     = n_seg_horizon * dt_seg
    tt_game_step  = n_seg_per_game_step * dt_seg

    # start time 
    tt = 0

    # propagate ref orbits 
    t_E, rv_E_hist = propagate_2Body(rv_0_E, t_horizon, mu, 1.0)
    t_P, rv_P_hist = propagate_2Body(rv_0_P, t_horizon, mu, 1.0)
    rv_E_hist = vv2m(rv_E_hist)
    rv_P_hist = vv2m(rv_P_hist)

    # save reference orbit 
    kep0_ref_E = copy(kep0_E)

    # --- trajectory optimization ---
    # Defaults chosen to reproduce the historical behavior exactly, so that adding
    # these knobs changes no number until someone deliberately sets one.
    #   Δv_max: measured max per-segment ‖Δv‖ is ~0.022 km/s, so 2.0 is inactive by
    #           a factor of ~90.  Even the paper's stated 0.1 km/s would not bind;
    #           binding requires ~0.02.  See defect D6.
    #   w_miss: weight on terminal miss relative to fuel.  See defect D11 and the
    #           docstring of min_Δv_dist.
    Δv_max = 2.0
    w_miss = 1.0

    # --- stage cost weights (see stage_cost in matrix_game_solver.jl) ---
    # λ2 = 0: the GAME payoff is separation only.  Measured Sep 1 (note [j]): at
    # λ2 = 0.1 the differential-fuel term was ~8,000x smaller than the separation
    # term and contributed 0.0% of the 6x6 matrix's variation, so it changed no
    # decision while implying in the write-up that fuel was traded off.  Fuel is
    # still minimized where it is real -- inside the TRAJECTORY objective, which
    # D11 fixed -- and ΔV is reported as its own metric.
    λ1 = 1.0    # separation term
    λ2 = 0.0    # differential-fuel term; see above

    # --- capture condition (B3, decided 2026-09-16 from the measured capture curve) ---
    # Two-level, post-hoc: capture = first passage of the inter-player separation below r.
    # Games are NEVER terminated — termination would censor the separation metrics and
    # break the comparability common random numbers buy. See capture_stats in Utils.jl.
    #   hard: 0.2 km = the ISS keep-out-sphere radius (citable proximity-ops grounding),
    #         and the smallest radius still resolvable at 100 games/cell.
    #   soft: 1.0 km = proximity-operations scale; the most discriminating radius on the
    #         measured curve (per-cell rates span 13–100%; 1.5 km saturates).
    # Hard sits well below the sensitive 0.5–1.0 km knee, soft at its top edge — the full
    # curve is reported alongside both (capture_curve) so neither reads as cherry-picked.
    r_capture_hard = 0.2
    r_capture_soft = 1.0

    # game parameters
    params = (
        mu=mu,
        r=r,
        n_seg_horizon=n_seg_horizon,
        t_horizon=t_horizon,
        n_seg_per_game_step=n_seg_per_game_step,
        tt_game_step=tt_game_step,
        kep0_ref_E=kep0_ref_E,
        T=T,
        strategy=p1_strategy,
        p2_strategy=p2_strategy,
        R_polygon=R_polygon,
        Δv_max=Δv_max,
        w_miss=w_miss,
        λ1=λ1,
        λ2=λ2,
        r_capture_hard=r_capture_hard,
        r_capture_soft=r_capture_soft,
        n_vertices=n_vertices,
        γ_fp=γ_fp,
        γ_fp_p2=γ_fp_p2,
        η_hedge=η_hedge,
        ic=ic
    )

    # save rv_ref from E to position for vertices of polygon 
    # rv_ref_E = rv_E_hist
    t_ref_E, rv_ref_E = prop_kepler_tof_Nseg(rv_0_E, zeros(params.n_seg_horizon, 3), params.n_seg_horizon, params.t_horizon / params.n_seg_horizon, params.mu)

    # save player state and control hists 
    tracked_strategies = ["mixed", "greedy", "random", (1:n_vertices)...]
    strategy_belief = ones(length(tracked_strategies)) / length(tracked_strategies)
    # C4: arity is now derived from `n_vertices` everywhere. The four sites that used to
    # hardcode 6 were this one, `tracked_strategies` above, `polygon_vertices`, and the
    # cost-matrix allocation in `compute_cost_matrices` (which already derived it).
    p = player_struct(; fp_belief=ones(n_vertices), strategy_belief, tracked_strategies)
    players = [p, deepcopy(p)]

    players[1].rv_0_hist = rv_E_hist
    players[2].rv_0_hist = rv_P_hist

    # init game 
    game = game_struct([], [], [], [], [], [], [], [], [])

    push!(game.tt, tt)
    push!(game.i_game_step, 1)
    push!(game.rv_E, rv_0_E)
    push!(game.rv_P, rv_0_P)
    push!(game.t_ref_E, t_ref_E)
    push!(game.rv_ref_E, rv_ref_E)
    push!(game.params, params)

    # compute all possible Δv solutions 
    players = compute_states_nash(params, game, players, rng)

    # save player state in game 
    push!(game.p1_state, players[1])
    push!(game.p2_state, players[2])

    return params, players, game
end

export init_game


## ====================================================================

"Create dummy IC for lambert transfer and then breaking up into smaller Δv. for testing purposes only!!!"
function lambert_IC()

    # define IC, target state, and lambert solve 
    R = 6378.0                # Earth radius [km] 
    r_0 = [20.0e6, 20.0e6, 0]  # [km] 
    r_f = [-20.0e6, 10.0e6, 0]  # [km] 
    # r_0 = [ R + 500, R + 500, 0 ]
    # r_f = [ R - 500, R - 500, 0 ] 
    tof = 1.0 * 86400
    mu = 398600.4418e9         # [km^3/s^2] 
    dm = "pro"

    # solve lambert orbit 
    v_0, v_f = lambertbattin(r_0, r_f, mu, dm, tof)

    # # # let's non-dimensionalize everything 
    # r_0, v_0 = nondim_rv( r_0, v_0, mu, R )
    # r_f, v_f = nondim_rv( r_f, v_f, mu, R )  
    # mu = 1.0 

    rv_0 = [r_0; v_0]

    # propagate lambert orbit 
    t_lambert, rv_lambert = propagate_2Body(rv_0, tof, mu, 1.0)
    rv_lambert = mapreduce(permutedims, vcat, rv_lambert)

    # N segments 
    N = 20
    # Δv_vec = zeros(N, 3) 
    # Δv_vec[1,:] = v_0 

    # initial position has all z velocity 
    v_z = [0; 0; norm(v_0)]

    # compute delta v vec for lambert solution 
    dv = v_0 - v_z
    dv = v_0

    # break up delta v into smaller segments 
    Δv_vec = []
    for i = 1:N
        push!(Δv_vec, dv / N)
    end
    Δv_vec = mapreduce(permutedims, vcat, Δv_vec)

    return r_0,            # initial position 
    r_f,            # final position 
    v_0,            # initial velocity 
    v_f,            # final velocity 
    rv_lambert,     # lambert orbit 
    Δv_vec,         # delta v vector 
    tof,            # time of flight 
    N,              # number of segments 
    mu              # gravitational parameter  
end

export lambert_IC
# r_0, r_f, v_0, v_f, rv_lambert, Δv_vec, tof, N, mu = lambert_IC() 

