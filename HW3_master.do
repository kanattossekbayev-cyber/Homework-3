************************************************************
* HW3 MASTER DO-FILE
* Replication of Stein et al. (2020) + AIPW Extension
* Author: Kanat Tossekbayev
************************************************************

clear all
set more off

************************************************************
* 0. Set working directory
************************************************************
cd "C:\Users\User\Desktop\HW3"

************************************************************
* 1. Merge and score data (original authors' scripts)
*    Assumes these do-files are already edited to use this folder
************************************************************

* Merge vignette data from IFLS4 and IFLS5
do "0-merge data-December 2020.do"

* Score vignette and create provider-level dataset
do "1-score vignette and covariates-December 2020.do"

************************************************************
* 2. Load provider-level data for replication & extension
************************************************************
use "vignette-scores-provider-level8.dta", clear

* Quick check of survey years
tab year
tab wave

************************************************************
* 3. Replication: main regression models (OLS)
************************************************************

* Install estout if not yet installed
capture which esttab
if _rc ssc install estout, replace

* Model 1: year only
reg vig_per i.year, vce(robust)
estimates store model1

* Model 2: year + cadre + urban + province
reg vig_per i.year i.cadre i.urban i.province, vce(robust)
estimates store model2

* Model 3: fully adjusted model
reg vig_per i.year i.cadre i.urban ///
    experience i.training_ncd i.diabetes_training i.drugs_training ///
    i.private_fac i.province, vce(robust)
estimates store model3

* Export replication table to RTF/Word
esttab model1 model2 model3 using "replication_results.rtf", replace ///
    se label star(* 0.10 ** 0.05 *** 0.01) ///
    title("Replication of Stein et al. (2020): Main Models") ///
    b(%9.3f) se(%9.3f)

************************************************************
* 4. (Optional) Coefficient plot for Models 1–3
************************************************************

* Install coefplot if needed
capture which coefplot
if _rc ssc install coefplot, replace

* Simple coefficient plot: year effect across models
coefplot ///
    (model1, label("Model 1")) ///
    (model2, label("Model 2")) ///
    (model3, label("Model 3")), ///
    keep(1.year) ///
    xline(0) ///
    xlabel(-12(2)4) ///
    legend(pos(6) ring(0)) ///
    title("Effect of 2014 (vs 2007) on Essential Vignette Score") ///
    xtitle("Percentage points")

graph export "coefplot_year_effect_models1_3.png", replace

************************************************************
* 5. AIPW Extension: Causal Effect of Year (2014 vs 2007)
************************************************************

* Treatment indicator: post = 1 if 2014, 0 if 2007
capture drop post
generate post = year
label define postlbl 0 "2007" 1 "2014"
label values post postlbl

* Check treatment distribution
tab post

* Check for missing covariates (for documentation)
misstable summarize vig_per cadre urban experience ///
    training_ncd diabetes_training drugs_training ///
    private_fac province year

* Create indicator of missingness (not strictly needed, but useful)
egen miss_any = rowmiss(vig_per cadre urban experience ///
    training_ncd diabetes_training drugs_training ///
    private_fac province year)

tab miss_any

* Keep only complete cases (if any missing)
keep if miss_any == 0

* AIPW estimation
teffects aipw ///
    (vig_per i.cadre i.urban experience i.training_ncd i.diabetes_training ///
             i.drugs_training i.private_fac i.province) ///
    (post     i.cadre i.urban experience i.training_ncd i.diabetes_training ///
             i.drugs_training i.private_fac i.province), ///
    vce(robust)

* The output will show ATE and POmean. For this dataset we obtained:
* ATE (post 1 vs 0) = -7.084407, SE = 0.5028577, 95% CI [-8.06999, -6.098824]
* POmean(post = 0)  = 36.66991, SE = 0.3884616

************************************************************
* 6. AIPW Figure: Point estimate and 95% CI
*    (Using the estimated numbers above)
************************************************************

matrix A = (-7.084407, -8.06999, -6.098824)

* A[1,1] = ATE
* A[1,2] = lower CI
* A[1,3] = upper CI

twoway ///
    (rcap A[1,2] A[1,3] 1, horizontal) ///
    (scatter A[1,1] 1), ///
    xlabel(-12(2)4) ///
    yscale(range(0.5 1.5)) ///
    ylab(1 "ATE 2014 vs 2007", nogrid) ///
    xtitle("Average Treatment Effect (percentage points)") ///
    title("AIPW Estimate of Year Effect with 95% CI") ///
    legend(off)

graph export "AIPW_ATE_plot.png", replace

************************************************************
* 7. Save log (optional)
************************************************************

* If you want a log file, uncomment the following lines:
* log using "HW3_master_log.smcl", replace
* (run the whole script)
* log close
************************************************************
* END OF MASTER DO-FILE
************************************************************
