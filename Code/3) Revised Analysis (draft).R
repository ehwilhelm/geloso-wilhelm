# =============================================================================
# 3) Revised Analysis (draft).R      DRAFT, 20 Nov 2026 - reads Version18.csv
#                                    Outcome switched to IMR LEVELS (19 Nov pm)
#
# Companion to "3) Revised Analysis Plan.md" (read that first).
#
# Paper: "Liberalizers Remember Dead Babies: Data Quality and Liberalization's
#         Effect on Infant Mortality" (Geloso & Wilhelm)
#
# Design (Eric, 18-19 Nov 2026):
#   Main regressor : 5-year change in the EFW summary index
#                    ("ECONOMIC FREEDOM ALL AREAS"). Change in EFW rank is a
#                    separate analysis (switch TREAT_SCALE; threshold to
#                    be decided).
#   Treatment      : liberalizer   = EFW change over t-5..t >= +1
#                    deliberalizer = EFW change over t-5..t <= -1
#                    Callais & Young adjacency blanking; Venezuela 2000 out.
#   Outcome        : IMR LEVEL (Eric, 19 Nov pm, replaces the IMR change):
#                    infant deaths per 1,000 live births ("infantmortality",
#                    UN IGME) at t+5, five years after the EFW window t-5..t
#                    (Callais & Young timing kept). OUTCOME = "IM_post".
#                    Alternative: "IM_t", the level at the end of the window.
#                    The earlier change outcomes stay available as settings:
#                    "change_IM_post" (t..t+5) and "change_IM" (t-5..t).
#   Covariates     : at t-5, same set as before (EFW, hc, ln GDP pc and its
#                    square, 5-yr GDP pc growth, fertility, old-age
#                    dependency, Polity5, urbanization, IMR).
#   Estimators     : PSM NN3, PSM kernel (Epanechnikov), Mahalanobis NN3 (BA).
#                    Each PSM estimator is also reported bias-adjusted (BA):
#                    within the matched sample, a regression of the outcome
#                    on IMR at t-5 among the matched controls corrects each
#                    match for its remaining gap in IMR at t-5 (Abadie and
#                    Imbens 2011). Added 19 Nov because, with the IMR level as
#                    the outcome, plain PSM leaves that gap in the estimate.
#   Specification sequence:
#     S1 Naive     : IMR level ~ EFW treatment, baseline covariates
#     S2 + SC      : + O'Reilly-Murphy state capacity c_comp (only; Eric,
#                    19 Nov: c_comp and pca_comp never in the same spec)
#     S3 Headline  : + con_int = IM_upper_bound - IM_lower_bound (data quality)
#     Relative precision (rp) is dropped from the analysis.
#   Sample         : headline 1970-2020 (last EFW window 2010-15, outcome
#                    2015-20). Appendix: extension to 2024 (APPENDIX_2024).
#
# Data notes for Version18.csv (Nishant, 20 Nov):
#   - totalpop and totalGDP are dropped. GDP per capita = rgdpe / pop, both
#     from PWT 11.0 (Eric, 20 Nov), now with full decimals.
#   - 5-yr GDP pc growth: the panel's `gdppc_5growth` column is used. Where
#     the previous 5-year point is not a panel row (e.g. 1965 for 1970),
#     Nishant computed it from PWT (Datawork~Nishant/gdp_growth_prior_rows.csv).
#     Where the panel has both points, it equals the log difference computed
#     here. If the panel ever has 1965 rows, they are read for growth only.
#   - PWT has no 2024 release yet: the 2024 rows carry 2023 PWT values.
#   - Polity5 ends in 2018; the 2018 value stands in for 2020 and later.
#   - The panel's lag* columns are not used; all lags are rebuilt here.
#
# Data: Datawork~Nishant is READ-ONLY. Nothing is written there.
# Outputs: Results/<data file name>/ (e.g. Results/version18/). Earlier
# results (Results/version16/, October Results/) stay untouched.
# =============================================================================


# =============================================================================
# Part 0: Settings
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(Matching)
  library(ggplot2)
  library(fixest)
})

find_root <- function() {
  d <- normalizePath(getwd(), winslash = "/")
  for (i in 1:5) {
    if (dir.exists(file.path(d, "Code")) && dir.exists(file.path(d, "Data")))
      return(d)
    d <- dirname(d)
  }
  stop("Run this script from the repository root or from Code/.")
}
root <- find_root()

# RA data (read-only). Override with Sys.setenv(REVISED_CSV = "...").
DATA_FILE <- Sys.getenv("REVISED_CSV",
  file.path(root, "Datawork~Nishant", "Version18.csv"))

# APPENDIX_2024 = FALSE: headline, 1970-2020.
# APPENDIX_2024 = TRUE : appendix, adds the 2015-20 EFW window with a
#                        2020-24 outcome (4 years, scaled to 5).
# Set from the command line with Sys.setenv(APPENDIX_2024 = "TRUE").
APPENDIX_2024 <- as.logical(Sys.getenv("APPENDIX_2024", "FALSE"))

# OUTCOME (set with Sys.setenv(OUTCOME = "...")):
#   "IM_post"        headline: IMR level at t+5 (for the appendix's 2015-20
#                    window this is the 2024 level, 4 years after)
#   "IM_t"           IMR level at t, the end of the EFW window
#   "change_IM_post" earlier outcome: IMR(t+5) - IMR(t)
#   "change_IM"      earlier outcome: IMR(t) - IMR(t-5)
OUTCOME <- Sys.getenv("OUTCOME", "IM_post")
# TREAT_SCALE: "score" (main, EFW score change of >= +1 / <= -1 points) or
#   "rank" (separate analysis on the EFW percentile rank; rank 1 = freest).
#   The 20% rank and 20% score runs were dropped on 19 Nov; the rank
#   threshold is still to be decided.
TREAT_SCALE <- Sys.getenv("TREAT_SCALE", "score")
THRESHOLD      <- 1      # "score": EFW points
RANK_THRESHOLD <- NA     # "rank": percentile points of the ranking, TO DECIDE
if (TREAT_SCALE == "rank" && is.na(RANK_THRESHOLD))
  stop("Set RANK_THRESHOLD before running the rank analysis.")

SC_VARS <- "c_comp"     # O'Reilly-Murphy ISC. Alternative: "pca_comp" (r = 0.99999);
                        # never both in one specification (Eric, 19 Nov)
GDP_SOURCE <- "rgdpe_pop"  # "rgdpe_pop" (PWT, Eric 20 Nov) | "gdppc" (panel column)
FERT_OPTION <- "F1"                 # F1 keep lagged fertility (decided 18 Nov)

B_BOOT      <- as.integer(Sys.getenv("B_BOOT", "200"))
SEED        <- 50826
psm_caliper <- 0.25
kernel_bw   <- 0.06

END_YEAR   <- if (APPENDIX_2024) 2024 else 2020
grid_years <- c(seq(1970, 2020, 5), if (APPENDIX_2024) 2024)
# grid_years gets 1965 added below if the panel has 1965 rows (growth only)

run_tag <- paste0(if (APPENDIX_2024) "appendix_1970-2024" else "headline_1970-2020",
                  if (OUTCOME == "IM_post") "" else paste0("_", OUTCOME),
                  if (TREAT_SCALE == "rank") "_rank" else "")

# Labels that follow the outcome
out_lab <- switch(OUTCOME,
  IM_post        = list(what = "IMR level 5 years after the EFW window",
                        axis = "ATT (IMR level at t+5, per 1,000)",
                        sign = "Negative = IMR lower than in matched controls."),
  IM_t           = list(what = "IMR level at the end of the EFW window",
                        axis = "ATT (IMR level at t, per 1,000)",
                        sign = "Negative = IMR lower than in matched controls."),
  change_IM_post = list(what = "IMR change over the next 5 years",
                        axis = "ATT (change in IMR t to t+5, per 1,000)",
                        sign = "Negative = IMR fell faster than in matched controls."),
  change_IM      = list(what = "IMR change over the EFW window",
                        axis = "ATT (change in IMR t-5 to t, per 1,000)",
                        sign = "Negative = IMR fell faster than in matched controls."))
data_tag <- tolower(tools::file_path_sans_ext(basename(DATA_FILE)))
out_dir <- file.path(root, "Results", data_tag, run_tag)
tab_dir <- file.path(out_dir, "tables")
fig_dir <- file.path(out_dir, "figures")
dir.create(tab_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)


# =============================================================================
# Part 1: Load, GDP per capita, complete grid, lags
# =============================================================================

raw <- read.csv(DATA_FILE, check.names = FALSE, stringsAsFactors = FALSE,
                fileEncoding = "latin1")
cat(sprintf("Loaded %s: %d rows x %d cols\n", basename(DATA_FILE),
            nrow(raw), ncol(raw)))
if (any(raw$year == 1965)) {
  grid_years <- c(1965, grid_years)
  cat("1965 rows found: used for the 1965-70 GDP pc growth covariate.\n")
}

level_vars <- c("infantmortality", "IM_lower_bound", "IM_upper_bound",
                "EFW", "EFW_rank", "gdppc", "gdppc_5growth_panel", "rgdpe", "pop", "hc", "fertilrate",
                "oldagedep", "polity5", "urbanpop", SC_VARS)

panel <- raw %>%
  rename(EFW = `ECONOMIC FREEDOM ALL AREAS`, EFW_rank = `EFW RANK`,
         gdppc_5growth_panel = gdppc_5growth) %>%
  filter(year %in% grid_years) %>%
  dplyr::select(country, year, all_of(level_vars)) %>%
  mutate(across(all_of(level_vars), ~ suppressWarnings(as.numeric(.)))) %>%
  # Complete grid, so lag() is always the previous grid point
  complete(country, year = grid_years) %>%
  arrange(country, year) %>%
  group_by(year) %>%
  mutate(
    # Percentile rank within the year (0 = freest, 1 = least free), because
    # the number of ranked countries grows from 82 to 153
    EFW_prank = (EFW_rank - 1) / (sum(!is.na(EFW_rank)) - 1)
  ) %>%
  group_by(country) %>%
  mutate(
    # GDP per capita: panel column (OWID) or PWT rgdpe / pop
    gdppc   = if (GDP_SOURCE == "rgdpe_pop") if_else(pop > 0, rgdpe / pop, NA_real_)
              else gdppc,
    lngdppc = log(gdppc),
    lngdppc2 = lngdppc^2,
    window      = year - lag(year),       # 5 (4 for 2020-2024)
    window_next = lead(year) - year,      # 5 (4 for 2020-2024)
    # 5-yr growth: computed log difference where the panel has the previous
    # point; otherwise the panel's own value (prior years filled by Nishant)
    gdppc_5growth = coalesce((lngdppc - lag(lngdppc)) * 5 / window,
                             gdppc_5growth_panel),
    # Data quality: width of the IGME 90% interval (deaths per 1,000)
    con_int = IM_upper_bound - IM_lower_bound,
    # Outcomes (C&Y timing: treatment over t-5..t, outcome over t..t+5)
    change_IM_post = (lead(infantmortality) - infantmortality) * 5 / window_next,
    IM_post        = lead(infantmortality),          # headline: level at t+5
    IM_t           = infantmortality,                # level at t
    change_IM      = (infantmortality - lag(infantmortality)) * 5 / window, # A2
    # Treatment inputs
    EFWdiff   = EFW - lag(EFW),
    EFWrdiff  = -(EFW_prank - lag(EFW_prank)),   # > 0 = moved up the ranking
    # Covariates at t-5
    lagEFW          = lag(EFW),
    laghc           = lag(hc),
    laglngdppc      = lag(lngdppc),
    laglngdppc2     = lag(lngdppc2),
    laggdpc_5growth = lag(gdppc_5growth),
    lagfertilrate   = lag(fertilrate),
    lagoldagedep    = lag(oldagedep),
    lagpolity5      = lag(polity5),
    lagurbanpop     = lag(urbanpop),
    lag_IM          = lag(infantmortality),
    lag_con_int     = lag(con_int)
  ) %>%
  ungroup()

for (v in SC_VARS) {
  panel[[paste0("lag_", v)]] <- ave(panel[[v]], panel$country,
                                    FUN = function(x) dplyr::lag(x))
}
lag_sc <- paste0("lag_", SC_VARS)


# =============================================================================
# Part 2: Treatments (Callais & Young blanking, as in "2) Analysis.R")
# =============================================================================

cy_blank <- function(x) {
  n <- length(x)
  if (n < 2) return(x)
  for (i in 2:n) if (x[i - 1] %in% 1) x[i] <- NA
  if (n >= 3) for (i in 3:n) if (x[i - 2] %in% 1) x[i] <- NA
  for (i in 1:(n - 1)) if (x[i + 1] %in% 1) x[i] <- NA
  x
}

treat_diff <- if (TREAT_SCALE == "rank") "EFWrdiff" else "EFWdiff"
treat_cut  <- if (TREAT_SCALE == "rank") RANK_THRESHOLD else THRESHOLD
treat_text <- if (TREAT_SCALE == "rank") "a large EFW rank change" else
  "a 1-point EFW change"

panel <- panel %>%
  arrange(country, year) %>%
  group_by(country) %>%
  mutate(
    lib_episode   = as.integer(.data[[treat_diff]] >=  treat_cut),
    delib_episode = as.integer(.data[[treat_diff]] <= -treat_cut),
    EFWjump = cy_blank(lib_episode),
    EFWdrop = cy_blank(delib_episode),
    EFWjump = if_else(country == "Venezuela" & year == 2000, NA_integer_, EFWjump),
    EFWdrop = if_else(country == "Venezuela" & year == 2000, NA_integer_, EFWdrop)
  ) %>%
  ungroup()

episodes <- panel %>%
  filter(EFWjump %in% 1 | EFWdrop %in% 1, !is.na(.data[[OUTCOME]])) %>%
  transmute(country, period = paste0(year - window, "-", year),
            type = if_else(EFWjump %in% 1, "Liberalization", "Deliberalization"),
            EFW_start = round(lagEFW, 2), EFW_change = round(EFWdiff, 2),
            pctile_rank_change = round(EFWrdiff, 3))
write.csv(episodes, file.path(tab_dir, "T1_episodes.csv"), row.names = FALSE)


# =============================================================================
# Part 3: Covariates and specification sequence
# =============================================================================

base_covars <- c("lagEFW", "laghc", "laglngdppc", "laggdpc_5growth",
                 "laglngdppc2", "lagfertilrate", "lagoldagedep", "lagpolity5",
                 "lagurbanpop", "lag_IM")

specs <- list(
  S1 = base_covars,                                 # naive
  S2 = c(base_covars, lag_sc),                      # + state capacity
  S3 = c(base_covars, lag_sc, "lag_con_int"))       # headline: + con_int
spec_labels <- c(
  S1 = "1) Naive",
  S2 = "2) + state capacity",
  S3 = "3) + state capacity + con_int (headline)")

contrasts <- list(
  dq_given_sc = c("S3", "S2"),   # HEADLINE: what con_int changes given SC
  sc          = c("S2", "S1"),   # what state capacity changes
  sc_and_dq   = c("S3", "S1"))   # both

all_covars <- unique(unlist(specs))


# =============================================================================
# Part 4: Estimators (from "2) Analysis.R")
# =============================================================================

ps_fit <- function(df, treatment, covars) {
  f <- as.formula(paste(treatment, "~", paste(covars, collapse = " + ")))
  suppressWarnings(fitted(glm(f, data = df, family = binomial(link = "logit"))))
}

# BA_VAR: the covariate the bias-adjusted PSM estimators regress on
BA_VAR <- "lag_IM"

att_nn3 <- function(df, treatment, ps, y = OUTCOME, ba = FALSE) {
  m <- tryCatch(if (ba)
                  Match(Y = df[[y]], Tr = df[[treatment]], X = ps, Z = df[[BA_VAR]],
                        M = 3, estimand = "ATT", caliper = psm_caliper,
                        replace = TRUE, CommonSupport = TRUE, BiasAdjust = TRUE)
                else
                  Match(Y = df[[y]], Tr = df[[treatment]], X = ps, M = 3,
                        estimand = "ATT", caliper = psm_caliper, replace = TRUE,
                        CommonSupport = TRUE),
                error = function(e) NULL)
  if (!is.list(m) || length(m$est) == 0) return(list(att = NA_real_, m = NULL))
  # With CommonSupport = TRUE, Match() drops rows outside the common support
  # and its index.treated / index.control refer to the TRIMMED data. Keep the
  # map back to rows of df (needed for balance tables).
  tr <- df[[treatment]] == 1
  lo <- max(min(ps[tr]), min(ps[!tr])); hi <- min(max(ps[tr]), max(ps[!tr]))
  m$rows <- which(ps >= lo & ps <= hi)
  list(att = as.numeric(m$est), m = m)
}

att_kernel <- function(df, treatment, ps, y = OUTCOME, ba = FALSE) {
  tr <- df[[treatment]] == 1
  yy <- df[[y]]; zz <- df[[BA_VAR]]
  ps_t <- ps[tr]; ps_c <- ps[!tr]; y_t <- yy[tr]; y_c <- yy[!tr]
  z_t <- zz[tr]; z_c <- zz[!tr]
  on_support <- ps_t >= min(ps_c) & ps_t <= max(ps_c)
  # Normalized kernel weights: row i = treated, column j = control
  W <- t(vapply(ps_t, function(p) {
    u <- (ps_c - p) / kernel_bw
    w <- ifelse(abs(u) < 1, 0.75 * (1 - u^2), 0)
    if (sum(w) == 0) rep(NA_real_, length(w)) else w / sum(w)
  }, numeric(length(ps_c))))
  ok_row <- on_support & !is.na(W[, 1])
  beta <- 0
  if (ba && any(ok_row)) {
    # Regression of the outcome on IMR(t-5) among matched controls, weighted
    # by the total kernel weight each control receives
    wc <- colSums(W[ok_row, , drop = FALSE])
    use <- wc > 0
    if (sum(use) > 2)
      beta <- unname(coef(lm(y_c[use] ~ z_c[use], weights = wc[use]))[2])
  }
  # Counterfactual: weighted control outcomes, shifted by beta times the
  # treated-control gap in IMR(t-5) (beta = 0 without bias adjustment)
  cf <- as.numeric(W %*% y_c) + beta * (z_t - as.numeric(W %*% z_c))
  keep <- ok_row & !is.na(cf)
  list(att = if (any(keep)) mean(y_t[keep] - cf[keep]) else NA_real_,
       n_treated = sum(keep))
}

att_mah <- function(df, treatment, covars, y = OUTCOME) {
  m <- tryCatch(Match(Y = df[[y]], Tr = df[[treatment]],
                      X = as.matrix(df[, covars]), M = 3, estimand = "ATT",
                      Weight = 2, BiasAdjust = TRUE, replace = TRUE),
                error = function(e) NULL)
  if (!is.list(m)) return(list(att = NA_real_, se = NA_real_, m = NULL))
  list(att = as.numeric(m$est), se = as.numeric(m$se), m = m)
}

# One common sample per pair: complete on all outcomes and every covariate
# of every spec, so S1-S3 differ only in the covariates.
test_sample <- function(data, treatment, control_filter = NULL) {
  need <- c(OUTCOME, all_covars)
  ok <- complete.cases(as.data.frame(data)[, unique(need)])
  df <- as.data.frame(data[ok, ])
  df <- df[!is.na(df[[treatment]]), ]
  if (!is.null(control_filter)) {
    drop <- df[[treatment]] == 0 & df[[control_filter]] %in% 1
    df <- df[!drop, ]
  }
  df
}

estimate_specs <- function(df, treatment, y = OUTCOME) {
  lapply(specs, function(cv) {
    ps <- ps_fit(df, treatment, cv)
    nn <- att_nn3(df, treatment, ps, y)
    list(nn3 = nn$att, nn3_match = nn$m,
         nn3_ba = att_nn3(df, treatment, ps, y, ba = TRUE)$att,
         kernel = att_kernel(df, treatment, ps, y)$att,
         kernel_ba = att_kernel(df, treatment, ps, y, ba = TRUE)$att,
         mah = att_mah(df, treatment, cv, y))
  })
}

psm_ests <- c("nn3", "nn3_ba", "kernel", "kernel_ba")
psm_names <- c(nn3 = "PSM NN3", nn3_ba = "PSM NN3 (BA)", kernel = "PSM Kernel",
               kernel_ba = "PSM Kernel (BA)")

cluster_boot <- function(df, treatment, y = OUTCOME, B = B_BOOT) {
  countries <- unique(df$country)
  idx <- split(seq_len(nrow(df)), df$country)
  cols <- paste(rep(names(specs), each = 4), psm_ests, sep = ".")
  res <- matrix(NA_real_, B, length(cols), dimnames = list(NULL, cols))
  set.seed(SEED)
  for (b in seq_len(B)) {
    db <- df[unlist(idx[sample(countries, length(countries), TRUE)],
                    use.names = FALSE), ]
    if (sum(db[[treatment]] == 1) < 5) next
    for (s in names(specs)) {
      ps <- tryCatch(ps_fit(db, treatment, specs[[s]]), error = function(e) NULL)
      if (is.null(ps)) next
      res[b, paste0(s, ".nn3")]       <- att_nn3(db, treatment, ps, y)$att
      res[b, paste0(s, ".nn3_ba")]    <- att_nn3(db, treatment, ps, y, ba = TRUE)$att
      res[b, paste0(s, ".kernel")]    <- att_kernel(db, treatment, ps, y)$att
      res[b, paste0(s, ".kernel_ba")] <- att_kernel(db, treatment, ps, y, ba = TRUE)$att
    }
  }
  res
}

smd_matched <- function(x, m) {
  if (!is.null(m$rows)) x <- x[m$rows]   # PSM NN3: indices are on trimmed data
  (weighted.mean(x[m$index.treated], m$weights) -
     weighted.mean(x[m$index.control], m$weights)) / sd(x[unique(m$index.treated)])
}
smd_raw <- function(x, tr) (mean(x[tr]) - mean(x[!tr])) / sd(x[tr])


# =============================================================================
# Part 5: Diagnostics
# =============================================================================

coverage <- panel %>% group_by(year) %>%
  summarise(across(all_of(c("infantmortality", "con_int", "EFW", "gdppc",
                            SC_VARS, "polity5", "hc")), ~ sum(!is.na(.))),
            .groups = "drop")
write.csv(coverage, file.path(tab_dir, "D1_coverage_by_year.csv"), row.names = FALSE)

d2_vars <- c("lag_IM", "lag_con_int", lag_sc, "lagpolity5", "lagfertilrate",
             "laglngdppc", "laghc", "lagEFW")
write.csv(round(cor(panel[, d2_vars], use = "pairwise.complete.obs"), 3),
          file.path(tab_dir, "D2_correlations.csv"))

vif_tab <- {
  dfv <- test_sample(panel, "EFWjump")
  sapply(specs$S3, function(v) {
    others <- setdiff(specs$S3, v)
    r2 <- summary(lm(as.formula(paste(v, "~", paste(others, collapse = "+"))),
                     data = dfv))$r.squared
    1 / (1 - r2)
  })
}
write.csv(data.frame(variable = names(vif_tab), VIF = round(vif_tab, 1)),
          file.path(tab_dir, "D2_vif_headline.csv"), row.names = FALSE)

selection <- do.call(rbind, lapply(c(jump = "EFWjump", drop = "EFWdrop"), function(tr) {
  df <- test_sample(panel, tr)
  f  <- as.formula(paste(tr, "~", paste(specs$S3, collapse = " + ")))
  co <- summary(glm(f, data = df, family = binomial))$coefficients
  data.frame(treatment = tr, term = rownames(co), round(co, 3), row.names = NULL)
}))
write.csv(selection, file.path(tab_dir, "D3_selection_logit.csv"), row.names = FALSE)


# =============================================================================
# Part 6: Regression benchmark, IMR level ~ continuous EFW change
# =============================================================================
# The "naive IMR ~ delta EFW" step in its simplest form: OLS of the outcome
# (IMR level at t+5) on the EFW change over the window, year fixed effects,
# country-clustered SEs, then the same three-step sequence.

reg_df <- panel %>% filter(!is.na(.data[[OUTCOME]])) %>%
  filter(if_all(all_of(all_covars), ~ !is.na(.)), !is.na(EFWdiff)) %>%
  filter(!(country == "Venezuela" & year == 2000))
rhs <- list(
  R0 = "EFWdiff",
  R1 = paste(c("EFWdiff", base_covars), collapse = " + "),
  R2 = paste(c("EFWdiff", base_covars, lag_sc), collapse = " + "),
  R3 = paste(c("EFWdiff", base_covars, lag_sc, "lag_con_int"), collapse = " + "))
regs <- lapply(rhs, function(r)
  feols(as.formula(paste(OUTCOME, "~", r, "| year")), data = reg_df,
        cluster = ~ country))
reg_tab <- do.call(rbind, lapply(names(regs), function(k) {
  ct <- coeftable(regs[[k]])
  data.frame(model = k, coef_EFWdiff = ct["EFWdiff", 1], se = ct["EFWdiff", 2],
             p = ct["EFWdiff", 4], n = nobs(regs[[k]]))
}))
reg_tab$model <- c("Delta EFW only", "+ baseline covariates",
                   "+ state capacity", "+ con_int")
write.csv(reg_tab, file.path(tab_dir, "T6_regression_continuous_EFW.csv"),
          row.names = FALSE)
print(reg_tab)


# =============================================================================
# Part 7: Pairs A-D (Tests 1-8), all specs, contrasts, balance
# =============================================================================

pairs <- list(
  A = list(treatment = "EFWjump", control_filter = NULL),
  B = list(treatment = "EFWjump", control_filter = "delib_episode"),
  C = list(treatment = "EFWdrop", control_filter = NULL),
  D = list(treatment = "EFWdrop", control_filter = "lib_episode"))
pair_names <- c(A = "Liberalization", B = "Liberalization, deliberalizers out of control group",
                C = "Deliberalization", D = "Deliberalization, liberalizers out of control group")

run_pair <- function(df, treatment, y, label) {
  n_tr <- sum(df[[treatment]] == 1)
  cat(sprintf("[%s] %s: %d rows, %d treated, %d countries\n", y, label,
              nrow(df), n_tr, length(unique(df$country))))
  if (n_tr < 3) return(NULL)
  list(df = df, treatment = treatment, n_treated = n_tr,
       est = estimate_specs(df, treatment, y),
       boot = cluster_boot(df, treatment, y))
}

run_all <- function(y) {
  out <- list()
  for (p in names(pairs)) {
    pr <- pairs[[p]]
    out[[p]] <- run_pair(test_sample(panel, pr$treatment, pr$control_filter),
                         pr$treatment, y, paste("Pair", p))
  }
  out
}

att_rows <- function(r, s) {
  e <- r$est[[s]]
  data.frame(spec = s, label = spec_labels[[s]],
             estimator = c(psm_names[psm_ests], "Mahalanobis NN3 (BA)"),
             att = c(sapply(psm_ests, function(k) e[[k]]), e$mah$att),
             se  = c(sapply(psm_ests, function(k)
                       sd(r$boot[, paste0(s, ".", k)], na.rm = TRUE)),
                     e$mah$se),
             n_treated = r$n_treated, n = nrow(r$df))
}

att_table <- function(results) {
  tab <- do.call(rbind, lapply(names(results), function(p) {
    if (is.null(results[[p]])) return(NULL)
    cbind(pair = p, do.call(rbind, lapply(names(specs), function(s)
      att_rows(results[[p]], s))))
  }))
  tab$p_value <- 2 * pnorm(-abs(tab$att / tab$se))
  tab
}

contrast_table <- function(results) {
  do.call(rbind, lapply(names(results), function(p) {
    r <- results[[p]]
    if (is.null(r)) return(NULL)
    do.call(rbind, lapply(names(contrasts), function(k) {
      a <- contrasts[[k]][1]; b <- contrasts[[k]][2]
      do.call(rbind, lapply(psm_ests, function(est) {
        d_hat <- r$est[[a]][[est]] - r$est[[b]][[est]]
        d_bt  <- r$boot[, paste0(a, ".", est)] - r$boot[, paste0(b, ".", est)]
        data.frame(pair = p, contrast = k, estimator = est, diff = d_hat,
                   se = sd(d_bt, na.rm = TRUE),
                   share_of_base = d_hat / r$est[[b]][[est]])
      }))
    }))
  }))
}

balance_table <- function(results) {
  bal_vars <- c(lag_sc, "lag_con_int", "lag_IM", "lagfertilrate", "lagpolity5")
  do.call(rbind, lapply(names(results), function(p) {
    r <- results[[p]]
    if (is.null(r)) return(NULL)
    tr <- r$df[[r$treatment]] == 1
    do.call(rbind, lapply(names(specs), function(s) {
      m_nn  <- r$est[[s]]$nn3_match
      m_mah <- r$est[[s]]$mah$m
      do.call(rbind, lapply(bal_vars, function(v) {
        x <- r$df[[v]]
        data.frame(pair = p, spec = s, variable = v,
                   smd_before    = smd_raw(x, tr),
                   smd_after_nn3 = if (is.null(m_nn)) NA else smd_matched(x, m_nn),
                   smd_after_mah = if (is.null(m_mah)) NA else smd_matched(x, m_mah))
      }))
    }))
  }))
}

res_main <- run_all(OUTCOME)
att_main <- att_table(res_main)
con_main <- contrast_table(res_main)
bal_main <- balance_table(res_main)
write.csv(att_main, file.path(tab_dir, "T3_att.csv"), row.names = FALSE)
write.csv(con_main, file.path(tab_dir, "T4_contrasts.csv"), row.names = FALSE)
write.csv(bal_main, file.path(tab_dir, "T5_balance.csv"), row.names = FALSE)

sum_vars <- c(OUTCOME, "EFWdiff", all_covars)
sumstats <- res_main$A$df[, sum_vars] %>%
  summarise(across(everything(),
                   list(Mean = ~mean(.), SD = ~sd(.), Min = ~min(.), Max = ~max(.)),
                   .names = "{.col}__{.fn}")) %>%
  pivot_longer(everything(), names_to = c("Variable", ".value"), names_sep = "__")
write.csv(sumstats, file.path(tab_dir, "T2_summary_statistics.csv"), row.names = FALSE)


# =============================================================================
# Part 8: Liberalizers (headline) vs deliberalizers (appendix)
# =============================================================================
# Full-sample estimates from Part 7: liberalizers = pair A (headline),
# deliberalizers = pair C (appendix). The above/below-median EFW split was
# dropped on 19 Nov (Eric): the halves were too thin to estimate.
# Two versions of the figure:
#   F1  : "No DQ control" (S2: naive + state capacity) vs
#         "DQ control: con_int" (S3, headline)
#   F1b : "No state capacity control" (S1, naive) vs
#         "State capacity control" (S2); neither controls for data quality

side_names <- c(A = "Liberalizers (headline)", C = "Deliberalizers (appendix)")
est_levels <- c("Mahalanobis NN3 (BA)", "PSM Kernel (BA)", "PSM Kernel",
                "PSM NN3 (BA)", "PSM NN3")

lib_delib_tab <- att_main %>% filter(pair %in% names(side_names))
write.csv(lib_delib_tab, file.path(tab_dir, "T7_liberalizers_vs_deliberalizers.csv"),
          row.names = FALSE)

n_lab <- lib_delib_tab %>% group_by(pair) %>%
  summarise(n_treated = first(n_treated), n = first(n), .groups = "drop") %>%
  mutate(side = factor(side_names[pair], levels = side_names),
         lab = paste0(n_treated, " treated, ", n, " obs"))

# spec_map: named vector, spec code -> legend label (first = without the
# control, second = with it)
ba_note <- paste0("BA = bias-adjusted. PSM (BA): regression on IMR at t-5 within the matched sample.\n",
                  "Mahalanobis (BA): regression on all matching covariates.")

plot_sides <- function(spec_map, cols, note, file) {
  g <- lib_delib_tab %>%
    filter(spec %in% names(spec_map)) %>%
    mutate(ctrl = factor(spec_map[spec], levels = spec_map),
           side = factor(side_names[pair], levels = side_names),
           estimator = factor(estimator, levels = est_levels),
           lo = att - 1.96 * se, hi = att + 1.96 * se)
  f <- ggplot(g, aes(x = att, y = estimator, colour = ctrl)) +
    geom_vline(xintercept = 0, colour = "grey30") +
    geom_errorbar(aes(xmin = lo, xmax = hi), width = 0, orientation = "y",
                  linewidth = 0.7, position = position_dodge(width = 0.55)) +
    geom_point(size = 2.6, position = position_dodge(width = 0.55)) +
    geom_text(data = n_lab, aes(x = Inf, y = Inf, label = lab), inherit.aes = FALSE,
              hjust = 1.05, vjust = 1.4, size = 3, colour = "grey35") +
    facet_wrap(~ side, nrow = 1, scales = "free_x") +
    scale_colour_manual(values = setNames(cols, spec_map), drop = FALSE) +
    labs(title = paste("Effect of", treat_text, "on the", out_lab$what),
         subtitle = paste0("ATT in deaths per 1,000 live births with 95% CI, ",
                           if (APPENDIX_2024) "1970-2024 (appendix)" else "1970-2020",
                           ". ", out_lab$sign, "\n", note, "\n", ba_note),
         x = out_lab$axis, y = NULL, colour = NULL) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "bottom", strip.text = element_text(face = "bold"),
          plot.title = element_text(face = "bold"), panel.spacing = unit(1.5, "lines"))
  ggsave(file.path(fig_dir, file), f, width = 10, height = 6.4, dpi = 200)
  invisible(f)
}

sc_name <- paste(SC_VARS, collapse = ", ")
plot_sides(c(S2 = "No DQ control", S3 = "DQ control: con_int"),
           c("#2a6fdb", "#e8613a"),
           paste0("Both specifications control for state capacity (", sc_name, ")."),
           "F1_lib_vs_delib_dq.png")
plot_sides(c(S1 = "No state capacity control",
             S2 = paste0("State capacity control: ", sc_name)),
           c("#8a8a8a", "#2a6fdb"),
           "Neither specification controls for data quality (con_int).",
           "F1b_lib_vs_delib_sc.png")


# =============================================================================
# Part 9: Full-sample figures
# =============================================================================

spec_cols <- c("1) Naive" = "#8a8a8a", "2) + state capacity" = "#2a6fdb",
               "3) + state capacity + con_int (headline)" = "#e8613a")

f2 <- att_main %>%
  mutate(pair = factor(pair_names[pair], levels = pair_names),
         label = factor(label, levels = names(spec_cols)),
         estimator = factor(estimator, levels = est_levels),
         lo = att - 1.96 * se, hi = att + 1.96 * se) %>%
  ggplot(aes(x = att, y = estimator, colour = label)) +
  geom_vline(xintercept = 0, colour = "grey30") +
  geom_errorbar(aes(xmin = lo, xmax = hi), width = 0, orientation = "y", linewidth = 0.7,
                 position = position_dodge(width = 0.6)) +
  geom_point(size = 2.4, position = position_dodge(width = 0.6)) +
  facet_wrap(~ pair, ncol = 1, scales = "free_x") +
  scale_colour_manual(values = spec_cols) +
  labs(title = "ATT by specification step",
       subtitle = paste0(out_lab$what, ", deaths per 1,000, 95% CI"),
       x = out_lab$axis, y = NULL, colour = NULL) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom", strip.text = element_text(face = "bold", hjust = 0))
ggsave(file.path(fig_dir, "F2_att_by_spec_step.png"), f2, width = 9, height = 12, dpi = 200)

f3 <- con_main %>% filter(contrast == "dq_given_sc") %>%
  mutate(pair = factor(pair_names[pair], levels = rev(pair_names))) %>%
  ggplot(aes(x = diff, y = pair, colour = estimator)) +
  geom_vline(xintercept = 0, colour = "grey30") +
  geom_pointrange(aes(xmin = diff - 1.96 * se, xmax = diff + 1.96 * se),
                  position = position_dodge(0.4)) +
  labs(title = "Headline contrast: what con_int changes once state capacity is matched",
       x = "ATT(step 3) - ATT(step 2), 95% bootstrap CI", y = NULL, colour = NULL) +
  theme_minimal(base_size = 11) + theme(legend.position = "bottom")
ggsave(file.path(fig_dir, "F3_headline_contrast.png"), f3, width = 9, height = 4.5, dpi = 200)


# =============================================================================
# Part 10: Robustness hooks (plan section 8; change a setting and rerun)
# =============================================================================
# Appendix 2024 : Sys.setenv(APPENDIX_2024 = "TRUE") and rerun
# Outcomes      : Sys.setenv(OUTCOME = "IM_t" / "change_IM_post" / "change_IM")
# Threshold     : THRESHOLD <- 0.75 or 0.5

saveRDS(list(panel = panel, main = res_main,
             att = att_main, contrasts = con_main, balance = bal_main,
             lib_delib = lib_delib_tab, regressions = reg_tab,
             settings = list(DATA_FILE = DATA_FILE, OUTCOME = OUTCOME,
                             APPENDIX_2024 = APPENDIX_2024, THRESHOLD = THRESHOLD,
                             TREAT_SCALE = TREAT_SCALE, SC_VARS = SC_VARS,
                             GDP_SOURCE = GDP_SOURCE,
                             B_BOOT = B_BOOT)),
        file.path(out_dir, "results.rds"))
cat("Done. Outputs in", out_dir, "\n")
