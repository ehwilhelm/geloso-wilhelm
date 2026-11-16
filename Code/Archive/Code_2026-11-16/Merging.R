# =============================================================================
# Merging.R
# R translation of Merging.do
#
# Purpose: Loads, cleans, and merges ~12 source datasets into a single
#          cross-country panel used in the EFW / income distribution project.
#          Then appends supplementary variables (unemployment, corruption, etc.)
#          and constructs all outcome and covariate variables.
#
# Required packages: tidyverse, haven, readxl, slider
# =============================================================================

library(tidyverse)
library(haven)
library(readxl)
library(slider)   # for sliding-window averages (NA-robust)

# --------------------------------------------------------------------------
# Convenience objects
# --------------------------------------------------------------------------

quinq_years <- c(1970, 1975, 1980, 1985, 1990, 1995, 2000, 2005, 2010, 2015)

# Country-name substitution helper (replaces Stata's `replace country = X if country == Y`)
recode_country <- function(df, old_name, new_name) {
  df$country[df$country == old_name] <- new_name
  df
}

# Apply a list of c(old, new) pairs in one call
apply_country_recodes <- function(df, pairs) {
  for (p in pairs) df <- recode_country(df, p[1], p[2])
  df
}

# Substitutions shared across nearly all World-Bank-sourced files
wb_recodes <- list(
  c("Bahamas, The",        "Bahamas"),
  c("Egypt, Arab Rep.",    "Egypt"),
  c("Gambia, The",         "Gambia"),
  c("Hong Kong SAR, China","Hong Kong"),
  c("Iran, Islamic Rep.",  "Iran"),
  c("Korea, Rep.",         "South Korea"),
  c("Kyrgyz Republic",     "Kyrgyzstan"),
  c("Macao SAR, China",    "Macao"),
  c("Russian Federation",  "Russia"),
  c("Slovak Republic",     "Slovakia"),
  c("Syrian Arab Republic","Syria"),
  c("Venezuela, RB",       "Venezuela"),
  c("Yemen, Rep.",         "Yemen"),
  c("Lao PDR",             "Laos")
)


# =============================================================================
# PART 1: Prepare individual source files
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Penn World Tables (PWT)
# -----------------------------------------------------------------------------
# NOTE: gdppc_5growth is computed before filtering to quinquennial years because
#       the original data is annual; L5.lngdppc in Stata grabs five years back.
#       If your PWT file is already annual, this approach is correct.
#       If it is already quinquennial, replace lag(lngdppc, 5) with lag(lngdppc, 1).

pwt <- read_excel("Data/StataReady/PWT.xlsx", sheet = "Data") %>%
  group_by(country) %>%
  arrange(year) %>%
  mutate(
    gdppc        = rgdpe / pop,
    gdppc2       = gdppc^2,
    lngdppc      = log(gdppc),
    gdppc_5growth = lngdppc - lag(lngdppc, 5)   # 5-year log-difference
  ) %>%
  ungroup() %>%
  apply_country_recodes(list(
    c("Bolivia (Plurinational State of)", "Bolivia"),
    c("D.R. of the Congo",                "Congo, Dem. Rep."),
    c("Congo",                            "Congo, Rep."),
    c("Côte d'Ivoire",                    "Cote d'Ivoire"),
    c("Curaçao",                          "Curacao"),
    c("China, Hong Kong SAR",             "Hong Kong"),
    c("Iran (Islamic Republic of)",       "Iran"),
    c("Republic of Korea",                "South Korea"),
    c("Lao People's DR",                  "Laos"),
    c("China, Macao SAR",                 "Macao"),
    c("Republic of Moldova",              "Moldova"),
    c("Russian Federation",               "Russia"),
    c("Saint Kitts and Nevis",            "St. Kitts and Nevis"),
    c("Saint Lucia",                      "St. Lucia"),
    c("Syrian Arab Republic",             "Syria"),
    c("U.R. of Tanzania: Mainland",       "Tanzania"),
    c("Venezuela (Bolivarian Republic of)","Venezuela"),
    c("Viet Nam",                         "Vietnam")
  )) %>%
  filter(year %in% quinq_years)

saveRDS(pwt, "Data/MergeReady/PWT.rds")


# -----------------------------------------------------------------------------
# 2. Economic Freedom of the World (EFW)
# -----------------------------------------------------------------------------

efw <- read_excel("Data/StataReady/EFW.xlsx",
                  sheet = "EFW  Panel Data 2021 Report") %>%
  rename(year = Year, country = Countries) %>%
  select(-ISO_Code) %>%
  arrange(country, year) %>%
  apply_country_recodes(list(
    c("Egypt, Arab Rep.",    "Egypt"),
    c("Bahamas, The",        "Bahamas"),
    c("Gambia, The",         "Gambia"),
    c("Hong Kong SAR, China","Hong Kong"),
    c("Iran, Islamic Rep.",  "Iran"),
    c("Korea, Rep.",         "South Korea"),
    c("Kyrgyz Republic",     "Kyrgyzstan"),
    c("Lao PDR",             "Laos"),
    c("Russian Federation",  "Russia"),
    c("Slovak Republic",     "Slovakia"),
    c("Syrian Arab Republic","Syria"),
    c("Venezuela, RB",       "Venezuela"),
    c("Yemen, Rep.",         "Yemen")
  )) %>%
  filter(year %in% quinq_years)

saveRDS(efw, "Data/MergeReady/EFW.rds")


# -----------------------------------------------------------------------------
# 3. Fertility Rate  (wide -> long reshape, like Stata's `reshape long y`)
# -----------------------------------------------------------------------------

fertility <- read_excel("Data/StataReady/FertilityRate.xls", sheet = "Data") %>%
  pivot_longer(-CountryName, names_to = "year", values_to = "fertilrate") %>%
  rename(country = CountryName) %>%
  mutate(year = as.integer(year)) %>%
  apply_country_recodes(wb_recodes) %>%
  filter(year %in% quinq_years)

saveRDS(fertility, "Data/MergeReady/Fertility.rds")


# -----------------------------------------------------------------------------
# 4. Literacy Rate
# -----------------------------------------------------------------------------

litrate <- read_excel("Data/StataReady/LiteracyRate.xls", sheet = "Data") %>%
  pivot_longer(-CountryName, names_to = "year", values_to = "litrate") %>%
  rename(country = CountryName) %>%
  mutate(year = as.integer(year)) %>%
  apply_country_recodes(wb_recodes) %>%
  filter(year %in% quinq_years)

saveRDS(litrate, "Data/MergeReady/LitRate.rds")


# -----------------------------------------------------------------------------
# 5. Old-Age Dependency
# -----------------------------------------------------------------------------

oldage <- read_excel("Data/StataReady/OldAgeDependency.xls", sheet = "Data") %>%
  pivot_longer(-CountryName, names_to = "year", values_to = "oldagedep") %>%
  rename(country = CountryName) %>%
  mutate(year = as.integer(year)) %>%
  apply_country_recodes(wb_recodes) %>%
  filter(year %in% quinq_years)

saveRDS(oldage, "Data/MergeReady/OldAgeDepend.rds")


# -----------------------------------------------------------------------------
# 6. Polity IV
# -----------------------------------------------------------------------------

polity <- read_excel("Data/StataReady/Polity.xls", sheet = "p5v2018") %>%
  apply_country_recodes(list(
    c("Bosnia",          "Bosnia and Herzegovina"),
    c("Cape Verde",      "Cabo Verde"),
    c("Congo Kinshasa",  "Congo, Dem. Rep."),
    c("Congo-Brazzaville","Congo, Rep."),
    c("Cote D'Ivoire",   "Cote d'Ivoire"),
    c("Swaziland",       "Eswatini"),
    c("Korea South",     "South Korea"),
    c("Myanmar (Burma)", "Myanmar"),
    c("Macedonia",       "North Macedonia"),
    c("Slovak Republic", "Slovakia"),
    c("UAE",             "United Arab Emirates")
  )) %>%
  filter(year %in% quinq_years)

saveRDS(polity, "Data/MergeReady/polity.rds")


# -----------------------------------------------------------------------------
# 7. Urban Population Share
# -----------------------------------------------------------------------------

urbanpop <- read_excel("Data/StataReady/UrbanPopShare.xls", sheet = "Data") %>%
  pivot_longer(-CountryName, names_to = "year", values_to = "urbanpop") %>%
  rename(country = CountryName) %>%
  mutate(year = as.integer(year)) %>%
  apply_country_recodes(wb_recodes) %>%
  filter(year %in% quinq_years)

saveRDS(urbanpop, "Data/MergeReady/UrbanPop.rds")


# -----------------------------------------------------------------------------
# 8. Decile Income Shares (CSV)
# -----------------------------------------------------------------------------

decile <- read_csv("Data/StataReady/DecileShares.csv") %>%
  filter(year %in% quinq_years) %>%
  apply_country_recodes(list(
    c("Bahamas, The",        "Bahamas"),
    c("Hong Kong SAR, China","Hong Kong"),
    c("Korea, Rep.",         "South Korea"),
    c("Kyrgyz Republic",     "Kyrgyzstan"),
    c("Russian Federation",  "Russia"),
    c("Slovak Republic",     "Slovakia"),
    c("Syrian Arab Republic","Syria"),
    c("Lao",                 "Laos"),
    c("Macedonia, FYR",      "North Macedonia"),
    c("Swaziland",           "Eswatini")
  ))

saveRDS(decile, "Data/MergeReady/DecileShare.rds")


# -----------------------------------------------------------------------------
# 9. SWIID (Gini coefficients)
# -----------------------------------------------------------------------------

swiid <- read_csv("Data/StataReady/SWIID_92.csv") %>%
  filter(year %in% quinq_years) %>%
  apply_country_recodes(list(
    c("Cape Verde",       "Cabo Verde"),
    c("Congo-Brazzaville","Congo, Rep."),
    c("Congo-Kinshasa",   "Congo, Dem. Rep."),
    c("Korea",            "South Korea")
    # Note: Cote d'Ivoire and Sao Tome may require encoding-specific handling
    #       (the .do file has garbled UTF-8 substitutions for those names)
  ))

saveRDS(swiid, "Data/MergeReady/SWIID.rds")


# -----------------------------------------------------------------------------
# 10. Secondary Education (gross enrolment)
# -----------------------------------------------------------------------------

secondary <- read_excel("Data/StataReady/SecondaryGross.xls", sheet = "Data") %>%
  pivot_longer(-CountryName, names_to = "year", values_to = "secondaryed") %>%
  rename(country = CountryName) %>%
  mutate(year = as.integer(year)) %>%
  apply_country_recodes(wb_recodes) %>%
  filter(year %in% quinq_years)

saveRDS(secondary, "Data/MergeReady/secondaryed.rds")


# -----------------------------------------------------------------------------
# 11. Primary Education (gross enrolment)
# -----------------------------------------------------------------------------

primary <- read_excel("Data/StataReady/PrimaryGross.xls", sheet = "Data") %>%
  pivot_longer(-CountryName, names_to = "year", values_to = "primaryed") %>%
  rename(country = CountryName) %>%
  mutate(year = as.integer(year)) %>%
  apply_country_recodes(wb_recodes) %>%
  filter(year %in% quinq_years)

saveRDS(primary, "Data/MergeReady/primaryed.rds")


# =============================================================================
# PART 2: Merge all source files -> ALLDATA
# =============================================================================
# Stata used `merge m:m country year` (left-join semantics: keep all PWT obs,
# drop unmatched right-side obs).  R equivalent: left_join().

alldata <- pwt %>%
  left_join(efw,       by = c("country", "year")) %>%
  left_join(fertility, by = c("country", "year")) %>%
  left_join(litrate,   by = c("country", "year")) %>%
  left_join(oldage,    by = c("country", "year")) %>%
  left_join(polity,    by = c("country", "year")) %>%
  left_join(urbanpop,  by = c("country", "year")) %>%
  left_join(decile,    by = c("country", "year")) %>%
  left_join(swiid,     by = c("country", "year")) %>%
  left_join(primary,   by = c("country", "year")) %>%
  left_join(secondary, by = c("country", "year"))


# =============================================================================
# PART 3: Construct income, EFW jump, lagged covariates, and outcome variables
# =============================================================================

# -- Country numeric ID (mirrors Stata's `egen countrynum = group(country)`) --
alldata <- alldata %>%
  mutate(countrynum = as.integer(factor(country))) %>%
  group_by(country) %>%
  arrange(year) %>%

  # -- Per-decile income: (total GDP * income share) / (decile pop fraction * total pop) --
  mutate(
    totalpop  = 1e6 * pop,
    totalGDP  = rgdpe * 1e6,
    inc_10    = (totalGDP * share10) / (0.10 * totalpop),
    inc_9     = (totalGDP * share9)  / (0.10 * totalpop),
    inc_8     = (totalGDP * share8)  / (0.10 * totalpop),
    inc_7     = (totalGDP * share7)  / (0.10 * totalpop),
    inc_6     = (totalGDP * share6)  / (0.10 * totalpop),
    inc_5     = (totalGDP * share5)  / (0.10 * totalpop),
    inc_4     = (totalGDP * share4)  / (0.10 * totalpop),
    inc_3     = (totalGDP * share3)  / (0.10 * totalpop),
    inc_2     = (totalGDP * share2)  / (0.10 * totalpop),
    inc_1     = (totalGDP * share1)  / (0.10 * totalpop),
    inc_top5  = (totalGDP * sharetop5) / (0.05 * totalpop),
    inc_top1  = (totalGDP * sharetop1) / (0.01 * totalpop)
  ) %>%

  # -- EFW jump indicator --
  # EFWjump = 1 if the EFW Summary index rose by more than 1 point over 5 years.
  # Set to NA if the country had a jump in the prior 5- or 10-year period or the
  # next 5-year period (to avoid contamination), and for Venezuela 2000.
  mutate(
    EFWdiff = Summary - lag(Summary, 1),   # lag(.,1) = 5-year lag in quinq panel
    EFWjump = case_when(
      is.na(EFWdiff)  ~ NA_real_,
      EFWdiff >  1    ~ 1,
      TRUE            ~ 0
    )
  ) %>%
  # Blank out observations adjacent to other jumps
  mutate(
    EFWjump = if_else(!is.na(EFWjump) & lag(EFWjump,  1) == 1, NA_real_, EFWjump),
    EFWjump = if_else(!is.na(EFWjump) & lag(EFWjump,  2) == 1, NA_real_, EFWjump),
    EFWjump = if_else(!is.na(EFWjump) & lead(EFWjump, 1) == 1, NA_real_, EFWjump),
    EFWjump = if_else(country == "Venezuela" & year == 2000,    NA_real_, EFWjump)
  ) %>%

  # -- Smaller- and bigger-jump robustness variants --
  mutate(
    EFW_smallerjump = case_when(
      is.na(EFWdiff) ~ NA_real_,
      EFWdiff > 0.75 ~ 1, TRUE ~ 0
    ),
    EFW_biggerjump = case_when(
      is.na(EFWdiff) ~ NA_real_,
      EFWdiff > 1.25 ~ 1, TRUE ~ 0
    ),
    # Apply same adjacency exclusions as main jump
    EFW_smallerjump = if_else(!is.na(EFW_smallerjump) & lag(EFWjump,1)==1, NA_real_, EFW_smallerjump),
    EFW_smallerjump = if_else(country=="Venezuela" & year==2000, NA_real_, EFW_smallerjump),
    EFW_biggerjump  = if_else(!is.na(EFW_biggerjump)  & lag(EFWjump,1)==1, NA_real_, EFW_biggerjump),
    EFW_biggerjump  = if_else(country=="Venezuela" & year==2000, NA_real_, EFW_biggerjump)
  ) %>%

  # -- Squared log GDP per capita --
  mutate(lngdppc2 = lngdppc^2) %>%

  # -- Five-year lagged control variables (1 row = 5 years in quinq panel) --
  mutate(
    lagEFW          = lag(Summary,      1),
    laghc           = lag(hc,           1),
    laglngdppc      = lag(lngdppc,      1),
    laggdpc_5growth = lag(gdppc_5growth,1),
    laglngdppc2     = lag(lngdppc2,     1),
    lagfertilrate   = lag(fertilrate,   1),
    lagoldagedep    = lag(oldagedep,    1),
    lagpolity2      = lag(polity2,      1),
    lagurbanpop     = lag(urbanpop,     1)
  ) %>%

  # -- Log income levels --
  mutate(across(c(inc_10, inc_9, inc_8, inc_7, inc_6, inc_5,
                  inc_4,  inc_3, inc_2, inc_1, inc_top5, inc_top1),
                log, .names = "ln_{.col}")) %>%

  # -- Lagged log income levels --
  mutate(
    lag_inc_10    = lag(ln_inc_10,   1),
    lag_inc_9     = lag(ln_inc_9,    1),
    lag_inc_8     = lag(ln_inc_8,    1),
    lag_inc_7     = lag(ln_inc_7,    1),
    lag_inc_6     = lag(ln_inc_6,    1),
    lag_inc_5     = lag(ln_inc_5,    1),
    lag_inc_4     = lag(ln_inc_4,    1),
    lag_inc_3     = lag(ln_inc_3,    1),
    lag_inc_2     = lag(ln_inc_2,    1),
    lag_inc_1     = lag(ln_inc_1,    1),
    lag_inc_top5  = lag(ln_inc_top5, 1),
    lag_inc_top11 = lag(ln_inc_top1, 1)   # note: named top11 to match Stata
  ) %>%

  # -- Lagged income shares --
  mutate(
    lag_share10   = lag(share10,   1),
    lag_share9    = lag(share9,    1),
    lag_share8    = lag(share8,    1),
    lag_share7    = lag(share7,    1),
    lag_share6    = lag(share6,    1),
    lag_share5    = lag(share5,    1),
    lag_share4    = lag(share4,    1),
    lag_share3    = lag(share3,    1),
    lag_share2    = lag(share2,    1),
    lag_share1    = lag(share1,    1),
    lag_sharetop5 = lag(sharetop5, 1),
    lag_sharetop1 = lag(sharetop1, 1)
  ) %>%

  # -- 5-year forward changes in income shares (outcome variables) --
  # F5.X in Stata = lead(X, 1) in a quinquennial panel
  mutate(
    changeshare10_5yr   = lead(share10,   1) - share10,
    changeshare9_5yr    = lead(share9,    1) - share9,
    changeshare8_5yr    = lead(share8,    1) - share8,
    changeshare7_5yr    = lead(share7,    1) - share7,
    changeshare6_5yr    = lead(share6,    1) - share6,
    changeshare5_5yr    = lead(share5,    1) - share5,
    changeshare4_5yr    = lead(share4,    1) - share4,
    changeshare3_5yr    = lead(share3,    1) - share3,
    changeshare2_5yr    = lead(share2,    1) - share2,
    changeshare1_5yr    = lead(share1,    1) - share1,
    changesharetop5_5yr = lead(sharetop5, 1) - sharetop5,
    changesharetop1_5yr = lead(sharetop1, 1) - sharetop1
  ) %>%

  # -- 5-year forward changes in log incomes (main outcome variables) --
  mutate(
    change_inc_10_5yr   = lead(ln_inc_10,   1) - ln_inc_10,
    change_inc_9_5yr    = lead(ln_inc_9,    1) - ln_inc_9,
    change_inc_8_5yr    = lead(ln_inc_8,    1) - ln_inc_8,
    change_inc_7_5yr    = lead(ln_inc_7,    1) - ln_inc_7,
    change_inc_6_5yr    = lead(ln_inc_6,    1) - ln_inc_6,
    change_inc_5_5yr    = lead(ln_inc_5,    1) - ln_inc_5,
    change_inc_4_5yr    = lead(ln_inc_4,    1) - ln_inc_4,
    change_inc_3_5yr    = lead(ln_inc_3,    1) - ln_inc_3,
    change_inc_2_5yr    = lead(ln_inc_2,    1) - ln_inc_2,
    change_inc_1_5yr    = lead(ln_inc_1,    1) - ln_inc_1,
    change_inc_top5_5yr = lead(ln_inc_top5, 1) - ln_inc_top5,
    change_inc_top1_5yr = lead(ln_inc_top1, 1) - ln_inc_top1
  ) %>%

  # -- Forward changes in Gini + lagged Gini --
  mutate(
    change_gini_disp_5yr = lead(gini_disp, 1) - gini_disp,
    change_gini_mkt_5yr  = lead(gini_mkt,  1) - gini_mkt,
    lag_gini_disp        = lag(gini_disp, 1),
    lag_gini_mkt         = lag(gini_mkt,  1)
  ) %>%
  ungroup()


# -- OECD member indicator --
oecd_countries <- c("Australia","Austria","Belgium","Canada","Chile","Colombia",
                    "Costa Rica","Czech Republic","Denmark","Estonia","Finland",
                    "France","Germany","Greece","Hungary","Iceland","Ireland",
                    "Israel","Italy","Japan","South Korea","Latvia","Lithuania",
                    "Luxembourg","Mexico","Netherlands","New Zealand","Norway",
                    "Poland","Portugal","Slovakia","Slovenia","Spain","Sweden",
                    "Switzerland","Turkey","United Kingdom","United States")

alldata <- alldata %>%
  mutate(oecd = if_else(country %in% oecd_countries, 1L, NA_integer_))


# -- Drop rows without EFW data, or without both income and Gini data --
alldata <- alldata %>%
  filter(!is.na(Summary)) %>%
  filter(!(is.na(inc_10) & is.na(gini_disp)))

saveRDS(alldata, "Data/MergeReady/ALLDATA.rds")


# =============================================================================
# PART 4: Supplementary variables -> ALLDATA_NewVariables
# =============================================================================

# -----------------------------------------------------------------------------
# 4a. Unemployment (alternative source) — rolling 5-year average, NA-robust
#     Stata's cascade of `replace` statements computes the mean over however
#     many of the 4 prior years are non-missing.  slider::slide_dbl with
#     na.rm = TRUE and .complete = FALSE replicates this cleanly.
# -----------------------------------------------------------------------------

ue_diff <- read_excel("Data/StataReady/Unemployment_Different.xls", sheet = "Data") %>%
  pivot_longer(-CountryName, names_to = "year", values_to = "unemployment_different") %>%
  rename(country = CountryName) %>%
  mutate(year = as.integer(year)) %>%
  apply_country_recodes(wb_recodes) %>%
  group_by(country) %>%
  arrange(year) %>%
  mutate(
    ue_5avg_diff = slide_dbl(unemployment_different, ~mean(.x, na.rm = TRUE),
                             .before = 4, .complete = FALSE)
  ) %>%
  ungroup() %>%
  filter(year %in% quinq_years) %>%
  select(-unemployment_different)

saveRDS(ue_diff, "Data/MergeReady/Unemployment_Different.rds")


# -----------------------------------------------------------------------------
# 4b. Unemployment (ILO estimate) — simple 5-year rolling average
# -----------------------------------------------------------------------------

ue_ilo <- read_excel("Data/StataReady/Unemployment_ILOEstimate.xls", sheet = "Data") %>%
  pivot_longer(-CountryName, names_to = "year", values_to = "unemployment_ILO") %>%
  rename(country = CountryName) %>%
  mutate(year = as.integer(year)) %>%
  apply_country_recodes(wb_recodes) %>%
  group_by(country) %>%
  arrange(year) %>%
  mutate(
    ue_5avg_ILO = slide_dbl(unemployment_ILO, ~mean(.x, na.rm = TRUE),
                            .before = 4, .complete = FALSE)
  ) %>%
  ungroup() %>%
  filter(year %in% quinq_years) %>%
  select(-unemployment_ILO)

saveRDS(ue_ilo, "Data/MergeReady/Unemployment_ILO.rds")


# -----------------------------------------------------------------------------
# 4c. Individualism (cross-sectional; merged on country only, not year)
# -----------------------------------------------------------------------------

individualism <- read_excel("Data/MergeReady/Trust_Individualism.xlsx",
                            sheet = "Sheet1") %>%
  select(-trust) %>%
  apply_country_recodes(list(
    c("Trinidad", "Trinidad and Tobago"),
    c("Burkina",  "Burkina Faso")
  ))

saveRDS(individualism, "Data/MergeReady/Individualism.rds")


# -----------------------------------------------------------------------------
# 4d. Corruption
# -----------------------------------------------------------------------------

corruption <- read_dta("Data/StataReady/Corruption.dta") %>%
  filter(year %in% quinq_years) %>%
  apply_country_recodes(list(c("Trinidad & Tobago", "Trinidad and Tobago")))

saveRDS(corruption, "Data/MergeReady/Corruption.rds")


# -----------------------------------------------------------------------------
# 4e. Trust
# -----------------------------------------------------------------------------

trust_dat <- read_excel("Data/Trust/TRUST_Collected.xlsx", sheet = "Sheet1") %>%
  rename(country = Country) %>%
  apply_country_recodes(list(c("Kyrgystan", "Kyrgyzstan")))

saveRDS(trust_dat, "Data/MergeReady/Trust.rds")


# -- Merge supplementary variables into ALLDATA --
alldata_new <- readRDS("Data/MergeReady/ALLDATA.rds") %>%
  left_join(trust_dat,    by = c("country", "year")) %>%
  left_join(corruption,   by = c("country", "year")) %>%
  left_join(individualism, by = "country") %>%          # cross-sectional: no year key
  left_join(ue_ilo,       by = c("country", "year")) %>%
  left_join(ue_diff,      by = c("country", "year")) %>%

  # Five-year lags of new variables
  group_by(country) %>%
  arrange(year) %>%
  mutate(
    lague_diff       = lag(ue_5avg_diff,   1),
    lague_ilo        = lag(ue_5avg_ILO,    1),
    lagcorruption    = lag(corruption,     1),
    lagindividualism = lag(individualism,  1),
    lagtrust         = lag(trust,          1)
  ) %>%
  ungroup()

saveRDS(alldata_new, "Data/MergeReady/ALLDATA_NewVariables.rds")


# -- Drop observations missing any key covariate (mirrors Stata's `drop if X == .`) --
alldata_clean <- alldata_new %>%
  filter(!is.na(laghc), !is.na(laglngdppc), !is.na(laggdpc_5growth),
         !is.na(laglngdppc2), !is.na(lagfertilrate), !is.na(lagoldagedep),
         !is.na(lagpolity2), !is.na(lagurbanpop),
         !is.na(lagcorruption), !is.na(lagindividualism), !is.na(lagtrust))


# =============================================================================
# PART 5: Summary statistics and Figures 1–3
# =============================================================================

# Summary statistics (mirrors Stata's `summ`)
summary(alldata_clean %>% select(Summary, share10:sharetop1))
summary(alldata_clean %>% select(inc_10:inc_top1, gini_disp, gini_mkt))
summary(alldata_clean %>% select(hc, lngdppc, gdppc_5growth, lngdppc2,
                                  fertilrate, oldagedep, polity2, urbanpop))
summary(alldata_clean %>% select(starts_with("changeshare")))
summary(alldata_clean %>% select(starts_with("change_inc")))
summary(alldata_clean %>% select(change_gini_disp_5yr, change_gini_mkt_5yr))
summary(alldata_clean %>% select(inc_10, ue_5avg_diff, ue_5avg_ILO,
                                  corruption, individualism, trust))

library(ggplot2)

# Figure 1: EFW vs. income shares (top and bottom decile)
ggplot(alldata_clean, aes(x = Summary, y = share10)) +
  geom_point(alpha = 0.4) + geom_smooth(method = "lm", se = TRUE) +
  labs(title = "Figure 1a: EFW vs. Top Decile Income Share",
       x = "EFW Summary Index", y = "Share of income (decile 10)")

ggplot(alldata_clean, aes(x = Summary, y = share1)) +
  geom_point(alpha = 0.4) + geom_smooth(method = "lm", se = TRUE) +
  labs(title = "Figure 1b: EFW vs. Bottom Decile Income Share",
       x = "EFW Summary Index", y = "Share of income (decile 1)")

# Figure 2: EFW vs. log income
ggplot(alldata_clean, aes(x = Summary, y = ln_inc_10)) +
  geom_point(alpha = 0.4) + geom_smooth(method = "lm", se = TRUE) +
  labs(title = "Figure 2a: EFW vs. Log Income (Top Decile)",
       x = "EFW Summary Index", y = "Log income (decile 10)")

ggplot(alldata_clean, aes(x = Summary, y = ln_inc_1)) +
  geom_point(alpha = 0.4) + geom_smooth(method = "lm", se = TRUE) +
  labs(title = "Figure 2b: EFW vs. Log Income (Bottom Decile)",
       x = "EFW Summary Index", y = "Log income (decile 1)")

# Figure 3: EFW vs. Gini
ggplot(alldata_clean, aes(x = Summary, y = gini_disp)) +
  geom_point(alpha = 0.4) + geom_smooth(method = "lm", se = TRUE) +
  labs(title = "Figure 3a: EFW vs. Disposable Gini",
       x = "EFW Summary Index", y = "Gini (disposable income)")

ggplot(alldata_clean, aes(x = Summary, y = gini_mkt)) +
  geom_point(alpha = 0.4) + geom_smooth(method = "lm", se = TRUE) +
  labs(title = "Figure 3b: EFW vs. Market Gini",
       x = "EFW Summary Index", y = "Gini (market income)")
