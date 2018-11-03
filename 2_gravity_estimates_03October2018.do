* This file will estimate how political stability influences trade.
use "data\data_`1'", clear
keep if year>=1998

* modelling selection into positive trading partners
gen trade=cond(exp>0,1,0)

probit trade rta contig colony comleg comrelig csl lndist gdpsum gdpsim dkl pvi pvj i.year, vce(robust)
estadd scalar r2 = e(r2_p)
estimates store selection

predict double p 
*limiting p
replace p=0.000001 if p<0.000001
replace p=0.999999 if p>0.999999&p<.
*generating first-stage variables
gen double z1=invnormal(p)
gen nu=normalden(z1)/p 
gen z=z1+nu
gen z2=z*z
gen z3=z2*z
eststo selection_margin: margins, dydx(*) post

glm exp  rta contig csl colony comleg comrelig lndist lngdpi lngdpj pvi pvj i.i i.j, vce(robust) family(poisson) noconst search irls
estimates store gravity_ppml_panel

glm exp  rta contig csl colony comleg comrelig lndist lngdpi lngdpj pvi pvj i.i i.j i.year, vce(robust) family(poisson) noconst search irls
estimates store gravity_ppml_panel_year

estpost sum  exp lnt trade rta contig colony comleg comrelig csl rta lndist autoc durab polcomp gdpsum gdpsim dkl lngdpi lngdpj pvi pvj if e(sample)
esttab, cells()

gen lnexp=ln(exp)

*Gravity regression with country-time fixed effects - So far we can not run a regression for the whole sample due to Stata limitations
reghdfe lnexp rta contig csl colony comleg comrelig lndist lngdpi lngdpj pvi pvj nu z z2 z3, a( i j) vce(robust)
estimates store gravity_hmr


*Gravity regression with country-time fixed effects - So far we can not run a regression for the whole sample due to Stata limitations
reghdfe lnexp rta contig csl colony comleg comrelig lndist lngdpi lngdpj pvi pvj nu z z2 z3, a( i j year) vce(robust)
estimates store gravity_hmr_year

reghdfe lnexp rta lnt contig csl colony comleg comrelig lndist lngdpi lngdpj pvi pvj nu z z2 z3, a( i j year) vce(robust)
estimates store gravity_hmr_year_tariff


* Results output
label var exp "Export"
label var lnexp "\$\ln(Export)\$"
label var rta "RTA"
label var pvi "Polit. stab. origin"
label var pvj "Polit. stab. destination"
label var lngdpi "\$\ln(GDP_{it})\$"
label var lngdpj "\$\ln(GDP_{jt})\$"
label var lndist "\$\ln(dist_{ij})\$"
label var contig "Common border"
label var colony "Colonial past"
label var comleg "Common legal"
label var comrelig "Common religion"
label var csl "Common language"
label var nu "\$\hat{\eta}_{ij,t}\$"
label var z "\$\hat{\bar{z}}_{ij,t}\$"
label var z2 "\$\hat{\bar{z}}_{ij,t}^{2}\$"
label var z3 "\$\hat{\bar{z}}_{ij,t}^{3}\$"
label var trade "Export\$>0\$, Yes=1"
label var autoc "Autocracy"
label var durab "Durability"
label var polcomp "Political competition"
label var gdpsum "GDP sum"
label var gdpsim "GDP similarity"
label var dkl "Endowment similarity"

estpost sum lnexp trade rta nu z contig colony comleg comrelig csl rta lndist autoc durab polcomp gdpsum gdpsim dkl lngdpi lngdpj pvi pvj if e(sample)
esttab, cells()

esttab gravity_ppml_panel gravity_ppml_panel_year  selection_margin gravity_hmr gravity_hmr_year gravity_hmr_year_tariff using "out\ps_elasticity_`1'",replace rtf r2 label noconstant star(* 0.05 ** 0.01) ///
		cells("b(fmt(3)star)" "se(fmt(3)par)") ///
		keep(rta pvi pvj lngdpi lngdpj nu z z2 z3 contig colony comleg comrelig csl lndist gdpsum gdpsim dkl) ///
		order(pvi pvj rta lngdpi lngdpj lndist contig colony comleg comrelig csl gdpsum gdpsim dkl nu z z2 z3 )

esttab gravity_ppml_panel gravity_ppml_panel_year  selection gravity_hmr gravity_hmr_year gravity_hmr_year_tariff using "out\ps_elasticity_`1'", booktabs replace ///
	keep(rta pvi pvj lngdpi lngdpj nu z z2 z3 contig colony comleg comrelig csl lndist gdpsum gdpsim dkl) ///
	order(pvi pvj rta lngdpi lngdpj lndist contig colony comleg comrelig csl gdpsum gdpsim dkl nu z z2 z3 ) ///
	cells(b(star fmt(3)) se( fmt(a2)par))  nolz star(+ .10 * 0.05 ** 0.01  )  ///
	collabels(none) mlabels(,depvars) nomtitles label r2(2) /// 
	substitute ("\_" "_") ///
	prehead (\begin{table} \footnotesize \begin{threeparttable} \caption{Export and political stability} ///
	\label{table:gravity} \centering	\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} ///
	\begin{tabular}{l*{@M}{c}} \toprule \toprule) ///
 	posthead(\midrule ) ///
	postfoot(\bottomrule \end{tabular} ///
	\begin{tablenotes} ///
		\small \item \sym{+} \(p<0.1\), \sym{*} \(p<0.05\), \sym{**} \(p<0.01\) Robust standard errors in parentheses. \\ ///
		Models (1) and (2) are estimated by PPML. Models (3) is probit. Models (4)-(6) are estimated by HMR method. ///
		\end{tablenotes}  \end{threeparttable} \end{table} )


