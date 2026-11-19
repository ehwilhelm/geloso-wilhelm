# ==============================================================================
# 1) Import_Merge.R
# Purpose: Import ALLDATA_NEW and EFW datasets and left-join all EFW variables
#          onto the first five variables of ALLDATA_NEW.
#
# Left join driving dataset: ALLDATA_NEW, sheet = "ALLDATA"
# Merge keys: [country] == [Countries]  AND  [year] == [Year]
#
# Run from project root (where EFW_IM_Code.Rproj lives) so that relative
# paths to the Data/ folder resolve correctly.
# ==============================================================================

library(readxl)
library(dplyr)
library(tidyverse)
library(haven)
library(readxl)
library(slider)

# ------------------------------------------------------------------------------
# Paths (relative to project root)
# ------------------------------------------------------------------------------

path_alldata <- "C:/Users/ehwil/OneDrive/Desktop/Geloso Collab/geloso-wilhelm/Data/ALLDATA_NEW.xlsx"
path_efw     <- "C:/Users/ehwil/OneDrive/Desktop/Geloso Collab/geloso-wilhelm/Data/economic-freedom-of-the-world-2025-master-index-data-for-researchers-iso.xlsx"

# ------------------------------------------------------------------------------
# Import
# ------------------------------------------------------------------------------

alldata <- read_excel(path_alldata, sheet = "ALLDATA")

# EFW has 3 descriptor header rows above the real variable names (row 4)
efw_raw <- read_excel(path_efw, sheet = "EFW Index 1970-2023", skip = 3)

# ------------------------------------------------------------------------------
# Country name harmonisation
# ALLDATA_NEW uses shorter / older naming conventions; EFW follows World Bank.
# The map below converts ALLDATA_NEW names to their EFW equivalents so the
# join key matches. Special characters (ü, ô) are written as Unicode escapes
# to ensure the file reads correctly regardless of system locale.
# ------------------------------------------------------------------------------

country_map <- c(
  "Bahamas"        = "Bahamas, The",
  "Cote d’Ivoire"  = "Côte d’Ivoire",  # ô = o-circumflex (ô); EFW: "Côte d’Ivoire"
  "Czech Republic" = "Czechia",
  "Egypt"          = "Egypt, Arab Rep.",
  "Gambia"         = "Gambia, The",
  "Hong Kong"      = "Hong Kong SAR, China",
  "Iran"           = "Iran, Islamic Rep.",
  "Kyrgyzstan"     = "Kyrgyz Republic",
  "Laos"           = "Lao PDR",
  "Russia"         = "Russian Federation",
  "Slovakia"       = "Slovak Republic",
  "South Korea"    = "Korea, Rep.",
  "Syria"          = "Syrian Arab Republic",
  "Turkey"         = "Türkiye",         # ü = u-umlaut (ü); EFW uses this spelling
  "Venezuela"      = "Venezuela, RB",
  "Yemen"          = "Yemen, Rep."
)

# Normalise curly/smart apostrophes to straight apostrophe in country strings.
# Excel files sometimes encode apostrophes as U+2019 (right single quotation
# mark) instead of U+0027 (apostrophe), which breaks exact-match joins.
norm_apostrophe <- function(x) gsub("’|‘", "'", x)

country_map <- setNames(norm_apostrophe(country_map), norm_apostrophe(names(country_map)))

alldata <- alldata %>%
  mutate(
    country = norm_apostrophe(country),
    country = if_else(country %in% names(country_map),
                      country_map[country],
                      country)
  )

efw_raw <- efw_raw %>%
  mutate(Countries = norm_apostrophe(Countries))

# ------------------------------------------------------------------------------
# Left join (alldata is the driving dataset)
# ------------------------------------------------------------------------------

# Regex matching metadata header strings carried over from the UNICEF/UN source
# file embedded in ALLDATA_NEW. Defined here so it can be used both in the
# filter below and in the diagnostics section.
metadata_pattern <- paste(
  "©",
  "United Nations",
  "Estimates",
  "File GEN",
  "POP/DB",
  "Suggested citation",
  "World Population Prospects",
  "Most Recent",
  sep = "|"
)

merged <- alldata %>%
  left_join(efw_raw,
            by = c("country" = "Countries", "year" = "Year")) %>%
  filter(!is.na(country),                               # drop blank/NA artefact rows
         !grepl(metadata_pattern, country))             # drop UN metadata header rows

# ------------------------------------------------------------------------------
# Diagnostics: flag unmatched rows
# ------------------------------------------------------------------------------

# A row failed to match if ISO_Code (EFW identifier) is NA after the join
unmatched <- merged %>%
  filter(is.na(ISO_Code)) %>%
  distinct(country, year) %>%
  arrange(country, year)

# Separate genuine country rows from any residual metadata artefacts

unmatched_countries <- unmatched %>%
  filter(!grepl(metadata_pattern, country, fixed = FALSE))

unmatched_metadata <- unmatched %>%
  filter(grepl(metadata_pattern, country, fixed = FALSE))

# ------------------------------------------------------------------------------
# Console report
# ------------------------------------------------------------------------------

cat("================================================================\n")
cat("MERGE DIAGNOSTICS\n")
cat("================================================================\n\n")

cat(sprintf("Rows in ALLDATA (5-variable subset) : %d\n", nrow(alldata)))
cat(sprintf("Rows in EFW                          : %d\n", nrow(efw_raw)))
cat(sprintf("Rows in merged output                : %d\n\n", nrow(merged)))

cat("----------------------------------------------------------------\n")
cat(sprintf("Country names harmonised via manual map (%d pairs):\n",
            length(country_map)))
cat("----------------------------------------------------------------\n")
for (nm in names(country_map)) {
  cat(sprintf("  %-28s  ->  %s\n", nm, country_map[nm]))
}

cat("\n----------------------------------------------------------------\n")
cat(sprintf("Unmatched country-year rows after harmonisation: %d\n",
            nrow(unmatched_countries)))
cat("(EFW variables will be NA for these observations)\n")
cat("----------------------------------------------------------------\n")
if (nrow(unmatched_countries) == 0) {
  cat("  None — all genuine country-year rows matched successfully.\n")
} else {
  summary_df <- unmatched_countries %>%
    group_by(country) %>%
    summarise(n_years  = n(),
              year_min = min(year),
              year_max = max(year),
              .groups  = "drop")
  for (i in seq_len(nrow(summary_df))) {
    cat(sprintf("  %-30s  %d obs  (%d–%d)\n",
                summary_df$country[i],
                summary_df$n_years[i],
                summary_df$year_min[i],
                summary_df$year_max[i]))
  }
}

cat("\n----------------------------------------------------------------\n")
cat(sprintf("Metadata / non-country artefact rows excluded: %d\n",
            nrow(unmatched_metadata)))
cat("(These are source-file header strings, not real country rows)\n")
cat("----------------------------------------------------------------\n")
if (nrow(unmatched_metadata) > 0) {
  cat(paste0("  ", unique(unmatched_metadata$country), "\n"), sep = "")
}

cat("\n================================================================\n")
cat("Final object: merged\n")
cat(sprintf("  Dimensions : %d rows x %d columns\n", nrow(merged), ncol(merged)))
cat("  Structure  : 5 ALLDATA vars + all EFW vars (ISO_Code, EFW scores,\n")
cat("               sub-indices, rankings, region, income classification)\n")
cat("================================================================\n")

#write.csv(merged, "merged.csv", row.names = FALSE)


# ------------------------------------------------------------------------------
# Prepare merged data
# ------------------------------------------------------------------------------

quinq_years <- c(1970, 1975, 1980, 1985, 1990, 1995, 2000, 2005, 2010, 2015)


# ------------------------------------------------------------------------------
#   1) Construct EFW Jump
# ------------------------------------------------------------------------------


merged$Summary <- merged$`ECONOMIC FREEDOM ALL AREAS`

alldata <- merged %>%
  mutate(countrynum = as.integer(factor(country))) %>%
  group_by(country) %>%
  arrange(year) %>%
  # -- EFW jump indicator --
  # EFWjump = 1 if the EFW Summary index rose by 1 or more point over 5 years.
  # Set to NA if the country had a jump in the prior 5- or 10-year period or the
  # next 5-year period (to avoid contamination), and for Venezuela 2000.
  mutate(
    EFWdiff = Summary - lag(Summary, 1),   # lag(.,1) = 5-year lag in quinq panel
    EFWrankdiff = `EFW RANK` - lag(`EFW RANK`, 1),
  # Index Changes
    EFWjump = case_when(
      is.na(EFWdiff)  ~ NA_real_,
      EFWdiff >=  1    ~ 1,
      TRUE            ~ 0
    ),
  # Add DROP = precipitous drop in EFW
  EFWdrop = case_when(
    is.na(EFWdiff)  ~ NA_real_,
    EFWdiff <=  -1    ~ 1,
    TRUE            ~ 0
  ),
  # Rank Changes
  # EFWrankjump = 1 if the FEW Rank changed by 17 or more over 5 years.
  # Set to NA if the country had a jump in the prior 5- or 10-year period or the
  # next 5-year period (to avoid contamination), and for Venezuela 2000.
  EFWrankjump = case_when(
    is.na(EFWrankdiff)  ~ NA_real_,
    EFWrankdiff >=  17    ~ 1,
    TRUE            ~ 0
  ),
  # Rank Drop
  EFWrankdrop = case_when(
    is.na(EFWrankdiff)  ~ NA_real_,
    EFWrankdiff <=  -17    ~ 1,
    TRUE            ~ 0
  )
  ) %>%
  # ---------------------------------------------------------------------------
  # Adjacency blanking
  # All four conditions (lag 1, lag 2, lead 1, Venezuela 2000) are combined in
  # ONE if_else per flag so every reference to the flag on the RHS sees the
  # SAME pre-blanking column. This avoids the sequential-cascade bug where a
  # later if_else would have referenced an already-modified value.
  # `%in% 1` (instead of `== 1`) makes NA boundary values return FALSE rather
  # than NA, so the second observation in each country's series is preserved.
  # ---------------------------------------------------------------------------
  mutate(
    EFWjump = if_else(
      lag(EFWjump,  1) %in% 1 |
      lag(EFWjump,  2) %in% 1 |
      lead(EFWjump, 1) %in% 1 |
      (country == "Venezuela" & year == 2000),
      NA_real_, EFWjump
    ),
    EFWdrop = if_else(
      lag(EFWdrop,  1) %in% 1 |
      lag(EFWdrop,  2) %in% 1 |
      lead(EFWdrop, 1) %in% 1 |
      (country == "Venezuela" & year == 2000),
      NA_real_, EFWdrop
    )
  ) %>%
  
  # Same combined-condition adjacency blanking applied to the rank flags
  mutate(
    EFWrankjump = if_else(
      lag(EFWrankjump,  1) %in% 1 |
      lag(EFWrankjump,  2) %in% 1 |
      lead(EFWrankjump, 1) %in% 1 |
      (country == "Venezuela" & year == 2000),
      NA_real_, EFWrankjump
    ),
    EFWrankdrop = if_else(
      lag(EFWrankdrop,  1) %in% 1 |
      lag(EFWrankdrop,  2) %in% 1 |
      lead(EFWrankdrop, 1) %in% 1 |
      (country == "Venezuela" & year == 2000),
      NA_real_, EFWrankdrop
    )
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
    # Apply same adjacency exclusions as main jump (referencing the
    # already-blanked EFWjump column; `%in% 1` handles NA boundaries)
    EFW_smallerjump = if_else(
      lag(EFWjump, 1) %in% 1 | (country == "Venezuela" & year == 2000),
      NA_real_, EFW_smallerjump
    ),
    EFW_biggerjump  = if_else(
      lag(EFWjump, 1) %in% 1 | (country == "Venezuela" & year == 2000),
      NA_real_, EFW_biggerjump
    )
  ) %>%
  ungroup()   # leave alldata as a plain tibble downstream

write.csv(alldata, "merged.csv", row.names = FALSE)



