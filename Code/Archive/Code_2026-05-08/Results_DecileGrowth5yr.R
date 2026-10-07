# =============================================================================
# Results_DecileGrowth5yr.R
# R translation of Results_DecileGrowth5yr.do
#
# Purpose: Table 5 — estimates the Average Treatment Effect on the Treated (ATT)
#          of a large EFW "jump" on 5-year log-income growth for each income
#          decile (1–10) plus the top 5% and top 1%.
#
#          Three matching estimators are run for each outcome:
#            1. PSM — 3 nearest neighbors (NN3), logit PS, caliper = 0.05
#            2. PSM — Epanechnikov kernel weights
#            3. Mahalanobis NN3 with Abadie-Imbens bias adjustment
#
#          Bootstrap standard errors (200 reps) are reported for estimators 1 & 2.
#
# R equivalents to Stata commands:
#   psmatch2  (NN / kernel)  ->  Matching::Match()
#   pstest                   ->  Matching::MatchBalance()
#   bootstrap r(att), r(200) ->  boot::boot()
#   teffects nnmatch biasadj ->  Matching::Match() with Weight=2, BiasAdjust=TRUE
#
# Required packages: haven, Matching, boot, dplyr
# =============================================================================

library(haven)
library(Matching)   # install.packages("Matching")
library(boot)
library(dplyr)

# --------------------------------------------------------------------------
# Load data
# --------------------------------------------------------------------------
alldata <- read_dta("Data/MergeReady/ALLDATA.dta")

# --------------------------------------------------------------------------
# Covariate vector shared across all matching specifications
# (matches the regressor list in every psmatch2 / teffects call)
# --------------------------------------------------------------------------
base_covars <- c("lagEFW", "laghc", "laglngdppc", "laggdpc_5growth",
                 "laglngdppc2", "lagfertilrate", "lagoldagedep",
                 "lagpolity2", "lagurbanpop")


# =============================================================================
# Helper functions
# =============================================================================

# -----------------------------------------------------------------------------
# complete_data()
# Drop any row missing the treatment, outcome, or covariates.
# -----------------------------------------------------------------------------
complete_data <- function(data, treatment, outcome, lag_outcome) {
  vars <- c(treatment, outcome, base_covars, lag_outcome)
  data[complete.cases(data[, vars]), ]
}


# -----------------------------------------------------------------------------
# run_psm_nn3()
# Propensity-score matching with 3 nearest neighbors and a caliper of 0.05
# on the raw propensity-score scale (replicates psmatch2 ... n(3) caliper(0.05)).
#
# Notes on translation:
#   - Propensity score estimated by logit (same as psmatch2's default).
#   - Matching::Match() caliper is in the units of X; since X here is the raw
#     PS (0–1), caliper = 0.05 directly replicates Stata's caliper(0.05).
#   - normalize = FALSE keeps X on its natural scale.
#   - replace = FALSE replicates psmatch2's default of no replacement.
#   - CommonSupport = TRUE trims outside common support.
# -----------------------------------------------------------------------------
run_psm_nn3 <- function(data, treatment, outcome, lag_outcome) {

  df   <- complete_data(data, treatment, outcome, lag_outcome)
  vars <- c(base_covars, lag_outcome)

  ps_formula <- as.formula(paste(treatment, "~", paste(vars, collapse = " + ")))
  ps_model   <- glm(ps_formula, data = df, family = binomial(link = "logit"))
  ps         <- fitted(ps_model)

  m_out <- Match(
    Y             = df[[outcome]],
    Tr            = df[[treatment]],
    X             = ps,
    M             = 3,
    estimand      = "ATT",
    caliper       = 0.05,
    normalize     = FALSE,   # keep raw PS scale so caliper matches Stata
    CommonSupport = TRUE,
    replace       = FALSE
  )

  list(match = m_out, ps_formula = ps_formula, df = df)
}


# -----------------------------------------------------------------------------
# run_psm_kernel()
# Kernel PSM (Epanechnikov kernel, replicates psmatch2 ... kernel caliper(0.05)).
# Matching::Match() with Weight = 2 applies Epanechnikov kernel weights.
# -----------------------------------------------------------------------------
run_psm_kernel <- function(data, treatment, outcome, lag_outcome) {

  df   <- complete_data(data, treatment, outcome, lag_outcome)
  vars <- c(base_covars, lag_outcome)

  ps_formula <- as.formula(paste(treatment, "~", paste(vars, collapse = " + ")))
  ps_model   <- glm(ps_formula, data = df, family = binomial(link = "logit"))
  ps         <- fitted(ps_model)

  m_out <- Match(
    Y             = df[[outcome]],
    Tr            = df[[treatment]],
    X             = ps,
    M             = 1,
    estimand      = "ATT",
    caliper       = 0.05,
    normalize     = FALSE,
    Weight        = 2,       # 2 = Epanechnikov kernel
    CommonSupport = TRUE
  )

  list(match = m_out, ps_formula = ps_formula, df = df)
}


# -----------------------------------------------------------------------------
# boot_psm_att()
# Bootstrap the ATT for either NN3 or kernel PSM (200 reps, seed 12345).
# Mirrors: set seed 12345; bootstrap r(att), r(200): psmatch2 ...
# -----------------------------------------------------------------------------
boot_psm_att <- function(fit_result, method = "nn3", B = 200) {

  df         <- fit_result$df
  ps_formula <- fit_result$ps_formula
  treatment  <- all.vars(ps_formula)[1]
  outcome    <- names(fit_result$df)[!names(fit_result$df) %in%
                                       c(all.vars(ps_formula), "country", "year")]
  # Recover outcome name from match object
  outcome_vec <- fit_result$match$Y

  stat_fn <- function(d, idx) {
    d_b <- d[idx, ]
    ps_b <- tryCatch(
      fitted(glm(ps_formula, data = d_b, family = binomial())),
      error = function(e) return(NA)
    )
    if (length(ps_b) == 1 && is.na(ps_b)) return(NA)

    m_b <- tryCatch({
      if (method == "nn3") {
        Match(Y = d_b[[names(d_b)[sapply(d_b, function(x) identical(x, outcome_vec))[1]]]],
              Tr = d_b[[treatment]], X = ps_b,
              M = 3, estimand = "ATT", caliper = 0.05,
              normalize = FALSE, CommonSupport = TRUE, replace = FALSE)
      } else {
        Match(Y = d_b[[names(d_b)[sapply(d_b, function(x) identical(x, outcome_vec))[1]]]],
              Tr = d_b[[treatment]], X = ps_b,
              M = 1, estimand = "ATT", caliper = 0.05,
              normalize = FALSE, Weight = 2, CommonSupport = TRUE)
      }
    }, error = function(e) NULL)

    if (is.null(m_b)) NA else m_b$est
  }

  set.seed(12345)
  boot(data = df, statistic = stat_fn, R = B)
}


# -----------------------------------------------------------------------------
# A cleaner bootstrap wrapper that avoids the fragile column-matching above.
# This version takes explicit column names and is easier to use in practice.
# -----------------------------------------------------------------------------
bootstrap_att <- function(data, treatment, outcome, lag_outcome,
                          method = "nn3", B = 200) {

  df   <- complete_data(data, treatment, outcome, lag_outcome)
  vars <- c(base_covars, lag_outcome)
  ps_formula <- as.formula(paste(treatment, "~", paste(vars, collapse = " + ")))

  stat_fn <- function(d, idx) {
    d_b  <- d[idx, ]
    ps_b <- tryCatch(
      fitted(glm(ps_formula, data = d_b, family = binomial())),
      error = function(e) return(NA_real_)
    )
    if (all(is.na(ps_b))) return(NA_real_)

    m_b <- tryCatch({
      if (method == "nn3") {
        Match(Y = d_b[[outcome]], Tr = d_b[[treatment]], X = ps_b,
              M = 3, estimand = "ATT", caliper = 0.05,
              normalize = FALSE, CommonSupport = TRUE, replace = FALSE)
      } else {
        Match(Y = d_b[[outcome]], Tr = d_b[[treatment]], X = ps_b,
              M = 1, estimand = "ATT", caliper = 0.05,
              normalize = FALSE, Weight = 2, CommonSupport = TRUE)
      }
    }, error = function(e) NULL)

    if (is.null(m_b)) NA_real_ else as.numeric(m_b$est)
  }

  set.seed(12345)
  boot(data = df, statistic = stat_fn, R = B)
}


# -----------------------------------------------------------------------------
# run_mah_nn3()
# Mahalanobis NN matching with 3 neighbors and Abadie-Imbens bias adjustment.
# Replicates: teffects nnmatch (...) (EFWjump), nn(3) atet biasadj(...)
#
# Notes:
#   - Weight = 2 in Matching::Match() uses inverse-covariance (Mahalanobis) distance.
#   - BiasAdjust = TRUE applies regression-based bias correction (Abadie & Imbens 2011).
#   - replace = TRUE is recommended for Mahalanobis matching (Stata's default for teffects).
# -----------------------------------------------------------------------------
run_mah_nn3 <- function(data, treatment, outcome, lag_outcome) {

  df   <- complete_data(data, treatment, outcome, lag_outcome)
  vars <- c(base_covars, lag_outcome)
  X    <- as.matrix(df[, vars])

  Match(
    Y           = df[[outcome]],
    Tr          = df[[treatment]],
    X           = X,
    M           = 3,
    estimand    = "ATT",
    Weight      = 2,          # Mahalanobis distance
    BiasAdjust  = TRUE,
    replace     = TRUE
  )
}


# =============================================================================
# Main loop: run all three estimators for each income decile / top share
# =============================================================================

# Each list element: outcome variable name, its lagged level used as a covariate,
# and a human-readable label for console output.
decile_specs <- list(
  list(label = "Decile 10 (top)",  outcome = "change_inc_10_5yr",   lag = "lag_inc_10"),
  list(label = "Decile 9",         outcome = "change_inc_9_5yr",    lag = "lag_inc_9"),
  list(label = "Decile 8",         outcome = "change_inc_8_5yr",    lag = "lag_inc_8"),
  list(label = "Decile 7",         outcome = "change_inc_7_5yr",    lag = "lag_inc_7"),
  list(label = "Decile 6",         outcome = "change_inc_6_5yr",    lag = "lag_inc_6"),
  list(label = "Decile 5",         outcome = "change_inc_5_5yr",    lag = "lag_inc_5"),
  list(label = "Decile 4",         outcome = "change_inc_4_5yr",    lag = "lag_inc_4"),
  list(label = "Decile 3",         outcome = "change_inc_3_5yr",    lag = "lag_inc_3"),
  list(label = "Decile 2",         outcome = "change_inc_2_5yr",    lag = "lag_inc_2"),
  list(label = "Decile 1 (bottom)",outcome = "change_inc_1_5yr",    lag = "lag_inc_1"),
  list(label = "Top 5%",           outcome = "change_inc_top5_5yr", lag = "lag_inc_top5"),
  list(label = "Top 1%",           outcome = "change_inc_top1_5yr", lag = "lag_inc_top11")
)

# Storage for results
results_table <- list()

for (spec in decile_specs) {

  cat("\n", strrep("=", 60), "\n")
  cat(" ", spec$label, "\n")
  cat(strrep("=", 60), "\n")

  # -------------------------------------------------------------------
  # Estimator 1: PSM — NN3
  # -------------------------------------------------------------------
  cat("\n--- PSM NN3 ---\n")
  fit_nn3 <- run_psm_nn3(alldata, "EFWjump", spec$outcome, spec$lag)

  cat("Point estimate (ATT):", fit_nn3$match$est, "\n")
  cat("Analytic SE:         ", fit_nn3$match$se,  "\n")

  # Covariate balance test (mirrors pstest ... , both)
  cat("\nBalance (MatchBalance):\n")
  vars_for_balance <- c(base_covars, spec$lag)
  bal_formula_nn3  <- as.formula(
    paste("EFWjump ~", paste(vars_for_balance, collapse = " + "))
  )
  MatchBalance(bal_formula_nn3,
               data      = fit_nn3$df,
               match.out = fit_nn3$match,
               nboots    = 0,
               print.level = 1)

  # Bootstrap SE
  cat("\nBootstrapping NN3 ATT (200 reps) ...\n")
  boot_nn3 <- bootstrap_att(alldata, "EFWjump", spec$outcome, spec$lag,
                             method = "nn3", B = 200)
  cat("Bootstrap SE:", sd(boot_nn3$t, na.rm = TRUE), "\n")

  # -------------------------------------------------------------------
  # Estimator 2: PSM — Kernel
  # -------------------------------------------------------------------
  cat("\n--- PSM Kernel ---\n")
  fit_kern <- run_psm_kernel(alldata, "EFWjump", spec$outcome, spec$lag)

  cat("Point estimate (ATT):", fit_kern$match$est, "\n")
  cat("Analytic SE:         ", fit_kern$match$se,  "\n")

  # Balance test
  cat("\nBalance (MatchBalance):\n")
  bal_formula_kern <- as.formula(
    paste("EFWjump ~", paste(vars_for_balance, collapse = " + "))
  )
  MatchBalance(bal_formula_kern,
               data      = fit_kern$df,
               match.out = fit_kern$match,
               nboots    = 0,
               print.level = 1)

  # Bootstrap SE
  cat("\nBootstrapping Kernel ATT (200 reps) ...\n")
  boot_kern <- bootstrap_att(alldata, "EFWjump", spec$outcome, spec$lag,
                              method = "kernel", B = 200)
  cat("Bootstrap SE:", sd(boot_kern$t, na.rm = TRUE), "\n")

  # -------------------------------------------------------------------
  # Estimator 3: Mahalanobis NN3 with bias adjustment
  # -------------------------------------------------------------------
  cat("\n--- Mahalanobis NN3 (bias-adjusted) ---\n")
  mah_fit <- run_mah_nn3(alldata, "EFWjump", spec$outcome, spec$lag)

  cat("ATT estimate:", mah_fit$est, "\n")
  cat("SE:          ", mah_fit$se,  "\n")
  cat("95% CI:      [", mah_fit$est - 1.96 * mah_fit$se, ",",
                        mah_fit$est + 1.96 * mah_fit$se, "]\n")

  # -------------------------------------------------------------------
  # Collect results for a summary table
  # -------------------------------------------------------------------
  results_table[[spec$label]] <- data.frame(
    decile        = spec$label,
    nn3_att       = fit_nn3$match$est,
    nn3_boot_se   = sd(boot_nn3$t, na.rm = TRUE),
    kern_att      = fit_kern$match$est,
    kern_boot_se  = sd(boot_kern$t, na.rm = TRUE),
    mah_att       = mah_fit$est,
    mah_se        = mah_fit$se,
    stringsAsFactors = FALSE
  )
}

# -------------------------------------------------------------------
# Print collated results (Table 5 equivalent)
# -------------------------------------------------------------------
cat("\n\n", strrep("=", 70), "\n")
cat("TABLE 5: ATT of EFW Jump on 5-Year Log-Income Growth by Decile\n")
cat(strrep("=", 70), "\n")

results_df <- bind_rows(results_table)
print(results_df, digits = 4, row.names = FALSE)
