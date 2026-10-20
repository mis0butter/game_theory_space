# Six literatures each cover half the design

**The combination you plan appears to be unoccupied, but every one of its parts has prior art.** That makes the honest claim narrow. No paper found across six literatures does all of the following together: put a Bayesian posterior over a discrete set of *opponent policy types* (minimax, greedy, random, fixed-target, and an exactly computed fictitious-play learner); define those types as solution concepts applied to a stage matrix that is re-optimized every step; play a receding-horizon lifted zero-sum trajectory game solved by LP; and report a measured minimax-to-oracle gap. Each part, however, has a precedent the reviewers will know. Type-based reasoning over hypothesised behaviours is Albrecht's HBA line. "Lifted" mixed-strategy trajectory games in receding-horizon pursuit-evasion belong to Peters et al. (RSS 2022). Online inference of an opponent's reasoning level in pursuit-evasion is Guan et al. (ACC 2021). Exploiting a known learner in a zero-sum game is Deng et al. (2019) and Assos et al. (2024). The exploitation-versus-safety trade-off is Johanson et al. (2007) and Ganzfried & Sandholm (2015). In orbital pursuit-evasion, "incomplete information" almost always means filtering a continuous cost parameter or picking between two guidance-law modes. The novelty is therefore the *instantiation and the measurement*, not a new framework, and the paper should say so explicitly. Two of your existing headline results are textbook consequences of zero-sum theory rather than discoveries: "omniscience is worth nothing against a proper randomizer" and FP being exploitable above the value. Present them as empirical confirmations in a new setting. The bib key `papuc_strategizing_2026` is a drone-racing model-predictive-game paper with no opponent-type inference; it is a peripheral citation. Several bibliographic details are still unverified, including the swapped names in the `hanlong…` key.

## Type-based reasoning supplies the machinery but never puts a learner in the hypothesis set

The formal home of your planned extension is the **stochastic Bayesian game and Harsanyi–Bellman Ad hoc Coordination (HBA)**. HBA keeps a posterior over a user-defined set of opponent types and plans against it ([Albrecht & Ramamoorthy, arXiv 1506.01170](https://arxiv.org/pdf/1506.01170)). Its types are maps from history and state to action distributions, so "a policy applied to the current stage matrix A_t" is a legitimate SBG type. **Frame your method as an instance of HBA/SBG type-based reasoning, not a new framework.** The paper you must engage most closely is **Albrecht, Crandall & Ramamoorthy, "Belief and truth in hypothesised behaviours" (AIJ 2016)**. It studies when posteriors are correct, the effect of priors, acting with wrong hypotheses, and statistically detecting a wrong hypothesis set. Its experiments use the **78 fixed 2x2 repeated games**, and its hypothesised types are Leader-Follower-Trigger agents, co-evolved decision trees, and neural nets. A **fictitious player appears only as the true, unmodelled opponent**, run for 10,000 rounds. The authors observe that HBA's early actions "shape the beliefs of the other player," but they never put an FP type into the hypothesis set ([arXiv 1507.07688](https://arxiv.org/pdf/1507.07688)). That is the precise gap your FP type fills. The survey to cite for positioning type-based plus recursive reasoning is Albrecht & Stone (AIJ 2018) ([arXiv 1709.08071](https://arxiv.org/abs/1709.08071v2)).

Adversarial instances of this idea also exist. Ganzfried's Bayesian opponent exploitation in zero-sum imperfect-information games best-responds to a Dirichlet posterior. In normal-form games that update reduces essentially to fictitious play ([arXiv 1603.03491](https://arxiv.org/pdf/1603.03491)). Expect a reviewer to note that your existing `FP_greedy` *is* a degenerate Bayesian exploiter. **Bayes-ToMoP (Yang et al., IJCAI 2019)** combines Bayesian policy reuse with theory-of-mind recursion to detect opponents that are either stationary or *higher-order reasoners about the agent itself*. It is the nearest ML precedent for "a type that models me" ([IJCAI](https://www.ijcai.org/proceedings/2019/88)).

The level-k and cognitive-hierarchy literature gives the right vocabulary for the FP type. In standard level-k, level-0 is uniform random and each level best-responds to the one below. Your FP type instead best-responds to the *empirical frequency of your own past vertices*. It is a learning level-1, and your agent reasoning about it is level-2. The conceptual ancestor is **sophisticated EWA and strategic teaching (Camerer, Ho & Chong, JET 2002)**, where sophisticated players know others are adaptive learners and farsighted ones deliberately shape those learners' beliefs ([Caltech record](https://authors.library.caltech.edu/records/acy85-62128)). Those experiments use general-sum trust and entry games, and the papers do not identify types by Bayesian inference. In control, the "Bayesian level inference plus receding horizon" combination already exists. **Li, Li, Girard & Kolmanovsky (CDC 2019)** infer a driver's cognitive level by Bayesian inference and act with predictive control ([arXiv 1908.04005](https://arxiv.org/abs/1908.04005)). **Guan, Maity, Kroninger & Tsiotras (ACC 2021)** discretize a stochastic aerial pursuit-evasion game into finite MDPs, solve it with level-k/CH, and give an **online algorithm for each agent to infer the opponent's rationality level** ([NSF PAR](https://par.nsf.gov/biblio/10315945)). Guan et al. is the closest pursuit-evasion precedent. So "Bayesian opponent-level inference in pursuit-evasion" is *not* new. What remains is that their types are reasoning depths rather than learners, and the setting is aerial MDPs rather than a lifted orbital matrix game.

## Exploitation theory already predicts your Gate B and B6 numbers

The theory of an "optimizer" who knows the learner's algorithm explains your existing results, so cite it rather than present those results as surprises. **Deng, Schneider & Sivan (NeurIPS 2019)** show that against any no-regret learner the optimizer guarantees its Stackelberg value. Against no-swap-regret learners it cannot do better, while against *mean-based* learners (a class containing FP-like follow-the-leader) it can do strictly better in general-sum games ([arXiv 1909.13861](https://arxiv.org/abs/1909.13861)). In a zero-sum game the Stackelberg value equals the minimax value. Your B6 sign reversal against a `mixed` evader (−0.117 ± 0.060 km) is therefore the empirical face of a known ceiling; this zero-sum corollary is our inference, not a theorem stated in the paper. **Assos, Dagan & Daskalakis (NeurIPS 2024)** go further for repeated zero-sum games. They compute the optimal play against Replicator Dynamics exactly, and they build an optimizer that **strictly exceeds the one-shot value against discrete-time MWU** ([arXiv 2407.04889](https://arxiv.org/abs/2407.04889)). This is the strongest theoretical support for "a level-2 model can profit from a known learner even in a zero-sum game." Classic deterministic FP is not Hannan-consistent, so exploiting it above the value is expected. A *smoothed* FP is no-regret, and the edge against it should vanish asymptotically; that is worth one sentence in the paper. FP-specific exploitation results exist only for **2x2 games** (Dong & Mu, [SSRN](https://doi.org/10.2139/ssrn.4201849), content unverified; Guo & Mu for Hedge, [arXiv 2312.09472](https://www.arxiv.org/pdf/2312.09472)). Nobody has published a closed-form level-2 FP predictor for general n×n zero-sum games, let alone time-varying ones.

The "price of safety" is a new *name* for an old *trade-off*. **Johanson, Zinkevich & Bowling's restricted Nash response (NIPS 2007)** traces the exploitation-vs-exploitability frontier. Its p = 0 endpoint is Nash and its p = 1 endpoint is the best response ([NeurIPS](https://proceedings.neurips.cc/paper/2007/hash/6e7b33fdea3adc80ebd648fffb665bb8-Abstract.html)). Your **+3.16–3.31 km** gap between the minimax floor and the oracle ceiling is exactly those two endpoints, measured in a continuous-dynamics game. **Ganzfried & Sandholm (ACM TEAC 2015)** characterize safe deviation in repeated zero-sum games: you may risk only the "gift" already banked above the value ([dblp](https://dblp.org/pid/00/744)). **Damer & Gini (AAMAS 2017)** handle safely using predictions in *normal-form* games, which makes them the formal match to a per-step 6x6 ([AAMAS PDF](https://ifmas.csc.liv.ac.uk/Proceedings/aamas2017/pdfs/p924.pdf)). AWESOME's "best-respond if the opponent looks stationary, else fall back to equilibrium" is the classic switch your type posterior generalizes ([arXiv cs/0307002](https://arxiv.org/abs/cs/0307002)). Recent poker work re-solves online while bounding exploitability: SES ([NeurIPS 2022](https://proceedings.neurips.cc/paper_files/paper/2022/hash/b12a1d1014e952e676f5d6931d03241a-Abstract.html)), OX-Search ([ICML 2024](https://mlanthology.org/icml/2024/ge2024icml-safe/)), and CDRNR ([AAMAS 2024](https://aamas.csc.liv.ac.uk/Proceedings/aamas2024/pdfs/p2393.pdf)). The July 2026 preprint CS-RNR exploits only once an opponent statistically separates from equilibrium, using anytime-valid confidence sequences ([arXiv 2607.28520](https://arxiv.org/abs/2607.28520)). That is a ready-made frame for "FP and the oracle hard-capture 100% of fixed-vertex evaders but gain nothing against randomizers." **No safe-exploitation work was found in continuous, differential, pursuit-evasion or space games.** The phrase "price of safety" is not an established term, so define it in the paper.

The time-varying-games theory explains why FP's cross-step pooling needs a justification other than equilibrium stationarity. Cardoso et al. (ICML 2019) show that per-player regret minimization fails to compete with Nash when the matrix changes each round ([PMLR](https://proceedings.mlr.press/v97/cardoso19a.html)). Fiez et al. (NeurIPS 2021) show that time averages can fail even in periodic zero-sum games with a *fixed* equilibrium ([arXiv 2111.03377](https://ar5iv.arxiv.org/html/2111.03377)). Zhang et al. (ICML 2022) define **dynamic NE regret** (cumulative gap to the per-round minimax value), a ready-made metric for your "value barely moves while the Nash mixture reshuffles" observation ([PMLR](https://proceedings.mlr.press/v162/zhang22an.html)). Duvocelle et al.'s tracking result requires strongly monotone stage games, and finite matrix games are not ([RePEc](https://ideas.repec.org/a/inm/ormoor/v48y2023i2p914-941.html)). Classic FP convergence (Robinson 1951; Daskalakis & Pan's Ω(t^{-1/n}) counterexample, [arXiv 1412.4840](https://arxiv.org/abs/1412.4840)) assumes a fixed matrix, so state plainly that it does not transfer. None of this theory treats FP specifically in time-varying games. The upshot for the narrative: FP works here because *opponent policies* are stationary (fixed-vertex, greedy), not because the equilibrium is. That argues directly for types conditioned on A_t over pooled vertex counts.

## Orbital and robotics work infers parameters and objectives, not policy types

The orbital pursuit-evasion literature is large but defines "incomplete information" differently from you. Most papers estimate a **continuous parameter** of a differential game, typically the opponent's LQ weighting matrices, with a UKF ([Li, Zhu & Luo, Sci China Tech Sci 2021](https://doi.org/10.1007/s11431-020-1662-0); [Liu et al., JGCD 2025](https://doi.org/10.2514/1.G008824)) or a learned GRU/LSTM. The closest structural analogue is **finite-mode multiple-model estimation**. Ye et al. (Acta Astronautica 2021) run a bank of parallel filters over a target whose unknown information "is assumed to belong to a finite set" ([DOI](https://doi.org/10.1016/j.actaastro.2020.12.015)). **Wang, Chen & Liao (Aerospace 2024)** use an LSTM-augmented IMM to estimate whether the evader is running an LQ or a ZEM law, then switch the pursuer to the matching response ([MDPI](https://www.mdpi.com/2226-4310/11/11/894)). That is "infer which opponent policy, then respond," but with two deterministic guidance laws, no matrix game, no mixed strategies and no learner. The most conceptually adjacent space paper is **Han & Dang (Sci. Reports 2026)**. It solves a 2x2 mixed Nash analytically, keeps a Bayesian belief over *which object is the real evader*, and defines three pursuer "intelligence levels". It evaluates those levels but never infers them ([PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC13186990/)). Matrix games in space otherwise mean target assignment under **complete information** with a GA solver ([Zhang et al. 2024](https://doi.org/10.1007/s42423-024-00159-x), your `hanlong…` entry), or a PSRO-style meta-game over trained RL policies ([Yu et al., AST 2026](https://doi.org/10.1016/j.ast.2025.111052)). RL work builds in robustness at training time through self-play or populations ([Mehlman & Falco 2025](https://doi.org/10.2514/1.I011632)). The one 2026 "opponent-modeling module" estimates *maneuvers* with a Kalman filter ([Li, Lin & Huang 2026](https://doi.org/10.1007/s40747-026-02338-9)). **No orbital PE paper was found that uses fictitious play online or infers a posterior over opponent policy types**, and none builds the payoff matrix from per-cell trajectory optimizations to geometric candidate targets.

Robotics owns the lifting. **Peters, Fridovich-Keil, Ferranti, Stachniss, Alonso-Mora & Laine (RSS 2022)** introduce the "lifted game". Each player optimizes several candidate trajectories, a bimatrix game is solved with a Lemke-Howson routine, play is receding-horizon, and the testbed is a **zero-sum pursuit-evasion "tag"** game. They state that "each player is oblivious to their opponent's decision making process" ([ar5iv](https://ar5iv.labs.arxiv.org/html/2205.00291); [code](https://github.com/lassepe/LiftedTrajectoryGames.jl)). The author list has no "Calderone". The differences you can claim are an LP for the zero-sum case, geometric hexagon candidates rather than learned ones, Keplerian dynamics, and the study of non-equilibrium opponents. The online-inference strand of robotics games infers **continuous cost parameters under a pure-strategy (G)NE assumption**. That includes LUCIDGames' UKF ([arXiv 2011.08152](https://arxiv.org/abs/2011.08152)), Liu, Peters & Alonso-Mora's MLE through a differentiable solver ([arXiv 2211.13779](https://arxiv.org/abs/2211.13779v1)), and the Bayesian inverse games ([arXiv 2402.08902](https://arxiv.org/abs/2402.08902v2); [arXiv 2601.00696](https://arxiv.org/abs/2601.00696)). Discrete-hypothesis precursors exist, again over objectives in pure-strategy games: Laine et al.'s multi-hypothesis interactions ([arXiv 2011.06047](https://arxiv.org/abs/2011.06047v1)) and Contingency Games ([arXiv 2304.05483](https://arxiv.org/abs/2304.05483v4)). Huang & Zhu's deceptive pursuit-evasion uses private types, PBNE and receding horizon, but not a lifted matrix game ([arXiv 1907.00459](https://arxiv.org/abs/1907.00459v2)). Fictitious play appears in none of these trajectory-game papers; they use iterated best response *inside* one solve.

A screen of the forward citations of Peters 2022 found **14 citers on Semantic Scholar** ([API](https://api.semanticscholar.org/graph/v1/paper/arXiv:2205.00291/citations?fields=title,authors,year,venue,externalIds&limit=100)) against **25 on Google Scholar**. None combines lifted mixed strategies with opponent-type inference. The single closest paper is **Sun, Trautman & Murphey, "Inverse Mixed Strategy Games with Generative Trajectory Models" (ICRA 2025 per Semantic Scholar)**. It infers game specifications online for mixed strategies represented by a CVAE. It has no finite candidate set, no type library and no FP ([arXiv 2502.03356](https://arxiv.org/abs/2502.03356)). One worrying search snippet, a multi-UAV "opponent intent inference" paper supposedly using a zero-sum mixed-strategy matrix game, was checked in full text and was **wrong**. The paper (Li, Feng & Zhang, *Sensors* 2026) is a CVAE plus hierarchical-SAC pipeline with zero occurrences of "matrix game", "Nash", "zero-sum" or "fictitious" ([PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC13075325/)).

The table below ranks what must be cited and the one-line differentiation for each.

| Prior work | What it shares | What it lacks relative to yours |
|---|---|---|
| Peters et al., RSS 2022 | Lifted candidate-trajectory mixed strategies, zero-sum PE, receding horizon | Any opponent model; FP; price of safety |
| Albrecht, Crandall & Ramamoorthy, AIJ 2016 | Bayesian posterior over hypothesised types; FP as opponent | FP inside the hypothesis set; time-varying stage game; zero-sum trajectory setting |
| Guan et al., ACC 2021 | Online opponent-level inference in pursuit-evasion | Learner types; LP-lifted matrix; orbital dynamics |
| Li et al., CDC 2019 | Bayesian level inference + receding horizon (control venue) | Zero-sum; learner types; finite candidate game |
| Camerer, Ho & Chong, JET 2002 | Sophisticated players modelling adaptive learners | Bayesian identification; zero-sum; dynamics |
| Deng et al. 2019; Assos et al. 2024 | Exploiting a known learner; zero-sum ceilings | Uncertainty over *which* type; time-varying matrices |
| Johanson et al. 2007; Ganzfried & Sandholm 2015; Damer & Gini 2017 | Exploitation vs safety frontier | Continuous / PE / space setting |
| Sun, Trautman & Murphey, ICRA 2025 | Mixed-strategy trajectory game + online inference | Finite candidates; discrete policy types; FP |
| Liu et al. RA-L 2023; LUCIDGames 2021 | Online opponent inference in receding-horizon games | Mixed strategies; non-equilibrium policy types |
| Wang et al. 2024; Ye et al. 2021 | Finite-set opponent-mode posterior in spacecraft PE | Matrix game; mixed play; learners; >2 types |
| Han & Dang 2026 | Orbital mixed Nash + Bayesian belief + opponent sophistication levels | Belief over opponent *policy* (theirs is over decoy identity) |
| Cardoso 2019; Zhang 2022; Fiez 2021 | Learning in time-varying zero-sum games | FP specifically; state-dependent receding-horizon stage games |

## What the paper can honestly claim

Three things are defensible as "to our knowledge" claims. First, a type library whose members are **stage-game solution concepts re-evaluated on a time-varying lifted matrix**. Second, the inclusion of an **exactly computed FP-learner type**, a level-2 model in the strategic-teaching sense, inside the Bayesian hypothesis set. Third, the **first measurement of the exploitation-versus-safety gap in orbital pursuit-evasion**. Three things are *not* defensible as novel: the lifting itself (Peters 2022), Bayesian opponent-level inference in pursuit-evasion (Guan 2021), and the fact that a randomizer is unexploitable or that FP is exploitable (zero-sum theory). Recommended wording for the contributions paragraph:

> "Building on the lifted trajectory games of Peters et al. [peters2022mixed], we cast orbital pursuit-evasion as a receding-horizon zero-sum matrix game over optimized candidate trajectories, solved by LP at every step. We then equip each player with type-based opponent reasoning in the sense of Albrecht et al. [albrecht2016belief]: a Bayesian posterior over a library of hypothesised opponent policies (minimax, greedy, random, fixed-target, and a fictitious-play learner), each defined as a map from the current stage matrix to a vertex distribution. Unlike prior type-based studies, which use a fixed stage game and treat learners only as unmodelled opponents, our library includes a fictitious-play type that the agent predicts exactly from its own action history, a level-2 model in the sense of strategic teaching [camerer2002sophisticated]. Unlike prior online-inference trajectory games, which estimate continuous opponent objectives under an equilibrium assumption [liu2023unknown, lecleach2021lucidgames, sun2025inverse], we infer *how* the opponent decides, including non-equilibrium and learning behaviours. To our knowledge, this is the first work in orbital pursuit-evasion to quantify the gap between the minimax security level and an omniscient best response — what we term the price of safety, the endpoints of the exploitation–exploitability frontier of [johanson2007robust] — and to show how much of it type-based reasoning recovers."

For the results section, wording such as "consistent with the zero-sum Stackelberg ceiling [deng2019strategizing], no opponent model, including an oracle, gains against an evader playing the stage Nash mixture" turns a potential reviewer objection into a validation. Do not write "first Bayesian opponent modelling in pursuit-evasion", "first lifted game", or "novel framework".

## Reviewers will probe identifiability, non-stationarity and inverse games

The sharpest technical objection is that **the FP type makes the opponent's behaviour depend on your own past actions**. The likelihood is still well defined, because the type is a deterministic function of a history you observe, but the process is not stationary. Albrecht et al. 2016 is the reference on when posteriors stay correct. The repo already logs a related modelling gap as D13 ("FP opponents unidentifiable"). On a given step, the FP type and greedy or minimax types can prescribe the same vertex, so the posterior can stall. Report posterior trajectories and confusion rates per true type rather than only final payoffs. A second objection is that **"exactly computable" assumes the opponent's FP shares your matrix, prior, tie-breaking and counting rule**. State this assumption, and consider a misspecified-FP robustness run. A third is that **inverse-game papers could encode greedy or fixed-target behaviour as cost parameters**, so the objective-versus-policy distinction must be argued, not asserted. A fourth is that **per-stage security does not obviously compose into a closed-loop guarantee across the receding horizon**. No result on this was found, so do not claim one. Finally, a cheap restricted-Nash-response interpolation (mixing the LP security strategy with the type-based best response) would trace the frontier between your two price-of-safety endpoints and pre-empt "why only endpoints?".

The verification to-dos before submission are these:

| Item | Status / action |
|---|---|
| Google Scholar citers of Peters 2022 | GS reports 25, S2 indexed 14; about 11 unscreened (CAPTCHA). Open [this link](https://scholar.google.com/scholar?cites=17465300582096261158) manually |
| Forward citers of Albrecht 2016 and Deng 2019 | Not screened for "fictitious play type"; do one Semantic Scholar pass |
| Albrecht PhD thesis (2015) and AAAI 2015 prior-beliefs paper | Not opened; could contain a learner type |
| Bayes-ToMoP experiments | Unchecked whether its "sophisticated" opponent is FP-like |
| Tang et al., AST 2021 (spacecraft switching strategies) | One snippet claims a matrix game + IMM; abstract inaccessible. Read before citing |
| LUCIDGames/MPOGames/Contingency Games details; Chinese-language journals | Not fully surveyed |
| `hanlongResearchStrategiesMultiSpacecraft2024` | Given/family names swapped by Zotero (Crossref repeats the swap). The first author is almost certainly **Zhang Hanlong** (family Zhang), so the entry should read "Zhang et al. 2024". Rekey and fix all five authors |
| Peters 2022 author list | Remove any "Calderone"; authors are Peters, Fridovich-Keil, Ferranti, Stachniss, Alonso-Mora, Laine |
| DOIs from memory | Ganzfried & Sandholm TEAC (10.1145/2716322, art. 8), Albrecht–Stone AIJ 2018, Camerer et al. QJE 2004, AAMAS 2013 pages, Schwarting PNAS, Contingency Games volume, Laine ICRA 2021 venue, Spica T-RO author list, Conitzer ML pages |
| Conflicts between sources | Johanson 2007 pages (721–728 on NeurIPS vs 1128–1135 on Bowling's page); Sun 2025 venue (ICRA per S2 only); Jain 2026 first name ("Yash" unconfirmed); Dong & Mu content (SSRN 403) |
| `papuc_strategizing_2026` | refs.bib has it as arXiv `@misc`; S2 lists RA-L 2026, DOI 10.1109/LRA.2026.3701568. Confirm, then upgrade the entry |
| `farago2021coordination` | A generic FP-on-coordination-games paper; supplement or replace it with Brown 1951 / Robinson 1951 |

### What `papuc_strategizing_2026` is

It is **Andrei-Carlo Papuc, Lasse Peters, Sihao Sun, Laura Ferranti and Javier Alonso-Mora, "Strategizing at Speed: A Learned Model Predictive Game for Multi-Agent Drone Racing,"** arXiv 2602.06925 (Feb 2026). Semantic Scholar lists it as RA-L 2026 ([arXiv](http://arxiv.org/abs/2602.06925)). It compares an interaction-aware Model Predictive Game against non-interactive contouring MPC. The game wins at moderate speed and loses at high speed because of latency, and a learned MPG amortizes the solve. "Learned" refers to the solver, not the opponent. It has no zero-sum PE, no opponent typing and no space setting. Its value to you is its framing question, "how deeply should an agent strategize before acting?", which parallels the minimax-versus-exploitation trade-off. Cite it in one clause of related work at most.

## BibTeX-ready entries with verification status

Status tags: **[V]** means confirmed this session against a publisher, arXiv, dblp or Crossref page; **[V-partial]** means the paper is confirmed but some field is not; **[K]** means from prior knowledge, so check before use.

```bibtex
% ---------- Lifted trajectory games / robotics ----------
@inproceedings{peters2022mixed,            % [V] Crossref/OpenAlex
  author    = {Peters, Lasse and Fridovich-Keil, David and Ferranti, Laura and Stachniss, Cyrill and Alonso-Mora, Javier and Laine, Forrest},
  title     = {Learning Mixed Strategies in Trajectory Games},
  booktitle = {Robotics: Science and Systems XVIII},
  year      = {2022},
  doi       = {10.15607/RSS.2022.XVIII.051}
}
@article{liu2023unknown,                   % [V] S2 metadata; vol/pages [V-partial]
  author  = {Liu, Xinjie and Peters, Lasse and Alonso-Mora, Javier},
  title   = {Learning to Play Trajectory Games Against Opponents With Unknown Objectives},
  journal = {IEEE Robotics and Automation Letters},
  volume  = {8}, number = {7}, pages = {4139--4146},
  year    = {2023},
  doi     = {10.1109/LRA.2023.3280809}
}
@article{lecleach2021lucidgames,           % [V]
  author  = {Le Cleac'h, Simon and Schwager, Mac and Manchester, Zachary},
  title   = {{LUCIDGames}: Online Unscented Inverse Dynamic Games for Adaptive Trajectory Prediction and Planning},
  journal = {IEEE Robotics and Automation Letters},
  volume  = {6}, number = {3}, pages = {5485--5492},
  year    = {2021}
}
@inproceedings{sun2025inverse,             % [V-partial] venue/DOI from Semantic Scholar only
  author    = {Sun, Max Muchen and Trautman, Pete and Murphey, Todd D.},
  title     = {Inverse Mixed Strategy Games with Generative Trajectory Models},
  booktitle = {IEEE International Conference on Robotics and Automation (ICRA)},
  year      = {2025},
  doi       = {10.1109/ICRA55743.2025.11128615}
}
@misc{laine2020multihypothesis,            % [V-partial] ICRA 2021 venue unverified
  author = {Laine, Forrest and Fridovich-Keil, David and Chiu, Chih-Yuan and Tomlin, Claire},
  title  = {Multi-Hypothesis Interactions in Game-Theoretic Motion Planning},
  year   = {2020},
  note   = {arXiv:2011.06047}
}
@article{peters2024contingency,            % [V-partial] volume/pages/DOI unverified
  author  = {Peters, Lasse and Bajcsy, Andrea and Chiu, Chih-Yuan and Fridovich-Keil, David and Laine, Forrest and Ferranti, Laura and Alonso-Mora, Javier},
  title   = {Contingency Games for Multi-Agent Interaction},
  journal = {IEEE Robotics and Automation Letters},
  year    = {2024},
  note    = {arXiv:2304.05483}
}
@misc{papuc_strategizing_2026,             % [V] arXiv; RA-L 2026 (DOI 10.1109/LRA.2026.3701568) per S2 only
  author = {Papuc, Andrei-Carlo and Peters, Lasse and Sun, Sihao and Ferranti, Laura and Alonso-Mora, Javier},
  title  = {Strategizing at Speed: A Learned Model Predictive Game for Multi-Agent Drone Racing},
  year   = {2026},
  doi    = {10.48550/arXiv.2602.06925}
}

% ---------- Type-based reasoning / level-k ----------
@article{albrecht2016belief,               % [V]
  author  = {Albrecht, Stefano V. and Crandall, Jacob W. and Ramamoorthy, Subramanian},
  title   = {Belief and Truth in Hypothesised Behaviours},
  journal = {Artificial Intelligence},
  volume  = {235}, pages = {63--94},
  year    = {2016},
  doi     = {10.1016/j.artint.2016.02.004}
}
@inproceedings{albrecht2013hba,            % [V] paper; pages [K]
  author    = {Albrecht, Stefano V. and Ramamoorthy, Subramanian},
  title     = {A Game-Theoretic Model and Best-Response Learning Method for Ad Hoc Coordination in Multiagent Systems},
  booktitle = {Proc. Int. Conf. on Autonomous Agents and Multiagent Systems (AAMAS)},
  pages     = {1155--1156},
  year      = {2013},
  note      = {Extended version: arXiv:1506.01170}
}
@article{albrecht2018survey,               % [V] paper; DOI [K]
  author  = {Albrecht, Stefano V. and Stone, Peter},
  title   = {Autonomous Agents Modelling Other Agents: A Comprehensive Survey and Open Problems},
  journal = {Artificial Intelligence},
  volume  = {258}, pages = {66--95},
  year    = {2018},
  doi     = {10.1016/j.artint.2018.01.002}
}
@inproceedings{yang2019bayestomop,         % [V] venue/DOI; full author list [K]
  author    = {Yang, Tianpei and Hao, Jianye and Meng, Zhaopeng and Zhang, Chongjie and Zheng, Yan and Zheng, Ze},
  title     = {Towards Efficient Detection and Optimal Response against Sophisticated Opponents},
  booktitle = {Proc. Int. Joint Conf. on Artificial Intelligence (IJCAI)},
  pages     = {623--629},
  year      = {2019},
  doi       = {10.24963/ijcai.2019/88}
}
@article{camerer2002sophisticated,         % [V]
  author  = {Camerer, Colin F. and Ho, Teck-Hua and Chong, Juin-Kuan},
  title   = {Sophisticated Experience-Weighted Attraction Learning and Strategic Teaching in Repeated Games},
  journal = {Journal of Economic Theory},
  volume  = {104}, number = {1}, pages = {137--188},
  year    = {2002},
  doi     = {10.1006/jeth.2002.2927}
}
@article{camerer2004cognitive,             % [K] DOI
  author  = {Camerer, Colin F. and Ho, Teck-Hua and Chong, Juin-Kuan},
  title   = {A Cognitive Hierarchy Model of Games},
  journal = {Quarterly Journal of Economics},
  volume  = {119}, number = {3}, pages = {861--898},
  year    = {2004},
  doi     = {10.1162/0033553041502225}
}
@inproceedings{guan2021bounded,            % [V]
  author    = {Guan, Yue and Maity, Dipankar and Kroninger, Christopher M. and Tsiotras, Panagiotis},
  title     = {Bounded-Rational Pursuit-Evasion Games},
  booktitle = {American Control Conference (ACC)},
  year      = {2021},
  doi       = {10.23919/ACC50511.2021.9483152}
}
@inproceedings{li2019cognitive,            % [V] paper; pages/DOI not retrieved
  author    = {Li, Sisi and Li, Nan and Girard, Anouck and Kolmanovsky, Ilya},
  title     = {Decision Making in Dynamic and Interactive Environments Based on Cognitive Hierarchy Theory, {B}ayesian Inference, and Predictive Control},
  booktitle = {IEEE Conference on Decision and Control (CDC)},
  year      = {2019},
  note      = {arXiv:1908.04005}
}

% ---------- Exploiting learners / safe exploitation ----------
@inproceedings{deng2019strategizing,       % [V]
  author    = {Deng, Yuan and Schneider, Jon and Sivan, Balasubramanian},
  title     = {Strategizing against No-regret Learners},
  booktitle = {Advances in Neural Information Processing Systems (NeurIPS)},
  volume    = {32}, year = {2019},
  note      = {arXiv:1909.13861}
}
@inproceedings{assos2024maximizing,        % [V]
  author    = {Assos, Angelos and Dagan, Yuval and Daskalakis, Constantinos},
  title     = {Maximizing Utility in Multi-Agent Environments by Anticipating the Behavior of Other Learners},
  booktitle = {Advances in Neural Information Processing Systems (NeurIPS)},
  volume    = {37}, year = {2024},
  note      = {arXiv:2407.04889}
}
@article{ganzfried2015safe,                % [V-partial] article no. and DOI [K]
  author  = {Ganzfried, Sam and Sandholm, Tuomas},
  title   = {Safe Opponent Exploitation},
  journal = {ACM Transactions on Economics and Computation},
  volume  = {3}, number = {2}, pages = {8:1--8:28},
  year    = {2015},
  doi     = {10.1145/2716322}
}
@inproceedings{johanson2007robust,         % [V] NeurIPS listing; pages conflict with Bowling page
  author    = {Johanson, Michael and Zinkevich, Martin and Bowling, Michael},
  title     = {Computing Robust Counter-Strategies},
  booktitle = {Advances in Neural Information Processing Systems 20 (NIPS)},
  pages     = {721--728},
  year      = {2007}
}
@inproceedings{damer2017safely,            % [V]
  author    = {Damer, Steven and Gini, Maria},
  title     = {Safely Using Predictions in General-Sum Normal Form Games},
  booktitle = {Proc. Int. Conf. on Autonomous Agents and Multiagent Systems (AAMAS)},
  pages     = {924--932},
  year      = {2017}
}
@article{conitzer2007awesome,              % [V-partial] pages [K]
  author  = {Conitzer, Vincent and Sandholm, Tuomas},
  title   = {{AWESOME}: A General Multiagent Learning Algorithm that Converges in Self-Play and Learns a Best Response Against Stationary Opponents},
  journal = {Machine Learning},
  volume  = {67}, pages = {23--43},
  year    = {2007},
  doi     = {10.1007/s10994-006-0143-1}
}

% ---------- Time-varying games / FP ----------
@inproceedings{cardoso2019competing,       % [V]
  author    = {Cardoso, Adrian Rivera and Abernethy, Jacob and Wang, He and Xu, Huan},
  title     = {Competing Against {N}ash Equilibria in Adversarially Changing Zero-Sum Games},
  booktitle = {Proc. Int. Conf. on Machine Learning (ICML)},
  series    = {PMLR}, volume = {97}, pages = {921--930},
  year      = {2019}
}
@inproceedings{zhang2022noregret,          % [V]
  author    = {Zhang, Mengxiao and Zhao, Peng and Luo, Haipeng and Zhou, Zhi-Hua},
  title     = {No-Regret Learning in Time-Varying Zero-Sum Games},
  booktitle = {Proc. Int. Conf. on Machine Learning (ICML)},
  series    = {PMLR}, volume = {162}, pages = {26772--26808},
  year      = {2022}
}
@inproceedings{fiez2021periodic,           % [V]
  author    = {Fiez, Tanner and Sim, Ryann and Skoulakis, Stratis and Piliouras, Georgios and Ratliff, Lillian},
  title     = {Online Learning in Periodic Zero-Sum Games},
  booktitle = {Advances in Neural Information Processing Systems 34 (NeurIPS)},
  pages     = {10313--10325},
  year      = {2021}
}
@article{robinson1951iterative,            % [K]
  author  = {Robinson, Julia},
  title   = {An Iterative Method of Solving a Game},
  journal = {Annals of Mathematics},
  volume  = {54}, number = {2}, pages = {296--301},
  year    = {1951}
}

% ---------- Orbital pursuit-evasion ----------
@article{wang2024imm,                      % [V] Crossref
  author  = {Wang, Chuangge and Chen, Danhe and Liao, Wenhe},
  title   = {Interactive Multiple-Model Learning Filter for Spacecraft Pursuit--Evasion Game Strategy Switch Based on Long Short-Term Memory Network},
  journal = {Aerospace},
  volume  = {11}, number = {11}, pages = {894},
  year    = {2024},
  doi     = {10.3390/aerospace11110894}
}
@article{ye2021multiple,                   % [V] Crossref
  author  = {Ye, Dong and Tang, Xu and Sun, Zhaowei and Wang, Chunbao},
  title   = {Multiple model adaptive intercept strategy of spacecraft for an incomplete-information game},
  journal = {Acta Astronautica},
  volume  = {180}, pages = {340--349},
  year    = {2021},
  doi     = {10.1016/j.actaastro.2020.12.015}
}
@article{li2021escape,                     % [V] Crossref
  author  = {Li, ZhenYu and Zhu, Hai and Luo, YaZhong},
  title   = {An escape strategy in orbital pursuit-evasion games with incomplete information},
  journal = {Science China Technological Sciences},
  volume  = {64}, pages = {559--570},
  year    = {2021},
  doi     = {10.1007/s11431-020-1662-0}
}
@article{han2026deception,                 % [V] full text read via PMC
  author  = {Han, Hongyu and Dang, Zhaohui},
  title   = {Deception in orbital games: simulation and dissimulation with a maneuverable decoy},
  journal = {Scientific Reports},
  volume  = {16}, pages = {15584},
  year    = {2026},
  doi     = {10.1038/s41598-026-46097-6}
}
@article{zhang2024matrix,                  % [V] Crossref; REPLACES hanlongResearchStrategiesMultiSpacecraft2024 (names un-swapped, family name Zhang - confirm)
  author  = {Zhang, Hanlong and Zhou, Wenya and Zhu, Mengping and Xie, Zhengyou and Guo, Jitang},
  title   = {Research on Strategies of Multi-Spacecraft Interception Based on Matrix Game},
  journal = {Advances in Astronautics Science and Technology},
  volume  = {7}, number = {2}, pages = {101--110},
  year    = {2024},
  doi     = {10.1007/s42423-024-00159-x}
}
```

## Conclusion

The literature search changes where the paper's weight should sit. The lifting and the minimax-versus-FP comparison are now the *setting*, credited to Peters et al. and to classic zero-sum theory. The contribution is the claim that **opponent-policy stationarity, not equilibrium stationarity, is what makes cross-step learning pay off in a re-solved trajectory game**, plus a type library that operationalizes this by conditioning every hypothesis on the current stage matrix. The time-varying-games theory (Cardoso, Fiez) supplies the "why pooling is unjustified" half. Your B6 results supply the "where the value actually is" half: 97–99% of the oracle's gain against fixed opponents, and nothing against randomizers.

The FP-learner type is the most distinctive element, and also the one most exposed to reviewers. It is new relative to Albrecht 2016 and Guan 2021, but only if the paper shows it is *identifiable* in practice (the open D13) and states its shared-matrix and tie-breaking assumptions. A posterior that cannot separate FP from greedy turns the headline novelty into a footnote. Getting that experiment right matters more than any further literature search. The one exception is the 11 unscreened Scholar citers of Peters 2022, which take ten minutes to check by hand.
