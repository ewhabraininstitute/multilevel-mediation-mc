# multilevel-mediation-mc

Custom code for the (1-1-1) multilevel mediation analysis with a quasi-Bayesian Monte Carlo indirect effect used in:

> Yoon S, Sung JE, Jun SB, et al. Sleep, nocturnal glycaemic variability, and prefrontal perfusion: a multimodal digital phenotyping study of next-day executive function in working adults.

## Contents

```
R/mlm_mediation_mc.R      core function mlm_mediation_mc()
R/run_mediation.R         driver: prior-night sleep -> same-night MAGE -> next-day cognition (Fig. 2c)
R/demo_synthetic.R        example on simulated data (no study data needed)
stata/mlm_mediation_mc.do Stata companion (mixed + Monte Carlo)
data/README.md            expected columns; data are not distributed
```

## Method

Per outcome, three linear mixed models with a participant random intercept are fitted by REML:
`M ~ X + covariates`, `Y ~ X + M + covariates`, `Y ~ X + covariates`. The indirect effect is `a*b`.
Each path coefficient is drawn 5,000 times from `N(estimate, SE^2)`; the 95% interval is the 2.5th–97.5th percentile
of the simulated `a*b` and the two-sided P value is `2*min(P(a*b <= 0), P(a*b >= 0))`.
Standardised coefficients rescale by the SDs of X, M and Y in the analysed rows.

## Requirements

R (>= 4.4) with `lme4` and `lmerTest`; Stata (>= 16) for the companion do-file.

```r
install.packages(c("lme4", "lmerTest"))
```

## Usage

```bash
Rscript R/demo_synthetic.R
Rscript R/run_mediation.R path/to/day_level.csv
```

```r
source("R/mlm_mediation_mc.R")
res <- mlm_mediation_mc(df, x = "lag_night_sleep_min", m = "lag_noct_mage", y = "rt3_composite",
                        id = "ID", covariates = c("age", "sex"), sims = 5000, seed = 1111111)
res[, c("ACME_std", "ACME_std_lwr", "ACME_std_upr", "ACME_p_MC", "Prop_mediated")]
```

Reported result (executive function, n = 4,253 person-days): standardised indirect effect 0.0085 (95% CI 0.0048–0.0131 [unrounded 2.5th percentile 0.004748]), P < 0.001, 8.4% of the total effect.

## License

MIT (see LICENSE).
