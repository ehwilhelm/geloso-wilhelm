# Version19 review (22 November 2026)

*Follow-up to `notes/Nishant Version18 Changes 2026-11-20.md`. Plain ASCII
so it compiles through LaTeX.*

## Summary

Nishant's update arrived as a new file, `Datawork~Nishant/Version19.csv`
(1,644 rows, 130 columns); `Version18.csv` is unchanged. It completes 7 of
the 9 changes on the 20 Nov list. Every source variable was rebuilt again
from the files in the folder: 113 of 117 match exactly in all 1,644 rows,
and the 4 exceptions are expected (below). Treatments usable in the matching
(strict rule, 1970-2020): **53 liberalizations and 30 deliberalizations**;
Pakistan 1970-75 is back now that its Polity5 value is in. With the 2024
extension: 53 and 31.

## Status of the 20 Nov list

| # | Change | Status | What Version19 shows |
|---|---|---|---|
| 1 | Add the missing country-years | Done | The same 158 country-years added; every value matches its source |
| 2 | 2024 values in the 2024 rows | Done | All 19 columns (WDI, state capacity, V-Dem) now carry 2024 values |
| 3 | Fill 8 missing growth values | Done | All 8 equal the PWT values |
| 4 | Pakistan 1970 Polity5 | Done | 0 in 1970; `lagpolity5` for 1975 is 0 |
| 5 | Recompute the lag columns | Done | Every `lag*` column equals the previous row, and every previous row is 5 years earlier (4 for 2024) |
| 6 | Add an `iso3` column | Done | Present and correct in every row |
| 7 | Mark or blank the 2024 `gdppc_5growth` | Open | Still ln(gdppc 2023 / gdppc 2020), a 3-year change, in 162 of 165 rows. Not used in the analysis; low priority |
| 8 | Fill `countrynum` and `oecd` | Done | `countrynum` in every row, one number per country, no duplicates; `oecd` is 0 or 1 |
| 9 | One rerunnable build script | Open | No script in the folder yet |

Still open from the 20 Nov "document or decide" list:

- **24 infant mortality values not from UN IGME 2025** (Hong Kong and
  Taiwan 1970-2015; Cyprus, Iran and Madagascar 1970; South Africa 1975).
  Unchanged; Eric to decide whether to keep and document them or leave them
  blank.
- **EFW column names `data...8`, `data...10` and so on** (12 columns).
  Unchanged; cosmetic.

The 4 variables that do not rebuild exactly are the IMR value and its two
bounds (the 24 values above) and Polity5 (Pakistan 1970, mapped by hand from
"Pakistan (former)" as requested).

## New issues

1. **The folder name "Earlier Versions | Datawork" cannot exist on
   Windows.** The character "|" is not allowed in Windows file names, so on
   a Windows computer git cannot check out the 16 files in it (a pull
   reports "invalid path"). Please rename it, for example to
   "Earlier Versions".
2. **Two current sources are filed under "Earlier Versions".** The EFW 2026
   workbook (the EFW source for Version19) and the Maddison Project file
   (used for 6 growth values in the analysis) are in use, not earlier
   versions. Suggest moving them back to the top level.
3. **Two copies of the EFW workbook.** `Downloaded Dataset_Updated.zip` also
   contains "...-iso 2.xlsx". Its EFW Ratings sheet is identical to the one
   in "Earlier Versions", so either copy works; keeping one avoids doubt.
4. **`PWT csv.zip` was removed.** The full-precision PWT file now sits inside
   `Downloaded Dataset_Updated.zip`; it is byte for byte the same file. No
   change needed, noted only because paths to it changed.
