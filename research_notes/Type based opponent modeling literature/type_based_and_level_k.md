# Type-based opponent reasoning, level-k / cognitive hierarchy, and exploiting learners — prior work for the ECC 2027 lifted-matrix-game paper

Verification legend: **[V]** = verified this session against a primary/publisher/arXiv/dblp page (link given). **[K]** = standard reference given from prior knowledge, bibliographic details believed correct but NOT re-checked this session — check DOI before it enters the .bib. **[U]** = could not verify content.

Our plan, for comparison: Bayesian posterior over a hypothesis set of opponent types {minimax/mixed, greedy, random, always-vertex-k, FP learner}, where every type is a *policy applied to the current stage matrix A_t* (which changes every step, receding horizon), and the FP type is a level-2 model computed exactly from the counts of *my own* past actions + uniform prior.

## (A) Type-based reasoning / hypothesised behaviours / ad hoc teamwork

### Takeaway
Type-based reasoning ("hypothesise a set of opponent policies, keep a Bayesian posterior, best-respond/plan against it") is well established (Albrecht et al., HBA; Southey et al. in poker; Kalai–Lehrer in game theory). The closest work, Albrecht–Crandall–Ramamoorthy (AIJ 2016), uses a *fixed* 2x2 stage game, mainly non-learning types, and uses a fictitious player only as the *true, unmodelled* opponent, not as a hypothesis in the set. We found no type-based work whose hypothesis set includes an exactly computed FP-learner type, and none where the type set is defined as policies on a stage matrix that is regenerated every step.

### Cited Findings
- **Albrecht & Ramamoorthy, "A game-theoretic model and best-response learning method for ad hoc coordination in multiagent systems," AAMAS 2013 (extended abstract, pp. 1155–1156); long version arXiv:1506.01170.** Introduces the *stochastic Bayesian game* (SBG) and **HBA (Harsanyi–Bellman Ad hoc Coordination)**, which keeps a posterior over a user-defined set of types and plans with Bellman-style optimal control against it. Evaluated in a cooperative (logistics / level-based foraging) domain and against humans in repeated Prisoner's Dilemma and Rock-Paper-Scissors. **[V]** — [arXiv](https://arxiv.org/pdf/1506.01170); [IFAAMAS PDF](https://ifaamas.csc.liv.ac.uk/Proceedings/aamas2013/docs/p1415.pdf)
- **Albrecht & Ramamoorthy, "On convergence and optimality of best-response learning with policy types in multiagent systems," UAI 2014; arXiv:1907.06995.** Convergence and optimality conditions for HBA-style posterior updates. **[V existence]** — [arXiv](https://arxiv.org/pdf/1907.06995)
- **Albrecht, Crandall & Ramamoorthy, "Belief and truth in hypothesised behaviours," *Artificial Intelligence* 235:63–94, 2016, doi:10.1016/j.artint.2016.02.004; arXiv:1507.07688.** Studies (1) whether posteriors are correct, under three ways of building them (product, sum, correlated); (2) the long-term effect of priors; (3) acting well with incorrect hypothesised types; (4) statistically detecting that the hypothesis set is wrong. **[V]** — [arXiv](https://arxiv.org/pdf/1507.07688); [AIJ announcement](https://lists.cs.umbc.edu/pipermail/agents/Week-of-Mon-20160328/005394.html)
  - What we found in the full text **[V]**: the prior-belief experiments use the 78 structurally distinct **2x2 repeated games**, so the stage game is fixed. The hypothesised types are automatically generated **Leader-Follower-Trigger** agents (target joint-action sequences, punish deviations with minimax/maximin), **co-evolved decision trees**, and **co-evolved neural nets**. A **fictitious player (FP)** and a **conditioned FP** were used *only as the true player 2*, run for 10,000 rounds. The authors note that "FP and CFP ... try to learn the behaviour of HBA," while the generated types "do not create models of HBA's behaviour." Their Observation 1 is that priors matter because HBA's early actions "shape the beliefs of the other player." So the paper sees the learner-shaping effect but does not put an FP type into the hypothesis set. It also illustrates posterior behaviour with three reinforcement-learning types (Fig. 1). [arXiv full text](https://arxiv.org/pdf/1507.07688)
- **Albrecht & Stone, "Reasoning about hypothetical agent behaviours and their parameters," AAMAS 2017; arXiv:1906.11064.** Extends type-based reasoning to *parameterised* types, inferring a type's continuous parameters along with which type it is. **[V existence]** — [UT page](https://www.cs.utexas.edu/~pstone/Papers/bib2html/b2hd-AAMAS17-Albrecht.html); [arXiv](https://arxiv.org/abs/1906.11064)
- **Albrecht & Stone, "Autonomous agents modelling other agents: A comprehensive survey and open problems," *Artificial Intelligence* 258:66–95, 2018; arXiv:1709.08071.** The standard survey. It classifies methods as policy reconstruction, type-based reasoning, classification, plan recognition, recursive reasoning (I-POMDP, level-k), graphical models, and group modelling. It is the right citation for positioning "type-based + recursive (level-k) reasoning". **[V existence; DOI from prior knowledge: 10.1016/j.artint.2018.01.002 — K]** — [arXiv](https://arxiv.org/abs/1709.08071v2); [UT page](https://www.cs.utexas.edu/~pstone/Papers/bib2html/b2hd-AIJ18-Albrecht.html)
- **Southey, Bowling, Larson, Piccione, Burch, Billings & Rayner, "Bayes' Bluff: Opponent modelling in poker," UAI 2005; arXiv:1207.1411.** Bayesian posterior over opponent strategies in (small) poker, with best responses to the posterior. This is an adversarial, zero-sum instance of type/posterior reasoning, but the opponent is stationary. **[K]**
- **Ganzfried (2016) "Bayesian opponent exploitation in imperfect-information games,"** arXiv:1603.03491. Bayesian best response to a Dirichlet-type opponent model in zero-sum imperfect-information games. Search summaries note that in normal-form games the efficient Bayesian-exploitation update "is essentially fictitious play," i.e. counts + best response. **[V existence]** — [arXiv](https://arxiv.org/pdf/1603.03491)
- **Stone, Kaminka, Kraus & Rosenschein, "Ad hoc autonomous agent teams," AAAI 2010** — defines ad hoc teamwork. **[K]**
- **Barrett, Stone & Kraus, "Empirical evaluation of ad hoc teamwork in the pursuit domain," AAMAS 2011**, and **Barrett, Rosenfeld, Kraus & Stone, "Making friends on the fly," *Artificial Intelligence* 242:132–171, 2017.** Bayesian belief over teammate models in a *predator–prey pursuit* grid domain. Note that the teammates are cooperative pursuers, and the adversary (prey) is not the modelled agent. **[K]**
- **Kalai & Lehrer, "Rational learning leads to Nash equilibrium," *Econometrica* 61(5):1019–1045, 1993.** The game-theory root of Bayesian/"rational" learning over opponent types (cited by Albrecht et al. 2016 as the origin). **[K]**
- **Yang, Hao, Meng, Zhang, Zheng & Zheng, "Towards efficient detection and optimal response against sophisticated opponents" (Bayes-ToMoP), IJCAI 2019, pp. 623–629, doi:10.24963/ijcai.2019/88; arXiv:1809.04240.** Combines Bayesian Policy Reuse with theory-of-mind recursive reasoning, to detect opponents that are either stationary or *higher-order reasoners about the agent itself*, in two-agent competitive games. This is the closest ML analogue to "a type that models me." **[V]** (author list beyond Yang & Hao is from prior knowledge) — [IJCAI](https://www.ijcai.org/proceedings/2019/88); [arXiv](https://arxiv.org/abs/1809.04240v5)
- **Rosman, Hawasly & Ramamoorthy, "Bayesian policy reuse," *Machine Learning* 104:99–127, 2016**, and **Hernandez-Leal et al. (BPR+, 2016)** handle switching / non-stationary opponents with a Bayesian belief over a policy library. **[K]**

### Inferences
- On whether these methods handle a stage game that changes every round: HBA and the SBG formalism do allow *state-dependent* types (types map the history and state to an action distribution), so in principle a type can be "a policy applied to the current stage matrix." The empirical studies we checked, however, use fixed 2x2 repeated games or cooperative gridworlds. Our "types as maps from A_t to a vertex distribution, on a fresh 6x6 each step" is therefore a legitimate SBG instance but empirically new. Present it as "an instance of HBA/SBG type-based reasoning in which types are stage-game solution concepts," not as a new framework.
- On adversarial or zero-sum settings: poker (Southey; Ganzfried) and Bayes-ToMoP (competitive games) cover them. The Albrecht line is mostly cooperative or general-sum.
- On learner types: Albrecht et al. 2016 explicitly put an FP learner against HBA, but only as the out-of-hypothesis truth. Our use of FP as a *hypothesised type* is new relative to that paper. Bayes-ToMoP's higher-order-reasoning opponents are the nearest precedent for a type that models the agent.

### Gaps
- We did not open the Albrecht PhD thesis (Edinburgh, 2015) or the AAAI 2015 paper "An empirical study on the practical impact of prior beliefs over policy types." Either might include a learner type in a hypothesis set. **[U]**
- We did not check the Bayes-ToMoP experiments for whether the "sophisticated" opponent is an FP-style learner or a ToM-level reasoner. **[U]**

## (B) Level-k / cognitive hierarchy, including strategic teaching and level-k against learners

### Takeaway
Level-k (Stahl–Wilson; Nagel; Costa-Gomes–Crawford–Broseta) and cognitive hierarchy (Camerer–Ho–Chong 2004) model *static* depth of reasoning, where level-0 is usually uniform random. The economics precedent for "knowing the other player is a learner" is **sophisticated EWA / strategic teaching** (Camerer–Ho–Chong 2002, JET). There, sophisticated players model a population of adaptive EWA learners, and farsighted ones "teach." In control, the level-k + Bayesian-inference + receding-horizon combination already exists for autonomous driving (Li et al., CDC 2019) and for aerial pursuit-evasion (Guan et al., ACC 2021). Our novelty therefore cannot be "Bayesian level-k in pursuit-evasion." It has to be the specific lifted-matrix-game setting and the inclusion of an FP-learner type that is computed exactly from my own action counts.

### Cited Findings
- **Stahl & Wilson, "On players' models of other players: Theory and experimental evidence," *Games and Economic Behavior* 10(1):218–254, 1995.** The level-n types model. **[K]**
- **Nagel, "Unraveling in guessing games: An experimental study," *American Economic Review* 85(5):1313–1326, 1995.** Beauty-contest evidence for iterated reasoning depth. **[K]**
- **Costa-Gomes, Crawford & Broseta, "Cognition and behavior in normal-form games: An experimental study," *Econometrica* 69(5):1193–1235, 2001.** **[K]**
- **Camerer, Ho & Chong, "A cognitive hierarchy model of games," *Quarterly Journal of Economics* 119(3):861–898, 2004** (DOI believed to be 10.1162/0033553041502225). Poisson-distributed levels; each level best-responds to the normalised distribution of the lower levels. **[K]**
- **Camerer, Ho & Chong, "Sophisticated experience-weighted attraction learning and strategic teaching in repeated games," *Journal of Economic Theory* 104(1):137–188, 2002, doi:10.1006/jeth.2002.2927.** Mixes adaptive EWA learners with sophisticated players who know others learn. Farsighted sophisticated players "strategically teach," i.e. shape the learners' future beliefs. Fit to p-beauty-contest and repeated trust-game data. This is the conceptual ancestor of "a level-2 type that predicts an FP learner's response to my own history." Note that EWA nests FP (belief learning) as a special case — **[K]** for the nesting claim. **[V]** — [Caltech record](https://authors.library.caltech.edu/records/acy85-62128); [SUFE listing](https://academicnewsletter.sufe.edu.cn/info/303602)
- **Chong, Camerer & Ho, "A learning-based model of repeated games with incomplete information," *Games and Economic Behavior*, 2006.** Follow-up on teaching in trust and entry games. **[V existence]** — [listing](https://academicnewsletter.sufe.edu.cn/info/329752)
- **Li, Li, Girard & Kolmanovsky, "Decision making in dynamic and interactive environments based on cognitive hierarchy theory, Bayesian inference, and predictive control," IEEE CDC 2019; arXiv:1908.04005.** Two-player dynamic game in which the ego infers the other driver's cognitive level by Bayesian inference and acts with receding-horizon optimal control. This is **structurally the closest control-venue precedent** for "Bayesian posterior over level types + receding horizon." **[V]** — [arXiv](https://arxiv.org/abs/1908.04005)
- **Guan, Maity, Kroninger & Tsiotras, "Bounded-rational pursuit-evasion games," American Control Conference 2021, doi:10.23919/ACC50511.2021.9483152.** Discretises a stochastic aerial pursuit-evasion game into a sequence of finite MDPs, solves it with level-k / cognitive hierarchy, and gives an **online algorithm for each agent to infer the opponent's rationality level**. This is **the closest pursuit-evasion precedent and must be cited.** Its types are reasoning levels, not learners, and the setting is aerial, not orbital. **[V]** — [NSF PAR](https://par.nsf.gov/biblio/10315945)
- **Li, Oyler, Zhang, Yildiz, Kolmanovsky & Girard, "Game theoretic modeling of driver and vehicle interactions for verification and validation of autonomous vehicle control systems," *IEEE Trans. Control Systems Technology* 26(5), 2018.** Level-k driver models in control. **[K]**
- **Gmytrasiewicz & Doshi, "A framework for sequential planning in multi-agent settings" (I-POMDP), *JAIR* 24:49–79, 2005.** Nested beliefs over other agents' models. This is the general recursive-modelling formalism that subsumes "level-2 model of an FP learner." **[K]**
- **Kokolakis & Vamvoudakis? / others on level-k in pursuit-evasion** — not verified; nothing found by search. **[U]**

### Inferences
- In standard level-k/CH, level-0 is uniform random and higher levels best-respond. Our FP type is a different kind of level-2: the FP opponent best-responds to the *empirical frequency of my actions*, which is a learning level-1 rather than a reasoning level-1. Strictly, our FP type is "level-1 over a history-based level-0 (my empirical mixture)," and our agent reasoning about it is level-2. That matches the sophisticated-EWA idea (sophisticated players model adaptive learners) more closely than Nagel/CH. Cite Camerer–Ho–Chong 2002 as the conceptual ancestor.
- We found no level-k or CH paper in which the level-0/level-1 anchor is a fictitious-play learner and the higher level exploits it in a *zero-sum* game. The economics teaching papers use trust and entry games, which are general-sum.

### Gaps
- No search hit for "level-k against fictitious play" as such. One more targeted Scholar query would be prudent, e.g. "sophisticated learner fictitious play zero-sum".
- We did not verify the content of Tian, Li, Kolmanovsky & Girard (T-ITS 2022) or of the roundabout CDC 2018 paper (Tian et al.). **[U]**

## (C) Exploiting learners: no-regret, FP, opponent shaping

### Takeaway
There is a solid theory of an "optimizer" who knows the learner's algorithm (Deng–Schneider–Sivan 2019; Assos–Dagan–Daskalakis 2024). Against no-regret learners in **zero-sum** games the optimizer is essentially capped at the game value. Assos et al. nonetheless show that one can strictly beat the value against *specific* algorithms (Replicator Dynamics, discrete MWU). Classic FP is *not* no-regret, so it can be exploited above the value. Only narrow results exist for FP specifically (Dong & Mu on 2x2 games). This supports our empirical finding that a level-2 FP model can exploit an FP pursuer/evader, while the theory says you cannot beat a proper randomizer (cf. our oracle-vs-`mixed` result).

### Cited Findings
- **Deng, Schneider & Sivan, "Strategizing against no-regret learners," NeurIPS 2019; arXiv:1909.13861.** Against a no-regret learner, the optimizer can always guarantee its Stackelberg value. With two learner actions it cannot exceed that. Against *mean-based* learners (a class that includes MWU and FP-like follow-the-leader) it can do strictly better in general-sum games. Against no-swap-regret learners it cannot exceed Stackelberg. In a zero-sum game the Stackelberg value equals the minimax value, so a no-regret opponent cannot be exploited beyond the value in the limit. **[V for the main results; the zero-sum corollary is our inference]** — [arXiv](https://arxiv.org/abs/1909.13861); [NeurIPS](https://papers.nips.cc/paper/2019/hash/8b6dd7db9af49e67306feb59a8bdc52c-Abstract.html)
- **Assos, Dagan & Daskalakis, "Maximizing utility in multi-agent environments by anticipating the behavior of other learners," NeurIPS 2024; arXiv:2407.04889.** Here an optimizer knows the learner's algorithm and utility. In **repeated zero-sum games** the optimal strategy against Replicator Dynamics is exactly computable, and against discrete-time MWU they build an optimizer that **strictly exceeds the one-shot game value** on average. In general-sum games, no FPTAS exists unless P=NP. This is **the strongest theory precedent for "exploit a known learner in a zero-sum game."** **[V]** — [arXiv](https://arxiv.org/abs/2407.04889); [NeurIPS PDF](https://proceedings.neurips.cc/paper_files/paper/2024/file/4476dd7320e0eba63961990d73525064-Paper-Conference.pdf)
- **Dong & Mu, "The optimal strategy against the opponent adopting fictitious play algorithm in infinitely repeated 2×2 games," SSRN working paper, doi:10.2139/ssrn.4201849.** According to the search summary, the optimal strategy against FP in 2x2 games depends on the payoff ordering, play cycles when the payoff parameter is rational, and "the FP algorithm can be exploited to the utmost extent." **[V existence via DOI; the abstract content comes only from the search snippet, since the SSRN page returned 403 — treat as U for details]** — [SSRN DOI](https://doi.org/10.2139/ssrn.4201849)
- **Guo & Mu, optimal strategy against Hedge in finitely repeated 2×2 zero-sum games, *Journal of Global Optimization* 93(3):861–895, 2025, doi:10.1007/s10898-025-01554-w; arXiv:2312.09472.** Exact exploitation of a known no-regret learner in a zero-sum game, for 2x2 only. **[V existence and venue]** — [IDEAS](https://ideas.repec.org/a/spr/jglopt/v93y2025i3d10.1007_s10898-025-01554-w.html); [arXiv](https://www.arxiv.org/pdf/2312.09472)
- **"Exploiting a no-regret opponent in repeated zero-sum games," *J. Shanghai Jiao Tong Univ. (Science)*, 2023, doi:10.1007/s12204-023-2610-2.** Models an adaptive no-regret opponent with an RNN and responds greedily. **[V existence; authors not captured]** — [Springer](https://link.springer.com/article/10.1007/s12204-023-2610-2)
- **Ganzfried & Sandholm, "Safe opponent exploitation," *ACM Trans. Economics and Computation* 3(2):8:1–8:28, 2015** (EC 2012 conference version). Characterises when one can deviate from Nash to exploit a model in repeated zero-sum games *without* risking less than the value, essentially by spending "gifts" accumulated earlier. **Directly relevant to our "price of safety" framing.** **[V citation via dblp snippet]** — [dblp](https://dblp.org/pid/00/744)
- **Johanson, Zinkevich & Bowling, "Computing robust counter-strategies," NeurIPS 2007** (restricted Nash response). Trades exploitation against exploitability. **[K]**; mentioned in [search summary](https://proceedings.neurips.cc/paper_files/paper/2022/file/b12a1d1014e952e676f5d6931d03241a-Paper-Conference.pdf)
- **Foerster, Chen, Al-Shedivat, Whiteson, Abbeel & Mordatch, "Learning with opponent-learning awareness" (LOLA), AAMAS 2018; arXiv:1709.04326.** Differentiates through the opponent's learning step to shape it. This is "exploit/shape a learner" for gradient learners. Follow-ups include Letcher et al., "Stable opponent shaping," ICLR 2019, and Lu et al., "Model-free opponent shaping," ICML 2022. **[K]**
- **Powers & Shoham, "New criteria and a new algorithm for learning in multi-agent systems," NIPS 2004**, and **"Learning against opponents with bounded memory," IJCAI 2005.** "Targeted optimality" against a known opponent class, plus safety. **Chakraborty & Stone, "Multiagent learning in the presence of memory-bounded agents," *JAAMAS* 28, 2014.** **[K]**
- FP background: **Brown (1951)**; **Robinson, "An iterative method of solving a game," *Annals of Math.* 54, 1951** (FP converges to the value in zero-sum games); **Daskalakis & Pan, "A counter-example to Karlin's strong conjecture for fictitious play," FOCS 2014** (FP can converge exponentially slowly). These explain why FP is exploitable for long transients. **[K]**; the slow-rate claim also appears in the [search summary](https://arxiv.org/pdf/2010.04223)

### Inferences
- Classic (unsmoothed, deterministic best-response) FP is not Hannan-consistent, so the Deng et al. ceiling does not bind it. Exploiting FP beyond the value in zero-sum games is therefore theoretically expected. This is consistent with our FP-greedy-vs-FP results. A *smoothed* FP is no-regret, and our edge against it should then vanish asymptotically. Consider saying this explicitly.
- Our observed result ("omniscience is worth nothing against a proper randomizer") is the zero-sum special case of Deng et al.'s Stackelberg = minimax ceiling. It is cite-able, not novel as theory.

### Gaps
- We found no paper that exploits FP in *general n×n zero-sum* games with a closed-form level-2 predictor. Dong & Mu covers 2×2 only, and its contents are unverified.

## (D) Is there prior work combining Bayesian type inference with an FP-learner type in a repeated or stochastic game?

### Takeaway
We did not find one. The nearest pieces are: (i) Albrecht–Crandall–Ramamoorthy 2016, which has Bayesian types but uses FP only as the true opponent outside the hypothesis set; (ii) Bayes-ToMoP, which has Bayesian detection of higher-order-reasoning opponents; (iii) sophisticated EWA, where players know others are learners, but there is no Bayesian identification among types; (iv) Li et al. CDC 2019 and Guan et al. ACC 2021, with Bayesian or online inference over *reasoning levels* in receding-horizon or pursuit-evasion settings. We frame the claim as "to our knowledge" and cite all four.

### Cited Findings
- FP appears only as an unmodelled opponent in the HBA prior study — [Albrecht et al. 2016](https://arxiv.org/pdf/1507.07688)
- Bayesian detection of stationary vs higher-order-reasoning opponents — [Yang et al. IJCAI 2019](https://www.ijcai.org/proceedings/2019/88)
- Sophisticated players modelling adaptive learners, with strategic teaching — [Camerer, Ho & Chong JET 2002](https://authors.library.caltech.edu/records/acy85-62128)
- Online inference of the opponent's level-k in pursuit-evasion — [Guan et al. ACC 2021](https://par.nsf.gov/biblio/10315945)
- Bayesian inference over cognitive-hierarchy levels + receding-horizon control — [Li et al. CDC 2019](https://arxiv.org/abs/1908.04005)

### Inferences
- The honest positioning is as follows. Type-based reasoning (HBA/SBG) and level-k inference in control and pursuit-evasion both exist. The contributions are (1) instantiating the type set as *stage-game solution concepts re-evaluated on a time-varying lifted matrix*; (2) including an exactly computable FP-learner type, a level-2 model in the sophisticated-EWA / strategic-teaching sense, inside the Bayesian hypothesis set; and (3) the orbital pursuit-evasion application with a measured price of safety. That third point should be tied to Ganzfried–Sandholm safe exploitation and to the zero-sum ceiling of Deng et al.
- One caveat to anticipate from reviewers: an FP type that models *me* makes the opponent's behaviour depend on my own past actions, so the posterior is not over a stationary process. Albrecht et al. 2016 is the reference on when posteriors stay correct, and on detecting wrong hypothesis sets.

### Gaps
- The "no prior work" claim rests on roughly 15 searches and is not exhaustive. Semantic Scholar forward citations of Albrecht et al. 2016 and of Deng et al. 2019 should be checked for "fictitious play type" before submission.

## BibTeX (8 most important)

```bibtex
@article{albrecht2016belief,
  author  = {Albrecht, Stefano V. and Crandall, Jacob W. and Ramamoorthy, Subramanian},
  title   = {Belief and Truth in Hypothesised Behaviours},
  journal = {Artificial Intelligence},
  volume  = {235},
  pages   = {63--94},
  year    = {2016},
  doi     = {10.1016/j.artint.2016.02.004}
}

@inproceedings{albrecht2013hba,
  author    = {Albrecht, Stefano V. and Ramamoorthy, Subramanian},
  title     = {A Game-Theoretic Model and Best-Response Learning Method for Ad Hoc Coordination in Multiagent Systems},
  booktitle = {Proc. 12th Int. Conf. on Autonomous Agents and Multiagent Systems (AAMAS)},
  pages     = {1155--1156},
  year      = {2013},
  note      = {Extended version: arXiv:1506.01170}
}

@article{albrecht2018survey,
  author  = {Albrecht, Stefano V. and Stone, Peter},
  title   = {Autonomous Agents Modelling Other Agents: A Comprehensive Survey and Open Problems},
  journal = {Artificial Intelligence},
  volume  = {258},
  pages   = {66--95},
  year    = {2018},
  doi     = {10.1016/j.artint.2018.01.002}
}

@article{camerer2002sophisticated,
  author  = {Camerer, Colin F. and Ho, Teck-Hua and Chong, Juin-Kuan},
  title   = {Sophisticated Experience-Weighted Attraction Learning and Strategic Teaching in Repeated Games},
  journal = {Journal of Economic Theory},
  volume  = {104},
  number  = {1},
  pages   = {137--188},
  year    = {2002},
  doi     = {10.1006/jeth.2002.2927}
}

@article{camerer2004cognitive,
  author  = {Camerer, Colin F. and Ho, Teck-Hua and Chong, Juin-Kuan},
  title   = {A Cognitive Hierarchy Model of Games},
  journal = {Quarterly Journal of Economics},
  volume  = {119},
  number  = {3},
  pages   = {861--898},
  year    = {2004},
  doi     = {10.1162/0033553041502225}
}

@inproceedings{deng2019strategizing,
  author    = {Deng, Yuan and Schneider, Jon and Sivan, Balasubramanian},
  title     = {Strategizing against No-regret Learners},
  booktitle = {Advances in Neural Information Processing Systems (NeurIPS)},
  volume    = {32},
  year      = {2019},
  note      = {arXiv:1909.13861}
}

@inproceedings{assos2024maximizing,
  author    = {Assos, Angelos and Dagan, Yuval and Daskalakis, Constantinos},
  title     = {Maximizing Utility in Multi-Agent Environments by Anticipating the Behavior of Other Learners},
  booktitle = {Advances in Neural Information Processing Systems (NeurIPS)},
  volume    = {37},
  year      = {2024},
  note      = {arXiv:2407.04889}
}

@inproceedings{guan2021bounded,
  author    = {Guan, Yue and Maity, Dipankar and Kroninger, Christopher M. and Tsiotras, Panagiotis},
  title     = {Bounded-Rational Pursuit-Evasion Games},
  booktitle = {American Control Conference (ACC)},
  year      = {2021},
  doi       = {10.23919/ACC50511.2021.9483152}
}

@inproceedings{li2019cognitive,
  author    = {Li, Sisi and Li, Nan and Girard, Anouck and Kolmanovsky, Ilya},
  title     = {Decision Making in Dynamic and Interactive Environments Based on Cognitive Hierarchy Theory, {B}ayesian Inference, and Predictive Control},
  booktitle = {IEEE Conference on Decision and Control (CDC)},
  year      = {2019},
  note      = {arXiv:1908.04005}
}

@article{ganzfried2015safe,
  author  = {Ganzfried, Sam and Sandholm, Tuomas},
  title   = {Safe Opponent Exploitation},
  journal = {ACM Transactions on Economics and Computation},
  volume  = {3},
  number  = {2},
  pages   = {8:1--8:28},
  year    = {2015}
}
```
Notes on the BibTeX: the AAMAS 2013 page range, the AIJ 2018 DOI, and the QJE DOI are from prior knowledge **[K]**. Check them on the publisher pages before final use. The CDC 2019 page numbers and DOI were not retrieved.
