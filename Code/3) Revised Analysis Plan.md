# Revised analysis plan: liberalization, state capacity and data quality

*Draft for Eric's review. First version 16 November 2026, revised 18 November
2026 (outcome timing updated the same afternoon). Companion script: `Code/3) Revised Analysis (draft).R` (drafted, not yet
run, because the panel is not final). Plain ASCII so it compiles through
LaTeX.*

## 0. What changed in this revision (18 Nov)

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
| Outcome | Change in IMR from $t$ to $t+5$, after the EFW window $t-5$ to $t$ (Callais & Young timing). IMR level at $t+5$ (A1) and the same-window change (A2) as robustness. | Eric, 18 Nov |
| Treatment | A 5-year EFW change of +1 or more (liberalization) or -1 or less (deliberalization), with Callais & Young adjacency blanking | Vincent Notes, Oct design |
| State capacity | O'Reilly-Murphy Index of State Capacity, time-varying | Eric, 17 Nov |
| Regime type | Polity5 as a matching covariate (2018 values stand in for 2020) | Eric, 16-17 Nov |
| Data quality | IGME 90% interval width, `con_int`, lagged. A control, never an outcome. | Vincent Notes; Eric, 18 Nov |
| Method | PSM (NN3, kernel) and Mahalanobis NN3 | Eric, 18 Nov |
| Pre/post measurement-error decomposition | Appendix | Eric and Vincent, 18 Nov |
| Fertility rate | Kept as a lagged covariate (F1); no further changes | Eric, 18 Nov |
| Jump threshold | Keep 1 point or more (not C&Y's strictly above 1). On `version11` this adds one liberalization (Congo, Rep. 1990-95, +1.00) and no deliberalizations. | Eric, 18 Nov |

## 2. Design

- **Timing (Callais & Young):** covariates at $t-5$, treatment window
  $t-5$ to $t$, outcome window $t$ to $t+5$.
- **Treatment $D_{it}$:** EFWjump (liberalization) or EFWdrop
  (deliberalization) over $t-5$ to $t$. With IMR ending in 2020, treatment
  windows run from 1970-75 to 2010-15. No jumps and only one drop occur in
  2015-20, so the lost window costs almost nothing.
- **Outcome (headline):** $\Delta Y_{i,t+5} = Y_{i,t+5} - Y_{i,t}$, the
  IGME infant mortality change in deaths per 1,000 live births over the 5
  years after the EFW window.
- **Robustness A1:** IMR level $Y_{i,t+5}$. **A2:** the October same-window
  change $Y_{it} - Y_{i,t-5}$.
- **Baseline covariates, all at $t-5$:** EFW, human capital, ln GDP per capita
  and its square, 5-year GDP growth, fertility rate (see Section 5), old-age
  dependency, Polity5, urbanization and IMR.
- **State capacity:** O'Reilly-Murphy `c_comp` at $t-5$. The three ISC
  sub-indices correlate at 0.98 or more, so only one is used. The codebook
  still needs to confirm that `comp` is the composite.
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
| A | Liberalizers | All non-liberalizing windows | 1, 2 |
| B | Liberalizers | Excludes every deliberalization window | 3, 4 |
| C | Deliberalizers | All non-deliberalizing windows | 5, 6 |
| D | Deliberalizers | Excludes every liberalization window | 7, 8 |

  Within each pair, every specification uses **one common sample**: rows
  complete on every covariate used by any specification. Differences between
  specifications then come from the covariates alone.

## 3. Specification ladder

| Spec | Matching covariates | Role |
|---|---|---|
| S0 | Baseline | Comparable to October Test 1 |
| S1 | Baseline + state capacity | "Without data quality" (new Test 1/3/5/7) |
| **S2** | **Baseline + state capacity + `con_int`** | **Headline, "with data quality" (new Test 2/4/6/8)** |
| S3 | Baseline + `con_int` | October Test 2 analogue, no state capacity |
| S4 | Baseline + state capacity + relative precision (`rp`) | Alternative data-quality measure |
| S5 | Baseline + state capacity + residual data quality | Robustness: `con_int` with the IMR level stripped out |

**Reported contrasts** (bootstrap SE from the same draws):

- **S2 - S1 (headline):** what data quality changes once state capacity is
  balanced. This is the "residual selection" of Section 2.3.
- S1 - S0: what state capacity changes.
- S2 - S0: both together.
- S3 - S0: data quality without state capacity (links back to October).

Each contrast is also shown as a share of its baseline ATT.

## 4. State capacity and data quality in the headline: endogeneity safeguards

```
   SC(t-5) ---> D (EFW jump/drop over t-5..t) ---> true IMR change t..t+5
     |                                                    |
     |                                                    v
     +---> true IMR(t-5) ---> con_int(t-5)        observed IMR change t..t+5
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
   - balance tables for `con_int` and lagged IMR under S1 and S2;
   - S4 (`rp`) and S5 (residual data quality) as robustness;
   - a collinearity check (VIF) of the propensity model.
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

## 7. Diagnostics and visualizations (to be tuned after Eric's review)

**Tables:**

- T1: episodes (liberalizations, deliberalizations) by period and country.
- T2: summary statistics for the common sample.
- T3: ATT by pair x specification x estimator.
- T4: contrasts (S2 - S1, S1 - S0, S2 - S0, S3 - S0) with bootstrap SEs.
- T5: balance (standardized mean differences before and after matching) on
  state capacity, `con_int`, lagged IMR, lagged fertility and Polity5.
- D1: coverage by year. D2: correlations and VIF. D3: selection logit (are
  liberalizers positively selected on state capacity?).

**Figures:**

- F1: ATT by specification for each pair, with 95% intervals (like the
  October Figure 1).
- F2: the headline contrast S2 - S1 for each pair and estimator.
- F3: balance "love plot" for S1 vs S2.
- F4: lagged `con_int` against lagged IMR, coloured by state-capacity tercile.

## 8. Robustness checks and appendix

- **A1 Level outcome:** IMR at $t+5$.
- **A2 October timing:** the IMR change over the EFW window itself,
  $Y_{it} - Y_{i,t-5}$. This links the new estimates to the October table.
- **A3 Pre/post decomposition** of measurement error (theory appendix).
- R1: state capacity measured by V-Dem fiscal capacity (`v2stfisccap`).
- R2: thresholds of 0.75 and 0.5 EFW points (more episodes; the paper already
  promises the 0.5 test).
- R3: add the 2015-20 treatment window with a 4-year 2020-24 outcome
  (scaled to 5 years).
- R4: placebo, using the IMR change from $t-10$ to $t-5$ (before the EFW
  window) as the outcome. It should show no "effect".
- R5: IGME vintage (old ALLDATA IMR vs `version11`).
- R6: drop the 1970-75 window.
- R7: fertility options F2-F5.
- R8: World Bank Statistical Capacity Indicator as the data-quality measure,
  2005-2020 only, once merged.

## 9. How results map to the case-study matrix

| Matrix cell | Statistic |
|---|---|
| Liberalizers select on state capacity (D3/E3) | D3 coefficient on lagged state capacity in the jump logit (positive?) and the drop logit (negative?) |
| IM ~ Lib + SC, "No change" (J4) | S1 - S0, pair A |
| IM ~ Lib + SC + DQ, "Up" (K4) | S2 - S1, pair A, positive (a smaller IMR reduction)? |
| Deliberalizers, "Down" (K6, L6) | S2 - S1, pair C, compared with pair A |

## 10. Project workplan

| Step | Who | What | Status (18 Nov) |
|---|---|---|---|
| 1 | Nishant | Complete panel construction | In progress (PWT/WDI done; V-Dem, GDP block, 2015 rows, lags, ISO3, script outstanding) |
| 2 | Eric, then Claude | Eric spot-checks 10-15 country-years of the matched data; Claude reviews them | Waiting on step 1 |
| 2b | Eric and Nishant | Follow-up questions if warranted | |
| 3 | Claude | Draft the R analysis on the final data, specs and this plan | Draft exists (this revision); finalized after steps 1-2 |
| 4 | Eric | Review and modify the R code | Planned this week for the draft |
| 5 | Claude | Tables and visualizations (Section 7), iterated | After step 4 |
| 6 | Eric | Update the paper draft | After step 5 |

## 11. Open questions

1. Headline end year: IMR through 2020 (recommended; no liberalizations after
   2015) or through 2024 (R3)?
