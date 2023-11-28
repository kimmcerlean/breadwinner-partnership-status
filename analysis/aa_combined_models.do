*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* combined_models.do
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* This file estimates initial models testing simpler v. more complicated
* measures of household changes

* Files used were created in sipp14_bw_descriptives and sipp96_bw_descriptives
* Note: we are currently not using the models here, but this combined file
* is then used for the decomposition, so this step is still needed. 
* I have commented out the models for now, in case we ever revisit - there
* was too much collinearity.

********************************************************************************
* First need to append the 2014 and 1996 files
********************************************************************************

local keep_vars "SSUID year PNUM firstyr spart_num ageb1 educ race avg_earn avg_mo_hrs birth bw50 bw50L bw60 bw60L trans_bw50 trans_bw60 trans_bw60_alt trans_bw60_alt2 coh_diss coh_mar durmom durmom_1st earn_change earn_change_hh earn_change_oth earn_change_raw earn_change_raw_hh earn_change_raw_oth earn_change_raw_sp earn_change_sp earn_gain earn_lose earn_non earndown8 earndown8_all earndown8_hh earndown8_hh_all earndown8_oth earndown8_oth_all earndown8_sp earndown8_sp_all earnings earnings_a_sp earnings_mis earnings_ratio earnings_sp earnup8 earnup8_all earnup8_hh earnup8_hh_all earnup8_oth earnup8_oth_all earnup8_sp earnup8_sp_all firstbirth yrfirstbirth full_no full_no_sp full_part full_part_sp gain_partner hh_earn hh_gain hh_gain_earn hh_lose hh_lose_earn avg_hhsize st_hhsize end_hhsize st_minorchildren end_minorchildren hours_change hours_change_sp avg_mo_hrs_sp hours_up5 hours_up5_all hours_up5_sp hours_up5_sp_all hoursdown5 hoursdown5_all hoursdown5_sp hoursdown5_sp_all lost_partner marr_coh marr_diss marr_wid mom_gain_earn mom_lose_earn momdown_othdown momdown_partdown momno_hhdown momno_othdown momno_othleft momno_partdown momno_relend momup_only momup_othdown momup_othleft momup_othup momup_partdown momup_partup momup_relend monthsobserved monthsobservedL nmos_bw50 nmos_bw60 no_full no_full_sp no_job_chg no_job_chg_sp no_part no_part_sp no_status_chg non_earn numearner oth_gain_earn oth_lose_earn other_earn other_earner part_full part_full_sp part_gain_earn part_lose_earn part_no part_no_sp resp_earn resp_non sing_coh sing_mar tage ageb1_mon thearn thearn_alt tpearn tpearn_mis wage_chg wage_chg_sp wagesdown8 wagesdown8_all wagesdown8_sp wagesdown8_sp_all wagesup8 wagesup8_all wagesup8_sp wagesup8_sp_all wpfinwgt correction momup_anydown momup_anyup momno_anydown momdown_anydown ageb1_gp status_b1 minors_fy mom_panel partner_gain partner_lose st_marital_status end_marital_status start_marital_status last_marital_status scaled_weight rmwkwjb educ_sp race_sp weeks_employed_sp"

// 1996 file
use "$SIPP96keep/96_bw_descriptives.dta", clear
gen correction=1

keep `keep_vars'

save "$tempdir/sipp96_to_append.dta", replace

// 2014 file
use "$SIPP14keep/bw_descriptives.dta", clear

rename avg_hrs 		avg_mo_hrs
rename hours_sp		avg_mo_hrs_sp
rename tage_fb 		ageb1_mon

gen yrfirstbirth_ch=year if firstbirth==1
bysort SSUID PNUM (yrfirstbirth_ch): replace yrfirstbirth_ch=yrfirstbirth_ch[1]
// browse SSUID PNUM year mom_panel firstbirth yrfirstbirth yrfirstbirth_ch

keep `keep_vars' st_occ_* end_occ_* st_tjb*_occ end_tjb*_occ program_income tanf_amount rtanfyn rtanfcov eeitc st_partner_earn end_partner_earn sex_sp

append using "$tempdir/sipp96_to_append.dta"

gen survey=.
replace survey=1996 if inrange(year,1995,2000)
replace survey=2014 if inrange(year,2013,2016)

// Missing value check - key IVs (DV handled elsewhere / meant to have missing because not always eligible, etc.)
tab race, m
tab educ, m // .02%
drop if educ==.
tab last_marital_status, m // .02%
drop if last_marital_status==.

// adding in lookups for poverty thresholds
browse year SSUID end_hhsize end_minorchildren

merge m:1 year end_hhsize end_minorchildren using "$projcode/stata/poverty_thresholds.dta"

browse year SSUID end_hhsize end_minorchildren threshold

drop if _merge==2
drop _merge

save "$combined_data/combined_annual_bw_status.dta", replace

/* investigations
browse earnup8_all earndown8_hh_all earn_lose if dv==1
browse SSUID PNUM year earnup8_all earndown8_hh_all earn_lose earn_change earn_change_sp earn_change_hh earn_change_raw earnings earnings_a_sp hh_earn earn_change_hh dv bw60 trans_bw60 // if dv==1

browse SSUID PNUM year earnup8_all earndown8_hh_all earn_lose bw60 trans_bw60 trans_bw60_alt if inlist(SSUID, "000418500162", "000418209903", "000418334944")
browse momup_only momup_anydown momup_othleft momup_anyup momno_hhdown momno_othleft momdown_anydown dv // if dv==1
*/

********************************************************************************
* now specify models
********************************************************************************
/*
gen dv=trans_bw60==1
replace dv=. if trans_bw60==. // recoding so only can be 0 or 1 - currently has missing values because we have been counting first year as "ineligible" since we don't know history. decide if that should stay?

gen dv_alt = trans_bw60_alt==1
replace dv_alt=. if trans_bw60_alt==. // recode from step 9 - some mothers not tracked until a later year in our sample, so this has more missing to account for loss of history prior to that.

// base models
local simple "earnup8_all earndown8_hh_all earn_lose"
local overlap "momup_only momup_anydown momup_othleft momup_anyup momno_hhdown momno_othleft momdown_anydown"
logistic dv i.year `simple'
logistic dv i.year `overlap'
logistic dv i.survey `simple' i.survey#i.(`simple')
logistic dv i.survey `overlap' i.survey#i.(`overlap')

// Making specification of earn_lose that is mutually exclusive
gen earnup_excl=earnup8_all
replace earnup_excl=0 if earn_lose==1
gen earndown_excl=earndown8_hh_all
replace earndown_excl=0 if earn_lose==1
*/

/*
*****************************************************************************************
**Rest of below is me trying to figure out the collinearity problem

// QA-ing
local simple "earnup8_all earndown8_hh_all earn_lose"
logistic dv i.year `simple'
logistic dv_alt i.year `simple'
logistic dv i.survey#i.(`simple')
logistic dv_alt i.survey#i.(`simple') // this doesn't solve the problem

local overlap "momup_only momup_anydown momup_othleft momup_anyup momno_hhdown momno_othleft momdown_anydown"
logistic dv i.year `overlap'
logistic dv_alt i.year `overlap'
logistic dv i.survey#i.(`overlap')
logistic dv_alt i.survey#i.(`overlap') // this doesn't solve the problem

// testing if it works even for just two variables at a time - it doesn't
foreach var in momup_anydown momup_othleft momup_anyup momno_hhdown momno_othleft momdown_anydown{
	logistic dv i.survey#i.momup_only i.survey#i.`var'
}

foreach var in  momup_only momup_othleft momup_anyup momno_hhdown momno_othleft momdown_anydown{
	logistic dv i.survey#i.momup_anydown i.survey#i.`var'
}


// creating my own interactions - but this pools across 1996 and 2014 for the 0s (bc multiplying by 0). it gives me results, but not quite apples to apples. think understating 1996 and over-stating 2014.
gen earnup_sur= earnup8_all * survey
gen earndown_sur = earndown8_hh_all * survey
gen earnlose_sur = earn_lose * survey
gen earnup_excl_sur= earnup_excl * survey
gen earndown_excl_sur = earndown_excl * survey

foreach var in momup_only momup_anydown momup_othleft momup_anyup momno_hhdown momno_othleft momdown_anydown{
    gen `var'_sur = `var' * survey
}

logistic dv i.earnup_sur i.earndown_sur i.earnlose_sur // this works but no main effect - so I *think* base is 0 pooled across 1996 and 2014, then interaction is just 1 in each year. could this work?
logistic dv i.survey earnup8_all earndown8_hh_all earn_lose i.earnup_sur i.earndown_sur i.earnlose_sur // when i add both main effects, collinear again
logistic dv earnup8_all earndown8_hh_all earn_lose i.earnup_sur i.earndown_sur i.earnlose_sur // okay so JUST predictor main effects - also collinear
logistic dv i.survey i.earnup_sur i.earndown_sur i.earnlose_sur // just survey main effect - works, but interpretation seems wonky

logistic dv i.momup_only_sur i.momup_anydown_sur i.momup_othleft_sur i.momup_anyup_sur i.momno_hhdown_sur i.momno_othleft_sur i.momdown_anydown_sur

/*
// trying to make it 1v2 to split out base - doesn't avoid the collinearity
gen earnup_alt = earnup8_all+1
gen earndown_alt = earndown8_hh_all+1
gen earnlose_alt = earn_lose+1

gen earnupalt_sur= earnup_alt * survey
gen earndownalt_sur = earndown_alt * survey
gen earnlosealt_sur = earnlose_alt * survey

logistic dv i.earnupalt_sur i.earndownalt_sur i.earnlosealt_sur // okay and back to same problems
*/

// base models with fit statistics
local simple "earnup8_all earndown8_hh_all earn_lose"
local overlap "momup_only momup_anydown momup_othleft momup_anyup momno_hhdown momno_othleft momdown_anydown"

logistic dv i.year `simple'
est store m1
fitstat
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 1) dec(2) alpha(0.001, 0.01, 0.05) replace 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 1) dec(2) eform alpha(0.001, 0.01, 0.05) append 

logistic dv i.year `overlap'
est store m2
fitstat
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 2) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 2) dec(2) eform alpha(0.001, 0.01, 0.05) append 

lrtest m1 m2, stats
// fitstat, using(m1)
// helpful ref for calculations: https://stats.idre.ucla.edu/stata/webbooks/logistic/chapter3/lesson-3-logistic-regression-diagnostics/
// pseudo R2 = (null-model) / null

logistic dv i.earnup_sur i.earndown_sur i.earnlose_sur
est store m3
fitstat
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 3) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 3) dec(2) eform alpha(0.001, 0.01, 0.05) append 

logistic dv i.momup_only_sur i.momup_anydown_sur i.momup_othleft_sur i.momup_anyup_sur i.momno_hhdown_sur i.momno_othleft_sur i.momdown_anydown_sur
est store m4
fitstat
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 4) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 4) dec(2) eform alpha(0.001, 0.01, 0.05) append 

lrtest m3 m4, stats

// alt specification for earn_lose such that if an earner leaves, other changes coded as 0
logistic dv i.year earnup_excl earndown_excl earn_lose
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 5) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 5) dec(2) eform alpha(0.001, 0.01, 0.05) append 

logistic dv i.earnup_excl_sur i.earndown_excl_sur i.earnlose_sur
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 6) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 6) dec(2) eform alpha(0.001, 0.01, 0.05) append 

// continuous IV specification
* first need to recode such that if earnings went from 0 to something, they are coded as changing (currently not the case, bc can't divide by zero)
sum earn_change
gen earn_change_rec = (earn_change - r(min)) / (r(max) - r(min)) if earn_change >=0
replace earn_change_rec = (earn_change - r(min)) / (r(min) - r(max)) if earn_change <0
replace earn_change_rec =0 if earn_change==0
replace earn_change_rec=1 if mom_gain_earn==1
replace earn_change_rec=-1 if mom_lose_earn==1

sum earn_change_hh
gen earn_change_hh_rec = (earn_change_hh - r(min)) / (r(max) - r(min)) if earn_change_hh >=0
replace earn_change_hh_rec = (earn_change_hh - r(min)) / (r(min) - r(max)) if earn_change_hh <0
replace earn_change_hh_rec =0 if earn_change_hh==0
replace earn_change_hh_rec=1 if hh_gain_earn==1
replace earn_change_hh_rec=-1 if hh_lose_earn==1

sum earn_change
gen earn_change2 = (earn_change - r(min)) / (r(max) - r(min)) // keeping on 0 to 1 is working better then -1 to 1 because not symmetrical

sum earn_change_hh
gen earn_change_hh2 = (earn_change_hh - r(min)) / (r(max) - r(min))

logistic dv i.year earn_lose earn_change2 earn_change_hh2
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 7) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 7) dec(2) eform alpha(0.001, 0.01, 0.05) append 

logistic dv i.survey#earn_lose i.survey#c.earn_change2 i.survey#c.earn_change_hh2
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 8) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 8) dec(2) eform alpha(0.001, 0.01, 0.05) append

logistic dv i.year earn_lose earn_change earn_change_hh
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 9) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 9) dec(2) eform alpha(0.001, 0.01, 0.05) append


*********************************************************************
** More investigating

corr earnup8_all earndown8_hh_all  earn_lose if dv==1
corr dv earnup8_all earndown8_hh_all earn_lose
corr dv earnup8_all earndown8_hh_all earn_lose if dv==1

gen dv_nom = dv

corr dv_nom earnup8_all earndown8_hh_all earn_lose if dv_nom==1
replace dv_nom=0 if dv_nom==. // okay def don't use this because the variables can't have 1 values in the first year (and that is where the missing come from)
collin earnup8_all earndown8_hh_all earn_lose

gen survey_test = 1 // wondering if getting messed up with use of 1996 and 2014
replace survey_test = 2 if survey == 2014

** testing making own interactions to test collinearity
cap drop earnup_sur 
cap drop earndown_sur 
cap drop earnlose_sur 

gen earnup_sur= earnup8_all * survey_test
gen earndown_sur = earndown8_hh_all * survey_test
gen earnlose_sur = earn_lose * survey_test

collin earnup_sur earndown_sur earnlose_sur dv

logistic dv i.survey_test earnup8_all earndown8_hh_all earn_lose i.earnup_sur i.earndown_sur i.earnlose_sur

logistic dv i.survey_test i.earnup_sur i.earndown_sur i.earnlose_sur // works with just interactions but this seems flawed...

/* https://www.statalist.org/forums/forum/general-stata-discussion/general/1297011-omitted-because-of-collinearity - see response number 6

"I guess I know what is going on. You are logging your dependent variable, which means that observations where the dependent variable is equal to zero are dropped. Therefore, dummy variables that are equal to 1 only when the dependent variable is zero will be identically zero in the sample used in the estimation. These will, of course, be dropped because of collinearity. I have discussed a similar problem in this paper. As an aside, it is a bad idea to estimate the model taking logs of a dependent variable that ca be zero; have a look here and here."
*/

// adding interactions - testing many things
local simple "earnup8_all earndown8_hh_all earn_lose"
logistic dv i.survey_test `simple' i.survey_test#i.(`simple')
logistic dv i.survey `simple' i.survey#i.(`simple')
logistic dv_nom i.survey `simple' i.survey#i.(`simple')
logistic dv i.year `simple' i.year#i.(`simple')
logistic dv_nom i.year `simple' i.year#i.(`simple')

// outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 3) dec(2) alpha(0.001, 0.01, 0.05) append 
// outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 3) dec(2) eform alpha(0.001, 0.01, 0.05) append 

logistic dv i.survey `overlap' i.survey#i.(`overlap')
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 4) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 4) dec(2) eform alpha(0.001, 0.01, 0.05) append

// by year, because so much collinearity in 2014 - this works, but changes interpretation bc base of 2014 is so different
logistic dv i.year `simple' if survey==1996
outreg2 using "$results/regression_by_year.xls", sideway stats(coef se pval) label ctitle(1996 1) dec(2) alpha(0.001, 0.01, 0.05) replace 
outreg2 using "$results/regression_by_year.xls", sideway stats(coef) label ctitle(1996 1) dec(2) eform alpha(0.001, 0.01, 0.05) append 

logistic dv i.year `overlap' if survey==1996
outreg2 using "$results/regression_by_year.xls", sideway stats(coef se pval) label ctitle(1996 2) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression_by_year.xls", sideway stats(coef) label ctitle(1996 2) dec(2) eform alpha(0.001, 0.01, 0.05) append  

logistic dv i.year `simple' if survey==2014
outreg2 using "$results/regression_by_year.xls", sideway stats(coef se pval) label ctitle(2014 1) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression_by_year.xls", sideway stats(coef) label ctitle(2014 1) dec(2) eform alpha(0.001, 0.01, 0.05) append 

logistic dv i.year `overlap' if survey==2014
outreg2 using "$results/regression_by_year.xls", sideway stats(coef se pval) label ctitle(2014 2) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression_by_year.xls", sideway stats(coef) label ctitle(2014 2) dec(2) eform alpha(0.001, 0.01, 0.05) append  


// seeing if estimating by group helps - it doesn't.
local simple "earnup8_all earndown8_hh_all earn_lose"
logistic dv i.survey `simple' i.survey#i.(`simple') if educ==2

local overlap "momup_only momup_anydown momup_othleft momup_anyup momno_hhdown momno_othleft momdown_anydown"
logistic dv i.survey `overlap' i.survey#i.(`overlap') if educ==2

// testing dur mom instead of year as discrete time for interactions
drop if durmom<0

logistic dv i.durmom `simple' i.survey#i.(`simple')
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 3a) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 3a) dec(2) eform alpha(0.001, 0.01, 0.05) append 

local overlap "momup_only momup_anydown momup_othleft momup_anyup momno_hhdown momno_othleft momdown_anydown"
logistic dv i.durmom `overlap' i.survey#i.(`overlap')
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 4a) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 4a) dec(2) eform alpha(0.001, 0.01, 0.05) append 

/*
Likelihood-ratio test                                 LR chi2(4)  =    143.63
(Assumption: m1 nested in m2)                         Prob > chi2 =    0.0000
*/

/* okay didn't work because survey encompasses year - leaving for reference
logistic dv i.year i.survey `simple'
est store m3
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 3) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 3) dec(2) eform alpha(0.001, 0.01, 0.05) append 

logistic dv i.year i.survey  `overlap'
est store m4
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 4) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 4) dec(2) eform alpha(0.001, 0.01, 0.05) append 

lrtest m3 m4

Likelihood-ratio test                                 LR chi2(4)  =    143.63
(Assumption: m3 nested in m4)                         Prob > chi2 =    0.0000

drop if durmom < 0
logistic dv i.durmom `simple' // testing durmom - okay also very similar results/regression
*/

********************************************************************************
* Models by demographics
********************************************************************************

// Education

// recode 1st 2 categories bc of sample
recode educ (1/2=1) (3=2) (4=3), gen(educ_gp)
label define educ_gp 1 "HS or less" 2 "Some College" 3 "College Plus"
label values educ_gp educ_gp

local simple "earnup8_all earndown8_hh_all earn_lose"
local overlap "momup_only momup_anydown momup_othleft momup_anyup momno_hhdown momno_othleft momdown_anydown"

putexcel set "$results/regression_educ.xls", replace

forvalues e=1/3{
	logistic dv i.year `simple' if educ_gp==`e'
	fitstat
	est store m1`e'
	outreg2 using "$results/regression_educ.xls", sideway stats(coef) label ctitle(Model 1: `e') dec(2) eform alpha(0.001, 0.01, 0.05) append
	logistic dv i.year `overlap' if educ_gp==`e'
	fitstat
	est store m2`e'
	outreg2 using "$results/regression_educ.xls", sideway stats(coef) label ctitle(Model 2: `e') dec(2) eform alpha(0.001, 0.01, 0.05) append 
	logistic dv i.earnup_sur i.earndown_sur i.earnlose_sur if educ_gp==`e'
	fitstat
	est store m3`e'
	outreg2 using "$results/regression_educ.xls", sideway stats(coef) label ctitle(Model 3: `e') dec(2) eform alpha(0.001, 0.01, 0.05) append 
	logistic dv i.momup_only_sur i.momup_anydown_sur i.momup_othleft_sur i.momup_anyup_sur i.momno_hhdown_sur i.momno_othleft_sur i.momdown_anydown_sur if educ_gp==`e'
	fitstat
	est store m4`e'
	outreg2 using "$results/regression_educ.xls", sideway stats(coef) label ctitle(Model 4: `e') dec(2) eform alpha(0.001, 0.01, 0.05) append 	
}

drop _est

// Race
local simple "earnup8_all earndown8_hh_all earn_lose"
local overlap "momup_only momup_anydown momup_othleft momup_anyup momno_hhdown momno_othleft momdown_anydown"

putexcel set "$results/regression_race.xls", replace

forvalues r=1/4{
	logistic dv i.year `simple' if race==`r'
	fitstat
	est store m1`r'
	outreg2 using "$results/regression_race.xls", sideway stats(coef) label ctitle(Model 1: `r') dec(2) eform alpha(0.001, 0.01, 0.05) append
	logistic dv i.year `overlap' if race==`r'
	fitstat
	est store m2`r'
	outreg2 using "$results/regression_race.xls", sideway stats(coef) label ctitle(Model 2: `r') dec(2) eform alpha(0.001, 0.01, 0.05) append 
	logistic dv i.earnup_sur i.earndown_sur i.earnlose_sur if race==`r'
	fitstat
	est store m3`r'
	outreg2 using "$results/regression_race.xls", sideway stats(coef) label ctitle(Model 3: `r') dec(2) eform alpha(0.001, 0.01, 0.05) append 
	logistic dv i.momup_only_sur i.momup_anydown_sur i.momup_othleft_sur i.momup_anyup_sur i.momno_hhdown_sur i.momno_othleft_sur i.momdown_anydown_sur if race==`r'
	fitstat
	est store m4`r'
	outreg2 using "$results/regression_race.xls", sideway stats(coef) label ctitle(Model 4: `r') dec(2) eform alpha(0.001, 0.01, 0.05) append 	
}

drop _est*

// Age at first birth
local simple "earnup8_all earndown8_hh_all earn_lose"
local overlap "momup_only momup_anydown momup_othleft momup_anyup momno_hhdown momno_othleft momdown_anydown"

putexcel set "$results/regression_age_birth.xls", replace

forvalues a=1/5{
	logistic dv i.year `simple' if ageb1_gp==`a'
	fitstat
	est store m1`a'
	outreg2 using "$results/regression_age_birth.xls", sideway stats(coef) label ctitle(Model 1: `a') dec(2) eform alpha(0.001, 0.01, 0.05) append
	logistic dv i.year `overlap' if ageb1_gp==`a'
	fitstat
	est store m2`a'
	outreg2 using "$results/regression_age_birth.xls", sideway stats(coef) label ctitle(Model 2: `a') dec(2) eform alpha(0.001, 0.01, 0.05) append 
	logistic dv i.earnup_sur i.earndown_sur i.earnlose_sur if ageb1_gp==`a'
	fitstat
	est store m3`a'
	outreg2 using "$results/regression_age_birth.xls", sideway stats(coef) label ctitle(Model 3: `a') dec(2) eform alpha(0.001, 0.01, 0.05) append 
	logistic dv i.momup_only_sur i.momup_anydown_sur i.momup_othleft_sur i.momup_anyup_sur i.momno_hhdown_sur i.momno_othleft_sur i.momdown_anydown_sur if ageb1_gp==`a'
	fitstat
	est store m4`a'
	outreg2 using "$results/regression_age_birth.xls", sideway stats(coef) label ctitle(Model 4: `a') dec(2) eform alpha(0.001, 0.01, 0.05) append 	
}


drop _est*

// Marital Status at first birth
local simple "earnup8_all earndown8_hh_all earn_lose"
local overlap "momup_only momup_anydown momup_othleft momup_anyup momno_hhdown momno_othleft momdown_anydown"

putexcel set "$results/regression_age_status.xls", replace

forvalues s=1/2{
	logistic dv i.year `simple' if status_b1==`s'
	fitstat
	est store m1`s'
	outreg2 using "$results/regression_age_status.xls", sideway stats(coef) label ctitle(Model 1: `s') dec(2) eform alpha(0.001, 0.01, 0.05) append
	logistic dv i.year `overlap' if status_b1==`s'
	fitstat
	est store m2`s'
	outreg2 using "$results/regression_age_status.xls", sideway stats(coef) label ctitle(Model 2: `s') dec(2) eform alpha(0.001, 0.01, 0.05) append 
	logistic dv i.earnup_sur i.earndown_sur i.earnlose_sur if status_b1==`s'
	fitstat
	est store m3`s'
	outreg2 using "$results/regression_age_status.xls", sideway stats(coef) label ctitle(Model 3: `s') dec(2) eform alpha(0.001, 0.01, 0.05) append 
	logistic dv i.momup_only_sur i.momup_anydown_sur i.momup_othleft_sur i.momup_anyup_sur i.momno_hhdown_sur i.momno_othleft_sur i.momdown_anydown_sur if status_b1==`s'
	fitstat
	est store m4`s'
	outreg2 using "$results/regression_age_status.xls", sideway stats(coef) label ctitle(Model 4: `s') dec(2) eform alpha(0.001, 0.01, 0.05) append 	
}

