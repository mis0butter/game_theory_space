# Overlap checks for the novelty claim (online opponent-type inference + lifted finite-candidate mixed-strategy trajectory game)

Checked 2026-10-20. Sources were read through Europe PMC (full-text XML of the Sensors paper), the Semantic Scholar Graph API, OpenAlex and the arXiv API. Google Scholar's "cited by" page showed a CAPTCHA, so I got its count but could not list the papers.

## Q1. The ResearchGate 403533525 paper ("... via Opponent Intent Inference")

### Takeaway
The paper is Li, Feng & Zhang, *Sensors* 26(7):2243, 2026. It does **not** use a matrix game, mixed strategies, LP, Nash equilibria, fictitious play or Bayesian type inference over policies. The search snippet that described a "zero-sum mixed-strategy matrix game with belief-based receding-horizon planning" was wrong. The paper is a deep-learning and MARL pipeline: a CVAE-style intent model, a distilled trajectory predictor, and a hierarchical SAC policy. It does not overlap our combination. At most it is a "related, intent-inference in UAV pursuit-evasion" citation.

### Cited Findings
- **Bibliographic record.** Wen-Xin Li, Yong-Xin Feng, Wenbo Zhang, "Safe Cooperative Decision-Making for Multi-UAV Pursuit–Evasion Games via Opponent Intent Inference," *Sensors* (MDPI) 26(7), article 2243. Published 2026-04-04 (S2 lists 2026-04-01). DOI 10.3390/s26072243, PMCID PMC13075325, PMID 41978023. All authors are at the School of Information Science and Engineering, Shenyang Ligong University; corresponding author fengyongxin@sylu.edu.cn. — [Europe PMC record / full text](https://pmc.ncbi.nlm.nih.gov/articles/PMC13075325/); [DOI](https://doi.org/10.3390/s26072243); [ResearchGate](https://www.researchgate.net/publication/403533525_Safe_Cooperative_Decision-Making_for_Multi-UAV_Pursuit-Evasion_Games_via_Opponent_Intent_Inference)
- **Definition of intent.** "opponent intent inference specifically denotes estimating the evader's behavior mode and short-horizon spatial subgoal from short observation sequences." The intent is η_t = (z_t, g_t). z_t is a discrete behavior mode with 4 modes; mode 0 is escape and mode 1 is occlusion-seeking. g_t is a continuous 2-D subgoal per evader. — [PMC full text](https://pmc.ncbi.nlm.nih.gov/articles/PMC13075325/)
- **How intent is inferred.** The authors call the model the "Generative Intent–Subgoal Model (GISM)". It is an observation-driven latent-variable generative model trained variationally, with a categorical prior over modes and a mode-conditioned Gaussian prior over subgoals. Its output is distilled into a "length-agnostic trajectory predictor" via multi-window knowledge distillation. Supervision comes from offline self-play data. — [PMC full text](https://pmc.ncbi.nlm.nih.gov/articles/PMC13075325/)
- **How decisions are made.** The problem is modeled as a "state-augmented decentralized partially observable Markov decision process (Dec-POMDP)". Belief and risk features feed a "belief-risk-gated hierarchical multi-agent policy based on soft actor-critic with a safety projection layer". Experiments run in a planar 2:2 obstacle-rich environment. — [PMC full text / abstract](https://pmc.ncbi.nlm.nih.gov/articles/PMC13075325/)
- **Absent terms.** A count over the full text found zero occurrences of "matrix game", "zero-sum", "mixed strategy", "Nash", "linear program", "equilibri", "payoff", "fictitious", "Bayes" and "Peters". "Receding" occurs once, and only in the description of the OPEN baseline ("an RL policy embedded in receding-horizon online planning"). — [PMC full text](https://pmc.ncbi.nlm.nih.gov/articles/PMC13075325/)
- **Reported results (authors' claims).** About 5–7% higher normalized expected return than the strongest baseline, about 22–25% fewer pursuer losses, and latency under 50 ms. — [abstract](https://pubmed.ncbi.nlm.nih.gov/41978023/)

### Inferences
- **What is inferred differs from ours.** The paper infers a hand-defined discrete behavior mode plus a continuous subgoal, which it uses as features for an RL policy. We infer a posterior over a discrete set of opponent *policies* (minimax, greedy, random, fixed-target, FP) inside an equilibrium-computing planner. Its "mode" set is loosely analogous to a type set, but it is never used to best-respond or to mix in a game-theoretic sense.
- **The paper's own framing helps us.** It says most prior MARL pursuit work "absorb[s]" opponent modelling into policy parameters, and that interpretable, explicitly maintained opponent beliefs are rare. We could cite it as recent evidence that explicit opponent-intent inference is valued in pursuit-evasion, while noting that it sits in the RL paradigm, not the game-solving paradigm.
- **Effect on the claim.** It does not threaten "to our knowledge, no prior work combines online opponent-type inference with a lifted / finite-candidate mixed-strategy trajectory game".

### Gaps
- I did not inspect the full reference list for further game-theoretic intent papers. The keyword scan found no game-theory references, though.

## Q2. Forward citations of Peters et al., "Learning Mixed Strategies in Trajectory Games" (RSS 2022)

### Takeaway
Semantic Scholar lists **14** citing works (OpenAlex lists 7, all inside the S2 set); Google Scholar reports "Cited by 25". None of the indexed citers combines a lifted / finite-candidate mixed-strategy trajectory game with online opponent-type inference or fictitious play. The closest neighbours fall into two groups:
- **Online opponent-objective inference in pure-strategy (GNE) trajectory games.** Liu, Peters & Alonso-Mora (RA-L 2023) and Jain et al. (arXiv 2026).
- **Mixed-strategy trajectory games with online inference of game parameters.** Sun, Trautman & Murphey (ICRA 2025). Here the inference targets objective/specification parameters, not a discrete set of opponent policy types, and the mixed strategy is a CVAE distribution rather than an LP over a finite candidate set.

The claim survives. It must be worded to exclude objective inference and inverse games: we infer opponent *policy types*, not cost parameters, and we do it within an LP-solved finite matrix game.

### Cited Findings
**Bibliographic record of the base paper.** Lasse Peters, David Fridovich-Keil, Laura Ferranti, Cyrill Stachniss, Javier Alonso-Mora, Forrest Laine, RSS XVIII (2022). DOI 10.15607/RSS.2022.XVIII.051, arXiv 2205.00291. — [OpenAlex](https://openalex.org/W4283787951); [arXiv](https://arxiv.org/abs/2205.00291)

**Citing works indexed by Semantic Scholar** ([API query](https://api.semanticscholar.org/graph/v1/paper/arXiv:2205.00291/citations?fields=title,authors,year,venue,externalIds&limit=100)). For each one I note whether it uses a lifted / finite mixed strategy and whether it does opponent modelling or online learning:

| Year | Work | Venue / ID | Mixed strategy? | Opponent inference / learning? |
|---|---|---|---|---|
| 2022/23 | Zanardi, Sessa, Käslin, Bolognani, Censi, Frazzoli — How Bad is Selfish Driving? | RA-L, 10.1109/LRA.2023.3251845 | Finite-action driving games, price of anarchy | No |
| 2022/25 | Chen, Bayiz, Fridovich-Keil, Topcu — Relationship design for socially-aware behavior in static games | JAAMAS, 10.1007/s10458-025-09699-4 | Static games | No |
| 2022 | Cathcart, Santos, Park, Leonard — Opinion-Driven Robot Navigation | arXiv 2210.01642 | No (opinion dynamics) | No |
| 2024/25 | Gonultas & Isler — Pursuit-Evasion for Car-like Robots with Sensor Constraints | IROS 2025, 10.1109/IROS60139.2025.11246244, arXiv 2405.05372 | POSG, learning-based | Learned belief over *opponent state* (not type) |
| 2024 | Sun, Baldini, Hughes, Trautman, Murphey — Mixed strategy Nash equilibrium for crowd navigation (BRNE) | IJRR, 10.1177/02783649241302342, arXiv 2403.01537 | Yes (iterative Bayesian update over *trajectory distributions* = mixed NE) | "Bayesian" refers to the equilibrium computation, not to opponent-type inference |
| 2024 | Krusniak & Laine — Mixed Strategy Constraints in Continuous Games | arXiv 2402.17874 | Yes (chance constraints on matrix and continuous games, pursuit-evasion example) | No |
| 2024 | Lidard, Hu, Hancock, Zhang, Contreras, ... Fisac, ... — Blending Data-Driven Priors in Dynamic Games (KLGame) | RSS 2024, arXiv 2402.14174 | Multi-modal stochastic policies | Uses a fixed data-driven prior; no online type inference |
| 2025 | de las Heras Molins, Roy-Almonacid, Lee, Peters, Fridovich-Keil — Approximate Solutions to Games of Ordered Preference | ITSC 2025, 10.1109/ITSC60802.2025.11423775 | No | No |
| 2025 | Krusniak, Xu, Palermo, Laine — Online Competitive Information Gathering for Partially Observable Trajectory Games | AAMAS 2025, arXiv 2506.01927 | POSG trajectory games, stochastic gradient play, pursuit-evasion test | Particle belief over *joint state*, not opponent type |
| 2025 | Sun, Trautman, Murphey — Inverse Mixed Strategy Games with Generative Trajectory Models | ICRA 2025, 10.1109/ICRA55743.2025.11128615, arXiv 2502.03356 | Yes (mixed strategy represented by a CVAE) | **Yes: online inverse game, inferring game specifications/objectives from observations "in real-time"** |
| 2025 | Guan, Shames, Summers — Best Response Convergence for Zero-sum Stochastic Dynamic Games with Partial and Asymmetric Information | ECC 2025, 10.23919/ECC65951.2025.11186954 | LQ games | Iterated best response (offline solution method, not online learning) |
| 2026 | Xu, Xi, He — Near-Optimal Mixed Strategy for Zero-Sum LQ Differential Games | IEEE TAC (per S2), arXiv 2605.30886 | Yes (LQ) | No |
| 2026 | Papuc, Peters, Sun, Ferranti, Alonso-Mora — Strategizing at Speed: Learned Model Predictive Game for Drone Racing | RA-L 2026, 10.1109/LRA.2026.3701568, arXiv 2602.06925 | Receding-horizon game (MPG), amortized by learning | No opponent-type inference |
| — | L. Peters — PhD thesis "Towards Fast, Flexible, and Data-Efficient Algorithms for Multi-Agent Interaction" | TU Delft (S2, no year) | Includes the RSS 2022 work | — |

Sources for the table: abstracts via the [arXiv API](https://arxiv.org/abs/2502.03356), [arXiv 2405.05372](https://arxiv.org/abs/2405.05372), [2403.01537](https://arxiv.org/abs/2403.01537), [2506.01927](https://arxiv.org/abs/2506.01927), [2402.17874](https://arxiv.org/abs/2402.17874), [2402.14174](https://arxiv.org/abs/2402.14174), [2501.06181](https://arxiv.org/abs/2501.06181) and [2602.06925](https://arxiv.org/abs/2602.06925). The OpenAlex list of citers is at [OpenAlex cites:W4283787951](https://api.openalex.org/works?filter=cites:W4283787951).

**Closest neighbours outside the indexed citation list** (same group, online opponent inference in trajectory games):
- **Liu, Peters & Alonso-Mora, "Learning to Play Trajectory Games Against Opponents With Unknown Objectives."** RA-L 2023, DOI 10.1109/LRA.2023.3280809, arXiv 2211.13779. It jointly infers opponents' *objectives* online, by maximum likelihood through a differentiable solver, and plays the corresponding generalized Nash equilibrium in receding horizon. The equilibrium is pure-strategy and continuous, not a finite-candidate mixed strategy. — [arXiv](https://arxiv.org/html/2211.13779v3); [S2 metadata](https://api.semanticscholar.org/graph/v1/paper/arXiv:2211.13779)
- **Jain, Liu, Peters, Fridovich-Keil, Topcu, "Bayesian Inverse Games with High-Dimensional Multi-Modal Observations."** arXiv 2601.00696, Jan 2026. It performs Bayesian inference over opponent objectives with receding-horizon (MPC-like) game play. This is not a finite mixed-strategy game. — [arXiv](https://arxiv.org/html/2601.00696)
- A general search ("fictitious play trajectory game candidate trajectories pursuit-evasion matrix game receding horizon") found nothing that combines fictitious play with a finite-candidate trajectory matrix game. The nearest results were a static JSFP pursuer-assignment paper and a discretized super-pursuer-vs-evader matrix game with no learning. — [search results incl. arXiv 2508.03824](https://arxiv.org/pdf/2508.03824)

### Inferences
- **Inverse games: the main overlap risk.** Reviewers may say "online opponent inference in trajectory games already exists". The answer is that those works (Liu 2023; Jain 2026; Sun 2025; also LUCIDGames, not checked here) infer continuous *cost or objective parameters* under an assumed equilibrium model. We infer a posterior over a discrete set of opponent *policy types*, some of which are non-equilibrium (greedy, random, fixed, FP), and we best-respond or mix over a finite LP-solved candidate game. We should cite Liu et al. 2023 and Sun et al. 2025 explicitly as the nearest work and draw this distinction.
- **Sun et al. 2025 (ICRA): the single closest paper.** It combines a mixed-strategy trajectory game with online inference. Its differences from ours: the mixed strategy is a continuous generative distribution, the inference is an inverse game over specifications, there is no type set, and there is no fictitious play.
- **Suggested claim wording.** "To our knowledge, prior work on mixed-strategy trajectory games either solves for equilibrium without modelling the opponent [Peters 2022; Sun 2024; Krusniak 2024], or infers opponent objective parameters under an equilibrium assumption [Liu 2023; Sun 2025; Jain 2026]. None combines a finite-candidate (lifted) matrix game with online inference over a set of non-equilibrium opponent policy types and fictitious-play beliefs." I judge this defensible. One caveat: 11 Google Scholar citers (25 − 14) were not inspected.

### Gaps
- **Scholar citers unchecked.** Google Scholar reports 25 citers, but the listing page was CAPTCHA-blocked ([GS cites id 17465300582096261158](https://scholar.google.com/scholar?cites=17465300582096261158)). About 11 citers (theses, workshop papers, non-indexed venues) are unverified. The author should open that link manually before submission.
- **Not checked.** I did not check LUCIDGames (Le Cleac'h et al.), MPOGames (So et al., ICRA 2023), or the Peters et al. "Contingency Games" line. They are likely relevant Bayesian-belief game planners, but they are not lifted mixed-strategy games. Their bibliographic details are unverified here.
- **Unconfirmed venue.** Xu, Xi & He's venue is "IEEE TAC" per Semantic Scholar only.

### BibTeX (verified metadata)
```bibtex
@inproceedings{peters2022mixed,
  author    = {Peters, Lasse and Fridovich-Keil, David and Ferranti, Laura and Stachniss, Cyrill and Alonso-Mora, Javier and Laine, Forrest},
  title     = {Learning Mixed Strategies in Trajectory Games},
  booktitle = {Robotics: Science and Systems XVIII},
  year      = {2022},
  doi       = {10.15607/RSS.2022.XVIII.051}
}
@article{liu2023unknown,
  author  = {Liu, Xinjie and Peters, Lasse and Alonso-Mora, Javier},
  title   = {Learning to Play Trajectory Games Against Opponents With Unknown Objectives},
  journal = {IEEE Robotics and Automation Letters},
  year    = {2023},
  doi     = {10.1109/LRA.2023.3280809}
}
@inproceedings{sun2025inverse,
  author    = {Sun, Max Muchen and Trautman, Pete and Murphey, Todd D.},
  title     = {Inverse Mixed Strategy Games with Generative Trajectory Models},
  booktitle = {IEEE International Conference on Robotics and Automation (ICRA)},
  year      = {2025},
  doi       = {10.1109/ICRA55743.2025.11128615}
}
@article{sun2024brne,
  author  = {Sun, Max Muchen and Baldini, Francesca and Hughes, Katie and Trautman, Peter and Murphey, Todd D.},
  title   = {Mixed Strategy {N}ash Equilibrium for Crowd Navigation},
  journal = {The International Journal of Robotics Research},
  year    = {2024},
  doi     = {10.1177/02783649241302342}
}
@article{jain2026bayesian,
  author  = {Jain, Yash and Liu, Xinjie and Peters, Lasse and Fridovich-Keil, David and Topcu, Ufuk},
  title   = {Bayesian Inverse Games with High-Dimensional Multi-Modal Observations},
  journal = {arXiv preprint arXiv:2601.00696},
  year    = {2026}
}
@article{li2026intent,
  author  = {Li, Wen-Xin and Feng, Yong-Xin and Zhang, Wenbo},
  title   = {Safe Cooperative Decision-Making for Multi-{UAV} Pursuit--Evasion Games via Opponent Intent Inference},
  journal = {Sensors},
  volume  = {26},
  number  = {7},
  pages   = {2243},
  year    = {2026},
  doi     = {10.3390/s26072243}
}
```
Note: S2 abbreviates Jain's first name as "Y."; "Yash" is unverified, so check it before use.
