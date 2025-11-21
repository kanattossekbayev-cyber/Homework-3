
/*

Code by Dorit Stein
dorittalia@gmail.com

For analysis in: 
Stein DT, Sudharsanan N, Dewi S, Manne-Goehler J, Witoelar F, Geldsetzer P. Change in clinical knowledge of diabetes among primary healthcare providers in Indonesia: repeated cross-sectional survey of 5105 primary healthcare facilities. BMJ Open Diabetes Research and Care. 2020 Oct 1;8(1):e001415.


This script (1 of 3) merges data from two waves of the Indonesia Family Life Survey (wave 4 and 5). Relevant data files are available in the Harvard Dataverse. 

*/

********************************************
****CLEAN AND MERGE Vignette DATA WITHIN IFLS4****
********************************************

***************************************************
*00. Public 2007
***************************************************
set more off
clear all

* Set user and the directory (YOUR path)
global dir "C:\Users\User\Desktop\HW3"
global raw "$dir"
global output "$dir"

	*without SAR - use COMMID07 in pusk and pra books 
	
	*load label sort Puskesmas data 2007
	use "$raw/4-pusk.dta", replace
	drop if h15 == 3 | h15 == .
			
	gen fac_type = " " 
	replace fac_type = "pusk"
	
	gen wave = " "
	replace wave = "four"
	
	sort fcode07 commid07
	
	rename a10 dual
	label def dual 1 "Yes" 3 "No"
	label val dual dual
	
	*657 providers
	***BEFORE: 941 facilities
	save "$raw/4-pusk-v2.dta", replace

***************************************************
*00. Private 2007
***************************************************

	**merge private provider knowledge data
	clear all 
	use "$raw/4-pra.dta"
	
	drop if hpr15 == 3 | hpr15 == .
	*drop if hpr25a-hpr29h == .
	
	sort fcode07 commid07
	*add columns with fac and year identifiers
	gen fac_type = " " 
	replace fac_type = "private"
	
	gen wave = " "
	replace wave = "four"
	
	*559 private providers 2007
	save "$raw/4-pra-v2.dta", replace
	
*APPEND
	append using "$raw/4-pusk-v2.dta", force
	
	save "$output/4-vignette.dta", replace
	
	*1215 observations total (2007)
	
********************************************
****CLEAN AND MERGE Vignette DATA WITHIN IFLS5****
********************************************

***************************************************
*00. Preamble
***************************************************
	* Set user and the directory (YOUR path)
global dir "C:\Users\User\Desktop\HW3"
global raw "$dir"
global output "$dir"


***************************************************
*00. Public 2014
***************************************************
	*public provider data
	*load in vignette data

	clear all
	
	use "$raw/5-pusk_vig.dta", replace
	drop if h15 == 3 | h15 == 7| h15 == .
	
	gen fac_type = " " 
	replace fac_type = "pusk"
	
	gen wave = " "
	replace wave = "five"
	
	merge 1:1 fascode ea using "$raw/5-pusk.dta", gen(merge_pusk)
	*not matched are 960-815 = 145 (146 really) who did not provide diabetes care
	keep if merge_pusk == 3
	drop merge_pusk
	
	rename a10 dual
	label def dual 1 "Yes" 3 "No"
	label val dual dual
	
	save "$raw/5-pusk-v2.dta", replace

***************************************************
*00. Private 2014
***************************************************
***add in private provider vignette from IFLS5
	use "$raw/5-pra.dta", replace
	
	*drop if not interviewed
	drop if result == 3

	save "$raw/5-pra-v2.dta", replace
	
	*private vignette data
	use "$raw/5-pra_vig.dta", replace
	*1598 total
	drop if hpr15 == 3 | hpr15 == 7 | hpr15 == .
	*1598-919 = 679 left
	sort fascode ea

	merge 1:1 fascode ea using "$raw/5-pra-v2.dta", gen(merge_pra)
	keep if merge_pra == 3
	drop merge_pra
	
	gen fac_type = " " 
	replace fac_type = "private"
	
	gen wave = " "
	replace wave = "five"
	
*APPEND
	append using "$raw/5-pusk-v2.dta", force
	
	*1494 facilities 2014
***************************************************
*00. APPEND 2007 + 2014
***************************************************
	append using "$output/4-vignette.dta", force
	
	*drop extraneous variables for now, can get them back later
	replace h15 = hpr15 if h15 == .
	drop hpr15
	
	replace h17 = hpr17 if h17 == .
	drop hpr17
	
	replace h17a = hpr17a if h17a == .
	drop hpr17a
	
	replace h18 = hpr18 if h18 == .
	drop hpr18
	
	replace h19 = hpr19 if h19 == .
	drop hpr19
	
	replace h20_2 = hpr20_2 if h20_2 == . 
	drop hpr20_2
	
	replace h21_2 = hpr21_2 if h21_2 == .
	drop hpr21_2
	
	replace h22_2 = hpr22_2 if h22_2 == .
	drop hpr22_2
	
	
	save "$output/full-vignette.dta", replace
	

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
