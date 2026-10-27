# Data

The individual-level ambulatory and neuroimaging data are not included in this repository. They are available from the corresponding author on reasonable request, subject to approval by the Institutional Review Board of Ewha W. University and a data-use agreement.

`R/run_mediation.R` and `stata/mlm_mediation_mc.do` expect one row per person-day with the following columns:

| Column | Description |
|---|---|
| `ID` | participant identifier (random-intercept cluster) |
| `age` | age in years |
| `sex` | `F` or `M` |
| `lag_night_sleep_min` | prior-night nocturnal sleep duration, minutes (exposure) |
| `lag_noct_mage` | prior-night nocturnal MAGE, mg/dL (mediator) |
| `rt1_composite`, `rt2_composite`, `rt3_composite` | next-day psychomotor-speed, selective-attention and executive-function composites, z-scores (outcomes) |
| `inc_fig3_4` | 1 for person-days in the prior-night MAGE analysis sample (optional; rows with 1 are kept) |

`mlm_mediation_mc()` itself accepts any exposure, mediator, outcome, covariate and cluster column names.
