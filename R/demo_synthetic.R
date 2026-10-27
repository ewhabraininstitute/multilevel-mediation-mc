# demo_synthetic.R
# Runs mlm_mediation_mc() on simulated day-level data with a known indirect effect (no study data required).
# Usage (from the repository root):  Rscript R/demo_synthetic.R
source("R/mlm_mediation_mc.R")

set.seed(1)
n_id <- 150; n_day <- 20
id <- rep(sprintf("P%03d", seq_len(n_id)), each = n_day)
age <- rep(round(runif(n_id, 25, 60)), each = n_day)
sex <- factor(rep(sample(c("F", "M"), n_id, replace = TRUE), each = n_day))
u_m <- rep(rnorm(n_id, 0, 6), each = n_day); u_y <- rep(rnorm(n_id, 0, 0.3), each = n_day)
sleep <- rnorm(n_id * n_day, 390, 90)                                  # exposure (minutes)
mage <- 40 - 0.03 * sleep + u_m + rnorm(n_id * n_day, 0, 12)           # mediator: a = -0.03
cog <- 0.0005 * sleep - 0.004 * mage + u_y + rnorm(n_id * n_day, 0, 0.5)  # outcome: b = -0.004, c' = 0.0005
d <- data.frame(ID = id, age = age, sex = sex, lag_night_sleep_min = sleep, lag_noct_mage = mage, rt3_composite = cog)

res <- mlm_mediation_mc(d, x = "lag_night_sleep_min", m = "lag_noct_mage", y = "rt3_composite", id = "ID",
                        covariates = c("age", "sex"), sims = 5000, seed = 1111111)
cat(sprintf("true a*b = %.6f\n", -0.03 * -0.004))
print(res[, c("n_rows", "a", "b", "cprime", "c_total", "ACME", "ACME_lwr", "ACME_upr", "ACME_p_MC", "Prop_mediated", "ACME_std")], digits = 4, row.names = FALSE)
