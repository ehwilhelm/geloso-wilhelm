# =============================================================================
# 2) Analysis.R   (rewritten 2026-05-08 per Vincent Notes + Analysis 5.8.2026)
#
# Purpose: Estimate the Average Treatment Effect on the Treated (ATT) of large,
#          sustained changes in economic freedom (EFW) on the change in infant
#          mortality rate (IMR), with and without controlling for data quality.
#
#   Paper title: "Infant Mortality, Liberalizations and Interventionism:
#                 A Causal Analysis Accounting for Data Quality"
#
# Key changes vs. the prior version (now archived in Code/Archive/):
#   - Outcome is ONLY change_IM (con_int and rp are no longer outcomes;
#     they are now data-quality COVARIATES — Vincent does not want CI width
#     used as a dependent variable in this paper)
#   - Rank-based treatments (EFWrankjump, EFWrankdrop) are scrapped
#   - 8-test framework (jump/drop x DQ-control on/off x control-group filter)
#   - Each test is run twice: once using lag_con_int as the DQ proxy,
#     once using lag_rp -- 2 separate RDS slices feed 2 Quarto documents
#
# Methodology (unchanged from prior version):
#   - Three matching estimators: PSM NN3, PSM Kernel, Mahalanobis NN3 (BA)
#   - 200-rep bootstrap SEs (seed 12345) for the two PSM specs
#   - Caliper = 0.25 SDs of the propensity score (Austin 2011)
#
# Run from project root (where EFW_IM_Code.Rproj lives).
# =============================================================================


# =============================================================================
# Part 0: Packages
# =============================================================================

library(dplyr)
library(tidyr)
library(Matching)   # PSM and Mahalanobis matching (loads MASS as a dep)
library(boot)       # bootstrap SEs
library(knitr)
library(kableExtra)
library(ggplot2)


# =============================================================================
# Part 1: Source the import / merge script
# =============================================================================

source("C:/Users/ehwil/OneDrive/Desktop/Geloso Collab/geloso-wilhelm/Code/1) Import_Merge.R")


# =============================================================================
# Part 2: Construct outcome and data-quality variables + lagEFW
# =============================================================================

# Coerce PSM lag covariates to numeric (readxl falls back to character on
# mixed Excel columns; glm() and mean() require numeric).
psm_lag_vars <- c("laghc", "laglngdppc", "laggdpc_5growth", "laglngdppc2",
                  "lagfertilrate", "lagoldagedep", "lagpolity2", "lagurbanpop")
alldata <- alldata %>%
  mutate(across(all_of(psm_lag_vars), ~ suppressWarnings(as.numeric(.))))

# Build outcomes, data-quality proxies, and their lagged levels.
# 5-year first differences (lag(., 1) = one quinquennial period).
alldata <- alldata %>%
  group_by(country) %>%
  arrange(year) %>%
  mutate(
    # Lagged EFW summary score (PSM covariate)
    lagEFW = lag(Summary, 1),

    # Data-quality proxies (LEVELS)
    con_int = IM_upper_bound - IM_lower_bound,                 # CI width
    rp      = (con_int / 2) / infantmortality,                  # relative precision

    # Outcome: 5-year change in IMR
    change_IM = infantmortality - lag(infantmortality, 1),

    # Lagged levels (PS-model covariates)
    lag_IM      = lag(infantmortality, 1),
    lag_con_int = lag(con_int,         1),
    lag_rp      = lag(rp,              1)
  ) %>%
  ungroup()


# =============================================================================
# Part 3: Treatment episode tables  (jump and drop only -- rank scrapped)
# =============================================================================

make_period <- function(yr) paste0(yr - 5, "-", yr)

tbl_EFWjump <- alldata %>%
  filter(EFWjump == 1) %>%
  transmute(Country = country, Period = make_period(year),
            `EFW Change` = round(EFWdiff, 3)) %>%
  arrange(desc(`EFW Change`))

tbl_EFWdrop <- alldata %>%
  filter(EFWdrop == 1) %>%
  transmute(Country = country, Period = make_period(year),
            `EFW Change` = round(EFWdiff, 3)) %>%
  arrange(`EFW Change`)

cat("\n=== Treatment Episode Counts ===\n")
cat(sprintf("EFWjump (score  up  >= +1.0) : %d episodes\n", nrow(tbl_EFWjump)))
cat(sprintf("EFWdrop (score down <= -1.0) : %d episodes\n", nrow(tbl_EFWdrop)))


# =============================================================================
# Part 4: Summary statistics
# =============================================================================

sumstat_vars <- c("infantmortality", "con_int", "rp",
                  "EFWdiff",
                  "lagEFW", "lag_IM", "lag_con_int", "lag_rp",
                  "laghc", "laglngdppc", "laggdpc_5growth",
                  "lagfertilrate", "lagoldagedep", "lagpolity2", "lagurbanpop")

sumstats <- alldata %>%
  dplyr::select(dplyr::all_of(sumstat_vars)) %>%
  summarise(across(everything(),
                   list(Mean = ~mean(., na.rm = TRUE),
                        SD   = ~sd(.,   na.rm = TRUE),
                        Min  = ~min(.,  na.rm = TRUE),
                        Max  = ~max(.,  na.rm = TRUE)),
                   .names = "{.col}__{.fn}")) %>%
  pivot_longer(everything(),
               names_to  = c("Variable", ".value"),
               names_sep = "__") %>%
  mutate(across(where(is.numeric), ~round(., 3)))


# =============================================================================
# Part 5: PSM helper functions  (extended for the 8-test framework)
#
#   New parameters compared with the prior version:
#     dq_covar         -- character; if non-NULL, the data-quality proxy column
#                         (lag_con_int or lag_rp) added to the PS covariate set
#     control_filter   -- character; if non-NULL, drop observations from the
#                         control pool (treatment == 0) where this column == 1.
#                         Used to remove deliberalizers (EFWdrop == 1) from
#                         the control group when treatment is EFWjump, and
#                         vice versa. Treated units are never dropped.
# =============================================================================

# Base lag covariates -- always included (same set as Results_DecileGrowth5yr.R)
base_covars <- c("lagEFW", "laghc", "laglngdppc", "laggdpc_5growth",
                 "laglngdppc2", "lagfertilrate", "lagoldagedep",
                 "lagpolity2", "lagurbanpop")

psm_caliper <- 0.25   # standard deviations of propensity score

# -----------------------------------------------------------------------------
# ps_covars() -- build the covariate vector for a given test
# -----------------------------------------------------------------------------
ps_covars <- function(lag_outcome, dq_covar = NULL) {
  c(base_covars, lag_outcome, dq_covar)
}

# -----------------------------------------------------------------------------
# apply_control_filter() -- drop "opposite-direction" events from controls
#   Removes ROWS where treatment == 0 AND control_filter == 1.
#   Leaves treated rows (treatment == 1) untouched.
# -----------------------------------------------------------------------------
apply_control_filter <- function(data, treatment, control_filter) {
  if (is.null(control_filter)) return(data)
  drop_mask <- (data[[treatment]] %in% 0) & (data[[control_filter]] %in% 1)
  data[!drop_mask, , drop = FALSE]
}

# -----------------------------------------------------------------------------
# complete_data() -- listwise deletion + control-pool filtering
# -----------------------------------------------------------------------------
complete_data <- function(data, treatment, outcome, lag_outcome,
                          dq_covar = NULL, control_filter = NULL) {
  data <- as.data.frame(data)
  data <- apply_control_filter(data, treatment, control_filter)
  vars <- c(treatment, outcome, ps_covars(lag_outcome, dq_covar))
  data[complete.cases(data[, vars]), ]
}

# -----------------------------------------------------------------------------
# run_psm_nn3() -- logit PS, 3 NN, caliper = 0.25 SDs
# -----------------------------------------------------------------------------
run_psm_nn3 <- function(data, treatment, outcome, lag_outcome,
                        dq_covar = NULL, control_filter = NULL) {
  df   <- complete_data(data, treatment, outcome, lag_outcome,
                        dq_covar, control_filter)
  vars <- ps_covars(lag_outcome, dq_covar)
  ps_formula <- as.formula(paste(treatment, "~", paste(vars, collapse = " + ")))
  ps <- fitted(glm(ps_formula, data = df, family = binomial(link = "logit")))

  m_out <- Match(
    Y = df[[outcome]], Tr = df[[treatment]], X = ps,
    M = 3, estimand = "ATT", caliper = psm_caliper,
    CommonSupport = TRUE, replace = FALSE
  )
  list(match = m_out, ps_formula = ps_formula, df = df, vars = vars)
}

# -----------------------------------------------------------------------------
# run_psm_kernel() -- Epanechnikov kernel
# -----------------------------------------------------------------------------
run_psm_kernel <- function(data, treatment, outcome, lag_outcome,
                           dq_covar = NULL, control_filter = NULL) {
  df   <- complete_data(data, treatment, outcome, lag_outcome,
                        dq_covar, control_filter)
  vars <- ps_covars(lag_outcome, dq_covar)
  ps_formula <- as.formula(paste(treatment, "~", paste(vars, collapse = " + ")))
  ps <- fitted(glm(ps_formula, data = df, family = binomial(link = "logit")))

  m_out <- Match(
    Y = df[[outcome]], Tr = df[[treatment]], X = ps,
    M = 1, estimand = "ATT", caliper = psm_caliper,
    Weight = 2, CommonSupport = TRUE
  )
  list(match = m_out, ps_formula = ps_formula, df = df, vars = vars)
}

# -----------------------------------------------------------------------------
# run_mah_nn3() -- Mahalanobis NN3 with Abadie-Imbens bias adjustment
# -----------------------------------------------------------------------------
run_mah_nn3 <- function(data, treatment, outcome, lag_outcome,
                        dq_covar = NULL, control_filter = NULL) {
  df   <- complete_data(data, treatment, outcome, lag_outcome,
                        dq_covar, control_filter)
  vars <- ps_covars(lag_outcome, dq_covar)
  X    <- as.matrix(df[, vars])
  Match(
    Y = df[[outcome]], Tr = df[[treatment]], X = X,
    M = 3, estimand = "ATT",
    Weight = 2, BiasAdjust = TRUE, replace = TRUE
  )
}

# -----------------------------------------------------------------------------
# bootstrap_att() -- 200-rep bootstrap. Seed: 50826
# -----------------------------------------------------------------------------
bootstrap_att <- function(data, treatment, outcome, lag_outcome,
                          dq_covar = NULL, control_filter = NULL,
                          method = "nn3", B = 200) {
  df   <- complete_data(data, treatment, outcome, lag_outcome,
                        dq_covar, control_filter)
  vars <- ps_covars(lag_outcome, dq_covar)
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
              M = 3, estimand = "ATT", caliper = psm_caliper,
              CommonSupport = TRUE, replace = FALSE)
      } else {
        Match(Y = d_b[[outcome]], Tr = d_b[[treatment]], X = ps_b,
              M = 1, estimand = "ATT", caliper = psm_caliper,
              Weight = 2, CommonSupport = TRUE)
      }
    }, error = function(e) NULL)

    if (is.null(m_b)) NA_real_ else as.numeric(m_b$est)
  }

  set.seed(50826)
  boot(data = df, statistic = stat_fn, R = B)
}

# -----------------------------------------------------------------------------
# extract_row() -- clean results row, robust to NULL match objects and
#                  zero-length analytic SE (Match() with replace=FALSE)
# -----------------------------------------------------------------------------
extract_row <- function(est_label, m_obj, bstrap = NULL) {
  if (is.null(m_obj)) {
    return(data.frame(
      Estimator = est_label, N_treated = NA_integer_,
      ATT = NA_real_, SE = NA_real_, p_value = NA_real_,
      CI_lo = NA_real_, CI_hi = NA_real_, stringsAsFactors = FALSE))
  }
  att    <- as.numeric(m_obj$est)
  se_raw <- if (!is.null(bstrap)) sd(bstrap$t, na.rm = TRUE) else m_obj$se
  se     <- if (length(se_raw) == 0 || is.null(se_raw)) NA_real_
            else as.numeric(se_raw)
  n_tr   <- if (!is.null(m_obj$index.treated))
              length(unique(m_obj$index.treated)) else NA_integer_
  pval   <- if (is.na(se) || se == 0) NA_real_ else 2 * pnorm(-abs(att / se))
  ci_lo  <- if (is.na(se)) NA_real_ else att - 1.96 * se
  ci_hi  <- if (is.na(se)) NA_real_ else att + 1.96 * se
  data.frame(
    Estimator = est_label, N_treated = as.integer(n_tr),
    ATT = round(att, 4), SE = round(se, 4),
    p_value = round(pval, 4),
    CI_lo = round(ci_lo, 4), CI_hi = round(ci_hi, 4),
    stringsAsFactors = FALSE)
}


# =============================================================================
# Part 6: Run all 8 tests x 2 data-quality proxies
#
#   Test grid (per Analysis 5.8.2026.txt and Vincent Notes.pdf):
#     Test 1: jump, NO data-quality control
#     Test 2: jump, WITH data-quality control
#     Test 3: jump, NO DQ, deliberalizers (EFWdrop) removed from controls
#     Test 4: jump, WITH DQ, deliberalizers removed from controls
#     Test 5: drop, NO data-quality control
#     Test 6: drop, WITH data-quality control
#     Test 7: drop, NO DQ, liberalizers (EFWjump) removed from controls
#     Test 8: drop, WITH DQ, liberalizers removed from controls
#
#   Each test runs 3 estimators (NN3 + bootstrap, Kernel + bootstrap, Mah NN3).
#   Tests 1, 3, 5, 7 do NOT involve any DQ proxy and are computed once each;
#   Tests 2, 4, 6, 8 are computed twice -- once per proxy.
# =============================================================================

test_grid <- list(
  list(num = 1, label = "Test 1: 1pt jump, no DQ control",
       treatment = "EFWjump", control_filter = NULL,    use_dq = FALSE),
  list(num = 2, label = "Test 2: 1pt jump, with DQ control",
       treatment = "EFWjump", control_filter = NULL,    use_dq = TRUE),
  list(num = 3, label = "Test 3: 1pt jump, no DQ, deliberalizers removed",
       treatment = "EFWjump", control_filter = "EFWdrop", use_dq = FALSE),
  list(num = 4, label = "Test 4: 1pt jump, with DQ, deliberalizers removed",
       treatment = "EFWjump", control_filter = "EFWdrop", use_dq = TRUE),
  list(num = 5, label = "Test 5: 1pt drop, no DQ control",
       treatment = "EFWdrop", control_filter = NULL,    use_dq = FALSE),
  list(num = 6, label = "Test 6: 1pt drop, with DQ control",
       treatment = "EFWdrop", control_filter = NULL,    use_dq = TRUE),
  list(num = 7, label = "Test 7: 1pt drop, no DQ, liberalizers removed",
       treatment = "EFWdrop", control_filter = "EFWjump", use_dq = FALSE),
  list(num = 8, label = "Test 8: 1pt drop, with DQ, liberalizers removed",
       treatment = "EFWdrop", control_filter = "EFWjump", use_dq = TRUE)
)

# Run one test (a single (treatment, dq_covar, control_filter) combination)
# and return a data.frame with one row per estimator.
run_one_test <- function(tspec, dq_covar = NULL) {
  tvar <- tspec$treatment
  cf   <- tspec$control_filter

  # Pre-flight check: enough treated units after filtering?
  df_check  <- complete_data(alldata, tvar, "change_IM", "lag_IM",
                             dq_covar, cf)
  n_treated <- sum(df_check[[tvar]] == 1, na.rm = TRUE)
  if (n_treated < 5) {
    cat(sprintf("    %s: only %d treated -- skipping.\n",
                tspec$label, n_treated))
    return(NULL)
  }

  cat(sprintf("    %s\n", tspec$label))
  cat(sprintf("      Complete cases: %d  Treated: %d  Controls: %d  ",
              nrow(df_check), n_treated, nrow(df_check) - n_treated))
  if (!is.null(dq_covar))   cat(sprintf("DQ=%s  ", dq_covar))
  if (!is.null(cf))         cat(sprintf("CF=%s  ", cf))
  cat("\n")

  nn3_fit  <- tryCatch(run_psm_nn3   (alldata, tvar, "change_IM", "lag_IM",
                                      dq_covar, cf), error = function(e) NULL)
  boot_nn3 <- if (!is.null(nn3_fit))
    tryCatch(bootstrap_att(alldata, tvar, "change_IM", "lag_IM",
                           dq_covar, cf, method = "nn3", B = 200),
             error = function(e) NULL) else NULL

  kern_fit  <- tryCatch(run_psm_kernel(alldata, tvar, "change_IM", "lag_IM",
                                       dq_covar, cf), error = function(e) NULL)
  boot_kern <- if (!is.null(kern_fit))
    tryCatch(bootstrap_att(alldata, tvar, "change_IM", "lag_IM",
                           dq_covar, cf, method = "kernel", B = 200),
             error = function(e) NULL) else NULL

  mah_fit <- tryCatch(run_mah_nn3(alldata, tvar, "change_IM", "lag_IM",
                                  dq_covar, cf), error = function(e) NULL)

  bind_rows(
    extract_row("PSM NN3",              if (!is.null(nn3_fit))  nn3_fit$match  else NULL, boot_nn3),
    extract_row("PSM Kernel",           if (!is.null(kern_fit)) kern_fit$match else NULL, boot_kern),
    extract_row("Mahalanobis NN3 (BA)", mah_fit, NULL)
  )
}

# Storage:  results_by_proxy[[proxy]][[test_num]] -> data.frame
results_by_proxy <- list("con_int" = list(), "rp" = list())

cat("\n", strrep("=", 70), "\n", sep = "")
cat(" Running 8-test framework x 2 DQ proxies (con_int and rp)\n")
cat(strrep("=", 70), "\n", sep = "")

for (proxy in c("con_int", "rp")) {
  cat(sprintf("\n--- Data-quality proxy: %s ---\n", proxy))
  proxy_var <- if (proxy == "con_int") "lag_con_int" else "lag_rp"

  for (tspec in test_grid) {
    dq_covar <- if (tspec$use_dq) proxy_var else NULL
    res <- run_one_test(tspec, dq_covar)
    results_by_proxy[[proxy]][[as.character(tspec$num)]] <- res
  }
}


# =============================================================================
# Part 7: Balance and distribution plots (PSM NN3 specification)
#   For each of the 8 tests x each DQ proxy, produce a PS-density plot and a
#   Love plot. With 16 test x proxy combinations, this is 32 figures total.
# =============================================================================

fig_dir <- "Code/Figures"
if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE)

smd_fn <- function(x, treat) {
  x_t <- x[treat == 1]; x_c <- x[treat == 0]
  m_diff <- mean(x_t, na.rm = TRUE) - mean(x_c, na.rm = TRUE)
  s_pool <- sqrt((var(x_t, na.rm = TRUE) + var(x_c, na.rm = TRUE)) / 2)
  if (is.na(s_pool) || s_pool == 0) return(NA_real_)
  m_diff / s_pool
}

make_balance_plots <- function(fit, tlabel, tvar, lag_outcome,
                               dq_covar = NULL) {
  if (is.null(fit) || is.null(fit$match$index.treated)) return(NULL)

  df <- fit$df
  ps <- fitted(glm(fit$ps_formula, data = df, family = binomial(link = "logit")))
  df$PS <- ps
  df$Treatment <- factor(df[[tvar]], levels = c(0, 1),
                         labels = c("Control", "Treated"))

  treated_ix <- fit$match$index.treated
  control_ix <- fit$match$index.control
  matched_df <- rbind(df[treated_ix, , drop = FALSE],
                      df[control_ix, , drop = FALSE])
  matched_df$Treatment <- factor(
    c(rep(1L, length(treated_ix)), rep(0L, length(control_ix))),
    levels = c(0, 1), labels = c("Control", "Treated"))

  df$Stage         <- "Before matching"
  matched_df$Stage <- "After matching"
  ps_long <- rbind(df[, c("PS", "Treatment", "Stage")],
                   matched_df[, c("PS", "Treatment", "Stage")])
  ps_long$Stage <- factor(ps_long$Stage,
                          levels = c("Before matching", "After matching"))

  p_ps <- ggplot(ps_long, aes(x = PS, fill = Treatment)) +
    geom_density(alpha = 0.5) +
    facet_wrap(~ Stage, ncol = 2) +
    scale_fill_manual(values = c("Control" = "#377EB8", "Treated" = "#E41A1C")) +
    labs(title    = sprintf("Propensity-score distribution: %s", tlabel),
         x = "Propensity score", y = "Density") +
    theme_bw() +
    theme(plot.title = element_text(face = "bold"),
          legend.position = "bottom")

  covars     <- ps_covars(lag_outcome, dq_covar)
  smd_before <- vapply(covars, function(v) smd_fn(df[[v]], df[[tvar]]),
                       numeric(1))
  smd_after  <- vapply(covars,
                       function(v) smd_fn(matched_df[[v]],
                                          as.integer(matched_df$Treatment) - 1L),
                       numeric(1))
  love_df <- data.frame(
    Covariate = factor(rep(covars, 2), levels = rev(covars)),
    SMD       = c(smd_before, smd_after),
    Stage     = factor(rep(c("Before matching", "After matching"),
                           each = length(covars)),
                       levels = c("Before matching", "After matching"))
  )
  p_love <- ggplot(love_df, aes(x = SMD, y = Covariate,
                                color = Stage, shape = Stage)) +
    geom_vline(xintercept = 0,           color = "gray40") +
    geom_vline(xintercept = c(-0.1, 0.1),
               linetype = "dashed", color = "gray60") +
    geom_point(size = 3) +
    scale_color_manual(name = NULL,
                       values = c("Before matching" = "#E41A1C",
                                  "After matching"  = "#377EB8")) +
    scale_shape_manual(name = NULL,
                       values = c("Before matching" = 16,
                                  "After matching"  = 17)) +
    labs(title = sprintf("Covariate balance: %s", tlabel),
         subtitle = "|SMD| < 0.10 = well balanced",
         x = "Standardized mean difference (treated - control)", y = NULL) +
    theme_bw() +
    theme(plot.title = element_text(face = "bold"),
          legend.position = "bottom")

  list(ps_density = p_ps, love = p_love)
}

balance_plots <- list("con_int" = list(), "rp" = list())

for (proxy in c("con_int", "rp")) {
  proxy_var <- if (proxy == "con_int") "lag_con_int" else "lag_rp"

  for (tspec in test_grid) {
    dq_covar <- if (tspec$use_dq) proxy_var else NULL
    fit <- tryCatch(
      run_psm_nn3(alldata, tspec$treatment, "change_IM", "lag_IM",
                  dq_covar, tspec$control_filter),
      error = function(e) NULL)
    if (is.null(fit) || is.null(fit$match$index.treated)) next

    plots <- make_balance_plots(fit, tspec$label, tspec$treatment,
                                "lag_IM", dq_covar)
    if (is.null(plots)) next

    stub <- gsub("[^A-Za-z0-9]+", "_",
                 paste("Test", tspec$num, proxy, sep = "_"))
    ggsave(file.path(fig_dir, paste0(stub, "_PS_density.png")),
           plots$ps_density, width = 9, height = 4.5, dpi = 150)
    ggsave(file.path(fig_dir, paste0(stub, "_Love_plot.png")),
           plots$love, width = 7, height = 5, dpi = 150)

    balance_plots[[proxy]][[as.character(tspec$num)]] <- plots
  }
}


# =============================================================================
# Part 8: Save outputs for Quarto rendering
# =============================================================================

quarto_data <- list(
  alldata          = alldata,
  tbl_EFWjump      = tbl_EFWjump,
  tbl_EFWdrop      = tbl_EFWdrop,
  sumstats         = sumstats,
  results_by_proxy = results_by_proxy,
  balance_plots    = balance_plots,
  test_grid        = test_grid
)

saveRDS(quarto_data, "Code/analysis_results.rds")
cat("\nAll results saved to Code/analysis_results.rds\n")