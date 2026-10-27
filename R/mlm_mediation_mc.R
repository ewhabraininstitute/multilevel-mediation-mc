# mlm_mediation_mc.R
# (1-1-1) multilevel mediation with a quasi-Bayesian Monte Carlo indirect effect.
# Three linear mixed models (REML, random intercept for the cluster) give the a, b, c' and c paths;
# each path coefficient is drawn from its sampling distribution (sims draws), the indirect effect is a*b,
# 95% intervals are percentile intervals of the draws and the two-sided P is 2*min(P(a*b <= 0), P(a*b >= 0)).
# Standardised coefficients rescale by the SDs of x, m and y in the analysed rows.
# Requires lme4 and lmerTest.

suppressPackageStartupMessages({ library(lme4); library(lmerTest) })

mlm_mediation_mc <- function(data, x, m, y, id = "ID", covariates = c("age", "sex"),
                             sims = 5000, seed = 1111111, conf = 0.95, REML = TRUE) {
  stopifnot(all(c(x, m, y, id, covariates) %in% names(data)))
  qs <- c((1 - conf) / 2, 1 - (1 - conf) / 2)
  vars <- c(x, m, y, id, covariates)
  d <- data[stats::complete.cases(data[, vars]), vars, drop = FALSE]
  cov_rhs <- if (length(covariates)) paste("+", paste(covariates, collapse = " + ")) else ""
  sd_x <- stats::sd(d[[x]]); sd_m <- stats::sd(d[[m]]); sd_y <- stats::sd(d[[y]])

  m_med <- lmerTest::lmer(stats::as.formula(sprintf("%s ~ %s %s + (1 | %s)", m, x, cov_rhs, id)), data = d, REML = REML)
  m_out <- lmerTest::lmer(stats::as.formula(sprintf("%s ~ %s + %s %s + (1 | %s)", y, x, m, cov_rhs, id)), data = d, REML = REML)
  m_tot <- lmerTest::lmer(stats::as.formula(sprintf("%s ~ %s %s + (1 | %s)", y, x, cov_rhs, id)), data = d, REML = REML)
  s_med <- coef(summary(m_med)); s_out <- coef(summary(m_out)); s_tot <- coef(summary(m_tot))
  a <- s_med[x, "Estimate"]; a_se <- s_med[x, "Std. Error"]
  b <- s_out[m, "Estimate"]; b_se <- s_out[m, "Std. Error"]
  cp <- s_out[x, "Estimate"]; cp_se <- s_out[x, "Std. Error"]
  c_tot <- s_tot[x, "Estimate"]; c_se <- s_tot[x, "Std. Error"]

  if (!is.null(seed)) set.seed(seed)
  a_d <- stats::rnorm(sims, a, a_se); b_d <- stats::rnorm(sims, b, b_se)
  cp_d <- stats::rnorm(sims, cp, cp_se); c_d <- stats::rnorm(sims, c_tot, c_se)
  ind_d <- a_d * b_d; ind <- a * b
  p_ind <- if (ind == 0) 1 else 2 * min(mean(ind_d <= 0), mean(ind_d >= 0))
  r_xm <- sd_x / sd_m; r_my <- sd_m / sd_y; r_xy <- sd_x / sd_y
  ci <- function(v) stats::quantile(v, qs, names = FALSE)
  ci_ind <- ci(ind_d); ci_ind_std <- ci((a_d * r_xm) * (b_d * r_my)); ci_prop <- ci(ind_d / c_d)

  out <- data.frame(
    x = x, m = m, y = y, n_rows = nrow(d), n_id = length(unique(d[[id]])), sd_x = sd_x, sd_m = sd_m, sd_y = sd_y,
    a = a, a_p = s_med[x, "Pr(>|t|)"], b = b, b_p = s_out[m, "Pr(>|t|)"],
    cprime = cp, cprime_p = s_out[x, "Pr(>|t|)"], c_total = c_tot, c_p = s_tot[x, "Pr(>|t|)"],
    ACME = ind, ACME_lwr = ci_ind[1], ACME_upr = ci_ind[2], ACME_p_MC = p_ind,
    ADE = cp, ADE_lwr = ci(cp_d)[1], ADE_upr = ci(cp_d)[2],
    Total = c_tot, Total_lwr = ci(c_d)[1], Total_upr = ci(c_d)[2],
    Prop_mediated = ind / c_tot, Prop_lwr = ci_prop[1], Prop_upr = ci_prop[2],
    a_std = a * r_xm, b_std = b * r_my, cprime_std = cp * r_xy, c_std = c_tot * r_xy,
    ACME_std = a * r_xm * b * r_my, ACME_std_lwr = ci_ind_std[1], ACME_std_upr = ci_ind_std[2],
    sims = sims, seed = if (is.null(seed)) NA_integer_ else seed, row.names = NULL, stringsAsFactors = FALSE)
  attr(out, "mc_draws") <- list(a = a_d, b = b_d, cprime = cp_d, c = c_d, indirect = ind_d)
  out
}
