# =============================================================================
# 2) Analysis.R
#
# Purpose: Estimate the Average Treatment Effect on the Treated (ATT) of large
#          changes in economic freedom (EFW) on infant mortality outcomes using
#          Propensity Score Matching (PSM) and Mahalanobis distance matching.
#
# Methodology draws from:
#   Callais & Young (2023) -- PSM on income decile growth
#   Grier (2025)           -- PSM on female employment and education
#
# Treatments (binary flags built in 1) Import_Merge.R):
#   EFWjump     -- EFW score rose    >= 1.0 point over 5 years
#   EFWdrop     -- EFW score fell    <= -1.0 point over 5 years
#   EFWrankjump -- EFW rank worsened >= 17 places (higher number = less free)
#   EFWrankdrop -- EFW rank improved >= 17 places (lower  number = more free)
#
#   Grouping per analysis instructions:
#     Group A: EFWjump + EFWrankdrop  (liberalisation: score up <-> rank down)
#     Group B: EFWdrop + EFWrankjump  (restriction:    score down <-> rank up)
#
# Outcomes (constructed below as 5-year first differences):
#   change_IM       -- change in infant mortality rate (per 1,000 live births)
#   change_con_int  -- change in CI width (IM_upper - IM_lower)
#   change_rp       -- change in relative precision = (con_int/2) / IM
#
# PSM covariates (lagged, pre-treatment; following Results_DecileGrowth5yr.R
# and Callais & Young 2023). All are already present in alldata after sourcing
# 1) Import_Merge.R, with the exception of lagEFW which is computed below.
#   lagEFW, laghc, laglngdppc, laggdpc_5growth, laglngdppc2,
#   lagfertilrate, lagoldagedep, lagpolity2, lagurbanpop,
#   plus the lagged outcome (specific to each regression)
#
# Estimators (per treatment x outcome):
#   1. PSM NN3 -- 3 nearest neighbors, logit PS, caliper = 0.05
#   2. PSM Kernel -- Epanechnikov kernel weights
#   3. Mahalanobis NN3 with Abadie-Imbens bias adjustment
#   Bootstrap SEs: 200 replications (seed 12345) for estimators 1 & 2
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
library(ggplot2)    # balance and distribution plots in Part 6.5


# =============================================================================
# Part 1: Source the import / merge script
#   This produces a single object `alldata` with ~220 columns:
#     - all original ALLDATA_NEW variables (incl. PSM lag covariates)
#     - all EFW variables (incl. ECONOMIC FREEDOM ALL AREAS = Summary, EFW RANK)
#     - constructed flags: EFWjump, EFWdrop, EFWrankjump, EFWrankdrop,
#                          EFWdiff, EFWrankdiff, EFW_smallerjump, EFW_biggerjump
# =============================================================================

source("C:/Users/ehwil/OneDrive/Desktop/Geloso Collab/geloso-wilhelm/Code/1) Import_Merge.R")


# =============================================================================
# Part 2: Construct outcome variables and lagEFW
#
# All PSM lag covariates already live in alldata. We add:
#   - lagEFW  = lag(Summary, 1)        (5-year lag in this quinquennial panel)
#   - outcome levels:  con_int, rp
#   - 5-year first differences: change_IM, change_con_int, change_rp
#   - lagged outcome levels: lag_IM, lag_con_int, lag_rp
#
# Note: alldata leaves 1) Import_Merge.R ungrouped (per the ungroup() at the
# end). We re-group here by country before applying lag/lead, then ungroup.
# =============================================================================

# -----------------------------------------------------------------------------
# Coerce PSM lag covariates to numeric.
# readxl falls back to character when an Excel column contains any mixed-type
# values (blanks, ".." sentinels, etc.) so several of the lag covariates arrive
# as character. Cast them to numeric with as.numeric(), which converts genuine
# non-numeric strings to NA. suppressWarnings() silences the expected
# "NAs introduced by coercion" notes. This must happen BEFORE summarise() and
# BEFORE glm() in the PSM step, both of which require numeric input.
# -----------------------------------------------------------------------------
psm_lag_vars <- c("laghc", "laglngdppc", "laggdpc_5growth", "laglngdppc2",
                  "lagfertilrate", "lagoldagedep", "lagpolity2", "lagurbanpop")

alldata <- alldata %>%
  mutate(across(all_of(psm_lag_vars), ~ suppressWarnings(as.numeric(.))))

# -----------------------------------------------------------------------------
# Construct lagEFW + outcome variables (5-year first differences and lags)
# -----------------------------------------------------------------------------
alldata <- alldata %>%
  group_by(country) %>%
  arrange(year) %>%
  mutate(
    # Lagged EFW summary score (PSM covariate)
    lagEFW = lag(Summary, 1),

    # Outcome levels
    con_int = IM_upper_bound - IM_lower_bound,
    rp      = (con_int / 2) / infantmortality,

    # 5-year first differences (outcomes for ATT estimation)
    change_IM      = infantmortality - lag(infantmortality, 1),
    change_con_int = con_int         - lag(con_int,         1),
    change_rp      = rp              - lag(rp,              1),

    # Lagged outcome levels (enter PS model as additional pre-treatment controls)
    lag_IM      = lag(infantmortality, 1),
    lag_con_int = lag(con_int,         1),
    lag_rp      = lag(rp,             1)
  ) %>%
  ungroup()


# =============================================================================
# Part 3: Treatment episode tables
#   Group A -- EFWjump + EFWrankdrop (liberalisation events)
#   Group B -- EFWdrop + EFWrankjump (restriction events)
#   Style: Grier (2025) Table 1 -- country, period, magnitude
# =============================================================================

# Helper: format the 5-year period from the end-year (1985 -> "1980-1985")
make_period <- function(yr) paste0(yr - 5, "-", yr)

# --- Group A: EFW Score Jump (score up = rank improved) ---

tbl_EFWjump <- alldata %>%
  filter(EFWjump == 1) %>%
  transmute(Country = country, Period = make_period(year),
            `EFW Change` = round(EFWdiff, 3)) %>%
  arrange(desc(`EFW Change`))

tbl_EFWrankdrop <- alldata %>%
  filter(EFWrankdrop == 1) %>%
  transmute(Country = country, Period = make_period(year),
            `Rank Change` = as.integer(EFWrankdiff)) %>%
  arrange(`Rank Change`)

# --- Group B: EFW Score Drop (score down = rank worsened) ---

tbl_EFWdrop <- alldata %>%
  filter(EFWdrop == 1) %>%
  transmute(Country = country, Period = make_period(year),
            `EFW Change` = round(EFWdiff, 3)) %>%
  arrange(`EFW Change`)

tbl_EFWrankjump <- alldata %>%
  filter(EFWrankjump == 1) %>%
  transmute(Country = country, Period = make_period(year),
            `Rank Change` = as.integer(EFWrankdiff)) %>%
  arrange(desc(`Rank Change`))

cat("\n=== Treatment Episode Counts ===\n")
cat(sprintf("EFWjump     (score  up  >= +1.0) : %d episodes\n", nrow(tbl_EFWjump)))
cat(sprintf("EFWrankdrop (rank  down >= -17)  : %d episodes\n", nrow(tbl_EFWrankdrop)))
cat(sprintf("EFWdrop     (score down <= -1.0) : %d episodes\n", nrow(tbl_EFWdrop)))
cat(sprintf("EFWrankjump (rank   up >= +17)   : %d episodes\n", nrow(tbl_EFWrankjump)))


# =============================================================================
# Part 4: Summary statistics
# =============================================================================

sumstat_vars <- c("infantmortality", "con_int", "rp",
                  "EFWdiff", "EFWrankdiff", "lagEFW",
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

cat("\n=== Summary Statistics ===\n")
print(as.data.frame(sumstats), row.names = FALSE)


# =============================================================================
# Part 5: PSM helper functions
#   Adapted from Results_DecileGrowth5yr.R. Parameterised by treatment,
#   outcome, and lag-outcome column names so the same functions work for all
#   four treatments and all three outcomes.
#
#   IMPORTANT: We use `data[, vars]` (base R) and `dplyr::select` (explicit
#   namespace) throughout to avoid clashes with MASS::select once Matching
#   loads MASS as a dependency.
# =============================================================================

# Pre-treatment lag covariates (same set as Results_DecileGrowth5yr.R)
base_covars <- c("lagEFW", "laghc", "laglngdppc", "laggdpc_5growth",
                 "laglngdppc2", "lagfertilrate", "lagoldagedep",
                 "lagpolity2", "lagurbanpop")

# -----------------------------------------------------------------------------
# complete_data() -- listwise deletion for treatment, outcome, and covariates
# -----------------------------------------------------------------------------
complete_data <- function(data, treatment, outcome, lag_outcome) {
  vars <- c(treatment, outcome, base_covars, lag_outcome)
  data <- as.data.frame(data)
  data[complete.cases(data[, vars]), ]
}

# -----------------------------------------------------------------------------
#   \/ CLAUDE CODE \/
#   Caliper note:
#   Matching::Match() interprets `caliper` as standard deviations of X, NOT
#   raw propensity-score units (this differs from Stata's psmatch2 which uses
#   the raw 0-1 PS scale). We therefore set caliper = 0.25 (SDs), close to
#   Austin (2011)'s recommended 0.20 SD on the logit-PS scale. The original
#   Stata code in Results_DecileGrowth5yr.do used caliper(0.05) on raw PS;
#   using 0.05 SD here would be ~10x tighter and would drop nearly all matches
#   given the typical PS spread observed (sd(PS) ~ 0.10 in this sample).
#   Also note: the older `normalize = FALSE` argument has been removed from
#   the Matching package and would now cause Match() to error.
#   
#   \/ EHW \/
#   Tested Matching::Match() function to set caliper (the yardstick for PSM) to 0.25 SDs
# -----------------------------------------------------------------------------
psm_caliper <- 0.25   # in standard deviations of the propensity score

# -----------------------------------------------------------------------------
# run_psm_nn3() -- logit PS, 3 nearest neighbors, caliper in SDs of PS
# -----------------------------------------------------------------------------
run_psm_nn3 <- function(data, treatment, outcome, lag_outcome) {
  df   <- complete_data(data, treatment, outcome, lag_outcome)
  vars <- c(base_covars, lag_outcome)
  ps_formula <- as.formula(paste(treatment, "~", paste(vars, collapse = " + ")))
  ps <- fitted(glm(ps_formula, data = df, family = binomial(link = "logit")))

  m_out <- Match(
    Y             = df[[outcome]],
    Tr            = df[[treatment]],
    X             = ps,
    M             = 3,        # 3 nearest neighbors
    estimand      = "ATT",
    caliper       = psm_caliper,
    CommonSupport = TRUE,
    replace       = FALSE
  )
  list(match = m_out, ps_formula = ps_formula, df = df, vars = vars)
}

# -----------------------------------------------------------------------------
# run_psm_kernel() -- Epanechnikov kernel
# -----------------------------------------------------------------------------
run_psm_kernel <- function(data, treatment, outcome, lag_outcome) {
  df   <- complete_data(data, treatment, outcome, lag_outcome)
  vars <- c(base_covars, lag_outcome)
  ps_formula <- as.formula(paste(treatment, "~", paste(vars, collapse = " + ")))
  ps <- fitted(glm(ps_formula, data = df, family = binomial(link = "logit")))

  m_out <- Match(
    Y             = df[[outcome]],
    Tr            = df[[treatment]],
    X             = ps,
    M             = 1,
    estimand      = "ATT",
    caliper       = psm_caliper,
    Weight        = 2,        # Weight = 2 in Matching::Match() = Epanechnikov kernel
    CommonSupport = TRUE
  )
  list(match = m_out, ps_formula = ps_formula, df = df, vars = vars)
}

# -----------------------------------------------------------------------------
# run_mah_nn3() -- Mahalanobis NN3 with Abadie-Imbens bias correction
#   Replicates Stata: teffects nnmatch ... nn(3) atet biasadj(...)
# -----------------------------------------------------------------------------
run_mah_nn3 <- function(data, treatment, outcome, lag_outcome) {
  df   <- complete_data(data, treatment, outcome, lag_outcome)
  vars <- c(base_covars, lag_outcome)
  X    <- as.matrix(df[, vars])

  Match(
    Y          = df[[outcome]],
    Tr         = df[[treatment]],
    X          = X,
    M          = 3,
    estimand   = "ATT",
    Weight     = 2,           # inverse-covariance distance = Mahalanobis
    BiasAdjust = TRUE,
    replace    = TRUE
  )
}

# -----------------------------------------------------------------------------
# bootstrap_att() -- 200-replication bootstrap of the ATT
#   Seed 50726 <- Seed used for this analysis
#############################################################################
#   Seed 12345 (<- Seed used by Callais & Young 2023 if want to replicate)  #
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

  set.seed(50726)
  boot(data = df, statistic = stat_fn, R = B)
}


# =============================================================================
# Part 6: Main analysis loop
#   Iterates over every (treatment x outcome) combination.
#   For each combination: PSM NN3 + bootstrap, PSM Kernel + bootstrap,
#   Mahalanobis NN3.
# =============================================================================

treatment_specs <- list(
  # Group A -- liberalisation
  list(label = "EFW Score Jump",  var = "EFWjump",
       desc = "EFW score increased >= 1.0 point (5-year change)"),
  list(label = "EFW Rank Drop",   var = "EFWrankdrop",
       desc = "EFW rank improved >= 17 places (lower rank = more free)"),
  # Group B -- restriction
  list(label = "EFW Score Drop",  var = "EFWdrop",
       desc = "EFW score decreased >= 1.0 point (5-year change)"),
  list(label = "EFW Rank Jump",   var = "EFWrankjump",
       desc = "EFW rank worsened >= 17 places (higher rank = less free)")
)

outcome_specs <- list(
  list(label = "Infant Mortality Rate",
       var = "change_IM",      lag = "lag_IM",
       note = "5-yr delta; negative values = improvement"),
  list(label = "CI Width (con_int)",
       var = "change_con_int", lag = "lag_con_int",
       note = "5-yr delta confidence interval width"),
  list(label = "Relative Precision (rp)",
       var = "change_rp",      lag = "lag_rp",
       note = "5-yr delta relative precision = (con_int/2) / IM")
)

all_results <- list()   # nested: all_results[[treatment]][[outcome]]

# Helper: extract a clean results row from a match object + optional bootstrap.
# Robust to:
#   - NULL match object              -> all NA row
#   - NULL or zero-length SE source  -> NA SE / p-value / CI (Match() with
#     replace=FALSE often returns numeric(0) for $se; bootstrap is preferred)
extract_row <- function(est_label, m_obj, bstrap = NULL) {
  if (is.null(m_obj)) {
    return(data.frame(
      Estimator = est_label, N_treated = NA_integer_,
      ATT = NA_real_, SE = NA_real_, p_value = NA_real_,
      CI_lo = NA_real_, CI_hi = NA_real_, stringsAsFactors = FALSE))
  }
  att <- as.numeric(m_obj$est)

  # Prefer bootstrap SE when available; otherwise fall back to analytic SE
  se_raw <- if (!is.null(bstrap)) sd(bstrap$t, na.rm = TRUE) else m_obj$se
  se     <- if (length(se_raw) == 0 || is.null(se_raw)) NA_real_ else as.numeric(se_raw)

  # Treated-on-common-support count: prefer length of unique matched treated
  n_tr <- if (!is.null(m_obj$index.treated)) {
    length(unique(m_obj$index.treated))
  } else {
    NA_integer_
  }

  pval  <- if (is.na(se) || se == 0) NA_real_ else 2 * pnorm(-abs(att / se))
  ci_lo <- if (is.na(se)) NA_real_ else att - 1.96 * se
  ci_hi <- if (is.na(se)) NA_real_ else att + 1.96 * se

  data.frame(
    Estimator = est_label, N_treated = as.integer(n_tr),
    ATT       = round(att,   4),
    SE        = round(se,    4),
    p_value   = round(pval,  4),
    CI_lo     = round(ci_lo, 4),
    CI_hi     = round(ci_hi, 4),
    stringsAsFactors = FALSE)
}

for (tspec in treatment_specs) {

  cat("\n", strrep("=", 65), "\n", sep = "")
  cat(" Treatment:", tspec$label, "\n")
  cat(strrep("=", 65), "\n", sep = "")

  tvar      <- tspec$var
  t_results <- list()

  for (ospec in outcome_specs) {

    ovar <- ospec$var
    lvar <- ospec$lag
    cat(sprintf("\n  Outcome: %s\n", ospec$label))

    # Treated count after complete-case filtering
    df_check  <- complete_data(alldata, tvar, ovar, lvar)
    n_treated <- sum(df_check[[tvar]] == 1, na.rm = TRUE)
    cat(sprintf("    Complete-case treated units: %d\n", n_treated))

    if (n_treated < 5) {
      cat("    Fewer than 5 treated units -- skipping.\n")
      t_results[[ospec$label]] <- NULL
      next
    }

    # --- Estimator 1: PSM NN3 + bootstrap ---
    nn3_fit  <- tryCatch(run_psm_nn3(alldata, tvar, ovar, lvar),  error = function(e) NULL)
    boot_nn3 <- if (!is.null(nn3_fit))
      tryCatch(bootstrap_att(alldata, tvar, ovar, lvar, method = "nn3", B = 200), error = function(e) NULL)
    else NULL

    # --- Estimator 2: PSM Kernel + bootstrap ---
    kern_fit  <- tryCatch(run_psm_kernel(alldata, tvar, ovar, lvar), error = function(e) NULL)
    boot_kern <- if (!is.null(kern_fit))
      tryCatch(bootstrap_att(alldata, tvar, ovar, lvar, method = "kernel", B = 200), error = function(e) NULL)
    else NULL

    # --- Estimator 3: Mahalanobis NN3 (bias-adjusted) ---
    mah_fit <- tryCatch(run_mah_nn3(alldata, tvar, ovar, lvar), error = function(e) NULL)

    # Collate results
    res <- bind_rows(
      extract_row("PSM NN3",              if (!is.null(nn3_fit))  nn3_fit$match  else NULL, boot_nn3),
      extract_row("PSM Kernel",           if (!is.null(kern_fit)) kern_fit$match else NULL, boot_kern),
      extract_row("Mahalanobis NN3 (BA)", mah_fit, NULL)
    )

    # Print summary to console
    for (i in seq_len(nrow(res))) {
      cat(sprintf("    %-26s ATT=%9.4f  SE=%7.4f  p=%5.3f\n",
                  res$Estimator[i], res$ATT[i], res$SE[i], res$p_value[i]))
    }

    t_results[[ospec$label]] <- res
  }

  all_results[[tspec$label]] <- t_results
}


# =============================================================================
# Part 6.5: Balance and distribution plots
#   For each treatment x outcome (change_IM and change_rp) to produce 
#   two diagnostic plots:
#
#     (a) Propensity-score density plot, before vs after matching.
#         Visual check of how well treated and control PS distributions
#         overlap once matching is applied.
#
#     (b) Love plot of standardized mean differences (SMDs) for every PSM
#         covariate, before vs after matching.
#         |SMD| < 0.10 is conventionally considered well-balanced (Austin 2011).
#         Vertical reference lines are drawn at 0 and ±0.10.
#
#   Both plots are based on the PSM NN3 fit (the primary specification).
#   Plots are saved as PNGs to Code/Figures/ AND stored in the RDS object so
#   the Quarto document can embed them inline.
# =============================================================================

# Create Figures directory
fig_dir <- "C:/Users/ehwil/OneDrive/Desktop/Geloso Collab/geloso-wilhelm/Code/Figures"
if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE)

# Restrict balance plots to the two outcomes requested in the brief
balance_outcome_labels <- c("Infant Mortality Rate", "Relative Precision (rp)")

# -----------------------------------------------------------------------------
# Helper: standardized mean difference for one variable across treatment groups
#   SMD = (mean_treated - mean_control) / pooled_SD
#   NA-safe: returns NA if pooled SD is 0 or undefined.
# -----------------------------------------------------------------------------
smd_fn <- function(x, treat) {
  x_t <- x[treat == 1]
  x_c <- x[treat == 0]
  m_diff <- mean(x_t, na.rm = TRUE) - mean(x_c, na.rm = TRUE)
  s_pool <- sqrt((var(x_t, na.rm = TRUE) + var(x_c, na.rm = TRUE)) / 2)
  if (is.na(s_pool) || s_pool == 0) return(NA_real_)
  m_diff / s_pool
}

# -----------------------------------------------------------------------------
# Helper: build a single balance figure (PS density) and Love plot for one
# treatment x outcome combination using the PSM NN3 match object.
# Returns a list with two ggplot objects: ps_density and love.
# -----------------------------------------------------------------------------
make_balance_plots <- function(fit, tlabel, olabel, tvar, lag_outcome) {
  if (is.null(fit) || is.null(fit$match$index.treated)) return(NULL)

  df <- fit$df

  # Recompute propensity score on the complete-case df
  ps <- fitted(glm(fit$ps_formula, data = df, family = binomial(link = "logit")))
  df$PS        <- ps
  df$Treatment <- factor(df[[tvar]], levels = c(0, 1),
                         labels = c("Control", "Treated"))

  # ---- Build the after-matching dataset using NN3 matched indices --------
  treated_ix <- fit$match$index.treated
  control_ix <- fit$match$index.control
  matched_df <- rbind(df[treated_ix, , drop = FALSE],
                      df[control_ix, , drop = FALSE])
  matched_df$Treatment <- factor(
    c(rep(1L, length(treated_ix)), rep(0L, length(control_ix))),
    levels = c(0, 1), labels = c("Control", "Treated")
  )

  # Combine for facet_wrap (Before vs After)
  df$Stage         <- "Before matching"
  matched_df$Stage <- "After matching"
  ps_long <- rbind(
    df[,         c("PS", "Treatment", "Stage")],
    matched_df[, c("PS", "Treatment", "Stage")]
  )
  ps_long$Stage <- factor(ps_long$Stage,
                          levels = c("Before matching", "After matching"))

  # ---- Plot (a): Propensity-score density, Before vs After --------------
  p_ps <- ggplot(ps_long, aes(x = PS, fill = Treatment)) +
    geom_density(alpha = 0.5) +
    facet_wrap(~ Stage, ncol = 2) +
    scale_fill_manual(values = c("Control" = "#377EB8", "Treated" = "#E41A1C")) +
    labs(title    = sprintf("Propensity-score distribution: %s", tlabel),
         subtitle = sprintf("Outcome: %s", olabel),
         x        = "Propensity score",
         y        = "Density") +
    theme_bw() +
    theme(plot.title    = element_text(face = "bold"),
          legend.position = "bottom")

  # ---- Plot (b): Love plot of SMDs ---------------------------------------
  covars     <- c(base_covars, lag_outcome)
  smd_before <- vapply(covars, function(v) smd_fn(df[[v]],         df[[tvar]]),
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
    labs(title    = sprintf("Covariate balance: %s", tlabel),
         subtitle = sprintf("Outcome: %s   |   |SMD| < 0.10 = well balanced",
                            olabel),
         x        = "Standardized mean difference (treated − control)",
         y        = NULL) +
    theme_bw() +
    theme(plot.title    = element_text(face = "bold"),
          legend.position = "bottom")

  list(ps_density = p_ps, love = p_love)
}

# -----------------------------------------------------------------------------
# Iterate over all 4 treatments x 2 balance-outcomes (8 combinations).
# Save plots to disk and stash in nested list for Quarto.
# -----------------------------------------------------------------------------
balance_plots <- list()

for (tspec in treatment_specs) {

  cat("\n  Generating balance plots for:", tspec$label, "\n")
  tvar <- tspec$var
  t_plots <- list()

  for (ospec in outcome_specs) {
    if (!(ospec$label %in% balance_outcome_labels)) next   # skip CI Width

    ovar <- ospec$var
    lvar <- ospec$lag

    fit <- tryCatch(run_psm_nn3(alldata, tvar, ovar, lvar),
                    error = function(e) NULL)
    if (is.null(fit) || is.null(fit$match$index.treated)) {
      cat(sprintf("    %s: NN3 match unavailable -- skipping plots.\n",
                  ospec$label))
      next
    }

    plots <- make_balance_plots(fit, tspec$label, ospec$label, tvar, lvar)
    if (is.null(plots)) next

    # File-name stub: replace spaces and parens with underscores
    stub <- gsub("[^A-Za-z0-9]+", "_",
                 paste(tspec$label, ospec$label, sep = "_"))

    ggsave(file.path(fig_dir, paste0(stub, "_PS_density.png")),
           plots$ps_density, width = 9,  height = 4.5, dpi = 150)
    ggsave(file.path(fig_dir, paste0(stub, "_Love_plot.png")),
           plots$love,        width = 7,  height = 5,   dpi = 150)

    t_plots[[ospec$label]] <- plots
    cat(sprintf("    %s: 2 figures written.\n", ospec$label))
  }

  balance_plots[[tspec$label]] <- t_plots
}

cat(sprintf("\nBalance figures saved to %s/\n", fig_dir))


# =============================================================================
# Part 7: Save objects for Quarto rendering
# =============================================================================

quarto_data <- list(
  alldata         = alldata,
  tbl_EFWjump     = tbl_EFWjump,
  tbl_EFWrankdrop = tbl_EFWrankdrop,
  tbl_EFWdrop     = tbl_EFWdrop,
  tbl_EFWrankjump = tbl_EFWrankjump,
  sumstats        = sumstats,
  all_results     = all_results,
  balance_plots   = balance_plots,   # nested list of ggplot objects
  treatment_specs = treatment_specs,
  outcome_specs   = outcome_specs
)

saveRDS(quarto_data, "C:/Users/ehwil/OneDrive/Desktop/Geloso Collab/geloso-wilhelm/Code/analysis_results.rds")
cat("\nAll results saved to C:/Users/ehwil/OneDrive/Desktop/Geloso Collab/geloso-wilhelm/Code/analysis_results.rds\n")