* need to keep only countires which are in my trade sample
use "$Dropbox\data\pwt\pwt90.dta", clear

rename countrycode code
keep if year>=2000
drop if hc==.
merge 1:1 code year using "I:\Dropbox\data\governance\wgidataset.dta", keep(match)
drop _merge
tempfile data
save `data'

keep if year==2000
keep code
tempfile data_id
save `data_id', replace

cd $dropbox\data\shapefiles\
unzipfile TM_WORLD_BORDERS_SIMPL-0.3.zip, replace
spshape2dta TM_WORLD_BORDERS_SIMPL-0.3.shp, replace
use TM_WORLD_BORDERS_SIMPL-0.3.dta, clear
generate code = ISO3
merge 1:1 code using `data_id', keep(match)
drop _merge
save TM_WORLD_BORDERS_SIMPL-0.3.dta, replace
spmatrix create contiguity Wc, replace
spmatrix create idistance Wd, replace

use `data'
merge m:1 code using TM_WORLD_BORDERS_SIMPL-0.3.dta, keep(match)
drop _merge
merge m:1 code using `data_id', keep(match)



gen fips=_ID
drop if fips==.
xtset fips year
spcompress, force
spbalance
spset fips, modify replace
gen lngdp=ln(rgdpo)
gen lnk=ln(ck)
gen lnl=ln(emp)
spxtregress lngdp rle pve hc lnk lnl, fe  dvarlag(Wc) errorlag(Wc) ivarlag(Wc: rle pve hc lnk lnl) force
estat impact hc
*spxtregress lngdp rle pve hc lnk lnl, re sarpanel noconstant  dvarlag(Wc) errorlag(Wc) ivarlag(Wc: rle pve hc lnk lnl) force
