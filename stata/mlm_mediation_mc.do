* mlm_mediation_mc.do
* Stata companion to R/mlm_mediation_mc.R: three mixed models (REML, random intercept), the indirect effect a*b,
* and a quasi-Bayesian Monte Carlo 95% interval and P value (5,000 draws). Edit the locals, then: do mlm_mediation_mc.do
version 16.0
clear all
set more off

local DATA "data/day_level.csv"
local X    lag_night_sleep_min
local M    lag_noct_mage
local Y    rt3_composite
local SIMS 5000
local SEED 1111111

import delimited "`DATA'", case(preserve) encoding("utf-8") clear
capture keep if inc_fig3_4 == 1
encode ID, gen(idn)
encode sex, gen(sexn)
foreach v in `X' `M' `Y' age {
    drop if missing(`v')
}
quietly summarize `X'
local sdx = r(sd)
quietly summarize `M'
local sdm = r(sd)
quietly summarize `Y'
local sdy = r(sd)

mixed `M' `X' age i.sexn || idn:, reml
local a = _b[`X']
local sea = _se[`X']
mixed `Y' `X' `M' age i.sexn || idn:, reml
local b = _b[`M']
local seb = _se[`M']
local cp = _b[`X']
mixed `Y' `X' age i.sexn || idn:, reml
local c = _b[`X']

preserve
clear
set seed `SEED'
set obs `SIMS'
gen double ind = rnormal(`a', `sea') * rnormal(`b', `seb')
_pctile ind, p(2.5 97.5)
local lo = r(r1)
local hi = r(r2)
quietly count if ind <= 0
local ple = r(N) / `SIMS'
quietly count if ind >= 0
local pge = r(N) / `SIMS'
restore

di as result _n "a = " %9.6f `a' "  b = " %9.6f `b' "  c' = " %9.6f `cp' "  c = " %9.6f `c'
di as result "ACME (a*b) = " %9.6f `a' * `b' "  MC 95% CI (" %9.6f `lo' ", " %9.6f `hi' ")  P_MC = " %6.4f 2 * min(`ple', `pge')
di as result "standardised: a* = " %7.4f `a' * `sdx' / `sdm' "  b* = " %7.4f `b' * `sdm' / `sdy' "  ACME* = " %8.5f `a' * `b' * `sdx' / `sdy' "  (" %8.5f `lo' * `sdx' / `sdy' ", " %8.5f `hi' * `sdx' / `sdy' ")"
di as result "proportion mediated = " %6.3f `a' * `b' / `c'
