# LOG — decision record

Append-only, newest first. Corrections are new entries; nothing gets edited. At milestones,
old entries roll up into a dated paragraph at the bottom. Each block: what ran (with run
identifier), what was decided, what was measured, what is predicted for the next run.

---

## 2026-10-29 — fig_belief relabelled (preview only; no new games)

**Ran:** scratch `belief.jl`. Legend titled "Type-based pursuer's belief that the evader is:"; panel titles
"<X> evader", with * marking evaders that are not in the library (FP-mixed, type-based). Data unchanged
(pursuer = Meta_greedy in every panel; mean of `p2_state[k].strategy_belief` over 100 trials). Old render kept
as `figures/paper/learning_gallery/belief_v1.png`.

## 2026-10-29 — fig_learning back to two panels (author's choice, "option 1"; no new games)

**Ran:** one-panel design reverted. `fig_learning()` is the two-panel version again, identical to
`learning_gallery/v10_two_panel_gain` except panel (b) is retitled "(b) How much closer than a minimax
pursuer". Numbers unchanged (gain over steps 10–30: MM +0.161, Gr +2.813, FPg +3.461, FPm +1.012).
Then: legend titled "Evader:" (left title, 2 rows) so the lines read as evader types.
Then: PAIR_SIZE widened 215 → 245 pt (height 212) and PAIR_TXT.legend 7 → 6.5 pt, so the titled legend fits one row; fig_summary and fig_learning re-rendered at the new size.
Then: reverted to PAIR_SIZE 215 × 212 (author prefers the old aspect). Legend kept at 6.5 pt, one row, `tellwidth = false` + right-aligned so it extends left over the y-label column. Both figures re-rendered.

## 2026-10-29 — fig_learning redrawn as one panel (author's choice, "option 2"; no new games)

**Ran:** `fig_learning()` rewritten in `test/figures_paper.jl`: one panel at PAIR_SIZE; colour = evader
(minimax, greedy, FP-greedy, FP-mixed); solid + 95% band = type-based pursuer, faint dashed = minimax
pursuer on the same trials. The gap between a colour's two lines is the gain; the subtracted panel (b) is
gone. The previous two-panel version is kept as `figures/paper/learning_gallery/v10_two_panel_gain.{png,pdf}`.

**Measured (steps 10–30, TB vs MM pursuer):** minimax evader 2.83 vs 3.00 (gap 0.16); greedy 0.21 vs 3.03
(2.81); FP-greedy 0.29 vs 3.76 (3.46); FP-mixed 2.46 vs 3.47 (1.01). Same as the 10-29 block above.

## 2026-10-29 — paper metric moved to steps 10–30 (author's request; 32-core, no new games)

**Ran:** `test/analyze_late.jl` (window list now 1–30, 6–30, 10–30, 15–30; output in scratch `late_10.txt`)
and `FIG_OUTDIR=figures/paper test/figures_paper.jl` with `LATE0` now read from ENV, default **10**
(`LATE0=6` reproduces the old figures). CRN verified across all cells. Value check: the 6–30 numbers
reproduce LOG 10-28 exactly (FPg − MM evader vs MM +0.784, vs FPg −0.382; TB − MM evader vs FPg −0.208).

**Measured, steps 10–30 (± 95% CI):**
- 6×6 table (rows evader Gr/MM/Rnd/FPg/FPm/TB; cols pursuer same order; avg):
  Gr 3.77 3.03 4.56 3.32 3.50 0.21 | 3.07 ± .12; MM 3.09 3.00 4.84 2.88 3.59 2.83 | 3.37 ± .07;
  Rnd 2.63 2.92 4.45 2.56 3.33 2.43 | 3.05 ± .06; FPg 3.06 3.76 7.04 2.43 4.23 0.29 | 3.47 ± .17;
  FPm 2.87 3.47 5.75 2.79 3.92 2.46 | 3.54 ± .10; TB 2.87 3.67 7.16 2.61 4.29 2.30 | 3.82 ± .14;
  pursuer avg 3.05 3.31 5.63 2.76 3.81 1.76 (± .03–.12). Cell CIs .02–.21.
- Meta-game: pure MM evader vs TB pursuer, 2.834 km; TB pursuer weakly dominant.
- FPg − MM evader by pursuer: Gr −0.04 ± .10 (ns), MM +0.76 ± .11, Rnd +2.20 ± .27, FPg −0.45 ± .06,
  FPm +0.64 ± .16, TB −2.54 ± .04; pooled +0.09 ± .13 (ns).
- Advantage over MM, pooled | vs TB: evader TB +0.45 ± .10 | −0.53; FPg +0.09 | −2.54; FPm +0.17 | −0.37;
  Gr −0.31 | −2.62; Rnd −0.32 | −0.41. Pursuer TB +1.55 ± .10 | +1.37; FPg +0.54 | +1.07; FPm −0.50 | −0.62;
  Gr +0.26 | +0.80; Rnd −2.32 | −3.49.
- TB − FPg evader: six pursuers +0.35 ± .08; five (no TB) +0.02 ± .06 (ns). TB − FPg pursuer −1.01 ± .10.
- TB pursuer − MM pursuer by evader: Gr −2.81, MM −0.16 ± .07, Rnd −0.50, FPg −3.46, FPm −1.01, TB −1.37.
  TB − FPg pursuer vs FPg evader −2.13 ± .05.
- TB − MM evader by pursuer: Gr −0.22 ± .11, MM +0.68, Rnd +2.32, FPg −0.27 ± .05, FPm +0.70, TB −0.53.
- vs TB pursuer, MM evader leads TB +0.53 ± .08, Rnd +0.41 ± .05. Self-play TB 2.30, FPg 2.43, MM 3.00.
- Price of safety: MM − oracle 3.64–3.74 km; FPg recovers 99.8–100.0%, TB 99.8–100.0%. vs MM evader:
  oracle − MM pursuer +0.14 ± .08 (3.14 vs 3.00), FPg 2.88, TB 2.83.
- FPg − MM evader vs MM pursuer by M: 6 +0.76, 12 +0.93, 24 +1.03.
- Robustness: 15–30 gives the same evader and pursuer rankings and no significant sign flips.

**Decided:** all metric figures regenerated at 10–30 in `figures/paper/` (summary, dv_vs_sep, learning
printout). Heatmap / boxplot / price-of-safety use their own step windows and are unchanged.
Capture and ΔV are whole-game and unchanged.

## 2026-10-29 — fig_heatmap_values (no new games)

**Ran:** `fig_heatmap(values = true)` (new keyword in `test/figures_paper.jl`; also added to the run block) →
`figures/paper/fig_heatmap_values.{pdf,png}`. Same layout and colours as `fig_heatmap`, with each cell's
mean separation over the 5-step window printed in it (`%.1f`, 5.5 pt; white on the darker half of the ramp).
`fig_heatmap` itself is unchanged. **Measured:** same numbers as the F2 printout; e.g. type-based pursuer vs
FP-greedy / greedy evader 0.5 / 0.6 km at steps 6–10 and 0.3 / 0.3 at 26–30.

## 2026-10-29 — belief spread across trials (32-core, no new games)

**Ran:** scratch `belief_spread.jl` on the existing type-based-pursuer cells (100 trials each).
It reads `p2_state[k].strategy_belief` for the true type (random for FP-mixed and type-based evaders).

**Measured:** true-type posterior, mean [p10 / median / p90] across trials:
- minimax: k2 .47 [.13/.35/.87], k5 .95 [.90/.98/1.00], k10 .99 [.99/1/1]
- greedy: k2 .63 [.43/.66/.81], k5 .97 [.92/.98/.99], k10 1.00
- FP-greedy: k2 .92 [.83/.97/.97], k5 1.00
- random: k2 .68 [.03/.99/.99], k5 .94 [1/1/1] (sd .21), k10 .98 (sd .12)
- FP-mixed→random: k2 .61 [.02/.99/.99], k5 .95, k10 1.00
- type-based→random: k2 .45 [.02/.19/.99], k5 .70 [.02/.99/1], k10 .84 [.30/1/1], k30 .95 (sd .22)

**Decided:** the belief is a categorical posterior, so it has no covariance. The trial-to-trial
spread is mostly all-or-nothing (bimodal) for random-like evaders, so the mean line understates how
fast most trials lock on. Mean ± sd would not be meaningful here; if bands are drawn, use p10–p90.

**Predicted:** n/a (no new run planned).

**Then:** `fig_belief` preview redrawn with a shaded p10–p90 band (across 100 trials) on the true-type line in each panel. Where most trials sit at 1.0 and a few lag, the mean line falls outside the band (bimodal); the caption must say the band is a percentile range, not a CI.

**Then:** band dropped at the author's request (confusing when the mean sits outside it). `fig_belief` is back to mean lines only; spread stays in this LOG block.

**Then (saturation check, scratch `belief_sat.jl`):** share of trials whose largest posterior entry is exactly 1.0 in Float64, and median 1 − max, at steps 3/5/10/30:
- minimax 0/0/0/0% (9e-2, 2e-2, 2e-4, 6e-11); greedy 0/0/0/100%; FP-greedy 0/0/0/100%
- random 0/0/16/95% (2e-2, 1e-5, 5e-12, 0); FP-mixed 0/0/3/94%; type-based 0/0/0/25% (4e-2, 2e-3, 1e-4, 1e-12)

The 1e-4 floor is on the *likelihood*, not the posterior: each contradicting step multiplies a wrong type by 1e-4, so after about four contradictions it drops below Float64 resolution and the posterior on the true type reads exactly 1.0. **Correction:** the earlier chat claim "90% of trials place belief 1.0 by step 3" was wrong; at step 3 the median is about 0.98. **Recommended (author to decide):** no rerun before ECC (it would change every type-based number). A posterior floor (fixed-share mixing with uniform) is noted as a limitation / future work.

## 2026-10-28 (night, belief) — type-based pursuer's posterior over types, by true evader (figure only)

**Ran.** Scratch `belief.jl` → `figures/paper/fig_belief` (preview, not in the paper). Mean over 100
trials of the TB pursuer's `strategy_belief` (p2_state), step 0 = uniform prior over 10 types; the six
fixed-vertex types summed. 32-core. **Measured** (posterior on the true type at steps 1/2/5/10/30):
MM .20/.47/.95/.99/1.00; Gr .37/.63/.97/1.00/1.00; FPg .43/.92/1.00/1.00/1.00; Rnd .12/.68/.94/.98/1.00.
Out of library: FPm → random .61/.95/1.00 at steps 2/5/10; TB evader → random .45/.70/.84/.95 at steps
2/5/10/30, with minimax .13–.17 through step 10 (FP-greedy peaks .25 at step 2). **Predicted.** Nothing.

---

## 2026-10-28 (night, chosen) — fig_learning final: type-based pursuer by evader (figure only)

**Decided (author).** `fig_learning` = gallery v4 without the thin baseline lines, now in
`test/figures_paper.jl` F6. (a) TB pursuer separation vs MM / Gr / FPg / FPm evaders; (b) paired gain
over a minimax pursuer on the same evader. Steps 6–30: sep 2.84 / 0.29 / 0.33 / 2.49; gain +0.152 /
+2.731 / +3.451 / +0.982 (= table and LOG 10-28 late). Gain at step 5: +0.17 / +0.76 / +2.75 / +0.93;
at step 8: +0.07 / +2.56 / +3.66 / +0.92. Gallery files stay in `figures/paper/learning_gallery/`
(not for the paper). Then: `fig_summary` and `fig_learning` both set to exactly 215 × 235 pt, fig_summary's
original canvas (`PAIR_SIZE`, saved uncropped so the size is exact; a brief 240 × 200 version was reverted), then 10% shorter: 215 × 212 pt.
Shared text sizes (`PAIR_TXT`: ticks/labels/legend 7, titles 8) and the same row layout (legend on top,
two panels, bottom label) so the pair's axes line up side by side; tick marks removed from `fig_learning`. **Predicted.** Nothing.

---

## 2026-10-28 (night, gallery 4) — candidate v0b: TB pursuer by evader / MM evader by pursuer (figure only)

**Ran.** Scratch `simple2.jl` → `learning_gallery/v0b_TBP_MME`. Raw separation only. Steps 6–30 (= table):
TB P vs MM / FPm / Gr / FPg E 2.84 / 2.49 / 0.29 / 0.33; MM E vs MM / Gr / FPg / TB P 2.99 / 3.10 / 2.88 /
2.84. **Predicted.** Nothing.

---

## 2026-10-28 (night, gallery 3) — simple fig_learning candidate v0: raw separation only (figure only)

**Ran.** Scratch `simple.jl` → `figures/paper/learning_gallery/v0_simple`. Two panels, no deltas:
(a) FPg evader, (b) MM evader, each vs MM / FPg / TB pursuers. Steps 6–30 means (= table): FPg E
3.78 / 2.50 / 0.33; MM E 2.99 / 2.88 / 2.84. **Predicted.** Nothing.

---

## 2026-10-28 (night, gallery 2) — gallery v9 replaced: minimax evader by pursuer (figure only)

**Changed.** `v9_MMP_by_evader` → `v9_MME_by_pursuer`: minimax evader vs TB / FPg / Gr / FPm pursuers,
bottom = gain over a minimax pursuer (steps 6–30): TB +0.152, FPg +0.111, Gr −0.103, FPm −0.588
(random pursuer omitted, −1.87). Top-panel titles shortened to the player name. Then (author) v9 bottom
flipped to top − gray baseline (evader's view; same magnitudes, opposite sign). **Predicted.** Nothing.

---

## 2026-10-28 (night, gallery) — nine fig_learning candidates for the author to choose from (figures only)

**Ran.** Scratch `gallery.jl` → `figures/paper/learning_gallery/v1..v9` (+ `_contact_sheet.png`). Each:
top = per-step mean separation (95% band), bottom = paired gain over the minimax player in the same
role. v1–v5 focal learner by opponent (FPg E, TB E, FPm E, TB P, FPg P; thin lines = same matchup with
minimax in the focal role); v6–v9 one fixed opponent, players compared against it (FPg E chased; TB /
FPg / MM pursuer fled; one gray minimax baseline). All steps 6–30 means match the 6×6 table. New gains
not logged before: TB E vs Gr / FPg P −0.149 / −0.208; FPm E vs MM / FPg / TB P +0.473 / −0.058 /
−0.356; FPg P vs Gr / TB E −0.275 / +0.997; Gr P vs FPg E +0.739; Rnd E vs MM P −0.067 (gain vs MM).
No intervals computed here (bands are drawn). **Predicted.** Nothing.

---

## 2026-10-28 (night, final+++) — fig_learning simplified (figure only)

**Changed.** Both panels now follow the FP-greedy evader; no legends, direct labels. (a) FPg − MM
evader vs MM / FPg / TB pursuers (unchanged lines). (b) MM − TB and MM − FPg pursuer separation vs the
FPg evader (+3.451, +1.276 over steps 6–30). Dropped from (b): TB vs greedy and vs minimax evaders
(their numbers stay in the table/LOG). Values unchanged from the blocks below. **Predicted.** Nothing.

---

## 2026-10-28 (night, final++) — fig_learning (b): FP-mixed line swapped for FP-greedy pursuer (figure only)

**Changed.** Panel (b) now: minimax − learning pursuer separation for TB vs FPg / Gr / MM evaders and
FPg pursuer vs FPg evader (gray). New line, MM − FPg pursuer vs FPg evader: +0.23 (step 3), +0.78 (5),
+1.00 (8), +1.24 (10), +1.53 (20), +1.41 (30); steps 6–30 mean **+1.276** (= 3.78 − 2.50, table).
TB on the same evader +3.451, so TB − FPg pursuer = 2.17 km (matches LOG 10-28 late). FPg v FPg
oscillation (spike step 7, dip step 9) appears in both panels, as it is the same cell. **Predicted.** Nothing.

---

## 2026-10-28 (night, final+) — fig_learning reinstated with new pairings (figure only)

**Decided (author).** `fig_learning` is back (reverses the night cut). New content (`figures_paper.jl`
F6): (a) FP-greedy − minimax evader vs MM / FPg / TB pursuers; (b) minimax − type-based pursuer vs
FPg / Gr / FPm / MM evaders; per-step paired gaps, up = learner better, 95% bands. Printed values
match the block below; steps 6–30 means +0.784 / −0.382 / −2.514 and +3.451 / +2.731 / +0.982 / +0.152.
**Predicted.** Nothing.

---

## 2026-10-28 (night, final) — per-step paired gaps for choosing fig_learning pairings (analysis only)

**Ran.** Scratch `ts.jl`: per-step mean separation and paired differences, 16 cells, 32-core. No new games.
**Measured** (paired, km; sign of 95% CI noted). Evader FPg − MM: vs MM pursuer +0.55 to +1.06 at every
step (flat, all significant); vs FPg pursuer +0.65/+0.86 at steps 3–4, ≈0 at 5–8, −0.40 at step 10,
−0.80 at step 30 (reversal); vs TB pursuer +0.26 at step 3, −1.92 at step 5, ≈−2.5 from step 8 (collapse).
Pursuer TB − MM: vs FPg evader −0.43 (step 3) → −2.75 (5) → −3.66 (8), flat after; vs Gr evader +0.24 (3)
→ −1.58 (6) → −2.56 (8), flat after (slower identification); vs FPm −0.6 to −1.1 from step 4; vs MM
evader ≈0 at every step except step 25 (−0.47). Evader TB − MM vs FPg / Gr / TB pursuers: positive at
steps 3–6, negative from about step 12–15. Single-step values are noisy (e.g. FPg v FPg step 7 +1.10).
**Predicted.** Nothing.

---

## 2026-10-28 (night, last) — heatmap window ranges for the results text (analysis only)

**Ran.** Scratch `hm.jl`: mean separation per 5-step window, 6×6 minus the random pursuer, 32-core.
**Measured.** Steps 1–5: 14.40–15.85 km in every matchup. Steps 6–10: 2.45–4.38 km except TB
pursuer vs FPg / Gr evaders 0.46 / 0.59. Steps 26–30: 2.21–4.33 km except TB vs FPg / Gr 0.30 /
0.25. No intervals (cell means). **Predicted.** Nothing.

---

## 2026-10-28 (night, later) — executed ΔV: learning evaders save fuel (analysis only)

**Ran.** Scratch `dv.jl` over the 36 6×6 cells (ΔV = Σ‖Δv‖ of executed impulses over 30 steps,
per player; separation over steps 6–30). 32-core machine. No new games.

**Measured** (paired vs the minimax player, 95% CI over 600 games):
- Evader ΔV pooled over six pursuers: MM 248.7 ± 1.0 m/s; **FPg 194.1 (−54.6 ± 3.3, t −32.7,
  −22%)**; **TB 208.5 (−40.1 ± 5.1, t −15.3, −16%)**; FPm 222.9 (−25.8 ± 1.5, −10%); Gr −4.9 ±
  3.1; Rnd +3.5 ± 1.4.
- Per pursuer, FPg and TB evaders vs MM evader: vs MM / Rnd / FPm pursuers −75.5 to −99.5 m/s
  while separation is +0.68 to +2.30 km (both better). TB evader spends **more** vs Gr (+34.8 ±
  2.8) and FPg (+40.9 ± 2.8) pursuers — the capture-avoidance matchups. FPg evader vs TB pursuer
  +1.4 ± 3.2 (null).
- Pursuer ΔV pooled: MM 337.9; all others 8–18 m/s less (TB −17.7 ± 3.4).
- Pursuer − evader ΔV, all 3,600 games: +99.7 ± 1.5 m/s; pursuer spends more in 36/36 cells.

**Not tested.** Why learners save fuel (hypothesis: minimax resamples its target each step and
reverses more often). Do not claim a mechanism.

**Predicted.** Nothing.

---

## 2026-10-28 (night) — paper cuts: oracle / price-of-safety section and fig_learning (decision only)

**Decided (author).** Cut from the paper: the Price of Safety subsection (fixed-vertex evaders,
oracle) with `fig_price_of_safety`, and `fig_learning`. `fig_dv_vs_sep` stays. The CDC reviews
never asked for an oracle benchmark. The price of safety is now stated from the tournament
(steps 6–30): TB − MM pursuer −2.73 (greedy evader) and −3.45 km (FP-greedy evader); MM pursuer
hard-captures those evaders in 4% and 7% of trials, TB in 100%. Separately, the author chose to
report point estimates without ± in the paper text and tables (CLAUDE.md updated); LOG keeps the
intervals. No runs.

---

## 2026-10-28 (late) — paper metric switched to mean separation over steps 6–30; all results recomputed (analysis only)

**Decided (author).** The paper's separation metric is now the mean over **steps 6–30**, after
the approach (≈36 → ≈4 km by step 4; heatmap window 1–5). Capture still uses all 30 steps
(close passes do occur in step 5: 1,406 of 6,000 games dip below 1 km in steps 1–5, 27 below
0.2 km). Steps 15–30 are the robustness check. Supersedes the "keep whole game" recommendation
in the block below.

**Ran.** New `test/analyze_late.jl` (windows 1–30 / 6–30 / 15–30; CRN verified over 61 cells:
6×6, B6, oracle) and scratch `cap.jl` (6×6 capture). `figures_paper.jl`: `cell()` gains `late`
(mean over s ≥ `LATE0` = 6); `fig_summary`, `fig_dv` use it; summary x-limits widened.
Steps 1–30 output reproduces every logged whole-game number. 32-core machine. No new games.

**Measured, steps 6–30** (paired, 95% CI; n = 100 per cell, 600 pooled):
- 6×6 means [evader rows Gr/MM/Rnd/FPg/FPm/TB × pursuer cols same order]:
  Gr 3.71 3.02 4.54 3.29 3.51 0.29 | MM 3.10 2.99 4.86 2.88 3.58 2.84 | Rnd 2.63 2.93 4.45 2.57
  3.33 2.43 | FPg 3.04 3.78 7.05 2.50 4.26 0.33 | FPm 2.86 3.47 5.72 2.83 3.91 2.49 | TB 2.95 3.67
  7.16 2.68 4.28 2.36. CI half-widths 0.02–0.18 per cell (whole game: 0.12–0.21; the approach
  carried most of the IC variance), 0.03–0.17 for averages.
- Evader averages: TB **3.85 ± 0.14**, FPm 3.54 ± 0.09, FPg 3.49 ± 0.17, MM 3.38 ± 0.07, Gr 3.06
  ± 0.11, Rnd 3.06 ± 0.06. Pursuer averages: TB **1.79 ± 0.09**, FPg 2.79 ± 0.03, Gr 3.05 ± 0.03,
  MM 3.31 ± 0.04, FPm 3.81 ± 0.05, Rnd 5.63 ± 0.11.
- Meta-game: pure (MM evader, TB pursuer), value **2.842** (cert 3.2e-14); TB pursuer lowest in
  every row.
- FPg − MM evader by pursuer: Gr −0.058 ± 0.085 (null), MM **+0.784 ± 0.098** (t 15.7), Rnd
  +2.189 ± 0.229, FPg **−0.382 ± 0.057** (t −13.2), FPm +0.679 ± 0.143, TB **−2.514 ± 0.039**
  (t −125.6).
- Advantage over MM, all opps | vs TB: evader TB +0.473 ± 0.092 | −0.479 ± 0.080; FPg +0.116 ±
  0.125 (**now null**, t 1.8) | −2.514; FPm +0.168 ± 0.053 | −0.356 ± 0.049; Gr −0.316 ± 0.093 |
  −2.554 ± 0.037; Rnd −0.320 ± 0.046 | −0.410 ± 0.048. Pursuer TB +1.520 ± 0.100 | +1.309 ±
  0.107; FPg +0.517 ± 0.052 | +0.997 ± 0.085; FPm −0.502 ± 0.045 | −0.608 ± 0.120; Gr +0.262 ±
  0.054 | +0.724 ± 0.106; Rnd −2.321 ± 0.094 | −3.489 ± 0.195.
- TB − FPg evader: six +0.357 ± 0.075, five (no TB pursuer) +0.021 ± 0.053 (null). TB − FPg
  pursuer (six) −1.003 ± 0.095.
- TB − MM pursuer by evader: Gr −2.731 ± 0.065, MM −0.152 ± 0.065 (t −4.6), Rnd −0.495 ± 0.063,
  FPg −3.451 ± 0.085, FPm −0.982 ± 0.084, TB −1.309 ± 0.107. TB − FPg pursuer vs FPg evader
  −2.174 ± 0.043.
- TB − MM evader by pursuer: Gr −0.149 ± 0.091 (**now significant**, t −3.2; null in whole game),
  MM +0.678 ± 0.102, Rnd +2.300 ± 0.239, FPg −0.208 ± 0.047, FPm +0.698 ± 0.139, TB −0.479 ±
  0.080. TB − FPg evader vs FPg pursuer +0.174 ± 0.053.
- Self-play: TB/TB 2.36 ± 0.07, FPg/FPg 2.50 ± 0.04, MM/MM 2.99 ± 0.06.
- Price of safety (B6): MM − oracle 3.62–3.69 km (t 89–108); FPg recovers 99.4–99.8%, TB
  99.7–99.9%; oracle 0.10–0.18 km vs MM 3.73–3.84. Vs MM evader: oracle − MM **+0.148 ± 0.070**
  (t 4.2), FPg − MM −0.111 ± 0.067, TB − MM −0.152 ± 0.065; means 3.14 / 2.99 / 2.88 / 2.84.
- FPg − MM evader vs MM pursuer by vertex count: M = 6 +0.784 ± 0.098, 12 +0.944 ± 0.096,
  24 +1.009 ± 0.085.
- **Steps 15–30 robustness:** both role rankings, the meta-game equilibrium (value 2.818) and
  every significant sign are unchanged; FPg − MM vs FPg pursuer −0.485 ± 0.074; TB − FPg evader
  (five) −0.001 ± 0.069.
- Capture, 6×6 (all 30 steps, Wilson): pooled over six pursuers, soft: MM evader 86.8% [83.9,
  89.3], FPg 68.8% [65.0, 72.4], TB **36.5% [32.7, 40.4]**; hard: MM 2.7% [1.6, 4.3], FPg 22.3%
  [19.2, 25.8], TB 3.3% [2.2, 5.1]. Hard capture is 100% for TB pursuer vs FPg and Gr, 18% [11.7,
  26.7] for FPg/FPg, 3.7% [3.1, 4.4] pooled over the other 33 cells.
- Out of library: MAP type is `random` in 90/100 (TB evader vs FPm) and 100/100 (TB pursuer vs
  FPm) games — the "90–100%" claim holds for FP-mixed alone.

**Predicted.** Nothing; no runs planned.

---

## 2026-10-28 (later) — does the opening approach flatten the 6×6 table? Steps 1–5 vs 6–30 (analysis only)

**Ran.** Scratch `late.jl` over the 36 cells, per-step separation split into steps 1–5 and
6–30. CRN verified. 32-core machine. No new games.

**Measured.** Steps 1–5 average 14.7–17.4 km in every cell (the approach from ~36 km), so they
add ~2 km to every whole-game entry. Paired advantage over minimax, whole game → steps 6–30:
TB pursuer +1.329 ± 0.087 → **+1.520 ± 0.100**; FP-greedy pursuer +0.468 → +0.517 ± 0.052;
TB evader +0.460 → +0.473 ± 0.092; FP-greedy evader +0.154 → +0.116 ± 0.125 (null in both);
random pursuer −2.186 → −2.321. Ranking and signs unchanged. Steps 6–30 pursuer column means:
Gr 3.05, MM 3.31, Rnd 5.63, FPg 2.79, FPm 3.81, TB 1.79; TB pursuer vs FPg / Gr evader 0.33 /
0.29 km. Steps 1–5 alone already differ by strategy (TB evader +0.391 ± 0.068 over minimax).

**Decided (recommended, author to confirm).** Keep whole-game means as the paper metric; the
approach compresses ratios, not differences. Meta-game equilibrium on steps 6–30 not computed.

**Predicted.** Nothing.

---

## 2026-10-28 — paper tables rebuilt for the 6×6 tournament; figures switched to Lato (analysis only)

**Ran.** Scratch scripts (`tables.jl`, `tb2.jl`) over the 36 cells of `test/results/n30/`;
CRN verified across all 36. `test/figures_paper.jl` re-run with `FIG_OUTDIR=figures/paper`.
No new games. 32-core machine.

**Measured** (paired over common ICs, 95% CI):
- `tab:contrast` (FP-greedy − minimax evader) reproduces the 09-02 rows exactly; new row vs the
  type-based pursuer **−2.176 ± 0.038 (t = −113.3)**.
- `tab:types`: every cell and every bold mark reproduces the 10-20 table. Six-opponent averages:
  pursuers minimax 5.27 ± 0.06, FP-greedy 4.81 ± 0.05, type-based 3.94 ± 0.09; evaders minimax
  5.35 ± 0.08, FP-greedy 5.50 ± 0.16, type-based 5.81 ± 0.13.
- Type-based − FP-greedy evader over all six pursuers: **+0.306 ± 0.065** (t = +9.2); over the
  five non-type-based pursuers: **+0.012 ± 0.045** (null). The evader lead comes entirely from
  the matchup against the type-based pursuer. Type-based − FP-mixed evader (six): +0.297 ± 0.059.
- Type-based − FP-greedy pursuer over all six evaders: **−0.861 ± 0.081** (t = −20.7).

**Decided.** All figures use Lato (OFL, shipped in `test/fonts/`); every PDF embeds only Lato.
`fig_summary` (advantage over minimax, dumbbell) and the 5-step-window `fig_heatmap` are the
two results figures; the boxplot is out of the paper. Legend "width ∝" reworded (Lato has no ∝).

**Predicted.** Nothing; no runs planned.

---

## 2026-10-27 — 6×6 tournament: type-based joins as the sixth strategy (analysis only)

**Decided.** The paper presents one 6×6 tournament (5 Gate B strategies + `Meta_greedy`) instead
of a 5×5 plus "18 further matchups". The 11 Meta cells share the Gate B CRN and the inert check
holds, so merging is legitimate. Hedge is cut from the paper (FP-mixed is already out of library).

**Ran.** `WITH_META=1 julia -t 8 --project=. test/analyze_gate_b.jl` (new env switch) and
`FIG_OUTDIR=figures/paper test/figures_paper.jl` (now 6×6; writes outside the paper folder).
No new games. 32-core machine.

**Measured** (mean separation, S = 30, pooled 95% CI over 600 games):
- Evader row means: **type-based 5.81 ± 0.13**, FP-mixed 5.51 ± 0.10, FP-greedy 5.50 ± 0.16,
  minimax 5.35 ± 0.08, greedy 5.06 ± 0.11, random 5.04 ± 0.08.
- Pursuer column means: **type-based 3.94 ± 0.09**, FP-greedy 4.81 ± 0.05, greedy 5.02 ± 0.06,
  minimax 5.27 ± 0.06, FP-mixed 5.77 ± 0.07, random 7.46 ± 0.11.
- The type-based column has the lowest mean in every row; vs a minimax evader it only ties
  FP-greedy (4.85 vs 4.87). Lowest cells: FP-greedy vs type-based 2.67, greedy vs type-based
  2.68, both 100% hard capture.
- FP-greedy − minimax evader, vs a type-based pursuer: **−2.176 ± 0.038** (t = −113).
- EGTA meta-game on the 6×6 means: **pure equilibrium (minimax evader, type-based pursuer),
  value 4.848 km** (cert 2.2e-14). No row weakly dominates all others. The 5×5 result (FP-greedy
  in the support on both sides) holds only without the type-based player.
- ΔV: the clean "FP evaders spend less" split is gone. Learner evaders 144–293 m/s, non-learner
  169–266 m/s; pursuers 251–371 m/s.

**Consequence for the paper.** "FP-greedy is the best evader and best pursuer" and "FP vs FP is
the lowest separation" are false in the 6×6. Heatmap, boxplot and ΔV figures regenerated.

**Predicted.** Nothing; no further runs planned.

## 2026-10-20 — type-based reasoning written into `MAIN_PAPER.tex`

**Paper edits:**
- *Abstract:* now covers three strategies: minimax, FP and type-based.
- *Intro:* the motivation paragraph is rewritten, and contribution 3 includes the
  type-based player.
- *Related work:* "Mixed Strategies and Type-Based Reasoning" is rewritten against the
  10-20 literature report.
- *Methods:* new §"Type-Based Opponent Reasoning" (`sec:types`): library, exact FP type,
  Bayes update (`eq:type_posterior`) with the 1e-4 floor, and its stated assumptions.
  Strategy 6 is added.
- *Setup:* the 18 extra matchups are described.
- *Results:* new §"Type-Based Reasoning" (`sec:typeresults`), with Table `tab:types` in
  two blocks (pursuer and evader comparisons). It covers identification, the pursuer
  gains, evader capture avoidance, out-of-set behavior and self-play.
- *Discussion:* now has four limitations; the future-work item on type reasoning is
  replaced with parameterized types and belief shaping.
- "FP is the best evader and pursuer" is qualified to "among the five tournament
  strategies".

**Bold rule in `tab:types`:** bold marks the best entry plus anything with a non-significant
paired difference from it. The type-based-opponent rows were checked separately:
- (a) Meta pursuer − FP pursuer vs a Meta evader = −0.286 ± 0.066;
- (b) Meta evader − minimax evader vs a Meta pursuer = −0.398 ± 0.070.

Both are significant, so a single bold entry in each row is correct.

**Solver totals re-run with the Meta cells** (`analyze_solver.jl`, 69 cells):
- **2,484,000 solves, 2 non-converged.** Both hit the iteration cap after reaching their
  vertex: miss 1.6e-12 km (regret_matching cell) and 1.4e-12 km (`p1_Meta_greedy_p2_greedy`,
  game 20, step 24).
- Max miss over all cells 4.25e-7 km.
- LP certificate max 1.8e-12 over 207,000 LPs.

The tournament figures are unchanged.

**bib (`refs.bib`):**
- 13 entries added from the report (only those tagged [V] or [V-partial]).
- `peters2022learning` upgraded to RSS 2022 with DOI.
- The `hanlong…` entry's swapped given/family names fixed. It now renders as Zhang et
  al.; the key is unchanged.

**Not compiled.**

---

## 2026-10-20 (32-core) — Meta sweep: type reasoning is a much stronger pursuer, and an evader that avoids capture

**Run:** `test/run_meta.jl`, 18 cells × 100 × 30, **75.8 min** on 32 threads. CRN was
verified against every Gate B / B6 cell compared below. Analysis is in
`test/analyze_meta.jl`. Meta = `Meta_greedy` with the FP-learner type. Contrasts are paired,
± is the 95% CI.

**Prediction check (LOG block below, written before the run): 1, 2 and 3 FAILED, 4
confirmed, 5 confirmed and exceeded, 6 recorded.**

1. **FAILED, in sign.** Meta evader vs FP pursuer: Meta − minimax = **−0.132 ± 0.042**
   (t = −6.2). This is still a loss, but half of FP's −0.254, and Meta − FP = +0.123 ± 0.047.
   The FP type *was* identified (posterior 0.82 at step 5, 1.000 at step 30). So knowing
   the pursuer's next move exactly does **not** buy mean separation. The capture data
   below show what it does buy.
2. **FAILED.** Meta evader vs minimax pursuer: **+0.627 ± 0.086** (t = +14.3), close to
   FP's +0.735 (Meta − FP = −0.108 ± 0.092). The minimax type *was* identified (0.97 at
   step 10). So a best response to the current Nash mixture gains as an evader, even though
   the oracle pursuer (the same move) lost against a minimax evader in B6. The mechanism is
   unexplained. Do not claim it.
3. **FAILED.** Meta evader vs greedy pursuer: −0.070 ± 0.078 (null), with greedy identified.
4. **CONFIRMED.** Meta pursuer vs fixed-vertex evaders recovers **97.9–99.4%** of the oracle's
   advantage, at least FP's at every vertex, with 100% hard capture. It identifies faster:
   it plays the oracle's move in 79% of step-2 decisions vs FP's 50%, and in 100% from step 3
   (FP: from step 4).
5. **CONFIRMED and exceeded.** Out-of-set opponents cause no collapse; Meta *gains*. As
   pursuer, FP_mixed −0.882 ± 0.073 and hedge −0.402 ± 0.062 vs the minimax pursuer; as
   evader vs FP_mixed, +0.641 ± 0.124. **The posterior falls back to the `random` type**:
   the final-step most-likely type is random in 90–100% of out-of-set games, so the uniform
   type acts as a catch-all.
6. Meta vs Meta: separation 4.45 ± 0.14, the lowest of any self-play pair (FP/FP 4.61,
   mixed/mixed 4.98). Hard capture is 6% [3, 12], vs FP/FP 18%. The evader's posterior
   settles on mixed (72) or FP (28); the pursuer's on random (95).

**Headline 1 — the pursuer side is dramatic.** The Meta pursuer column mean is **3.84 km**,
vs FP_greedy's 4.82 (the previous best) and minimax's 5.21. Paired, Meta minus the minimax
pursuer:
- vs FP_greedy evader: **−3.044 ± 0.073**, hard capture **100%**;
- vs greedy evader: −2.299 ± 0.060;
- vs FP_mixed evader: −0.882;
- vs random evader: −0.459;
- vs minimax evader: **−0.134 ± 0.058** (t = −4.5). It gains even against a randomizer,
  where the oracle lost (+0.117). It ties FP here (−0.020 ± 0.045).

**Type reasoning turns FP's weakness into a capture**: a learner is fully predictable to a
reasoner that models it.

**Headline 2 — the evader side is a safety result, not a separation result.** The Meta
evader row mean is 6.08, tying FP_greedy's 6.07. But against the pursuers it predicts
exactly, it almost never gets close:

| pursuer | evader | soft capture (1 km) | median closest approach | late-game sep |
|---|---|---|---|---|
| FP_greedy | minimax | 91% [84, 95] | 0.66 km | 2.87 |
| FP_greedy | FP_greedy | 100% [96, 100] | 0.65 | 2.39 |
| FP_greedy | **Meta** | **9% [5, 16]** | **1.61** | 2.55 |
| greedy | minimax | 91% | 0.71 | 3.10 |
| greedy | **Meta** | **1% [0, 5]** | **1.57** | 2.82 |
| mixed | minimax | 96% | 0.64 | 3.00 |
| mixed | **Meta** | **53% [43, 62]** | 0.95 | 3.70 |
| FP_mixed (out of set) | Meta | 69% | 0.59 | 4.37 |

Knowing the pursuer's move lets the evader dodge every close pass while holding a
moderate, slightly lower mean distance. The gain is in the worst case, not the average.
The concave payoff √(d + ε) weights close approaches, so this is consistent with the
evader optimizing the game's actual objective. Against a stochastic, out-of-set pursuer
(FP_mixed) the dodge disappears.

**Pursuit–evasion asymmetry (hypothesis, not tested).** Prediction helps the pursuer far
more than the evader. Knowing the evader's target lets the pursuer go there. Knowing the
pursuer's target leaves the evader five alternatives on the same hexagon, which differ
little in mean distance but let it avoid the closest pass.

**For the paper:**
- Report Meta as the strongest pursuer (column mean 3.84) and FP's predictability as the
  reason FP loses to it.
- Report the evader result as capture avoidance (91% → 9% soft capture vs FP), not as
  separation.
- State plainly that the planned headline (evader turns FP's −0.254 positive) failed.

---

## 2026-10-20 — D13 closed: FP learner type added to type-based reasoning; predictions for the Meta sweep

**Code:**
- `tracked_strategies` gains `"FP_greedy"`, appended last so earlier type indices are unchanged.
- New `own_counts(game, idx, n)` builds `ones(n)` plus the player's OWN past choices from
  public game history. This is exactly a plain (γ = 1) FP opponent's belief about that
  player; the reasoner never reads the opponent's private `fp_belief`.
- `fp_type_vertex` mirrors the `FP_greedy` branch operation for operation, so ties resolve
  identically.
- `update_strategy_belief!` and `predict_opponent_vertices` take a `fp_vertex` keyword. A
  tracked FP type with no prediction throws rather than falling back to uniform.

**D13's premise was wrong.** It said the FP type needs the opponent's unobservable
`fp_belief`. For plain FP that belief is a deterministic function of my own history.

**Verified:**
- *Exactness:* new testset, both roles, 12 steps. The type's prediction equals the FP
  opponent's actual move at every step, and `own_counts` equals the opponent's private
  belief bitwise. The posterior reaches > 0.99 on the FP type.
- *Test suite:* 3,428 / 3,428 pass (was 3,369).
- *Inertness:* new `test/check_meta_inert.jl` re-runs games 1–8 of `mixed`/`mixed`,
  `FP_greedy`/`FP_greedy` and `FP_greedy`/`mixed` with the sweep's seeds. They are
  **bitwise identical** to the saved files (chosen, rv_chosen, cost, fp_belief), because
  only Meta_* strategies read `strategy_belief`.

**Positioning correction (author's point):** every receding-horizon game rebuilds its matrix
each step (Peters 2022 included), and HBA's stochastic Bayesian games already let types
depend on state. So "types applied to a time-varying matrix" is **not** a novelty claim.
What remains:
- learning that carries across replanning steps (Peters solves each step memorylessly);
- the C3 point that pooled vertex counts track something unstable while a belief over
  *rules* tracks something stable;
- the FP-learner type in the hypothesis set;
- the application and the price-of-safety measurement.

**Planned run:** `test/run_meta.jl`, 18 cells × 100 trials × 30 steps, with CRN
(`MersenneTwister(1)` per cell), dispersed ICs and slim saves:
- `Meta_greedy` evader vs the 5 tournament pursuers;
- `Meta_greedy` pursuer vs the 5 tournament evaders;
- `Meta_greedy` pursuer vs fixed-vertex evaders 1–6;
- `Meta_greedy` vs `Meta_greedy`;
- `hedge` evader vs `Meta_greedy`, an out-of-set opponent.

**Predicted (written before running):**
1. **Meta evader vs FP_greedy pursuer:** Meta − minimax evader is **positive and
   significant**, reversing FP_greedy's −0.254 ± 0.051. Once the FP type is identified, the
   pursuer's move is known exactly. *This is the headline test. If it is not positive, the
   idea does not work here.*
2. **Meta evader vs mixed pursuer:** **well below FP's +0.735**, somewhere in [−0.2, +0.3].
   Meta identifies the `mixed` type and best-responds to the *current* Nash mixture, which
   is the oracle's move. B6 showed the oracle gains nothing against a randomizer, because
   supported vertices are exactly indifferent. If this holds, FP's +0.735 does not come
   from knowing the opponent's distribution, which is worth a sentence in the paper.
3. **Meta evader vs greedy pursuer:** **larger than FP's +0.003**, since the greedy type
   predicts the pursuer's move exactly.
4. **Meta pursuer vs fixed-vertex evaders:** matches the oracle and **identifies faster than
   FP** (point types settle in 1–2 steps; FP needed about 5 to match the oracle). Recovery
   ≥ FP's 97.5–99.4%.
5. **Out-of-set opponents (FP_mixed, hedge):** smaller gains and no collapse. Meta stays
   within 0.3 km of the minimax baseline in the same cell.
6. **Meta vs Meta:** no confident prediction. Neither is in the other's hypothesis set.
   Report whatever happens, including which type each posterior settles on.

---

## 2026-10-20 — all six figures placed in `MAIN_PAPER.tex`

**Decided (author):** put every figure in now and cut text or figures later, once the page
count is known.

**Placement:**
- Heatmap: `figure*`, in Learning vs minimax.
- Learning, boxplot and ΔV: one column each, in Learning vs minimax.
- Price of safety: one column, in Price of Safety.

Every figure is referenced in the text (Fig. 1 had no reference before). There is one new
paragraph in Learning vs minimax: the approach dominates short windows, the reversal starts
after about step 7, and FP evaders spend less ΔV. The ΔV ranges are quoted as per-matchup means
**without intervals**; add intervals or soften this before submission. One sentence was added
to Price of Safety. **Not compiled**; this probably pushes the paper well past 6 pages.

---

## 2026-10-20 (32-core) — paper figures: old CDC figures regenerated, two new ones

**Run:** new `test/figures_paper.jl`. It reads the Gate B and B6 cells, plus one fresh 10-step
mixed/mixed game run unslimmed for F1. It writes true-size vector PDFs to
`Game_Theory_Space_ECC_2027/images/fig_*.pdf` (15–29 KB each) and PNG previews to
`figures/paper/`. The font is Nimbus Roman (Times). There is one fixed color per strategy,
with line style as the redundant cue.

**Value check:** the S = 30 heatmap reproduces the 09-02 5×5 table cell for cell, and the
row and column means (6.07 / 4.82) match. F6's whole-game paired gains are +0.735 and −0.254,
matching the contrast table. F1's candidate endpoints lie on the hexagon to within 6.5e-12 km.

| fig | what | regenerates |
|---|---|---|
| F1 `fig_game_step` | one game at s = 2/5/10, in the evader-reference RIC frame; line width = Nash weight | `k_replan_*.png`, whose widths were pre-D1 weights. **Swapped into the paper as Fig. 1**, with a rewritten caption |
| F2 `fig_heatmap` | 5×5 mean separation over the first S = 5/10/30 steps, each window on its own color scale | `MC_results_late_game_heatmap.png` |
| F3 `fig_boxplot` | per-game separation by evader and by pursuer strategy, pooled over opponents (n = 500 per box) | `..._boxplot.png`, which boxed 5 cell means per box |
| F4 `fig_dv_vs_sep` | executed ΔV per player vs mean separation, one point per matchup | `..._delta_v_vs_distance.png` |
| F5 `fig_price_of_safety` | per-step separation, log y: (a) vs fixed-vertex evaders (600 games), (b) vs a minimax evader | new |
| F6 `fig_learning` | (a) per-step separation for the 2×2 of minimax/FP; (b) paired FP − minimax gap per step | new |

**Definitional changes from the CDC figures:**
- The metric is **mean separation** (the paper's metric), not "last-quarter game value".
- The windows are the first S steps of the 30-step games. This is exact, because nothing
  in a step depends on the total length.
- F3 boxes per-game values, not cell means.

**New observations (from figures, not yet in the text):**
- *The opening approach dominates short windows.* Separation is ≈36 km at step 1 and
  ≈4 km by step 4. S = 5 and S = 10 means (15 km, 9 km) are mostly the approach, so the S = 30
  game is the meaningful one.
- *F5:* FP-greedy tracks the oracle step for step. Both cross the 0.2 km hard-capture line
  at about step 8 and settle around 0.1 km. The minimax pursuer settles around 3.8 km. Against a
  minimax evader all three pursuers sit on top of each other at about 3 km.
- *F6:* the FP evader's gain over a minimax pursuer opens by step 3 and holds at 0.5–1.1 km.
  Against an FP pursuer it is positive until about step 7, then turns negative and stays there
  (−0.4 to −0.8 km). **The sign reversal is a mid-game effect, appearing once the pursuer's
  beliefs have accumulated.**
- *F4, executed ΔV (first numbers for Gate B):* FP evaders spend less than non-FP evaders
  (150–235 vs 239–266 m/s over 30 steps). Pursuers spend 280–350 m/s. These are cell means
  without intervals, so they are **not paper-ready** as numbers.

**Not done:** none of F2–F6 is in the `.tex` yet; the choice depends on page budget.

---

## 2026-10-19 (32-core) — C3 re-run here; the frozen-matrix tail now covers all 3,000 matrices

**Run:** `test/analyze_c3.jl` on the original Gate B cells (no new sweep). It ran twice: once
with the default 200-matrix sample, and once with the new `C3_N_FROZEN=all` option (every
matrix; FP on a 6×6 is cheap).

**Value check (same machine as 09-17): passes.** The 200-sample run reproduces the 09-17
numbers: median 3.370e-3 at T = 10,000, rate T^-0.56, ‖ΔA‖/‖A‖ 18.47%, ‖Δp*‖₁ 1.3594, |ΔV|
0.1306, and FP/FP NashConv 2.63e-1 / 2.24e-1. The Mac's 10-17 numbers differed only by the
known cross-machine drift.

**C3.1 on all 3,000 matrices** (this replaces the Mac's 10-17 tail table):

| | 10 | 100 | 1,000 | 10,000 | rate |
|---|---|---|---|---|---|
| median | 1.647e-1 | 4.067e-2 | 1.058e-2 | 3.126e-3 | T^-0.57 |
| p90 | 1.883e-1 | 6.310e-2 | 2.178e-2 | 7.521e-3 | T^-0.47 |
| max | 2.937e-1 | 1.319e-1 | 4.490e-2 | 1.510e-2 | T^-0.43 |

**The 10-17 caveat ("200 of 3,000 sampled") is closed.** Every one of the 3,000 real payoff
matrices from the `mixed`/`mixed` cell ends below 1.51e-2 at T = 10,000. The tail
quantiles fall monotonically at every checkpoint, and the worst-case rate (T^-0.43) is the same
as the Mac's 200-sample estimate. The matrices come from one cell; FP/FP's matrices were not
frozen-tested.

**Paper:** `MAIN_PAPER.tex` quotes no C3 numbers. Its pooling sentence (the "decision rule"
justification in the beliefs subsection) rests on C3 qualitatively. If space allows, one
sentence could cite the frozen-matrix check and the 1.36 L1 per-step equilibrium shift.

**Every LOG number the paper uses is now from the 32-core machine.**

---

## 2026-10-19 (32-core) — V₆ − V₂₄ paired CI; solver reliability sweep-wide; uncontended timing

**Machine:** the 32-core Linux machine with the full Gate B/C data. Every number here replaces
the Mac (8-core) number from the entry below, so the paper quotes one machine.

**Check against the prior block's prediction:** "run the script on the full sweep to confirm
it holds sweep-wide". **Holds.** Convergence, miss, ΔV and LP numbers match the 2-cell Mac
numbers to two figures. **Timing does not transfer**, as explained below.

**Run 1, C4 paired intervals:** `test/analyze_c4.jl` now pairs per-game mean LP values across
arities. CRN was checked: `params.ic` is identical for M = 6/12/24. It also bootstraps games
jointly, with 10,000 resamples. Units are √km.

| quantity | value |
|---|---|
| V₆ − V₂₄ | **+0.0251 ± 0.0081** (t = 6.1; 1.2%) |
| V₆ − V₁₂ | +0.0188 ± 0.0098 (t = 3.8) |
| V₁₂ − V₂₄ | +0.0063 ± 0.0077 (t = 1.6, **not resolved**) |
| V_cont (Richardson) | 2.0742, bootstrap [2.058, 2.091] |
| V₆ to V_cont | 1.5%, bootstrap [0.92, 2.12]% |
| ratio of successive differences | 0.34, bootstrap **[0.02, 1.30]** |
| per-game CI on V_M | ±0.011–0.013 (the old per-step ± was 0.026) |

**Correction to 09-17:** "shrinks by 0.34 per doubling, faster than O(h_M)'s 0.50" is not
supported. The ratio's interval spans 0.02–1.30 and includes 0.5. What holds is that V
decreases significantly from 6 to 12 and from 6 to 24, then flattens below resolution. That is
consistent with the bound, but the rate is not pinned. The paper is reworded to say this.
The table ± is now per game, which is the correct unit. The per-step ± was wider: most
step-level variance is within a game and averages out.

**Run 2, solver reliability over all 51 six-vertex cells:** `test/analyze_solver.jl` now
discovers every cell in `test/results/n30/` and reports the 25-cell tournament separately.

| quantity | tournament (25 cells) | all 51 cells |
|---|---|---|
| solves converged | **900,000 / 900,000** (Wilson lb 99.9996%) | 1,835,999 / 1,836,000 |
| escalated to AL | 0 | 0 |
| terminal miss | median 4.55e-12, p95 1.23e-11, max 1.84e-7 km | max 3.31e-7 km |
| max per-segment ΔV | 0.0336 km/s (60× under the cap) | same |
| L-BFGS iterations | median 56, p95 94 | same |
| LP cert violation | median 3.0e-15, max 1.3e-12, 0 > 1e-8, 0 fallbacks (75,000 LPs) | max 1.8e-12 (153,000) |

The one failure is in `p1_regret_matching_p2_mixed`, game 16, step 21, P2, vertex 1. It hit
the 2,000-iteration cap with miss 1.6e-12 km and ΔV 5.6e-6 km/s. It had reached its target,
so only the flag fails, likely from the non-smooth exact penalty near Δv ≈ 0. It is harmless,
and it is outside the tournament.

**Timing: the recorded `t_solve` is contention-dominated.** In-sweep, with 32 games on 32
threads, the median solve is 195 ms and the median step 2.60 s (max 11.9 s, margin ≥ 49×).
That is not a single-core figure. New `test/bench_step.jl` (`-t 1`, mixed/mixed, 5 games ×
30 steps, warm-up discarded) measures uncontended: **11.6 ms per solve (p95 20.7), 0.156 s
per step (p95 0.187, max 0.669)**, against 583 s executed, so a margin of **≥ 870×** (median
3,743×). The Mac's "0.54 s / ≥ 123×" was also contended, by 8 threads. The paper now quotes
the uncontended number, plus "no step over 12 s even with 32 games sharing the processor".

**Paper (`MAIN_PAPER.tex`):** abstract and §Solver now use the tournament figures (900,000
solves, 75,000 LPs) and the uncontended timing. §Lifting has the paired CIs and bootstrap
intervals, and its red TODO is removed. The table ± is per trial. **One red marker remains:**
the ISS keep-out citation.

**Still from the Mac:** the 10-17 C3 tail (FP on frozen matrices). Re-run `analyze_c3.jl`
here before quoting it.

---

## 2026-10-19 — solver reliability re-measured on the current pipeline; paper step 3 drafted

**Why re-measure:** the reliability numbers the docs quoted did not come from the pipeline
behind the results. 99.53% convergence was **BFGS** in the Aug 31 smoke sweep, and the
"4.1 cm terminal miss" was measured **before the solver change**. Every Gate B/C result was
produced with **LBFGS**.

**Run:** new `test/analyze_solver.jl` reads the per-solve `solve_info` records. Inputs: the
two locally regenerated cells (`mixed`/`mixed`, `FP_greedy`/`FP_greedy`, 8-core machine,
2026-10-17), giving 72,000 trajectory solves and 6,000 LPs.

| quantity | value |
|---|---|
| trajectory solves converged | **72,000 / 72,000** (Wilson 95% lower bound 99.995%) |
| escalated to AL (ΔV cap hit) | 0 |
| terminal miss | median 4.5e-12 km, p95 1.2e-11, max 1.5e-7 km (= 2.4e-8 R) |
| max per-segment ΔV | 0.0324 km/s vs 2.0 cap (62×) |
| L-BFGS iterations | median 56, p95 94 |
| wall time per solve | median 40 ms, p95 83 ms (8 threads contending; ~16 ms on the 32-core) |
| LP certificate violation | median 2.8e-15, max 1.3e-12, 0 above 1e-8, 0 fallbacks |
| compute per game step (12 solves + LP, serial) | median 0.54 s, p95 0.76, max 4.72 s |
| trajectory executed per step | 583 s, so the margin is ≥ 123× (median 1,082×) |

**Caveat:** this covers 2 of the 25 tournament cells. Run the script on the 32-core machine's
full sweep to confirm it holds sweep-wide.

**Unit correction:** the LP value V_M (C4) is in **√km**, not km, because the payoff is
√(d + ε). `analyze_c4.jl` and the 2026-09-17 C4 entry label it "km". Mean separations
(tournament, B6) are genuinely km.

**Paper step 3 (`MAIN_PAPER.tex`):**
- New subsection "Approximation Error of the Lifting" (`sec:lifting`). Proposition 1,
  |V_M − V_𝒞| ≤ L·h_M, proved by nearest-vertex projection under a Lipschitz assumption
  (Assumption 1), with an explicit scope paragraph (G2): it covers the circle stage game, not
  the original problem or the closed loop.
- Results: solver reliability and timing (numbers above); lifting convergence (Table, C4);
  learning vs minimax (contrast table, sign reversal, EGTA sentence); capture (hard 0.2 /
  soft 1.0, Wilson CIs); price of safety (B6).
- New abstract, contributions list and discussion.
- Dropped the separate-ΔV promise: no executed-ΔV numbers exist for Gate B.

**Hard-capture comparison corrected for the paper:** LOG 09-16's "18% vs ≤ 9% in every other
cell" is not separated cell-by-cell. FP/FP 18% [11.7, 26.7] overlaps the next cell's 9%
[4.8, 16.2]. Against the other 24 cells *pooled*, 62/2,400 = 2.6% [2.0, 3.3], it separates
cleanly. The paper uses the pooled comparison.

**Remaining red markers:** a paired CI on V₆ − V₂₄ (needs the 32-core C4 data), and a
citation for the ISS 200 m keep-out sphere. **Length:** ~5,200 words by rough count, so likely
over 6 pages once compiled. Not compiled here.

---

## 2026-10-19 — paper merged into one file

The author pasted every section into `MAIN_PAPER.tex`; the `\input{sections/...}` lines are
now commented out, except for `macros`. A scripted check found every non-blank line of the six
section files in the merged file, so the step 1 and step 2 edits came through. From now on,
edit only `MAIN_PAPER.tex`. `sections/*.tex`, other than `macros.tex`, are stale copies.

---

## 2026-10-18 — paper step 2: methods and problem formulation rewritten against the reviews

**Checked against the code first:** `axis_123`, `polygon_vertices`, `stage_cost`,
`compute_cost_matrices`, `solve_mixed_nash` / `solve_mixed_security_strategy`,
`nash_certificate`, `update_beliefs!`, `choose_strategies!`, `min_Δv_dist_solve` and
`prop_kepler_tof_Nseg` (each impulse is applied, then the arc is coasted).

**`prob_form.tex`:**
- Dynamics stated as Keplerian flow with impulses (R7 #1).
- Distance `d_k` separated from the payoff `ℓ_k = sqrt(d_k + ε)`, ε = 0.1 km (R7 m1). The paper
  no longer mentions λ₁/λ₂.
- Game written as max over the evader, min over the pursuer, with a consistent saddle inequality.
- Dropped the unenforced bandwidth 𝓑 and feasible set 𝓕, and the red marks. Kept the
  Sims-Flanagan citation, but as "same transcription" rather than "follows the method".

**`methods.tex`:**
- Frame given by formula, including ê₁·ê₂ = −sin γ (R5 #1). Vertex formula for r_{v_j}.
- Trajectory problem as solved: smoothed ΔV plus an exact-penalty *position* miss; LBFGS,
  forward-mode AD, Lambert initial guess; cap verified afterward (R7 #1, R8 #2).
- Indices: j for the evader, l for the pursuer (R8 #3).
- Both LPs with explicit shifts and value recovery; "game value" reserved for V; saddle-point
  certificate stated (R7 #2–3, #6; R8 #1).
- Beliefs FP-only, with distinct symbols: q̂ is the evader's belief, p̂ the pursuer's (R7 m2,
  R8 #4). The pooling assumption is stated as "a stable decision rule", per C3.
- New Strategies subsection: greedy as a heuristic (G1, R7 #4); FP-mixed formula (G3, R7 #5).

**`results.tex`:** dropped the duplicate strategy list and fixed a reference to the removed
`eq:stage_cost`. All `\ref`/`\eqref` targets resolve (scripted check). **Not compiled.**

**Remaining TODOs:** a forward reference to the lifting-bound section (step 3).

---

## 2026-10-18 — paper step 1: stale CDC content removed from the `.tex`

**Removed:** the abstract's "factor of 2.7 / 3.22" claim; Tables I–III and the boxplot, heatmap
and ΔV figures (with their prose and all commented-out old-number blocks) from
`results.tex`; the discussion's claims that FP "consistently outperforms" baselines and wins
on fuel, and that random beats greedy "at every horizon"; and the related-work claim that FP
"ensures convergence". FP converges only for a fixed matrix, per C3.

**Corrected from the code (`IC.jl`), in the setup paragraph:** dispersed ICs; ΔV cap 2 km/s,
never binding (the paper said 0.1); λ₂ = 0; Ipopt + saddle-point certificate instead of
OSQP; no probability floor; 100 trials with common random numbers instead of 50 identical
orbits; S = 30 only. Added the Ipopt citation (Wächter & Biegler 2006) to `refs.bib`.

**Left for step 2:** everything in the methods section, including the LP, Eq. 7, notation,
the FP-mixed definition and the frame description. The old `images/*.png` result files are
now unreferenced but left on disk. **Not compiled:** LaTeX is not installed here.

---

## 2026-10-18 — CDC reviews restored after the CDC folder was deleted

The author deleted `Game_Theory_Space_CDC_2026/` and `docs/README_plan.md` while cleaning up,
then asked to keep the reviews. The four review files were restored from commit 66eadae into
`Game_Theory_Space_ECC_2027/reviews/`. Everything else, including the CDC submission PDF and
the archived plan, stays deleted and can be recovered from git history. References in
`CLAUDE.md`, `README.md` and the archived narrative now point to the new location.

---

## 2026-10-18 — docs cut to essentials; the paper is now edited in-repo

**Decided (author):** (1) Edit the `.tex` in `Game_Theory_Space_ECC_2027/` directly. This
reverses the "deliver markdown, no LaTeX in this repo" rule. (2) `CLAUDE.md` and `README.md`
were too long and confusing; cut them to essentials.

**Done:** `CLAUDE.md` went from 230 to ~150 lines. "Current state" has no result numbers, and a
new "The paper" section gives the editing rules. `README.md` went from 659 to ~110 lines:
thesis, a one-line-per-result table pointing to LOG dates, gate status, and the paper to-do.
The full previous README is archived verbatim as `docs/README_narrative_2026-10-18.md`. It is
the drafting source for the `.tex`. The review map (its §4.8) and page budget (§4.7) live there.

**Found while surveying the `.tex`:** it is still the CDC text. Every number is void. No
plotting scripts exist for Gate B/C figures. LaTeX is not installed on this machine, so page
count is unverified. Three bib entries are incomplete. The affiliation footnote has an
unassigned ².

---

## 2026-10-17 — CDC review response map (W5); README had `greedy` wrong

**What:** mapped every comment from R5, R7, R8 and the AE to its answer. Map in README §4.8.
No runs.

**Correction — README §3.5 misdescribed `greedy`.** It said "argmax/argmin of expected payoff
against the opponent's Nash mixture". The code (`choose_strategies!`, `argmax(mixing_weights[i])`)
picks the **largest weight in the player's own Nash mixture**, which is exactly the rule R7 #4
criticized. Every `greedy` number is correct for the rule as coded; only the description was
wrong. **Decided:** keep the rule and call it a heuristic baseline. Changing it would re-open
Gate B nine days before ECC.

**Three gaps remain open (README §4.8):**
- **G1** `greedy` rationale — relabelled, as above.
- **G2** The lifting bound's scope. It compares the lifted game with a stage game whose targets
  lie anywhere on the circumcircle. It does not reach the original continuous-control game,
  which has a reachable set rather than a circle and a 30-step closed loop. This is the main
  theory exposure for ECC, and contribution #1 rests on it.
- **G3** `FP_mixed` — the formula (`∝ c − min c + 1e-6`) is now written in §3.5. Its heuristic
  status must be stated.

**Also noted:** the AE asks for tractability *guarantees*. We have only measurements (a
nonconvex local solve). Say so rather than imply more.

---

## 2026-10-17 — C3.1 tail recorded: FP converges on every sampled frozen matrix

**Why:** the 2026-09-17 C3 entry logged only the *median* frozen-matrix NashConv. A reviewer
will ask whether FP converges on every matrix, and the p90/max were printed but never recorded.

**Run:** Gate B data is not on this (8-core) machine. Its `test/results/n30/` held only the
pre-fix CDC-era `games_50.jld2`. So the two cells `analyze_c3.jl` reads were **regenerated
locally** with Gate B's exact settings (CRN `MersenneTwister(1)` per cell, `disperse`, slim,
100 × 30): `mixed`/`mixed` 222 s, `FP_greedy`/`FP_greedy` 240 s on 8 threads. Driver kept
outside the repo (a 10-line call to `run_MC_games_parallel`, identical to `run_gate_b.jl`'s).
New files are `games_100.jld2` beside the untouched `games_50.jld2`. `analyze_c3.jl` now also
prints the p90 and max rates.

**C3.1 result, 200 real matrices, NashConv by FP iteration count:**

| | 10 | 100 | 1,000 | 10,000 | rate |
|---|---|---|---|---|---|
| median | 1.643e-1 | 4.262e-2 | 1.169e-2 | 3.703e-3 | T^-0.55 |
| p90 | 1.878e-1 | 6.792e-2 | 2.309e-2 | 8.168e-3 | T^-0.45 |
| max | 2.223e-1 | 1.020e-1 | 3.402e-2 | 1.158e-2 | T^-0.43 |

**FP converges on every sampled matrix.** The tail is monotone at every checkpoint, slower
than the median (T^-0.43 vs T^-0.55), and the worst matrix ends at 1.2e-2 km. The claim
holds without qualification on the sample. Caveat: 200 of 3,000 matrices are sampled, not all.

**Unplanned finding: regeneration on a different machine is close but NOT bitwise.** Against
the 2026-09-17 numbers from the 32-core machine:

| quantity | 09-17 (32-core) | 10-17 (8-core) |
|---|---|---|
| frozen median @ 10,000 | 3.37e-3 | 3.70e-3 |
| median rate | T^-0.56 | T^-0.55 |
| ‖ΔA‖/‖A‖ median | 18.5% | 18.44% |
| ‖Δp*‖₁ median | 1.359 | 1.362 |
| \|ΔV\| median | 0.131 | 0.1306 |
| FP/FP NashConv, steps 1–5 / 26–30 | 2.63e-1 / 2.24e-1 | 2.66e-1 / 2.15e-1 |

The C3.2 statistics move in the 3rd–4th significant figure, so the **payoff matrices
themselves differ**; this is not just FP's argmax being sensitive to ties. The likeliest
source is floating-point differences across CPU, BLAS or library builds; this is not
isolated. **Every conclusion is unchanged.** But "deterministic under CRN" has only been
verified *on one machine* (B6's bitwise check); it does not hold across machines.
Value-preservation checks must compare files produced on the same machine.

**For the paper:** quote one run consistently. Recommend the 32-core numbers for everything
already in README §5 and this entry's table for the tail, with the source noted.

---

## 2026-10-16 (later) — ECC 2027 CFP read; docs re-pointed at a controls audience

**Correction to the entry below:** the format is now known, from the
[ECC 2027 CFP](https://ecc27.euca-ecc.org/call-for-papers/). Papers are due **Oct 31 2026**
via PaperCept. Review manuscript ≤ 8 pp two-column; **final ≤ 6 pp**, +2 at paid over-length
charges. ieeeconf.cls, US Letter, PDF ≤ 3 MB. Notification Mar 5, final Apr 5 2027;
conference in Brussels, 13–16 July 2027. The CFP is **still silent on blind review**.

**Decided (author asked for a controls-oriented emphasis):**
- Write to **6 pages**, not 8, so nothing has to be cut or paid for after acceptance.
- Contributions are reordered: (1) the lifting bound and its convergence curve, (2) solver
  reliability and timing, (3) the safety/adaptation tradeoff with capture rates. EGTA, C1,
  C2 and `Meta_*` are demoted to one sentence each.
- Gate D becomes **W1–W6** (README §4.7). The W prefix avoids colliding with defect IDs.
- No new experiments are planned. The constraint is page budget, not compute.

**Derived, not newly measured:** compute per game step ≈ 1.5 s single-threaded (from the
~46 s per 30-step game), against ~585 s of trajectory executed per step (5 segments × ~117 s),
roughly 400× margin. This is quoted in README §1 as a real-time-feasibility point. Re-measure
it before it goes in a table.

`docs/README_plan.md` is left untouched; it is archived.

---

## 2026-10-16 — venue change: AAMAS 2027 → ECC 2027 (paper due Oct 31)

**Decision (author):** retarget from AAMAS 2027 (abstract Oct 1 / paper Oct 8, both passed) to
**ECC 2027, paper due Oct 31 2026**. No new runs. Gates A–C stand unchanged; numbers are
venue-independent. Gate D (writing support) is now the current work, for a controls audience.

**Unconfirmed:** ECC 2027 page limit and whether review is double-blind — no 2027 CFP found
on 2026-10-16 (ECC 2026 used PaperCept). Check before sizing figures/tables.

**Framing implication to weigh, not yet decided:** the AAMAS-specific emphasis (EGTA, no-regret
baseline, opponent-modeling literature) matters less; C4/C5 (lifting bound), receding-horizon
solver characterization, and capture definitions matter more — and ECC reviewers overlap the
CDC community whose reviews are in `Game_Theory_Space_CDC_2026/reviews/`.

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
