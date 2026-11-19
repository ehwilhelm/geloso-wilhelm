---
title: "Section 2.3: measurement error before and after treatment"
subtitle: "Proposals to extend Eqs. 1-6 of the Geloso-Wilhelm draft"
---

*Draft for Eric's review, 17 November 2026. Notation follows Section 2.3 of
`Papers/LiberalizationIMRData.pdf`. All math is plain ASCII LaTeX.*

# 0. Notation added to the draft's

Each treatment episode is a 5-year window. Write $0$ for the start of the
window ($t-5$, "pre") and $1$ for its end ($t$, "post"). $D_i = 1$ if country
$i$'s EFW summary moves by at least one point over the window. $S_{i0}$ and
$S_{i1}$ are O'Reilly-Murphy state capacity at the start and end, and $Q_{i0}$
and $Q_{i1}$ are statistical capacity, proxied by the IGME interval. $X_{i0}$
holds the other pre-period matching covariates, with Polity5 among them as
regime type.

Eq. 1 holds at both dates:

$$
Y^{obs}_{is} = Y^{true}_{is} + u_{is}, \qquad s \in \{0, 1\}.
$$

**The key change from the draft.** Eq. 3 writes the ATT in post-treatment
*levels*, but our estimator uses the 5-year *change*
$\Delta Y_i = Y_{i1} - Y_{i0}$. Rewriting Eqs. 3-6 in changes is what brings
"pre" and "post" into the theory.

# Proposal A: Measurement bias as a difference-in-differences

Differencing Eq. 1 gives

$$
\Delta Y^{obs}_i = \Delta Y^{true}_i + \Delta u_i,
\qquad \Delta u_i = u_{i1} - u_{i0}.
$$

Substituting this into the change version of Eq. 3:

$$
\hat{\tau}^{obs}_{ATT}
= \frac{1}{N_T}\sum_{i \in T}\Big[\Delta Y^{obs}_i - \sum_{j \in C} w_{ij}\,\Delta Y^{obs}_j\Big]
= \hat{\tau}^{true}_{ATT} + \big(\overline{\Delta u}_T - \overline{\Delta u}^{M}_C\big).
$$

Writing out the last term:

$$
\text{Bias}
= \underbrace{\big(\bar{u}_{T,1} - \bar{u}^{M}_{C,1}\big)}_{\text{post: treated minus matched controls}}
- \underbrace{\big(\bar{u}_{T,0} - \bar{u}^{M}_{C,0}\big)}_{\text{pre: treated minus matched controls}} .
$$

**What this adds to Section 2.3.**

- The bias is the *gap in measurement error between treated and comparison
  countries after treatment, minus the same gap before*. That is the
  "difference between treated and comparison countries over the treatment
  window" that the section is missing.
- **Eq. 2 is necessary but not sufficient.** A gap in levels of measurement
  error, $E[u_{is} \mid S_i] \neq E[u_{is}]$, that stays fixed across the
  window cancels out of the change. Bias needs the *change* in measurement
  error to differ by treatment status:

$$
E[\Delta u_i \mid D_i = 1, X_{i0}, S_{i0}] \neq E[\Delta u_i \mid D_i = 0, X_{i0}, S_{i0}] .
$$

- This gives the identifying assumption a clean statement, a **conditional
  parallel-measurement assumption**: once matched on pre-period covariates,
  state capacity and statistical capacity, treated and controls have the same
  expected change in measurement error.

$$
E[\Delta u_i \mid D_i = 1, X_{i0}, S_{i0}, Q_{i0}] = E[\Delta u_i \mid D_i = 0, X_{i0}, S_{i0}, Q_{i0}] .
$$

  The "residual selection" argument then reads: matching on $S_{i0}$ alone
  does not deliver this, and adding $Q_{i0}$ moves us closer to it.

# Proposal B: Make the error depend on data quality (IGME shrinkage)

Proposal A says *when* bias arises but not its sign. A model of how IGME
builds its estimates supplies one. Where data are thin, the B3 model pulls the
estimate toward a smooth model trend $m_{is}$. Let $q_{is} \in [0,1]$ be the
weight on country data, so $q$ is high where vital registration is good and
low in survey-only countries:

$$
Y^{obs}_{is} = q_{is}\,Y^{true}_{is} + (1 - q_{is})\,m_{is}
\quad\Longrightarrow\quad
u_{is} = (1 - q_{is})\,(m_{is} - Y^{true}_{is}) .
$$

Under normal-normal shrinkage, $1 - q_{is}$ is the share of posterior variance
that comes from the model. That ties it to the width of the IGME interval, the
proxy we actually observe: a wider interval means a lower $q_{is}$.

Hold $q$ fixed within the window. Take matched pairs with the same model trend
($\Delta m_i = \Delta m_j = \Delta m$), and assume the controls' true change
equals the treated country's counterfactual, $\Delta Y^{true}_j = \Delta Y_i(0)$.
Then

$$
\hat{\tau}^{obs}_{ATT}
\approx \underbrace{\bar{q}_T\,\tau^{true}_{ATT}}_{\text{attenuation}}
+ \underbrace{\frac{1}{N_T}\sum_{i \in T}\sum_{j \in C} w_{ij}\,(q_i - q_j)\,\big(\Delta Y_i(0) - \Delta m\big)}_{\text{measurement composition}} .
$$

**Two forces with opposite pulls:**

1. **Attenuation** ($\bar{q}_T < 1$). The model trend does not know a country
   liberalized, so poor measurement shrinks the observed effect toward zero.
   This is the original "data quality hides gains" pitch.
2. **Composition** ($q_i \neq q_j$). If treated countries are measured *better*
   than their matches ($q_T > q_C$), and true counterfactual declines run
   faster than the model trend, the observed effect is *inflated*. That fits
   the October finding: liberalizers had narrower intervals than their matches
   (SMD $-0.43$), and adding the interval shrank the ATT.

Proposal B therefore states when the paper's title claim holds ("liberalizers
remember dead babies", so the composition term dominates) and when the
opposite would hold (attenuation dominates). It also explains why matching on
$Q_{i0}$ addresses the composition term (it balances $q_i$ against $q_j$) but
not attenuation, which needs a correction for $\bar{q}_T$.

# Proposal C: Time-varying state capacity inside the window

State capacity changes over time, and a liberalization can raise it (the
case-study sheet: "liberalization precedes improvements in state capacity").
Let the data weight vary with capacity, $q_{is} = q(S_{is}, Q_{is})$, and
expand the change in error:

$$
\Delta u_i
= \underbrace{(1 - q_{i0})\,\Delta(m_i - Y^{true}_i)}_{\text{fixed-quality part}}
\;-\; \underbrace{\Delta q_i\,(m_{i1} - Y^{true}_{i1})}_{\text{quality changes during the window}} .
$$

Combine this with Proposal A. Matching on pre-period values ($S_{i0}$,
$Q_{i0}$) balances the first term. The second term depends on

$$
E[\Delta q_i \mid D_i = 1] - E[\Delta q_i \mid D_i = 0],
\qquad \Delta q_i \approx \frac{\partial q}{\partial S}\,\Delta S_i + \frac{\partial q}{\partial Q}\,\Delta Q_i .
$$

If liberalizers build statistical capacity *during* the reform (new surveys,
better registration), this term is non-zero, and no pre-treatment matching can
remove it. $\Delta S_i$ and $\Delta Q_i$ are post-treatment, so conditioning on
them would be a bad control.

**What we can do with it:**

- Report $\Delta Q_i$ (and $\Delta S_i$) for treated and matched controls as a
  *diagnostic*, not a control, and not an outcome, in keeping with Vincent's
  note.
- Sign the bias: when the true model gap $(m_{i1} - Y^{true}_{i1})$ has a known
  sign, the direction of the bias follows from the sign of the gap in
  $\Delta q$.
- Bound it with a sensitivity parameter, e.g. "the result survives unless
  treated countries gained more than $\delta$ in measurement weight relative to
  controls."

# Proposal D: An event-study version

Use several windows around treatment at $k = 0$ and define the measurement gap
in each window:

$$
G_k = \bar{u}_{T,k} - \bar{u}^{M}_{C,k},
\qquad k \in \{-2, -1, 0, +1\} .
$$

The bias in Proposal A is $G_0 - G_{-1}$. A pre-trend test is then
$G_{-1} - G_{-2} = 0$. We can't observe $u$ directly, but the same contrast in
the observed interval width ($Q$) and in the placebo outcome (the IMR change in
the window before treatment, robustness R4 in the plan) shows whether matched
pairs were on parallel measurement paths before treatment. This links the
theory section to Section 7 of the analysis plan.

# Recommendation

- Put **Proposal A** in the text. It is a one-line extension of Eqs. 3-6, it
  answers "what is missing" directly, and it gives the paper a stated
  identifying assumption.
- Use **Proposal B** for the intuition and the sign. It explains both the
  "hidden gains" pitch and the October result (shrinkage) in one equation.
- Put **Proposal C** in a short paragraph or a footnote on time-varying state
  capacity and why we match only on pre-period values. It also motivates
  reporting $\Delta Q$ as a diagnostic.
- Keep **Proposal D** for the empirical section.
