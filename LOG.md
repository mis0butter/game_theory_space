# LOG — decision record

Append-only, newest first. Corrections are new entries; nothing gets edited. At milestones,
old entries roll up into a dated paragraph at the bottom. Each block: what ran (with run
identifier), what was decided, what was measured, what is predicted for the next run.

---

## 2026-09-17 — C1 (asymmetric): the discounting gain is mostly the PURSUER hurting itself

**Run:** `test/run_c1_asym.jl` — per-player γ, both one-sided directions, 3 γ × 2 directions ×
100 trials, CRN against the Gate B `FP_greedy`/`FP_greedy` baseline (4.614 km).

**Prediction check.** I predicted the symmetric FP/FP gain would "survive one-sidedly" because
an `FP_greedy` opponent drifts systematically. It survives — but at a quarter of the size, and
the decomposition says something I did not anticipate.

| γ | symmetric Δ (both) | evader-only Δ | pursuer-only Δ | sum | interaction |
|---|---|---|---|---|---|
| 0.5 | +1.393* | +0.353* | **+0.944*** | 1.297 | +0.10 |
| 0.8 | +0.705* | +0.154* | **+0.713*** | 0.867 | −0.16 |
| 0.9 | +0.325* | +0.070* | **+0.324*** | 0.395 | −0.07 |

**The effects are essentially additive** (interaction ≈ ±0.1 against main effects up to 1.4),
and **the pursuer-only term is positive** — separation *rises* when the pursuer discounts, and
the pursuer wants it low. So discounting **hurts the pursuer**, by ~2.7× more than it helps
the evader. The symmetric +1.393 km decomposes as **68% pursuer self-harm, 25% evader gain**.

**This changes how C1 must be reported.** "Discounted FP gains 1.4 km" would be wrong by 4× as
a claim about adopting discounting. The correct statement is **+0.35 km if you discount and
your opponent does not; +1.39 km if you both do** — and the difference is not an interaction
but the opponent damaging itself.

**Mechanism — partially confirmed, reported as such.** Hypothesis: discounting shrinks the
effective sample size (30 → ~2 steps at γ=0.5), raising dispersion, which is protective for an
evader and costly for a pursuer. Measured on realized play:

- *Evader side, supported.* A discounting evader's switch rate between consecutive vertices
  goes **78% → 96%** at γ=0.5, with entropy already pinned near the 6-vertex max (1.75 → 1.76
  of 1.79). It stops persisting on any vertex — harder to predict.
- *Pursuer side, not as stated.* Entropy rises (1.578 → 1.675) but the switch rate does not
  (62% → 56% → 62%, non-monotone). "More erratic" is not the right description.
- *Unpredicted.* When the pursuer discounts, the **evader settles**: entropy 1.746 → 1.647,
  switch rate 78% → 62%. A less focused pursuer hands its opponent a stable target.

So the supported statement is about **dispersion, not noise**: discounting raises the
discounting player's own dispersion, which protects an evader and costs a pursuer — both by
pursuing less effectively and by letting the opponent settle. Enough to explain both signs and
the additivity; not a clean one-line mechanism, and should not be written as one.

---

## 2026-09-17 — C1 (symmetric grid): discounting needs *systematic* drift, and the
## falsification check caught something real

**Run:** `test/run_c1c2.jl`, cells 1–9 of 15 (γ × opponent, plus the falsification row).
Analysis `test/analyze_c1c2.jl`. CRN with Gate B throughout, so every Δ below is paired.

**Prediction check — my mid-flight refinement was WRONG and the original was right.**
Yesterday I logged that discounting should help whenever the opponent's realized
*distribution* drifts, and specifically that it should therefore help against `mixed`
(whose Nash mixture reshuffles 1.36 in L1 per step). Measured against `mixed`, where γ
touches only the evader and the test is cleanly one-sided:

| γ | 1.0 | 0.5 | 0.8 | 0.9 |
|---|---|---|---|---|
| separation | 5.716 | 5.686 | 5.691 | 5.739 |
| paired Δ | — | −0.030 | −0.025 | +0.022 |

**All null.** The correct condition is **systematic drift**, not mere movement. The stage
equilibrium's churn is large but evidently unpredictable, so forgetting old samples discards
information without buying any tracking ability.

**Against `FP_greedy`, monotone and large — but confounded.** 4.614 → 4.939 (γ=0.9) → 5.319
(0.8) → **6.007 (0.5)**, all significant, perfectly monotone in memory length (30 → 10 → 5 →
2 steps). The FP/FP cell is the worst in the Gate B matrix, and shortening memory relieves it
by 30%. **But γ was global, so both players discount** — this is a symmetric perturbation and
says nothing about whether forgetting helps the player adopting it. Per-player γ (`γ_fp_p2`)
was added for exactly this; `test/run_c1_asym.jl` runs both one-sided directions.

**THE FALSIFICATION CHECK FIRED, and investigating it was worth more than the result.**
Against a fixed-vertex evader — a constant point mass, nothing to track — γ=0.5 measured
Δ = −0.019 ± 0.009 km, t = −4.30. Predicted null. Direction: the *discounting pursuer does
better*. Mechanism, measured directly rather than rationalized:

| γ | belief mass on the true vertex, steps 1-3 → 16-30 | plays the oracle move, steps 1-3 → 4+ |
|---|---|---|
| 1.0 | 0.368 → 0.824 | 45% → **100%** |
| 0.5 | 0.569 → **1.000** | 48% → 100% |

Discounting decays the **`ones(n)` uniform prior** far faster — γ=0.5 is fully confident by
step 11 while plain FP is still at 0.82 after 30 steps. But **from step 4 on every γ plays
identically**, because the best response depends on which vertex holds plurality, not on how
much mass it holds. The whole effect lives in steps 1–3 (48% vs 45% oracle agreement); the
game is a dynamical system, so those few early divergences persist into the separation metric.
Effect size **0.7%**, against 30% in the FP/FP cell — two mechanisms separated by an order of
magnitude and a half.

**So the prediction was imprecise, not wrong.** "Nothing to forget" ignored that the uniform
prior is itself stale information. The sharp statement: **discounting helps when there is
genuinely stale information — a systematically drifting opponent, or the initial prior.**
Against `mixed` even the prior-decay effect is null, because there is no single true vertex to
lock onto, so escaping the prior faster buys no better move. The `ones(n)` prior is a modelling
choice that interacts with γ and deserves a sentence in the paper rather than silence.

**Predicted (for the asymmetric run):** the FP/FP gain should survive one-sidedly — an
`FP_greedy` opponent drifts *systematically* as its beliefs accumulate, which is the condition
the `mixed` column showed is required. If the one-sided effect is null while the symmetric one
was +1.393 km, then the symmetric result is about mutual lock-in only, and C1's headline
becomes "discounting is not individually rational here" — a different and more interesting
claim than the plan anticipated.

---

## 2026-09-17 — C4 + C5 complete: the hexagon is already within ~1.5% of the continuum

**Run:** `test/run_c4.jl` — arities 12 and 24 × {`mixed`/`mixed`, `FP_greedy`/`mixed`} × 100
trials × 30 steps, **63.3 min** on 32 threads, CRN with every other sweep. n=6 was **not**
re-run: its code path is bitwise-preserved, so re-running would have produced identical files
at full cost. Analysis `test/analyze_c4.jl`.

**Code: the four hardcoded arity-6 sites are generalized** (one — the cost-matrix allocation
— was already derived). Two decisions worth keeping:

- **n=6 keeps the original arithmetic verbatim.** The natural general formula (vertex k at
  angle 360°k/n) is *not* bitwise identical at n=6, because `cosd(120)` is not bitwise
  `-cosd(60)`; positions move ~2e-12 km. Physically nothing, but exact reproduction is a
  verification tool this project actively uses (it is what proved B6's overwrite of the Gate B
  cells was schema-only). So only n ≠ 6 takes the general path, and a test asserts the two are
  *not* bitwise equal while agreeing to <1e-9, so nobody "simplifies" the duplication away.
- **Two data-loss landmines found and fixed, same root cause.** `results_folder` keyed only on
  game *steps* and strategies, so (a) a 12-vertex run would have overwritten the 6-vertex Gate
  B cells, and (b) the three γ values of the C1 sweep would have overwritten each other **and**
  Gate B's `FP_greedy` cells. Every swept knob (arity, γ, η) now appears in the path, at
  non-default values only, so all pre-Gate-C paths stay valid. Pinned by a testset asserting
  all combinations are distinct and defaults map to the historical path.

**C4 — the convergence curve.** Per-step LP value of the lifted stage game, paired across
arities:

| M | h_M = 2R·sin(π/2M) | V_M [km] | to extrapolated V_cont |
|---|---|---|---|
| 6 | 3.302 km | 2.1057 ± 0.0263 | 0.0315 km (**1.5%**) |
| 12 | 1.665 | 2.0869 ± 0.0264 | 0.0127 (0.6%) |
| 24 | 0.834 | 2.0806 ± 0.0263 | 0.0063 (0.3%) |

Successive differences shrink by **0.34** per doubling — *faster* than the 0.50 that `O(h_M)`
predicts, so C5's bound holds with room to spare. Richardson on `V_M = V_cont + C·h_M` gives
**V_cont ≈ 2.0742 km** and **L ≈ 0.0076 km per km** of covering radius.

**C5 — what this licenses.** The hexagon is not an arbitrary discretization: quadrupling the
action set moves the value 1.2%, and M=6 is already within ~1.5% of the extrapolated
continuum. The safety claim is about a game that differs from the continuous one by about a
percent in value. That is the answer to Reviewer 5 #4, as a measurement.

**Directional detail.** V *decreases* with refinement (V₂₄ < V₁₂ < V₆). Both players gain
actions at once, so monotonicity does not fix the sign a priori — observing a decrease says
the **pursuer gains slightly more from a finer action set than the evader does**. Small but
consistent across all three arities.

**The headline strengthens under refinement** — `FP_greedy`'s edge over the Nash evader:
+0.735 ± 0.083 (M=6) → +0.858 ± 0.084 (12) → **+0.931 ± 0.070, t = 25.9** (24). So "FP's
advantage is an artifact of a coarse action set" is answered with data pointing the other way:
a finer set gives a predictable opponent more ways to be exploited and the learner more to
learn. LP certificates hold at 1.7e-12 even on 24×24 games, so none of this is solver drift.

**Cross-validation.** The M=6 row reproduces Gate B's headline exactly (+0.735 ± 0.083,
t = +17.33) and its `mixed`/`mixed` separation (4.98), confirming `analyze_c4.jl` and
`analyze_gate_b.jl` compute the same quantities by independent code paths.

**Also landed: C1 and C2 implementations** (sweeps running). C1 is recency-weighted FP,
`f_s = γ·f_{s-1} + g_{s-1}`, γ=1 short-circuiting so plain FP is bitwise untouched — verified
over a full game and pinned against the exact geometric closed form. C2 is `regret_matching`
(parameter-free) and `hedge`, using the `learner_state` field pulled forward in Gate A; they
sample from their mixture rather than taking an argmax (the guarantee is about the played
distribution), the oracle can best-respond to them (a learner's mixture is knowable, so it is
the `mixed` case), and the testset checks the actual guarantee — max regret / T decaying to
0.0087 and 0.0078 by T = 10,000 — plus **inertness**: no `learner_state` is created for any
Gate A/B strategy, so `update_learners!` provably cannot perturb an existing number.

Suite now **3,369 passing**.

---

## 2026-09-17 — C3 complete: FP does not track the equilibrium, and that is the finding

**Run:** `test/analyze_c3.jl` — no new sweep, entirely on Gate B's `mixed`/`mixed` and
`FP_greedy`/`FP_greedy` cells (3,000 payoff matrices). Plus a support-structure probe.

**C3.1 — frozen matrix (Robinson's setting), on real payoff matrices rather than random
ones.** FP's empirical play converges to the LP equilibrium: NashConv falls 1.64e-1 → 3.37e-3
over 10 → 10,000 iterations, an empirical rate of **T^-0.56** — essentially the textbook
O(T^-1/2). FP converging to the LP's own answer validates both implementations jointly. This
is the *only* regime where the classical theorem applies, and it is the only place we claim it.

**C3.2 — the variation budget, and the number that reframes the paper.** Per step:

| quantity | median | p90 |
|---|---|---|
| ‖A_{k+1} − A_k‖_F, as a fraction of ‖A_k‖ | **18.5%** | 28.7% |
| \|V_{k+1} − V_k\| (game value) | 0.131 km | 0.547 |
| **‖p*_{k+1} − p*_k‖₁ (equilibrium mix)** | **1.359** | 1.975 |

L1 distance between probability vectors maxes out at 2.0. **The stage equilibrium reshuffles
almost completely every step** while its *value* barely moves. The mechanism, measured
directly: equilibrium support is broad (median **4 of 6**, never pure), and the supported
vertices are **exactly indifferent** (best-vs-2nd-best gap against the equilibrium mix:
median 0.00% — the defining property of a mixed equilibrium). A weakly-determined mixture
plus an 18%-per-step matrix perturbation gives an **82% chance the modal vertex changes
between consecutive steps**, with the value pinned.

**C3.3 — tracking, not convergence.** Realized empirical play in `FP_greedy`/`FP_greedy` sits
at a NashConv of ~0.25 km (≈5% of the ~4.5 km payoff scale) that is **flat across all 30
steps** — 2.63e-1 in steps 1–5, 2.24e-1 in steps 26–30. It does not converge; it holds a
roughly constant gap, exactly as a moving target predicts. The stage equilibrium itself sits
at 1.1e-14, i.e. the LP's own residual.

**THE REFRAMING, and it is the honest one.** Taken together these say **FP's empirical
success is not explained by equilibrium tracking.** The target moves almost completely each
step, and empirical play never closes on it. So the assumption that licenses cross-step belief
pooling is *not* "the stage equilibrium is stable" — that is now measured false. It is the
much weaker and more defensible **"the opponent's decision rule is stable across steps."**
B6 corroborates from the other side: FP's edge is maximal against a fixed-vertex opponent
(a perfectly stable rule) and **reverses** against another exploiter (no stable rule). C3
supplies the mechanism for the result B6 measured.

This is what §3.6 / C3's "state the assumption explicitly" requirement was asking for, and the
answer turned out to be more interesting than restating it — the obvious assumption is false,
and the method does not need it.

**Also worth one line in the paper:** the ~0.25 km exploitability of realized FP play is
*larger* than the 2.37% median decision margin between the best and second-best vertex. FP is
exploitable by more than a typical vertex gap — which is precisely why `FP_greedy` loses to
another `FP_greedy` (the §5.3 sign reversal) rather than something exotic.

**Prediction refined 2026-09-17, before the C1 sweep returned.** The original wording said
discounting should help against opponents whose *rule* drifts. That is the wrong condition —
the right one is whether the opponent's **realized action distribution** drifts, which cuts
across the strategy names. A `mixed` opponent has a perfectly stationary *rule* ("play the
stage Nash mixture") but, by C3.2's own measurement, a distribution that reshuffles by 1.36 in
L1 per step. So γ < 1 should help against `mixed` too, not only against `FP_*`. The
falsification check is unchanged and is the sharper statement of it: against a **fixed-vertex**
opponent the realized distribution is a constant point mass, so discounting must do nothing.

**Predicted (for C2's no-regret learner):** given the equilibrium reshuffles 82% of steps,
regret matching / Hedge should NOT beat FP by tracking the equilibrium better — its uniform
O(1/√T) bound is about the *time-average*, which is the wrong object here. Expect it to be
competitive-but-not-dominant in mean separation, and to differ most in *worst-case*
exploitability rather than mean outcome. If it wins big on mean separation, suspect an
implementation advantage rather than a theoretical one.

---

## 2026-09-16 — B6 complete: the exploitation ceiling, and where it stops applying

**Run:** `test/run_b6.jl` — 7 evaders (vertices 1–6 + `mixed` reference) × 3 pursuers
(`oracle`, `FP_greedy`, `mixed`) × 100 trials × 30 steps = 2,100 games, **83.8 min** on 32
threads, CRN verified. Analysis `test/analyze_b6.jl`. Gate B's `p1_mixed_p2_*` cells were
overwritten by the reference row; backed up first to `test/results/_gateb_backup/` and
confirmed **bitwise identical** afterward (separations, chosen vertices, ICs) — the md5
difference was only the two new `params` capture-radius keys. That is an unplanned but real
**reproducibility result: the pipeline is deterministic under CRN across a two-week gap.**

**Prediction check** (against the 2026-09-16 B3 block):
- *"oracle hard-captures well above the 6% tournament ceiling"* — **confirmed, emphatically.**
  100% hard capture against every fixed-vertex evader, versus 0–9% for the Nash pursuer.
- *"FP recovers most of the oracle's rate within ~10 steps"* — **confirmed and sharper.** FP
  plays the oracle's exact move 75% of the time in steps 1–5 and **100% from step 6 onward.**
- *"per-vertex oracle security values show a stable ordering where the Nash-opposed ranking
  did not"* — **half right, recorded honestly.** On whole-game mean separation there is no
  meaningful ordering at all (3.3% spread, per-vertex CIs ±0.13 covering the entire range).
  On *late-game* separation there is a clean one — see below.

**B6.1 — the price of safety.** Against a fixed-vertex evader, the Nash pursuer gives up
**+3.16 to +3.31 km** (t = 94–110, paired) versus the oracle — roughly **130% of the oracle's
own value**. In capture terms the same fact is starker: oracle and FP hard-capture **100%** of
fixed-vertex evaders; Nash hard-captures **0–9%**. The price of safety is the difference
between catching a predictable evader every single time and essentially never.

**B6.2 — what online modelling recovers: 97.5–99.4%** of the available exploitation, across
all six vertices (bootstrap CIs, paired resampling). The gap between *learning it from
observation* and *being told it outright* is 20–83 metres. This is the stand-in for the MARL
baseline (§5), and it is a stronger result than that comparison would have produced.

**THE BOUNDARY — and it is the most interesting number in the sweep.** Against the `mixed`
evader the price of safety **reverses**: −0.117 ± 0.060 km, t = −3.82, significant. The
oracle does *worse* than Nash, and FP (4.87) beats both oracle (5.10) and Nash (4.98).
Knowing the opponent's true distribution buys **nothing** against an opponent that randomizes
properly — and committing to a myopic best response to that distribution actively hurts over
30 steps. This is the stage-game caveat (flagged in the driver *before* the run) showing up as
a measured effect rather than a hypothetical.

So the headline now has both ends measured: **against a predictable opponent, modelling ≈
omniscience and safety costs everything; against a properly randomizing one, omniscience is
worth less than nothing and the security strategy is doing exactly its job.** The recovery
metric is reported `n/a` there rather than as a number — the ratio is undefined when the
denominator is non-positive, and printing −97.6% [−283.8%, −34.4%] would have been
meaningless.

**B6.3 — the geometry question, and a second correction to note [f].** On whole-game mean the
six vertices are statistically indistinguishable under the oracle (2.430–2.512 km, spread 3.3%,
CIs ±0.13). **Note [f]'s surviving claim — "~1.1 km spread, about 25%, so which vertex you
play does matter" — does not hold at n=100; that 25% was itself six-seed noise.** But on
*late-game* separation under the oracle a clean split appears, with non-overlapping CIs:

| | late-game separation [km] |
|---|---|
| out-of-plane (1 top, 4 bot) | 0.038 ± 0.011, 0.046 ± 0.014 |
| in-plane (2, 3, 5, 6) | 0.109 ± 0.020 – 0.129 ± 0.023 |

Out-of-plane vertices are **~2.9× more exploitable**. Under the Nash pursuer the same
comparison is noise (6% spread, overlapping CIs). **So the in-plane/out-of-plane hypothesis is
real, but only visible against an opponent that actually exploits** — which is exactly why
note [f]'s Nash-based design produced a ranking that flipped between n=2 and n=6. The
retraction was right about the evidence; the physics was there all along, behind the wrong
opponent. Caveat to state: all of these sit *below* the 0.2 km hard-capture radius, so the
geometry determines how deeply inside capture the evader ends up, not whether it escapes.

**Predicted (for Gate C):** C1's recency-weighted FP should show little effect against these
fixed-vertex opponents (nothing to forget when the opponent never changes) and its value
should appear only against `FP_*` and `Meta_*` opponents, whose behaviour genuinely drifts. If
γ < 1 helps against a *fixed*-vertex evader, something is wrong with the implementation.

---

## 2026-09-16 — B3 closed: hard/soft capture defined, measured, implemented

**Run:** fine-grid capture analysis over the existing CRN sweep (`test/results/n30/`, no
re-run needed — slim persistence keeps per-game separations); then `test/analyze_gate_b.jl`
re-run end-to-end with the new capture section (exit 0; B4 table and B5 EGTA bitwise
unchanged — the change is reporting-only).

**Decided — the capture condition, closing B3:**

- **Hard capture = 0.2 km** — the ISS keep-out-sphere radius (citable proximity-ops
  grounding), and measured to be the smallest radius still statistically resolvable at
  n=100/cell: 80 events across 2,500 games; pooled per-evader Wilson CIs separate `greedy`
  1.6% [0.8, 3.1] from `FP_greedy` 6.8% [4.9, 9.4]. At 0.1 km rates are 0.2–1.4% (0–3
  events/cell, unresolvable); 0.25–0.3 km resolve better but have no physical citation.
- **Soft capture = 1.0 km** — proximity-operations scale, and the most discriminating radius
  on the measured curve: per-cell rates span 13–100% (1.5 km saturates at 85–100%, 0.75 km
  discriminates less). Pooled per-evader: `mixed` 86.2% [82.9, 88.9] vs `FP_greedy`
  62.6% [58.3, 66.7].
- **Post-hoc first passage, no in-game termination.** Termination would censor the
  separation metrics and break CRN pairing comparability days before narrative lock;
  time-to-capture comes from the same first passage anyway.

**New finding — the headline restated in capture terms:** the `FP_greedy`/`FP_greedy` cell
is an extreme hard-capture outlier — **18% vs ≤ 9% in every other cell** (14% already at
0.15 km; the sweep-wide minimum separation of 9 m is in that cell). Mutual exploitation
doesn't just lose mean separation, it courts hard capture at ~2.5× the rate of any other
matchup. Also new: median first-soft-capture step is 7–17.5 (of 30); the `FP_greedy`
*pursuer* penetrates the 1 km zone fastest (median step ~7–11 across evaders).

**Implemented:** `params.r_capture_hard` / `r_capture_soft` in `init_game`;
`separation_series` / `capture_stats` / `wilson95` in `Utils.jl` (post-hoc, slim-compatible —
the old `min_separation` path read `X[chosen]`, which slim strips, so it could not run on the
Gate B data at all; the new `rv_chosen` path is pinned bitwise-equal to the old one on full
games — boundary *positions* are bitwise shared between steps because the impulsive burn
touches only velocity); `analyze_gate_b.jl` capture section reports hard/soft counts, pooled
Wilson CIs, time-to-soft-capture, and retains the radius curve; new B3 testset in
`runtests.jl`.

**Predicted (for B6, now unblocked):** against fixed-vertex evaders the oracle-BR pursuer
hard-captures at well above the 6% tournament ceiling, and `FP_greedy` recovers most of the
oracle's soft-capture rate within ~10 steps (consistent with its median first-passage step of
7–9 against predictable evaders). Per-vertex oracle security values show a stable ordering
where the Nash-opposed ranking (2026-09-01 entry) did not.

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
