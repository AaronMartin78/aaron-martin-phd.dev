# Party Politics multilevel models (Tables 4 & 5) - findings

## What the reported models actually are
Tables 4 and 5 are **three-level nested mixed-effects logits**, not two-level:

    xtmelogit <dv> <covariates> || start_group_num: || bloc_id3:

a random intercept for the EP party group (`start_group_num`, 25 groups) AND a
random intercept for the national-party delegation (`bloc_id3`) nested within it.
lme4 equivalent: `(1 | start_group_num/bloc_id3)`.

## Ground truth (from march25_2021.log), Table 5 (amb_switch)

| Column | Model | logLik | key coefficients |
|--------|-------|--------|------------------|
| 4  | intensity | -563.988 | z_intense2 -0.3592, c_npd_perc -11.160, c_epg_perc -9.314, govt2 -0.7115, mep_tenure 0.3726, female -0.7780, _cons -5.6818 |
| 7  | quadratic | -513.389 | a1_std2 1.3359, a2_std2 0.6217, a1^2 -0.1782, a2^2 -0.0933, c_npd_perc -12.744 |
| 10 | full      | -493.246 | a1_std2 1.6026, a2_std2 0.8869, a1^2 -0.2034, a2^2 -0.1150 |

(The published `table5.txt` matches the intensity and quadratic columns exactly;
the "full" column differs slightly - 1.624 vs 1.6026 - suggesting the printed
table was assembled from a marginally different model run than this log.)

## Reproduction status
- **Exact Stata outputs are preserved in the log**, so the results themselves are
  recoverable at full precision without Stata.
- **Independent reproduction was attempted in Python and did not succeed here:**
  a two-level fit is systematically ~20-40% attenuated (wrong structure), and the
  correct three-level nested fit could not be optimized within the sandbox's
  compute limit (nested quadrature is expensive; Stata itself hit "not concave"
  iterations, so the models are numerically delicate).
- **Recommended path:** run `make_pp_multilevel.R` (corrected to the nested
  `(1 | start_group_num/bloc_id3)` structure) in RStudio and compare its output to
  the ground-truth values above. `lme4` will be close but is not guaranteed to
  match Stata's `xtmelogit` to the decimal.
