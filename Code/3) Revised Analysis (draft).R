# =============================================================================
# 3) Revised Analysis (draft).R      DRAFT, revised 18 Nov 2026 - NOT YET RUN
#
# Companion to "3) Revised Analysis Plan.md" (read that first).
#
# Paper: "Liberalizers Remember Dead Babies: Data Quality and Liberalization's
#         Effect on Infant Mortality" (Geloso & Wilhelm)
#
# Headline (plan sections 2-3):
#   Outcome   : IMR LEVEL at the end of the 5-year window (OUTCOME = "IM_t").
#               The 5-year change (October outcome) is appendix check A1.
#   Treatment : EFW jump (+1) = liberalizer, EFW drop (-1) = deliberalizer,
#               Callais & Young adjacency blanking. Both directions, pairs A-D.
#   Matching  : PSM NN3, PSM kernel, Mahalanobis NN3 (bias-adjusted) on
#               t-5 covariates. Polity5 = regime type (covariate).
#   Headline  : S2 = baseline + O'Reilly-Murphy state capacity + con_int
#               (IGME interval width, data-quality proxy).
#               Headline contrast S2 - S1 = what data quality changes once
#               state capacity is balanced.
#
# Data: Nishant's panel in Datawork~Nishant is READ-ONLY. Nothing is written
# there. The panel is not final, so this script is a draft.
# Outputs go to Results/revised_2026-11/ (October results stay intact).
# Items that depend on unfinished RA work are marked  # TODO(data).
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
  file.path(root, "Datawork~Nishant", "version11_wdi_merge_dataset.csv"))

OUTCOME      <- "IM_t"     # headline: IMR level at t. Appendix A1: "change_IM"
END_YEAR     <- 2020       # headline panel ends 2020 (plan section 11, Q3)
INCLUDE_2024 <- FALSE      # TODO(data): needs 2020 GDP block
THRESHOLD    <- 1          # EFW points defining a jump/drop (R2: 0.75, 0.5)

SC_VAR   <- "c_comp"       # O'Reilly-Murphy ISC   # TODO(data): confirm codebook
SC_ALT   <- "v2stfisccap"  # R1 robustness swap
FERT_OPTION <- "F1"        # F1 keep | F2 drop | F3 lag t-10 | F4 residualized
                           # | F5 PSM only (not in Mahalanobis). Plan section 5.

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
# Part 1: Load, complete 5-year grid, rebuild lags from levels
# =============================================================================

raw <- read.csv(DATA_FILE, check.names = FALSE, stringsAsFactors = FALSE,
                encoding = "UTF-8")
cat(sprintf("Loaded %s: %d rows x %d cols\n", basename(DATA_FILE),
            nrow(raw), ncol(raw)))

level_vars <- unique(c("infantmortality", "IM_lower_bound", "IM_upper_bound",
                       "EFW", "hc", "lngdppc", "lngdppc2", "gdppc_5growth",
                       "fertilrate", "oldagedep", "polity5", "urbanpop",
                       SC_VAR, SC_ALT))

grid_years <- c(seq(1970, END_YEAR, 5), if (INCLUDE_2024) 2024)

panel <- raw %>%
  rename(EFW = `ECONOMIC FREEDOM ALL AREAS`) %>%
  filter(year %in% grid_years) %>%
  dplyr::select(country, year, all_of(level_vars)) %>%
  mutate(across(all_of(level_vars), ~ suppressWarnings(as.numeric(.)))) %>%
  # Complete grid: a country with no 2015 row gets an all-NA 2015 row, so
  # lag() is always the previous grid point, never a 10-year jump (Lebanon).
  complete(country, year = grid_years) %>%
  arrange(country, year) %>%
  group_by(country) %>%
  mutate(
    window  = year - lag(year),               # 5 (4 for 2020-2024)
    con_int = IM_upper_bound - IM_lower_bound,
    rp      = (con_int / 2) / infantmortality,
    # Outcomes
    IM_t      = infantmortality,                                   # headline
    change_IM = (infantmortality - lag(infantmortality)) * 5 / window, # A1
    # Treatment input
    EFWdiff = EFW - lag(EFW),
    # Covariates at t-5 (rebuilt here; the lag* columns in the RA file are
    # not updated)
    lagEFW          = lag(EFW),
    laghc           = lag(hc),
    laglngdppc      = lag(lngdppc),
    laglngdppc2     = lag(lngdppc2),
    laggdpc_5growth = lag(gdppc_5growth),
    lagfertilrate   = lag(fertilrate),
    lag2fertilrate  = lag(fertilrate, 2),    # F3: fertility at t-10
    lagoldagedep    = lag(oldagedep),
    lagpolity5      = lag(polity5),
    lagurbanpop     = lag(urbanpop),
    lag_IM          = lag(infantmortality),
    lag2_IM         = lag(infantmortality, 2),   # R4 placebo outcome (t-10)
    lag_con_int     = lag(con_int),
    lag_rp          = lag(rp),
    lag_SC          = lag(.data[[SC_VAR]]),
    lag_SC_alt      = lag(.data[[SC_ALT]])
  ) %>%
  ungroup()

# TODO(data): 17 countries have no 2015 row (see the 16 Nov data review notes);
# they drop from the 2010-15 and 2015-20 windows until Nishant adds them.


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
    EFWjump = if_else(country == "Venezuela" & year == 2000, NA_integer_, EFWjump),
    EFWdrop = if_else(country == "Venezuela" & year == 2000, NA_integer_, EFWdrop)
  ) %>%
  ungroup()

episodes <- panel %>%
  filter(EFWjump %in% 1 | EFWdrop %in% 1) %>%
  transmute(country, period = paste0(year - window, "-", year),
            type = if_else(EFWjump %in% 1, "Liberalization", "Deliberalization"),
            EFWdiff = round(EFWdiff, 2))
write.csv(episodes, file.path(tab_dir, "T1_episodes.csv"), row.names = FALSE)


# =============================================================================
# Part 3: Derived controls (residualized measures for robustness only)
# =============================================================================

resid_na <- function(formula, data) {
  as.numeric(residuals(lm(formula, data = data, na.action = na.exclude)))
}
panel <- panel %>% mutate(yearf = factor(year))

# S5: data quality with the IMR level stripped out
panel$lag_dq_perp <- resid_na(
  log(lag_con_int) ~ log(lag_IM) + I(log(lag_IM)^2) + yearf, panel)
# F4: fertility with lagged IMR stripped out
panel$lagfert_perp <- resid_na(
  lagfertilrate ~ log(lag_IM) + I(log(lag_IM)^2) + yearf, panel)


# =============================================================================
# Part 4: Covariates and specification ladder
# =============================================================================

fert_var <- switch(FERT_OPTION,
                   F1 = "lagfertilrate", F2 = NULL, F3 = "lag2fertilrate",
                   F4 = "lagfert_perp",  F5 = "lagfertilrate")

base_covars <- c("lagEFW", "laghc", "laglngdppc", "laggdpc_5growth",
                 "laglngdppc2", fert_var, "lagoldagedep", "lagpolity5",
                 "lagurbanpop", "lag_IM")

specs <- list(
  S0 = base_covars,
  S1 = c(base_covars, "lag_SC"),                     # "without DQ"
  S2 = c(base_covars, "lag_SC", "lag_con_int"),      # HEADLINE "with DQ"
  S3 = c(base_covars, "lag_con_int"),                # Oct Test 2 analogue
  S4 = c(base_covars, "lag_SC", "lag_rp"),           # alt DQ measure
  S5 = c(base_covars, "lag_SC", "lag_dq_perp"))      # DQ net of IMR level
spec_labels <- c(
  S0 = "Baseline",
  S1 = "+ state capacity",
  S2 = "+ state capacity + con_int (headline)",
  S3 = "+ con_int only",
  S4 = "+ state capacity + rp",
  S5 = "+ state capacity + residual DQ")

contrasts <- list(
  dq_given_sc = c("S2", "S1"),   # HEADLINE
  sc          = c("S1", "S0"),
  sc_and_dq   = c("S2", "S0"),
  dq_only     = c("S3", "S0"))

all_covars <- unique(unlist(specs))

# Mahalanobis covariates: under F5, fertility stays in the propensity model
# but leaves the Mahalanobis distance.
mah_covars <- function(cv) if (FERT_OPTION == "F5") setdiff(cv, "lagfertilrate") else cv


# =============================================================================
# Part 5: Estimators (from "2) Analysis.R", generalized to any outcome)
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
  if (is.null(m) || length(m$est) == 0) return(list(att = NA_real_, m = NULL))
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
  list(att = mean(y_t[keep] - cf[keep]), n_treated = sum(keep))
}

att_mah <- function(df, treatment, covars, y = OUTCOME) {
  m <- tryCatch(Match(Y = df[[y]], Tr = df[[treatment]],
                      X = as.matrix(df[, covars]), M = 3, estimand = "ATT",
                      Weight = 2, BiasAdjust = TRUE, replace = TRUE),
                error = function(e) NULL)
  if (is.null(m)) return(list(att = NA_real_, se = NA_real_, m = NULL))
  list(att = as.numeric(m$est), se = as.numeric(m$se), m = m)
}

# One common sample per pair (complete on the outcome, the appendix outcome
# and every covariate of every spec)
test_sample <- function(data, treatment, control_filter = NULL) {
  need <- c("IM_t", "change_IM", all_covars)
  ok <- complete.cases(as.data.frame(data)[, need])
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
         mah = att_mah(df, treatment, mah_covars(cv), y))
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
  # standardized mean difference after matching, using the treated SD
  (weighted.mean(x[m$index.treated], m$weights) -
     weighted.mean(x[m$index.control], m$weights)) / sd(x[unique(m$index.treated)])
}
smd_raw <- function(x, tr) (mean(x[tr]) - mean(x[!tr])) / sd(x[tr])


# =============================================================================
# Part 6: Diagnostics (D1-D3)
# =============================================================================

coverage <- panel %>% group_by(year) %>%
  summarise(across(all_of(c("IM_t", all_covars)), ~ sum(!is.na(.))),
            .groups = "drop")
write.csv(coverage, file.path(tab_dir, "D1_coverage_by_year.csv"), row.names = FALSE)

d2_vars <- c("lag_IM", "lag_con_int", "lag_rp", "lag_SC", "lagpolity5",
             "lagfertilrate", "laglngdppc", "laghc")
write.csv(round(cor(panel[, d2_vars], use = "pairwise.complete.obs"), 2),
          file.path(tab_dir, "D2_correlations.csv"))

# VIF of each covariate in the headline set (1 / (1 - R^2) on the others)
vif_tab <- {
  dfv <- test_sample(panel, "EFWjump")
  sapply(specs$S2, function(v) {
    others <- setdiff(specs$S2, v)
    r2 <- summary(lm(as.formula(paste(v, "~", paste(others, collapse = "+"))),
                     data = dfv))$r.squared
    1 / (1 - r2)
  })
}
write.csv(data.frame(variable = names(vif_tab), VIF = round(vif_tab, 2)),
          file.path(tab_dir, "D2_vif_headline.csv"), row.names = FALSE)

# D3: selection on state capacity and data quality
selection <- lapply(c(jump = "EFWjump", drop = "EFWdrop"), function(tr) {
  df <- test_sample(panel, tr)
  f  <- as.formula(paste(tr, "~", paste(specs$S2, collapse = " + ")))
  co <- summary(glm(f, data = df, family = binomial))$coefficients
  co[intersect(c("lag_SC", "lag_con_int", "lagpolity5", "lagfertilrate"),
               rownames(co)), , drop = FALSE]
})
print(selection)
saveRDS(selection, file.path(tab_dir, "D3_selection_logit.rds"))


# =============================================================================
# Part 7: Pairs A-D (Tests 1-8), all specs, contrasts, balance
# =============================================================================

pairs <- list(
  A = list(treatment = "EFWjump", control_filter = NULL),            # Tests 1-2
  B = list(treatment = "EFWjump", control_filter = "delib_episode"), # Tests 3-4
  C = list(treatment = "EFWdrop", control_filter = NULL),            # Tests 5-6
  D = list(treatment = "EFWdrop", control_filter = "lib_episode"))   # Tests 7-8

run_all <- function(y) {
  out <- list()
  for (p in names(pairs)) {
    pr <- pairs[[p]]
    df <- test_sample(panel, pr$treatment, pr$control_filter)
    cat(sprintf("[%s] Pair %s: %d rows, %d treated, %d countries\n", y, p,
                nrow(df), sum(df[[pr$treatment]] == 1), length(unique(df$country))))
    out[[p]] <- list(df = df, est = estimate_specs(df, pr$treatment, y),
                     boot = cluster_boot(df, pr$treatment, y))
  }
  out
}

att_table <- function(results) {
  tab <- do.call(rbind, lapply(names(results), function(p) {
    r <- results[[p]]
    do.call(rbind, lapply(names(specs), function(s) {
      e <- r$est[[s]]
      data.frame(pair = p, spec = s, label = spec_labels[[s]],
                 estimator = c("PSM NN3", "PSM Kernel", "Mahalanobis NN3 (BA)"),
                 att = c(e$nn3, e$kernel, e$mah$att),
                 se  = c(sd(r$boot[, paste0(s, ".nn3")], na.rm = TRUE),
                         sd(r$boot[, paste0(s, ".kernel")], na.rm = TRUE),
                         e$mah$se))
    }))
  }))
  tab$p_value <- 2 * pnorm(-abs(tab$att / tab$se))
  tab
}

contrast_table <- function(results) {
  do.call(rbind, lapply(names(results), function(p) {
    r <- results[[p]]
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
  bal_vars <- c("lag_SC", "lag_con_int", "lag_IM", "lagfertilrate", "lagpolity5")
  do.call(rbind, lapply(names(results), function(p) {
    r <- results[[p]]; tr <- r$df[[pairs[[p]]$treatment]] == 1
    do.call(rbind, lapply(names(specs), function(s) {
      m_nn  <- r$est[[s]]$nn3_match
      m_mah <- r$est[[s]]$mah$m
      do.call(rbind, lapply(bal_vars, function(v) {
        x <- r$df[[v]]
        data.frame(pair = p, spec = s, variable = v,
                   smd_before   = smd_raw(x, tr),
                   smd_after_nn3 = if (is.null(m_nn)) NA else smd_matched(x, m_nn),
                   smd_after_mah = if (is.null(m_mah)) NA else smd_matched(x, m_mah))
      }))
    }))
  }))
}

res_level <- run_all("IM_t")                       # headline
att_lvl <- att_table(res_level)
con_lvl <- contrast_table(res_level)
bal_lvl <- balance_table(res_level)
write.csv(att_lvl, file.path(tab_dir, "T3_att_levels.csv"), row.names = FALSE)
write.csv(con_lvl, file.path(tab_dir, "T4_contrasts_levels.csv"), row.names = FALSE)
write.csv(bal_lvl, file.path(tab_dir, "T5_balance_levels.csv"), row.names = FALSE)

# Appendix A1: same design, 5-year change outcome
res_change <- run_all("change_IM")
write.csv(att_table(res_change), file.path(tab_dir, "A1_att_changes.csv"), row.names = FALSE)
write.csv(contrast_table(res_change), file.path(tab_dir, "A1_contrasts_changes.csv"),
          row.names = FALSE)

# Summary statistics for the pair-A common sample
sum_vars <- c("IM_t", "change_IM", "EFWdiff", all_covars)
sumstats <- res_level$A$df[, sum_vars] %>%
  summarise(across(everything(),
                   list(Mean = ~mean(.), SD = ~sd(.), Min = ~min(.), Max = ~max(.)),
                   .names = "{.col}__{.fn}")) %>%
  pivot_longer(everything(), names_to = c("Variable", ".value"), names_sep = "__")
write.csv(sumstats, file.path(tab_dir, "T2_summary_statistics.csv"), row.names = FALSE)


# =============================================================================
# Part 8: Figures (first pass; to be tuned after Eric's review)
# =============================================================================

pair_names <- c(A = "Liberalization", B = "Liberalization, no deliberalizers",
                C = "Deliberalization", D = "Deliberalization, no liberalizers")

# F1: ATT by spec, pair and estimator
f1 <- att_lvl %>%
  mutate(pair = pair_names[pair], lo = att - 1.96 * se, hi = att + 1.96 * se,
         spec = factor(spec, levels = names(specs))) %>%
  ggplot(aes(x = spec, y = att, colour = estimator)) +
  geom_hline(yintercept = 0, colour = "grey60") +
  geom_pointrange(aes(ymin = lo, ymax = hi), position = position_dodge(0.5)) +
  facet_wrap(~ pair, scales = "free_y") +
  labs(x = NULL, y = "ATT on IMR at t (deaths per 1,000)", colour = NULL) +
  theme_minimal() + theme(legend.position = "bottom")
ggsave(file.path(fig_dir, "F1_att_by_spec.png"), f1, width = 9, height = 6, dpi = 200)

# F2: headline contrast S2 - S1
f2 <- con_lvl %>% filter(contrast == "dq_given_sc") %>%
  mutate(pair = pair_names[pair]) %>%
  ggplot(aes(x = pair, y = diff, colour = estimator)) +
  geom_hline(yintercept = 0, colour = "grey60") +
  geom_pointrange(aes(ymin = diff - 1.96 * se, ymax = diff + 1.96 * se),
                  position = position_dodge(0.4)) +
  coord_flip() +
  labs(x = NULL, y = "ATT(S2) - ATT(S1): adding con_int given state capacity",
       colour = NULL) +
  theme_minimal() + theme(legend.position = "bottom")
ggsave(file.path(fig_dir, "F2_headline_contrast.png"), f2, width = 8, height = 4, dpi = 200)

# F3: balance (love plot), S1 vs S2, Mahalanobis
f3 <- bal_lvl %>% filter(spec %in% c("S1", "S2")) %>%
  mutate(pair = pair_names[pair]) %>%
  pivot_longer(c(smd_before, smd_after_mah), names_to = "when", values_to = "smd") %>%
  ggplot(aes(x = smd, y = variable, shape = when, colour = spec)) +
  geom_vline(xintercept = c(-0.1, 0, 0.1), colour = "grey70", linetype = c(2, 1, 2)) +
  geom_point(position = position_dodge(0.4)) +
  facet_wrap(~ pair) +
  labs(x = "Standardized mean difference", y = NULL, shape = NULL, colour = NULL) +
  theme_minimal() + theme(legend.position = "bottom")
ggsave(file.path(fig_dir, "F3_balance_S1_S2.png"), f3, width = 9, height = 6, dpi = 200)

# F4: data quality vs IMR level, by state-capacity tercile
f4 <- panel %>% filter(!is.na(lag_con_int), !is.na(lag_IM), !is.na(lag_SC)) %>%
  mutate(sc_tercile = factor(ntile(lag_SC, 3), labels = c("Low", "Middle", "High"))) %>%
  ggplot(aes(x = lag_IM, y = lag_con_int, colour = sc_tercile)) +
  geom_point(alpha = 0.5, size = 1) +
  scale_x_log10() + scale_y_log10() +
  labs(x = "Lagged IMR (log scale)", y = "Lagged IGME interval width (log scale)",
       colour = "State capacity") +
  theme_minimal()
ggsave(file.path(fig_dir, "F4_conint_vs_imr_by_sc.png"), f4, width = 7, height = 5, dpi = 200)


# =============================================================================
# Part 9: Robustness hooks (plan section 8; change a setting and rerun)
# =============================================================================
# R1  SC_VAR <- SC_ALT                      (V-Dem fiscal capacity)
# R2  THRESHOLD <- 0.75 or 0.5
# R3  INCLUDE_2024 <- TRUE                  # TODO(data): 2020 GDP block
# R4  placebo: run_all("lag2_IM") after adding "lag2_IM" to test_sample()'s
#     required columns; should show no effect
# R5  IGME vintage: point REVISED_CSV at the old merged.csv build
# R6  drop windows ending 1975
# R7  FERT_OPTION <- "F2" / "F3" / "F4" / "F5"
# R8  WB Statistical Capacity Indicator    # TODO(data): not merged yet

saveRDS(list(panel = panel, levels = res_level, changes = res_change,
             att = att_lvl, contrasts = con_lvl, balance = bal_lvl,
             settings = list(DATA_FILE = DATA_FILE, OUTCOME = OUTCOME,
                             END_YEAR = END_YEAR, THRESHOLD = THRESHOLD,
                             SC_VAR = SC_VAR, FERT_OPTION = FERT_OPTION)),
        file.path(out_dir, "revised_results.rds"))
cat("Done. Outputs in", out_dir, "\n")
