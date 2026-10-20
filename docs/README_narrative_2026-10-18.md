> **ARCHIVED 2026-10-18.** This is the full research narrative as it stood when `README.md` was
> cut down to essentials. It is the drafting source for the ECC paper's `.tex` sections:
> detailed method prose, every results write-up, the CDC review response map (§4.8) and the
> page budget (§4.7). Not maintained. Current status lives in `README.md` and `CLAUDE.md`.

# Online Opponent Exploitation in Orbital Pursuit-Evasion Games

**Target: ECC 2027** (European Control Conference, Brussels, 13–16 July 2027) — **paper due
Oct 31 2026** via PaperCept. Review manuscript ≤ 8 pages two-column (ieeeconf.cls, US Letter,
PDF ≤ 3 MB); **final ≤ 6 pages**, +2 at paid over-length charges. Notification Mar 5, final
Apr 5 2027. The CFP does not state the review model (blind or not) — confirm in PaperCept's
author instructions. Switched from AAMAS 2027 on 2026-10-16 ([CFP](https://ecc27.euca-ecc.org/call-for-papers/)).

This document is the working research narrative — a
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

**Framing for ECC (controls audience).** This is a **game-theoretic receding-horizon guidance
law** for spacecraft pursuit-evasion: each step solves nonconvex trajectory NLPs, assembles a
finite zero-sum game, and solves it by certified LP. The controls questions come first — *is
the finite approximation faithful, is the scheme reliably solvable in time, and what do
capture and safety mean* — and the opponent-adaptation result is what the scheme buys you.

> **Headline:** a minimax (security) guidance policy versus an adaptive one that learns its
> specific opponent online — what adaptation gains, and what it costs in safety.
> **Supporting result (first-class for ECC):** the lifting — a proposition bounding the value
> gap to the continuous game, with an empirical convergence curve (6/12/24 vertices).

**Contributions, in ECC order:**

1. **A lifted receding-horizon formulation with a value-gap bound.** Restricting an action set
   moves the value in a known direction, and `|V_M − V_cont| ≤ L·h_M`; measured, the hexagon is
   within ~1.5% of the extrapolated continuum value (§5.8).
2. **A reliable, characterized solution pipeline.** Nonconvex trajectory NLP solved to local
   optimality by quasi-Newton (99.53% convergence, ~16 ms/solve, terminal miss 4 cm vs a
   6.378 km polygon); matrix game by LP with a solver-independent saddle-point certificate
   (0 failures / 2,500). Compute per game step (~1.5 s single-threaded, from the ~46 s/30-step
   measurement) is ~400× shorter than the ~585 s of trajectory executed per step (§4.2–4.3, §5.6).
3. **The safety/adaptation tradeoff, quantified with intervals and capture rates.** Adaptive
   guidance (fictitious play) beats minimax against most opponents, reverses sign against
   another adaptive player, and the price of safety against a predictable opponent is
   +3.2–3.3 km with 100% vs 0–9% hard capture (§5.3, §5.5, §5.7).

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
- **Albrecht & Stone**, opponent modeling / type-based reasoning — background for the
  `Meta_*` strategies. Secondary for ECC; cite in one line or drop.
- **Empirical game-theoretic analysis (EGTA, Wellman)** — the tournament as a meta-game
  (§5.4). Secondary for ECC: one sentence ("nothing is dominant; FP is in the support on both
  sides") answers CDC Reviewer 8 without spending page space.
- **Controls positioning — author to supply citations:** orbital pursuit-evasion differential
  games, game-theoretic / min-max MPC, and spacecraft proximity-operations guidance. These are
  the communities ECC reviewers come from; the contribution should be stated relative to them,
  not only relative to Peters et al.
- The **CDC 2026 reviews** (in-repo) are the most relevant pre-read now: ECC draws on the same
  reviewer community. The formulation must be fully specified (which plane the hexagon lies
  in, what the LP solves, solver convergence rates, what capture means), and every claim
  interval-bearing. Per-comment mapping in §4.7 (W5).

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
| `greedy` | the vertex with the **largest weight in its own Nash mixture** (`argmax(w*)`) — a **heuristic baseline**, not a rational use of a mixed equilibrium, whose guarantee requires sampling the full distribution (CDC R7 #4). Not a best response to anything. |
| `random` | uniform over vertices |
| `FP_greedy` | best pure response to the empirical frequency of the opponent's past choices |
| `FP_mixed` | **heuristic** stochastic FP: with expected payoff `c = A_own·q̂` under the FP belief, sample vertex `i` with probability `∝ c_i − min(c) + 10⁻⁶`. Always non-negative and invariant to adding a constant to `c`. The worst vertex gets ~0 probability. Not a smoothed best response (CDC R7 #5). |
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
inter-player separation and **hard/soft capture** (first passage below 0.2 km / 1.0 km, §5.5,
with the full radius curve reported alongside) plus time-to-first-capture; per-step
exploitability / NashConv of played strategies; LP certificate residuals; solver convergence
rate.

### 4.6 The workstream gates

Work is organized into four gates. This is the project's skeleton — **the definitions below
are authoritative**; `docs/README_plan.md` §4 holds the original longer-form spec for
provenance only and is not maintained.

| Gate | What it is | Status |
|---|---|---|
| **A** | **Correctness + existential diagnostics.** Fix the defects that would invalidate any number (the LP sign inversion, the stage cost, the trajectory solver, the AD path), and settle the existential question of whether candidates actually reach their vertices. A1–A6. | ✅ **complete 2026-08-31** |
| **B** | **The honest re-run.** Real Monte Carlo with dispersed ICs, slim persistence, the full 5×5 tournament with intervals and a valid paired test, the EGTA meta-game, a capture condition, and the oracle best-response ceiling. B1–B6. | ✅ **complete 2026-09-16** |
| **C** | **The contribution.** The methodological content that makes this a paper rather than a corrected replication: a better learner, a standard no-regret baseline, an honest convergence claim, and the lifting made rigorous. C1–C5, below. | ✅ **complete 2026-09-17** |
| **D** | **Writing support for ECC 2027.** Deliver prose as markdown, tables as CSV with intervals, figures as PDF, sized for a 6-page ieeeconf paper and pointed at a controls audience. W1–W6 in §4.7. | ⬜ **current**, Oct 16 – 31 |

**Narrative locked at the end of Gate B.** Gate C adds to the story; it should not require
re-opening the numbers in §5. If a Gate C result contradicts one, that is a finding to
report, not a reason to silently re-run Gate B.

#### Gate C — the contribution

- **C1 — recency-weighted FP.** ✅ **Complete 2026-09-17** — §5.9. Implemented with per-player
  γ; the operative condition turned out to be *systematic* drift, not mere movement.
- **C2 — no-regret learner.** ✅ **Complete 2026-09-17** — §5.9. Regret matching and Hedge;
  competitive but not dominant, and the gap appears against a best-responder.
- **C3 — FP convergence, honestly split.** ✅ **Complete 2026-09-17** — §5.9. Frozen-matrix
  convergence holds on every sampled matrix (median `T^-0.55`, worst case `T^-0.43`;
  tail recorded 2026-10-17); the time-varying case is a *tracking* result with a flat
  ~0.25 km gap, and FP's success is **not** explained by equilibrium tracking.
- **C4 — vertex ablation 6/12/24.** ✅ **Complete 2026-09-17** — results in §5.9.
- **C5 — lifting proposition.** Statement and empirical constant in §5.9.
- **B6 — oracle best-response pursuer** vs fixed-vertex evaders: (oracle − Nash) = the price
  of safety; (FP vs oracle) = fraction of available exploitation recovered online, the stand-in
  for a MARL baseline; (oracle across vertices) = per-vertex security values, the clean
  geometry number. **Complete 2026-09-16** — results in §5.7.

### 4.7 Gate D — writing support for ECC 2027 (Oct 16 – 31)

Items are numbered **W1–W6**, not D1–D6, to avoid colliding with the defect IDs D1–D14.

**Page budget.** Write to **6 pages**, the final limit. The 8-page review allowance is
available, but anything in pages 7–8 must either be cut after acceptance or paid for. Proposed
allocation for the two-column ieeeconf format:

| Section | ~pages | Content |
|---|---|---|
| I. Introduction | 0.75 | problem, controls positioning, the three contributions |
| II. Problem formulation | 1.0 | dynamics, continuous game, lifting, stage payoff, sign convention |
| III. Receding-horizon scheme | 1.0 | trajectory NLP + solver, LP + certificate, policies (minimax / greedy / FP) |
| IV. Lifting bound | 0.75 | proposition (C5) + vertex-convergence curve (C4) |
| V. Results | 1.5 | MC/CRN design; tradeoff and sign reversal; price of safety (B6); capture |
| VI. Conclusion | 0.25 | |
| References | 0.5–0.75 | |

**Emphasis shift from AAMAS.** *Promote:* the lifting bound (§5.8), solver reliability and
timing (§4.2–4.3, §5.6), capture definitions (§5.5), the price of safety (§5.7), and the
explicit sign convention. *Keep, compressed:* the tournament headline and sign reversal (§5.3),
FP's convergence on a frozen matrix plus "it tracks a stable opponent rule, not the
equilibrium" (C3, two sentences). *Demote to one sentence or cut:* EGTA (§5.4), no-regret
learners (C2), discounting (C1), `Meta_*` types, D13 identifiability.

| Item | Deliverable | Status |
|---|---|---|
| **W1** | Section outline + page budget agreed with the author (table above as the draft) | ⬜ |
| **W2** | Figures as PDF, sized for one column: capture curve (§5.5), vertex-convergence curve (§5.8), price-of-safety / oracle-vs-FP-vs-Nash (§5.7), and optionally the 5×5 tournament heatmap | ⬜ |
| **W3** | Tables as CSV with 95% CIs: `FP_greedy − mixed` contrast by opponent (§5.3); M = 6/12/24 values (§5.8); solver characterization (§5.6) | ⬜ |
| **W4** | Markdown prose per section, written for controls readers (problem statement as an optimal-control / game formulation first, learning second) | ⬜ |
| **W5** | CDC-review response map: each reviewer comment in `Game_Theory_Space_ECC_2027/reviews/` → the section and number that answers it | ✅ map drafted 2026-10-17 (§4.8); 3 gaps open |
| **W6** | Submission check: ≤ 3 MB PDF, ieeeconf format, page count; anonymize the supplementary material only if the review model turns out to be blind | ⬜ |

### 4.8 CDC review response map (W5)

Status key: **✅ fixed** = changed in code and measured; **✍ writing** = substance exists, but
the paper must state it; **⚠ gap** = not yet answered. Reviews are in
`Game_Theory_Space_ECC_2027/reviews/`.

**The three open gaps:**

- **G1 — `greedy` (R7 #4, AE "rationale behind the greedy … rule").** The code still picks
  `argmax(w*)`, exactly what R7 criticized. Changing it would re-open Gate B, so the decision
  is to **label it a heuristic baseline** (§3.5) and say so in the paper. Until 2026-10-17 this
  README misdescribed it as a best response to the opponent's Nash mixture.
- **G2 — distance to the original problem (R5 #4, AE).** The lifting bound covers the circle
  stage game, not the continuous-control closed loop (scope note in §5.8). Either state that
  scope precisely in the paper, or extend the bound to a reachable-set net.
- **G3 — `FP_mixed` (R7 #5, AE).** It is well defined, but the formula and its heuristic
  status must be in the paper (§3.5). Optional: compare against a softmax (logit) response.

| Source | Comment | Status | Where answered |
|---|---|---|---|
| R5 #1 | Vertex position in the local orbital frame | ✍ writing | §3.3: ê₂–ê₃ (radial/normal) plane, non-orthogonal frame; the paper needs the formula |
| R5 #2 | How the Nash distribution w* is used | ✍ writing | §3.5 strategy table (`mixed` samples w*; `greedy` per G1) |
| R5 #3 | Imperfect MPC tracking — is the mixed strategy meaningful? | ✅ fixed | §5.1: median terminal miss 4.1 cm vs R = 6.378 km (max 2.8e-5·R) |
| R5 #4 | Distance to the original problem; theory needed | ⚠ **G2** | §5.8 proposition + 6/12/24 curve (1.5%); scope note |
| R7 #1 | Tractability: structure of F, convexity, solver, runtime | ✅ fixed | §4.2, §5.6: Kepler two-body + impulsive; nonconvex NLP to local optimality; LBFGS 99.53%, ~16 ms/solve; Ipopt 0/12. Real-time margin (§1) is derived — re-measure. No *guarantee*, only measurement — say so (AE asked for "guarantees") |
| R7 #2 | Payoff convention inconsistent with the LP | ✅ fixed | Defect D1; §3.4–3.5: evader maximizes A, pursuer minimizes; pinned by a test asserting the old pairing is exploitable |
| R7 #3 | How each player's weights are computed | ✅ fixed / ✍ | `sms(−A)` for P1, `sms(Aᵀ)` for P2, saddle-point certificate (§4.3). Write both LPs out |
| R7 #4 | `greedy` = largest Nash weight is not rational | ⚠ **G1** | §3.5 relabelled as a heuristic baseline |
| R7 #5 | `FP_mixed` underdefined; c_exp is not a distribution | ⚠ **G3** | §3.5 formula |
| R7 #6 | "Game value" used ambiguously | ✍ writing | Reserve "value" for the LP value V (§5.8); call the empirical metric "mean separation" |
| R7 m1 | Two stage-cost definitions (Eq. 2 vs 9) | ✍ writing | Fuel term gone (λ₂ = 0), so one definition remains. But the payoff is `λ₁·mean sqrt(d + 0.1)`, not d — use distinct symbols |
| R7 m2 | Belief update reads as applying to all strategies | ✍ writing | State it as FP/learner-only; fix the n vs f notation |
| R7 m3 | Metrics partly overlap | ✍ writing | Now the reverse: ΔV is independent of the payoff (λ₂ = 0), while the payoff is a monotone function of distance. Say both plainly |
| R8 #1 | Write the LPs for both players | ✅ / ✍ | Same as R7 #2–3 |
| R8 #2 | Eq. 7 compares a 6-D state with a 3-D vertex | ✍ writing | §3.3 objective uses the position r(T; x) only |
| R8 #3 | Vertex indexing (j vs l, generic agent i) | ✍ writing | Distinct indices for evader and pursuer targets |
| R8 #4 | Same symbol for beliefs over different action spaces | ✍ writing | Distinct belief symbols per player |
| R8 #5 | "Dominant strategy" misused | ✅ fixed | §5.4 EGTA: nothing is dominant; FP_greedy is in the support on both sides, pure for neither. Keep this sentence even with EGTA demoted |
| R8 #6 | Game-step notation S inconsistent | ✍ writing | |
| R8 #7 | Incomplete references | ✍ writing | |
| AE | LP inconsistency "potentially affecting validity" | ✅ fixed | D1; every CDC number is void and re-measured (§5.6) |
| AE | Use of w*; imperfect tracking; greedy/FP rationale | see R5 #2–3, G1, G3 | |
| AE | Theory linking discrete to continuous | ⚠ **G2** | |
| AE | Tractability claims: solver, runtime, guarantees | ✅ / ✍ | Solver and runtime measured; guarantees not available — state it as a nonconvex local solve |

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

### 5.4 Equilibrium restatement (EGTA) — *secondary for ECC, one sentence in the paper*

The 5×5 tournament as a normal-form meta-game: value 5.1084 km (certificate 9.4e-15). Evader
support: `greedy` 0.830 / `FP_greedy` 0.170. Pursuer support: `mixed` 0.449 / `FP_greedy`
0.551. **Nothing is dominant** — the correct claim (vs CDC Reviewer 8's objection) is support
membership: `FP_greedy` is in the support on both sides and pure for neither. The meta-game
itself says exploitation is worth playing and worth not playing exclusively.

### 5.5 Capture — two-level, decided 2026-09-16

Capture is **post-hoc first passage** of the inter-player separation below a radius — games
are never terminated (termination would censor the separation metrics and break CRN
comparability). Two named thresholds, both measured against the full capture curve before
being chosen:

- **Hard capture, 0.2 km** — the ISS keep-out-sphere radius, the citable proximity-ops "last
  safety barrier," and the smallest radius still statistically resolvable at n=100/cell
  (80 events across the sweep; pooled per-evader Wilson CIs separate `greedy` 1.6% [0.8, 3.1]
  from `FP_greedy` 6.8% [4.9, 9.4]).
- **Soft capture, 1.0 km** — proximity-operations scale, and the most discriminating radius
  on the curve (per-cell rates span 13–100%; 1.5 km saturates). Pooled: `mixed` evader
  soft-captured 86.2% [82.9, 88.9] vs `FP_greedy` 62.6% [58.3, 66.7].

**The `FP_greedy`/`FP_greedy` cell is an extreme hard-capture outlier: 18% vs ≤ 9% in every
other cell** (14% already at 0.15 km; the sweep-wide minimum separation of 9 m is in that
cell). Mutual exploitation doesn't just lose mean separation — it courts hard capture at
~2.5× the rate of any other matchup. That is the sign-reversal headline restated in capture
terms. The other notable cell: `FP_greedy` evader vs `random` pursuer resists soft capture
(13% at 1 km vs 55–100% elsewhere) — an unpredictable opponent defeats the modeling, the
honest counterpoint to the headline.

The full curve (0.1–2 km) is still reported alongside both thresholds: it is steepest in
0.5–1.0 km, and showing it is the honest answer to "why these radii." Minimum separations
run 9 m–229 m; sampling resolution is one segment boundary (~117 s), stated with the metric.

### 5.6 Solver characterization (what CDC asked for)

99.53% trajectory-solver convergence over 15,000 solves; 0/2,500 LP certificate failures;
`mixed`/`mixed` NashConv of *played* strategies median 1.6e-14 — the equilibrium machinery is
correct end to end. Every CDC-era number is void (D1 alone made 53% of its LP solves
non-equilibria); no reconciliation is attempted.

### 5.7 The exploitation ceiling — both ends of the tradeoff (B6)

An **oracle best-response** pursuer is told the evader's true decision rule and best-responds
exactly (it knows a randomizer's *distribution*, never its realization — informed, not
clairvoyant). It is not a realistic player; it is a **ceiling** on how much any pursuer could
extract. Run against fixed-vertex evaders — the most exploitable opponent that exists — it
brackets the whole tradeoff:

**Against a predictable opponent, modeling ≈ omniscience, and safety costs everything.**
The Nash pursuer gives up **+3.16 to +3.31 km** versus the oracle (t = 94–110, paired) —
about 130% of the oracle's own value. In capture terms: the oracle and `FP_greedy` both
hard-capture **100%** of fixed-vertex evaders; Nash hard-captures **0–9%**. And `FP_greedy`
recovers **97.5–99.4%** of the available exploitation, converging fast — it plays the
oracle's exact move 75% of the time in steps 1–5 and **100% from step 6 onward**. The gap
between learning an opponent from observation and being handed the answer is 20–83 metres.

**Against a properly randomizing opponent, omniscience is worth less than nothing.** Versus a
`mixed` evader the contrast **reverses**: −0.117 ± 0.060 km (t = −3.82). The oracle does
*worse* than Nash, and `FP_greedy` beats both. Knowing the true distribution buys nothing
when there is nothing to exploit, and committing to a myopic best response to it actively
hurts over 30 steps. This is the security strategy doing exactly its job — and it is the same
sign reversal as §5.3, arriving independently at the opposite extreme of the opponent space.

**Method caveat, stated plainly:** the oracle is a **greedy best response to the opponent's
true per-step distribution**, not a 30-step optimum. A dynamic-programming pursuer could
sacrifice now to set up a better capture later, so the price of safety above is a *lower
bound*. Never describe it as "the optimal pursuer."

### 5.8 The lifting is faithful *and* nearly converged at six vertices (C4 + C5)

§5.1 established that candidate trajectories reach their vertices (median miss 4.1 cm against
R = 6.378 km), so the finite action set is real. C4/C5 answer the harder question: is the
*hexagon* — six vertices specifically — enough?

**The proposition (C5).** Restricting a maximizer's action set can only lower the value of a
zero-sum game, and restricting a minimizer's can only raise it, so each lifting is a bound on
the continuous game in a known direction. Quantitatively, if the stage cost is Lipschitz with
constant `L` over the reachable set and the vertex set is an `h_M`-net of the polygon's
circumcircle, then

    |V_M − V_cont| ≤ L · h_M,       h_M = 2R·sin(π/2M)

`h_M` halves each time `M` doubles: 3.30 km at M = 6, 1.67 at 12, 0.83 at 24.

**Scope of the bound — state it exactly, or a theory reviewer will.** `V_cont` here is the
value of a *stage* game whose targets may lie anywhere on the polygon's circumcircle. It is
**not** the original continuous-control game: that game ranges over the whole reachable set,
not a circle, and is played over 30 receding-horizon steps, not one stage. So the proposition
bounds the gap between the lifted game and the circle game, one step at a time. It says
nothing about the closed loop. Closing that gap would need (a) an h-net of the reachable set
instead of the circle, and (b) a statement of what carries across steps. Neither is done.
This is the main open theory item behind CDC R5 #4 and the AE's request for "theoretical
analysis connecting the discrete approximation to the original continuous control problem".

**The measurement (C4).** The per-step LP value of the lifted stage game, 100 trials × 30
steps per arity, under common random numbers so the arities are *paired*:

| M | h_M [km] | V_M [km] | distance to extrapolated V_cont |
|---|---|---|---|
| 6 | 3.302 | 2.1057 ± 0.0263 | 0.0315 km (**1.5%**) |
| 12 | 1.665 | 2.0869 ± 0.0264 | 0.0127 km (0.6%) |
| 24 | 0.834 | 2.0806 ± 0.0263 | 0.0063 km (0.3%) |

Successive differences shrink by a factor of **0.34** per doubling — *faster* than the 0.50
the `O(h_M)` bound predicts, so the bound holds with room to spare. Richardson extrapolation
on the model `V_M = V_cont + C·h_M` gives **V_cont ≈ 2.074 km** and an empirical Lipschitz
constant of **L ≈ 0.008 km per km** of covering radius.

**The claim this licenses.** The hexagon is not an arbitrary discretization: quadrupling the
action set moves the game's value by 1.2%, and the six-vertex value is already within ~1.5%
of the extrapolated continuum. The safety claim of §5.2–5.3 is therefore about a game that
differs from the continuous one by about a percent in value — which is the answer to
Reviewer 5 #4, and it is a measurement rather than an assertion.

**A directional detail worth one sentence.** V *decreases* with refinement. Both players gain
actions simultaneously, so the monotonicity argument does not fix the sign a priori; observing
V₂₄ < V₁₂ < V₆ says the **pursuer gains slightly more from a finer action set than the evader
does**. Small (1.2% total) but consistent across all three arities.

**And the headline is not a coarse-lattice artifact — it strengthens under refinement:**

| M | `FP_greedy` edge over the Nash evader |
|---|---|
| 6 | +0.735 ± 0.083 km (t = 17.3) |
| 12 | +0.858 ± 0.084 (t = 20.1) |
| 24 | +0.931 ± 0.070 (t = 25.9) |

A finer action set gives a predictable opponent more ways to be exploited and the learner more
to learn, so online opponent modeling gains 27% more from M = 6 to M = 24. Pre-empts the
obvious reviewer question with data in the right direction. (LP certificates stay at 1.7e-12
even on the 24×24 games, so none of this is solver drift.)

### 5.9 What makes fictitious play work here — and what does not (C1, C2, C3)

Three Gate C results sharpen the method section, and the first is a correction to an
assumption the paper would otherwise have made silently.

**FP does not track the equilibrium (C3).** The stage game moves fast: the payoff matrix
changes 18.5% of its norm per step, and the equilibrium *mixture* moves 1.359 in L1 per step
out of a maximum 2.0, with the modal vertex changing **82% of the time**. The mechanism is
measured, not speculated: equilibrium support is broad (median 4 of 6, never pure) and the
supported vertices are exactly indifferent (median best-vs-second gap 0.00%), so the mixture
is weakly determined and small perturbations reshuffle it while the *value* barely moves
(0.131 km/step). Realized FP-vs-FP play sits at ~0.25 km exploitability, **flat across all 30
steps** — it never converges on the equilibrium.

So the assumption that licenses pooling beliefs across steps is **not** "the stage equilibrium
is stable" — that is measured false. It is the weaker and more defensible **"the opponent's
decision rule is stable."** B6 corroborates from the other side: FP's edge is maximal against
a fixed-vertex opponent (a perfectly stable rule) and reverses against another exploiter (no
stable rule). On a frozen matrix — Robinson's actual setting — FP does converge to the LP
equilibrium, and on **every** sampled matrix, not just typically. Over 200 real payoff matrices,
NashConv after 10 → 10,000 iterations goes:

| | 10 | 100 | 1,000 | 10,000 | rate |
|---|---|---|---|---|---|
| median | 1.64e-1 | 4.26e-2 | 1.17e-2 | 3.70e-3 | `T^-0.55` |
| p90 | 1.88e-1 | 6.79e-2 | 2.31e-2 | 8.17e-3 | `T^-0.45` |
| max | 2.22e-1 | 1.02e-1 | 3.40e-2 | 1.16e-2 | `T^-0.43` |

The median is essentially the textbook rate; the tail is slower but monotone, with the worst
matrix at 1.2e-2 km after 10,000 iterations. That is the only regime where we invoke the
theorem. (Table from the 2026-10-17 local regeneration — LOG; the original 32-core run gave a
median of 3.37e-3 and `T^-0.56`.)

**Discounting needs systematic drift, not mere movement (C1).** Recency-weighted FP
(`f_s = γ·f_{s-1} + g_{s-1}`) was expected to help because uniform pooling averages across
different games. It does — but only under a sharper condition than "the opponent moves":

| evader `FP_greedy` vs | γ=1.0 | γ=0.9 | γ=0.8 | γ=0.5 |
|---|---|---|---|---|
| `mixed` (unpredictable churn) | 5.716 | 5.739 | 5.691 | 5.686 — **all null** |
| `FP_greedy` (systematic drift) | 4.614 | 4.939* | 5.319* | **6.007*** |

Against `mixed`, whose mixture churns hard but *unpredictably*, discounting buys nothing at
any γ. Against `FP_greedy`, whose distribution drifts systematically as its own beliefs
accumulate, the gain is large and monotone in memory length. **The operative condition is
predictable drift.** (The `FP_greedy` column discounts both players, so it measures mutual
memory; the one-sided decomposition is a separate run.)

A deliberate falsification check — γ against a *fixed-vertex* evader, where nothing should be
learnable — returned a small but significant effect (−0.019 km at γ=0.5, t = −4.30) and the
investigation improved the claim. Discounting decays the `ones(n)` **uniform prior** far
faster (belief mass on the true vertex reaches 1.000 by step 11 at γ=0.5, versus 0.824 after
30 steps at γ=1), but from step 4 onward every γ plays *identically*, because the best
response depends on which vertex holds plurality rather than how much. The entire 0.7% effect
lives in steps 1–3. So the honest statement is that discounting helps when there is genuinely
stale information — **a systematically drifting opponent, or the initial prior** — and the
prior is a modelling choice that interacts with γ.

**A no-regret learner is competitive, not dominant (C2).** Regret matching (parameter-free)
and Hedge, as evaders:

| evader | vs `mixed` | vs `FP_greedy` | vs `oracle` (best-responder) |
|---|---|---|---|
| `mixed` | 4.981 | 4.868 | **5.098** |
| `regret_matching` | 5.402 | 4.731 | 4.575 |
| `hedge` | 4.923 | 4.622 | 4.504 |

Neither beats `FP_greedy` overall (−0.314 and −0.793 against a `mixed` pursuer; +0.118 and
+0.009 against an FP pursuer). The interesting column is the last one: **against a
best-responding opponent the stage-game security strategy beats both learners.** That is the
no-regret guarantee's scope made concrete — it bounds the *time-average*, while minimax bounds
*each step*, and an opponent that best-responds to the learner's current mixture exploits
precisely that gap. Given C3's finding that the equilibrium reshuffles 82% of steps, the
time-average is not the object that matters here, which is why the standard no-regret
baseline does not win.

*Caveat to state explicitly:* regret matching is parameter-free, so its result is
unconditional; Hedge's depends on a learning rate, and η is swept rather than assumed.

### 5.10 Negative results kept deliberately

- The vertex-geometry "confound" was claimed at n=2, failed to replicate at n=6, and B6 now
  resolves it at n=100 — in a way that corrects the retraction too. On **whole-game mean**
  the six vertices are statistically indistinguishable under the oracle (3.3% spread, CIs
  covering the full range), so note [f]'s surviving claim that "~25% spread means which
  vertex you play matters" was *itself* six-seed noise. But on **late-game** separation a
  clean split appears, with non-overlapping CIs: out-of-plane vertices (0.038, 0.046 km) are
  **~2.9× more exploitable** than in-plane ones (0.109–0.129 km). Under a Nash pursuer that
  same comparison is noise. **The in-plane/out-of-plane effect is real but only visible
  against an opponent that actually exploits** — which is exactly why the original
  Nash-based design produced an unstable ranking. Caveat: all these values sit below the
  0.2 km hard-capture radius, so geometry sets how deeply inside capture the evader ends
  up, not whether it escapes.
- Ipopt fails on the trajectory NLP (0% convergence) — reported as a comparison, which
  answers the solver question better than either result alone.
- The ΔV cap never binds at this scenario scale; the fuel term contributes 0% of the payoff
  variation. Both stated rather than tuned.

## 6. Open items and schedule

| When | What | |
|---|---|---|
| ~~Aug 31~~ | Gate A — A1–A6 | ✅ done |
| ~~Sep 1–16~~ | Gate B — B1–B6 (B3 capture radius and B6 oracle both closed Sep 16) | ✅ done, **narrative locked** |
| ~~Sep 17 – 20~~ | Gate C — C1–C5 (§4.6) | ✅ done Sep 17 |
| ~~Oct 1 / Oct 8~~ | ~~AAMAS 2027 abstract / paper~~ — venue dropped 2026-10-16 | |
| **Oct 16 – 31** | **Gate D — writing support for ECC 2027** (W1–W6, §4.7) | ⬜ **current** |
| **Oct 31** | **ECC 2027 paper deadline** (PaperCept) | |
| Mar 5 2027 | Notification | |
| Apr 5 2027 | Final manuscript, ≤ 6 pages (+2 paid) | |

No new experiments are planned. All numbers are venue-independent, and Gates A–C are complete.
The binding constraint is the **6-page budget**, not compute.

**What to cut from the paper if pages run out:** `Meta_*` → C1 discounting → C2 no-regret →
EGTA → the 24-vertex row (keep 6/12 and the extrapolation). **Never cut:** the sign
convention, the lifting bound and its convergence curve, solver reliability and timing,
randomized ICs with CIs, capture rates, the price of safety. Together these make the
controls claims provable rather than asserted.

## 7. Reproduction

```bash
julia -t 32 --project=.                       # threads default to 1 — always pass -t
julia -t 32 --project=. test/run_gate_b.jl    # full 5×5 × 100 × 30 CRN sweep, ~106 min
julia -t 8  --project=. test/analyze_gate_b.jl
julia -t 32 --project=. -e 'using Pkg; Pkg.test()'   # ~3,135 assertions
```

Run from the repo root (paths are relative). Results land in `test/results/n30/`
(slim format, ~33 MB/file, ~805 MB/sweep).
