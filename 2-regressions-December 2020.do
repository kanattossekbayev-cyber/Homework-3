
/*

Code by Dorit Stein
dorittalia@gmail.com

For analysis in: 
Stein DT, Sudharsanan N, Dewi S, Manne-Goehler J, Witoelar F, Geldsetzer P. Change in clinical knowledge of diabetes among primary healthcare providers in Indonesia: repeated cross-sectional survey of 5105 primary healthcare facilities. BMJ Open Diabetes Research and Care. 2020 Oct 1;8(1):e001415.


This script (3 of 3) runs the regressions in the paper, including the supplementary analysis and robustness checks.

*/

********************************************
****provider level regress****
********************************************
	set more off
clear all

* Set user and the directory (YOUR path)
global dir "C:\Users\User\Desktop\HW3"
global raw "$dir"
global output "$dir"


	use "$output/vignette-scores-provider-level8.dta", replace
	
	*create province indicators (just using levels of factor variable)
	tab province, generate(province)
	
	ssc install coefplot, replace
	

********************************************
****provider level regress****
********************************************
	*REGRESSION TABLE
	eststo clear
	
	reg vig_per i.year i.cadre, cluster(commid)
		estimates store null
	
	reg vig_per i.year i.cadre i.urban i.province, cluster(commid)
		estimates store unadjusted
	
	reg vig_per i.year i.cadre i.urban experience i.training_ncd ///
	i.diabetes_training i.drugs_training i.private_fac i.province, ///
	cluster(commid)
		estimates store adjusted_final
		
			
********************************************
****Coefplot****
********************************************

	*set graph things
		*ssc install grstyle
		grstyle clear
		grstyle init
		grstyle set plain, nogrid 

	coefplot (null, label("Model 1") msymbol(o) color(black) ciopts(color(black)) mlabcolor (black)) ///
			(unadjusted, label("Model 2") msymbol(d) color(maroon) ciopts(color(maroon)) mlabcolor (maroon)) ///
			(adjusted_final, label("Model 3") msymbol(s) color(navy) ciopts(color(navy)) mlabcolor (navy)), ///
			drop(_cons *.province) /// 
		name(graphygraph, replace)  ///
	xlabel(,labsize(3)) xline(0, lwidth(vthin) lcolor(dkorange)) ///
	ylabel(1 "Year" 2 "Nurse" 3 "Midwife" 4 "Paramedic" 5 "Urban" 6 "Years of Experience" ///
	7 "NCD Training" 8 "Diabetes Training" 9 "Diabetes Drugs Training" ///
	10 "Private Facility", labsize(3)) ///
	mlabel format(%-2.1f) mlabposition(2) mlabgap(*1.0) mlabsize(2.5) ///
	graphregion(color(white)) legend(position(5) rows(1) size(3)) ///
	ysize(10)  ///
	xsize(7) ///
	xlabel(-12(4)4) xscale(range(-12(1)4))
	
	graph export "$output/Figure3-coefplot.eps", replace fontface(Helvetica)
	 
	
********************************************
****2014 regressions with place of education****
			**for appendix**
********************************************

	*where did you study? in diabetes vignette
	gen vig_education = . 
	replace vig_education = 0 if h17a == 1 | h17a == 2 | h17a == 3 | ///
	h17a == 4 | h17a == 5 
	replace vig_education = 1 if h17a == 6
	replace vig_education = 2 if h17a == 7
	replace vig_education = 3 if h17a == 95
	
	label def vig_education 0 "Main universities" ///
	2 "private university" 3 "Other" ///
	1 "Other State university"
	label value vig_education vig_education
	
	*run only 2014 vignette to see if score is different by place of study*
	eststo clear
	
	reg vig_per i.cadre i.vig_education if year == 1 ///
	, cluster(commid)
		estimates store uni1
	
	reg vig_per i.cadre i.urban i.vig_education i.province if year == 1 ///
	, cluster(commid)
		estimates store uni2

	reg vig_per i.cadre i.urban experience i.training_ncd ///
	i.diabetes_training i.drugs_training i.private_fac i.vig_education ///
	i.province if year == 1, ///
	cluster(commid)
		estimates store uni3

	************************************************
	**************ROBUSTNESS CHECKS*****************
	************************************************
	
	eststo clear
	
	*original Model 3
		reg vig_per i.year i.cadre i.urban experience i.training_ncd ///
		i.diabetes_training i.drugs_training i.private_fac i.province, cluster(commid)
		estimates store adjusted_final
	
	*Check #1: community level FE only
		reg vig_per i.year i.cadre i.urban experience i.training_ncd ///
		i.diabetes_training i.drugs_training i.private_fac i.commid, cluster(commid)
		estimates store robust_one
	
	*Check #2: community level RE and province FE
	
	xtset commid
	
	xtreg vig_per i.year i.cadre i.urban experience i.training_ncd ///
	i.diabetes_training i.drugs_training i.private_fac i.province, re cluster(commid)
	estimates store robust_two

