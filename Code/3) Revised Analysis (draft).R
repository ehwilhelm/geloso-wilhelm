# =============================================================================
# 3) Revised Analysis (draft).R          DRAFT, 16 Nov 2026 - NOT YET RUN
#
# Companion to "3) Revised Analysis Plan.md" (read that first).
#
# Paper: "Liberalizers Remember Dead Babies: Data Quality and Liberalization's
#         Effect on Infant Mortality" (Geloso & Wilhelm)
#
# What is new relative to "2) Analysis.R" (Oct 2026, Tests 1-8):
#   * Reads Nishant's revised panel (Datawork~Nishant/version9...) READ-ONLY.
#     Nothing is written back to that folder.
#   * Rebuilds every lag/change from levels on a complete country x 5-year
#     grid (the lag* columns in version9 are carried over from ALLDATA and
#     are not rebuilt for 2020; e.g. lagpolity2 is lagged polity2, not polity5).
#   * Adds an explicit STATE CAPACITY covariate (O'Reilly-Murphy Index of State
#     Capacity, with V-Dem fiscal capacity and Polity5 as alternatives).
#   * Separates STATISTICAL capacity from state capacity: the IGME interval is
#     purged of its mechanical dependence on the IMR level (and year), giving
#     a "residual data quality" measure, DQ_perp.
#   * Specification ladder S0-S5 (see plan) instead of on/off DQ, so the
#     headline contrast is ATT(S3) - ATT(S1): what data quality adds AFTER
#     state capacity is already balanced (the paper's "residual selection").
#
# Everything that depends on unfinished RA work is marked  # TODO(data).
# Outputs go to Results/revised_2026-11/ so the October results stay intact.
# =============================================================================


# =============================================================================
# Part 0: Settings
# =============================================================================

library(dplyr)
library(tidyr)
library(Matching)
library(ggplot2)

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
  file.path(root, "Datawork~Nishant", "version9_new_merge_dataset.csv"))

END_YEAR     <- 2020    # headline panel ends 2020 (see plan, section 5)
INCLUDE_2024 <- FALSE   # TRUE adds the 4-year 2020-2024 window (robustness)
THRESHOLD    <- 1       # EFW change defining a jump/drop (0.75, 0.5 robustness)

SC_VAR  <- "c_comp"     # headline state-capacity measure  # TODO(data): confirm
SC_ALTS <- c("v2stfisccap", "polity5")   # robustness swaps for SC_VAR

B_BOOT      <- 200
SEED        <- 50826
psm_caliper <- 0.25
kernel_bw   <- 0.06

out_dir <- file.path(root, "Results", "revised_2026-11")
tab_dir <- file.path(out_dir, "tables")
fig_dir <- file.path(out_dir, "figures")
dir.create(tab_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)


# =============================================================================
# Part 1: Load, put on a complete 5-year grid, rebuild lags from levels
# =============================================================================

raw <- read.csv(DATA_FILE, check.names = FALSE, stringsAsFactors = FALSE,
                encoding = "UTF-8")
cat(sprintf("Loaded %s: %d rows x %d cols, years %s\n", basename(DATA_FILE),
            nrow(raw), ncol(raw), paste(sort(unique(raw$year)), collapse = " ")))

level_vars <- c("infantmortality", "IM_lower_bound", "IM_upper_bound",
                "EFW", "hc", "lngdppc", "lngdppc2", "gdppc_5growth",
                "fertilrate", "oldagedep", "polity5", "urbanpop",
                SC_VAR, SC_ALTS)
level_vars <- unique(level_vars)

grid_years <- c(seq(1970, END_YEAR, 5), if (INCLUDE_2024) 2024)

panel <- raw %>%
  rename(EFW = `ECONOMIC FREEDOM ALL AREAS`) %>%
  filter(year %in% grid_years) %>%
  dplyr::select(country, year, all_of(level_vars)) %>%
  mutate(across(all_of(level_vars), ~ suppressWarnings(as.numeric(.)))) %>%
  # Complete grid: a country missing 2015 gets an all-NA 2015 row, so lag()
  # below is always "previous grid point", never a 10-year jump.
  complete(country, year = grid_years) %>%
  arrange(country, year) %>%
  group_by(country) %>%
  mutate(
    window  = year - lag(year),                  # 5, or 4 for 2020-2024
    scale5  = 5 / window,                        # puts 2020-24 on a 5-yr basis
    # Data-quality building blocks (UN IGME 90% interval)
    con_int = IM_upper_bound - IM_lower_bound,
    rp      = (con_int / 2) / infantmortality,
    # Outcome: 5-year change in IMR (deaths per 1,000)
    change_IM = (infantmortality - lag(infantmortality)) * scale5,
    # Treatment input (unscaled: a 1-point move in 4 years still counts)
    EFWdiff = EFW - lag(EFW),
    # Pre-treatment (t-5) covariates, rebuilt from levels
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
    lag_con_int     = lag(con_int),
    lag_rp          = lag(rp),
    # Placebo outcome: IMR change in the window BEFORE treatment
    pre_change_IM   = lag(change_IM)
  ) %>%
  ungroup()

# Lagged state-capacity measures, one column per candidate
for (v in unique(c(SC_VAR, SC_ALTS))) {
  panel <- panel %>% group_by(country) %>%
    mutate(!!paste0("lag_", v) := lag(.data[[v]])) %>% ungroup()
}
panel$lag_SC <- panel[[paste0("lag_", SC_VAR)]]

# TODO(data): 2020 and 2024 rows have no PWT/WDI covariates yet (hc, lngdppc,
# fertility, old-age dependency, urbanization). 2015-2020 episodes only need
# the 2015 values, which exist, so the headline panel to 2020 is usable now.
# 17 countries have no 2015 row at all (Bahamas, Belize, Burundi, CAR, Chad,
# Congo Rep., Fiji, Guinea-Bissau, Guyana, Haiti, Lebanon, Mauritania, Nepal,
# Nicaragua, Oman, Qatar, Yemen) and so drop from the 2010-15 and 2015-20
# windows until Nishant adds them.


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

panel <- panel %>%
  arrange(country, year) %>%
  group_by(country) %>%
  mutate(
    lib_episode   = as.integer(EFWdiff >=  THRESHOLD),
    delib_episode = as.integer(EFWdiff <= -THRESHOLD),
    EFWjump = cy_blank(lib_episode),
    EFWdrop = cy_blank(delib_episode),
    # Venezuela 2000 exclusion carried over from Callais & Young
    EFWjump = if_else(country == "Venezuela" & year == 2000, NA_integer_, EFWjump),
    EFWdrop = if_else(country == "Venezuela" & year == 2000, NA_integer_, EFWdrop)
  ) %>%
  ungroup()

episodes <- panel %>%
  filter(EFWjump %in% 1 | EFWdrop %in% 1) %>%
  transmute(country, period = paste0(year - window, "-", year),
            type = if_else(EFWjump %in% 1, "jump", "drop"),
            EFWdiff = round(EFWdiff, 2))
write.csv(episodes, file.path(tab_dir, "episodes.csv"), row.names = FALSE)
print(table(episodes$type, substr(episodes$period, 6, 9)))
# Expect almost no new episodes after 2010 (dry run on version9: 0 jumps and
# 1 drop of >= 1 point in 2015-2020). The extension mostly adds controls.


# =============================================================================
# Part 3: Separate statistical capacity from state capacity
#
#   ln(con_int) is ~88% explained by ln(IMR) and year in version9, so the raw
#   interval is mostly an IMR-level proxy. DQ_perp is what is left:
#     lag_dq_perp    : residual of ln(lag_con_int) on ln(lag_IM), its square,
#                      and year FE  (headline)
#     lag_dq_perp_sc : same, also partialling out lag_SC (robustness; shows
#                      how much of measurement quality state capacity explains)
#   Both are built from t-5 values only, so neither can respond to treatment.
# =============================================================================

resid_na <- function(formula, data) {
  fit <- lm(formula, data = data, na.action = na.exclude)
  as.numeric(residuals(fit))
}

panel <- panel %>%
  mutate(ln_lag_IM  = log(lag_IM),
         ln_lag_con = log(lag_con_int),
         yearf      = factor(year))

panel$lag_dq_perp <- resid_na(
  ln_lag_con ~ ln_lag_IM + I(ln_lag_IM^2) + yearf, panel)
panel$lag_dq_perp_sc <- resid_na(
  ln_lag_con ~ ln_lag_IM + I(ln_lag_IM^2) + yearf + lag_SC, panel)

# Diagnostic D2: how entangled are state and statistical capacity?
dq_sc_cor <- panel %>%
  dplyr::select(ln_lag_IM, ln_lag_con, lag_rp, lag_dq_perp, lag_SC,
                lagpolity5, starts_with("lag_v2"), laglngdppc) %>%
  cor(use = "pairwise.complete.obs") %>% round(2)
write.csv(dq_sc_cor, file.path(tab_dir, "D2_dq_sc_correlations.csv"))

r2 <- function(f) summary(lm(f, data = panel))$r.squared
dq_r2 <- data.frame(
  model = c("ln con_int ~ ln IMR + ln IMR^2 + year",
            "  ... + state capacity",
            "  ... + state capacity + ln GDP pc + Polity5"),
  R2 = c(r2(ln_lag_con ~ ln_lag_IM + I(ln_lag_IM^2) + yearf),
         r2(ln_lag_con ~ ln_lag_IM + I(ln_lag_IM^2) + yearf + lag_SC),
         r2(ln_lag_con ~ ln_lag_IM + I(ln_lag_IM^2) + yearf + lag_SC +
              laglngdppc + lagpolity5)))
write.csv(dq_r2, file.path(tab_dir, "D2_dq_variance_decomposition.csv"),
          row.names = FALSE)
print(dq_r2)


# =============================================================================
# Part 4: Specification ladder
# =============================================================================

base_covars <- c("lagEFW", "laghc", "laglngdppc", "laggdpc_5growth",
                 "laglngdppc2", "lagfertilrate", "lagoldagedep",
                 "lagpolity5", "lagurbanpop", "lag_IM")

specs <- list(
  S0 = base_covars,                                       # = Oct Test 1/3/5/7
  S1 = c(base_covars, "lag_SC"),                          # + state capacity
  S2 = c(base_covars, "lag_con_int"),                     # = Oct Test 2/4/6/8
  S3 = c(base_covars, "lag_SC", "lag_dq_perp"),           # HEADLINE
  S4 = c(base_covars, "lag_dq_perp"),                     # DQ without SC
  S5 = c(base_covars, "lag_SC", "lag_rp")                 # alt DQ measure
)
spec_labels <- c(
  S0 = "Baseline (C&Y + lagged IMR)",
  S1 = "+ state capacity",
  S2 = "+ raw interval width (Oct design)",
  S3 = "+ state capacity + residual DQ (headline)",
  S4 = "+ residual DQ only",
  S5 = "+ state capacity + relative precision")

# Contrasts reported with bootstrap SEs (same draws for both terms)
contrasts <- list(
  sc_increment       = c("S1", "S0"),  # what balancing state capacity does
  dq_beyond_sc       = c("S3", "S1"),  # HEADLINE: residual selection on DQ
  dq_total           = c("S3", "S0"),
  dq_without_sc      = c("S4", "S0"),
  oct_replication    = c("S2", "S0"))

all_covars <- unique(unlist(specs))


# =============================================================================
# Part 5: Estimators (copied from "2) Analysis.R" so this file stands alone)
# =============================================================================

ps_fit <- function(df, treatment, covars) {
  f <- as.formula(paste(treatment, "~", paste(covars, collapse = " + ")))
  suppressWarnings(fitted(glm(f, data = df, family = binomial(link = "logit"))))
}

att_nn3 <- function(df, treatment, covars, ps = NULL) {
  if (is.null(ps)) ps <- ps_fit(df, treatment, covars)
  m <- tryCatch(Match(Y = df$change_IM, Tr = df[[treatment]], X = ps, M = 3,
                      estimand = "ATT", caliper = psm_caliper, replace = TRUE,
                      CommonSupport = TRUE),
                error = function(e) NULL)
  if (is.null(m) || length(m$est) == 0) return(list(att = NA_real_, m = NULL))
  list(att = as.numeric(m$est), m = m)
}

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

att_mah <- function(df, treatment, covars) {
  m <- tryCatch(Match(Y = df$change_IM, Tr = df[[treatment]],
                      X = as.matrix(df[, covars]), M = 3, estimand = "ATT",
                      Weight = 2, BiasAdjust = TRUE, replace = TRUE),
                error = function(e) NULL)
  if (is.null(m)) return(list(att = NA_real_, se = NA_real_))
  list(att = as.numeric(m$est), se = as.numeric(m$se))
}

# One common sample per pair: complete on the outcome and on EVERY covariate
# used by ANY spec, so differences between specs come from the covariates only.
test_sample <- function(data, treatment, control_filter = NULL) {
  ok <- complete.cases(as.data.frame(data)[, c("change_IM", all_covars)])
  df <- as.data.frame(data[ok, ])
  df <- df[!is.na(df[[treatment]]), ]
  if (!is.null(control_filter)) {
    drop <- df[[treatment]] == 0 & df[[control_filter]] %in% 1
    df <- df[!drop, ]
  }
  df
}

estimate_specs <- function(df, treatment) {
  lapply(specs, function(cv) {
    ps <- ps_fit(df, treatment, cv)
    list(nn3    = att_nn3(df, treatment, cv, ps)$att,
         kernel = att_kernel(df, treatment, cv, ps)$att,
         mah    = att_mah(df, treatment, cv))
  })
}

cluster_boot <- function(df, treatment, B = B_BOOT) {
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
      res[b, paste0(s, ".nn3")]    <- att_nn3(db, treatment, specs[[s]], ps)$att
      res[b, paste0(s, ".kernel")] <- att_kernel(db, treatment, specs[[s]], ps)$att
    }
  }
  res
}

# Standardized mean difference, treated vs (weighted) controls
smd <- function(x, tr, w = NULL) {
  if (is.null(w)) w <- rep(1, sum(!tr))
  mt <- mean(x[tr]); mc <- weighted.mean(x[!tr], w)
  (mt - mc) / sqrt((var(x[tr]) + var(x[!tr])) / 2)
}


# =============================================================================
# Part 6: Diagnostics before any ATT
# =============================================================================

# D1: coverage by year of everything the specs need
coverage <- panel %>% group_by(year) %>%
  summarise(across(all_of(c("change_IM", all_covars)), ~ sum(!is.na(.))),
            .groups = "drop")
write.csv(coverage, file.path(tab_dir, "D1_coverage_by_year.csv"), row.names = FALSE)

# D3: selection on state capacity and on residual DQ (case-study prediction P1:
# liberalizers are positively selected on state capacity)
selection <- lapply(c(jump = "EFWjump", drop = "EFWdrop"), function(tr) {
  df <- test_sample(panel, tr)
  f  <- as.formula(paste(tr, "~", paste(specs$S3, collapse = " + ")))
  co <- summary(glm(f, data = df, family = binomial))$coefficients
  co[c("lag_SC", "lag_dq_perp", "lagpolity5"), , drop = FALSE]
})
print(selection)
saveRDS(selection, file.path(tab_dir, "D3_selection_logit.rds"))


# =============================================================================
# Part 7: Tests (same four pairs as October), all specs, bootstrap contrasts
# =============================================================================

pairs <- list(
  A = list(treatment = "EFWjump", control_filter = NULL),            # Tests 1-2
  B = list(treatment = "EFWjump", control_filter = "delib_episode"), # Tests 3-4
  C = list(treatment = "EFWdrop", control_filter = NULL),            # Tests 5-6
  D = list(treatment = "EFWdrop", control_filter = "lib_episode"))   # Tests 7-8

results <- list()
for (p in names(pairs)) {
  pr <- pairs[[p]]
  df <- test_sample(panel, pr$treatment, pr$control_filter)
  cat(sprintf("Pair %s: %d rows, %d treated, %d countries\n", p, nrow(df),
              sum(df[[pr$treatment]] == 1), length(unique(df$country))))
  results[[p]] <- list(df = df, est = estimate_specs(df, pr$treatment),
                       boot = cluster_boot(df, pr$treatment))
}

# ATT table
att_tab <- do.call(rbind, lapply(names(results), function(p) {
  r <- results[[p]]
  do.call(rbind, lapply(names(specs), function(s) {
    e <- r$est[[s]]
    se_nn <- sd(r$boot[, paste0(s, ".nn3")], na.rm = TRUE)
    se_kn <- sd(r$boot[, paste0(s, ".kernel")], na.rm = TRUE)
    data.frame(pair = p, spec = s, label = spec_labels[[s]],
               estimator = c("PSM NN3", "PSM Kernel", "Mahalanobis NN3 (BA)"),
               att = c(e$nn3, e$kernel, e$mah$att),
               se  = c(se_nn, se_kn, e$mah$se))
  }))
}))
att_tab$p_value <- 2 * pnorm(-abs(att_tab$att / att_tab$se))
write.csv(att_tab, file.path(tab_dir, "att_by_spec.csv"), row.names = FALSE)

# Contrast table (bootstrap SE of the difference; PSM estimators only, since
# Mahalanobis SEs are analytic and not on common draws)
con_tab <- do.call(rbind, lapply(names(results), function(p) {
  r <- results[[p]]
  do.call(rbind, lapply(names(contrasts), function(k) {
    a <- contrasts[[k]][1]; b <- contrasts[[k]][2]
    do.call(rbind, lapply(c("nn3", "kernel"), function(est) {
      d_hat <- r$est[[a]][[est]] - r$est[[b]][[est]]
      d_bt  <- r$boot[, paste0(a, ".", est)] - r$boot[, paste0(b, ".", est)]
      data.frame(pair = p, contrast = k, estimator = est,
                 diff = d_hat, se = sd(d_bt, na.rm = TRUE),
                 share_of_baseline = d_hat / r$est[[b]][[est]])
    }))
  }))
}))
write.csv(con_tab, file.path(tab_dir, "contrasts.csv"), row.names = FALSE)

# Balance on SC and DQ, before matching and after NN3 matching on each spec
bal_tab <- do.call(rbind, lapply(names(results), function(p) {
  r <- results[[p]]; tr <- r$df[[pairs[[p]]$treatment]] == 1
  do.call(rbind, lapply(names(specs), function(s) {
    ps <- ps_fit(r$df, pairs[[p]]$treatment, specs[[s]])
    m  <- att_nn3(r$df, pairs[[p]]$treatment, specs[[s]], ps)$m
    sapply(c("lag_SC", "lag_dq_perp", "lag_con_int", "pre_change_IM"), function(v) {
      x <- r$df[[v]]
      after <- if (is.null(m)) NA_real_ else
        (weighted.mean(x[m$index.treated], m$weights) -
           weighted.mean(x[m$index.control], m$weights)) /
        sqrt((var(x[tr]) + var(x[!tr])) / 2)
      c(before = smd(x, tr), after = after)
    }) -> sm
    data.frame(pair = p, spec = s, variable = colnames(sm),
               smd_before = sm["before", ], smd_after = sm["after", ])
  }))
}))
write.csv(bal_tab, file.path(tab_dir, "balance_sc_dq.csv"), row.names = FALSE)


# =============================================================================
# Part 8: Robustness hooks (switch on one at a time; see plan section 7)
# =============================================================================
# R1  SC_VAR <- "v2stfisccap" / "polity5"            (alt state capacity)
# R2  THRESHOLD <- 0.75 or 0.5                         (more episodes)
# R3  INCLUDE_2024 <- TRUE                             (4-year last window)
# R4  outcome = pre_change_IM                          (placebo, should be ~0)
# R5  IGME vintage: rerun S0/S2 on the old ALLDATA IMR (merged.csv) vs version9
# R6  drop 1970-75 windows (most drops; widest intervals)
# R7  drop Hong Kong and Taiwan (no IGME interval) - already implied by the
#     common sample, but report it
# R8  WB Statistical Capacity Indicator as DQ for 2005-2020 windows only
#     TODO(data): SCI not yet in version9

saveRDS(list(panel = panel, results = results, att = att_tab,
             contrasts = con_tab, balance = bal_tab, settings = list(
               DATA_FILE = DATA_FILE, END_YEAR = END_YEAR,
               INCLUDE_2024 = INCLUDE_2024, THRESHOLD = THRESHOLD,
               SC_VAR = SC_VAR)),
        file.path(out_dir, "revised_results.rds"))
cat("Done. Outputs in", out_dir, "\n")
