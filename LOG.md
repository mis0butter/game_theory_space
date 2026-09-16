# LOG — decision record

Append-only, newest first. Corrections are new entries; nothing gets edited. At milestones,
old entries roll up into a dated paragraph at the bottom. Each block: what ran (with run
identifier), what was decided, what was measured, what is predicted for the next run.

---

## 2026-09-16 — documentation restructure

**Run:** none (docs only).

**Decided:** `README_plan.md` (732 lines, plan + status + notes interleaved) split into three
files: `CLAUDE.md` (always-loaded operational context + `Current state`), `LOG.md` (this file),
`README.md` (human-readable research narrative: intro / references / problem / method /
results). `README_plan.md` retained as archive at `docs/README_plan.md` with a superseded
banner; its notes
[a]–[k] are the provenance for every number quoted here.

**State carried forward:** Gate B complete; open items are B3's capture radius and B6 (oracle
best-response), then Gate C. Gate B code changes still uncommitted (`min_fns.jl`,
`play_games.jl`, `runtests.jl`, `test/run_gate_b.jl`, `test/analyze_gate_b.jl`).

**Predicted (for B6, once a radius is picked):** against a fixed-vertex evader, the oracle-BR
pursuer captures at a far higher rate than the Nash-mixed pursuer did in the retracted note-[f]
experiment (which never came close to capture); `FP_greedy` recovers most of the oracle's
exploitation within the first ~10 steps on so predictable an opponent. The per-vertex oracle
security values will show a *stable* ordering where the Nash-opposed ranking (2026-09-01 entry)
did not.

---

## 2026-09-02 — CRN re-run + full Gate B analysis (B4, B5, B3 curve)

**Run:** `test/results/n30/` — CRN sweep, 25 matchups × 100 trials × 30 steps = 2,500 games,
~900,000 solves, **106.2 min** on 32 threads. Driver `test/run_gate_b.jl`, analysis
`test/analyze_gate_b.jl`. Config: dispersed ICs, λ2 = 0, LBFGS, slim_save. `crn_ok` verified
common random numbers from realized `params.ic` before any paired number was quoted.

**Prediction check:** the plan's §9 risk 1 predicted the headline might shrink to zero once
signs were correct. **Did not fire** — the prediction wrongly assumed a stage-game minimax
guarantee transfers to a 30-step receding-horizon game with a moving payoff matrix.

**Measured — the headline table** (mean separation, km, mean ± 95% CI, n = 100; rows P1
evader/maximizer, cols P2 pursuer/minimizer):

| P1 \ P2 | greedy | mixed | random | FP_greedy | FP_mixed | **row mean** |
|---|---|---|---|---|---|---|
| greedy | 5.56±0.13 | 4.98±0.13 | 6.46±0.18 | 5.21±0.13 | 5.48±0.17 | 5.54±0.08 |
| mixed | 5.05±0.13 | 4.98±0.13 | 6.78±0.19 | 4.87±0.13 | 5.56±0.15 | 5.45±0.09 |
| random | 4.64±0.13 | 4.93±0.13 | 6.35±0.17 | 4.58±0.13 | 5.30±0.15 | 5.16±0.09 |
| **FP_greedy** | 5.05±0.15 | 5.72±0.14 | 8.76±0.21 | **4.61±0.12** | 6.19±0.16 | **6.07±0.15** |
| FP_mixed | 4.85±0.13 | 5.43±0.14 | 7.55±0.17 | 4.83±0.13 | 5.86±0.15 | 5.70±0.11 |
| **col mean** | 5.03±0.07 | 5.21±0.07 | 7.18±0.11 | **4.82±0.06** | 5.68±0.07 | |

`FP_greedy` is best evader *and* best pursuer. The `FP_greedy − mixed` paired contrast changes
sign with the opponent: +0.003±0.072 (t=+0.08, a tight null) vs `greedy`; +0.735±0.083
(t=+17.33) vs `mixed`; +1.983±0.198 vs `random`; **−0.254±0.051 (t=−9.81) vs `FP_greedy`** —
exploiting an exploiter is worse than playing safe; +0.631±0.126 vs `FP_mixed`.
`FP_greedy`/`FP_greedy` (4.61) is the lowest cell in the matrix.

**Pairing bought a 1.4×–3.5× SE reduction** (ratios 2.79, 2.32, 1.41, 3.54, 1.71). The
`greedy` column resolved from "underpowered" to a genuine null. Reproducibility vs the
unpaired sweep: identical `greedy`/`greedy` (5.56), row means within 0.06 km, all significant
contrasts preserved in sign.

**B5 EGTA meta-game:** value **5.1084 km**, certificate 9.4e-15. P1 support: `greedy` 0.830 /
`FP_greedy` 0.170. P2 support: `mixed` 0.449 / `FP_greedy` 0.551. **Nothing is dominant.** The
honest claim vs Reviewer 8 is *support membership*: `FP_greedy` is in both supports, pure for
neither. `random` and `FP_mixed` out of support on both sides.

**B3, partially — capture as a curve** (no capture condition exists in the code yet):

| radius (km) | 0.10 | 0.25 | 0.50 | 1.00 | 2.00 |
|---|---|---|---|---|---|
| `mixed` evader (range over 5 pursuers) | 0–1% | 1–10% | 19–32% | 66–96% | 99–100% |
| `FP_greedy` evader | 0–3% | 1–21% | 6–38% | 13–100% | 43–100% |

Min inter-player separations run 9 m – 229 m. Curve steepest between 0.5 and 1.0 km — that
interval is where the radius choice changes conclusions. `FP_greedy` vs `random` is the outlier
(13% at 1 km): an unpredictable opponent defeats the modelling.

**For the writing, pre-empt:** `FP_greedy` gains +0.735 km against `mixed`, "supposed to be
unexploitable" — no contradiction; `mixed` is a *stage-game* security strategy and its
guarantee does not compound across 30 steps of a moving matrix. Same cross-step-pooling
assumption C3 must state.

**Decided:** B3's radius still open; B6 blocked on it. Narrative otherwise ready to lock.

---

## 2026-09-01 (pm) — first Gate B sweep lands, but unpaired

**Run:** `test/results/n30_unpaired_2026-09-01/` — same 25 × 100 × 30 config, **106.4 min**,
32 threads. Data retained.

**Found:** `run_MC_games_parallel` derives per-game seeds from the rng it is handed
(`play_games.jl:124`), and the driver threaded a single `MersenneTwister(1)` through all 25
calls in sequence — every cell drew *different* ICs, so only an unpaired test was licensed,
and B4 asks for paired.

**Decided:** reseed **inside** the matchup loop so game *k* uses bit-identical ICs in all 25
cells (valid because `IC.jl:61-65` draws all five IC variates unconditionally before anything
strategy-dependent touches the rng — verified via `params.ic`). Re-run under CRN.

**Predicted:** paired SEs materially tighter; unpaired point estimates reproduced within noise.
*(Confirmed 2026-09-02: 1.4×–3.5×; row means within 0.06 km.)*

---

## 2026-09-01 — D14 crash; λ2 = 0 decision; LBFGS; B1/B2 land

**Run:** first Gate B attempt **crashed ~200,000 solves in (~40 min)**.

**D14 found and fixed:** the objective guard `isfinite(raw(x)) ? v : 1e6` never sees a *thrown*
exception — a large trial Δv drives mean anomaly to Inf, `kepler_E` evaluates `sin(Inf)`,
`DomainError` propagates. 15,000 smoke-sweep solves never hit it; only a 900k-solve run could.
Fix: `guarded` catches `DomainError`/`InexactError`/`OverflowError` → 1e6 penalty (line search
backs off); anything else rethrows. Pinned by a testset. **Lesson: a guard against non-finite
return values is not a guard against a propagator that throws.**

**Decided — note [j] closed, option 3: the payoff is separation-only, λ2 = 0.** Measured
decomposition: separation term ≈ 4.1 with range 0.4442 across the 6×6; fuel term ≈ 0.0005 with
range **0.0000** — ~8,000× smaller, contributing 0% of the variation. Raising λ2 rejected (would
re-open every Gate A measurement days before narrative lock); normalization rejected likewise.
ΔV is reported as a separate metric. (Related finding for the writing: `A[i,j]` asymmetry comes
from the horizon-averaged stage cost over different flight paths from ~20 km-apart starts, not
from fuel; terminal separations are exactly symmetric.)

**Decided — LBFGS default** (`min_fns.jl:206`), taking note [i]'s lever: 60-subproblem
measurement gives LBFGS 100% convergence, 56 iters, miss 4.2e-12 km vs BFGS's 828 iters at
comparable miss; only cost is ~35–59% more ΔV, which with λ2 = 0 never reaches a decision —
it changes a reported metric, not play. Swap back via `method = BFGS(...)`.

**B1 (D2 fixed):** `init_game(...; disperse=true)` draws `a_P/a_E` uniform on (1.0045, 1.0055)
plus ν and Ω jitter on both craft, driven by the game rng; `run_MC_games_parallel` **defaults
`disperse=true`** so the failure cannot recur silently. Deliberately *not* `rand_IC` (it drops
the drift and hands the pursuer the evader's velocity — a different scenario). `params.ic`
records the realized draw.

**B2:** `slim()` persistence — drops the per-step candidate trajectory sets (~77% of the file;
nothing the analysis reads). 33 MB/file vs 59; ~805 MB for the full sweep.

---

## 2026-09-01 (am) — verification figures; note [f] geometry claim retracted

**Run:** figure generation on Gate A data; commit `1582724`.

**Retracted:** the "geometric confound" (in-plane vertices systematically better for the
evader) **did not replicate**. Claimed from n=2 seeds without an interval; at 6 seeds
(`fig7_vertex_geometry.pdf`) the ranking essentially inverts and per-seed ranks cross
constantly — no stable ordering, and the two out-of-plane vertices rank 1st and 4th. What
survives: real vertex-dependent spread (~1.1 km on a ~4.4 km grand mean, ~25%), just not a
fixed bias. The experiment was also mis-designed — a Nash-mixed pursuer *declines to exploit*,
the wrong opponent for a perfectly predictable evader. Folded into B6 (oracle best-response).
**Lesson recorded: no claim from n=2, in a plan whose own rule is "no number without an
interval."**

**Re-measured after D4** (1,250 matrices): matrix range 59.8%, P1 leverage 18.1%,
**best-vs-2nd-best row gap 2.37%** — the decision margin. Pre-fix D1 NashConv (7.5e-2) was
comparable to that gap, i.e. **53.0% of pre-fix LP solves (663/1,250) were not equilibria at
all** (`fig2_lp_correctness.pdf`).

---

## 2026-08-31 (evening) — smoke sweep passes; Gate A closes

**Run:** `test/results/n10/` — 25 matchups × 5 games × 10 steps, 15,000 trajectory solves,
2,500 LPs, **27.3 min** on 32 threads. Commits `19fb075`, `5506f0e`.

**Measured:** BFGS convergence **99.53%** (14,929/15,000); 0% escalation to the augmented
Lagrangian (ΔV cap never binds); terminal miss median 7.3e-12 km, max 8.2e-05 (R = 6.378).
LP certificate violation median 3.7e-15, **0/2,500 above 1e-8**, 0 fallbacks.
**`mixed`/`mixed` NashConv of played strategies: median 1.6e-14** — D1 is fixed end to end.

**Cost warning:** in-pipeline median 0.505 s/solve under BFGS (not the 0.154 s step-1 figure)
→ full Gate B projected ~2.5 h. Levers named: LBFGS (~10–15× faster), lower maxiter, or accept.
*(Resolved 2026-09-01: LBFGS taken.)*

---

## 2026-08-31 — A6/D9: BFGS in, Ipopt rejected by measurement; D10 unblocks AD

**Run:** solver bake-off on the 12 step-1 subproblems, then all 60 across 10 steps. Commit
`adb0aea`.

**D10 first:** `cart2kep` allocated `oe = zeros(6)` (`Vector{Float64}`) on the objective's call
path → `ForwardDiff` threw on every gradient. **No gradient-based solver could ever have run**;
the plan's "LBFGS fallback" was never a hedge. One-line fix, gated bitwise on 20,000 states and
against `central_fdm(5,1)` to 1.6e-9.

**Measured (60 subproblems, median):** Nelder-Mead 1.7% converged; **Ipopt 0% converged at any
budget up to 5,000 iters** (JuMP user-defined operator gives it no structure on a stiff
problem; miss oscillates non-monotonically) and 1.29 s wall; LBFGS+BackTracking 100%, 0.013 s;
BFGS+BackTracking 100%, 0.174 s, 35% less fuel. Two load-bearing details, neither in the plan:
a **guarded objective** (line search hits non-finite values) and **BackTracking, not
HagerZhang** (which extrapolates into the blow-up; this alone moved 1/12 → 12/12).

**Decided:** BFGS + BackTracking default (later LBFGS, 2026-09-01); AL bypassed unless the ΔV
cap binds post-solve; caveat for the paper: termination is on step/objective tol, not gradient
norm — the miss term is an exact penalty, non-smooth at the solution, and the smooth squared
alternative measured strictly worse (4.2e-2 vs 1.4e-9).

**Corrected [g]:** the earlier "optimized costs 162% of Lambert" was **Nelder-Mead's
inefficiency, not a physical price** — BFGS matches Lambert's fuel (0.02926 vs 0.02928 km/s)
while cutting miss from 20.3 km to 7.6e-12 km. *The optimizer buys twelve orders of magnitude
of targeting accuracy for no fuel at all.*

---

## 2026-08-31 — Gate A correctness fixes (D1, D3–D8, D11); tests from 6 lines to 3,105

**Run:** diagnostics on freshly generated data (the old machine's 12 GB of results never
existed here). Commits `941c1c3`, `0ccc33a`.

- **D1 fixed** — `sms(-A)` for P1, `sms(A')` for P2, orientation *derived* from `stage_cost`.
  Value threaded, weights normalized centrally, `z ≥ 1e-4` floor dropped. Pinned by a test
  asserting the old pairing is exploitable.
- **D7 quantified, LP solver swapped OSQP → Ipopt (tol 1e-14).** On 313 real payoff matrices:
  OSQP defaults median residual 7.5e-4 (100% > 1e-8); OSQP polished still fails 55.3%;
  Ipopt 3.5e-15, 0%. Every CDC-era LP was solved to ~three decimal places. Added
  `nash_certificate` (solver-independent saddle residual) + record-and-fall-back policy.
- **D3 retired — NOT a defect.** 2,880 on-policy samples: median terminal miss **4.1 cm**,
  p95 8.1 cm, max 18 cm = 2.8e-5·R. The lifting is real; §9 risk 2 dead.
- **D4 fixed** — stage cost `λ1·sqrt(dist+0.1) + λ2·(‖u_P‖−‖u_E‖)`. Sign trap avoided: the
  commented "intended" line was itself sign-inverted under the corrected D1 orientation.
  Pinned: equal burns cancel exactly.
- **D5 fixed** — three defects, not two: P2 `Meta_greedy` missing transpose *and* argmin/argmax;
  `Meta_mixed` missing transpose *and* inverted weight formula.
- **D11 fixed** — `sum_norm_Δv` returns true ΔV (ε=1e-12 desingularized); `w_miss` in `params`,
  swept 1→1000, clean monotone fuel/miss tradeoff, reachability passes at every setting.
- **D6 reframed** — measured max ‖Δv‖ 0.0221–0.0525 km/s; neither 2.0 nor the paper's 0.1
  would ever bind. Plumbing fixed (`params.Δv_max`); state inactivity honestly.
- **D8 fixed** — `@exfiltrate` removed, `load_games_vec` repaired, `prop_rv_ref` aliasing fixed,
  `@elapsed` on every solve and LP.
- Schema pulled forward from Gate C: `solve_info`, `learner_state`, all-keyword
  `player_struct` constructor.
- `test/runtests.jl`: 6 lines → 3,105 assertions, 0 failing.

**Still open at Gate A close:** D12 (AL double-counts objective — deferred, only reachable via
unused `min_Δv`), D13 (`tracked_strategies` has no FP/Meta hypotheses; ID rate structurally NaN
for FP opponents — a modeling gap, not a bug: extending it needs the opponent's unobservable
`fp_belief`. Surface in the writing).

---

## Roll-up — before 2026-08-31

The paper was submitted to **CDC 2026 (#2010) and rejected** (3 reviews + AE in
`Game_Theory_Space_CDC_2026/reviews/`; common theme: game formulation under-specified and
internally inconsistent). A code audit traced two review complaints to genuine bugs and
produced defects **D1–D9**; **D10–D14** were found later during execution. The AAMAS 2027 plan
was authored 2026-08-30/31 (commits `b3404a1`, `c076a1b`) as `README_plan.md`, including the
agreed framing (online opponent exploitation vs oblivious equilibrium play; the delta over
Peters et al. RSS 2022) and decisions not to relitigate: no MARL baseline for this deadline
(oracle BR instead), fuel stays in the trajectory objective, venue is AAMAS. Machine
corrections found on arrival: 32 cores not 8; `test/results/` (~12 GB) gitignored and never
copied — all Gate A inputs regenerated (~1 min); Julia 1.12.7 vs Manifest resolved under
1.11.1; branch `aamas`, no `README.md` (until 2026-09-16). Four plan premises later proved
wrong and were corrected in place: D3 dead on day 1; the AD path was broken (D10), not
de-risked; Ipopt does not converge here; the ΔV cap can never bind.
