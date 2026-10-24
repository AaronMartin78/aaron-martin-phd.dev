# EUP replication - validation report

Python port validated against the original Stata datasets (_A/_B/_C) and replication_log.log.

## Data pipeline (cell-level agreement)
- Stage A: 958457/958457 cells match across 241 columns, 3977 rows -> 100.000%
- Stage B: 1081744/1081744 cells match across 272 columns, 3977 rows -> 100.000%
- Stage C: 795/795 cells match across 15 columns, 53 rows -> 100.000%

## Table 4 - Firth penalized logit (vs replication_log.log)
- all_switch_full: N=3962 (Stata 3962), logLik*=-637.68894 (Stata -637.68894)
- indiv_switch_full: N=3962 (Stata 3962), logLik*=-455.84114 (Stata -455.84114)
- bloc_switch_full: N=3962 (Stata 3962), logLik*=-326.97514 (Stata -326.97514)