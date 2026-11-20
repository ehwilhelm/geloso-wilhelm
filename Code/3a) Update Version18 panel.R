# =============================================================================
# 3a) Update Version18 panel.R                                  20 Nov 2026
#
# Adds to Nishant's Version18 panel every country-year (1970-2020 every 5
# years, plus 2024) that has a rating in the "EFW Ratings" sheet of the 2026
# EFW file (the raw EFW source, Eric 20 Nov) and a UN IGME infant mortality
# estimate, but no row in Version18. Every variable of the added rows is
# rebuilt from the same source files Nishant used, after checking that the
# rebuild reproduces his existing rows.
#
# Also:
#   - fills 5-yr GDP pc growth where PWT has the year five years earlier
#     but Version18 has no value (same formula as Nishant's prior-year file);
#   - recomputes the panel's lag* columns (previous row of the country, as in
#     Version18), because added rows change which row comes before.
# Existing Version18 values are otherwise left exactly as they are.
#
# Reads (read-only): Datawork~Nishant/Version18.csv, the EFW 2026 xlsx,
#   "PWT csv.zip", and "Downloaded Dataset.zip" (UN IGME 2025, WDI extract,
#   OWID Polity, O'Reilly-Murphy state capacity with V-Dem, V-Dem v16).
# Writes: Data/Version18_updated.csv (panel, with a new last column
#   `row_source`) and Data/Version18_updated_checks.csv (rebuild checks).
# Nothing is written in Datawork~Nishant.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readxl)
})

find_root <- function() {
  d <- normalizePath(getwd())
  repeat {
    if (dir.exists(file.path(d, "Datawork~Nishant"))) return(d)
    up <- dirname(d)
    if (up == d) stop("Run from inside the geloso-wilhelm repository.")
    d <- up
  }
}
root <- find_root()
dw   <- file.path(root, "Datawork~Nishant")
dz   <- file.path(dw, "Downloaded Dataset.zip")

grid_years <- c(seq(1970, 2020, 5), 2024)
PWT_YEAR   <- function(y) ifelse(y == 2024, 2023, y)  # PWT 2024 not released
POLITY_YEAR <- function(y) ifelse(y == 2020, 2018, y) # Polity5 ends in 2018
# Version18's 2024 rows carry 2025 values for old-age dependency, urban
# population, the state capacity file and V-Dem (but 2024 for IGME, EFW and
# fertility). The added 2024 rows follow the same convention so the panel
# stays consistent; flagged in the data review.
Y2025 <- function(y) ifelse(y == 2024, 2025, y)

# --- Version18 ---------------------------------------------------------------
# Read as text so that existing cells are written back byte for byte
v18_txt <- read.csv(file.path(dw, "Version18.csv"), check.names = FALSE,
                    colClasses = "character", na.strings = character(0),
                    fileEncoding = "latin1")
v18_cols <- names(v18_txt)
num <- function(x) suppressWarnings(as.numeric(x))
v18 <- v18_txt
v18[] <- lapply(v18_txt, function(x) if (all(is.na(num(x[x != "" & x != "NA"]))) &&
                                         any(x != "" & x != "NA")) x else num(x))
v18$country <- v18_txt$country

# --- EFW Ratings sheet (raw EFW source) ---------------------------------------
efw <- suppressMessages(read_excel(
  file.path(dw, "economic-freedom-of-the-world-2026-master-index-data-for-researchers-iso.xlsx"),
  sheet = "EFW Ratings", skip = 3))
efw_cols <- intersect(names(efw), v18_cols)          # the 82 EFW columns
stopifnot(length(efw_cols) == 82)
efw <- efw %>% rename(year = Year, iso = ISO_Code) %>%
  mutate(year = as.integer(year)) %>% filter(year %in% grid_years)

# --- Country names -> ISO3 -----------------------------------------------------
# Version18 names that differ from the EFW file's names
iso_alias <- c("Bahamas" = "BHS", "Cote d'Ivoire" = "CIV", "Czech Republic" = "CZE",
               "Egypt" = "EGY", "Gambia" = "GMB", "Hong Kong" = "HKG", "Iran" = "IRN",
               "Kyrgyzstan" = "KGZ", "Laos" = "LAO", "Russia" = "RUS",
               "Slovakia" = "SVK", "South Korea" = "KOR", "Syria" = "SYR",
               "Turkey" = "TUR", "Venezuela" = "VEN", "Yemen" = "YEM")
efw_name_iso <- setNames(efw$iso, efw$Countries)
v18$iso <- ifelse(v18$country %in% names(iso_alias), iso_alias[v18$country],
                  efw_name_iso[v18$country])
stopifnot(!anyNA(v18$iso))
country_of_iso <- setNames(v18$country, v18$iso)

# --- Sources -------------------------------------------------------------------
cat("Reading sources...\n")
igme <- read.csv(unz(dz, "UN IGME 2025 3.csv"), check.names = FALSE,
                 stringsAsFactors = FALSE) %>%
  filter(`Series Name` == "UN IGME estimate", Sex == "Total",
         `Wealth Quintile` == "Total",
         Indicator %in% c("Infant mortality rate", "Under-five mortality rate")) %>%
  transmute(iso = REF_AREA, year = as.integer(floor(REF_DATE)), Indicator,
            OBS_VALUE, LOWER_BOUND, UPPER_BOUND)
igme_w <- full_join(
  igme %>% filter(Indicator == "Under-five mortality rate") %>%
    transmute(iso, year, U5MR = OBS_VALUE, U5MR_lower_bound = LOWER_BOUND,
              U5MR_upper_bound = UPPER_BOUND),
  igme %>% filter(Indicator == "Infant mortality rate") %>%
    transmute(iso, year, infantmortality = OBS_VALUE,
              IM_lower_bound = LOWER_BOUND, IM_upper_bound = UPPER_BOUND),
  by = c("iso", "year"))

pwt <- read.csv(unz(file.path(dw, "PWT csv.zip"), "pwt110 (2)-Data.csv"),
                check.names = FALSE, stringsAsFactors = FALSE, encoding = "UTF-8") %>%
  transmute(iso = countrycode, pyear = year, rgdpe, pop, hc)
pwt_gpc <- function(iso, y) {
  k <- match(paste(iso, y), paste(pwt$iso, pwt$pyear))
  pwt$rgdpe[k] / pwt$pop[k]
}

wdi_raw <- read.csv(unz(dz, paste0("P_Data_Extract_From_World_Development_Indicators/",
                                   "93a2d9b6-a9c7-4d05-9927-68ce9f5e3b63_Data.csv")),
                    check.names = FALSE, stringsAsFactors = FALSE)
wdi_raw <- wdi_raw[wdi_raw$`Series Code` %in% c("SP.DYN.TFRT.IN", "SP.POP.DPND.OL",
                                                "SP.URB.TOTL.IN.ZS"), ]
ycols <- grep("^[0-9]{4} \\[YR", names(wdi_raw), value = TRUE)
wdi <- do.call(rbind, lapply(ycols, function(yc) data.frame(
  iso = wdi_raw$`Country Code`, code = wdi_raw$`Series Code`,
  year = as.integer(substr(yc, 1, 4)),
  value = suppressWarnings(as.numeric(wdi_raw[[yc]])))))
wdi <- wdi %>% filter(year %in% c(grid_years, 2025)) %>%
  tidyr::pivot_wider(names_from = code, values_from = value)
wdi_f <- wdi %>% transmute(iso, year, fertilrate = SP.DYN.TFRT.IN)
wdi_o <- wdi %>% transmute(iso, y25 = year, oldagedep = SP.POP.DPND.OL,
                           urbanpop = SP.URB.TOTL.IN.ZS)

polity <- read.csv(unz(dz, "democracy-index-polity.csv"), check.names = FALSE,
                   stringsAsFactors = FALSE) %>%
  transmute(iso = Code, pyear = Year, polity5 = Democracy) %>% filter(iso != "")

sc_vars <- c("c_nar", "c_fisc", "c_comp", "pca_nar", "pca_fisc", "pca_comp",
             "v2x_rule", "v2svstterr", "v2clrspct", "v2dlencmps", "v2stfisccap",
             "v2peedueq")
statecap <- read.csv(unz(dz, "statecap_vdem_v16.csv"), check.names = FALSE,
                     stringsAsFactors = FALSE) %>%
  transmute(iso = country_text_id, y25 = year, across(all_of(sc_vars)))

vdem_vars <- c("v2x_polyarchy", "v2x_libdem", "v2x_partipdem", "v2x_delibdem",
               "v2x_egaldem")
vdem_file <- "V-Dem-CY-FullOthers-v16_csv/V-Dem-CY-Full+Others-v16.csv"
vdem_head <- names(read.csv(unz(dz, vdem_file), nrows = 1, check.names = FALSE))
keep <- c("country_text_id", "year", vdem_vars)
cc <- ifelse(vdem_head %in% keep, NA, "NULL")
vdem <- read.csv(unz(dz, vdem_file), colClasses = cc, check.names = FALSE) %>%
  rename(iso = country_text_id, y25 = year) %>% filter(y25 %in% c(grid_years, 2025))

# --- Rebuild every source variable for a set of (iso, year) ------------------
build <- function(keys) {
  keys %>%
    mutate(pyear = PWT_YEAR(year)) %>%
    left_join(igme_w, by = c("iso", "year")) %>%
    left_join(pwt, by = c("iso", "pyear")) %>%
    mutate(gdppc = rgdpe / pop, gdppc2 = gdppc^2, lngdppc = log(gdppc),
           lngdppc2 = lngdppc^2,
           # growth over the previous 5 years; the 2024 row (PWT 2023) is
           # compared with 2020, as in Version18
           gdppc_5growth = log(gdppc) -
             log(pwt_gpc(iso, ifelse(year == 2024, 2020, year - 5)))) %>%
    mutate(y25 = Y2025(year)) %>%
    left_join(wdi_f, by = c("iso", "year")) %>%
    left_join(wdi_o, by = c("iso", "y25")) %>%
    mutate(polyear = POLITY_YEAR(year)) %>%
    left_join(polity %>% rename(polyear = pyear), by = c("iso", "polyear")) %>%
    mutate(polity5 = if_else(year == 2024, NA_real_, as.numeric(polity5))) %>%
    left_join(statecap, by = c("iso", "y25")) %>%
    left_join(vdem, by = c("iso", "y25")) %>%
    left_join(efw %>% dplyr::select(iso, year, all_of(efw_cols)),
              by = c("iso", "year")) %>%
    dplyr::select(-pyear, -polyear, -y25)
}
src_vars <- c("U5MR", "U5MR_lower_bound", "U5MR_upper_bound", "infantmortality",
              "IM_lower_bound", "IM_upper_bound", "rgdpe", "pop", "hc", "gdppc",
              "gdppc2", "lngdppc", "lngdppc2", "gdppc_5growth", "fertilrate",
              "oldagedep", "polity5", "urbanpop", sc_vars, vdem_vars, efw_cols)
stopifnot(all(src_vars %in% v18_cols))

# --- Check: the rebuild reproduces Version18 ------------------------------------
reb <- build(v18 %>% dplyr::select(iso, year))
checks <- do.call(rbind, lapply(src_vars, function(s) {
  a <- num(v18_txt[[s]]); b <- num(reb[[s]])
  same <- (is.na(a) & is.na(b)) |
          (!is.na(a) & !is.na(b) & abs(a - b) <= 1e-6 * pmax(1, abs(b)))
  data.frame(variable = s, rows = length(a), identical = sum(same),
             v18_only = sum(!is.na(a) & is.na(b)),
             source_only = sum(is.na(a) & !is.na(b)),
             differ = sum(!is.na(a) & !is.na(b) & !same))
}))
cat("\nRebuild of existing Version18 rows (rows identical out of 1,486):\n")
print(checks[checks$identical < checks$rows, ], row.names = FALSE)
cat(sprintf("%d of %d variables reproduce exactly in every row.\n",
            sum(checks$identical == checks$rows), nrow(checks)))

# --- Rows to add ------------------------------------------------------------------
cand <- efw %>%
  filter(!is.na(`ECONOMIC FREEDOM ALL AREAS`)) %>%
  dplyr::select(iso, year, Countries) %>%
  anti_join(v18 %>% dplyr::select(iso, year), by = c("iso", "year"))
new <- build(cand %>% dplyr::select(iso, year)) %>%
  filter(!is.na(infantmortality))
new$country <- ifelse(new$iso %in% names(country_of_iso),
                      country_of_iso[new$iso],
                      cand$Countries[match(paste(new$iso, new$year),
                                           paste(cand$iso, cand$year))])
new$country <- iconv(new$country, "UTF-8", "ASCII//TRANSLIT")
cat(sprintf("\nAdding %d country-years (%d in countries already in Version18, %d in %d new countries).\n",
            nrow(new), sum(new$iso %in% v18$iso), sum(!new$iso %in% v18$iso),
            length(unique(new$iso[!new$iso %in% v18$iso]))))

# Country-level constants: countrynum and oecd as in the country's other rows
# (countrynum is empty in Version18's 2020 and 2024 rows, kept that way)
cnum <- v18 %>% filter(!is.na(countrynum)) %>% distinct(iso, countrynum)
oecd <- v18 %>% distinct(iso, oecd)
new <- new %>%
  left_join(cnum, by = "iso") %>%
  left_join(oecd, by = "iso") %>%
  mutate(countrynum = if_else(year >= 2020, NA_integer_, as.integer(countrynum)))

# --- Combine, fill growth, recompute lags ----------------------------------------
fmt <- function(x) ifelse(is.na(x), "", as.character(x))  # 15 significant digits
for (s in setdiff(v18_cols, names(new))) new[[s]] <- NA
new_txt <- as.data.frame(lapply(new[, v18_cols], fmt), check.names = FALSE,
                         stringsAsFactors = FALSE)
new_txt$year <- as.character(new$year)
old_txt <- v18_txt
old_txt$row_source <- "Version18"
new_txt$row_source <- "added 2026-11-20 from sources (3a script)"
old_txt$iso <- v18$iso; new_txt$iso <- new$iso
old_txt$prev_v18 <- ave(as.integer(old_txt$year), old_txt$country,
                        FUN = function(y) { o <- order(y); r <- rep(NA_integer_, length(y))
                                            r[o] <- c(NA, y[o][-length(y)]); r })
new_txt$prev_v18 <- NA_integer_
# base R from here on: dplyr would rename the duplicate-style EFW names
# ("data...8" etc.)
upd <- rbind(old_txt, new_txt[, names(old_txt)])
upd <- upd[order(upd$country, as.integer(upd$year)), ]
rownames(upd) <- NULL

# 5-yr growth where Version18 has none but PWT has both years
g_reb <- build(data.frame(iso = upd$iso, year = as.integer(upd$year)))$gdppc_5growth
fill <- is.na(num(upd$gdppc_5growth)) & !is.na(g_reb) & upd$row_source == "Version18"
upd$gdppc_5growth[fill] <- fmt(g_reb[fill])
cat(sprintf("Filled 5-yr GDP pc growth in %d existing rows: %s\n", sum(fill),
            paste(upd$country[fill], upd$year[fill], collapse = ", ")))

# lag* = previous row of the same country, as in Version18. Recomputed only
# where the previous row changed (added rows) or a base value was filled;
# all other lag cells stay byte for byte.
lag_map <- c(laghc = "hc", laglngdppc = "lngdppc", laggdpc_5growth = "gdppc_5growth",
             laglngdppc2 = "lngdppc2", lagfertilrate = "fertilrate",
             lagoldagedep = "oldagedep", lagpolity5 = "polity5",
             lagurbanpop = "urbanpop")
prev_of <- function(x) ave(x, upd$country, FUN = function(z) c(NA, z[-length(z)]))
upd$prev_upd    <- as.integer(prev_of(upd$year))
upd$prev_filled <- as.logical(prev_of(fill))
redo <- (is.na(upd$prev_v18) & !is.na(upd$prev_upd)) |
        (!is.na(upd$prev_v18) & upd$prev_v18 != upd$prev_upd) |
        upd$row_source != "Version18" | (upd$prev_filled %in% TRUE)
for (l in names(lag_map)) {
  prev_val <- ave(upd[[lag_map[[l]]]], upd$country,
                  FUN = function(x) c("", x[-length(x)]))
  prev_val[is.na(prev_val)] <- ""
  upd[[l]][redo] <- prev_val[redo]
}
cat(sprintf("Lag columns recomputed in %d existing rows (new previous row or filled growth).\n",
            sum(redo & upd$row_source == "Version18")))
upd <- upd[, c(v18_cols, "row_source")]

# --- Write (same layout as Version18: quotes only where a field has a comma) ----
q <- function(x) ifelse(grepl("[\",]", x), paste0("\"", gsub("\"", "\"\"", x), "\""), x)
out <- file.path(root, "Data", "Version18_updated.csv")
lines <- c(paste(q(names(upd)), collapse = ","),
           do.call(paste, c(lapply(upd, q), sep = ",")))
writeLines(lines, out, useBytes = TRUE)
write.csv(checks, file.path(root, "Data", "Version18_updated_checks.csv"),
          row.names = FALSE)
cat(sprintf("\nWrote %s: %d rows (%d Version18 + %d added), %d columns.\n",
            out, nrow(upd), sum(upd$row_source == "Version18"),
            sum(upd$row_source != "Version18"), ncol(upd)))
