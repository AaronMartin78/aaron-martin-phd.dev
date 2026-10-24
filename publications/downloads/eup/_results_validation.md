# Results validation vs replication_log.log

## Table 2 - t-tests (23 tests)
  -> 23 passed, 0 failed

## Table 4 - Firth models (7)
  OK  all_switch_full  N=3962 (stata 3962)  logLik*=-637.68894 (stata -637.68894)
  OK  indiv_switch_full N=3962 (stata 3962)  logLik*=-455.84114 (stata -455.84114)
  OK  bloc_switch_full N=3962 (stata 3962)  logLik*=-326.97514 (stata -326.97514)
  OK  all_power        N=3962 (stata 3962)  logLik*=-1288.81064 (stata -1288.8106)
  OK  all_power_col    N=3962 (stata 3962)  logLik*=-697.40471 (stata -697.40471)
  OK  indiv_power      N=3962 (stata 3962)  logLik*=-477.35726 (stata -477.35726)
  OK  bloc_power       N=3962 (stata 3962)  logLik*=-361.04744 (stata -361.04744)

## Appendix B - McElroy (2 models)
  OK  mc_logit   N=545 (stata 545)  logLik=-203.50908 (stata -203.50908)
  OK  mc_firth   N=579 (stata 579)  logLik=-193.07426 (stata -193.07426)

## TOTAL: 32 passed, 0 failed