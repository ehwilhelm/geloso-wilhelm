# Review of Datawork~Nishant (read-only)

Reviewed 2026-10-07. Nothing in `Datawork~Nishant` was edited.

**What's in the folder:** `ALLDATA_NEW_MERGED_UNICEF.csv` (1,163 rows × 135 cols), `UNICEF-CME_DF_2021_WQ-1.0-download.csv` (IGME 2024 round, infant mortality, total sex, 149 countries, 1931–2024), and `Merging Process.txt`. There is no script.

**What I compared against:** `Data/ALLDATA_NEW.xlsx` (sheet ALLDATA). `merged.csv` is gitignored, so it isn't in the repo, but `Code/1) Import_Merge.R` builds it by left-joining EFW onto ALLDATA_NEW. The IMR columns pass straight through, so ALLDATA_NEW is the right baseline for the IMR comparison.

## What checks out

- Same 135 columns, in the same order. Same 1,163 country-years once the 7 UN metadata rows and 4 blank rows are dropped. No duplicate country-years.
- Only `infantmortality`, `IM_lower_bound` and `IM_upper_bound` changed. Every other column differs by less than 1e-6, which is CSV float rounding.
- For countries that are in the UNICEF file, 1,115 of 1,163 rows reproduce IGME `OBS_VALUE` exactly at year-06.
- Lower bound ≤ IMR ≤ upper bound holds in every row.
- Country names stayed in ALLDATA's style ("Turkey", "South Korea"), so the `country_map` in `1) Import_Merge.R` still matches EFW.
- "South Korea" holds Republic of Korea values (2.86 in 2015; North Korea is 17.2). The note saying the name "was changed to Dem Rep of Korea" looks like a wording slip, but it's worth confirming with him.

## Issues to fix

1. **No 2020 rows were added.** The output still covers 1970–2015 at five-year steps, which was the main goal. IGME runs to 2024 and EFW 2025 has 165 countries in 2020, but the ALLDATA covariates stop at 2015, so a 2020 row needs new covariates as well as the IMR.
2. **There is no script, so the update can't be reproduced.** The process note describes the steps, but there is no code. Ask him for the R/Stata/Python script and to commit it next to the output.
3. **The UNICEF file in the folder isn't the file he merged from.** Republic of Korea, Tanzania and Moldova were updated, but none of them is in this CSV. The note also mentions Anguilla and Aruba, which aren't in it either. The download in the folder covers only 149 areas. He should save the full IGME download he actually used.
4. **He merged on country names rather than ISO3 codes.** IGME has ISO3 in `REF_AREA` and EFW has `ISO_Code`. Adding an ISO3 column to ALLDATA and joining on it would remove the name-mapping step and the encoding problems (see 9).
5. **Some rows mix data vintages.** Where IGME had no match, the old values were kept:
   - Hong Kong and Taiwan (all 10 years each) aren't covered by IGME. They have no CI, so they drop out of the data-quality tests (2, 4, 6, 8) but stay in tests 1, 3, 5 and 7. The samples will differ between the paired tests unless we restrict them to a common sample.
   - Cyprus 1970, Iran 1970 and Madagascar 1970 kept older values because their IGME series start in 1971–72. South Africa 1975 is in the same position (IGME starts in 1976), and South Africa 1970 has no IMR at all.
   - Decide whether to set these to NA or flag them, rather than splicing old values onto the new series.
6. **Some revisions are large.** 31 country-years moved by more than 5% and 11 by more than 10%, across 9 countries. Examples: Madagascar 1980 went from 95 to 138 (+45%), Nigeria 1970 from 148 to 207 (+39%), and Angola 2010 from 69 to 51 (−26%). These can change the IMR outcomes around jumps and drops. Rerun tests 1–8 on both vintages to make sure the results aren't driven by the vintage. Vintage-to-vintage revision size could also serve as a second data-quality measure.
7. **CI widths barely moved.** Relative CI width correlates 0.96 between the old and new data, so the data-quality control should behave about the same. Still, run a spot-check of the rank of each country's CI width.
8. **The panel stays limited to ALLDATA's rows.** 76 of 153 countries have fewer than 10 observations (for example, Bhutan, Laos and Liberia have only 2015). IGME covers many more of those country-years. If the matching needs lagged IMR or more pre-period years, take IMR straight from IGME for every country-year in EFW instead of only ALLDATA's existing rows.
9. **Fix the Türkiye encoding at the source.** His notes say "Rename TÃ¼rkiye" in mergedata.csv. That's UTF-8 read as Latin-1. Read and write files with `encoding = "UTF-8"`, and joining on ISO3 avoids the problem entirely.

## Things to check for the 2020 extension and the covariates

- **Polity5 ends in 2018,** so `polity2` and `xconst` will be missing for 2020. Pick a replacement now (V-Dem polyarchy, or an Our World in Data series that extends Polity) and use it across all years for consistency.
- **Penn World Table vs Maddison.** ALLDATA uses PWT variables (`rgdpe`, `pop`, `hc`), but the README link under "Penn World Tables" goes to Maddison. PWT 10.01 ends in 2019 and PWT 11.0 runs to 2023. Use PWT 11.0, and check that `gdppc`, `lngdppc` and `gdppc_5growth` are rebuilt on one vintage rather than a mix.
- **Recompute derived columns after adding 2020.** That covers the `lag*` and `change*_5yr` columns, plus `countrynum` (it is re-derived in `1) Import_Merge.R` anyway).
- **Statistical Capacity Indicator coverage.** It covers only 2004–2020, so it can't serve as the data-quality control before 2005. The IGME CI stays the main measure, and SCI works as a robustness check on 2005–2020. SPI is only 2016 onward, which is consistent with keeping it low priority.
- **Countries he couldn't find (Hong Kong, Moldova, Taiwan, Tanzania).** Moldova and Tanzania are in IGME (as "Republic of Moldova" and "United Republic of Tanzania"). Only Hong Kong and Taiwan are actually missing. Keep his planned "which source lacks which country" list.
- **V-Dem download.** The Country-Year "V-Dem Full+Others" dataset is the right one. The second paper (state capacity and democratization) will need it.
- **Large files.** Keep large raw files on Box as planned, but commit the scripts and a small codebook to the repo.
