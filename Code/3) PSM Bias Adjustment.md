# Bias-adjusted propensity score matching for the IMR level outcome

*Draft for Eric's review, 19 November 2026 (workplan item 2b for 20 Nov).
Companion to Section 3b of `Code/3) Revised Analysis Plan.md` and to
`Code/3) Revised Analysis (draft).R`. Plain ASCII so it compiles through
LaTeX.*

## 1. Why an adjustment is needed

Until 19 November the outcome was a 5-year *change* in infant mortality.
Differencing removes each country's starting IMR level, so a treated country
and its matches could start from somewhat different IMR levels without that
gap showing up in the estimate. With the IMR *level* at $t+5$ as the outcome,
the starting level carries straight through: IMR is very persistent, so a
country that starts 10 deaths per 1,000 higher is still about 8 to 9 higher
ten years later.

Propensity score matching (PSM) matches on a single number, the estimated
probability of treatment. Two countries with the same propensity score can
still differ in their IMR at $t-5$, because that score blends IMR with the
other covariates. Whatever IMR gap is left after matching passes almost one
for one into a plain PSM estimate on the level outcome. That is why the plain
PSM estimates jumped around and had standard errors of 4 to 7 deaths per
1,000, while the Mahalanobis estimator, which already corrects for leftover
covariate gaps, stayed tight.

The bias adjustment removes the part of the estimate that is explained by
the leftover gap in IMR at $t-5$.

## 2. Notation

- Each observation $i$ is a country and a 5-year EFW window from $t-5$ to
  $t$.
- $D_i = 1$ for a treated window: a liberalization (EFW score up by more
  than 1 point; headline) or a deliberalization (down by more than 1 point;
  appendix). Strict thresholds from 20 Nov, as in the literature. $T$ is the set of treated windows, $N_1$ their number, and $C$
  the comparison pool.
- $Y_i = IMR_{i,t+5}$: the outcome, infant deaths per 1,000 live births
  (UN IGME), five years after the window.
- $M_i = IMR_{i,t-5}$: infant mortality at the start of the window.
- $X_i$: the matching covariates at $t-5$ for a given specification (naive;
  plus state capacity `c_comp`; plus `con_int`). $M_i$ is one of them.
- $\hat p_i = \Lambda(X_i'\hat\gamma)$: the propensity score from a logit of
  $D_i$ on $X_i$.

## 3. Plain PSM (the estimates shown before 19 Nov)

Each treated window is compared with a weighted average of comparison
windows:

$$\widehat{ATT} = \frac{1}{N_1} \sum_{i \in T}
\Big[ Y_i - \sum_{j \in C} w_{ij}\, Y_j \Big],
\qquad \sum_{j \in C} w_{ij} = 1 .$$

The weights $w_{ij}$ depend only on the propensity scores:

- **NN3:** $w_{ij} = 1/3$ for each of the three comparison windows with the
  closest $\hat p$ (with replacement, within a caliper of $0.25\,sd(\hat p)$),
  and 0 for all others.
- **Kernel:** Epanechnikov weights,
  $$w_{ij} = \frac{K\big((\hat p_j - \hat p_i)/h\big)}
  {\sum_{k \in C} K\big((\hat p_k - \hat p_i)/h\big)}, \qquad
  K(u) = 0.75\,(1-u^2)\,1\{|u| < 1\}, \qquad h = 0.06 .$$

## 4. Bias-adjusted PSM (proposed 19 Nov)

Keep the same matches and weights, but before comparing outcomes, move each
matched control's outcome to what it would be if that control had started
from the treated country's IMR level:

$$\widehat{ATT}^{BA} = \frac{1}{N_1} \sum_{i \in T}
\Big[ Y_i - \sum_{j \in C} w_{ij}\,\big( Y_j + \hat\beta\,(M_i - M_j) \big) \Big].$$

The slope $\hat\beta$ comes from a weighted least squares regression of the
outcome on starting IMR, run **only on the matched comparison windows**:

$$Y_j = \alpha + \beta\, M_j + e_j, \qquad j \in C,
\qquad \text{weights } \omega_j = \sum_{i \in T} w_{ij} .$$

A comparison window that is never used as a match gets weight zero; one used
for several treated windows counts that many times. Estimating $\beta$ only
on the matched controls keeps the adjustment local to the countries that
actually serve as the counterfactual.

**The same estimator, written as a correction.** Rearranging the sum gives

$$\widehat{ATT}^{BA} = \widehat{ATT} - \hat\beta
\Big( \bar M_T - \bar M_{C}^{w} \Big),
\qquad
\bar M_T = \frac{1}{N_1}\sum_{i \in T} M_i, \quad
\bar M_{C}^{w} = \frac{1}{N_1}\sum_{i \in T}\sum_{j \in C} w_{ij} M_j .$$

The adjusted estimate is the plain estimate minus $\hat\beta$ times the
leftover gap in starting IMR between treated windows and their matches. If
matching had balanced IMR at $t-5$ exactly, the gap would be zero and the two
estimates would coincide.

## 5. Worked example

Liberalizers, 1970-2020, specification with state capacity (`c_comp`), PSM
NN3 (`version16.csv`, 19 Nov):

| Quantity | Value |
|---|---|
| Plain estimate $\widehat{ATT}$ | $-11.4$ |
| Leftover gap $\bar M_T - \bar M_C^w$ | $-7.6$ (treated started 7.6 deaths per 1,000 lower than their matches) |
| Slope $\hat\beta$ among matched controls | $0.90$ |
| Adjusted estimate $-11.4 - 0.90 \times (-7.6)$ | $-4.6$ |

Most of the plain estimate's $-11.4$ was a starting-point difference, not an
effect of liberalization. Across specifications, the adjustment cuts the
bootstrap standard errors for liberalizers from about 7 to about 3 (NN3) and
from about 4.3 to about 2.3 (kernel).

## 6. How it relates to the other estimators

- **Mahalanobis NN3 (BA)** already used this correction, with the whole
  covariate vector instead of IMR alone:
  $Y_j + \hat\beta'(X_i - X_j)$. That is why it was stable from the start.
- **The regression benchmark** (table T6) controls for all covariates
  linearly over the whole sample. The bias-adjusted PSM sits in between: it
  matches first, then uses a regression only to clean up the remaining IMR
  gap within the matched sample.
- The adjustment is the matching bias correction of Abadie and Imbens
  (2011, *Journal of Business and Economic Statistics* 29(1): 1-11), applied
  here with a single variable, IMR at $t-5$.

## 7. Implementation and inference

- **NN3:** `Matching::Match(Y, Tr, X = pscore, Z = lag_IM, M = 3,
  caliper = 0.25, replace = TRUE, CommonSupport = TRUE, BiasAdjust = TRUE)`.
- **Kernel:** the formulas in Section 4, coded in `att_kernel(..., ba = TRUE)`.
- **Standard errors:** the same country-clustered bootstrap (200 draws) as
  the plain estimators. Each draw re-estimates the propensity score, the
  matches and $\hat\beta$, so the uncertainty in $\hat\beta$ is included.
- Script setting `BA_VAR` names the adjustment variable (`lag_IM`).

## 8. Choices to discuss

1. **Adjust on IMR at $t-5$ only, or on all covariates?** IMR only keeps the
   PSM estimators distinct from Mahalanobis and targets the one covariate
   that drives the level outcome. Adjusting on all covariates is the
   textbook Abadie-Imbens version and would bring PSM and Mahalanobis
   closer together.
2. **Linear in IMR.** The correction assumes the outcome moves linearly with
   starting IMR within the matched sample. A log specification
   ($\ln Y$ on $\ln M$) is a natural check, since IMR declines roughly in
   proportion to its level.
3. **Which estimates to headline.** With the level outcome, the
   bias-adjusted PSM and the Mahalanobis estimates are the reliable ones;
   the plain PSM estimates could move to an appendix table.
