# =============================================================================
# 3) Revised Analysis (draft).R      DRAFT, 19 Nov 2026 - reads version16.csv
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
#   Specification sequence:
#     S1 Naive     : IMR level ~ EFW treatment, baseline covariates
#     S2 + SC      : + O'Reilly-Murphy state capacity c_comp (only; Eric,
#                    19 Nov: c_comp and pca_comp never in the same spec)
#     S3 Headline  : + con_int = IM_upper_bound - IM_lower_bound (data quality)
#     Relative precision (rp) is dropped from the analysis.
#   Sample         : headline 1970-2020 (last EFW window 2010-15, outcome
#                    2015-20). Appendix: extension to 2024 (APPENDIX_2024).
#
# Data notes for version16.csv:
#   - GDP per capita is the panel's `gdppc` column (Our World in Data, per
#     Eric 19 Nov); GDP_SOURCE = "rgdpe_pop" rebuilds it from PWT instead.
#     In version16 `gdppc` still equals rgdpe / pop exactly in every row.
#   - 5-yr GDP pc growth at 1970 needs 1965 GDP pc. If the panel has 1965
#     rows, they are read and used for that growth (and nothing else is
#     estimated on them), which brings the 1970-75 EFW windows back.
#   - PWT has no 2024 release yet: the 2024 rows carry 2023 PWT values.
#   - Polity5 ends in 2018; the 2018 value stands in for 2020 and later.
#   - The panel's lag* columns are not used; all lags are rebuilt here.
#
# Data: Datawork~Nishant is READ-ONLY. Nothing is written there.
# Outputs: Results/version16/ (tables/, figures/). October results untouched.
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
  file.path(root, "Datawork~Nishant", "version16.csv"))

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
GDP_SOURCE <- "gdppc"   # "gdppc" (panel column, OWID) | "rgdpe_pop" (PWT)
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
out_dir <- file.path(root, "Results", "version16", run_tag)
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
                "EFW", "EFW_rank", "gdppc", "rgdpe", "pop", "hc", "fertilrate",
                "oldagedep", "polity5", "urbanpop", SC_VARS)

panel <- raw %>%
  rename(EFW = `ECONOMIC FREEDOM ALL AREAS`, EFW_rank = `EFW RANK`) %>%
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
    gdppc_5growth = (lngdppc - lag(lngdppc)) * 5 / window,
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

# Median split for the two-by-two figure: EFW at the start of the window
# (t-5) above or below that year's cross-country median.
panel <- panel %>%
  group_by(year) %>%
  mutate(efw_half = if_else(lagEFW > median(lagEFW, na.rm = TRUE),
                            "EFW score above median", "EFW score below median")) %>%
  ungroup()

episodes <- panel %>%
  filter(EFWjump %in% 1 | EFWdrop %in% 1, !is.na(.data[[OUTCOME]])) %>%
  transmute(country, period = paste0(year - window, "-", year),
            type = if_else(EFWjump %in% 1, "Liberalization", "Deliberalization"),
            EFW_start = round(lagEFW, 2), EFW_change = round(EFWdiff, 2),
            pctile_rank_change = round(EFWrdiff, 3),
            efw_half)
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

att_nn3 <- function(df, treatment, ps, y = OUTCOME) {
  m <- tryCatch(Match(Y = df[[y]], Tr = df[[treatment]], X = ps, M = 3,
                      estimand = "ATT", caliper = psm_caliper, replace = TRUE,
                      CommonSupport = TRUE),
                error = function(e) NULL)
  if (!is.list(m) || length(m$est) == 0) return(list(att = NA_real_, m = NULL))
  list(att = as.numeric(m$est), m = m)
}

att_kernel <- function(df, treatment, ps, y = OUTCOME) {
  tr <- df[[treatment]] == 1
  yy <- df[[y]]
  ps_t <- ps[tr]; ps_c <- ps[!tr]; y_t <- yy[tr]; y_c <- yy[!tr]
  on_support <- ps_t >= min(ps_c) & ps_t <= max(ps_c)
  cf <- vapply(ps_t, function(p) {
    u <- (ps_c - p) / kernel_bw
    w <- ifelse(abs(u) < 1, 0.75 * (1 - u^2), 0)
    if (sum(w) == 0) NA_real_ else sum(w * y_c) / sum(w)
  }, numeric(1))
  keep <- on_support & !is.na(cf)
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
         kernel = att_kernel(df, treatment, ps, y)$att,
         mah = att_mah(df, treatment, cv, y))
  })
}

cluster_boot <- function(df, treatment, y = OUTCOME, B = B_BOOT) {
  countries <- unique(df$country)
  idx <- split(seq_len(nrow(df)), df$country)
  cols <- paste(rep(names(specs), each = 2), c("nn3", "kernel"), sep = ".")
  res <- matrix(NA_real_, B, length(cols), dimnames = list(NULL, cols))
  set.seed(SEED)
  for (b in seq_len(B)) {
    db <- df[unlist(idx[sample(countries, length(countries), TRUE)],
                    use.names = FALSE), ]
    if (sum(db[[treatment]] == 1) < 5) next
    for (s in names(specs)) {
      ps <- tryCatch(ps_fit(db, treatment, specs[[s]]), error = function(e) NULL)
      if (is.null(ps)) next
      res[b, paste0(s, ".nn3")]    <- att_nn3(db, treatment, ps, y)$att
      res[b, paste0(s, ".kernel")] <- att_kernel(db, treatment, ps, y)$att
    }
  }
  res
}

smd_matched <- function(x, m) {
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
             estimator = c("PSM NN3", "PSM Kernel", "Mahalanobis NN3 (BA)"),
             att = c(e$nn3, e$kernel, e$mah$att),
             se  = c(sd(r$boot[, paste0(s, ".nn3")], na.rm = TRUE),
                     sd(r$boot[, paste0(s, ".kernel")], na.rm = TRUE),
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
      do.call(rbind, lapply(c("nn3", "kernel"), function(est) {
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
# Part 8: Two-by-two diagnostic, liberalizers/deliberalizers x EFW half
# =============================================================================
# Rows: liberalizers (pair A) and deliberalizers (pair C). Columns: EFW at
# t-5 above or below that year's median. Treated and comparison countries are
# both drawn from the same half, and matching is redone within the half.
# Two versions of the figure:
#   F1  : "No DQ control" (S2: naive + state capacity) vs
#         "DQ control: con_int" (S3, headline)
#   F1b : "No state capacity control" (S1, naive) vs
#         "State capacity control" (S2); neither controls for data quality

halves <- c("EFW score above median", "EFW score below median")
grid_res <- list()
for (p in c("A", "C")) for (h in halves) {
  pr <- pairs[[p]]
  df <- test_sample(panel, pr$treatment, pr$control_filter)
  df <- df[df$efw_half == h, ]
  grid_res[[paste(p, h, sep = "|")]] <-
    run_pair(df, pr$treatment, OUTCOME, paste("Pair", p, "-", h))
}

grid_tab <- do.call(rbind, lapply(names(grid_res), function(k) {
  r <- grid_res[[k]]
  pp <- strsplit(k, "|", fixed = TRUE)[[1]]
  if (is.null(r)) {
    return(data.frame(pair = pp[1], half = pp[2], spec = NA, label = NA,
                      estimator = NA, att = NA, se = NA,
                      n_treated = sum(test_sample(panel, pairs[[pp[1]]]$treatment)$efw_half == pp[2] &
                                        test_sample(panel, pairs[[pp[1]]]$treatment)[[pairs[[pp[1]]]$treatment]] == 1),
                      n = NA))
  }
  cbind(pair = pp[1], half = pp[2],
        do.call(rbind, lapply(names(specs), function(s) att_rows(r, s))))
}))
write.csv(grid_tab, file.path(tab_dir, "T7_two_by_two_median_split.csv"),
          row.names = FALSE)

est_levels <- c("Mahalanobis NN3 (BA)", "PSM Kernel", "PSM NN3")

n_lab <- grid_tab %>% group_by(pair, half) %>%
  summarise(n_treated = first(n_treated), n = first(n), .groups = "drop") %>%
  mutate(row = factor(if_else(pair == "A", "Liberalizers", "Deliberalizers"),
                      levels = c("Liberalizers", "Deliberalizers")),
         half = factor(half, levels = halves),
         lab = paste0(n_treated, " treated", if_else(is.na(n), " (too few to match)",
                                                     paste0(", ", n, " obs"))))

# spec_map: named vector, spec code -> legend label (first = without the
# control, second = with it)
plot_grid <- function(spec_map, cols, note, file) {
  g <- grid_tab %>%
    filter(spec %in% names(spec_map)) %>%
    mutate(ctrl = factor(spec_map[spec], levels = spec_map),
           row = factor(if_else(pair == "A", "Liberalizers", "Deliberalizers"),
                        levels = c("Liberalizers", "Deliberalizers")),
           half = factor(half, levels = halves),
           estimator = factor(estimator, levels = est_levels),
           lo = att - 1.96 * se, hi = att + 1.96 * se)
  f <- ggplot(g, aes(x = att, y = estimator, colour = ctrl)) +
    geom_vline(xintercept = 0, colour = "grey30") +
    geom_errorbar(aes(xmin = lo, xmax = hi), width = 0, orientation = "y",
                  linewidth = 0.7, position = position_dodge(width = 0.55)) +
    geom_point(size = 2.6, position = position_dodge(width = 0.55)) +
    geom_text(data = n_lab, aes(x = Inf, y = Inf, label = lab), inherit.aes = FALSE,
              hjust = 1.05, vjust = 1.4, size = 3, colour = "grey35") +
    facet_grid(row ~ half, scales = "free_x") +
    scale_colour_manual(values = setNames(cols, spec_map), drop = FALSE) +
    labs(title = paste("Effect of", treat_text, "on the", out_lab$what),
         subtitle = paste0("ATT in deaths per 1,000 live births with 95% CI, ",
                           if (APPENDIX_2024) "1970-2024 (appendix)" else "1970-2020",
                           ". ", out_lab$sign, "\n",
                           note, " EFW halves split at each year's median EFW at t-5."),
         x = out_lab$axis, y = NULL, colour = NULL) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "bottom", strip.text = element_text(face = "bold"),
          plot.title = element_text(face = "bold"), panel.spacing = unit(1.2, "lines"))
  ggsave(file.path(fig_dir, file), f, width = 10, height = 7, dpi = 200)
  invisible(f)
}

sc_name <- paste(SC_VARS, collapse = ", ")
plot_grid(c(S2 = "No DQ control", S3 = "DQ control: con_int"),
          c("#2a6fdb", "#e8613a"),
          paste0("Both specifications control for state capacity (", sc_name, ")."),
          "F1_two_by_two_dq_median_split.png")
plot_grid(c(S1 = "No state capacity control",
            S2 = paste0("State capacity control: ", sc_name)),
          c("#8a8a8a", "#2a6fdb"),
          "Neither specification controls for data quality (con_int).",
          "F1b_two_by_two_sc_median_split.png")


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
ggsave(file.path(fig_dir, "F2_att_by_spec_step.png"), f2, width = 9, height = 9, dpi = 200)

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

saveRDS(list(panel = panel, main = res_main, grid = grid_res,
             att = att_main, contrasts = con_main, balance = bal_main,
             grid_tab = grid_tab, regressions = reg_tab,
             settings = list(DATA_FILE = DATA_FILE, OUTCOME = OUTCOME,
                             APPENDIX_2024 = APPENDIX_2024, THRESHOLD = THRESHOLD,
                             TREAT_SCALE = TREAT_SCALE, SC_VARS = SC_VARS,
                             GDP_SOURCE = GDP_SOURCE,
                             B_BOOT = B_BOOT)),
        file.path(out_dir, "results.rds"))
cat("Done. Outputs in", out_dir, "\n")
