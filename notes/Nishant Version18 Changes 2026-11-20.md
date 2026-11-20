# Version18: changes and inconsistencies for Nishant

*20 November 2026. Plain ASCII so it compiles through LaTeX.*

## Summary

Version18 is accurate where it has rows, but it is missing 158
country-years that both the EFW Ratings sheet and UN IGME cover. Adding
them is the main change. Every value in Version18 was rebuilt from the
source files in `Datawork~Nishant`: 113 of 117 source variables match
exactly in all 1,486 rows, and the few exceptions are listed below.

The 158 rows are already built, from the same sources, in
`Data/Version18_updated.csv` on main (filter `row_source` = "added
2026-11-20 from sources (3a script)"). The script that builds them,
`Code/3a) Update Version18 panel.R`, shows the source, key and year rule
for every variable. `Version18.csv` itself was not changed.

## Changes to make

In priority order. Items 1 to 5 affect the analysis; 6 to 9 make the panel
easier to maintain.

1. **Add the missing country-years (158 rows).**
    - 92 rows in 51 countries already in the panel, for example Kuwait 1970
      and 2000-2015, Zimbabwe 1970-1990, United Arab Emirates 1975-2005,
      Oman 1975-1995, Guyana 1970-1985, and most 2000 rows for transition
      countries.
    - 66 rows in 12 countries not in the panel: Bahrain, Belarus, Brunei,
      Comoros, Djibouti, Guinea, Iraq, Libya, Papua New Guinea, Somalia,
      Sudan, Timor-Leste.
    - How: build the country-year list from the EFW Ratings sheet (every
      ISO_Code, 1970-2020 every 5 years plus 2024) and keep rows with a UN
      IGME estimate, instead of starting from the old `merged.csv`, which
      lacks these rows.
    - Why it matters: they hide 24 treatment episodes, 14 of which enter
      the matching.
2. **Use 2024 values in the 2024 rows (153 rows, 19 columns).** These
   columns carry 2025 values now:
    - WDI: `oldagedep`, `urbanpop`;
    - state capacity file: `c_nar`, `c_fisc`, `c_comp`, `pca_nar`,
      `pca_fisc`, `pca_comp`, `v2x_rule`, `v2svstterr`, `v2clrspct`,
      `v2dlencmps`, `v2stfisccap`, `v2peedueq`;
    - V-Dem: `v2x_polyarchy`, `v2x_libdem`, `v2x_partipdem`,
      `v2x_delibdem`, `v2x_egaldem`.

   IGME, EFW and fertility already use 2024.
3. **Fill 8 missing 5-year GDP growth values from PWT.** Formula:
   ln(rgdpe/pop at t) - ln(rgdpe/pop at t-5), from the full-precision PWT
   file, as in `gdp_growth_prior_rows.csv`. They were missed because
   version16 had pop rounded to 0 or no row five years earlier.

   | Row | gdppc_5growth |
   |---|---|
   | Bahamas 1975 | -0.4208 |
   | Barbados 1975 | 0.1212 |
   | Belize 1980 | 0.0856 |
   | Iceland 1970 | 0.0219 |
   | Luxembourg 1970 | 0.2605 |
   | Malta 1970 | 0.4430 |
   | Seychelles 2015 | 0.1611 |
   | Kuwait 2020 | -0.1712 |

4. **Pakistan 1970 Polity5 (1 row, plus `lagpolity5` for Pakistan 1975).**
   The OWID file lists Pakistan before 1971 as "Pakistan (former)", code
   OWID_FPK, value 0 in 1970, so the name merge missed it. This costs one
   deliberalization (Pakistan 1970-75).
5. **Recompute the lag columns after adding rows (60 existing rows).** Each
   `lag*` column is the previous row of the same country, which must be 5
   years earlier (2020 for 2024). Kuwait 2020 currently follows Kuwait 1995.
6. **Merge on ISO3 codes and add an `iso3` column.** 16 country names
   differ from PWT and 16 from the EFW file (for example Bolivia, Tanzania,
   Turkey; Bahamas, Egypt, Russia). Name merges caused items 1 and 4.
7. **Mark or blank the 2024 `gdppc_5growth` (153 rows).** It is a 3-year
   change (PWT 2023 vs 2020), not a 5-year one. The analysis does not use
   it.
8. **Fill `countrynum` and `oecd` fully.** `countrynum` is empty in all
   306 rows for 2020 and 2024: copy each country's number to them. `oecd`
   is 1 or empty, never 0: code non-OECD countries as 0.
9. **One rerunnable script from the raw files to the panel.** Open since
   the 16 Nov review. `Code/3a) Update Version18 panel.R` can serve as a
   starting point.

## Inconsistencies to document or decide

These do not block the analysis but should be either fixed or written down.

- **24 infant mortality values are not from UN IGME 2025.** Hong Kong and
  Taiwan 1970-2015 (20 rows): IGME does not publish them, so they also
  have no bounds and no `con_int`. Cyprus 1970, Iran 1970, Madagascar 1970
  and South Africa 1975: IGME 2025's series for these countries starts
  later (Cyprus in 1971). All 24 values are carried over from the older
  `ALLDATA_NEW_MERGED_UNICEF.csv`. Please note the source of each, or leave
  them blank to keep one IGME vintage (Eric to decide).
- **EFW column names `data...8`, `data...10` and so on.** These are names
  R's readxl gave to the unnamed "data" columns of the EFW sheet. Renaming
  them after the component they belong to (for example `1Ai data`) would
  make the panel readable.
- **Venezuela GDP after 2010.** PWT 11.0's `rgdpe` per capita falls from
  18,518 (2010) to 5,488 (2015), 165 (2020) and 89 (2024). The panel
  copies PWT correctly; this is PWT's own series. Worth a note in the
  codebook.

## Gaps in the sources: no action needed

- **Human capital (`hc`)** is missing in 80 rows because PWT has no index
  for those countries and years (for example Bahamas, Chad, Georgia, Oman).
- **State capacity (`c_comp`)** is missing before 2005 for Iceland, Peru,
  Tanzania and Uganda in the O'Reilly-Murphy file itself.
- **Polity5** does not cover Belize, Iceland and Malta, and ends in 2018
  (the 2018 value stands in for 2020, as agreed).
- **5-year GDP growth cannot come from PWT** for Hungary 1970 and Kuwait
  1970 (PWT starts in 1970) or Estonia, Latvia, Lithuania and Russia 1990
  (PWT starts in 1990). The analysis fills these 6 from the Maddison
  Project file in your folder; they can stay blank in the panel.

## What checked out

Everything else in Version18 matches its sources exactly.

| Variables | Checked against | Result |
|---|---|---|
| `rgdpe`, `pop`, `hc` | Full-precision PWT file (`PWT csv.zip`) | Identical in all 1,486 rows; 2024 rows = PWT 2023 |
| `gdppc`, `gdppc2`, `lngdppc`, `lngdppc2` | `rgdpe / pop` | Identical |
| `gdppc_5growth` | ln of PWT GDP per capita, t vs t-5 | Identical in all 1,321 values for 1970-2020; all 146 rows of `gdp_growth_prior_rows.csv` match PWT |
| 82 EFW columns | EFW Ratings sheet, 2026 file | Identical |
| `infantmortality`, `U5MR` and bounds | UN IGME 2025 estimates | Identical except the 24 values above |
| `fertilrate`, `oldagedep`, `urbanpop` | WDI extract | Identical except the 2024 year (item 2) |
| `polity5` | OWID Polity5 (2018 for 2020) | Identical except Pakistan 1970 (item 4) |
| State capacity and V-Dem columns | Statecap file and V-Dem v16 | Identical except the 2024 year (item 2) |
| `lag*` columns | Previous row of the country | Identical |
| Country-years | Duplicates | None |
