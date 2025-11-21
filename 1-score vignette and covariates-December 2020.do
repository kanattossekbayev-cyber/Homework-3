
/*

Code by Dorit Stein
dorittalia@gmail.com

For analysis in: 
Stein DT, Sudharsanan N, Dewi S, Manne-Goehler J, Witoelar F, Geldsetzer P. Change in clinical knowledge of diabetes among primary healthcare providers in Indonesia: repeated cross-sectional survey of 5105 primary healthcare facilities. BMJ Open Diabetes Research and Care. 2020 Oct 1;8(1):e001415.


This script (2 of 3) scores the diabetes care vignette and generates relevant covariates.

*/

********************************************
****SCORE VIGNETTES****
********************************************
	set more off

clear all

* Set user and the directory (YOUR path)
global dir "C:\Users\User\Desktop\HW3"
global raw "$dir"
global output "$dir"

	
	use "$output/full-vignette.dta", replace

	*use "$output/4-5-vignette-full-data.dta", replace
	
	*score
	*remove unecessary columns 
		*chest x-ray
		drop h28a
		drop hpr28a
		*ultrasound
		drop h28f
		drop hpr28f
		*sputum exam 
		drop h28c
		drop hpr28c
	
	*add up all responses with a 1
	
	*loop through and keep 1s but put 0 for 2 + 3 so can add up for score
	
	///ESSENTIAL ITEMS FIRST///
	
	foreach x of varlist hpr25a-hpr29h {
	gen `x'_1 = . 
	replace  `x'_1 = 1 if `x' == 1
	replace `x'_1 = 0 if `x' == 2 | `x' == 3 | `x' == 9
	}
	
	foreach x of varlist h25a-h29h {
	gen `x'_1 = .
	replace  `x'_1 = 1 if `x' == 1
	replace `x'_1 = 0 if `x' == 2 | `x' == 3 | `x' == 9 
	}
	
	
	drop h25f_1 h25g_1 h25h_1 h25o_1 h25q_1 h26n_1 h27b_1 h27d_1 ///
	h27f_1 h27i_1 h27j_1 h28d_1 h28e_1 h28g_1 h28i_1 h29c_1
	drop hpr25f_1 hpr25g_1 hpr25h_1 hpr25o_1 hpr25q_1 hpr26n_1 hpr27b_1 hpr27d_1 ///
	hpr27f_1 hpr27i_1 hpr27j_1 hpr28d_1 hpr28e_1 hpr28g_1 hpr28i_1 hpr29c_1
	
	*add up each row of responses and divide by 38 for score (ESSENTIAL)
	egen vig_total1 = rowtotal(h25a_1-h29h_1) if fac_type == "pusk"
	replace vig_total1 = . if fac_type == "private"
	egen vig_total2 = rowtotal(hpr25a_1-hpr29h_1) if fac_type == "private"
	replace vig_total2 = . if fac_type == "pusk"
	
	gen vig_total = .
	replace vig_total = vig_total1 if fac_type == "pusk"
	replace vig_total = vig_total2 if fac_type == "private"
	
	gen vig_score = .
	replace vig_score = vig_total/38
	
	
	label var vig_score "ESSENTIAL Vignette Score"
	
	sum vig_score
	sum vig_score if fac_type == "pusk"
	sum vig_score if fac_type == "private"
	
	*format commid and year	
	destring commid07, replace
	destring commid14, replace
	
	gen commid = . 
	replace commid = commid14 if commid07 == . 
	replace commid = commid07 if commid14 == . 
	
	*year variable
	gen year = " " 
	replace year = "1" if wave == "five"
	replace year = "0" if wave == "four"
	destring year, replace
	label def year 1 "2014" 0 "2007"
	label value year year
	
	*cadre
	gen cadre = . 
	replace cadre = 1 if h17 == 1 | h17 == 2
	replace cadre = 2 if h17 == 3 //nurse
	replace cadre = 3 if h17 == 4 //midwife
	replace cadre = 4 if h17 == 5 //paramedic
	
	label def cadre 1 "doctor" 2 "nurse" ///
	3 "midwife" 4 "paramedic"
	label value cadre cadre
	
	tab cadre, generate(cadre)
	label def cadre1 0 "Non-physician" 1 "medical or specialist doctor"
	label value cadre1 cadre1
	label def cadre22 0 "Non-nurse" 1 "Nurse"
	label value cadre2 cadre22
	label def cadre3 0 "Non-midwife" 1 "Midwife"
	label value cadre3 cadre3
	label def cadre4 0 "Non-paramedic" 1 "Paramedic"
	label value cadre4 cadre4
	
	gen vig_per = vig_score *100
	label var vig_per "Essential vignette percent"
	
	drop if commid == 9999
	
	gen private_fac = " "
	replace private_fac = "1" if fac_type == "private"
	replace private_fac = "0" if fac_type == "pusk"
	destring private_fac, replace
	lab def private_fac 1 "private" 0 "puskesmas"
	lab var private_fac private_fac
	
	label var h20_2 "received NCD training"
	rename h20_2 training_ncd
	label var h18 "when did head complete training"
	rename h18 complete_ed
	
	*training relabel
	replace training_ncd = . if training_ncd == 9
	replace training_ncd = 0 if training_ncd == 3
	replace training_ncd = 0 if h19 == 3 
	*h19 asks if they had training (360 said no)
	tab training_ncd year, missing
	
	label def training_ncd 0 "No Training" 1 "Yes Training"
	label value training_ncd training_ncd
	
	*interactions
	gen privxtime = private_fac*year
	
	gen phys = 1 if cadre == 1
	replace phys = 0 if cadre ~= 1
	gen physxtime = phys*year 
	
	gen nurse = 1 if cadre == 2 | cadre == 3
	replace nurse = 0 if cadre == 1 | cadre == 4
	gen nursextime = nurse*year
	
	gen priv_nurse = 0
	replace priv_nurse = 1 if nurse == 1 & private_fac == 1
	gen pnursextime = priv_nurse * year

	rename lk05 urban 
	replace urban = 1 if urban == 1
	replace urban = 0 if urban == 2
	label def urban 1 "Urban" 0 "Rural"
	label value urban urban
	
	*trained in last 10 years
	gen train_ten = . 
	replace train_ten = 0 if complete_ed < 1997 & year == 0
	replace train_ten = 0 if complete_ed < 2004 & year == 1
	replace train_ten = 1 if complete_ed >= 1997 & year == 0
	replace train_ten = 1 if complete_ed >= 2004 & year == 1
	replace train_ten = . if complete_ed == 9998
	
	*years of experience 
	replace complete_ed = . if complete_ed == 9998
	gen experience = . 
	replace experience = (2007 - complete_ed) if year == 0
	replace experience = (2014 - complete_ed) if year == 1
	replace experience = 0 if year == 0 & complete_ed == 2008
	replace experience = 0 if year == 1 & complete_ed == 2015
	
	label def private_fac2 1 "Private" 0 "Public" 
	label value private_fac private_fac2
	
	gen logexperience = log(experience)
	
	drop if urban == .
	drop if experience == .
	drop if training == .
	
	*pull out province code from commid for IFLS 4 facilities
	*make commid string to subset first 2 digits
	tostring commid, gen(commid_string) 
	gen province = substr(commid_string, 1, 2)
	destring province, replace
	
	label def province 12 "North Sumatra" 13 "West Sumatra" 16 "South Sumatra" 18 "Lampung" ///
	31 "Jakarta" 32 "West Java" 33 "Central Java" 34 "Yogyakarta" 35 "East Java" ///
	51 "Bali" 52 "West Nusa Tenggara" 63 "South Kalimantan" 73 "South Sulawesi"
	label val province province
	
	*name of private facility type
	rename lk13 priv_type
	label def priv_type 1 "Private Physician" 2 "Clinic" 3 "Midwife" ///
	4 "Paramedic/Nurse" 5 "Village Midwife"
	label val priv_type priv_type
	
	*type of public
	rename lk11 pub_type
	label def pub_type 1 "Puskesmas" 2 "Puskesmas Pembantu"
	label val pub_type pub_type
	
	*outer java-bali and java-bali 
	gen outer_javabali = 0
	replace outer_javabali = 1 if province == 12 | province == 13 | ///
	province == 16 | province == 18 | ///
	province == 73 | province == 63 | province == 52
	
	label def outer_javabali 0 "Java/Bali" 1 "Outer Java/Bali"
	label val outer_javabali outer_javabali
	
	*java and non-java
	gen non_java = 0
	replace non_java = 1 if province == 51 | province == 12 | province == 13 | ///
	province == 16 | province == 18 | ///
	province == 73 | province == 63 | province == 52
	
	*remove strings in fascode so can destring
	gen byte notnumeric = real(fascode)==.
	
	replace fascode = "0232050" if fascode == "023205B"    
	replace fascode = "7305150" if fascode == "73C515A"
	destring fascode, gen(fcode)
	
	*make FCODEd variable that has FCODE with COMMID embedded in it
	gen fcode2 = " "
	replace fcode2 = fcode14 if fcode07 == ""
	replace fcode2 = fcode07 if fcode14 == ""
	*remove strings in fascode so can destring
	gen byte fnotnumeric = real(fcode2)==.
	
	replace fcode2 = "12242050" if fcode2 == "1224205B"    
	replace fcode2 = "99995150" if fcode2 == "9999515A"
	destring fcode2, gen(fcode3)
	
	**DIABETES TRAINING**
	*code Ever had Diabetes training WITH DRUGS
		*#4 - regarding/concerning drugs for diabetes
			*1 - Yes, 3 - No
	*hpr20_4 IFLS4/5 - private
	*h20_4 IFLS4/5 - public
	*h19 is have you had training since you graduated, 
	*so 3 = NO and then would be NO for all subsequent training questions
	
	*indicators for training - non-mutually exclusive 
	*ever had ncd training, diabetes training with drugs, diabetes training
	
	gen drugs_training = . 
	replace drugs_training = 1 if hpr20_4 == 1 | h20_4 == 1
	replace drugs_training = 0 if hpr20_4 == 3 | h20_4 == 3
	replace drugs_training = 0 if h19 == 3
	label var drugs_training "Ever had Diabetes Training with Drugs"
	label def drugs_training 1 "Yes Drugs Training" 0 "No Drugs Training"
	label val drugs_training drugs_training
	
	*Ever had Diabetes training 
	gen diabetes_training = . 
	replace diabetes_training = 1 if hpr20_3 == 1 | h20_3 == 1
	replace diabetes_training = 0 if hpr20_3 == 3 | h20_3 == 3
	replace diabetes_training = 0 if h19 == 3
	label var diabetes_training "Ever had Diabetes Training" 
	label def diabetes_training 1 "Yes Diabetes Training" 0 "No Diabetes Training"
	label val diabetes_training diabetes_training
	
	*leveled variable for no diabetes training, diabetes training with no drugs only, diabetes training with drugs
	gen training_levels = .
	replace training_levels = 0 if h19 == 3 | drugs_training == 0 | diabetes_training == 0
	replace training_levels = 1 if diabetes_training == 1 & drugs_training == 0
	replace training_levels = 2 if drugs_training == 1
	label var training_levels "No, Diabetes, Drug Training Levels"
	label def training_levels 0 "No Training" 1 "Diabetes training" 2 "Diabetes with drug training"
	label val training_levels training_levels
	
	*respondents who said no training since graduation 
	*h19
	
	*make categories of experience
	gen exp_level = .
	replace exp_level = 0 if experience <= 5
	replace exp_level = 1 if experience > 5 & experience <= 10
	replace exp_level = 2 if experience > 10 & experience <= 20
	replace exp_level = 3 if experience > 20 & experience != .
	label var exp_level "Categories of experience"
	label def exp_level 0 "Less than or equal to 5" 1 "5-10" 2 "10-20" 3 "20+"
	label val exp_level exp_level
	
	
	save "$output/vignette-scores-provider-level8.dta", replace
