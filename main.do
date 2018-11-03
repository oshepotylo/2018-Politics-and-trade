clear all
set maxvar 32767
set matsize 11000
set  emptycells drop
set more off

local date 03October2018

global data "$dropbox\data"
cd "$dropbox\2018 Politics and Trade\"

*log using log\logof_`date'.log

*do do\1_data_prep_`date' `date'
do do\2_gravity_estimates_`date' `date'
