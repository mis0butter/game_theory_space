# Online Opponent Exploitation in Orbital Pursuit-Evasion Games

**Target: AAMAS 2027** — abstract Oct 1 2026, paper Oct 8 2026, 8 pages + unlimited
references, ACM sigconf, double-blind. This document is the working research narrative — a
rough draft of the paper's structure, kept as markdown per the division of labor (the author
owns the LaTeX in Overleaf; this repo delivers prose as markdown, figures as PDF, tables as
CSV with intervals). Operational details live in `CLAUDE.md`; the decision history in `LOG.md`.

---

## 1. Introduction

Two spacecraft play a pursuit-evasion game in low Earth orbit: an **evader** holds a reference
orbit while a **pursuer** maneuvers to close distance, both under impulsive-thrust dynamics.
The continuous trajectory game is intractable per se; we **lift** it onto a finite action set —
at each decision step both players choose among six candidate trajectories targeting the
vertices of a hexagon placed ahead on the evader's reference orbit — and solve the resulting
6×6 zero-sum matrix game each step, in receding horizon.

> **Headline:** what a player gains by modeling and exploiting a *specific* opponent online,
> and what it gives up in safety by doing so.
> **Supporting lemma:** the lifting — a proposition bounding the gap to the continuous game,
> plus a vertex-count ablation.

The dependency runs lifting → safety: a minimax strategy over six vertices is unexploitable
only against opponents confined to those six vertices, so the safety claim is worth exactly as
much as the lifting is faithful. (Measured: the lifting is faithful to 2.8×10⁻⁵ of the hexagon
radius — §5.1.)

The central empirical finding: a fictitious-play learner that best-responds to accumulated
beliefs about its specific opponent (**FP_greedy**) is simultaneously the best evader *and*
the best pursuer across a 5×5 strategy tournament — yet its advantage over the safe
equilibrium strategy **reverses sign** when the opponent is itself an exploiter. Exploiting an
exploiter is worse than playing safe, and two mutual exploiters produce the worst outcome of
any cell in the tournament. The empirical meta-game equilibrium says the same thing in
equilibrium terms: exploitation is worth playing, and worth *not* playing exclusively.

## 2. Main references and positioning

- **Peters, Fridovich-Keil, et al., *Learning Mixed Strategies in Trajectory Games*, RSS
  2022** — the closest prior work, already cited. They lift trajectory games to finite
  candidate sets, compute mixed Nash per step, and play in receding horizon (20-step horizon,
  replan every 9 steps), with a randomized-IC tournament reported as mean ± SEM. So lifting,
  mixed strategies, receding horizon, *and* a time-varying payoff matrix are all prior art —
  **do not claim any of them as novelty**. The defensible delta is in their own words: *"each
  player is oblivious to their opponent's decision making process."* Their adaptation is a
  trajectory generator trained offline by self-play; within a match nobody infers anything
  about who they are playing. **This paper's axis: online opponent exploitation vs. oblivious
  equilibrium play** — FP accumulates beliefs about a specific opponent across game steps and
  best-responds, with no training.
- **Robinson (1951)** — fictitious play converges in zero-sum games, **for a fixed payoff
  matrix only**. Our matrix moves every step, so the classical theorem does not apply; the
  honest claim is a *tracking* result (§4.6, C3).
- **Albrecht & Stone**, opponent modeling / type-based reasoning — the AAMAS framing for the
  `Meta_*` strategies (Bayesian posterior over a set of opponent types).
- **Empirical game-theoretic analysis (EGTA, Wellman)** — the strategy tournament analyzed as
  a normal-form meta-game (§5.4).
- The **CDC 2026 reviews** (in-repo) function as a hostile pre-read: the formulation must be
  fully specified (which plane the hexagon lies in, what the LP solves, solver convergence
  rates, what capture means), and every claim interval-bearing.

Treat the payoff matrix's time-variation not as novelty but as the thing that makes cross-step
belief pooling *questionable* — and address it honestly (§4.6, §6).

## 3. Problem

### 3.1 Scenario

Both craft start near-circular at 620 km altitude: `a = 6998 km`, `e = 0.01`, `i = 20°`,
period ≈ 97 min. The pursuer is offset in semi-major axis, `a_P = ρ·a_E`. Per Monte Carlo
trial, `ρ ~ U(1.0045, 1.0055)` and both craft receive true-anomaly and RAAN jitter (drawn
before anything strategy-dependent touches the RNG, which is what enables common random
numbers across strategy pairs). Initial separation ≈ 20 km.

### 3.2 Dynamics

Keplerian two-body propagation with impulsive Δv. A candidate trajectory over a horizon of
`N = 10` segments of equal time-of-flight is parameterized by `x ∈ R^{3N}` (30 decision
variables — stored column-major as a 30×1 matrix): coast under `prop_kepler_tof_Nseg`, apply
`Δv_i` at each segment boundary. The propagation is ForwardDiff-differentiable end to end
(this had to be *made* true — defect D10).

### 3.3 The continuous game and its lifting

The underlying object is a zero-sum trajectory game over continuous control sequences. At game
step `s`, a regular hexagon of radius `R = 6.378 km` is placed around the evader's reference
position one horizon ahead, **in the local `ê₂–ê₃` (radial/normal) plane** — note: *not* the
plane normal to velocity; the frame `axis_123` is non-orthogonal with `a₁·a₂ ≈ −e`, and the
two planes differ by ~0.57° at e = 0.01. (Reviewer 5 asked exactly this.) Vertex order:
`(top, topin, botin, bot, botout, topout)`.

Each player solves 6 trajectory optimizations (12 total per step), one per vertex `j`:

```
min_x   Σᵢ ‖Δvᵢ‖  +  w_miss · ‖r(T; x) − r_vertex_j‖        (w_miss = 1)
```

— true ΔV (ε-desingularized for the gradient) plus an exact-penalty terminal miss. The miss
term is a norm, non-smooth precisely at the solution; the smooth squared alternative measures
strictly worse (its gradient vanishes near zero and the solver stops driving the miss down:
4.2e-2 km vs 1.4e-9). Solved by quasi-Newton (LBFGS or BFGS) with a backtracking line search
and a guarded objective (§4.2). A per-segment cap `‖Δvᵢ‖ ≤ Δv_max` exists but is measured
**never to bind** at this scenario scale (max observed ‖Δv‖ ≈ 0.05 km/s against the paper's
stated 0.1 cap) — stated honestly rather than tuned into activity.

### 3.4 The stage game

With `X¹ⱼ, X²ₖ` the players' candidate trajectories, the payoff matrix is

```
A[i,j] = stage_cost(X¹ᵢ, X²ⱼ) = λ₁ · mean_t sqrt( ‖r¹(t) − r²(t)‖ + 0.1 )
```

a horizon-averaged separation. **P1 (evader) maximizes A; P2 (pursuer) minimizes A** — the
single most important sign convention in the codebase (defect D1 was exactly this, inverted).
The payoff is **separation-only by decision** (λ₂ = 0): the differential-fuel term
`λ₂(‖u_P‖−‖u_E‖)` of the CDC paper's Eq. (9), though now implemented with the correct
functional form (D4), measures ~8,000× smaller than the separation term and contributes 0% of
the matrix's variation at λ₂ = 0.1 — so it is dropped from the payoff and **ΔV is reported as
a separate metric**. `A` is not symmetric even though the hexagon is: the stage cost is a
horizon average and the players fly different paths from starts ~20 km apart; terminal
separations are exactly symmetric.

### 3.5 Per-step equilibrium and strategies

The 6×6 zero-sum game is solved by LP for a mixed Nash equilibrium (security strategies
`p* = sms(−A)` for the maximizer, `q* = sms(Aᵀ)` for the minimizer), with a
solver-independent **saddle-point certificate** checked on every solve. Strategies available
to each player per step:

| strategy | rule |
|---|---|
| `mixed` | sample from own Nash mixture — the stage-game *safety* strategy |
| `greedy` | argmax/argmin of expected payoff against the opponent's Nash mixture |
| `random` | uniform over vertices |
| `FP_greedy` | best pure response to the empirical frequency of the opponent's past choices |
| `FP_mixed` | mixture proportional to expected payoff under the FP belief |
| `Meta_greedy` / `Meta_mixed` | Bayesian posterior over a set of opponent *types*, best-respond to the posterior-predictive |
| `Int j` | fixed pure vertex — the maximally predictable opponent, used for oracle experiments |

**Receding horizon:** 10 segments planned, 5 executed, then re-plan. Only the beliefs
(`fp_belief`, `strategy_belief`, learner state) persist across steps.

### 3.6 What makes this hard to claim cleanly

- The payoff matrix moves every step (at step 30 the players are ~3 orbits from step 1), so
  FP's convergence guarantee does not apply and `mixed`'s security guarantee does not
  compound across steps. Both must be stated, not papered over.
- Cross-step belief pooling assumes vertex `j` denotes a consistent direction in the local
  `ê₂–ê₃` frame even though it is a different physical point each step. This is the honest
  weak point of the method; state it explicitly.
- Opponent *identification* is structurally uncomputable for FP opponents (D13): the tracked
  hypothesis set cannot contain `FP_*` types because that would require the opponent's
  private belief state. ID-rate metrics are therefore reported only for identifiable types.

## 4. Method — what is actually implemented

### 4.1 Pipeline

Per game step: advance the reference orbit → execute the previously chosen 5 segments → 12
trajectory optimizations → 6×6 payoff matrix → LP + certificate → per-strategy choice →
belief update → truncate horizon. See `CLAUDE.md` for the code map.

### 4.2 Trajectory solver (answers CDC Reviewer 7 #1)

It is a **nonconvex NLP solved to local optimality**. We evaluated an interior-point solver
(Ipopt via a JuMP user-defined operator): **0% convergence at any iteration budget up to
5,000** — the problem is stiff (1e-5 km/s of Δv moves the terminal position by metres over 10
segments) and the operator interface gives the solver no curvature structure. Quasi-Newton
with analytic AD gradients converges on **100% of benchmark solves and 99.53% of 15,000
in-pipeline solves**. Two load-bearing details: a *guarded objective* returning a large finite
penalty when the propagation blows up — and the guard must catch **thrown** `DomainError`s
(`sin(Inf)` inside the Kepler solve), not just non-finite returns, a failure mode that only
appeared ~200,000 solves into a 900,000-solve sweep (D14); and a **backtracking** line search —
the HagerZhang default extrapolates into the blow-up region (this alone: 1/12 → 12/12).
Caveat to state: termination is on step/objective tolerance, not gradient norm, because the
exact-penalty miss term is non-smooth at the solution.

Solver defaults: **LBFGS** (~16 ms/solve, miss ~4e-12 km) for sweeps; BFGS available
(~35–59% less ΔV, ~0.2–0.5 s/solve) — with λ₂ = 0 the ΔV difference changes a reported
metric, not play. Fuel finding worth a sentence: the optimizer matches the Lambert initial
guess's fuel (0.02926 vs 0.02928 km/s) while cutting terminal miss from 20.3 km to 7.6e-12 km
— *twelve orders of magnitude of targeting accuracy for no fuel at all*.

### 4.3 Matrix-game LP (answers CDC Reviewer 7 #2 / 8 #1)

Ipopt at `tol = 1e-14` (the LP is the *only* place Ipopt is used). The CDC-era solver (OSQP,
a first-order QP method, at defaults) solved every LP to ~3 decimal places — median
saddle-point residual 7.5e-4 on real payoff matrices, and polishing still fails 55.3% of the
time *while reporting success*. The replacement is validated by a solver-independent
certificate: median residual 3.5e-15, **0 failures in 2,500 sweep LPs**. Failure policy is
record-and-fall-back (never `error()` inside a threaded sweep) so the failure rate is itself a
reportable number. The decision margin this protects: median best-vs-2nd-best row gap is
**2.37%**, and the pre-fix D1 error (median NashConv 7.5e-2) was larger than it — **53% of
CDC-era LP solves were not equilibria at all**.

### 4.4 Monte Carlo design

100 trials × 30 steps per matchup, 5×5 strategy pairs, **dispersed initial conditions** (the
CDC-era code hardcoded both orbits, making deterministic matchups N=1 — D2), under **common
random numbers**: trial `k` uses bit-identical ICs in all 25 cells, verified from the realized
IC fingerprint before any paired number is quoted. Pairing bought a **1.4×–3.5× reduction in
standard error**. Rule: **no number enters a table without an interval.**

### 4.5 Metrics

Mean and late-game separation; total ΔV per player (separate from payoff); minimum
inter-player separation and **capture rate as a curve over candidate radii** (no single radius
is baked in yet — §6); per-step exploitability / NashConv of played strategies; LP certificate
residuals; solver convergence rate.

### 4.6 Planned (Gate C)

- **C1 — recency-weighted FP:** `f_s = γ·f_{s−1} + g_{s−1}`, γ = 1 recovering uniform FP;
  effective memory 1/(1−γ). The argument: uniform pooling averages over *different* games.
- **C2 — no-regret learner:** regret matching and/or Hedge — the AAMAS-expected baseline, and
  dynamic-regret bounds exist for time-varying games, which upgrades C3's tracking claim.
- **C3 — FP convergence, honestly split:** (i) frozen-matrix sanity check where Robinson
  applies; (ii) time-varying **tracking** — measure ‖A_{s+1} − A_s‖ and bound the
  exploitability gap by the variation budget. Do not claim Robinson applies to (ii).
- **C4 — vertex ablation 6/12/24** (fallback 6/12/18): the lifted value should stabilize as
  the action set refines. Four hardcoded arity-6 sites to generalize first.
- **C5 — lifting proposition:** restricting a maximizer's actions can only lower the value; a
  Lipschitz stage cost over a δ-net of the reachable set gives `|V_M − V_cont| ≤ L·h_M`. C4
  supplies the empirical curve; together, the answer to Reviewer 5 #4.
- **B6 — oracle best-response pursuer** vs fixed-vertex evaders: (oracle − Nash) = the price
  of safety; (FP vs oracle) = fraction of available exploitation recovered online, the stand-in
  for a MARL baseline; (oracle across vertices) = per-vertex security values, the clean
  geometry number. Blocked on the capture radius.

**Decided against (do not relitigate):** a MARL baseline for this deadline (12 NLPs per
environment step makes 10⁵–10⁶ training steps require a surrogate that is then not this
problem; also an unfair offline-vs-online comparison — the oracle BR is the honest ceiling);
claiming time-variation as novelty; removing fuel from the *trajectory* objective (it stays
there; only the *game payoff* is separation-only).

## 5. Summary of results (Gate B, 2026-09-02, CRN sweep — all numbers in `LOG.md`)

### 5.1 The lifting is faithful

Median terminal miss **4.1 cm** against R = 6.378 km (p95 8.1 cm, max 18 cm = 2.8e-5·R), no
late-game degradation, no player asymmetry — monitored per solve, asserted in the test suite.
The action space is real; the safety claim's foundation holds.

### 5.2 The tournament headline

`FP_greedy` is the best evader (row mean **6.07 ± 0.15 km**) *and* the best pursuer (column
mean **4.82 ± 0.06 km**) — online opponent modeling pays on both sides of a zero-sum game.
(Full 5×5 table with 95% CIs: LOG 2026-09-02.)

### 5.3 The exploitation/safety tradeoff, directly measured

The paired `FP_greedy − mixed` evader contrast **changes sign with the opponent**:

| vs pursuer | Δ [km], paired 95% CI | t | reading |
|---|---|---|---|
| greedy | +0.003 ± 0.072 | +0.08 | a tight null — modeling buys nothing here |
| mixed | +0.735 ± 0.083 | +17.33 | exploiting the "unexploitable" safety player |
| random | +1.983 ± 0.198 | +19.62 | largest gain vs an unmodelable opponent's noise |
| **FP_greedy** | **−0.254 ± 0.051** | **−9.81** | **exploiting an exploiter is worse than playing safe** |
| FP_mixed | +0.631 ± 0.126 | +9.83 | |

`FP_greedy` vs `FP_greedy` (4.61 km) is the lowest cell in the matrix: mutual exploitation is
worst for the evader. **That is the thesis falling out of the data.** Pre-empt the obvious
attack: the +0.735 vs `mixed` is no contradiction — `mixed` is a *stage-game* security
strategy and its guarantee does not compound across 30 steps of a moving matrix (§3.6).

### 5.4 Equilibrium restatement (EGTA)

The 5×5 tournament as a normal-form meta-game: value 5.1084 km (certificate 9.4e-15). Evader
support: `greedy` 0.830 / `FP_greedy` 0.170. Pursuer support: `mixed` 0.449 / `FP_greedy`
0.551. **Nothing is dominant** — the correct claim (vs CDC Reviewer 8's objection) is support
membership: `FP_greedy` is in the support on both sides and pure for neither. The meta-game
itself says exploitation is worth playing and worth not playing exclusively.

### 5.5 Capture (open: the radius)

No capture condition exists in the code yet; capture is reported as a curve over radii
(0.1–2 km, LOG 2026-09-02). Minimum separations run 9 m–229 m; the curve is steepest in
0.5–1.0 km, exactly where the radius choice changes conclusions. Notable: `FP_greedy` evader
vs `random` pursuer is the outlier (13% at 1 km vs 55–100% elsewhere) — an unpredictable
opponent defeats the modeling, the honest counterpoint to the headline.

### 5.6 Solver characterization (what CDC asked for)

99.53% trajectory-solver convergence over 15,000 solves; 0/2,500 LP certificate failures;
`mixed`/`mixed` NashConv of *played* strategies median 1.6e-14 — the equilibrium machinery is
correct end to end. Every CDC-era number is void (D1 alone made 53% of its LP solves
non-equilibria); no reconciliation is attempted.

### 5.7 Negative results kept deliberately

- The vertex-geometry "confound" (in-plane vs out-of-plane) **did not replicate** at n=6
  after being claimed at n=2 — there is real per-vertex spread (~25% of the mean) but no
  stable ordering. Re-measured properly under B6's oracle pursuer.
- Ipopt fails on the trajectory NLP (0% convergence) — reported as a comparison, which
  answers the solver question better than either result alone.
- The ΔV cap never binds at this scenario scale; the fuel term contributes 0% of the payoff
  variation. Both stated rather than tuned.

## 6. Open items and schedule

| When | What |
|---|---|
| now | **Pick the capture radius** (B3; the 0.5–1.0 km knee is the sensitive zone — justify the choice, e.g. by a physical docking/inspection distance, and show the curve regardless) |
| then | **B6** oracle best-response runs (≥20 seeds, CIs) |
| Sep 14–20 | Gate C: C1–C5 |
| Sep 21–30 | Writing support, figures, abstract draft |
| Oct 1 | Abstract deadline (title/authors lock) |
| Oct 8 | Paper deadline |

**Drop order if the calendar slips:** `Meta_*` promotion → 24-vertex ablation (keep 6/12) →
no-regret learner (keep discounted FP) → EGTA. **Never cut:** the sign fix, the miss-distance
diagnostic, randomized ICs with CIs, exploitability — those four make the headline provable
rather than asserted.

## 7. Reproduction

```bash
julia -t 32 --project=.                       # threads default to 1 — always pass -t
julia -t 32 --project=. test/run_gate_b.jl    # full 5×5 × 100 × 30 CRN sweep, ~106 min
julia -t 8  --project=. test/analyze_gate_b.jl
julia -t 32 --project=. -e 'using Pkg; Pkg.test()'   # ~3,135 assertions
```

Run from the repo root (paths are relative). Results land in `test/results/n30/`
(slim format, ~33 MB/file, ~805 MB/sweep).
