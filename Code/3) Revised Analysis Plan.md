# Revised analysis plan: liberalization, state capacity and data quality

*Draft for Eric's review. First version 16 November 2026, revised 18 and 19
November 2026, 20 November 2026 for `Version18` and 22 November 2026 for
`Version19`. Companion script: `Code/3) Revised Analysis (draft).R`, which
now reads `Datawork~Nishant/Version19.csv` and runs end to end. Plain ASCII
so it compiles through LaTeX.*

## 0f. Matching covariates revisited (22 Nov, afternoon)

Eric (22 Nov): the covariate set may overfit or include covariates that do
not matter for EFW jumps and IMR. Drop ln GDP per capita squared (the
Kuznets-curve reason Callais & Young give is about inequality). Consider
dropping IMR at $t-5$, since IMR is the outcome. Lawson (Working Paper,
Section 3) matches on income, human capital and lagged EFW only.

**Decision (Eric, 22 Nov):** the headline matches on Lawson's three
covariates (lagged EFW, ln GDP per capita, human capital) plus IMR at
$t-5$, then + `c_comp` (S2) and + `con_int` (S3). The Callais & Young set
without the square is the appendix robustness check. ln GDP per capita
squared is dropped completely, from the code and from the comparison.
Script settings: `COVARIATE_SET = "lawson"` (default) or `"cy"`;
`MATCH_ON_IMR = FALSE` leaves IMR at $t-5$ out of the matching. Outputs:
`Results/version19/headline_1970-2020/` and `appendix_1970-2024/` (Lawson
set), `Results/version19/headline_1970-2020_cov-cy/` (robustness). The four
variants below are in `Results/version19/covariate_sets_headline_1970-2020.csv`.

**What the two papers do.**

- Callais & Young (2023, Section 4.3) choose covariates that (i) predict
  the treatment, (ii) predict the outcome, or both. They use ln GDP per
  capita, its square ("Kuznets effects"), 5-year growth, human capital,
  Polity2, fertility, urbanization and old-age dependency, plus lagged EFW
  and "the lagged value of the respective outcome variable", all at $t-5$.
- Lawson (Section 3) computes the propensity score from income, human
  capital and EFW lagged one year. (An earlier paragraph of the same
  section also lists population, employment and three UN population-policy
  variables.) The lagged outcome is not matched on. For infant mortality
  (Table 8) her ATTs are -26 to -75 deaths per 1,000, about one standard
  deviation of IMR, and the chi-squared test rejects covariate balance in
  every PSM specification.

**Why IMR at $t-5$ is in the matching set.** It is not the outcome. The
outcome is IMR at $t+5$; IMR at $t-5$ is measured before the EFW window
opens, so the treatment cannot affect it. It is the lagged outcome that
Callais & Young match on. With the outcome in levels it is the covariate
that matters most: in the headline sample the correlation between IMR at
$t+5$ and IMR at $t-5$ is 0.96, and a country that starts 10 deaths per
1,000 higher is still about 8 higher ten years later. It does not predict
who liberalizes (p = 0.82 in the selection logit, table D3), so it qualifies
under criterion (ii), the outcome.

**What dropping it does** (Version19, headline liberalizers):

- Without IMR in the matching, the matched groups start from different IMR
  levels. With the Lawson set, the NN3-matched controls' IMR at $t-5$ is 0.40
  and 0.58 standard deviations above the liberalizers' in S1 and S2 (0.00 to
  0.15 when IMR is matched on), and plain PSM reports that gap as an effect:
  NN3 -14.7 and -17.0, both significant. The deliberalizers show the mirror
  image: +15 to +18 in S1 and S2, significant, for NN3, kernel and
  Mahalanobis. This is the pattern in Lawson's Table 8.
- The bias-adjusted PSM estimators barely move, because the bias adjustment
  regresses the outcome on IMR at $t-5$ within the matched sample and so
  removes the leftover gap after matching. Dropping IMR from the matching
  moves the whole IMR correction into that linear regression: the same
  control, but more dependent on the regression being right. Dropping IMR
  from the bias adjustment as well would leave plain PSM on the IMR level,
  which compares countries at different starting points.
- Mahalanobis (BA) adjusts only on its matching covariates, so without IMR
  it no longer corrects for it at all.

**Overfitting.** The concern is fair. With the Callais & Young set, the S3
logit has 11 covariates for 53 liberalizations (about 5 treated per
covariate; 2.7 for the 30 deliberalizations). Mahalanobis matching in 11
dimensions leaves lagged EFW, by far the strongest predictor of treatment
(z = -7), poorly matched: standardized difference -0.51 to -0.67 after
matching. The Lawson set plus IMR has 6 covariates in S3 (about 9 treated
per covariate), lagged EFW differs by -0.19 to -0.43 after Mahalanobis
matching, and the sample gains 2 liberalizations and 3 deliberalizations
(55 and 33) because missing Polity5 and growth values no longer drop rows.

ATT on the IMR level at $t+5$, liberalizers, 1970-2020, S1 / S2 / S3
(* = p < 0.05):

| Covariate set | Treated | PSM NN3 plain | PSM NN3 BA | PSM kernel BA | Mahalanobis (BA) |
|---|---|---|---|---|---|
| C&Y without square (appendix check) | 53 | -10.84* / -7.67 / -1.89 | -3.79 / -2.65 / 0.02 | -3.19 / -1.76 / -1.40 | -3.03* / -3.41* / -1.57 |
| C&Y without square, no IMR | 53 | -7.88 / -1.20 / -6.57 | -2.50 / -2.72 / -0.53 | -3.14 / -2.51 / -1.06 | -2.61 / -1.09 / 0.43 |
| **Lawson plus IMR (headline)** | 55 | -5.00 / -5.20 / -0.25 | -3.61 / -2.12 / -0.33 | -3.13* / -2.94* / -1.70 | -3.08* / -1.86 / -1.77 |
| Lawson, no IMR | 55 | -14.67* / -16.96* / -5.82 | -3.47 / -2.06 / -1.24 | -2.94* / -2.94* / -1.43 | -2.77 / -0.85 / -1.56 |

No S3 (headline, with `con_int`) estimate is significant in any set. With
the Lawson set plus IMR, every estimate moves toward zero when `con_int` is
added. In the 2024 appendix (55 and 34 treated with the Lawson set) the
pattern is the same: Mahalanobis -3.47* / -2.31 / -1.36, kernel BA -3.38* /
-3.14* / -1.96.

**Why this set:** it answers the overfitting concern (6 covariates in S3,
better balance on lagged EFW, 2 more liberalizations and 3 more
deliberalizations) and still controls for where each country's IMR started,
which drives a level outcome. The Callais & Young set without the square
stays as the robustness check because 5-year growth and old-age dependency
do predict liberalization in the selection logit (p = 0.01); the result
should not depend on leaving them out.

## 0e. Data updated to Nishant's `Version19` (22 Nov)

- **Data:** `Datawork~Nishant/Version19.csv` (Nishant, 22 Nov), chosen by
  Eric on 22 Nov as the analysis panel. It carries 7 of the 9 changes on
  the 20 Nov list: the same 158 added country-years as
  `Data/Version18_updated.csv`, 2024 values in the 2024 rows, the 8 PWT
  growth values, Pakistan 1970 Polity5, recomputed lags, an `iso3` column,
  and full `countrynum` and `oecd`. Every source variable was rebuilt and
  checked again (`notes/Nishant Version19 Review 2026-11-22.md`).
  `Data/Version18_updated.csv` and `Code/3a) Update Version18 panel.R` are
  no longer used by the analysis; they stay in place for the record.
- **Script changes:** the default data file is `Version19.csv`. The PWT and
  Maddison files used to fill 5-year growth are now found by file name
  inside any zip archive in `Datawork~Nishant`, because Nishant moved them
  on 22 Nov (PWT into `Downloaded Dataset_Updated.zip`, Maddison into the
  "Earlier Versions" subfolder); countries are matched to them on `iso3`.
  Only 6 growth values are still filled outside the panel, all from
  Maddison (Hungary and Kuwait 1970; Estonia, Latvia, Lithuania and Russia
  1990).
- **Treatments usable in the matching** (strict rule, 1970-2020): 53
  liberalizations and 30 deliberalizations (`Version18_updated`: 53 and
  29). The added one is Pakistan 1970-75, now that its Polity5 value is in.
  With the 2024 extension: 53 and 31.
- **Still open in the data** (none affects the headline matching): the 24
  IMR values not from UN IGME 2025 (Section 6c), the 2024 `gdppc_5growth`
  as a 3-year change (not used), and Venezuela's PWT GDP after 2010.
- **Outputs:** `Results/version19/`. Results in Section 9d.

## 0d. Version18 completed from the EFW Ratings sheet (20 Nov, 10:30 AM)

- **Data:** `Data/Version18_updated.csv`, built by
  `Code/3a) Update Version18 panel.R` (Eric, 20 Nov: the raw EFW source is
  the "EFW Ratings" sheet of the 2026 EFW file; update Version18
  accordingly). It is Version18 plus the 158 country-years that have an EFW
  rating and a UN IGME estimate but were missing from Version18 (92 in 51
  countries already in the panel, 66 in 12 new countries). Nishant's
  `Version18.csv` is not changed. The analysis script reads the updated
  file by default.
- **How the added rows are built:** every variable is rebuilt from the
  files in `Datawork~Nishant` (UN IGME 2025, PWT 11.0 full precision, the
  WDI extract, OWID Polity5, the O'Reilly-Murphy/V-Dem state capacity file,
  V-Dem v16, the EFW Ratings sheet). The same rebuild reproduces 113 of the
  117 source variables in all 1,486 existing rows exactly; the other 4 are
  explained in Section 6c. Existing values are kept byte for byte, except
  the `lag*` columns of 60 rows whose previous row is new and 5-year growth
  in 8 rows that PWT can fill. Checks: `Data/Version18_updated_checks.csv`.
- **Treatments usable in the matching** (strict rule, 1970-2020): 53
  liberalizations (43 on Version18) and 29 deliberalizations (25). With the
  2024 extension: 53 and 30.
- **Outputs:** `Results/version18_updated/`. `Results/version18/` keeps the
  runs on Nishant's file for comparison.

## 0c. Data updated to `Version18` (20 Nov)

- **Treatment rule made strict** (Eric, 20 Nov, 10 AM): liberalizer = EFW
  change of **more than +1**, deliberalizer = **less than -1**, as in the
  literature. Script setting `STRICT_THRESHOLD = TRUE` (default); `FALSE`
  restores the earlier >= +1 / <= -1 rule and writes to `..._ge1` folders.
  Effect on `Version18`: Congo, Rep. 1990-95 (+1.00) drops out; nothing else
  sits exactly on the threshold.

- **Data:** `Datawork~Nishant/Version18.csv` (Nishant, 20 Nov). `totalpop`
  and `totalGDP` are dropped. GDP per capita is `rgdpe / pop`, both from
  PWT 11.0, now with full decimals (Eric, 20 Nov; script setting
  `GDP_SOURCE = "rgdpe_pop"`, the new default). `hc` also has decimals.
- **5-year GDP per capita growth** now uses the panel's `gdppc_5growth`
  where the previous 5-year point is not a panel row (Nishant filled 142 of
  them from PWT, listed in `Datawork~Nishant/gdp_growth_prior_rows.csv`).
  Where both points are panel rows, the script's own log difference is used;
  the two agree exactly. The 12 values still missing are filled in the
  script (setting `GROWTH_FILL`, 20 Nov, Eric: "fill in any missing growth
  gaps"): 8 from Nishant's full-precision PWT file
  (`Datawork~Nishant/PWT csv.zip`) and 4 from the Maddison Project file in
  the same folder (Hungary 1970; Estonia, Lithuania, Russia 1990), where
  PWT has no earlier year. Each run lists them in
  `tables/D4_growth_filled.csv`.
- **More treatments in both directions.** With the IMR level outcome and
  complete covariates and the strict rule, the 1970-2020 headline sample
  has 43 liberalizations (40 on `version16`) and 25 deliberalizations (12).
  With the 2024 extension: 43 and 26. The gain comes from the 1970-75
  windows and, after the growth fill, Russia 1990-95; Congo, Rep. 1990-95
  leaves under the strict rule.
- **Outputs:** `Results/version18/headline_1970-2020/` and
  `Results/version18/appendix_1970-2024/`. The output folder is now named
  after the data file, so the `version16` results stay as they were.
- Data review: Section 6c, and the full review in the project files
  (`reviews/Version18 Data Review 2026-11-20.md`).

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
| Treatment | A 5-year EFW change of more than +1 (liberalization) or less than -1 (deliberalization), strict as in the literature, with Callais & Young adjacency blanking | Eric, 20 Nov (replaces >= +1 / <= -1) |
| State capacity | O'Reilly-Murphy Index of State Capacity, time-varying: `c_comp` only (`pca_comp` is an alternative, never in the same spec) | Eric, 17 and 19 Nov |
| Sample period | Headline 1970-2020; extension to 2024 in the appendix | Eric, 19 Nov |
| Main regressor | Change in the EFW summary index; change in EFW rank as a separate analysis | Eric, 19 Nov |
| Specification sequence | Naive, then + state capacity (`c_comp`), then + `con_int` (headline); `rp` dropped | Eric, 19 Nov |
| GDP per capita | PWT 11.0 `rgdpe / pop` (`totalpop`, `totalGDP` dropped), with 5-year growth; 2023 PWT values stand in for 2024 | Eric, 20 Nov (replaces 19 Nov OWID) |
| Regime type | Polity5 as a matching covariate (2018 values stand in for 2020) | Eric, 16-17 Nov |
| Data quality | IGME 90% interval width, `con_int` = `IM_upper_bound` - `IM_lower_bound`, lagged. A control, never an outcome. `rp` dropped. | Vincent Notes; Eric, 18-19 Nov |
| Method | PSM (NN3, kernel) and Mahalanobis NN3 | Eric, 18 Nov |
| Pre/post measurement-error decomposition | Appendix | Eric and Vincent, 18 Nov |
| Fertility rate | Kept as a lagged covariate (F1); no further changes | Eric, 18 Nov |
| Matching covariates | Lawson set (lagged EFW, ln GDP per capita, human capital) plus IMR at $t-5$. Callais & Young set without the square as an appendix robustness check. ln GDP per capita squared dropped completely (Section 0f) | Eric, 22 Nov |
| Panel | Nishant's `Version19.csv` (replaces `Data/Version18_updated.csv`) | Eric, 22 Nov |
| Jump threshold | **Strictly more than 1 point** in either direction, as in the literature (replaces the 18 Nov choice of 1 point or more). On `Version18` this drops one liberalization (Congo, Rep. 1990-95, +1.00) and no deliberalizations. Script setting `STRICT_THRESHOLD` | Eric, 20 Nov |

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
- **Baseline covariates, all at $t-5$ (Eric, 22 Nov):** EFW, ln GDP per
  capita, human capital and IMR (Lawson's set plus the lagged outcome;
  Section 0f). Appendix robustness: the Callais & Young set without the
  square (adds 5-year GDP growth, fertility rate (Section 5), old-age
  dependency, Polity5 and urbanization).
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

where $B$ holds the baseline covariates (EFW, ln GDP per capita, human
capital and $M_i \equiv IMR_{i,t-5}$; Section 0f), $SC$ is `c_comp` and
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

## 6c. Data flags from `Version18` (20 Nov)

- Fixed: `rgdpe`, `pop` and `hc` have decimals again (no `pop` = 0 rows),
  and 5-year growth is filled for 1970 and the other prior years on the
  19 Nov list. All `rgdpe`, `pop`, `hc` and growth values equal Nishant's
  full-precision PWT file (`Datawork~Nishant/PWT csv.zip`) exactly.
- 12 rows still lacked 5-year growth; the script now fills them (Section
  0c). Only Russia 1990 changes the treated sample.
- **158 country-years with an EFW rating and an IGME IMR estimate are not in
  the panel** (92 in 51 panel countries, for example Kuwait 2000-2015,
  Zimbabwe 1970-1990 and many 2000 rows; 66 in 12 countries absent
  entirely, for example Bahrain, Belarus, Iraq). Inherited from
  `merged.csv`. They hide up to 26 more treated windows of more than 1
  point (18 liberalizations, 8 deliberalizations). List for Nishant:
  `reviews/version18_missing_efw_rows.csv` in the project files.
- The panel's EFW is the 2026 file's "EFW Ratings" sheet; the "EFW Panel
  Dataset" sheet's summary index differs (sd 0.32 points). Settled 20 Nov
  (Eric): the "EFW Ratings" sheet is the source.
- The 2024 `gdppc_5growth` in the panel is a 3-year change (2020 to 2023
  PWT). Not used in any matching.
- Version18's 2024 rows mix years: IGME, EFW and fertility are 2024 values,
  but old-age dependency, urban population, the state capacity variables
  and V-Dem are **2025** values. Not used in any matching (only the 2024
  IMR enters, as an outcome). The added 2024 rows follow the same
  convention; to fix in Nishant's next version.
- 24 IMR values are not from UN IGME 2025: Hong Kong and Taiwan 1970-2015
  (not IGME countries; no bounds, so no `con_int`) and Cyprus 1970, Iran
  1970, Madagascar 1970 and South Africa 1975 (IGME 2025 starts later for
  these; values and bounds from an earlier round).
- Venezuela: PWT 11.0 `rgdpe` per capita falls from 18,518 (2010) to 5,488
  (2015) and 165 (2020). Outside the headline (covariates at $t-5$ end in
  2010) but inside the 2024 appendix.
- Growth from `rgdpe` is noisy (5-year log growth beyond +/-1 for Nigeria,
  Zimbabwe, Syria, Azerbaijan, Guyana, Venezuela). A robustness run with
  growth from PWT `rgdpna` is worth adding (R9).
- Pakistan 1970 Polity5 is missing because the OWID file names it
  "Pakistan (former)"; this drops the Pakistan 1970-75 deliberalization.
- `c_comp` is missing before 2005 for Iceland, Peru, Tanzania and Uganda in
  the source file itself.
- Episodes still lost to missing covariates: 8 liberalizations (Belize
  2000-05, Estonia, Iceland 1985-90, Malta, Peru, Russia, Tanzania and Uganda
  1990-95) and 4 deliberalizations (Iceland 1970-75 and 2005-10, Pakistan
  and Peru 1970-75).

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
- R9: 5-year GDP per capita growth from PWT `rgdpna` instead of `rgdpe`
  (PWT's recommendation for growth over time; see Section 6c).

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

## 9c. Run on `Version18_updated` (20 Nov, 10:30 AM)

Results are in `Results/version18_updated/headline_1970-2020/` and
`Results/version18_updated/appendix_1970-2024/` (strict treatment rule;
53 liberalizations and 29 deliberalizations in the headline sample). ATT on
the IMR level at $t+5$, liberalizers, 1970-2020, bootstrap SE in
parentheses (* = p < 0.05):

| Estimator | S1 naive | S2 + `c_comp` | S3 + `con_int` |
|---|---|---|---|
| PSM NN3, plain | -5.89 (5.38) | -6.24 (5.45) | -2.88 (5.24) |
| PSM NN3, bias-adjusted | -2.07 (2.42) | -2.54 (2.47) | -0.76 (2.29) |
| PSM kernel, plain | -4.58 (3.33) | -1.69 (3.64) | -1.07 (3.57) |
| PSM kernel, bias-adjusted | -2.76 (2.00) | -1.90 (2.07) | -1.17 (2.04) |
| Mahalanobis NN3 (bias-adjusted) | -2.69 (1.36)* | -2.28 (1.34) | -1.19 (1.20) |

Every liberalizer estimate is negative and every one shrinks toward zero
when `con_int` is added (S3 vs S2), by 0.6 to 3.4 deaths per 1,000. Only
Mahalanobis S1 is significant at 5% (S2 p about 0.09). No deliberalizer
estimate is significant. In the 2024 appendix nothing is significant at 5%
(Mahalanobis S1 -2.47, SE 1.32). Regression benchmark (T6): -2.1 to -2.2
deaths per 1,000 per EFW point with covariates (p about 0.02), unchanged by
`con_int`; the EFW change alone is no longer significant (-1.7, p 0.26).

On Nishant's `Version18.csv` (strict rule, 43 and 25 treated;
`Results/version18/`): Mahalanobis S1 -2.84 (1.39), S2 -2.85 (1.50), S3
-1.22 (1.23); no PSM estimate significant.

## 9d. Run on `Version19` (22 Nov, Lawson covariates plus IMR)

Results are in `Results/version19/headline_1970-2020/` and
`Results/version19/appendix_1970-2024/` (strict rule; Lawson set plus IMR
at $t-5$, Section 0f; 55 liberalizations and 33 deliberalizations in the
headline sample, 55 and 34 with 2024). ATT on the IMR level at $t+5$,
liberalizers, 1970-2020, bootstrap SE in parentheses (* = p < 0.05):

| Estimator | S1 naive | S2 + `c_comp` | S3 + `con_int` |
|---|---|---|---|
| PSM NN3, plain | -5.00 (5.31) | -5.20 (5.48) | -0.25 (5.16) |
| PSM NN3, bias-adjusted | -3.61 (2.10) | -2.12 (2.18) | -0.33 (1.99) |
| PSM kernel, plain | -4.08 (2.64) | -2.99 (3.04) | -1.61 (2.58) |
| PSM kernel, bias-adjusted | -3.13 (1.45)* | -2.94 (1.43)* | -1.70 (1.41) |
| Mahalanobis NN3 (bias-adjusted) | -3.08 (1.51)* | -1.86 (1.32) | -1.77 (1.19) |

Every liberalizer estimate is negative and moves toward zero when `con_int`
is added (S3 vs S2), by 0.1 (Mahalanobis) to 5.0 (plain NN3) deaths per
1,000. Kernel BA in S1 and S2 and Mahalanobis in S1 are significant at 5%;
nothing is significant in S3. Excluding deliberalizers from the control
group (pair B) gives the same picture.

Deliberalizers (33 treated): no estimate is significant except plain NN3
in pair D, S3 (+17.8, SE 8.1), the least stable estimator. In the 2024
appendix: Mahalanobis -3.47* / -2.31 / -1.36, kernel BA -3.38* / -3.14* /
-1.96; nothing significant in S3.

Regression benchmark (T6, same covariates): -2.5 deaths per 1,000 per EFW
point with covariates (p 0.005 to 0.006), -2.46 with `con_int`; the EFW
change alone is not significant (-1.67, p 0.26).

Robustness, Callais & Young set without the square
(`Results/version19/headline_1970-2020_cov-cy/`, 53 and 30 treated):
Mahalanobis -3.03* / -3.41* / -1.57, kernel BA -3.19 / -1.76 / -1.40, NN3
BA -3.79 / -2.65 / 0.02; nothing significant in S3. Runs with the covariate
set used until 22 Nov are in the git history (commit bff7059).

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

### Next steps (Eric, 19 Nov, for 20 Nov)

| Item | What | Status (22 Nov) |
|---|---|---|
| 1 | Review and validate the updated panel once Nishant adds unrounded `rgdpe`, `pop` and `hc` and the missing prior-period GDP for 5-year growth (147 country-years listed in `version16_missing_prior_gdp.csv`) | Done on `Version18` (Section 6c): PWT values confirmed exactly, growth gaps filled. EFW Ratings sheet confirmed as the EFW source; the 158 missing country-years added in `Data/Version18_updated.csv` (Section 0d). 22 Nov: Nishant's `Version19` includes them and checks out against the sources; it is now the analysis panel (Section 0e) |
| 2 | Specifications on the IMR level, with bias-adjusted PSM | Rerun on `Version19` (Section 9d; earlier runs in 9c) |
| 2b | Bias adjustment in mathematical form, with an explanation, in its own markdown file | Draft: `Code/3) PSM Bias Adjustment.md` |
| 3 | Liberalizers as the headline, deliberalizers in the appendix; possibly a combined-magnitude analysis of liberalizers and deliberalizers in the appendix | First part done (figures F1, F1b). Combined magnitude: open, to define with Eric |
| 4 | Prepare the agreed diagnostics (Section 7) | Tables T1-T7 and D1-D3 run; love plot and `con_int` vs IMR figure still to add |

Eric reviews the R code separately on his own.

## 11. Open questions

1. Headline end year: settled 19 Nov, 1970-2020 headline and 2024 in the
   appendix.
2. EFW rank analysis threshold: still to be set. The 20% rank and 20% score
   runs were dropped on 19 Nov.
3. "Magnitude combining liberalizers with deliberalizers" (Eric, 19 Nov, with
   a question mark): for example, one treatment for any EFW move of 1 point
   or more in either direction, or the signed EFW change as a continuous
   treatment. To define before building.
