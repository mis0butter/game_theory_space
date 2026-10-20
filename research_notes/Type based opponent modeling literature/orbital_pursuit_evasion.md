# Orbital / spacecraft pursuit-evasion with opponent inference, learning, mixed strategies, and matrix-game formulations

Compiled 2026-10-20. Metadata (authors / venue / year / DOI) for every entry below was checked against Crossref or the publisher record unless marked **[UNVERIFIED]**. Full texts were read only where stated (most publishers returned 403 to the fetch tool). Where I report a method detail from an abstract only, I say so.

**Bottom line:** I found **no paper that does our combination**: a receding-horizon matrix game over a finite set of optimized trajectories, solved by LP for a mixed equilibrium, with fictitious play or Bayesian inference over a library of opponent *policy types* (minimax / greedy / random / fixed / learner). The closest work splits into four separate strands, and each one covers only part of our setup:
1. **Incomplete-information orbital pursuit-evasion (PE) with parameter or mode estimation.** These are continuous differential games (LQ / ZEM) where the unknown is a cost-weight parameter or a *mode* from a small finite set, estimated by UKF / IMM / filter banks / LSTM / GRU. The closest to type-based reasoning is multiple-model estimation over a finite strategy set (Ye et al. 2021; Wang et al. 2024; Wei et al. 2025).
2. **Matrix games and mixed strategies in orbital games.** Hanlong et al. 2024 (multi-round matrix game, complete information, GA solver); Han & Dang 2026 (2x2 mixed Nash plus a Bayesian belief over *decoy identity*, not opponent type); Yu et al. 2026 (a meta-game payoff matrix over RL strategy populations).
3. **Learning-based orbital PE.** RL / MARL / self-play / population training (Jiang et al. 2023 vs random evaders; Mehlman & Falco 2025 DARL; Yu et al. 2026; Jiang et al. 2025; Li et al. 2026 with a Kalman "opponent-modeling" module that estimates *maneuvers*, not policy types).
4. **Space-domain Bayesian / imperfect-information games that are not PE.** Becker & Sunberg 2022 (MCCFR, SDA); Boh, Funke & Akella 2025 (Bayesian game, cislunar SSA).

---

## Q1. Orbital/spacecraft PE with incomplete information, Bayesian games, opponent intention/type estimation, "unknown opponent"

### Takeaway
There is a large and active literature, mostly Chinese groups publishing in AST, Acta Astronautica, JGCD, Sci China Tech Sci, Aerospace, and Space Sci & Tech. It almost always models the unknown as a **continuous parameter** of a differential game (the opponent's LQ weighting matrices) estimated by a filter, or as a **mode from a small finite set** of guidance laws (LQ vs ZEM) estimated by IMM / multiple-model filters. The finite-mode IMM work is the closest analogue to Bayesian type inference. However, it infers the opponent's *guidance law in a continuous differential game*, never a posterior over policy types that feeds a best response in a lifted matrix game. None of it uses fictitious play.

### Cited Findings
- **Li, Zhu & Luo (2020/2021), "An escape strategy in orbital pursuit-evasion games with incomplete information," Sci China Tech Sci 64:559–570, DOI 10.1007/s11431-020-1662-0.** This is the earliest well-cited journal paper on incomplete-information orbital PE. Its precursor at ISSFD 2019 (Li Zhen-yu et al.) models orbital PE as a two-player zero-sum differential game in which each spacecraft knows only its own cost and control gains. It estimates the opponent's parameters with an Unscented Kalman Filter and designs the control law from those estimates. It notes that "existing researches on orbital pursuit-evasion generally assume the game has complete information." — [Crossref/Springer](https://doi.org/10.1007/s11431-020-1662-0); [ISSFD 2019 PDF](https://issfd.org/ISSFD_2019/ISSFD_2019_AIAC18_Li-Zhen-yu.pdf). (ISSFD paper content is from a search snippet; full text not read.)
- **Ye, Tang, Sun & Wang (2021), "Multiple model adaptive intercept strategy of spacecraft for an incomplete-information game," Acta Astronautica 180:340–349, DOI 10.1016/j.actaastro.2020.12.015.** A terminal intercept game with incomplete information. A *bank of filters run in parallel* identifies the target's unknown information, which "is assumed to belong to a finite set and stay fixed throughout the game." **This is the closest structural analogue to our Bayesian type posterior** (a finite hypothesis set with multiple-model probabilities), but it applies to a continuous differential-game guidance law, not to discrete policy types in a matrix game. — [Crossref](https://doi.org/10.1016/j.actaastro.2020.12.015); description from [HIT Scholar listing](https://scholar.hit.edu.cn/en/publications/multiple-model-adaptive-intercept-strategy-of-spacecraft-for-an-i/) via search snippet.
- **Tang, Ye, Huang, Sun & Sun (2021), "Pursuit-evasion game switching strategies for spacecraft with incomplete-information," Aerosp Sci Technol 119:107112, DOI 10.1016/j.ast.2021.107112.** Metadata verified. **[Method UNVERIFIED]:** one search summary said it treats the missing information as an extended state, formulates a matrix game, and combines IMM with a smooth variable structure filter. A second summary attributed the matrix-game element to a different paper. I could not access the abstract (403; Semantic Scholar has no abstract). Read it before citing for "matrix game". — [ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S1270963821006222)
- **Tang, Ye, Luo, Low & Sun (2022), "A Hybrid Game Strategy for the Pursuit of Out-of-Control Spacecraft under Incomplete-Information," Aerospace 9(8):455, DOI 10.3390/aerospace9080455.** The target's maneuver strategy is unknown. The target's control is treated as a disturbance, and a disturbance estimator identifies the missing information. The resulting hybrid strategy is derived from a unilateral optimal cost. The method is estimation, not type reasoning. — [Crossref abstract](https://doi.org/10.3390/aerospace9080455)
- **Wang, Chen & Liao (2024), "Interactive Multiple-Model Learning Filter for Spacecraft Pursuit–Evasion Game Strategy Switch Based on LSTM Network," Aerospace 11(11):894, DOI 10.3390/aerospace11110894.** The evader switches between an LQ evasion law and a ZEM evasion law. An LSTM-augmented IMM filter estimates the evader's *strategy mode* probabilities, and the pursuer switches to the matching pursuit strategy. **This is the closest to "infer which opponent policy, then respond":** a finite set of 2 opponent strategies, posterior mode probabilities, and a best-response switch. It differs from our setup in continuous LQ/ZEM guidance (no matrix game), no mixed strategies, and no learner types. The authors note the mode probabilities separate poorly when strategies differ little. — [Semantic Scholar abstract / MDPI](https://www.mdpi.com/2226-4310/11/11/894)
- **Wei, Liu & Wei (2025), "Mode-switching cooperative defense strategy for the orbit pursuit-evasion-defense game," Defence Technology 44:272–286, DOI 10.1016/j.dt.2024.10.006.** The pursuer's attack and avoidance modes are modeled by differential games. An IMM bank of smooth variable structure filters recognizes the pursuer's mode in real time, and the evader–defender pair then plays an LQ cooperative "luring" strategy. This is multiple-model mode inference in a three-body PE-D game. — [Crossref](https://doi.org/10.1016/j.dt.2024.10.006); method from [search snippet](https://doaj.org/article/a1ef65fbc9ec49aeb62afbaab8736ca3)
- **Liu, Yang, Li & Xin (2025), "Parameter-Optimized Pursuit Strategy for Orbital Games with Incomplete Information," JGCD 48(8), DOI 10.2514/1.G008824.** An extended state containing parameters "that characterize the evasion strategy." A UKF estimates the evader's control weighting matrices, and a receding-horizon parameter-optimized pursuit law follows. — [Crossref abstract](https://doi.org/10.2514/1.G008824)
- **Xu, Liu, Yang, Cao & Li (2026), "Parameter estimation via multi-task GRU for incomplete-information orbital pursuit-evasion games," Aerosp Sci Technol 176:112093, DOI 10.1016/j.ast.2026.112093.** A follow-up from the same group that replaces the UKF with a learned GRU estimator (abstract not accessed). — [Crossref](https://doi.org/10.1016/j.ast.2026.112093)
- **Zhang, Wang, Zheng & Zhao (2026), "Spacecraft pursuit-evasion game with incomplete information: A pre-training approximate dynamic programming method," Acta Astronautica 243, DOI 10.1016/j.actaastro.2026.01.071** (preprint SSRN 10.2139/ssrn.5336058). Approximate dynamic programming for incomplete-information PE (abstract not accessed). — [Crossref](https://doi.org/10.1016/j.actaastro.2026.01.071)
- **Guo, Li, Han & Li (2024), "Deducing Spacecraft Incomplete-Information Pursuit-Evasion Games using Partial Observations," IAF Astrodynamics Symposium (IAC 2024), DOI 10.52202/078368-0170.** Infers the game from partial observations (abstract not accessed). — [Crossref](https://doi.org/10.52202/078368-0170)
- **Wang, Zhang & Bi (2025), "Game Strategy Prediction for Spacecraft Orbital Pursuit–Evasion Game Based on Long Short-Term Memory," Space: Sci & Tech 5, DOI 10.34133/space.0279.** Predicts the opponent's game strategy with an LSTM (abstract not accessed). — [Crossref](https://doi.org/10.34133/space.0279)
- **Sun, Han, Wang, Tian & Huang (2026), "Dynamic Time-Window Nash Equilibrium Strategies for Spacecraft Pursuit–Evasion Games Under Incomplete Strategies," Machines 14(3):280, DOI 10.3390/machines14030280.** The evader "can switch maneuvering modes" and deploys countermeasures. The pursuer's perception is modeled as an evidence-theoretic belief, with Jensen–Shannon divergence between nominal and corrupted beliefs driving adaptive re-planning windows. The model uses linearized LVLH dynamics and a continuous Nash formulation. — [Crossref abstract](https://doi.org/10.3390/machines14030280)
- **Wu, Wang & Wu (2024), "Intent inferring based human-machine game control strategy for spacecraft rendezvous," J Franklin Inst 361:106918, DOI 10.1016/j.jfranklin.2024.106918.** Intent inference applied to *human–machine* shared control in rendezvous, not adversarial PE. — [Crossref](https://doi.org/10.1016/j.jfranklin.2024.106918)
- **Mascellani, Oliva, De Maria & Maestrini (2026), "Real-Time Estimation and Control for Orbital Pursuit–Evasion with Angles-Only Navigation," JGCD 49, DOI 10.2514/1.G009598.** Zero-sum, then non-zero-sum SDRE evasion under angles-only navigation, with "uncertain and incomplete information." The uncertainty is about state estimation, not opponent type. — [Crossref abstract](https://doi.org/10.2514/1.G009598)
- **Han & Dang (2026), "Deception in orbital games: simulation and dissimulation with a maneuverable decoy," Scientific Reports 16:15584, DOI 10.1038/s41598-026-46097-6** (NWPU; full text read via [PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC13186990/)).
  - Dynamics are two-body Keplerian with Lambert transfers.
  - A 2x2 game over (which object is the real evader) x (which the pursuer chases first) is solved *analytically* for a mixed Nash equilibrium (indifference conditions, not LP).
  - The multi-step game uses OODA re-planning with a **Bayesian belief over decoy identity** and threshold-triggered resampling.
  - It defines **three pursuer "intelligence levels"** (naive / guesses p / plays mixed Nash). These are opponent sophistication types, but the paper evaluates them, it does not infer them.
  - Maneuver actions are continuous (PSO/BFGS).
  - It has no fictitious play and no greedy or random opponent models.
  - **This is the most conceptually adjacent space paper:** mixed strategies, Bayesian belief, and multiple opponent sophistication levels in an orbital game. But its belief is over *which target is real*, not over the opponent's policy.
- **Shen, Jia, Chen, Blasch & Pham (2015), "Pursuit-evasion games with information uncertainties for elusive orbital maneuver and space object tracking," Proc SPIE 9469:94690J, DOI 10.1117/12.2181160.** Imperfect-information orbital PE with entropy-based costs and Nash / mixed-Nash equilibria, in an SSA tracking setting. The earlier work in the series is Shen et al. 2011, SPIE 8044:80440B, DOI 10.1117/12.882903 (two-step plane-alignment then saddle-point game). — [Crossref](https://doi.org/10.1117/12.2181160); [SPIE 2011](https://spiedigitallibrary.org/conference-proceedings-of-spie/8044/80440B/Pursuit-evasion-orbital-game-for-satellite-interception-and-collision-avoidance/10.1117/12.882903.short)
- **Linville & Hess (2020), "Linear Regression Models Applied to Spacecraft Imperfect Information Pursuit-Evasion Differential Games," AIAA SciTech 2020, DOI 10.2514/6.2020-0952.** Metadata only. — [Crossref](https://doi.org/10.2514/6.2020-0952)
- A Texas A&M dissertation, "Incomplete Information Pursuit-Evasion Games with Applications to Spacecraft Rendezvous and Missile Defense," frames *behavior learning* as estimating the opponent's strategy so that the game reduces to one-sided optimal control. Author and year are not captured. — [OAKTrust handle 1969.1/154101](https://oaktrust.library.tamu.edu/handle/1969.1/154101) **[author/year UNVERIFIED]**

### Inferences
- The orbital PE community's notion of "incomplete information" is mostly **parametric estimation inside a differential game** (UKF on LQ weights, disturbance observers, GRU/LSTM predictors). That is different from **Harsanyi-style type reasoning over a policy library** feeding a best response in a normal-form (lifted) game, which is what we plan.
- The finite-mode IMM papers (Ye 2021; Wang 2024; Wei 2025) are the honest precedent for "a posterior over a finite set of opponent strategies." We should cite them as the space-domain antecedent and differentiate on four points:
  - (i) discrete lifted action sets with an LP mixed equilibrium;
  - (ii) a type library that includes *learning* opponents (fictitious play) and mixed/randomizing opponents, not just two deterministic guidance laws;
  - (iii) exploitation measured against a minimax "price of safety" baseline;
  - (iv) full Keplerian dynamics with impulsive Lambert-seeded trajectories.

### Gaps
- I could not access abstracts or full texts for Tang et al. 2021 (AST), Li et al. 2020 (SCTS), Zhang et al. 2026 (Acta), Guo et al. 2024 (IAC), Wang et al. 2025 (Space), or Xu et al. 2026 (AST). Their exact estimator and information structure should be checked before citing them for anything more specific than "incomplete-information orbital PE with opponent parameter estimation."
- No paper I found explicitly computes a Bayes–Nash equilibrium of an orbital *pursuit-evasion* game.

---

## Q2. Spacecraft PE using matrix games, mixed strategies, discretized maneuver sets, multi-round interception

### Takeaway
Matrix-game and mixed-strategy formulations exist but are rare. Hanlong et al. 2024 is the closest structural match: a multi-round interception matrix game with mixed Nash. It assumes **complete information**, uses a GA solver, and has no opponent learning. No paper I found builds the payoff matrix from per-cell trajectory optimizations to geometric candidate targets, as we do with the hexagon lifting.

### Cited Findings
- **Zhang Hanlong, Zhou Wenya, Zhu Mengping, Xie Zhengyou & Guo Jitang (2024), "Research on Strategies of Multi-Spacecraft Interception Based on Matrix Game," Advances in Astronautics Science and Technology 7(2):101–110, DOI 10.1007/s42423-024-00159-x.** Many-to-many non-cooperative interception "with complete information." It builds a multi-round interception model on matrix-game theory, interprets the Nash mixed strategy, and uses a genetic-algorithm solver. **There is no opponent modeling or learning.** Note that in the bib entry the given and family names are swapped by Zotero: Crossref also lists "Zhang Hanlong" with given = Zhang, family = Hanlong. Most likely the family name is **Zhang** and the given name is **Hanlong**, so the cite key "hanlong..." and "Hanlong et al." are probably wrong. Consider "Zhang et al. 2024". — [Crossref](https://doi.org/10.1007/s42423-024-00159-x); abstract from our refs.bib entry.
- **Han & Dang (2026), Sci Rep** (see Q1): a 2x2 mixed-strategy Nash over target identity, solved analytically, with impulsive Lambert maneuvers. — [PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC13186990/)
- **Yu, Wu, Yin, Chang & Huang (2026), "Diverse strategy generation for orbital pursuit-evasion games using distributed reinforcement learning," Aerosp Sci Technol 168:111052, DOI 10.1016/j.ast.2025.111052.** Discrete choices of Δv direction plus continuous magnitude. It "generates diverse strategy populations satisfying Nash equilibrium" for both sides in GEO one-on-one engagements and computes mixed-strategy Nash equilibria from a payoff matrix over policies. This is a PSRO-style meta-game: matrix games over *learned policies*, not over per-step trajectories. — [Crossref](https://doi.org/10.1016/j.ast.2025.111052); method from [ScienceDirect snippet](https://www.sciencedirect.com/science/article/pii/S1270963825011150)
- **Xu, Zhao, Zhang & Dang (2025), "Delta-V-Based Cooperative Strategies for Orbital Two-Pursuer One-Evader Pursuit–Evasion Games," Space: Sci & Tech 5:0222, DOI 10.34133/space.0222.** Nash equilibrium for 2-v-1 *impulsive* orbital PE, reduced to a composite 1-v-1 game. — [Crossref abstract](https://doi.org/10.34133/space.0222)
- **Becker & Sunberg (2022), "Imperfect Information Games and Counterfactual Regret Minimization in Space Domain Awareness," AMOS 2022, DOI 10.64861/txha9592.** Full text read. MCCFR on a mode-change detection game, plus sparse MCCFR on an orbit-change game with Keplerian dynamics. It shows convergence to unexploitable *stochastic* (mixed) strategies for the satellite and the ground station, explicitly motivated by bluffing and concealment. This is SDA sensor tasking, not PE. — [AMOS PDF](https://amostech.com/TechnicalPapers/2022/Poster/Becker.pdf)
- **Boh, Funke & Akella (2025), "A Game-Theoretical Exploration of L1/L2 Cislunar Space Situational Awareness Using Bayesian Games," AMOS 2025, DOI 10.64861/sijx9169.** Full text read (first pages). A two-player Bayesian game in which teams deploy heterogeneous observers (Watchers / Seekers / Legacy) under a Δv and budget constraint in L1/L2 halo orbits, with observational uncertainty. A companion IAF paper is Boh, Funke & Akella 2025, "Bayesian Game-Theoretic Approaches for Cislunar Space Domain Awareness," IAF Space Systems Symposium, pp. 1123–1136, DOI 10.52202/083091-0099. **This is the only explicit "Bayesian game" in the space domain I found, and it is SSA architecture, not PE.** A search summary said it solves for Bayes–Nash equilibria via a zero-sum LP; I did not confirm this in the text I read. — [AMOS PDF](https://amostech.com/TechnicalPapers/2025/Cislunar_SDA/Boh.pdf)
- A Technion paper, "Pursuit Evasion Guidance in a Switched System," treats incomplete information as worst-case over a finite set of switch sequences, which yields pursuit and evasion *matrix games*. It is planar and missile-type (ZEM), not orbital. **[authors/venue UNVERIFIED]** — [Technion PDF](https://aerospace.technion.ac.il/lab/casy/wp-content/uploads/sites/12/2024/01/PURSUIT-EVASION-GUIDANCE-IN-A-SWITCHED-SYSTEM.pdf)

### Inferences
- In the space literature, "matrix game" means one of three things:
  - a target-assignment or identity game (Hanlong; Han & Dang);
  - a meta-game over trained policies (Yu et al.);
  - a game over abstract SDA actions (Becker; Boh).
- Our lifting, where cells are mean stage cost from 12 per-step trajectory optimizations to hexagon vertices on a receding horizon, appears novel in the orbital PE setting. That is a claim we can make carefully ("to our knowledge").

### Gaps
- I did not find the full text of Hanlong et al. to confirm what the "rounds" are and how the payoff entries are computed (complete information is confirmed from the abstract).

---

## Q3. Learning-based spacecraft PE (RL, MARL, fictitious self-play, opponent modelling)

### Takeaway
There is a heavy RL/MARL literature since about 2021. Opponent diversity is handled by **training-time** self-play, populations, or opponent pools, not by **online** inference of the opponent's policy during an engagement. One 2026 paper has an "opponent modeling module," but it estimates the opponent's *maneuvers* with a Kalman filter. I found **no orbital PE paper that uses fictitious play** as an online learning rule against an opponent.

### Cited Findings
- **Jiang, Ye, Xiao, Sun & Zhang (2023), "Orbital Interception Pursuit Strategy for Random Evasion Using Deep Reinforcement Learning," Space: Sci & Tech 3:0086, DOI 10.34133/space.0086.** The pursuer is trained by DRL against an evader with a random maneuver strategy. This is relevant to our "random" opponent type. — [Crossref abstract](https://doi.org/10.34133/space.0086)
- **Mehlman & Falco (2025), "Satellite Chasers: Divergent Adversarial Reinforcement Learning to Engage Intelligent Adversaries on Orbit," J Aerosp Inf Syst 22:1013–1019, DOI 10.2514/1.I011632** (arXiv 2409.17443). Two-stage MARL that promotes *diverse adversarial strategies* during training for a robust evader. The scenario is 2 "cats" vs 1 "mouse," a partially observable capture-the-flag game. It is from the same Falco group as fotiadis_adversarial_2025. — [Crossref abstract](https://doi.org/10.2514/1.I011632)
- **Li, Lin & Huang (2026), "A physics-informed reinforcement learning framework for impulsive orbital pursuit–evasion under stochastic maneuvers," Complex & Intelligent Systems 12:214, DOI 10.1007/s40747-026-02338-9.** PPO with a "Kalman-driven opponent modeling module" that estimates latent impulsive maneuvers from noisy measurements, plus a CW-based physics-consistency loss. **"Opponent modeling" here means maneuver/state estimation, not policy-type inference.** — [Crossref](https://doi.org/10.1007/s40747-026-02338-9); method from [Springer snippet](https://link.springer.com/article/10.1007/s40747-026-02338-9)
- **Jiang, Zheng, Yu & Yin (2025), "A Population Reinforcement Learning Method for Pursuit-Evasion Game of the Spacecraft," Lecture Notes in Mechanical Engineering, pp. 213–225, DOI 10.1007/978-981-95-3025-0_15.** Generation-wise PPO with *weighted self-play opponent selection*. — [Crossref](https://doi.org/10.1007/978-981-95-3025-0_15)
- **Yu et al. (2026), AST 168:111052**: Nash-equilibrium strategy populations (see Q2).
- **Zhao, Zhang & Dang (2023), "PRD-MADDPG: An efficient learning-based algorithm for orbital pursuit-evasion game with impulsive maneuvers," Adv Space Res 72:211–230, DOI 10.1016/j.asr.2023.03.014.** MADDPG for impulsive orbital PE. — [Crossref](https://doi.org/10.1016/j.asr.2023.03.014)
- **Zhang, Zhang, Zhang, Shi, Tang & Li (2022), "Near-optimal interception strategy for orbital pursuit-evasion using deep reinforcement learning," Acta Astronautica 198:9–25, DOI 10.1016/j.actaastro.2022.05.057.** — [Crossref](https://doi.org/10.1016/j.actaastro.2022.05.057)
- **Yu, Liu & Yue (2024), "Reinforcement learning-based decision-making for spacecraft pursuit-evasion game in elliptical orbits," Control Eng Practice 153:106072, DOI 10.1016/j.conengprac.2024.106072.** — [Crossref](https://doi.org/10.1016/j.conengprac.2024.106072)
- **Yang et al. (2021), "Two-Stage Pursuit Strategy for Incomplete-Information Impulsive Space Pursuit-Evasion Mission…," Aerospace 8(10):299.** Multi-impulse transfer for the far stage, then DDPG for the close-range game under J2, with incomplete information. **[full author list UNVERIFIED]** — [Strathprints PDF](https://strathprints.strath.ac.uk/78158/1/Yang_etal_Aerospace_2021_Two_stage_pursuit_strategy_for_incomplete_information_impulsive_space_pursuit_evasion_mission.pdf); [MDPI](https://www.mdpi.com/2226-4310/8/10/299)
- The search found no orbital PE paper using fictitious play or no-regret learning online. The fictitious-play mentions in space work were training-time solvers in older SSA sensor-management work (Shen/Blasch/Pham line), and I could not confirm them in a specific paper. — search: [SPIE 2011](https://spiedigitallibrary.org/conference-proceedings-of-spie/8044/80440B/Pursuit-evasion-orbital-game-for-satellite-interception-and-collision-avoidance/10.1117/12.882903.short)

### Inferences
- Positioning:
  - RL papers *amortize* robustness into a policy at training time (self-play or populations, approximating a Nash or robust policy).
  - We instead keep the per-step game explicit and **adapt online within a single engagement** (FP over the opponent's vertex frequencies, later a Bayesian posterior over policy types).
  - That is complementary and novel in the orbital PE setting, and it is directly comparable to Jiang et al. 2023 (a pursuer trained against a random evader) and DARL (diversity for robustness).

### Gaps
- Chinese-language journals (e.g., Acta Aeronautica et Astronautica Sinica, J Astronautics, JEIT) may contain opponent-modelling orbital work I did not survey. For example, the JEIT paper "Multi-Agent Deep RL Strategy for Multi-Spacecraft Long-Distance Orbital Game" (DOI 10.11999/JEIT251384) appeared in results but was not examined.

---

## Q4. Baselines frequently cited (brief)

### Takeaway
These are only relevant as complete-information differential-game baselines. None does opponent modeling.

### Cited Findings
- **Fotiadis, Rommel, Falco & Topcu (2025), "Adversarial Pursuits in Cislunar Space," arXiv:2509.20330 (our `fotiadis_adversarial_2025`).** A zero-sum differential game in the CR3BP, solved locally via continuous-time DDP (iterative LQ approximations to HJI). The evader is simulated against a *worst-case* pursuer and a *linear-quadratic* pursuer. This is evaluation against a non-worst-case opponent, but there is **no inference or learning of the opponent**. Its finding that a worst-case design meets a non-worst-case opponent is thematically related to our "price of safety." — refs.bib abstract; [arXiv](https://arxiv.org/abs/2509.20330)
- Our refs.bib also includes Venigalla & Scheeres 2022 (AIAA SciTech, cooperative and non-cooperative collision avoidance), with no opponent modeling. Pontani & Conway 2009, the Jia 2025 approximate approach, and Stupik were not re-verified in this pass.

### Inferences / Gaps
- None.

---

## Q5. Check of refs.bib entries

### Takeaway
None of the five bib entries does opponent modelling in orbital PE. Only `papuc_strategizing_2026` involves interaction-aware game planning, and it is drone racing, not space.

### Cited Findings
- **`papuc_strategizing_2026`: Papuc, Peters, Sun, Ferranti & Alonso-Mora, "Strategizing at Speed: A Learned Model Predictive Game for Multi-Agent Drone Racing," arXiv:2602.06925 (Feb 2026), DOI 10.48550/arXiv.2602.06925.** Compares a Model Predictive Game (MPG, interaction-aware but slow) with contouring MPC (fast, non-interactive). It finds that MPG wins at moderate speed but loses at high speed due to latency, and proposes a *Learned* MPG that amortizes the game solve. **It is not space, not zero-sum PE, and has no opponent type inference.** "Learned" refers to amortizing the solver, not learning the opponent. The relevance is the receding-horizon dynamic game, and the "how deeply should an agent strategize" question parallels our minimax-vs-exploitation trade-off. Distance from our work: far. — refs.bib entry; [arXiv](http://arxiv.org/abs/2602.06925)
- **`hanlongResearchStrategiesMultiSpacecraft2024`**: see Q2. A matrix game with mixed strategies and multi-round interception, under **complete information**, with a GA solver. No opponent modelling. This is the closest bib entry structurally. The author-name order is likely swapped (family name Zhang).
- **`fotiadis_adversarial_2025`**: see Q4. A CR3BP differential game evaluated against worst-case and LQ pursuers. No opponent modelling.
- **`carlo_cyber_2024`: Carlo & Obergfaell, "Cyber attacks on critical infrastructures and satellite communications," Int J Critical Infrastructure Protection 46:100701 (2024), DOI 10.1016/j.ijcip.2024.100701.** A policy, legal, and cyber-resilience review. **No game theory and no opponent modelling.** It is motivation-only.
- **`farago2021coordination`: Faragó, Cîrlugea & Hintea, "Coordination Game Analysis using Brown's Fictitious Play," 44th Int Conf on Telecommunications and Signal Processing (TSP 2021), IEEE, pp. 175–178.** Applies Brown's FP to coordination games. It is generic FP, **not space and not opponent typing**. It could be replaced or supplemented by canonical FP references (Brown 1951; Robinson 1951). I did not fetch the DOI for this pass.

---

## BibTeX-ready entries (8 most important for positioning)

```bibtex
@article{ye2021multiple,
  author  = {Ye, Dong and Tang, Xu and Sun, Zhaowei and Wang, Chunbao},
  title   = {Multiple model adaptive intercept strategy of spacecraft for an incomplete-information game},
  journal = {Acta Astronautica},
  volume  = {180},
  pages   = {340--349},
  year    = {2021},
  doi     = {10.1016/j.actaastro.2020.12.015}
}

@article{wang2024imm,
  author  = {Wang, Chuangge and Chen, Danhe and Liao, Wenhe},
  title   = {Interactive Multiple-Model Learning Filter for Spacecraft Pursuit--Evasion Game Strategy Switch Based on Long Short-Term Memory Network},
  journal = {Aerospace},
  volume  = {11},
  number  = {11},
  pages   = {894},
  year    = {2024},
  doi     = {10.3390/aerospace11110894}
}

@article{li2021escape,
  author  = {Li, ZhenYu and Zhu, Hai and Luo, YaZhong},
  title   = {An escape strategy in orbital pursuit-evasion games with incomplete information},
  journal = {Science China Technological Sciences},
  volume  = {64},
  pages   = {559--570},
  year    = {2021},
  doi     = {10.1007/s11431-020-1662-0}
}

@article{liu2025parameter,
  author  = {Liu, Pengxuan and Yang, Bin and Li, Shuang and Xin, Ming},
  title   = {Parameter-Optimized Pursuit Strategy for Orbital Games with Incomplete Information},
  journal = {Journal of Guidance, Control, and Dynamics},
  volume  = {48},
  number  = {8},
  year    = {2025},
  doi     = {10.2514/1.G008824}
}

@article{han2026deception,
  author  = {Han, Hongyu and Dang, Zhaohui},
  title   = {Deception in orbital games: simulation and dissimulation with a maneuverable decoy},
  journal = {Scientific Reports},
  volume  = {16},
  pages   = {15584},
  year    = {2026},
  doi     = {10.1038/s41598-026-46097-6}
}

@article{zhang2024matrix,
  author  = {Zhang, Hanlong and Zhou, Wenya and Zhu, Mengping and Xie, Zhengyou and Guo, Jitang},
  title   = {Research on Strategies of Multi-Spacecraft Interception Based on Matrix Game},
  journal = {Advances in Astronautics Science and Technology},
  volume  = {7},
  number  = {2},
  pages   = {101--110},
  year    = {2024},
  doi     = {10.1007/s42423-024-00159-x}
}

@article{yu2026diverse,
  author  = {Yu, Tongtong and Wu, Haoran and Yin, Qiyue and Chang, Yongzhe and Huang, Simeng},
  title   = {Diverse strategy generation for orbital pursuit-evasion games using distributed reinforcement learning},
  journal = {Aerospace Science and Technology},
  volume  = {168},
  pages   = {111052},
  year    = {2026},
  doi     = {10.1016/j.ast.2025.111052}
}

@article{jiang2023random,
  author  = {Jiang, Rui and Ye, Dong and Xiao, Yan and Sun, Zhaowei and Zhang, Zeming},
  title   = {Orbital Interception Pursuit Strategy for Random Evasion Using Deep Reinforcement Learning},
  journal = {Space: Science \& Technology},
  volume  = {3},
  pages   = {0086},
  year    = {2023},
  doi     = {10.34133/space.0086}
}
```

Optional extras:

```bibtex
@article{wei2025modeswitching,
  author  = {Wei, Yongshang and Liu, Tianxi and Wei, Cheng},
  title   = {Mode-switching cooperative defense strategy for the orbit pursuit-evasion-defense game},
  journal = {Defence Technology},
  volume  = {44},
  pages   = {272--286},
  year    = {2025},
  doi     = {10.1016/j.dt.2024.10.006}
}

@inproceedings{becker2022cfr,
  author    = {Becker, Tyler and Sunberg, Zachary},
  title     = {Imperfect Information Games and Counterfactual Regret Minimization in Space Domain Awareness},
  booktitle = {Advanced Maui Optical and Space Surveillance Technologies Conference (AMOS)},
  year      = {2022},
  doi       = {10.64861/txha9592}
}

@inproceedings{boh2025bayesian,
  author    = {Boh, John and Funke, Zachary and Akella, Maruthi R.},
  title     = {A Game-Theoretical Exploration of {L1/L2} Cislunar Space Situational Awareness Using Bayesian Games},
  booktitle = {Advanced Maui Optical and Space Surveillance Technologies Conference (AMOS)},
  year      = {2025},
  doi       = {10.64861/sijx9169}
}

@article{mehlman2025darl,
  author  = {Mehlman, Cameron and Falco, Gregory},
  title   = {Satellite Chasers: Divergent Adversarial Reinforcement Learning to Engage Intelligent Adversaries on Orbit},
  journal = {Journal of Aerospace Information Systems},
  volume  = {22},
  pages   = {1013--1019},
  year    = {2025},
  doi     = {10.2514/1.I011632}
}
```
