# Notes for data review with Nishant, 16 November 2026

File reviewed: `Datawork~Nishant/version9_new_merge_dataset.csv` (commit d76ef67, 13 Nov), 1,459 rows x 232 columns, 153 countries, years 1970-2015 every 5 years plus 2020 and 2024. The file was read only and nothing in `Datawork~Nishant` was changed.

## Items to fix

### 1. 17 countries have no 2015 row

These countries have both 2010 and 2020 rows but no 2015 row:

Bahamas, Belize, Burundi, Central African Republic, Chad, Congo Rep., Fiji, Guinea-Bissau, Guyana, Haiti, Lebanon, Mauritania, Nepal, Nicaragua, Oman, Qatar, Yemen.

The gap comes from the original ALLDATA base, which had no 2015 row for these countries (your mapping sheet says the same for the Bahamas). It matters for two reasons:

- These countries drop out of both the 2010-15 and 2015-20 windows.
- A lag taken on the rows as they stand jumps from 2010 straight to 2020, so a 10-year change gets read as a 5-year change. Lebanon's EFW goes from 6.72 (2010) to 5.23 (2020). That -1.49 shows up as a false "2015-20 deliberalization", one of only two drops of a point or more in that window.

**Ask:** add 2015 rows for all 17 countries from IGME, EFW, state capacity, V-Dem and the covariate sources.

### 2. No GDP, human capital or demographic covariates for 2020 or 2024

`hc`, `rgdpe`, `gdppc`, `lngdppc`, `lngdppc2`, `gdppc_5growth`, `fertilrate`, `oldagedep` and `urbanpop` are empty in every 2020 and 2024 row.

- The 2015-20 window only needs 2015 values, which exist, so the analysis through 2020 can run now.
- The 2020 values are needed for any 2020-24 window and for the 5-year GDP growth ending in 2020.

**Ask:** fill 2020 (and 2024 if we use it) from one vintage throughout: PWT 11.0 for `hc`, `rgdpe` and `pop`, and WDI for fertility, old-age dependency and urbanization. Then rebuild `gdppc`, `lngdppc`, `lngdppc2` and `gdppc_5growth` from that vintage for every year rather than mixing vintages.

### 3. EFW numbers don't match the 2025 EFW file in `Data/`

Comparison of `ECONOMIC FREEDOM ALL AREAS` in version9 with `Data/economic-freedom-of-the-world-2025-master-index-data-for-researchers-iso.xlsx` (sheet "EFW Index 1970-2023"), by country name:

| Year | Countries compared | Exact match | Mean absolute difference | Largest difference |
|---|---|---|---|---|
| 1990 | 102 | 14 | 0.09 | 0.32 |
| 2000 | 109 | 17 | 0.06 | 0.23 |
| 2010 | 133 | 36 | 0.03 | 0.18 |
| 2015 | 121 | 32 | 0.03 | 0.17 |
| 2020 | 134 | 8 | 0.06 | 0.46 |

The largest 2020 gaps are Nigeria (5.85 vs 6.31), Burkina Faso (5.87 vs 6.24) and Myanmar (5.73 vs 5.50). Your mapping sheet cites an "EFW Ratings" sheet, which the 2025 file doesn't have, and the 2025 file stops at 2023 while version9 has 2024. So version9 most likely comes from a newer EFW release (2026 report?), which revises earlier years. That's fine, but we need to know which release it is.

**Ask:**
- Commit the EFW file you actually used to `Data/` and write down its release and download date.
- Confirm that every year (1970-2024) comes from that one file, not old values from ALLDATA mixed with new ones.
- Confirm what the "2024" row holds (EFW 2024 data, or 2023?).

Changes in EFW vintage can move countries across the +/-1-point jump/drop threshold, so we'll recount episodes once this is settled.

### 4. Still no ISO3 code or merge script

- **ISO3:** every merge is still done on country names. Fourteen version9 names differ from the EFW file's names (Bahamas, Cote d'Ivoire, Czech Republic, Egypt, Gambia, Iran, Kyrgyzstan, Laos, Russia, Slovakia, Syria, Turkey, Venezuela, Yemen). Your mapping sheet handles these by hand. **Ask:** add an `iso3` column (IGME `REF_AREA`, EFW `ISO_Code` and V-Dem `country_text_id` all have it) and join on `iso3` + `year`.
- **Script:** **ask** for the R (or Python) script that builds version9 from the raw downloads, committed in your folder next to the output, so the file can be rebuilt when IGME 2025 comes out in March 2027.

## Items to note (no fix needed unless we decide otherwise)

- **Polity5, 2020:** Polity5 ends in 2018. As agreed, the 2018 values stand in for 2020. Please note this in a short codebook. The 2024 rows have no Polity5 value.
- **State capacity, 2024:** per your commit message, the 2024 row holds the 2025 Index of State Capacity values. Please put that in the codebook too.
- **2020 to 2024 is a 4-year step.** That's fine to keep, but the codebook should say so. For now the analysis will end in 2020.
- **`lag*` columns are stale.** They carry over from ALLDATA and weren't rebuilt for 2020 (for example, `lagpolity2` is lagged Polity2, not Polity5). The analysis script rebuilds all lags itself, so you don't need to fix these. Just don't rely on them.
- **Column names `data...8`, `data...10`, ... in the EFW block** are R's automatic names for the duplicate "data" headers. Renaming them to the component they belong to (for example `1Ai_data`) would make the file easier to read.
- **Codebook:** a short `.md` in your folder listing each source, its version, its download date and any carry-forward rules (Polity 2018 to 2020, ISC 2025 to 2024) would cover most of the above.
