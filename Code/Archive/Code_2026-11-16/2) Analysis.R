# =============================================================================
# 2) Analysis.R   (revised 2026-10-07 per Vincent Notes; May 2026 version is
#                  frozen in Code/Archive/Code_2026-05-08/)
#
# Paper: "Infant Mortality, Liberalizations and Interventionism:
#         A Causal Analysis Accounting for Data Quality"
#
# Question: how much does data quality hide (or exaggerate) the change in
#           infant mortality (IMR) that follows a large, sustained change in
#           economic freedom (EFW)?
#
# Design (Vincent Notes, 8 May 2026):
#   Outcome   : 5-year change in IMR (change_IM). The UN IGME interval is NOT
#               an outcome in this paper; it enters only as a control.
#   Treatments: EFWjump  (5-year EFW change >= +1, "liberalizer")
#               EFWdrop  (5-year EFW change <= -1, "deliberalizer")
#   DQ control: lagged UN IGME 90% interval width (lag_con_int, preferred) or
#               lagged relative precision (lag_rp), added to the matching
#               covariates.
#   Tests 1-8 : jump/drop x DQ control off/on x opposite-direction episodes
#               kept/removed from the control group (see test_grid below).
#
# What changed relative to the May 2026 version:
#   1. Reads merged.csv (built by the untouched "1) Import_Merge.R") from a
#      relative path, so the script runs on any machine.
#   2. Jump/drop flags are rebuilt here with Callais & Young's (2023) Stata
#      sequence (Merging.do lines 347-354). Stata's `replace` runs row by row,
#      so after blanking a jump that follows a jump, the FIRST jump of a
#      sustained reform survives. The May version blanked both episodes of a
#      back-to-back pair and so dropped every sustained reformer's first
#      episode. The Venezuela 2000 exclusion is also applied here: in
#      merged.csv the country is spelled "Venezuela, RB", so the May rule
#      (country == "Venezuela") never fired.
#   3. Tests 3/4/7/8 remove EVERY opposite-direction episode (raw EFW change
#      past -1/+1) from the control group, including episodes blanked by the
#      adjacency rule; the May filter only removed episodes that survived it.
#   4. Each test pair (1 vs 2, 3 vs 4, ...) is estimated on the SAME sample
#      (rows with a non-missing data-quality proxy), so the gap between them
#      is caused only by adding the control, not by losing observations.
#   5. "PSM Kernel" is now a real Epanechnikov kernel estimator (psmatch2
#      default bandwidth 0.06). Matching::Match(Weight = 2) is Mahalanobis
#      weighting, not a kernel, so the May "kernel" column was a second
#      nearest-neighbour estimate.
#   6. PSM NN3 matches WITH replacement, as psmatch2 does with n(3).
#   7. Bootstrap resamples whole countries (country-clustered, 200 reps) and
#      re-estimates the with- and without-DQ ATTs on the same draw, giving a
#      standard error for the headline quantity:
#          hidden gain = ATT(with DQ control) - ATT(without DQ control).
#
# Outputs (written to Results/):
#   Results/tables/*.csv     - episode lists, ATT tables, hidden-gain table,
#                              balance table
#   Results/figures/*.png    - figures used in the results write-up
#                              (also copied to docs/figures for the website)
#   Code/analysis_results.rds - everything the IM_Lib_Int Quarto files need
#
# Run from the repository root or from Code/ (the .Rproj folder).
# =============================================================================


# =============================================================================
# Part 0: Packages and paths
# =============================================================================

library(dplyr)
library(tidyr)
library(Matching)   # nearest-neighbour and Mahalanobis matching
library(ggplot2)

# Locate the repository root (the folder that holds Code/ and Data/)
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

# merged.csv is written by "1) Import_Merge.R" to its working directory.
# Look in the usual places; set MERGED_CSV to override.
merged_candidates <- c(Sys.getenv("MERGED_CSV"),
                       file.path(root, "Code", "merged.csv"),
                       file.path(root, "merged.csv"),
                       file.path(root, "Data", "merged.csv"))
merged_path <- merged_candidates[merged_candidates != "" &
                                 file.exists(merged_candidates)][1]
if (is.na(merged_path))
  stop("merged.csv not found. Run '1) Import_Merge.R' first or set MERGED_CSV.")

out_dir <- file.path(root, "Results")
tab_dir <- file.path(out_dir, "tables")
fig_dir <- file.path(out_dir, "figures")
dir.create(tab_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

B_BOOT      <- 200     # bootstrap replications
SEED        <- 50826   # same seed as the May version
psm_caliper <- 0.25    # NN3 caliper, in SDs of the propensity score
kernel_bw   <- 0.06    # Epanechnikov bandwidth (psmatch2 default)


# =============================================================================
# Part 1: Load data, rebuild treatments, outcome and data-quality variables
# =============================================================================

raw <- read.csv(merged_path, check.names = FALSE, stringsAsFactors = FALSE,
                encoding = "UTF-8")
cat(sprintf("Loaded %s: %d rows, years %d-%d\n", merged_path, nrow(raw),
            min(raw$year), max(raw$year)))

psm_lag_vars <- c("laghc", "laglngdppc", "laggdpc_5growth", "laglngdppc2",
                  "lagfertilrate", "lagoldagedep", "lagpolity2", "lagurbanpop")

# Callais & Young blanking, replicating Stata's sequential `replace`:
#   replace x = . if L5.x  == 1   (cascades: uses already-updated values)
#   replace x = . if L10.x == 1
#   replace x = . if F5.x  == 1
# Input is one country's flags in year order on a gap-free 5-year panel.
cy_blank <- function(x) {
  n <- length(x)
  if (n < 2) return(x)
  for (i in 2:n) if (x[i - 1] %in% 1) x[i] <- NA
  if (n >= 3) for (i in 3:n) if (x[i - 2] %in% 1) x[i] <- NA
  for (i in 1:(n - 1)) if (x[i + 1] %in% 1) x[i] <- NA
  x
}

alldata <- raw %>%
  mutate(across(all_of(psm_lag_vars), ~ suppressWarnings(as.numeric(.)))) %>%
  arrange(country, year) %>%
  group_by(country) %>%
  mutate(
    gap_ok   = is.na(lag(year)) | (year - lag(year)) == 5,
    EFWdiff  = Summary - lag(Summary, 1),
    # raw episodes (no adjacency blanking) - used for control-group filters
    lib_episode   = as.integer(EFWdiff >=  1),
    delib_episode = as.integer(EFWdiff <= -1),
    EFWjump = cy_blank(lib_episode),
    EFWdrop = cy_blank(delib_episode),
    EFWjump = if_else(country == "Venezuela, RB" & year == 2000,
                      NA_integer_, EFWjump),
    EFWdrop = if_else(country == "Venezuela, RB" & year == 2000,
                      NA_integer_, EFWdrop),
    # PSM covariate: lagged EFW level
    lagEFW = lag(Summary, 1),
    # Data-quality proxies (UN IGME 90% uncertainty interval)
    con_int = IM_upper_bound - IM_lower_bound,
    rp      = (con_int / 2) / infantmortality,
    # Outcome and its lag
    change_IM = infantmortality - lag(infantmortality, 1),
    lag_IM      = lag(infantmortality, 1),
    lag_con_int = lag(con_int, 1),
    lag_rp      = lag(rp, 1)
  ) %>%
  ungroup()
stopifnot(all(alldata$gap_ok))

# Countries that ever liberalized / deliberalized (country-level sensitivity)
ever <- alldata %>% group_by(country) %>%
  summarise(ever_lib   = as.integer(any(lib_episode   %in% 1)),
            ever_delib = as.integer(any(delib_episode %in% 1)), .groups = "drop")
alldata <- alldata %>% left_join(ever, by = "country")

# Comparison with the May flags carried in merged.csv
flag_compare <- data.frame(
  Flag = c("EFWjump", "EFWdrop"),
  May_2026 = c(sum(raw$EFWjump %in% 1), sum(raw$EFWdrop %in% 1)),
  Revised  = c(sum(alldata$EFWjump %in% 1), sum(alldata$EFWdrop %in% 1)))
print(flag_compare)


# =============================================================================
# Part 2: Episode tables and summary statistics
# =============================================================================

make_period <- function(yr) paste0(yr - 5, "-", yr)

tbl_EFWjump <- alldata %>% filter(EFWjump == 1) %>%
  transmute(Country = country, Period = make_period(year),
            `EFW Change` = round(EFWdiff, 2)) %>%
  arrange(desc(`EFW Change`))
tbl_EFWdrop <- alldata %>% filter(EFWdrop == 1) %>%
  transmute(Country = country, Period = make_period(year),
            `EFW Change` = round(EFWdiff, 2)) %>%
  arrange(`EFW Change`)
write.csv(tbl_EFWjump, file.path(tab_dir, "episodes_jump.csv"), row.names = FALSE)
write.csv(tbl_EFWdrop, file.path(tab_dir, "episodes_drop.csv"), row.names = FALSE)

base_covars <- c("lagEFW", "laghc", "laglngdppc", "laggdpc_5growth",
                 "laglngdppc2", "lagfertilrate", "lagoldagedep",
                 "lagpolity2", "lagurbanpop", "lag_IM")
dq_vars <- c(con_int = "lag_con_int", rp = "lag_rp")

# Analysis sample: every row usable by both the with- and without-DQ tests
analysis_ok <- complete.cases(alldata[, c("change_IM", base_covars, unname(dq_vars))])

sumstat_vars <- c("change_IM", "infantmortality", "con_int", "rp", "EFWdiff",
                  base_covars, unname(dq_vars))
sumstats <- alldata[analysis_ok, ] %>%
  dplyr::select(all_of(sumstat_vars)) %>%
  summarise(across(everything(),
                   list(Mean = ~mean(., na.rm = TRUE), SD = ~sd(., na.rm = TRUE),
                        Min  = ~min(., na.rm = TRUE),  Max = ~max(., na.rm = TRUE)),
                   .names = "{.col}__{.fn}")) %>%
  pivot_longer(everything(), names_to = c("Variable", ".value"), names_sep = "__") %>%
  mutate(across(where(is.numeric), ~ round(., 3)))
write.csv(sumstats, file.path(tab_dir, "summary_statistics.csv"), row.names = FALSE)


# =============================================================================
# Part 3: Estimators
# =============================================================================

# Build the sample for one test: treated + control rows, control filter
# applied to controls only, complete on every covariate any proxy needs.
test_sample <- function(data, treatment, control_filter = NULL) {
  df <- as.data.frame(data[analysis_ok, ])
  df <- df[!is.na(df[[treatment]]), ]
  if (!is.null(control_filter)) {
    drop <- df[[treatment]] == 0 & df[[control_filter]] %in% 1
    df <- df[!drop, ]
  }
  df
}

ps_fit <- function(df, treatment, covars) {
  f <- as.formula(paste(treatment, "~", paste(covars, collapse = " + ")))
  suppressWarnings(fitted(glm(f, data = df, family = binomial(link = "logit"))))
}

# PSM, 3 nearest neighbours on the logit propensity score, with replacement,
# caliper 0.25 SD, common support (psmatch2 n(3) common analogue)
att_nn3 <- function(df, treatment, covars, ps = NULL) {
  if (is.null(ps)) ps <- ps_fit(df, treatment, covars)
  m <- tryCatch(Match(Y = df$change_IM, Tr = df[[treatment]], X = ps, M = 3,
                      estimand = "ATT", caliper = psm_caliper, replace = TRUE,
                      CommonSupport = TRUE),
                error = function(e) NULL)
  if (is.null(m) || length(m$est) == 0) return(list(att = NA_real_, m = NULL))
  list(att = as.numeric(m$est), m = m)
}

# PSM, Epanechnikov kernel (psmatch2 kernel common, bandwidth 0.06)
att_kernel <- function(df, treatment, covars, ps = NULL) {
  if (is.null(ps)) ps <- ps_fit(df, treatment, covars)
  tr <- df[[treatment]] == 1
  y  <- df$change_IM
  ps_t <- ps[tr]; ps_c <- ps[!tr]; y_t <- y[tr]; y_c <- y[!tr]
  on_support <- ps_t >= min(ps_c) & ps_t <= max(ps_c)
  cf <- vapply(ps_t, function(p) {
    u <- (ps_c - p) / kernel_bw
    w <- ifelse(abs(u) < 1, 0.75 * (1 - u^2), 0)
    if (sum(w) == 0) NA_real_ else sum(w * y_c) / sum(w)
  }, numeric(1))
  keep <- on_support & !is.na(cf)
  list(att = mean(y_t[keep] - cf[keep]), n_treated = sum(keep))
}

# Mahalanobis NN3 with Abadie-Imbens bias adjustment and analytic SE
# (teffects nnmatch ... biasadj analogue)
att_mah <- function(df, treatment, covars) {
  m <- tryCatch(Match(Y = df$change_IM, Tr = df[[treatment]],
                      X = as.matrix(df[, covars]), M = 3, estimand = "ATT",
                      Weight = 2, BiasAdjust = TRUE, replace = TRUE),
                error = function(e) NULL)
  if (is.null(m)) return(list(att = NA_real_, se = NA_real_, n = NA_integer_))
  list(att = as.numeric(m$est), se = as.numeric(m$se),
       n = length(unique(m$index.treated)))
}

# Point estimates for every proxy setting ("none", "con_int", "rp") on one sample
spec_names <- c(none = "No DQ control", con_int = "DQ control: con_int",
                rp = "DQ control: rp")
covars_for <- function(spec) if (spec == "none") base_covars else
  c(base_covars, dq_vars[[spec]])

estimate_all <- function(df, treatment, with_mah = TRUE) {
  out <- list()
  for (s in names(spec_names)) {
    cv <- covars_for(s)
    ps <- ps_fit(df, treatment, cv)
    nn <- att_nn3(df, treatment, cv, ps)
    kn <- att_kernel(df, treatment, cv, ps)
    out[[s]] <- list(nn3 = nn$att, kernel = kn$att,
                     nn3_ntr = if (!is.null(nn$m)) length(unique(nn$m$index.treated)) else NA,
                     kernel_ntr = kn$n_treated, nn3_match = nn$m, ps = ps)
    if (with_mah) out[[s]]$mah <- att_mah(df, treatment, cv)
  }
  out
}

# Country-clustered bootstrap: resample countries with replacement, re-run
# NN3 and kernel for all three specs on the same draw.
cluster_boot <- function(df, treatment, B = B_BOOT) {
  countries <- unique(df$country)
  idx_by_c  <- split(seq_len(nrow(df)), df$country)
  set.seed(SEED)
  res <- matrix(NA_real_, B, 6,
                dimnames = list(NULL, paste(rep(names(spec_names), each = 2),
                                            c("nn3", "kernel"), sep = ".")))
  for (b in seq_len(B)) {
    draw <- sample(countries, length(countries), replace = TRUE)
    db <- df[unlist(idx_by_c[draw], use.names = FALSE), ]
    if (sum(db[[treatment]] == 1) < 5) next
    for (s in names(spec_names)) {
      cv <- covars_for(s)
      ps <- tryCatch(ps_fit(db, treatment, cv), error = function(e) NULL)
      if (is.null(ps)) next
      res[b, paste0(s, ".nn3")]    <- att_nn3(db, treatment, cv, ps)$att
      res[b, paste0(s, ".kernel")] <- att_kernel(db, treatment, cv, ps)$att
    }
  }
  res
}


# =============================================================================
# Part 4: Tests 1-8
#
#   Test 1: jump, no DQ control            Test 5: drop, no DQ control
#   Test 2: jump, DQ control               Test 6: drop, DQ control
#   Test 3: jump, no DQ, deliberalizers    Test 7: drop, no DQ, liberalizers
#           removed from control group             removed from control group
#   Test 4: jump, DQ, deliberalizers       Test 8: drop, DQ, liberalizers
#           removed                                removed
#
# Tests come in pairs that share a sample (1&2, 3&4, 5&6, 7&8). Each pair is
# estimated once with all three settings (no DQ / con_int / rp), so Tests
# 2, 4, 6, 8 have a con_int and an rp version, as in the May design.
# =============================================================================

test_grid <- list(
  list(num = 1, label = "Test 1: 1pt jump, no DQ control",
       treatment = "EFWjump", control_filter = NULL,            use_dq = FALSE, pair = "A"),
  list(num = 2, label = "Test 2: 1pt jump, with DQ control",
       treatment = "EFWjump", control_filter = NULL,            use_dq = TRUE,  pair = "A"),
  list(num = 3, label = "Test 3: 1pt jump, no DQ, deliberalizers removed",
       treatment = "EFWjump", control_filter = "delib_episode", use_dq = FALSE, pair = "B"),
  list(num = 4, label = "Test 4: 1pt jump, with DQ, deliberalizers removed",
       treatment = "EFWjump", control_filter = "delib_episode", use_dq = TRUE,  pair = "B"),
  list(num = 5, label = "Test 5: 1pt drop, no DQ control",
       treatment = "EFWdrop", control_filter = NULL,            use_dq = FALSE, pair = "C"),
  list(num = 6, label = "Test 6: 1pt drop, with DQ control",
       treatment = "EFWdrop", control_filter = NULL,            use_dq = TRUE,  pair = "C"),
  list(num = 7, label = "Test 7: 1pt drop, no DQ, liberalizers removed",
       treatment = "EFWdrop", control_filter = "lib_episode",   use_dq = FALSE, pair = "D"),
  list(num = 8, label = "Test 8: 1pt drop, with DQ, liberalizers removed",
       treatment = "EFWdrop", control_filter = "lib_episode",   use_dq = TRUE,  pair = "D")
)

pairs <- list(
  A = list(treatment = "EFWjump", control_filter = NULL,            tests = c(1, 2)),
  B = list(treatment = "EFWjump", control_filter = "delib_episode", tests = c(3, 4)),
  C = list(treatment = "EFWdrop", control_filter = NULL,            tests = c(5, 6)),
  D = list(treatment = "EFWdrop", control_filter = "lib_episode",   tests = c(7, 8)),
  # Country-level sensitivity: drop every country that EVER moved the other way
  B_country = list(treatment = "EFWjump", control_filter = "ever_delib", tests = c(3, 4)),
  D_country = list(treatment = "EFWdrop", control_filter = "ever_lib",   tests = c(7, 8))
)

pair_results <- list()
for (p in names(pairs)) {
  pr <- pairs[[p]]
  df <- test_sample(alldata, pr$treatment, pr$control_filter)
  cat(sprintf("\nPair %s (%s, filter = %s): %d rows, %d treated, %d controls\n",
              p, pr$treatment, ifelse(is.null(pr$control_filter), "none",
                                      pr$control_filter),
              nrow(df), sum(df[[pr$treatment]] == 1), sum(df[[pr$treatment]] == 0)))
  est  <- estimate_all(df, pr$treatment)
  boot <- cluster_boot(df, pr$treatment)
  pair_results[[p]] <- list(df = df, est = est, boot = boot,
                            n_obs = nrow(df), n_treated = sum(df[[pr$treatment]] == 1),
                            n_countries = length(unique(df$country)))
}

# ---- Tidy ATT table: one row per pair x spec x estimator -------------------
stars <- function(p) ifelse(is.na(p), "", ifelse(p < .01, "***",
                     ifelse(p < .05, "**", ifelse(p < .1, "*", ""))))

att_rows <- list()
for (p in names(pairs)) {
  r <- pair_results[[p]]
  for (s in names(spec_names)) {
    e <- r$est[[s]]
    for (k in c("nn3", "kernel")) {
      draws <- r$boot[, paste0(s, ".", k)]
      se <- sd(draws, na.rm = TRUE)
      att <- e[[k]]
      att_rows[[length(att_rows) + 1]] <- data.frame(
        pair = p, spec = s,
        estimator = c(nn3 = "PSM NN3", kernel = "PSM Kernel")[[k]],
        n_treated = c(nn3 = e$nn3_ntr, kernel = e$kernel_ntr)[[k]],
        att = att, se = se, p_value = 2 * pnorm(-abs(att / se)),
        boot_ok = sum(!is.na(draws)))
    }
    att_rows[[length(att_rows) + 1]] <- data.frame(
      pair = p, spec = s, estimator = "Mahalanobis NN3 (BA)",
      n_treated = e$mah$n, att = e$mah$att, se = e$mah$se,
      p_value = 2 * pnorm(-abs(e$mah$att / e$mah$se)), boot_ok = NA)
  }
}
att_table <- bind_rows(att_rows) %>%
  mutate(test = mapply(function(p, s) pairs[[p]]$tests[if (s == "none") 1 else 2],
                       pair, spec),
         ci_lo = att - 1.96 * se, ci_hi = att + 1.96 * se,
         stars = stars(p_value)) %>%
  dplyr::select(pair, test, spec, estimator, n_treated, att, se, ci_lo, ci_hi,
                p_value, stars, boot_ok)
write.csv(att_table %>% mutate(across(where(is.numeric), ~ round(., 4))),
          file.path(tab_dir, "att_all_tests.csv"), row.names = FALSE)

# ---- Hidden gain: ATT(with DQ) - ATT(no DQ), same sample, paired draws ----
hidden_rows <- list()
for (p in names(pairs)) {
  r <- pair_results[[p]]
  for (s in c("con_int", "rp")) {
    for (k in c("nn3", "kernel")) {
      d_draw <- r$boot[, paste0(s, ".", k)] - r$boot[, paste0("none.", k)]
      diff <- r$est[[s]][[k]] - r$est$none[[k]]
      se <- sd(d_draw, na.rm = TRUE)
      hidden_rows[[length(hidden_rows) + 1]] <- data.frame(
        pair = p, proxy = s,
        estimator = c(nn3 = "PSM NN3", kernel = "PSM Kernel")[[k]],
        att_no_dq = r$est$none[[k]], att_dq = r$est[[s]][[k]],
        hidden = diff, se = se,
        ci_lo = quantile(d_draw, .025, na.rm = TRUE),
        ci_hi = quantile(d_draw, .975, na.rm = TRUE),
        p_value = 2 * pnorm(-abs(diff / se)))
    }
    hidden_rows[[length(hidden_rows) + 1]] <- data.frame(
      pair = p, proxy = s, estimator = "Mahalanobis NN3 (BA)",
      att_no_dq = r$est$none$mah$att, att_dq = r$est[[s]]$mah$att,
      hidden = r$est[[s]]$mah$att - r$est$none$mah$att,
      se = NA, ci_lo = NA, ci_hi = NA, p_value = NA)
  }
}
hidden_table <- bind_rows(hidden_rows) %>%
  mutate(pct_change = 100 * hidden / abs(att_no_dq))
rownames(hidden_table) <- NULL
write.csv(hidden_table %>% mutate(across(where(is.numeric), ~ round(., 4))),
          file.path(tab_dir, "hidden_gain.csv"), row.names = FALSE)


# ---- Regression check: OLS with year fixed effects, country-clustered SE ---
# Same samples as Tests 1/2 and 5/6. Matching does not use the period, while
# IMR declines differ a lot by decade, so this shows the comparison holds once
# each episode is compared only with country-years from the same period.
library(sandwich); library(lmtest)
reg_rows <- list()
for (p in c("A", "C")) {
  df <- pair_results[[p]]$df; tr <- pairs[[p]]$treatment
  for (s in names(spec_names)) {
    f <- as.formula(paste("change_IM ~", tr, "+",
                          paste(covars_for(s), collapse = " + "), "+ factor(year)"))
    m  <- lm(f, data = df)
    ct <- coeftest(m, vcov = vcovCL(m, cluster = ~ country))[tr, ]
    reg_rows[[length(reg_rows) + 1]] <- data.frame(
      treatment = tr, spec = s, n = nobs(m), coef = ct[1], se = ct[2],
      p_value = ct[4])
  }
}
reg_table <- bind_rows(reg_rows); rownames(reg_table) <- NULL
write.csv(reg_table %>% mutate(across(where(is.numeric), ~ round(., 4))),
          file.path(tab_dir, "regression_check.csv"), row.names = FALSE)


# =============================================================================
# Part 5: Data-quality balance (the mechanism)
#   Standardized mean difference in lagged DQ between treated and controls:
#   before matching, after NN3 matching WITHOUT the DQ control, and after NN3
#   matching WITH it.
# =============================================================================

smd <- function(x_t, x_c) {
  s <- sqrt((var(x_t) + var(x_c)) / 2)
  if (is.na(s) || s == 0) NA_real_ else (mean(x_t) - mean(x_c)) / s
}
matched_smd <- function(df, m, v) {
  if (is.null(m)) return(NA_real_)
  smd(df[[v]][m$index.treated], df[[v]][m$index.control])
}

balance_rows <- list()
for (p in c("A", "B", "C", "D")) {
  r  <- pair_results[[p]]; df <- r$df; tr <- pairs[[p]]$treatment
  for (s in c("con_int", "rp")) {
    v <- dq_vars[[s]]
    balance_rows[[length(balance_rows) + 1]] <- data.frame(
      pair = p, proxy = s,
      stage = c("Before matching", "Matched without DQ control",
                "Matched with DQ control"),
      smd = c(smd(df[[v]][df[[tr]] == 1], df[[v]][df[[tr]] == 0]),
              matched_smd(df, r$est$none$nn3_match, v),
              matched_smd(df, r$est[[s]]$nn3_match, v)))
  }
}
balance_table <- bind_rows(balance_rows)
write.csv(balance_table %>% mutate(smd = round(smd, 3)),
          file.path(tab_dir, "dq_balance.csv"), row.names = FALSE)

# Full Love-plot balance (all covariates) for each test, NN3, for the Quarto
covar_balance <- function(df, tr, m, covars) {
  data.frame(
    Covariate = covars,
    before = sapply(covars, function(v) smd(df[[v]][df[[tr]] == 1], df[[v]][df[[tr]] == 0])),
    after  = sapply(covars, function(v) matched_smd(df, m, v)))
}


# =============================================================================
# Part 6: Figures
# =============================================================================

col_none <- "#2a78d6"; col_ci <- "#eb6834"; col_rp <- "#1baf7a"
ink <- "#0b0b0b"; ink2 <- "#52514e"; grid_col <- "#e4e3df"
theme_paper <- theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major = element_line(colour = grid_col, linewidth = 0.3),
        axis.text = element_text(colour = ink2), axis.title = element_text(colour = ink),
        plot.title = element_text(face = "bold", colour = ink),
        plot.subtitle = element_text(colour = ink2),
        strip.text = element_text(face = "bold", colour = ink, hjust = 0),
        legend.position = "bottom", legend.title = element_blank(),
        plot.title.position = "plot",
        plot.background = element_rect(fill = "white", colour = NA))

pair_lab <- c(A = "Liberalization (Tests 1-2)",
              B = "Liberalization, deliberalizers out of control group (Tests 3-4)",
              C = "Deliberalization (Tests 5-6)",
              D = "Deliberalization, liberalizers out of control group (Tests 7-8)")

# Figure 1: ATT by test, estimator and DQ setting
f1 <- att_table %>% filter(pair %in% c("A", "B", "C", "D")) %>%
  mutate(pair = factor(pair_lab[pair], levels = pair_lab),
         spec = factor(spec_names[spec], levels = spec_names),
         estimator = factor(estimator, levels = rev(c("PSM NN3", "PSM Kernel",
                                                      "Mahalanobis NN3 (BA)"))))
p1 <- ggplot(f1, aes(x = att, y = estimator, colour = spec)) +
  geom_vline(xintercept = 0, colour = ink2, linewidth = 0.4) +
  geom_errorbar(aes(xmin = ci_lo, xmax = ci_hi), width = 0, orientation = "y", linewidth = 0.6,
                 position = position_dodge(width = 0.6)) +
  geom_point(size = 2.4, position = position_dodge(width = 0.6)) +
  facet_wrap(~ pair, ncol = 1) +
  scale_colour_manual(values = c(col_none, col_ci, col_rp)) +
  labs(title = "Effect of a 1-point EFW change on 5-year IMR change",
       subtitle = "ATT in deaths per 1,000 live births with 95% CI.\nNegative = IMR fell faster than in matched controls.",
       x = "ATT (change in IMR, per 1,000)", y = NULL) +
  theme_paper
ggsave(file.path(fig_dir, "fig1_att_by_test.png"), p1, width = 8.5, height = 8, dpi = 200)

# Figure 2: hidden gain with bootstrap CI (NN3 and kernel)
f2 <- hidden_table %>% filter(pair %in% c("A", "B", "C", "D"),
                              estimator != "Mahalanobis NN3 (BA)") %>%
  mutate(pair = factor(pair_lab[pair], levels = rev(pair_lab)),
         estimator = factor(estimator, levels = c("PSM NN3", "PSM Kernel")),
         proxy = factor(spec_names[proxy], levels = spec_names[2:3]))
p2 <- ggplot(f2, aes(x = hidden, y = pair, colour = proxy)) +
  geom_vline(xintercept = 0, colour = ink2, linewidth = 0.4) +
  geom_errorbar(aes(xmin = ci_lo, xmax = ci_hi), width = 0, orientation = "y", linewidth = 0.6,
                 position = position_dodge(width = 0.5)) +
  geom_point(size = 2.4, position = position_dodge(width = 0.5)) +
  facet_wrap(~ estimator, nrow = 1) +
  scale_colour_manual(values = c(col_ci, col_rp)) +
  scale_y_discrete(labels = function(x) gsub(" \\(", "\n(", x)) +
  labs(title = "How much does the data-quality control move the ATT?",
       subtitle = "ATT with DQ control minus ATT without, same sample, 95% country-cluster bootstrap CI.\nFor liberalizations, negative = the control reveals a larger IMR decline (hidden gains).",
       x = "Change in ATT (per 1,000)", y = NULL) +
  theme_paper
ggsave(file.path(fig_dir, "fig2_hidden_gain.png"), p2, width = 9, height = 5, dpi = 200)

# Figure 3: DQ balance before/after matching
f3 <- balance_table %>%
  mutate(pair = factor(pair_lab[pair], levels = rev(pair_lab)),
         stage = factor(stage, levels = c("Before matching",
                                          "Matched without DQ control",
                                          "Matched with DQ control")),
         proxy = paste("Lagged", ifelse(proxy == "con_int",
                                        "interval width (con_int)",
                                        "relative precision (rp)")))
p3 <- ggplot(f3, aes(x = smd, y = pair, colour = stage, shape = stage)) +
  annotate("rect", xmin = -0.1, xmax = 0.1, ymin = -Inf, ymax = Inf,
           fill = "#f1f0ec") +
  geom_vline(xintercept = 0, colour = ink2, linewidth = 0.4) +
  geom_point(size = 2.8) +
  facet_wrap(~ proxy, nrow = 1) +
  scale_colour_manual(values = c("#52514e", col_none, col_ci)) +
  scale_shape_manual(values = c(16, 17, 15)) +
  scale_y_discrete(labels = function(x) gsub(" \\(", "\n(", x)) +
  labs(title = "Data quality of treated vs. control country-years",
       subtitle = "Standardized mean difference in lagged data quality, treated minus control.\nShaded band = |SMD| < 0.1. Positive = treated were measured less precisely.",
       x = "Standardized mean difference", y = NULL) +
  theme_paper
ggsave(file.path(fig_dir, "fig3_dq_balance.png"), p3, width = 9, height = 5, dpi = 200)

# Figure 4: how the two DQ proxies relate to the IMR level
f4 <- alldata[analysis_ok, ] %>%
  mutate(group = case_when(EFWjump %in% 1 ~ "Liberalization episode",
                           EFWdrop %in% 1 ~ "Deliberalization episode",
                           TRUE ~ "Other country-years"),
         group = factor(group, levels = c("Other country-years",
                                          "Liberalization episode",
                                          "Deliberalization episode"))) %>%
  dplyr::select(country, year, group, lag_IM, lag_con_int, lag_rp) %>%
  pivot_longer(c(lag_con_int, lag_rp), names_to = "proxy", values_to = "value") %>%
  mutate(proxy = ifelse(proxy == "lag_con_int",
                        "Interval width, con_int (per 1,000)",
                        "Relative precision, rp (half-width / IMR)"))
p4 <- ggplot(f4, aes(x = lag_IM, y = value)) +
  geom_point(data = ~ filter(.x, group == "Other country-years"),
             colour = "#c3c2b7", size = 1.1, alpha = 0.7) +
  geom_point(data = ~ filter(.x, group != "Other country-years"),
             aes(colour = group), size = 2, alpha = 0.95) +
  facet_wrap(~ proxy, nrow = 1, scales = "free_y") +
  scale_x_log10() + scale_y_log10() +
  scale_colour_manual(values = c(col_none, col_ci)) +
  labs(title = "Data quality and the level of infant mortality",
       subtitle = "Lagged values, log scales. Grey = country-years with no qualifying EFW change.",
       x = "Lagged IMR (per 1,000, log scale)", y = NULL) +
  theme_paper
ggsave(file.path(fig_dir, "fig4_dq_vs_imr.png"), p4, width = 9, height = 4.3, dpi = 200)

# Copy the figures to the website folder (docs/, published by GitHub Pages)
docs_fig_dir <- file.path(root, "docs", "figures")
dir.create(docs_fig_dir, recursive = TRUE, showWarnings = FALSE)
file.copy(list.files(fig_dir, pattern = "\\.png$", full.names = TRUE),
          docs_fig_dir, overwrite = TRUE)


# =============================================================================
# Part 7: Objects for the IM_Lib_Int Quarto documents
#   results_by_proxy[[proxy]][[test]] keeps the May layout (one data.frame per
#   test with Estimator, N_treated, ATT, SE, p_value, CI_lo, CI_hi).
# =============================================================================

to_test_df <- function(p, s) {
  att_table %>% filter(pair == p, spec == s) %>%
    transmute(Estimator = estimator, N_treated = as.integer(n_treated),
              ATT = round(att, 4), SE = round(se, 4), p_value = round(p_value, 4),
              CI_lo = round(ci_lo, 4), CI_hi = round(ci_hi, 4))
}
results_by_proxy <- list(con_int = list(), rp = list())
for (proxy in c("con_int", "rp")) {
  for (t in test_grid) {
    s <- if (t$use_dq) proxy else "none"
    results_by_proxy[[proxy]][[as.character(t$num)]] <- to_test_df(t$pair, s)
  }
}

saveRDS(list(
  alldata = alldata, tbl_EFWjump = tbl_EFWjump, tbl_EFWdrop = tbl_EFWdrop,
  sumstats = sumstats, results_by_proxy = results_by_proxy,
  att_table = att_table, hidden_table = hidden_table,
  balance_table = balance_table, reg_table = reg_table,
  flag_compare = flag_compare,
  pair_n = sapply(pair_results, function(r) c(obs = r$n_obs, treated = r$n_treated,
                                               countries = r$n_countries)),
  test_grid = test_grid, fig_dir = fig_dir
), file.path(root, "Code", "analysis_results.rds"))

cat("\nDone. Tables in Results/tables, figures in Results/figures,\n",
    "Quarto inputs in Code/analysis_results.rds\n")
