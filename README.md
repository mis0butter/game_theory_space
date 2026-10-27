# Online Opponent Exploitation in Orbital Pursuit-Evasion Games

Two spacecraft play pursuit-evasion in low Earth orbit. Each game step, both players choose
among six candidate trajectories (one per vertex of a hexagon ahead on the evader's orbit),
the 6×6 zero-sum matrix game is solved by LP, and play continues in receding horizon. We ask
what a player gains by **learning its specific opponent online** (fictitious play, or
type-based reasoning over a library of opponent rules) instead of playing the safe minimax
strategy — and what it gives up in safety.

**Target: ECC 2027**, paper due **Oct 31 2026** via PaperCept. Review copy ≤ 8 pages, final
≤ 6 (+2 paid); ieeeconf, US Letter, PDF ≤ 3 MB. Notification Mar 5, final Apr 5 2027.
([CFP](https://ecc27.euca-ecc.org/call-for-papers/)) The live paper is in **Overleaf**; the copy
in `Game_Theory_Space_ECC_2027/` lags behind it.
A CDC 2026 version was rejected; its reviews are in `Game_Theory_Space_ECC_2027/reviews/`.

Every number below has its interval and run details in `LOG.md`. The full method and results
write-up is archived in `docs/README_narrative_2026-10-18.md`.

## The story, for a controls audience

A **game-theoretic receding-horizon guidance law**, with three contributions:

1. **The finite approximation is faithful, with a bound.** Shrinking an action set moves the
   game value in a known direction, and `|V_M − V_C| ≤ ℓ·h_M` (Proposition 1, on the circle C). Measured, the six-vertex
   value is within ~1.5% of the extrapolated continuous value.
2. **It solves reliably and fast.** The nonconvex trajectory NLP is solved locally by LBFGS,
   and each LP is checked by a solver-independent certificate.
3. **Safety vs. adaptation, quantified.** Fictitious play beats minimax against most opponents,
   loses against another learner, and the price of safety is large against a predictable one.
   Type-based reasoning, whose library includes an FP learner, exploits that learner: it is the
   strongest pursuer, and as evader it avoids close passes.

## Key results (100 trials × 30 steps, common random numbers, 95% CIs)

| Result | Number | LOG |
|---|---|---|
| Candidates reach their vertices | median miss 4.6e-12 km, max 1.8e-7 km vs a 6.378 km hexagon | 10-19 (32-core) |
| Trajectory solver reliability (LBFGS) | 2,484,000 solves, 2 hit the iteration cap (both already at their vertex, miss ~1e-12 km); Ipopt 0/60 | 10-20 (32-core) |
| LP correctness | 0 / 207,000 certificate failures (max 1.8e-12) | 10-20 (32-core) |
| Real-time margin | 0.16 s median compute per step (one core) vs 583 s executed (≥ 870×) | 10-19 (32-core) |
| FP_greedy is the best evader and best pursuer (of the 5 tournament strategies) | 6.07 ± 0.15 / 4.82 ± 0.06 km | 09-02 |
| FP_greedy − mixed (evader), vs a mixed pursuer | **+0.735 ± 0.083 km** | 09-02 |
| … vs an FP_greedy pursuer | **−0.254 ± 0.051 km** — the sign reverses | 09-02 |
| Nothing is dominant (meta-game) | FP_greedy in the support on both sides, pure on neither | 09-02 |
| Capture (hard 0.2 km / soft 1.0 km) | FP vs FP hard-capture 18% [11.7, 26.7] vs 2.6% [2.0, 3.3] pooled elsewhere | 10-19 |
| Price of safety vs a fixed-vertex evader | +3.16–3.31 km; oracle and FP capture 100%, Nash 0–9% | 09-16 |
| FP vs the omniscient oracle | FP recovers 97.5–99.4% of the available exploitation | 09-16 |
| Six vertices vs the continuum | 1.5% [0.9, 2.1] from extrapolated value; V₆ − V₂₄ = 0.025 ± 0.008 √km; FP edge grows to +0.931 at 24 vertices | 09-17, 10-19 |
| FP on a frozen matrix | converges on all 3,000 real matrices (median T^-0.57, worst T^-0.43; max 1.5e-2 at T = 10⁴) | 10-19 (32-core) |
| FP in the real (moving) game | does not converge on the equilibrium; it tracks a stable opponent *rule* | 09-17 |
| Discounted FP, no-regret learners | secondary: one sentence each in the paper | 09-17 |
| Type-based is the strongest pursuer | column mean 3.84 km (FP 4.82, minimax 5.21); vs an FP evader −3.044 ± 0.073 km, 100% hard capture | 10-20 |
| Type-based evader avoids capture | ties FP on separation (6.08 vs 6.07); soft capture vs an FP pursuer 9% [5, 16] vs minimax's 91% | 10-20 |
| Type-based vs fixed-vertex evaders | recovers 97.9–99.4% of the oracle's advantage | 10-20 |

## Status

| Gate | What | Status |
|---|---|---|
| A | Correctness: LP sign bug (D1), stage cost, trajectory solver, AD path | ✅ Aug 31 |
| B | Honest re-run: dispersed ICs, intervals, meta-game, capture, oracle | ✅ Sep 16 |
| C | Contribution: discounted FP, no-regret, convergence check, vertex ablation, lifting bound | ✅ Sep 17 |
| — | Type-based reasoning (Meta sweep, 18 cells) | ✅ Oct 20 |
| D | Write the ECC paper | 🟡 drafted; author finishing in Overleaf, due Oct 31 |

## Paper to-do

The author is editing in **Overleaf**; the repo `MAIN_PAPER.tex` lags behind it, so the ✅
marks below describe the repo copy as of 10-20.

**1. ✅ Remove what is no longer true** (done 2026-10-18; red TODOs mark the gaps). Abstract numbers; Tables I–III and all three results
figures; the setup paragraph (OSQP, 1e-4 floor, λ₂ = 0.1, identical orbits); "dominant";
the fuel-efficiency claims; "FP ensures convergence" in related work.

**2. ✅ Fix the methods section (CDC review items)** (done 2026-10-18; G1 and G3 closed in the text).

| Where | Fix | Review |
|---|---|---|
| Eq. 10 (LP) | Write both players' LPs in the correct sign convention | R7 #2–3, R8 #1, AE |
| Eq. 7 | Compare position (3-D) with the vertex, not the 6-D state | R8 #2 |
| `A_jl` indexing | Separate evader / pursuer vertex indices | R8 #3 |
| Eq. 9 | λ₂ = 0; the 0.1 is the smoothing term and λ₁ a weight; payoff ≠ distance | R7 m1 |
| Frame bullets | The real frame is not orthonormal; give the actual construction | R5 #1 |
| Belief update | Fix `n`/`f` and `q̂_i = f_j`; separate symbols per player; FP-only | R7 m2, R8 #4 |
| Strategy list | **G1:** `greedy` is a heuristic baseline. **G3:** give `FP_mixed`'s formula | R7 #4–5, AE |
| MPC problem | State what is actually solved (exact-penalty LBFGS, cap never binds); drop the red 𝓕 / 𝓑 / Sims-Flanagan text | R7 #1 |
| Throughout | "Game value" means only the LP value; one game-step symbol | R7 #6, R8 #6 |

**3. ✅ Add the new ECC content** (drafted 2026-10-19; 32-core numbers swapped in; one red marker remains: the ISS keep-out citation). A lifting-bound section with **G2**, the bound's scope: it
covers the circle stage game, not the continuous closed loop. A solver paragraph, with the
real-time margin re-measured. Capture definitions and rates. Price of safety. The
sign-reversal table with intervals.

**3b. ✅ Type-based reasoning** (10-20): methods section, Table `tab:types`, abstract, intro,
related work and limitations.

**4. ✅ Figures and tables.** `test/figures_paper.jl` makes six PDFs in
`Game_Theory_Space_ECC_2027/images/fig_*.pdf`; all six are in the `.tex` (10-20).

**5. Fit the page limit.** ~7,400 words with six figures, well over 6 pages. Cut figures and
text once the page count is known. The ΔV sentence needs intervals or softening.

**6. Submission checks.** The ISS 200 m keep-out citation (last red marker); page count (LaTeX
is not installed here); the affiliation footnote lists ² but no author has it; two incomplete
bib entries (`albrechtReasoningHypotheticalAgent`: no venue or year; `sims1997preliminary`: no
venue); AI-use disclosure policy; ≤ 3 MB; blind or not.

## Reproduction

```bash
julia -t 32 --project=.                              # threads default to 1 — always pass -t
julia -t 32 --project=. test/run_gate_b.jl           # 5×5 × 100 × 30 sweep, ~106 min
julia -t 8  --project=. test/analyze_gate_b.jl
julia -t 32 --project=. -e 'using Pkg; Pkg.test()'   # 3,369 assertions
```

Run from the repo root (paths are relative). Results go to `test/results/` (gitignored).
