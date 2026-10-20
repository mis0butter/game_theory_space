# Robotics/control prior work: online opponent objective/type inference in dynamic games, and lifted (finite-candidate) mixed-strategy trajectory games

Scope: closest robotics/control related work for an ECC 2027 paper on a receding-horizon "lifted" zero-sum matrix game (finite candidate trajectories per player, LP mixed equilibrium each step), minimax vs fictitious play, plus planned Bayesian type-based reasoning over a discrete set of opponent policies (minimax, greedy, random, fixed-target, FP learner). Searches done 2026-10-20 (WebSearch/WebFetch, ~20 calls). Facts below are from search snippets of primary pages (arXiv, RSS proceedings, publisher, lab pages) unless marked.

**Bottom line:** I found no paper that combines (a) online inference of the opponent's type, objective, or policy class with (b) a lifted, finite-candidate, mixed-strategy trajectory game. The closest pieces are separate. **Peters et al. RSS 2022** is the lifted mixed-strategy trajectory game, with no opponent inference. **Liu, Peters, Alonso-Mora RA-L 2023**, **LUCIDGames RA-L 2021**, and **Auto-Encoding Bayesian Inverse Games 2024** do online or Bayesian objective inference, but in continuous pure-strategy (generalized) Nash trajectory games. **Laine et al. "Multi-Hypothesis Interactions" 2020/21**, **Contingency Games RA-L 2024**, and **Huang & Zhu (deceptive PE, PBNE)** maintain beliefs over discrete hypotheses or types, but not over a lifted matrix game of candidate trajectories. Fictitious play does not appear in any of the robotics trajectory-game papers found. The robotics papers use iterated best response (Spica, Wang/Schwager) or simultaneous gradient play instead.

---

## Q1. Lifted / finite-candidate trajectory games with mixed strategies (Peters et al. and follow-ups)

### Takeaway
The lifted formulation comes from Peters, Fridovich-Keil, Ferranti, Stachniss, Alonso-Mora, and Laine (RSS 2022). Each player optimizes several candidate trajectories, a bimatrix game over the candidates is solved for mixed weights, play is receding-horizon, and the testbed is a zero-sum pursuit-evasion "tag" game. Our setup is structurally the same idea. **The author list in the brief is wrong:** there is no "Calderone" on this paper. I found no direct 2023–2026 "lifted game" follow-up. The nearest mixed-strategy trajectory-game works are Krusniak & Laine (chance-constrained mixed strategies) and Sun, Trautman & Murphey (inverse mixed-strategy games).

### Cited Findings
- **Peters, L., Fridovich-Keil, D., Ferranti, L., Stachniss, C., Alonso-Mora, J., Laine, F. "Learning Mixed Strategies in Trajectory Games." RSS XVIII, 2022, paper 051, DOI 10.15607/RSS.2022.XVIII.051; arXiv 2205.00291.** — [RSS proceedings](https://roboticsproceedings.org/rss18/p051.html); [arXiv](https://arxiv.org/abs/2205.00291)
  - Two contributions. (i) An offline-trained (neural) trajectory generator reduces online cost. (ii) A *lifted game* in which "players optimize multiple candidate trajectories in unison" to build more competitive mixed strategies. Validated on pursuit-evasion "tag." — [arXiv](https://arxiv.org/abs/2205.00291)
  - The mixed strategy over candidates comes from solving a **bimatrix game** with a custom Lemke-Howson routine ("BMG(A,B) maps cost matrices A and B to mixed equilibrium strategies"). The tag game is **zero-sum** (f2 = −f1). Play is receding-horizon ("model-predictive game play," "receding-horizon learning over 2500 turns"). Candidate counts are small, e.g., the pursuer learns 2 candidates and a baseline evader uses 20 pre-sampled trajectories. — [ar5iv full text](https://ar5iv.labs.arxiv.org/html/2205.00291)
  - **No opponent modeling, type inference, or fictitious play.** In decentralized tournaments "each player is oblivious to their opponent's decision making process." — [ar5iv full text](https://ar5iv.labs.arxiv.org/html/2205.00291)
  - Reference implementation: LiftedTrajectoryGames.jl (Julia). — [GitHub](https://github.com/lassepe/LiftedTrajectoryGames.jl)
- **Krusniak, M., Laine, F. "Mixed Strategy Constraints in Continuous Games."** AAMAS 2025 Workshop on Autonomous Robots and Multirobot Systems (ARMS); arXiv 2402.17874 (v2, June 2025). Treats coupled constraints such as collision avoidance under mixed strategies as chance constraints. Solves over pure strategies and mixing weights together in a GNEP, motivates the idea on matrix games, and demonstrates on a modified pursuit-evasion example. — [arXiv](https://arxiv.org/html/2402.17874v2)
- **Sun, M. M., Trautman, P., Murphey, T. "Inverse Mixed Strategy Games with Generative Trajectory Models." arXiv 2502.03356, Feb 2025.** Infers *mixed-strategy* behavior distributions from noisy data, representing the mixed strategy with a CVAE. Continuous trajectory distributions, not a finite candidate set. This is the closest "inverse plus mixed strategy" trajectory-game paper. Its venue was not confirmed. — [arXiv](https://arxiv.org/abs/2502.03356v1)
- Peters's TU Delft dissertation "Game-Theoretic Motion Planning for Multi-Agent Interaction" (2026) collects this line of work. — [search snippet; TU Delft project page](https://autonomousrobots.nl/projects/game-theoretic-mp) (dissertation itself not opened)

### Inferences
- The lifting itself is prior art (Peters et al. 2022), so we should cite it as the origin of "lifted" and not claim novelty for it. Our differences: an LP for a zero-sum matrix game rather than Lemke-Howson for a bimatrix game; geometric candidates (hexagon vertices) rather than learned candidates; orbital dynamics; and the study of *non-equilibrium opponents* (FP, greedy, fixed, random), which Peters et al. explicitly do not model.
- The brief's "Peters, Calderone, Fridovich-Keil" attribution must be corrected before it reaches the bibliography. (Dennis Calderone does not appear on this paper.)

### Gaps
- I found no 2023–2026 paper extending the *lifted* formulation by name. Checking Google Scholar's "cited by" list for 2205.00291 directly would settle this. I could not do that with the tools available.
- I did not verify whether Krusniak & Laine have a 2025–2026 archival (non-workshop) version.

---

## Q2. Online objective/type inference in dynamic (trajectory) games

### Takeaway
There is a mature line of work on online inference of opponents' cost parameters inside receding-horizon Nash trajectory games: UKF-based (LUCIDGames), MLE through a differentiable solver (Liu et al.), joint state-and-objective estimation (Peters et al. RSS 2021 / IJRR 2023), and Bayesian VAE posteriors (Liu et al. 2024; Jain et al. 2026). All of these use a **continuous parameter vector of a cost function** in a **pure-strategy (G)NE** game. None uses a discrete set of opponent *policies* or *learning rules*, and none uses mixed strategies over finite candidates.

### Cited Findings
- **Le Cleac'h, S., Schwager, M., Manchester, Z. "LUCIDGames: Online Unscented Inverse Dynamic Games for Adaptive Trajectory Prediction and Planning." IEEE RA-L 6(3):5485–5492, 2021; arXiv 2011.08152.** Uses a UKF to maintain a Bayesian estimate of other agents' objective parameters online and feeds the estimate into a receding-horizon game planner. Estimation uncertainty is handled with uncertainty-ellipse constraints. Runs at about 40 Hz in driving scenarios. — [arXiv](https://arxiv.org/abs/2011.08152); [Stanford MSL](https://msl.stanford.edu/bibliography/le_cleach_lucidgames_2021.html)
- **Peters, L., Fridovich-Keil, D., Rubies-Royo, V., Tomlin, C. J., Stachniss, C. "Inferring Objectives in Continuous Dynamic Games from Noise-Corrupted Partial State Observations." RSS XVII, 2021, DOI 10.15607/RSS.2021.XVII.030; arXiv 2106.03611.** Estimates objectives and states jointly under Nash equilibrium constraints, from noisy partial observations. — [RSS proceedings](https://roboticsproceedings.org/rss17/p030.html)
  - Extended version: Peters, Rubies-Royo, Tomlin, Ferranti, Alonso-Mora, Stachniss, Fridovich-Keil, "Online and Offline Learning of Player Objectives from Partial Observations in Dynamic Games," IJRR 2023, 42(10):917–937; arXiv 2302.01999. — [arXiv](https://arxiv.org/abs/2302.01999v1); [TU Delft](https://research.tudelft.nl/en/publications/online-and-offline-learning-of-player-objectives-from-partial-obs) (the IJRR author list is from memory and was not verified in snippets, so check it)
- **Liu, X., Peters, L., Alonso-Mora, J. "Learning to Play Trajectory Games Against Opponents with Unknown Objectives." IEEE RA-L 8(7):4139–4146, 2023 (presented at IROS 2023); arXiv 2211.13779.** An adaptive model-predictive game solver estimates opponents' objectives online by MLE, using gradients of a differentiable GNE solver, and computes the ego's GNE strategy. Handles partial observations and inequality constraints. Real-time hardware results. — [arXiv](https://arxiv.org/abs/2211.13779v1); [TU Delft](https://research.tudelft.nl/en/publications/learning-to-play-trajectory-games-against-opponents-with-unknown-)
- **Liu, X., Peters, L., Alonso-Mora, J., Topcu, U., Fridovich-Keil, D. "Auto-Encoding Bayesian Inverse Games." WAFR 2024; arXiv 2402.08902.** A structured VAE with a differentiable game solver as the decoder gives Bayesian posteriors over unknown objectives rather than point MLEs. These posteriors lead to safer and more efficient game-theoretic planning in driving simulations. — [arXiv](https://arxiv.org/abs/2402.08902v2) (the WAFR venue comes from a search summary and was not opened)
- **Jain, Y., Liu, X., Peters, L., Fridovich-Keil, D., Topcu, U. "Bayesian Inverse Games with High-Dimensional Multi-Modal Observations." arXiv 2601.00696, Jan 2026 (preprint, no venue).** Extends the VAE approach to multiple sensing modalities. — [arXiv](https://arxiv.org/abs/2601.00696)
- **Schwarting, W., Pierson, A., Alonso-Mora, J., Karaman, S., Rus, D. "Social behavior for autonomous vehicles." PNAS, 2019.** Estimates human drivers' Social Value Orientation (a scalar "type" for selfishness or altruism) online and plans by solving the dynamic game for a Nash equilibrium. Tested on merges and unprotected left turns, including NGSIM data. — [author PDF (BU)](https://sites.bu.edu/pierson/files/2021/05/schwarting2019pnas.pdf); [MIT DSpace](https://dspace.mit.edu/handle/1721.1/136563) (volume, pages, and DOI not confirmed in snippets; I believe it is 116(50):24972–24978, DOI 10.1073/pnas.1820676116, but this is unverified)
- **Laine, F., Fridovich-Keil, D., Chiu, C.-Y., Tomlin, C. "Multi-Hypothesis Interactions in Game-Theoretic Motion Planning." arXiv 2011.06047 (Nov 2020; ICRA 2021 per my recollection, not verified).** Keeps a **finite set of hypotheses** about other agents' objectives and constraints, each with a probability, and folds them into a feedback game. This is the closest "discrete type set inside a trajectory game" precursor. **Correction to the brief:** the authors are Laine et al., not Schwarting. — [arXiv](https://arxiv.org/abs/2011.06047v1)
- **Peters, L., Bajcsy, A., Chiu, C.-Y., Fridovich-Keil, D., Laine, F., Ferranti, L., Alonso-Mora, J. "Contingency Games for Multi-Agent Interaction." IEEE RA-L 2024; arXiv 2304.05483.** Game-theoretic contingency planning over a discrete belief about other agents' intents. A scalar "branching time" models when the uncertainty resolves and is estimated online. Prior game-theoretic planners under uncertainty appear as special cases. — [arXiv](https://arxiv.org/abs/2304.05483v4); [NSF PAR](https://par.nsf.gov/biblio/10511428-contingency-games-multi-agent-interaction)
- **Hu, H., Isele, D., Bae, S., Fisac, J. F. "Active Uncertainty Reduction for Safe and Efficient Interaction Planning: A Shielding-Aware Dual Control Approach." IJRR 2023, DOI 10.1177/02783649231215371; arXiv 2302.00171.** Treats unknown parameters of other agents (goals, attention, willingness to cooperate) as hidden states. Implicit dual control yields active information gathering, with a safety shield. — [SAGE](https://journals.sagepub.com/doi/10.1177/02783649231215371); [Princeton SAFE lab](https://saferobotics.princeton.edu/research/aur)
- **Lidard, J., Hu, H., Hancock, A., Zhang, Z., Gimó Contreras, A., Modi, V., DeCastro, J., Gopinath, D., Rosman, G., Leonard, N., Santos, M., Fisac, J. F. "Blending Data-Driven Priors in Dynamic Games" (KLGame). RSS XX, 2024, DOI 10.15607/RSS.2024.XX.020; arXiv 2402.14174.** A KL-regularized dynamic game toward a multimodal reference policy, with a per-agent knob between task-driven and data-driven behavior. Computes *multimodal* approximate feedback Nash strategies. — [RSS proceedings](https://roboticsproceedings.org/rss20/p020.html)
- **Fridovich-Keil, D., Bajcsy, A., Fisac, J. F., Herbert, S. L., Wang, S., Dragan, A. D., Tomlin, C. J. "Confidence-aware motion prediction for real-time collision avoidance." IJRR 39(2–3):250–265, 2020 (online 2019).** Keeps a Bayesian belief over a model-confidence (rationality) parameter of a human model and widens predictions when the model fits poorly. This is prediction, not a game. Precursor: Fisac et al., RSS 2018, "Probabilistically Safe Robot Planning with Confidence-Based Human Predictions." — [Princeton](https://collaborate.princeton.edu/en/publications/confidence-aware-motion-prediction-for-real-time-collision-avoida/); [RSS 2018](https://roboticsproceedings.org/rss14/p69.html)
- **Sadigh, D., Sastry, S., Seshia, S. A., Dragan, A. D. "Planning for Autonomous Cars that Leverage Effects on Human Actions." RSS XII, 2016.** Treats the human as an optimal planner with a reward learned by IRL, and the robot plans around its influence on the human (an underactuated Stackelberg-like model). Companion: "Information Gathering Actions over Human Internal State," IROS 2016, which uses active probing to infer a discrete or continuous human "driving style." Extended in Autonomous Robots 42(7):1405–1426, 2018, "Planning for cars that coordinate with people," DOI 10.1007/s10514-018-9746-1. — [RSS proceedings](https://roboticsproceedings.org/rss12/p29.html); [Seshia pubs](https://people.eecs.berkeley.edu/~sseshia/pubs/b2hd-sadigh-auton18.html) (IROS 2016 contents not read)
- **Huang, Z., Xie, Y., Ma, B., Shen, S., Ma, J. "Fast and Scalable Game-Theoretic Trajectory Planning with Intentional Uncertainties." arXiv 2507.12174, Jul 2025.** A Bayesian game over intention types. The agent-form game is shown to be an exact potential game, so a Bayesian Nash equilibrium is found by optimization. Pure-strategy and potential-game based. — [arXiv](https://arxiv.org/html/2507.12174v1)

### Inferences
- The robotics inverse-game literature infers **"what does the opponent want"** (cost weights or goals) and then assumes the opponent plays a Nash or GNE strategy given those costs. Our planned type space is different: it is over **how the opponent decides** (minimax, greedy, random, fixed-target, FP learner), i.e., behavioral or bounded-rationality types, including a *learning* type. Within robotics, this is closer to "level-k / policy-class" modelling than to inverse games. It is a defensible point of distinction, but it should be stated carefully: "objective inference" papers could in principle encode fixed-target or greedy behavior as cost parameters.
- Laine et al. 2020/21 and Peters et al. (Contingency Games, 2024) are the closest *discrete-hypothesis* precursors and must be cited. Their hypotheses are about objectives and constraints in pure-strategy games, not mixed-strategy candidate games.

### Gaps
- I did not confirm exact volumes or DOIs for Contingency Games (RA-L 2024), Schwarting PNAS, the Laine ICRA 2021 venue, or the Spica T-RO author list. These are marked in the BibTeX below.
- Several 2021–2024 intent-inference game papers were not searched for individually because of the tool budget, e.g., Schwarting et al. "Stochastic Dynamic Games in Belief Space" (T-RO 2021), So/Fridovich-Keil "MPOGames," Mehr et al. "Maximum-entropy multi-agent dynamic games."

---

## Q3. Type / Bayesian games in pursuit-evasion (robotics and aerospace)

### Takeaway
Bayesian-type pursuit-evasion work exists. In robotics it takes the form of perfect Bayesian Nash equilibrium with deception (Huang & Zhu). In aerospace, the spacecraft PE literature mostly estimates the evader's cost weights or control gains with filters (UKF, particle filter, IMM), and the 2025 IEEE paper fits that pattern. None found uses a finite candidate-trajectory matrix game with a belief over discrete opponent policies.

### Cited Findings
- **Huang, L., Zhu, Q. "A Dynamic Game Framework for Rational and Persistent Robot Deception With an Application to Deceptive Pursuit-Evasion." IEEE Trans. Automation Science and Engineering; arXiv 1907.00459** (an earlier title was "Dynamic Games of Asymmetric Information for Deceptive Autonomous Vehicles"). Private types, belief updates, PBNE solution concept, a receding-horizon algorithm, and Bayesian learning to counter deception, applied to pursuit-evasion. — [arXiv](https://arxiv.org/abs/1907.00459v2); [NSF PAR](https://par.nsf.gov/biblio/10312131) (TASE year and volume not verified)
- **Spacecraft PE with incomplete information:** the pursuer estimates the evader's cost-function weights with a particle swarm plus unscented particle filter and redesigns its strategy, under J2 perturbation (IEEE, 2025). — [IEEE Xplore 10970006](https://ieeexplore.ieee.org/abstract/document/10970006/) (authors, title wording, and venue not opened)
- ISSFD 2019, "Orbital Pursuit-Evasion Games with Incomplete Information": UKF estimation of the opponent's cost or gains. — [ISSFD PDF](https://issfd.org/ISSFD_2019/ISSFD_2019_AIAC18_Li-Zhen-yu.pdf) (not opened)
- Aerospace Science and Technology (2022), "Pursuit-evasion game switching strategies for spacecraft with incomplete-information": IMM estimation of a target that switches strategies. — [ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S1270963821006222) (authors not verified; a search summary named "Li and Ye")
- Multi-UAV PE via opponent intent inference: a zero-sum mixed-strategy matrix game plus a belief-risk framework in receding-horizon planning. — [ResearchGate](https://www.researchgate.net/publication/403533525_Safe_Cooperative_Decision-Making_for_Multi-UAV_Pursuit-Evasion_Games_via_Opponent_Intent_Inference) (**authors, venue, and year unverified; could be the closest structural match, so read the full text before citing**)
- Background game theory, not robotics: Bayesian opponent exploitation keeps a posterior over the opponent's mixed strategy and best-responds to it (Ganzfried & Sandholm, arXiv 1603.03491). — [arXiv](https://arxiv.org/pdf/1603.03491)

### Inferences
- In the spacecraft PE literature, "incomplete information" is usually treated as continuous parameter estimation. A discrete behavioral-type posterior applied to a per-step lifted matrix game looks unoccupied, but the multi-UAV paper above needs checking.

### Gaps
- The multi-UAV intent-inference paper (ResearchGate 403533525) could not be verified. It is the single most important item to check for overlap.
- Other researchers' scopes cover the space-specific PE literature in depth.

---

## Q4. Fictitious play / iterated best response inside trajectory or dynamic games in robotics

### Takeaway
Robotics trajectory-game solvers use **iterated best response (IBR)**, sometimes with sensitivity terms, as an *equilibrium-finding* scheme inside a single planning solve. They do not use fictitious play as a *cross-step learning rule against an opponent*. I found no robotics paper that uses fictitious play over a receding-horizon sequence of trajectory or matrix games. FP appears in robotics only for discrete cooperative action selection.

### Cited Findings
- **Spica, R., Cristofalo, E., Wang, Z., Montijano, E., Schwager, M. "A Real-Time Game Theoretic Planner for Autonomous Two-Player Drone Racing." IEEE T-RO, 2020; RSS XIV 2018 version authored by Spica, Falanga, Cristofalo, Montijano, Scaramuzza, Schwager; arXiv 1801.02302.** Receding-horizon planner using sensitivity analysis inside an IBR scheme to approximate Nash equilibria in real time. The racing game is treated as zero-sum. — [RSS 2018](https://www.roboticsproceedings.org/rss14/p40.html); [Stanford MSL](https://msl.stanford.edu/bibliography/spica_real-time_2020.html) (T-RO author list from a search summary; verify)
- **Wang, M., Wang, Z., Talbot, J., Gerdes, J. C., Schwager, M. "Game-Theoretic Planning for Self-Driving Cars in Multivehicle Competitive Scenarios." IEEE T-RO, 2021.** RSS 2019 precursor: "Game Theoretic Planning for Self-Driving Cars in Competitive Scenarios," which uses IBR with a sensitivity term. — [Stanford MSL](https://msl.stanford.edu/bibliography/wang_game-theoretic_2021.html); [RSS 2019](https://roboticsproceedings.org/rss15/p48.html)
- Fictitious play in robotics, discrete and cooperative: "Fictitious play for cooperative action selection in robot teams," arXiv 1611.05638, which tracks teammates' mixed strategies with an EKF. — [arXiv](https://arxiv.org/abs/1611.05638) (authors and venue not verified)
- Peters et al. 2022 mention simultaneous gradient play and IBR only as related solution methods, with no FP. — [ar5iv](https://ar5iv.labs.arxiv.org/html/2205.00291)

### Inferences
- FP as an opponent-model learner across receding-horizon stage games, where **the stage matrix changes every step**, is uncommon in robotics. Its closest relatives are in the learning-in-games and MARL literature (outside this scope). We should say plainly that classical FP convergence guarantees assume a *fixed* matrix game, and that our nonstationary per-step matrices break this assumption. This also motivates the Bayesian type layer.

### Gaps
- I did not search the MPC/learning-in-games literature in control (e.g., FP or no-regret learning for differential games in TAC/CDC) for lack of budget. Another researcher's scope may cover it.

---

## Explicit flag: does any paper already combine online opponent-type/objective inference with a lifted finite-candidate mixed-strategy trajectory game?

**None found.** These are the nearest misses, ranked by closeness, with what each lacks:
1. Peters et al., RSS 2022: lifted, mixed, zero-sum, receding-horizon PE. Lacks any opponent inference.
2. Multi-UAV PE via opponent intent inference (ResearchGate 403533525): a mixed-strategy matrix game plus belief, receding-horizon. **Unverified; check it.**
3. Laine et al. 2020/21 and Contingency Games (RA-L 2024): a discrete hypothesis belief inside a trajectory game. Pure-strategy, not lifted.
4. Liu, Peters, Alonso-Mora (RA-L 2023), LUCIDGames (RA-L 2021), and the Bayesian inverse games (2024, 2026): online objective inference in receding-horizon games. Continuous costs, pure (G)NE.
5. Sun, Trautman, Murphey (2025): inverse *mixed-strategy* trajectory games. Offline or generative, continuous distributions, not finite candidates.
6. Huang & Zhu (TASE): Bayesian types, PBNE, PE, receding horizon. Not a lifted trajectory matrix game.

---

## BibTeX (the ~8 most important; fields marked `% VERIFY` were not confirmed)

```bibtex
@inproceedings{peters2022lifted,
  author    = {Peters, Lasse and Fridovich-Keil, David and Ferranti, Laura and Stachniss, Cyrill and Alonso-Mora, Javier and Laine, Forrest},
  title     = {Learning Mixed Strategies in Trajectory Games},
  booktitle = {Robotics: Science and Systems XVIII},
  year      = {2022},
  doi       = {10.15607/RSS.2022.XVIII.051}
}

@article{liu2023unknownobjectives,
  author  = {Liu, Xinjie and Peters, Lasse and Alonso-Mora, Javier},
  title   = {Learning to Play Trajectory Games Against Opponents With Unknown Objectives},
  journal = {IEEE Robotics and Automation Letters},
  volume  = {8},
  number  = {7},
  pages   = {4139--4146},
  year    = {2023},
  note    = {arXiv:2211.13779}
}

@article{lecleach2021lucidgames,
  author  = {Le Cleac'h, Simon and Schwager, Mac and Manchester, Zachary},
  title   = {{LUCIDGames}: Online Unscented Inverse Dynamic Games for Adaptive Trajectory Prediction and Planning},
  journal = {IEEE Robotics and Automation Letters},
  volume  = {6},
  number  = {3},
  pages   = {5485--5492},
  year    = {2021},
  note    = {arXiv:2011.08152}
}

@inproceedings{peters2021inferring,
  author    = {Peters, Lasse and Fridovich-Keil, David and Rubies-Royo, Vicen{\c{c}} and Tomlin, Claire J. and Stachniss, Cyrill},
  title     = {Inferring Objectives in Continuous Dynamic Games from Noise-Corrupted Partial State Observations},
  booktitle = {Robotics: Science and Systems XVII},
  year      = {2021},
  doi       = {10.15607/RSS.2021.XVII.030}
}

@article{peters2024contingency,
  author  = {Peters, Lasse and Bajcsy, Andrea and Chiu, Chih-Yuan and Fridovich-Keil, David and Laine, Forrest and Ferranti, Laura and Alonso-Mora, Javier},
  title   = {Contingency Games for Multi-Agent Interaction},
  journal = {IEEE Robotics and Automation Letters},
  year    = {2024},
  note    = {arXiv:2304.05483}  % VERIFY volume/number/pages/DOI
}

@misc{laine2020multihypothesis,
  author = {Laine, Forrest and Fridovich-Keil, David and Chiu, Chih-Yuan and Tomlin, Claire},
  title  = {Multi-Hypothesis Interactions in Game-Theoretic Motion Planning},
  year   = {2020},
  note   = {arXiv:2011.06047}  % VERIFY: published at ICRA 2021?
}

@inproceedings{liu2024autoencoding,
  author    = {Liu, Xinjie and Peters, Lasse and Alonso-Mora, Javier and Topcu, Ufuk and Fridovich-Keil, David},
  title     = {Auto-Encoding {Bayesian} Inverse Games},
  booktitle = {Workshop on the Algorithmic Foundations of Robotics (WAFR)},  % VERIFY
  year      = {2024},
  note      = {arXiv:2402.08902}
}

@article{schwarting2019social,
  author  = {Schwarting, Wilko and Pierson, Alyssa and Alonso-Mora, Javier and Karaman, Sertac and Rus, Daniela},
  title   = {Social Behavior for Autonomous Vehicles},
  journal = {Proceedings of the National Academy of Sciences},
  year    = {2019},
  volume  = {116},            % VERIFY
  number  = {50},             % VERIFY
  pages   = {24972--24978},   % VERIFY
  doi     = {10.1073/pnas.1820676116}  % VERIFY
}

@article{hu2023activeuncertainty,
  author  = {Hu, Haimin and Isele, David and Bae, Sangjae and Fisac, Jaime F.},
  title   = {Active Uncertainty Reduction for Safe and Efficient Interaction Planning: A Shielding-Aware Dual Control Approach},
  journal = {The International Journal of Robotics Research},
  year    = {2023},
  doi     = {10.1177/02783649231215371}
}

@article{spica2020racing,
  author  = {Spica, Riccardo and Cristofalo, Eric and Wang, Zijian and Montijano, Eduardo and Schwager, Mac},
  title   = {A Real-Time Game Theoretic Planner for Autonomous Two-Player Drone Racing},
  journal = {IEEE Transactions on Robotics},
  year    = {2020}   % VERIFY author list, volume, pages
}

@misc{krusniak2025mixedconstraints,
  author = {Krusniak, Mel and Laine, Forrest},
  title  = {Mixed Strategy Constraints in Continuous Games},
  year   = {2025},
  note   = {AAMAS 2025 Workshop on Autonomous Robots and Multirobot Systems (ARMS); arXiv:2402.17874}
}
```
