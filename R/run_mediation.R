# run_mediation.R
# Day-level mediation of prior-night sleep -> same-night nocturnal MAGE -> next-day cognition (three domains).
# Usage (from the repository root):  Rscript R/run_mediation.R path/to/day_level.csv
# The analytic dataset is not distributed with this repository (see data/README.md).
source("R/mlm_mediation_mc.R")

args <- commandArgs(trailingOnly = TRUE)
infile <- if (length(args) >= 1) args[1] else "data/day_level.csv"
if (!file.exists(infile)) stop("Analytic dataset not found: ", infile)
d <- read.csv(infile, stringsAsFactors = FALSE)
d$sex <- factor(d$sex)
if ("inc_fig3_4" %in% names(d)) d <- d[d$inc_fig3_4 == 1, ]

outcomes <- c(psychomotor_speed = "rt1_composite", selective_attention = "rt2_composite", executive_function = "rt3_composite")
res <- do.call(rbind, lapply(names(outcomes), function(k) {
  r <- mlm_mediation_mc(d, x = "lag_night_sleep_min", m = "lag_noct_mage", y = outcomes[[k]], id = "ID",
                        covariates = c("age", "sex"), sims = 5000, seed = 1111111)
  cbind(domain = k, r)
}))
print(res[, c("domain", "n_rows", "a_std", "b_std", "cprime_std", "c_std", "ACME_std", "ACME_std_lwr", "ACME_std_upr", "ACME_p_MC", "Prop_mediated")], digits = 3, row.names = FALSE)
write.csv(res, "mediation_results.csv", row.names = FALSE)
