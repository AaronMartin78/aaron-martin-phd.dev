# Party Politics validation

## Data pipeline (dataset_12222020 -> PP_dataset)
- 2219166/2219166 cells match across 558 columns, 3977 rows -> 100.000%

## Firth session_switch models (Table 5 robustness) vs march25_2021.log
- OK  as_firth_intense: N=3977 logLik*=-643.86901 (stata -643.86901)
- OK  as_firth_quad: N=3977 logLik*=-568.22092 (stata -568.22092)
- OK  as_firth_full: N=3977 logLik*=-556.95429 (stata -556.95429)

## Firth: 3/3 match

## Multilevel Tables 4/5 (xtmelogit)
- Not reproduced here: no software available that matches Stata's
  adaptive quadrature; models are convergence-sensitive. R/lme4
  scripts for the model structures are in make_pp_multilevel.R.