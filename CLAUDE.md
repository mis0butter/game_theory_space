# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Current state

*Rewritten in place each session. Last updated: 2026-09-16.*

- **Phase:** Gate B complete (data + analysis). Narrative locks after B3/B6.
- **Config (Gate B, current):** payoff is **separation-only** (`params.λ2 = 0`); trajectory
  solver is **LBFGS + BackTracking** (default in `min_fns.jl`, swap via `method=` kwarg);
  `disperse=true` (D2 fixed, default); `slim_save=true` (33 MB/file); 100 trials × 30 steps;
  CRN via reseeding `MersenneTwister(1)` *inside* the matchup loop (`test/run_gate_b.jl`).
- **Last run:** CRN sweep 2026-09-02, 106.2 min on 32 threads → `test/results/n30/`
  (25 matchups × 100 games, ~900k solves). Unpaired predecessor retained at
  `test/results/n30_unpaired_2026-09-01/`. Smoke sweep at `test/results/n10/`.
- **Best numbers:** `FP_greedy` is best evader (row mean 6.07±0.15 km) *and* best pursuer
  (col mean 4.82±0.06). `FP_greedy − mixed` **reverses sign** vs an `FP_greedy` pursuer:
  −0.254±0.051 km, t = −9.81. EGTA meta-game value 5.1084 km; `FP_greedy` in both supports,
  pure for neither. Solver: 99.53% convergence, 0/2,500 LP certificate failures.
- **Next step:** pick the **capture radius** (B3 — curve is steepest 0.5–1.0 km, so the choice
  matters there), then **B6** (oracle best-response pursuer). Then Gate C (C1–C5).
- **Repo state:** Gate B work is **uncommitted** — `min_fns.jl` (D14 guard), `play_games.jl`
  (`slim_save`), `runtests.jl` (+30 asserts), `test/run_gate_b.jl`, `test/analyze_gate_b.jl`.
- **Open defects:** D12 (AL double-count, deferred, off hot path), D13 (FP opponents
  unidentifiable — modeling gap, surface in the writing).

## Working rules

- Read `Current state` above at session start. Read LOG.md only for history on a specific task.
- End of any training/eval session: prepend a block to LOG.md, then update `Current state`.
- Check the newest LOG block's "Predicted" against the new run before analyzing anything else.

## Documentation map

| File | Role |
|---|---|
| `CLAUDE.md` | This file. Always loaded: current state, how to run, code map, conventions |
| `LOG.md` | Append-only decision record, newest first. Corrections are new entries |
| `README.md` | Human-readable detailed plan: intro, references, problem, method, results |
| `docs/README_plan.md` | **Archived** original handoff plan — superseded by the three above |

## What this is

`trajectory_optimization_game_theory` — a Julia package implementing a **two-spacecraft orbital
pursuit-evasion game** in low Earth orbit.

An **evader (P1)** follows a reference orbit; a **pursuer (P2)** tries to close distance. Both
start near-circular at 620 km altitude (`a = 6998 km`, `e = 0.01`, `i = 20°`, period ~97 min);
the pursuer is offset at `a_P ≈ 1.005·a` (dispersed per trial since D2's fix).

At each **game step**:

1. A hexagon of 6 vertices, radius `R_polygon = 6.378 km`, is placed around the evader's
   reference orbit position one horizon ahead.
2. **Both players** solve 6 trajectory optimizations each (12 total) — impulsive Δv sequences
   targeting each vertex.
3. The 6×6 **zero-sum matrix game** `A[i,j]` = mean stage cost with P1 on vertex `i`, P2 on `j`.
4. The matrix game is solved by LP for a mixed Nash equilibrium.
5. Each player picks a vertex per its strategy (`mixed` / `greedy` / `random` / `FP_greedy` /
   `FP_mixed` / `Meta_greedy` / `Meta_mixed`, or an `Int` for a fixed pure vertex).
6. **Receding horizon:** 10 segments are planned, 5 are executed.

This is the "lifting" of a continuous trajectory game onto a finite action set.

**Target venue: AAMAS 2027** (abstract Oct 1, paper Oct 8 2026). Previously submitted to CDC
2026 and rejected. The research narrative and results live in `README.md`; the decision history
in `LOG.md`.

## Running things

```bash
julia -t 32 --project=.        # ALWAYS pass -t; Threads.nthreads() defaults to 1
```

- **All result paths are relative** — run from the repo root or paths break.
- `run_MC_games_parallel` uses `Threads.@threads`; without `-t` every sweep is serial.
- `test/runtests.jl` — the real test suite (~3,135 assertions). Run it after any solver change.
- `test/run_gate_b.jl` — the current sweep driver (5×5 × 100 × 30, CRN, ~106 min on 32 threads).
- `test/analyze_gate_b.jl` — B4/B5 analysis: paired intervals, EGTA, capture curve.
- `test/run_all_MC_table.jl` / `test/analyze_late_game.jl` — the older sweep + analysis pair.
- Everything else in `test/` is a REPL-style script, not a test.

**Measured cost** (32-core machine): ~16 ms per trajectory solve with LBFGS (~0.5 s with BFGS
in-pipeline), ~46 s per 30-step game single-threaded, **~106 min for the full 5×5 × 100 sweep**.

## Code organization

| Path | Role |
|---|---|
| `src/game_theory/matrix_game_solver.jl` | The core. LP Nash solver, `stage_cost`, cost matrices, strategy selection, belief updates |
| `src/game_theory/exploitability.jl` | Exploitability / NashConv / belief exploitability |
| `src/game_theory/play_games.jl` | Game loop: `prop_game_step`, `run_game`, `run_MC_games_parallel` |
| `src/Opt/min_fns.jl` | `min_Δv_dist` (the one the game uses), `min_Δv_dist_solve`, guarded objective |
| `src/Opt/aug_L.jl` | Hand-rolled augmented Lagrangian (bypassed unless the ΔV cap binds — it never has) |
| `src/Opt/obj_fns.jl` | `miss_distance_prop_kepler_Nseg`, `sum_norm_Δv`, `constrain_Δv` |
| `src/Opt/min_ipopt.jl` | 27-line unconstrained stub, **not wired into the pipeline** |
| `src/Dyn/kepler.jl` | `prop_kepler_tof_Nseg` — the workhorse propagator |
| `src/Dyn/propagator.jl` | `kep2cart` / `cart2kep`, ODE propagation, `prop_chosen_rv` |
| `src/Dyn/prop_delta_v.jl` | `find_ref_orbit`, `prop_rv_ref` |
| `src/Lambert/` | Battin Lambert solver — supplies the optimizer's initial guess |
| `src/Utils/IC.jl` | `init_game` — **all initial conditions and `params` live here** (incl. dispersion, λ1/λ2, w_miss, Δv_max) |
| `src/Utils/structs.jl` | `player_struct`, `game_struct` |
| `src/Utils/Utils.jl` | `polygon_vertices`, save/load, `slim()` persistence, MC statistics |
| `src/Utils/plotting.jl` | GLMakie plotting |
| `src/old/` | **Dead** — not included by the module |

## One game step — the execution path

This is the thing a new agent most needs.

```
prop_game_step                      play_games.jl:3
  find_ref_orbit / prop_rv_ref      prop_delta_v.jl — advance the reference orbit
  prop_chosen_rv                    propagator.jl  — execute last step's chosen trajectory
  compute_states_nash               matrix_game_solver.jl (orchestrator)
    compute_players_XU              12 trajectory optimizations (2 players × 6 vertices)
    compute_cost_matrices           6×6 zero-sum A;  players[2].cost == -players[1].cost
    compute_mixing_weights!         the LP → mixed Nash (Ipopt, tol=1e-14, nash_certificate)
    choose_strategies!              per-strategy vertex selection
    update_beliefs!                 FP counts + Bayesian meta-strategy posterior
    update_chosen_trajectories!     truncate horizon (10) to executed (5)
```

Fresh `player_struct`s are built each step; only `fp_belief`, `strategy_belief`,
`tracked_strategies`, and `learner_state` carry forward. `game.p1_state` / `p2_state` are
append-only, so every step's full candidate set is retained unless `slim_save` drops the
candidate trajectory sets (~77% of the file; nothing the analysis reads).

## Conventions that will bite you

**Sign convention — the single most important thing in this repo.**

`stage_cost` **increases with separation**. `players[1].cost = +stage_cost`,
`players[2].cost = -stage_cost`. P1 is the evader and wants separation, therefore:

> **P1 (evader) MAXIMIZES `A`. P2 (pursuer) MINIMIZES `A`.**

`solve_mixed_security_strategy(M)` returns the security strategy of the row player who
**MINIMIZES** `M`. So `solve_mixed_nash` uses `sms(-A)` for P1 and `sms(A')` for P2. Getting
this backwards was defect D1, which invalidated every `mixed`/`greedy` number in the CDC
submission. `test/runtests.jl` pins it with a test asserting the *old* pairing is exploitable.

**Other conventions:**

- `player_struct` has an **all-keyword constructor** — use `player_struct(; fp_belief=...)`, not
  the 15-argument positional form.
- The decision vector is a **30×1 `Matrix`** (`reshape(Δv_vec, N*3, 1)`), not a `Vector`, and it
  is **column-major**: segment `i`'s components are at flat indices `i, N+i, 2N+i` — *not*
  `3(i-1)+1 : 3i`.
- `axis_123` is **not an orthogonal frame**: `a1·a2 ≈ -e`. The hexagon lies in the `a2`–`a3`
  (radial/normal) plane, not the plane normal to velocity.
- Vertex order from `polygon_vertices` is `(top, topin, botin, bot, botout, topout)` = 1..6, and
  it returns a **fixed-arity NamedTuple** — changing vertex count means rewriting it (see C4 in
  `README.md`).
- `params` is a plain `NamedTuple` built in `init_game`, stored as a 1-element vector, hence the
  `game.params[1]` idiom. Since B1, `params.ic` records the realized IC draw — the CRN
  fingerprint the paired analysis checks.
- **The objective guard must catch throws, not just non-finite values** (D14): `kepler_E` can
  raise `DomainError` from `sin(Inf)` on a large trial Δv. `guarded` in `min_fns.jl` catches
  `DomainError`/`InexactError`/`OverflowError` → 1e6 penalty; anything else rethrows.

## Gotchas

- **Threads default to 1.** Always `-t`.
- **Paths are relative.** Run from the repo root.
- **The trajectory optimizer is LBFGS + BackTracking** (BFGS available via `method=`). Ipopt is
  used *only* for the matrix-game LP — it does not converge on the trajectory problem (0/12 at
  any budget; LOG 2026-08-31). Do not confuse the two roles.
- **Never `error()` inside `Threads.@threads`.** One bad 6×6 would kill an entire sweep. Record
  and fall back; report the failure rate.
- **Value-preservation discipline.** When fixing infrastructure, verify numbers are unchanged
  (bitwise where possible) so that when results *do* move, the cause is unambiguous.
- **Measure before choosing.** Several plan-era numbers did not reproduce (0.591 → 0.0221 km/s;
  Ipopt "already de-risked" → 0% convergence). Re-measure before trusting a written claim.
- **No number enters a paper table without an interval.** And no claim from n=2 (the retracted
  vertex-geometry confound is the cautionary tale — LOG 2026-09-01).
- Julia is **1.12.7**; `Manifest.toml` was resolved under **1.11.1**. Any `Pkg.add` re-resolves
  it — treat dependency changes as deliberate, tagged events.
- The repo is on branch **`aamas`**, not `main`.
- `src/old/` and `test/old/` are dead code. `min_golden_ratio` is dead *and* broken.
- The Julia LSP reports spurious `UnusedBinding` warnings on NamedTuple fields. Ignore them.

## Paper sources & division of labor

1. `Game_Theory_Space_CDC_2026/root.tex` + `sections/` — the **old pre-fictitious-play draft**,
   *not* the CDC submission.
2. `Game_Theory_Space_CDC_2026/Game_Theory_Space_ICRA_2026 (2).pdf` — the only in-repo copy of
   the **actual CDC submission**; its source lives in Overleaf.
3. Reviews in `Game_Theory_Space_CDC_2026/reviews/` (3 reviewers + AE). Common theme: the
   game-theoretic formulation was under-specified and internally inconsistent. Two complaints
   were genuine code bugs (D1, and the solver-detail request behind D7/D9).

**Division of labor: the author (Junette Hsin) owns the paper in Overleaf.** Deliver prose as
markdown and figures as PDF. **Do not create LaTeX in this repo.** Double-blind: any
supplementary zip must strip author names and git history.
