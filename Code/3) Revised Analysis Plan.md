# Revised analysis plan: liberalization, state capacity and statistical capacity

*Draft for Eric's review, 16 November 2026. Companion script:
`Code/3) Revised Analysis (draft).R` (drafted, not yet run).*

## 0. Purpose and status

We are re-running the propensity-score-matching analysis of large EFW changes and
infant mortality (IMR) on Nishant's revised panel. The main change from the
October Tests 1–8 is that **state capacity** and **statistical capacity** now
enter as separate covariates. The headline asks what data quality adds *after*
state capacity is already balanced. That is the "residual selection" argument
in Section 2.3 of the draft paper.

Nishant's data work is not finished, so everything here is provisional. The
numbers quoted below come from a dry run on
`Datawork~Nishant/version9_new_merge_dataset.csv` (13 Nov 2026), which was read
but not changed.

## 1. What the source documents imply

| Source | What it settles | What it leaves open |
|---|---|---|
| **Vincent Notes (8 May 2026)** | The interval enters only as a **control**, never as an outcome, in this paper. Tests 1–8 keep the jump/drop × DQ on/off × opposite-movers-removed structure. State capacity and democratization *as treatments* belong to paper 2. | Nothing on how state capacity enters paper 1. |
| **Notes, `IM Liberal Data Quality Notes.md` (7 Oct)** | Baseline ATT is −1.8 to −3.2 per 1,000 over 5 years. Adding `con_int` shrinks it by 24–37%, but the shift is not significant. Liberalizers were measured *better* than their matches (SMD −0.43). `con_int` is mostly an IMR-level proxy (r = 0.83). | The notes ask for a sharper DQ measure, the 2020/2024 end year, and more deliberalization episodes. |
| **Case-study matrix (xlsx)** | The testable predictions: (P1) liberalizers are positively selected on state capacity; (P2) adding state capacity changes the matched counterfactual; (P3) adding DQ on top of state capacity *moderates* the liberalization effect ("Up" in column K); (P4) the DQ effect may appear only for liberalizers, not deliberalizers. | The matrix treats state capacity and DQ as both High or both Low. The design has to test that link rather than assume it. |
| **Draft paper (`LiberalizationIMRData.pdf`)** | Section 2.3 is the identification argument: matching on state capacity balances who gets treated but not the measurement process. So state capacity goes in first and DQ goes in on top. | Sections 3.2–5 are empty. The abstract and introduction say the effect is "reduced by between a half and a third" and "still significant". The October numbers are 24–37% with an insignificant shift, so this text has to follow whatever the revised run shows. |

Two points to settle before running:

1. **Polity5 is regime type, not state capacity.** The October baseline already
   matches on lagged Polity2, so "controlling for state capacity via Polity5" is
   already in Test 1. I recommend the O'Reilly–Murphy Index of State Capacity
   (already merged as `c_nar`/`c_fisc`/`c_comp`) as the state-capacity measure.
   Polity5 stays in the baseline as a Callais & Young covariate, and V-Dem fiscal
   capacity (`v2stfisccap`) serves as the robustness swap.
2. **The three ISC sub-indices are almost the same series** (pairwise r ≥ 0.98),
   so use one (`c_comp`, if the codebook confirms it is the composite) rather
   than several.

## 2. Causal structure and the endogeneity problem

The paths we have to respect (t−5 = start of the 5-year window, t = end):

```
              ┌────────────────────────────┐
              │                            ▼
   SC(t-5) ──► Liberalization(t-5→t) ──► true IMR change ──► measured IMR change
      │                                                   ▲
      ├──► true IMR level(t-5) ──► interval width(t-5)    │
      │                                   ▲               │
      └──► statistical capacity ──────────┴──► measurement error u
```

- **State capacity → statistical capacity.** This is the link the paper relies
  on, and it is why the two can't go into the headline together as raw
  measures. Raw interval width carries state capacity, the IMR level and
  measurement quality all at once.
- **The interval is mostly the IMR level.** In version9, ln(interval width) on
  ln(IMR), its square and year dummies gives **R² = 0.875**. Adding `c_comp`
  raises it only to 0.881, and the leftover part correlates just −0.12 with
  state capacity. So once the IMR level is netted out, measurement quality and
  state capacity are only weakly related. That helps identification, because
  they can sit in the same propensity model without heavy collinearity. It
  also tells us something about the paper's mechanism: most of the
  state-capacity–data-quality link runs through how high mortality is.
- **Post-treatment contamination.** The case-study sheet says liberalization
  *precedes* gains in state capacity, and reform programmes often bring new
  DHS/MICS surveys, which narrow intervals. State capacity or data quality
  measured during or after the window is therefore a mediator, and
  conditioning on it would be a bad control.
- **End-of-series extrapolation.** IGME intervals widen in the latest years
  because those years are projected past the last survey, and the 2025 IGME
  round (March 2027) will revise them. That affects 2020 and especially 2024.

**Rules for the headline specification**

1. Every state-capacity and data-quality covariate is measured at **t−5**.
   Nothing measured after treatment enters the matching.
2. Data quality enters as **DQ⊥**: the residual of ln(lagged interval width) on
   ln(lagged IMR), its square and year dummies. This strips out the mechanical
   level effect, so DQ⊥ measures how well a country is measured *given* how
   high its mortality is. Raw `con_int` and `rp` stay as robustness.
3. **Order matters for the claim.** The headline contrast is
   **ATT(SC + DQ⊥) − ATT(SC)**, which is what data quality adds once state
   capacity is balanced. That is the paper's "residual selection". ATT(SC) −
   ATT(baseline) is reported separately as the state-capacity step.
4. All specifications within a test pair share **one sample** (complete on
   every covariate used by any specification), and the same bootstrap draws
   give standard errors for each contrast.
5. Balance diagnostics report SMDs for state capacity, DQ⊥ and the placebo
   pre-trend under every specification. A specification only counts if it
   balances what it claims to control for.

## 3. Data status (version9, 13 Nov) and asks for Nishant

| Item | Status | Needed for |
|---|---|---|
| IMR + 90% bounds (IGME 2024 round) | 1970–2024, 148 countries in 2020 | ready |
| EFW summary + 82 components | 1970–2024; **does not match the 2025 EFW file in `Data/`** (only 8 of 134 countries match exactly in 2020). The mapping sheet cites an "EFW Ratings" sheet, which suggests the 2026 report. | Commit the source EFW file and note its vintage |
| State capacity (ISC `c_*`, `pca_*`) | 1970–2024. The 2024 row holds 2025 values (per his commit). | ready; confirm the codebook meaning of nar/fisc/comp |
| V-Dem (`v2stfisccap`, `v2svstterr`, `v2x_rule`, …) | 1970–2024 | ready |
| Polity5 | Filled for 141 countries in 2020, but Polity5 ends in 2018 | Say what the 2020 value is (2018 carried forward?) |
| PWT/WDI covariates (hc, GDP, growth, fertility, old-age dep., urban) | **Missing for 2020 and 2024** | 2020 values needed only for a 2020–24 window; 2015–20 uses 2015 values, which exist |
| `lag*` columns | Carried over from ALLDATA and not rebuilt (e.g. `lagpolity2` is lagged Polity2) | The draft rebuilds all lags itself, so these can be ignored |
| 2015 rows | **Missing for 17 countries** (Bahamas, Belize, Burundi, CAR, Chad, Congo Rep., Fiji, Guinea-Bissau, Guyana, Haiti, Lebanon, Mauritania, Nepal, Nicaragua, Oman, Qatar, Yemen). This turns Lebanon's 2010–20 change into a false "2020 drop" if lags are taken naively. | Add the 2015 rows |
| Year grid | 2020 → 2024 is a 4-year step | Decide on 2024 (Section 5) |
| ISO3 key | Still none; merges are on names | Add ISO3 |
| Script | Still none | Commit the merge script |
| WB Statistical Capacity Indicator | Not merged yet | Robustness R8 (2005–2020 only) |

## 4. Design (unchanged from October unless noted)

- **Unit:** country × 5-year window, 1970–75 through 2015–20.
- **Treatments:** a 5-year EFW change of +1 or more (jump) or −1 or less
  (drop), with Callais & Young adjacency blanking and the Venezuela 2000
  exclusion.
- **Outcome:** 5-year change in IGME IMR, deaths per 1,000.
- **Baseline covariates (S0):** lagged EFW, human capital, ln GDP pc and its
  square, 5-year growth, fertility, old-age dependency, Polity5, urbanization
  and lagged IMR.
- **Estimators:** PSM NN3 (caliper 0.25), Epanechnikov kernel PSM (bandwidth
  0.06) and Mahalanobis NN3 with bias adjustment. Country-clustered bootstrap
  with 200 replications.
- **Dry-run sample through 2020** (complete on every covariate including ISC):
  1,007 country-windows, **43 jumps and 26 drops**, compared with 43 and 22 in
  October. The 2015–20 window adds 118 control rows but only **1 drop and 0
  jumps**.

The extension to 2020 mostly adds controls and post-2005 state-capacity and
data-quality variation. It adds almost no treated episodes. Section 7 (R2)
covers power.

## 5. End year: recommendation

**Headline through 2020; 2020–24 as robustness only.**

- No jump and only one drop occurs after 2015, so ending in 2024 adds no
  treatment variation.
- The 2024 IMR values and intervals are IGME projections that the March 2027
  round will revise, and their intervals are widened by extrapolation. That is
  the measurement artifact we are trying to control for.
- The 2020–24 window is 4 years and its covariates are still missing.

If you still want 2024, the draft supports it (`INCLUDE_2024 <- TRUE`): it
scales the outcome to a 5-year basis and keeps the treatment threshold
unscaled.

## 6. Specification ladder

| Spec | Covariates added to S0 | Role |
|---|---|---|
| S0 | — | Baseline; replicates October Tests 1/3/5/7 |
| S1 | lagged state capacity | The state-capacity step (P1, P2) |
| S2 | raw lagged interval width | Replicates October Tests 2/4/6/8 |
| **S3** | **state capacity + DQ⊥** | **Headline** |
| S4 | DQ⊥ only | Shows whether order matters |
| S5 | state capacity + relative precision | Alternative DQ measure |

Reported contrasts, each with a bootstrap SE: **S3 − S1 (headline)**, S1 − S0,
S3 − S0, S4 − S0 and S2 − S0. Each is also shown as a share of its baseline
ATT.

Tests 1–8 stay as the four sample pairs (A: jumps; B: jumps with
deliberalizers removed; C: drops; D: drops with liberalizers removed). Within
each pair the "with DQ" test becomes S3 and the "without" test becomes S1, with
S0 and S2 shown so readers can line them up with the October table.

## 7. Diagnostics and robustness

**Diagnostics (run before any ATT):**

- D1: coverage by year for every covariate.
- D2: correlations and R² decomposition of the interval on IMR level, state
  capacity, GDP and Polity5. This is the endogeneity evidence for the paper.
- D3: selection logit of treatment on state capacity and DQ⊥ given S0. This
  tests P1: are liberalizers positively selected on state capacity?
- D4: balance (SMD before and after) on state capacity, DQ⊥, raw interval
  width and the pre-period IMR change, for every specification.

**Robustness:**

- R1: state capacity measured as V-Dem fiscal capacity, then Polity5 alone.
- R2: 0.75 and 0.5 thresholds (more episodes; the draft paper already promises
  the 0.5 test).
- R3: 2020–24 window included.
- R4: placebo outcome, the IMR change in the window *before* treatment. It
  should be about zero, and if it isn't, matching has failed on trends.
- R5: IGME vintage. Rerun S0 and S2 on the old ALLDATA IMR and on version9 to
  show that results are not an artifact of the revision. The October review
  found 31 country-years revised by more than 5%.
- R6: drop the 1970–75 window, which holds most of the drops and the widest
  intervals.
- R7: report that Hong Kong and Taiwan (no IGME interval) drop out of the
  common sample.
- R8: World Bank Statistical Capacity Indicator as the DQ measure, 2005–2020
  windows only (once merged).
- Heterogeneity for P4: S3 − S1 for jumps against drops, and by
  above/below-median state capacity. With about 43 and 26 treated cases this is
  descriptive only.

**Diagnostic only, not a result:** the change in DQ⊥ over the treatment window
would show whether liberalization *improves measurement*, which is the reverse
channel. Vincent's note keeps the interval out of the outcome role in this
paper, so I'd show it only in an appendix balance table, or hold it for paper 2.

## 8. How the results map back to the case-study matrix

| Matrix cell | Statistic that answers it |
|---|---|
| D3/E3: liberalizers select on state capacity | D3 coefficient on lagged state capacity in the jump logit (positive?) and the drop logit (negative?) |
| J4: IM ~ Lib + SC, "No change" | S1 − S0 for pair A, about zero? |
| K4: IM ~ Lib + SC + DQ, "Up" (effect moderated) | S3 − S1 for pair A, positive (less negative ATT)? |
| K6/L6: deliberalizers, "Down", DQ effect may not show | S3 − S1 for pair C, compared with pair A |
| L5/L7: DQ already captured through state capacity for matched controls | D2 R² step from adding state capacity (version9 dry run: 0.875 → 0.881, so mostly *not* captured) |

## 9. Sequence

1. **Now (no new data needed):** run the draft on version9 through 2020,
   produce D1–D4, and check the S0 and S2 replication against the October
   table.
2. **When Nishant delivers** the 2015 rows, the EFW source file, the Polity
   2020 note, ISO3 and the merge script: rerun everything and freeze the
   sample.
3. Write results into paper Sections 3.2–4 and revise the abstract and
   introduction claims to match.
4. Robustness R1–R8 and the appendix.

## 10. Questions for you (and Vincent)

1. Is ISC `c_comp` acceptable as the headline state-capacity measure, with
   Polity5 kept only as a baseline covariate? Or do you want Polity5 itself to
   be "state capacity" in the headline?
2. Should DQ⊥ (residualized on the IMR level) replace raw `con_int` in the
   headline? This is a change from October, where raw `con_int` was the
   headline.
3. Headline end year: 2020 (my recommendation) or 2024?
4. Do you want the change in DQ⊥ over the treatment window shown as an
   appendix diagnostic, or held entirely for paper 2?
