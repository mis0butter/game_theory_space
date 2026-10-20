# CLAUDE.md

Guidance for Claude Code when working in this repository. When responding to prompts, ELI5 to the human user.

## Current state

*Rewritten in place each session. Keep it short — results go in `LOG.md`, not here. Last updated: 2026-10-18.*

- **Goal:** submit to **ECC 2027 by Oct 31 2026** (PaperCept; review copy ≤ 8 pp, final ≤ 6 pp;
  ieeeconf, PDF ≤ 3 MB; CFP silent on blind review). Write for a **controls audience**.
- **Research:** Gates A–C are done. No new sweeps are planned.
- **Now:** rewriting the paper in `Game_Theory_Space_ECC_2027/`. It is still the CDC text and
  steps 1 (remove stale CDC claims) and 2 (methods vs. the CDC reviews) are done; red `[TODO: …]` markers show where new content goes. The to-do list is in `README.md` § Paper to-do.
- **Open review gap:** G2, the lifting bound's scope (step 3). G1 (`greedy` = heuristic) and
  G3 (`FP_mixed` formula) are closed in `methods.tex`.
- **Open defects:** D12 (deferred, off the hot path), D13 (FP opponents unidentifiable —
  mention it in the writing).
- **Data location:** full Gate B/C results are on the 32-core machine. This 8-core machine only
  has `mixed`/`mixed` and `FP_greedy`/`FP_greedy` (regenerated 2026-10-17).
- **Repo:** last commit 66eadae. Uncommitted: doc rewrites, `test/analyze_c3.jl`, and the whole
  `Game_Theory_Space_ECC_2027/` folder.

## Working rules

- Read `Current state` at session start. Read `LOG.md` only for the history of a specific task.
- After any run: prepend a block to `LOG.md` (what ran, what was decided, what was measured),
  then update `Current state`.
- Check the newest LOG block's "Predicted" against a new run before analyzing anything else.

## Documentation map

| File | Role |
|---|---|
| `CLAUDE.md` | This file: current state, how to run, code map, conventions |
| `README.md` | Short project summary: thesis, key results, status, paper to-do |
| `LOG.md` | Append-only decision record, newest first. **Every number with its interval lives here** |
| `docs/README_narrative_2026-10-18.md` | Archived full narrative — drafting source for the `.tex` |

## The paper

- **Edit the `.tex` files in `Game_Theory_Space_ECC_2027/` directly.** That folder is the paper.
- **The whole paper is in `MAIN_PAPER.tex`** (sections pasted in 2026-10-19). Edit only that
  file. `sections/*.tex` are stale copies — do not edit them. The one exception is
  `sections/macros.tex`, which is still `\input` and holds the preamble. `root_template.tex` and `root.pdf` are the ECC template, not the
  paper. `sections/old/`, `MAIN_PRES.tex` and `pres_*` are not part of the paper.
- **LaTeX is not installed on this machine**, so page count and compile errors can only be
  checked where the author compiles. Say so rather than guess.
- Figures: PDF, one ieeeconf column wide where possible. Keep the whole PDF ≤ 3 MB.
- Every number in the paper must come from `LOG.md` with its interval, using one machine's
  run consistently (the 32-core run unless LOG says otherwise).
- `Game_Theory_Space_ECC_2027/reviews/` holds the CDC 2026 reviews (3 reviewers + AE). The rest
  of the CDC folder was deleted 2026-10-18; it is still in git history (commit 66eadae). ECC
  reviewers are the same community, so treat these reviews as the pre-read.

## What this is

`trajectory_optimization_game_theory` — a Julia package for a **two-spacecraft orbital
pursuit-evasion game** in low Earth orbit. An **evader (P1)** follows a reference orbit; a
**pursuer (P2)** tries to close distance. Both start near-circular at 620 km altitude
(`a = 6998 km`, `e = 0.01`, `i = 20°`), the pursuer at `a_P ≈ 1.005·a` (dispersed per trial).

At each **game step**:

1. A hexagon of 6 vertices, radius 6.378 km, is placed around the evader's reference
   position one horizon ahead.
2. Each player solves 6 trajectory optimizations (12 total), one Δv sequence per vertex.
3. These form a 6×6 **zero-sum matrix game** `A[i,j]` (mean stage cost, P1 on `i`, P2 on `j`).
4. An LP gives the mixed Nash equilibrium.
5. Each player picks a vertex by its strategy (`mixed` / `greedy` / `random` / `FP_greedy` /
   `FP_mixed` / `Meta_*` / learners / `oracle`, or an `Int` for a fixed vertex).
6. **Receding horizon:** 10 segments planned, 5 executed.

## Running things

```bash
julia -t 32 --project=.        # ALWAYS pass -t; Threads.nthreads() defaults to 1
```

- **Run from the repo root** — all result paths are relative.
- `test/runtests.jl` — the real test suite (3,369 assertions). Run it after any solver change.
- Sweep drivers: `test/run_gate_b.jl` (5×5 × 100 × 30, ~106 min on 32 threads), `run_b6.jl`,
  `run_c1c2.jl`, `run_c1_asym.jl`, `run_c2_fill.jl`, `run_c4.jl`.
- Analysis: `test/analyze_gate_b.jl`, `analyze_b6.jl`, `analyze_c1c2.jl`, `analyze_c3.jl`,
  `analyze_c4.jl`. Results go to `test/results/` (gitignored).
- Everything else in `test/` is a REPL-style script, not a test.
- **Cost** (32-core): ~16 ms per LBFGS trajectory solve; ~46 s per 30-step game single-threaded.

## Code organization

| Path | Role |
|---|---|
| `src/game_theory/matrix_game_solver.jl` | The core: LP Nash solver, `stage_cost`, cost matrices, strategy selection, belief updates |
| `src/game_theory/exploitability.jl` | Exploitability / NashConv |
| `src/game_theory/play_games.jl` | Game loop: `prop_game_step`, `run_game`, `run_MC_games_parallel` |
| `src/Opt/min_fns.jl` | `min_Δv_dist` (what the game uses), `min_Δv_dist_solve`, guarded objective |
| `src/Opt/aug_L.jl` | Augmented Lagrangian — bypassed unless the ΔV cap binds (it never has) |
| `src/Opt/obj_fns.jl` | `miss_distance_prop_kepler_Nseg`, `sum_norm_Δv`, `constrain_Δv` |
| `src/Dyn/kepler.jl` | `prop_kepler_tof_Nseg` — the workhorse propagator |
| `src/Dyn/propagator.jl` | `kep2cart` / `cart2kep`, `prop_chosen_rv` |
| `src/Dyn/prop_delta_v.jl` | `find_ref_orbit`, `prop_rv_ref` |
| `src/Lambert/` | Battin Lambert solver — the optimizer's initial guess |
| `src/Utils/IC.jl` | `init_game` — **all initial conditions and `params`** |
| `src/Utils/structs.jl` | `player_struct`, `game_struct` |
| `src/Utils/Utils.jl` | `polygon_vertices`, save/load, `results_folder`, MC and capture statistics |
| `src/Opt/min_ipopt.jl`, `src/old/`, `test/old/` | Dead — not in the pipeline |

## One game step — the execution path

```
prop_game_step                      play_games.jl
  find_ref_orbit / prop_rv_ref      advance the reference orbit
  prop_chosen_rv                    execute last step's chosen trajectory
  compute_states_nash               matrix_game_solver.jl (orchestrator)
    compute_players_XU              12 trajectory optimizations
    compute_cost_matrices           6×6 A;  players[2].cost == -players[1].cost
    compute_mixing_weights!         LP → mixed Nash (Ipopt, tol=1e-14, nash_certificate)
    choose_strategies!              per-strategy vertex selection
    update_beliefs!                 FP counts + Bayesian meta-strategy posterior
    update_chosen_trajectories!     truncate horizon (10) to executed (5)
```

Fresh `player_struct`s are built each step; only `fp_belief`, `strategy_belief`,
`tracked_strategies` and `learner_state` carry forward.

## Conventions that will bite you

**Sign convention — the most important thing in this repo.** `stage_cost` increases with
separation; `players[1].cost = +stage_cost`, `players[2].cost = -stage_cost`.

> **P1 (evader) MAXIMIZES `A`. P2 (pursuer) MINIMIZES `A`.**

`solve_mixed_security_strategy(M)` returns the strategy of the row player who **minimizes** `M`,
so `solve_mixed_nash` uses `sms(-A)` for P1 and `sms(A')` for P2. Getting this backwards was
defect D1, which voided every CDC number. A test asserts the old pairing is exploitable.

- `greedy` = `argmax` of the player's **own** Nash weights — a heuristic, not a best response.
- `player_struct` has an **all-keyword constructor** — use `player_struct(; fp_belief=...)`.
- The decision vector is a **30×1 `Matrix`**, **column-major**: segment `i` is at flat indices
  `i, N+i, 2N+i`.
- `axis_123` is **not orthogonal** (`a1·a2 ≈ -e`). The hexagon lies in the `a2`–`a3`
  (radial/normal) plane, not the plane normal to velocity.
- Vertex order is `(top, topin, botin, bot, botout, topout)` = 1..6. For n ≠ 6 a general
  formula is used; n = 6 keeps the original arithmetic so old results stay bitwise identical.
- `params` is a `NamedTuple` stored as a 1-element vector (`game.params[1]`). `params.ic` is the
  realized IC draw, used to check common random numbers.
- The objective guard must **catch throws** (`DomainError`/`InexactError`/`OverflowError` →
  1e6 penalty), not just non-finite values (D14).

## Gotchas

- **Threads default to 1** — always pass `-t`. **Paths are relative** — run from the repo root.
- **Trajectory optimizer = LBFGS + BackTracking.** Ipopt is used *only* for the matrix-game LP;
  it never converges on the trajectory problem.
- **Never `error()` inside `Threads.@threads`.** Record, fall back, report the failure rate.
- **Value preservation:** after infrastructure changes, check numbers are unchanged (bitwise
  where possible) — but **only against files made on the same machine**; the two machines
  differ in the 3rd–4th significant figure.
- **Measure before trusting a written claim.** Several plan-era numbers did not reproduce.
- **No number in a paper table without an interval**, and no claim from tiny samples.
- Julia 1.12.7, but `Manifest.toml` was resolved under 1.11.1 — any `Pkg.add` re-resolves it.
- The branch is **`aamas`** (historical name), not `main`.
- The Julia LSP's `UnusedBinding` warnings on NamedTuple fields are spurious.
