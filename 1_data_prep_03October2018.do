


use $data\gravity\exp_imp_dots, clear
replace exp=. if exp==0
replace imp=. if imp==0
drop if exp==.&imp==.

replace exp=exp/1000000000

replace codei="ROU" if codei=="ROM"
replace codej="ROU" if codej=="ROM"

drop n*

*make a rectangular trade matrix
drop if codej=="ATG"|codej=="BTN"|codej=="BWA"|codej=="ERI"|codej=="KIR"|codej=="KOS"|codej=="LSO"|codej=="NAM"| ///
		codej=="PLW"|codej=="SSD"|codej=="SWZ"|codej=="TLS"|codej=="TUV"|codej=="TWN"
		
*Data for these countries do not exist
*no distance data
drop if codei=="MNE"|codej=="MNE"
drop if codei=="COD" | codej=="COD"
*no language data
drop if codei=="ETH"|codej=="ETH"
drop if codei=="GNQ" | codej=="GNQ"
drop if codei=="MDV"|codej=="MDV"
drop if codei=="MMR" | codej=="MMR"
drop if codei=="SRB"|codej=="SRB"
drop if codei=="MNG" | codej=="MNG"
drop if codei=="WSM"|codej=="WSM"
drop if codei=="KNA" | codej=="KNA"

keep if year>=1960

tempfile data
tempfile fulldata
save `data'
keep if year==1960
fillin codei codej year
drop _fillin	
save `fulldata'



foreach yr of numlist 1961/2014 {
use `data'
keep if year==`yr'
fillin codei codej year
drop _fillin
replace exp=0 if exp==.
replace imp=0 if imp==.
append using `fulldata'
save `fulldata', replace
}

merge m:1 codei codej year using $data\gravity\rta_gravity_cepii, keep(match master)
drop _merge
merge m:1 codei codej using $data\gravity\lang, keep(match master) keepusing(csl)
drop _merge
replace csl=1 if codei==codej


rename codei code
merge m:1 code year using $data\gdp\gdp2015, keep(match master)
replace gdp=gdp/1000000000
drop _merge
merge m:1 code year using $data\pop\pop2015, keep(match master)
replace pop=pop/1000000
drop _merge
merge m:1 code year using $data\polity\polity, keep (match master)
drop _merge
merge m:1 code year using $data\governance\wgidataset, keep (match master)
drop _merge
rename code codei
rename gdp gdpi
rename pop popi
rename autoc autoci
rename durable durablei
rename polcomp polcompi
rename pve pvi

rename codej code
merge m:1 code year using $data\gdp\gdp2015, keep(match master)
replace gdp=gdp/1000000000
drop _merge
merge m:1 code year using $data\pop\pop2015, keep(match master)
replace pop=pop/1000000
drop _merge
merge m:1 code year using $data\polity\polity, keep (match master)
drop _merge
merge m:1 code year using $data\governance\wgidataset, keep (match master)
drop _merge


rename code codej
rename gdp gdpj
rename pop popj
rename autoc autocj
rename durable durablej
rename polcomp polcompj
rename pve pvj


* Adding applied tariffs

rename codej iso3
gen iso3eu=iso3
replace iso3eu="EUN" if iso3=="BGR"&year>=2007
replace iso3eu="EUN" if iso3=="ROU"&year>=2007
replace iso3eu="EUN" if iso3=="CZE"&year>=2004
replace iso3eu="EUN" if iso3=="EST"&year>=2004
replace iso3eu="EUN" if iso3=="HUN"&year>=2003
replace iso3eu="EUN" if iso3=="LTU"&year>=2004
replace iso3eu="EUN" if iso3=="LVA"&year>=2003
replace iso3eu="EUN" if iso3=="POL"&year>=2004
replace iso3eu="EUN" if iso3=="SVK"&year>=2003
replace iso3eu="EUN" if iso3=="SVN"&year>=2004
replace iso3eu="EUN" if iso3=="MLT"&year>=2004
replace iso3eu="EUN" if iso3=="CYP"&year>=2003
replace iso3eu="EUN" if iso3=="AUT"&year>=1995
replace iso3eu="EUN" if iso3=="BEL"&year>=1957
replace iso3eu="EUN" if iso3=="DEU"&year>=1957
replace iso3eu="EUN" if iso3=="DNK"&year>=1973
replace iso3eu="EUN" if iso3=="ESP"&year>=1986
replace iso3eu="EUN" if iso3=="FIN"&year>=1995
replace iso3eu="EUN" if iso3=="FRA"&year>=1957
replace iso3eu="EUN" if iso3=="GBR"&year>=1973
replace iso3eu="EUN" if iso3=="GRC"&year>=1981
replace iso3eu="EUN" if iso3=="IRL"&year>=1973
replace iso3eu="EUN" if iso3=="ITA"&year>=1957
replace iso3eu="EUN" if iso3=="LUX"&year>=1957
replace iso3eu="EUN" if iso3=="NLD"&year>=1957
replace iso3eu="EUN" if iso3=="PRT"&year>=1986
replace iso3eu="EUN" if iso3=="SWE"&year>=1995
replace iso3eu="EUN" if iso3=="HRV"&year>=2013
*update the tariff data below to expand time span. Download from TRAINS
*Also get data on NTM measures                        
merge m:1 iso3eu year using $data\tariff\mfn_2003_2015.dta, keep(match master)
drop _merge

rename iso3eu codejeu

merge m:1 codei codejeu year using $data\tariff\applied_tariff_1988_2016, keep(match master)

gen tariff=AHS

* replace missing bilateral tariff with mfn tariff
*replace tariff=mfn if tariff==.

drop _merge
rename iso3 codej



* Generating variables for regressions					
gen lndist=ln(distw)
gen lngdpi=ln(gdpi)
gen lngdpj=ln(gdpj)
gen lnt=ln(1+tariff/100)


* RTA selection
gen autoc=abs(autoci-autocj)
gen durab=abs(durablei-durablej)
gen polcomp=abs(polcompi-polcompj)
gen gdpsum=ln(gdpi+gdpj)
gen gdpsim=ln(abs(gdpi-gdpj))
gen dkl=ln(abs(gdpi/popi-gdpj/popj))

drop autoci autocj durablei durablej polcompi polcompj


encode codei, gen(i)
encode codej, gen(j)
gen codeij=codei+codej
encode codeij, gen(ij)

gen y=year
tostring y, replace
gen iy=codei+y
gen jy=codej+y
encode iy,g(niy)
encode jy,g(njy)

drop  codeij y iy jy


xtset ij year


* Results output
label var rta "RTA"
label var lngdpi "ln(GDP_(it))"
label var lngdpj "ln(GDP_(jt))"
label var lndist "ln(dist_(ij))"
label var lnt "Ln(1+ Applied MFN tariff)"
label var contig "Common border"
label var colony "Colonial past"
label var comleg "Common legal"
label var comrelig "Common religion"
label var csl "Common language"
label var autoc "Autocracy"
label var durab "Durability"
label var polcomp "Political competition"
label var gdpsum "GDP sum"
label var gdpsim "GDP similarity"
label var dkl "Endowment similarity"
label var pvi "Political sability i"
label var pvj "Political stability j"


save "data\data_`1'", replace
