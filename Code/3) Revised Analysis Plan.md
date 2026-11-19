# Revised analysis plan: liberalization, state capacity and data quality

*Draft for Eric's review. First version 16 November 2026, revised 18 and 19
November 2026. Companion script: `Code/3) Revised Analysis (draft).R`, which
now reads `Datawork~Nishant/version16.csv` and runs end to end. Plain ASCII so
it compiles through LaTeX.*

## 0b. Outcome switched to IMR levels (19 Nov, afternoon)

- **The dependent variable is the IMR level, not the IMR change** (Eric,
  19 Nov): infant deaths per 1,000 live births (UN IGME) at $t+5$, five years
  after the EFW window $t-5$ to $t$. This applies to every specification
  (naive, + state capacity, + `con_int`), every matching estimator and the
  regression benchmark, from now on. Script setting `OUTCOME = "IM_post"`
  (the default).
- The Callais & Young timing is otherwise kept: treatment over $t-5$ to $t$,
  all matching covariates at $t-5$, including the IMR level at $t-5$.
- The IMR level at $t$, the end of the EFW window, is available as an
  alternative (`OUTCOME = "IM_t"`). The earlier change outcomes,
  $Y_{i,t+5} - Y_{i,t}$ and $Y_{it} - Y_{i,t-5}$, stay in the script as
  settings but are no longer reported.
- In the 2024 appendix, the 2015-20 window's outcome is the 2024 level
  (4 years after the window; a level is not rescaled).
- **The 20% rank and 20% score runs are dropped** (Eric, 19 Nov), with their
  outputs and figures. The EFW rank analysis remains a separate analysis with
  its threshold still to be set.
- Outputs: `Results/version16/headline_1970-2020/` and
  `appendix_1970-2024/` now hold the level results. The change results they
  held before are in git history (commit b9865fa).
- **Liberalizers are the headline results; deliberalizers go in the
  appendix** (Eric, 19 Nov).
- **The above/below-median EFW split is dropped** (Eric, 19 Nov): the halves
  were too thin (as few as 4 treated). The two figures are now a simple
  side-by-side of liberalizers (headline) and deliberalizers (appendix) on
  the full sample: F1 compares "No DQ control" with "DQ control: con_int",
  F1b compares "No state capacity control" with "State capacity control:
  c_comp".
- **Bias-adjusted PSM added** (19 Nov): each PSM estimator is reported
  plain and bias-adjusted on IMR at $t-5$; formulas in Section 3b.

## 0a. What changed in the 19 Nov morning revision

- **Sample period.** The headline results cover **1970-2020**: EFW windows
  1970-75 to 2010-15, with IMR outcomes through 2020. The **extension of the
  panel to 2024 goes in the appendix**: it adds the 2015-20 EFW window with a
  2020-24 IMR outcome (the 2024 IMR level). Script setting `APPENDIX_2024`.
- **Data:** `version16.csv` (19 Nov). GDP per capita is the panel's `gdppc`
  column, which comes from Our World in Data (Eric, 19 Nov pm; switch
  `GDP_SOURCE = "rgdpe_pop"` to rebuild it from PWT). PWT 2024 is not
  released, so the 2024 rows carry 2023 PWT values. Nishant is pulling
  unrounded `rgdpe`, `pop` and `hc`, and 1965 GDP per capita so that 5-year
  GDP growth exists for 1970 (more deliberalizers, see Section 6b).
- **Main independent variable:** the 5-year change in the EFW summary index
  (`ECONOMIC FREEDOM ALL AREAS`). The change in EFW **rank** is a separate
  analysis (script setting `TREAT_SCALE = "rank"`).
- **Treatment:** liberalizer = EFW change of **+1 or more**; deliberalizer =
  EFW change of **-1 or less** (Eric, 19 Nov).
- **Specification sequence (replaces S0-S5):**
  1. Naive: IMR level ~ EFW treatment, matching on the baseline covariates.
  2. Add state capacity: O'Reilly-Murphy `c_comp` only (Eric, 19 Nov pm:
     `c_comp` and `pca_comp` are never in the same specification).
  3. **Headline:** add `con_int` = `IM_upper_bound` - `IM_lower_bound`.
- **Relative precision (`rp`) is dropped** from the analysis, and so is the
  residualized data-quality measure (old S5). `con_int` is the only
  data-quality control.
- **New diagnostic figure:** a two-by-two grid, liberalizers vs
  deliberalizers by EFW score above vs below the median, each panel comparing
  "No DQ control" (step 2) with "DQ control: con_int" (step 3) for each
  matching method, in the style of Figure 1 of the notes page.
- **Regression benchmark:** OLS of the IMR level on the continuous EFW change
  with year fixed effects, adding the same three steps (table T6).

## 0. What changed in the previous revision (18 Nov)

- **Outcome follows Callais & Young (2023), applied to IMR** (Eric, 18 Nov,
  after checking their paper): the **5-year change in IMR over the 5 years
  after the EFW window**, $Y_{i,t+5} - Y_{i,t}$. The IMR level and the
  October same-window change become robustness checks A1 and A2.
- **Headline specification:** IMR ~ EFW treatment, with matching on the
  baseline covariates plus **O'Reilly-Murphy state capacity** and the **IGME
  interval width (`con_int`)** as the data-quality proxy. The residualized
  data-quality measure from the first draft moves to robustness.
- **Polity5** stays in the matching as regime type, not as state capacity.
- **Liberalizers and deliberalizers** are both treated, using the same four
  sample pairs as the October Tests 1-8.
- **Estimators:** propensity-score matching (NN3 and kernel) and Mahalanobis
  NN3 matching of comparison countries.
- **Fertility rate as a covariate:** assessed in Section 5, with options.
- **Data:** the script now reads Nishant's `version11_wdi_merge_dataset.csv`
  (17 Nov).
- **Project workplan:** Eric's six-step sequence is in Section 10.

**What Callais & Young do.** Their outcome is the 5-year change in each
inequality measure. In the SSRN version in `Papers/`: "For all three outcomes
variables, we examine five-year changes" (p. 16, Sec. 4.2); "The outcome in
all cases is the 5-year change" (p. 19, Sec. 5); they compare "post-treatment
changes" (p. 9). Their replication code (`Callais Young/Merging.do`) defines
the treatment as the EFW change from $t-5$ to $t$ (line 346), the outcome as
the change from $t$ to $t+5$ (`F5.y - y`, lines 450-470), and the covariates,
including the lagged outcome level, at $t-5$ (lines 397-447). Following them
for IMR changes the October timing: the October code measured the IMR change
over the same window as the EFW change (`change_IM`, `2) Analysis.R` line
153). This makes the October estimates A2.

## 1. Decisions to date

| Topic | Decision | Source |
|---|---|---|
| Outcome | **IMR level at $t+5$**, after the EFW window $t-5$ to $t$ (replaces the change outcome). Level at $t$ as an alternative. | Eric, 19 Nov (replaces 18 Nov) |
| Treatment | A 5-year EFW change of +1 or more (liberalization) or -1 or less (deliberalization), with Callais & Young adjacency blanking | Vincent Notes, Oct design |
| State capacity | O'Reilly-Murphy Index of State Capacity, time-varying: `c_comp` only (`pca_comp` is an alternative, never in the same spec) | Eric, 17 and 19 Nov |
| Sample period | Headline 1970-2020; extension to 2024 in the appendix | Eric, 19 Nov |
| Main regressor | Change in the EFW summary index; change in EFW rank as a separate analysis | Eric, 19 Nov |
| Specification sequence | Naive, then + state capacity (`c_comp`), then + `con_int` (headline); `rp` dropped | Eric, 19 Nov |
| GDP per capita | `gdppc` from Our World in Data, with 5-year growth (1965 values to be added); 2023 PWT values stand in for 2024 | Eric, 19 Nov |
| Regime type | Polity5 as a matching covariate (2018 values stand in for 2020) | Eric, 16-17 Nov |
| Data quality | IGME 90% interval width, `con_int` = `IM_upper_bound` - `IM_lower_bound`, lagged. A control, never an outcome. `rp` dropped. | Vincent Notes; Eric, 18-19 Nov |
| Method | PSM (NN3, kernel) and Mahalanobis NN3 | Eric, 18 Nov |
| Pre/post measurement-error decomposition | Appendix | Eric and Vincent, 18 Nov |
| Fertility rate | Kept as a lagged covariate (F1); no further changes | Eric, 18 Nov |
| Jump threshold | Keep 1 point or more (not C&Y's strictly above 1). On `version11` this adds one liberalization (Congo, Rep. 1990-95, +1.00) and no deliberalizations. | Eric, 18 Nov |

## 2. Design

- **Timing (Callais & Young):** covariates at $t-5$, treatment window
  $t-5$ to $t$, outcome measured at $t+5$.
- **Treatment $D_{it}$:** EFWjump (liberalization) or EFWdrop
  (deliberalization) over $t-5$ to $t$. With IMR ending in 2020, treatment
  windows run from 1970-75 to 2010-15. No jumps and only one drop occur in
  2015-20, so the lost window costs almost nothing.
- **Outcome (headline, 19 Nov):** the IMR level $Y_{i,t+5}$, IGME infant
  deaths per 1,000 live births five years after the EFW window. Alternative:
  the level at the end of the window, $Y_{it}$. The change outcomes used
  until 19 Nov ($Y_{i,t+5} - Y_{i,t}$ and $Y_{it} - Y_{i,t-5}$) are retired.
- **Baseline covariates, all at $t-5$:** EFW, human capital, ln GDP per capita
  and its square, 5-year GDP growth, fertility rate (see Section 5), old-age
  dependency, Polity5, urbanization and IMR.
- **State capacity:** O'Reilly-Murphy `c_comp` at $t-5$ (Eric, 19 Nov).
  `pca_comp` correlates with it at 0.99999, so it is only an alternative
  (`SC_VARS`), never added alongside it.
- **Data quality:** `con_int` = upper minus lower bound of the IGME 90%
  interval at $t-5$.
- **Estimators:** PSM NN3 (logit score, caliper 0.25 SD, with replacement),
  Epanechnikov kernel PSM (bandwidth 0.06), and Mahalanobis NN3 with
  Abadie-Imbens bias adjustment. The PSM standard errors come from a
  country-clustered bootstrap with 200 replications, which also gives standard
  errors for the differences between specifications.
- **Samples, kept from Tests 1-8:**

| Pair | Treated | Comparison pool | October tests |
|---|---|---|---|
| A | Liberalizers (headline) | All non-liberalizing windows | 1, 2 |
| B | Liberalizers (headline robustness) | Excludes every deliberalization window | 3, 4 |
| C | Deliberalizers (appendix) | All non-deliberalizing windows | 5, 6 |
| D | Deliberalizers (appendix) | Excludes every liberalization window | 7, 8 |

  Within each pair, every specification uses **one common sample**: rows
  complete on every covariate used by any specification. Differences between
  specifications then come from the covariates alone.

## 3. Specification sequence (19 Nov)

| Step | Matching covariates | Role |
|---|---|---|
| S1 | Baseline | 1) Naive: IMR level ~ EFW treatment |
| S2 | Baseline + `c_comp` | 2) + state capacity; "No DQ control" |
| **S3** | **Baseline + `c_comp` + `con_int`** | **3) Headline; "DQ control: con_int"** |

**Reported contrasts** (bootstrap SE from the same draws):

- **S3 - S2 (headline):** what data quality changes once state capacity is
  balanced. This is the "residual selection" of Section 2.3.
- S2 - S1: what state capacity changes.
- S3 - S1: both together.

**Liberalizers vs deliberalizers (figures F1 and F1b, 19 Nov).** Two
panels side by side, full sample: liberalizers (pair A, headline) and
deliberalizers (pair C, appendix). F1 shows S2 ("No DQ control") and S3
("DQ control: con_int"); F1b shows S1 ("No state capacity control") and S2
("State capacity control: c_comp"); each for PSM NN3, PSM kernel and
Mahalanobis NN3. The earlier split by EFW score above or below the median
was dropped on 19 Nov.

Each contrast is also shown as a share of its baseline ATT.

## 3b. Estimators in mathematical form (19 Nov)

**Notation.** Window $t-5$ to $t$. $D_i = 1$ if country-window $i$ is a
liberalization (headline) or a deliberalization (appendix). The outcome is
the IMR level five years after the window, $Y_i = IMR_{i,t+5}$. $X_i^{(s)}$
is the vector of matching covariates at $t-5$ for specification
$s \in \{S1, S2, S3\}$:

$$X_i^{(S1)} = B_{i,t-5}, \qquad
X_i^{(S2)} = (B_{i,t-5}, SC_{i,t-5}), \qquad
X_i^{(S3)} = (B_{i,t-5}, SC_{i,t-5}, CI_{i,t-5}),$$

where $B$ holds the baseline covariates (EFW, human capital, ln GDP per
capita and its square, 5-year GDP growth, fertility, old-age dependency,
Polity5, urbanization and $M_i \equiv IMR_{i,t-5}$), $SC$ is `c_comp` and
$CI$ is `con_int` = `IM_upper_bound` - `IM_lower_bound`. $T$ is the set of
treated windows, $N_1 = |T|$, and $C$ the comparison pool.

**Propensity score.** A logit, estimated separately for each specification:

$$\hat p_i = \Pr(D_i = 1 \mid X_i^{(s)}) = \Lambda(X_i^{(s)\prime}\hat\gamma).$$

**(1) Plain PSM (the estimates shown before 19 Nov, "PSM NN3" and "PSM
Kernel"):**

$$\widehat{ATT} = \frac{1}{N_1} \sum_{i \in T}
\Big[ Y_i - \sum_{j \in C} w_{ij} Y_j \Big],$$

with matching weights that sum to one for each treated $i$:

- NN3: $w_{ij} = 1/3$ if $j$ is one of the three controls closest to $i$ in
  $\hat p$ (with replacement, caliper $0.25\,sd(\hat p)$), and 0 otherwise.
- Kernel: $w_{ij} = K\big((\hat p_j - \hat p_i)/h\big) /
  \sum_{k \in C} K\big((\hat p_k - \hat p_i)/h\big)$, with
  $K(u) = 0.75(1-u^2)\,1\{|u|<1\}$ and $h = 0.06$.

**(2) Bias-adjusted PSM (proposed 19 Nov, "PSM NN3 (BA)" and "PSM Kernel
(BA)"):** the same weights $w_{ij}$, but each matched control's outcome is
moved to the treated country's IMR level at $t-5$:

$$\widehat{ATT}^{BA} = \frac{1}{N_1} \sum_{i \in T}
\Big[ Y_i - \sum_{j \in C} w_{ij}\big( Y_j + \hat\beta (M_i - M_j) \big) \Big],$$

where $\hat\beta$ is the slope from a weighted least squares regression of
the outcome on IMR at $t-5$ among the matched controls only,

$$Y_j = \alpha + \beta M_j + e_j, \qquad j \in C, \quad
\text{weights } \omega_j = \sum_{i \in T} w_{ij}.$$

Equivalently,

$$\widehat{ATT}^{BA} = \widehat{ATT} - \hat\beta
\Big( \bar M_T - \sum_{i \in T}\sum_{j \in C} \tfrac{w_{ij}}{N_1} M_j \Big):$$

the plain estimate minus $\hat\beta$ times the gap in IMR at $t-5$ that
matching on $\hat p$ leaves between treated countries and their matches.
With the IMR level as the outcome, $\hat\beta$ is about 0.8 to 0.9 (IMR is
very persistent), so a leftover gap moves the plain estimate almost one for
one; this is the source of the plain PSM noise. Example (liberalizers, S2,
NN3): treated countries' IMR at $t-5$ is 7.6 below their matches',
$\hat\beta = 0.90$, and the estimate moves from $-11.4$ to
$-11.4 - 0.90 \times (-7.6) = -4.6$. This is the Abadie and Imbens
(2011) bias correction, applied with $M$ only; in the script it is
`Match(..., Z = lag_IM, BiasAdjust = TRUE)` for NN3 and the formula above
for the kernel.

**(3) Mahalanobis NN3 (BA), unchanged:** matches on the Mahalanobis distance
in $X_i^{(s)}$ and applies the same correction with the full vector,
$\hat\beta' (X_i - X_j)$, instead of $\hat\beta (M_i - M_j)$.

## 4. State capacity and data quality in the headline: endogeneity safeguards

```
   SC(t-5) ---> D (EFW jump/drop over t-5..t) ---> true IMR level at t+5
     |                                                    |
     |                                                    v
     +---> true IMR(t-5) ---> con_int(t-5)        observed IMR level at t+5
     |                            ^                       ^
     +---> statistical capacity --+---> measurement error u(t), u(t+5)
```

1. **Pre-treatment timing.** State capacity, `con_int` and every other
   covariate are measured at $t-5$. Liberalization can raise state capacity
   and bring new surveys, so values from $t$ would be mediators (bad
   controls).
2. **`con_int` carries the IMR level.** In the version9 data, ln(`con_int`) on
   ln(IMR), its square and year dummies gives R-squared = 0.875 (state
   capacity adds 0.006). With lagged IMR already matched, `con_int` partly
   duplicates it. Three checks keep the headline honest:
   - balance tables for `con_int` and lagged IMR under S2 and S3;
   - a collinearity check (VIF) of the propensity model.
   (`rp` and the residualized measure were dropped on 19 Nov.)
3. **Collinearity of state capacity with other covariates.** State capacity
   correlates about 0.66 with Polity5 and about 0.76 with ln GDP per capita.
   Report the VIF and the propensity-score overlap with and without state
   capacity.
4. **Common sample and common bootstrap draws** for every contrast.

The pre/post decomposition of measurement error (Proposals A-D in
`notes/section-2-3-pre-post-measurement-error.md`, project files) belongs to
the appendix. With the C&Y timing, its "pre" and "post" are $t$ and $t+5$.

## 5. Fertility rate as a matching covariate

**Short answer:** lagged fertility does not create a misspecification in the
sense of biasing the ATT. It is measured at $t-5$, before treatment, and it is
one of the Callais & Young covariates. Your concern is still well founded,
though. It can distort the *headline contrast* and the Mahalanobis matches,
for three reasons:

1. **Near-duplicate of lagged IMR.** Fertility and IMR move together through
   the demographic transition. High IMR raises fertility (replacement and
   insurance births), and high fertility raises IMR (parity, birth spacing,
   maternal age). In `version11` the correlation between fertility and IMR is
   0.89. With both in the propensity model and in the Mahalanobis distance,
   matching gives demographic stage roughly double weight. That leaves less
   weight for state capacity and `con_int`, which are exactly the variables
   the headline is about.
2. **Shared data source, shared error.** In survey-dependent countries,
   WPP/WDI fertility and IGME infant mortality are both built largely from the
   same DHS/MICS birth histories, and both are modelled between surveys. So
   lagged fertility partly proxies the *measurement process*. It can absorb
   part of what `con_int` is meant to capture and shrink the S2 - S1
   contrast.
3. **Mediator if mistimed.** Liberalization can lower fertility, which then
   lowers IMR. Contemporaneous or post-treatment fertility would be a bad
   control. The draft uses only $t-5$ values, so this is a rule to keep, not a
   current problem.

**Options:**

| Option | What it does | Use |
|---|---|---|
| F1 Keep lagged fertility | Comparability with Callais & Young and October | Headline unless diagnostics flag a problem |
| F2 Drop fertility | Lagged IMR carries demographic stage alone | Robustness: report the ATT and S2 - S1 with and without |
| F3 Longer lag (fertility at $t-10$) | Breaks shared shocks and feedback with IMR at $t-5$ | Robustness |
| F4 Residualized fertility | Keeps only the part of lagged fertility not explained by lagged IMR (as in S5 for data quality) | Robustness; keeps a pure fertility signal |
| F5 Split by estimator | Fertility in the propensity model but not in the Mahalanobis distance | Robustness for the Mahalanobis estimator |
| F6 Different demographic control | e.g. lagged population growth or female schooling instead of fertility | Only if F2-F4 show fertility drives results |

**Diagnostics that decide it:** the VIF of lagged fertility; propensity-score
overlap under F1 and F2; balance on `con_int` and state capacity under F1 and
F2; and whether S2 - S1 moves materially between F1 and F2-F4. The draft
script switches between F1-F5 with one setting (`FERT_OPTION`).

## 6. Data status (`version11_wdi_merge_dataset.csv`, 17 Nov) and asks

| Item | Status |
|---|---|
| PWT and WDI covariates | Updated. `hc`, `rgdpe`, fertility, old-age dependency and urbanization now run to 2024. Historical `hc` and fertility values were revised (new vintages). |
| GDP per capita block | `gdppc`, `lngdppc`, `lngdppc2` and `gdppc_5growth` are still empty for 2020 and 2024. `pop` is rounded to whole millions, so these can't be rebuilt from `rgdpe/pop`. **Ask:** rebuild them from one PWT vintage. |
| 2015 rows | Still missing for the same 17 countries |
| `lag*` columns | Not updated (Nishant's note). The script rebuilds all lags itself. |
| V-Dem | Still to be updated (Nishant's note) |
| ISO3, merge script, EFW source | As in the 16 Nov data review notes |

**What can run now:** treatment windows 1970-75 to 2010-15 need covariates
at 1970-2010 and IMR up to 2020. Those exist. The 17 countries with no 2015
row lose the 2005-10 and 2010-15 windows until those rows are added. Adding
the 2015-20 window (outcome 2020-24) needs IMR for 2024 (present) and the
2015 covariates.

## 6b. Data flags from `version16` (19 Nov)

- `hc` holds whole numbers only (1, 2, 3, 4) and `pop` is rounded to whole
  millions, from `version10` on. In `version9` they had decimals (Chile 1990:
  hc 2.64, pop 13.27). 65 rows have `pop` = 0. Eric is asking Nishant for
  unrounded `rgdpe`, `pop` and `hc` (19 Nov).
- The `gdppc` column equals `rgdpe / pop` exactly in every `version16` row,
  so it does not yet hold the Our World in Data series.
- `gdppc_5growth` is empty for 1970 (it needs 1965 GDP per capita), so every
  1970-75 window drops out of the matching. With 1970 growth filled, the
  headline sample would go from 12 to 25 deliberalizations and from 40 to 44
  liberalizations (count on `version16`, 19 Nov). The script reads 1965 rows
  automatically once the panel has them.
- `c_comp` and `pca_comp` correlate at 0.99999.

## 7. Diagnostics and visualizations (to be tuned after Eric's review)

**Tables:**

- T1: episodes (liberalizations, deliberalizations) by period and country.
- T2: summary statistics for the common sample.
- T3: ATT by pair x specification x estimator.
- T4: contrasts (S3 - S2 headline, S2 - S1, S3 - S1) with bootstrap SEs.
- T5: balance (standardized mean differences before and after matching) on
  state capacity, `con_int`, lagged IMR, lagged fertility and Polity5.
- T6: regression benchmark, IMR level on the continuous EFW change, year
  fixed effects, country-clustered SEs, same three steps.
- T7: liberalizers vs deliberalizers, the estimates behind figures F1 and
  F1b.
- D1: coverage by year. D2: correlations and VIF. D3: selection logit (are
  liberalizers positively selected on state capacity?).

**Figures:**

- F1: liberalizers (headline) vs deliberalizers (appendix), "No DQ control"
  vs "DQ control: con_int" for each matching method (Section 3).
- F1b: the same layout for step 2, without any data-quality control:
  "No state capacity control" (S1) vs "State capacity control: c_comp" (S2).
- F2: ATT by specification step for each pair, with 95% intervals (like
  Figure 1 of the notes page).
- F3: the headline contrast S3 - S2 for each pair and estimator.
- Still to add: balance "love plot" for S2 vs S3; lagged `con_int` against
  lagged IMR by state-capacity tercile.

## 8. Robustness checks and appendix

- **A1 Level at the end of the window:** IMR at $t$ (`OUTCOME = "IM_t"`).
- **A2 Earlier change outcomes** (retired 19 Nov, kept as script settings):
  $Y_{i,t+5} - Y_{i,t}$ and the October same-window change
  $Y_{it} - Y_{i,t-5}$.
- **A3 Pre/post decomposition** of measurement error (theory appendix).
- R1: state capacity measured by V-Dem fiscal capacity (`v2stfisccap`).
- R2: thresholds of 0.75 and 0.5 EFW points (more episodes; the paper already
  promises the 0.5 test).
- R3 (now the appendix): add the 2015-20 treatment window with a 4-year
  2020-24 outcome (the 2024 IMR level).
- R4: placebo, using the IMR change from $t-10$ to $t-5$ (before the EFW
  window) as the outcome. It should show no "effect".
- R5: IGME vintage (old ALLDATA IMR vs `version11`).
- R6: drop the 1970-75 window.
- R7: fertility options F2-F5 (not wired into the 19 Nov script).
- R8: World Bank Statistical Capacity Indicator as the data-quality measure,
  2005-2020 only, once merged.

## 9. How results map to the case-study matrix

| Matrix cell | Statistic |
|---|---|
| Liberalizers select on state capacity (D3/E3) | D3 coefficient on lagged state capacity in the jump logit (positive?) and the drop logit (negative?) |
| IM ~ Lib + SC, "No change" (J4) | S2 - S1, pair A |
| IM ~ Lib + SC + DQ, "Up" (K4) | S3 - S2, pair A, positive (a smaller IMR reduction)? |
| Deliberalizers, "Down" (K6, L6) | S3 - S2, pair C, compared with pair A |

## 9b. First run on `version16` (19 Nov, headline 1970-2020)

Results are in `Results/version16/headline_1970-2020/` and
`Results/version16/appendix_1970-2024/`. They are a first pass on data that
Eric is still validating; see the data flags in the thread and Section 6b.

## 10. Project workplan

| Step | Who | What | Status (18 Nov) |
|---|---|---|---|
| 1 | Nishant | Complete panel construction | In progress (PWT/WDI done; V-Dem, GDP block, 2015 rows, lags, ISO3, script outstanding) |
| 2 | Eric, then Claude | Eric spot-checks 10-15 country-years of the matched data; Claude reviews them | Waiting on step 1 |
| 2b | Eric and Nishant | Follow-up questions if warranted | |
| 3 | Claude | Draft the R analysis on the final data, specs and this plan | 19 Nov: draft reads `version16` and runs; finalized after steps 1-2 |
| 4 | Eric | Review and modify the R code | Planned this week for the draft |
| 5 | Claude | Tables and visualizations (Section 7), iterated | After step 4 |
| 6 | Eric | Update the paper draft | After step 5 |

## 11. Open questions

1. Headline end year: settled 19 Nov, 1970-2020 headline and 2024 in the
   appendix.
2. EFW rank analysis threshold: still to be set. The 20% rank and 20% score
   runs were dropped on 19 Nov.
