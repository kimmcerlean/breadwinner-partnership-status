*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* decomposition_equation.do
* Kim McErlean
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* This file creates Tables 1-4 for the paper (basic descriptives of the sample)
* as well as tables for the results of the decomposition equation

* File used was created in ab_decomposition_equation.do
* Note: this relies on macros created in step ab, so cannot run this in isolation

use "$tempdir/combined_bw_equation_desc.dta", clear // created in step ab

********************************************************************************
* Creating tables for paper
********************************************************************************

// Table 1: Sample descriptives
putexcel set "$results/Breadwinner_Predictor_Tables", sheet(Table1) replace
putexcel A1:D1 = "Unweighted Ns", merge border(bottom) hcenter bold
putexcel B2 = "Total Sample"
putexcel C2 = "1996 SIPP"
putexcel D2 = "2014 SIPP"
putexcel A3 = "No. of respondents"
putexcel A4 = "No. of person-years"
putexcel A5 = "No. of transitions to primary earning status"
putexcel A6:D6 = "Weighted Descriptives", merge border(bottom) hcenter bold
putexcel A7 = "Median HH income at time t-1 (inflation-adjusted)"
putexcel A8 = "Mothers' median income at time t-1 (inflation-adjusted)"
putexcel A9 = "Race/ethnicity (time-invariant)"
putexcel A10 = "Non-Hispanic White", txtindent(4)
putexcel A11 = "Black", txtindent(4)
putexcel A12 = "Non-Hispanic Asian", txtindent(4)
putexcel A13 = "Hispanic", txtindent(4)
putexcel A14 = "Education (time-varying)"
putexcel A15 = "Less than HS", txtindent(4)
putexcel A16 = "HS Degree", txtindent(4)
putexcel A17 = "Some College", txtindent(4)
putexcel A18 = "College Plus", txtindent(4)
putexcel A19 = "Relationship Status (time-varying)"
putexcel A20 = "Married", txtindent(4)
putexcel A21 = "Cohabitating", txtindent(4)
putexcel A22 = "Single", txtindent(4)
putexcel A23 = "Age at first birth (time-invariant)"
putexcel A24 = "Younger than 20", txtindent(4)
putexcel A25 = "20-24", txtindent(4)
putexcel A26 = "25-29", txtindent(4)
putexcel A27 = "Older than 30", txtindent(4)
putexcel A28 = "Marital Status at first birth (time-invariant)"
putexcel A29 = "Married", txtindent(4)
putexcel A30 = "Never Married", txtindent(4)

putexcel F2 = "2014: Ever BW"
putexcel G2 = "2014: Never BW"

putexcel I1:L1 = "1996", merge border(bottom) hcenter bold
putexcel I2 = "Became BW"
putexcel J2 = "BW at Birth"
putexcel K2 = "BW at Birth: Always"
putexcel L2 = "Always BW"
putexcel M1:P1 = "2014", merge border(bottom) hcenter bold
putexcel M2 = "Became BW"
putexcel N2 = "BW at Birth"
putexcel O2 = "BW at Birth: Always"
putexcel P2 = "Always BW"

// First create a variable for ever breadwinning status
/* this was made somewhere else?
gen bw60_all = bw60_mom
replace bw60_all = 0 if mom_panel==1 & year < yrfirstbirth
bysort SSUID PNUM (bw60_all): egen ever_bw60 = max(bw60_all)
*/
bysort SSUID PNUM (bw50): egen ever_bw50 = max(bw50)
browse SSUID PNUM year bw60 trans_bw60_alt2 firstbirth yrfirstbirth bw60_mom bw60_all ever_bw60

tab ever_bw60 if survey_yr==2
unique SSUID PNUM if survey_yr==2, by(ever_bw60)

*Transitions
gen eligible=(bw60lag==0)
replace eligible=. if bw60lag==.
gen transitioned=0
replace transitioned=1 if trans_bw60_alt2==1 & bw60lag==0
replace transitioned=. if trans_bw60_alt2==.
// svy: tab eligible, obs
// this is what it needs to match: svy: tab survey trans_bw60_alt2 if bw60lag==0, row

local colu "C D"

// there is probably a more efficient way to do this but I am currently struggling

*Sample total
forvalues y=1/2{
	local col: word `y' of `colu'
	egen total_N_`y' = nvals(id) if survey_yr==`y'
	sum total_N_`y'
	replace total_N_`y' = r(mean)
	local total_N_`y' = total_N_`y'
	putexcel `col'3= `total_N_`y'', nformat(###,###)
	egen total_PY_`y' = count(id) if survey_yr==`y'
	sum total_PY_`y'
	replace total_PY_`y' = r(mean)
	local total_PY_`y' = total_PY_`y'
	putexcel `col'4= `total_PY_`y'', nformat(###,###)
}

// total
egen total_N = nvals(id) 
global total_N = total_N
putexcel B3 = $total_N, nformat(###,###)
egen total_PY = count(id)
global total_PY = total_PY
putexcel B4 = $total_PY, nformat(###,###)

// 2014 - ever BW status
egen total_N_ever14 = nvals(id) if survey_yr==2 & ever_bw60==1
sum total_N_ever14
replace total_N_ever14 = r(mean)
global total_N_ever14 = total_N_ever14
putexcel F3 = $total_N_ever14, nformat(###,###)
egen total_PY_ever14 = count(id) if survey_yr==2 & ever_bw60==1
sum total_PY_ever14
replace total_PY_ever14 = r(mean)
global total_PY_ever14 = total_PY_ever14
putexcel F4 = $total_PY_ever14, nformat(###,###)

egen total_N_never14 = nvals(id) if survey_yr==2 & ever_bw60==0
sum total_N_never14
replace total_N_never14 = r(mean)
global total_N_never14 = total_N_never14
putexcel G3 = $total_N_never14, nformat(###,###)
egen total_PY_never14 = count(id) if survey_yr==2 & ever_bw60==0
sum total_PY_never14
replace total_PY_never14 = r(mean)
global total_PY_never14 = total_PY_never14
putexcel G4 = $total_PY_never14, nformat(###,###)

// Comparison mothers
local colu1 "I M"
local colu2 "J N"
local colu3 "K O"
local colu4 "L P"

forvalues y=1/2{
	local col1: word `y' of `colu1'
	local col2: word `y' of `colu2'
	local col3: word `y' of `colu3'
	local col4: word `y' of `colu4'
			
	egen trans_N_`y' = nvals(id) if survey_yr==`y' & transitioned==1
	sum trans_N_`y'
	replace trans_N_`y' = r(mean)
	local trans_N_`y' = trans_N_`y'
	putexcel `col1'3= `trans_N_`y'', nformat(###,###)
	egen trans_PY_`y' = count(id) if survey_yr==`y' & transitioned==1
	sum trans_PY_`y'
	replace trans_PY_`y' = r(mean)
	local trans_PY_`y' = trans_PY_`y'
	putexcel `col1'4= `trans_PY_`y'', nformat(###,###)
	
	egen birth_N_`y' = nvals(id) if survey_yr==`y' & bw_at_birth==1
	sum birth_N_`y'
	replace birth_N_`y' = r(mean)
	local birth_N_`y' = birth_N_`y'
	putexcel `col2'3= `birth_N_`y'', nformat(###,###)
	egen birth_PY_`y' = count(id) if survey_yr==`y' & bw_at_birth==1
	sum birth_PY_`y'
	replace birth_PY_`y' = r(mean)
	local birth_PY_`y' = birth_PY_`y'
	putexcel `col2'4= `birth_PY_`y'', nformat(###,###)
	
	egen birth2_N_`y' = nvals(id) if survey_yr==`y' & bw_at_birth==1 & always_bw==1
	sum birth2_N_`y'
	replace birth2_N_`y' = r(mean)
	local birth2_N_`y' = birth2_N_`y'
	putexcel `col3'3= `birth2_N_`y'', nformat(###,###)
	egen birth2_PY_`y' = count(id) if survey_yr==`y' & bw_at_birth==1 & always_bw==1
	sum birth2_PY_`y'
	replace birth2_PY_`y' = r(mean)
	local birth2_PY_`y' = birth2_PY_`y'
	putexcel `col3'4= `birth2_PY_`y'', nformat(###,###)	
	
	egen always_N_`y' = nvals(id) if survey_yr==`y' & always_bw==1
	sum always_N_`y'
	replace always_N_`y' = r(mean)
	local always_N_`y' = always_N_`y'
	putexcel `col4'3= `always_N_`y'', nformat(###,###)
	egen always_PY_`y' = count(id) if survey_yr==`y' & always_bw==1
	sum always_PY_`y'
	replace always_PY_`y' = r(mean)
	local always_PY_`y' = always_PY_`y'
	putexcel `col4'4= `always_PY_`y'', nformat(###,###)
}

local colu "C D"

forvalues y=1/2{
	local col: word `y' of `colu'
	** sum eligible if survey_yr==`y'
	** putexcel `col'5=(`r(mean)'*`r(N)'), nformat(###,###)
	sum transitioned if survey_yr==`y'
	putexcel `col'5=(`r(mean)'*`r(N)'), nformat(###,###)
}

** sum eligible
** putexcel B5=(`r(mean)'*`r(N)'), nformat(###,###)
sum transitioned
putexcel B5=(`r(mean)'*`r(N)'), nformat(###,###)

*Income 
* HH
sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID  [aweight=wpfinwgt], detail // is this t-1?
putexcel B7=`r(p50)', nformat(###,###)
sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 [aweight=wpfinwgt], detail // is this t-1?
putexcel C7=`r(p50)', nformat(###,###)
sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 [aweight=wpfinwgt], detail
putexcel D7=`r(p50)', nformat(###,###)
sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ever_bw60==1 [aweight=wpfinwgt], detail
putexcel F7=`r(p50)', nformat(###,###)
sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ever_bw60==0 [aweight=wpfinwgt], detail
putexcel G7=`r(p50)', nformat(###,###)

sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & transitioned==1 [aweight=wpfinwgt], detail
putexcel I7=`r(p50)', nformat(###,###)
sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & bw_at_birth==1 [aweight=wpfinwgt], detail
putexcel J7=`r(p50)', nformat(###,###)
sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & bw_at_birth==1 & always_bw==1 [aweight=wpfinwgt], detail
putexcel K7=`r(p50)', nformat(###,###)
sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & always_bw==1 [aweight=wpfinwgt], detail
putexcel L7=`r(p50)', nformat(###,###)

sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & transitioned==1 [aweight=wpfinwgt], detail
putexcel M7=`r(p50)', nformat(###,###)
sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & bw_at_birth==1 [aweight=wpfinwgt], detail
putexcel N7=`r(p50)', nformat(###,###)
sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & bw_at_birth==1 & always_bw==1 [aweight=wpfinwgt], detail
putexcel O7=`r(p50)', nformat(###,###)
sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & always_bw==1 [aweight=wpfinwgt], detail
putexcel P7=`r(p50)', nformat(###,###)

*Mother
sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID [aweight=wpfinwgt], detail // is this t-1?
putexcel B8=`r(p50)', nformat(###,###)
sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 [aweight=wpfinwgt], detail // is this t-1?
putexcel C8=`r(p50)', nformat(###,###)
sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 [aweight=wpfinwgt], detail 
putexcel D8=`r(p50)', nformat(###,###)
sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ever_bw60==1 [aweight=wpfinwgt], detail 
putexcel F8=`r(p50)', nformat(###,###)
sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ever_bw60==0 [aweight=wpfinwgt], detail 
putexcel G8=`r(p50)', nformat(###,###)

sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & transitioned==1 [aweight=wpfinwgt], detail
putexcel I8= `r(p50)', nformat(###,###)
sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & bw_at_birth==1 [aweight=wpfinwgt], detail
putexcel J8=`r(p50)', nformat(###,###)
sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & bw_at_birth==1 & always_bw==1 [aweight=wpfinwgt], detail
putexcel K8=`r(p50)', nformat(###,###)
sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & always_bw==1 [aweight=wpfinwgt], detail
putexcel L8=`r(p50)', nformat(###,###)

sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & transitioned==1 [aweight=wpfinwgt], detail
putexcel M8=`r(p50)', nformat(###,###)
sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & bw_at_birth==1 [aweight=wpfinwgt], detail
putexcel N8=`r(p50)', nformat(###,###)
sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & bw_at_birth==1 & always_bw==1 [aweight=wpfinwgt], detail
putexcel O8=`r(p50)', nformat(###,###)
sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & always_bw==1 [aweight=wpfinwgt], detail
putexcel P8=`r(p50)', nformat(###,###)

* Race
tab race [aweight=wpfinwgt], gen(race)
// test: svy: mean race1

local colu "C D"
local i=1

foreach var in race1 race2 race3 race4{
		
		forvalues y=1/2{
			local col: word `y' of `colu'
			local row = `i'+9
			svy: mean `var' if survey_yr==`y'
			matrix `var'_`y' = e(b)
			putexcel `col'`row' = matrix(`var'_`y'), nformat(#.##%)
		}
		
		svy: mean `var'
		matrix `var' = e(b)
		putexcel B`row' = matrix(`var'), nformat(#.##%)
		svy: mean `var' if survey_yr==2 & ever_bw60==1
		matrix `var'_ever = e(b)
		putexcel F`row' = matrix(`var'_ever), nformat(#.##%)
		svy: mean `var' if survey_yr==2 & ever_bw60==0
		matrix `var'_never = e(b)
		putexcel G`row' = matrix(`var'_never), nformat(#.##%)
		local ++i
	}

* Education
tab educ [aweight=wpfinwgt], gen(educ)
tab educ_gp  [aweight=wpfinwgt], gen(educ_gp)
// test: svy: mean educ1

local colu "C D"
local i=1

foreach var in educ1 educ2 educ3 educ4{
		
		forvalues y=1/2{
			local col: word `y' of `colu'
			local row = `i'+14
			svy: mean `var' if survey_yr==`y'
			matrix `var'_`y' = e(b)
			putexcel `col'`row' = matrix(`var'_`y'), nformat(#.##%)
		}
		
		svy: mean `var'
		matrix `var' = e(b)
		putexcel B`row' = matrix(`var'), nformat(#.##%)
		svy: mean `var' if survey_yr==2 & ever_bw60==1
		matrix `var'_ever = e(b)
		putexcel F`row' = matrix(`var'_ever), nformat(#.##%)
		svy: mean `var' if survey_yr==2 & ever_bw60==0
		matrix `var'_never = e(b)
		putexcel G`row' = matrix(`var'_never), nformat(#.##%)
		local ++i
	}
	

* Marital Status - December of prior year
recode last_marital_status (1=1) (2=2) (3/5=3), gen(marital_status_t1)
label define marr 1 "Married" 2 "Cohabiting" 3 "Single"
label values marital_status_t1 marr

// for JG ask 10/10/22
browse SSUID PNUM year earnings_adj thearn_adj bw60 bw50 earnings_ratio
tab marital_status_t1 bw60 if survey_yr==2, row // 15.41%
unique SSUID PNUM if survey_yr==2 & marital_status_t1==1, by(ever_bw60) // 1633 / 6288 = 25.9%

tab marital_status_t1 bw50 if survey_yr==2, row // 23.34%
unique SSUID PNUM if survey_yr==2 & marital_status_t1==1, by(ever_bw50) // 2251 / 6288 = 35.8%

// need just her percentage of partner earnings
gen wife_ratio = earnings_adj / (earnings_adj + earnings_sp_adj)
browse SSUID PNUM  earnings_adj earnings_sp_adj wife_ratio

gen wife_bw60=.
replace wife_bw60 =0 if wife_ratio <.60 & wife_ratio!=.
replace wife_bw60 =1 if wife_ratio >=.60 & wife_ratio!=.

gen wife_bw50=.
replace wife_bw50 =0 if wife_ratio <.50 & wife_ratio!=.
replace wife_bw50 =1 if wife_ratio >=.50 & wife_ratio!=.

gen wife_bw50_alt=.
replace wife_bw50_alt =0 if wife_ratio <=.50 & wife_ratio!=.
replace wife_bw50_alt =1 if wife_ratio >.50 & wife_ratio!=.

tab marital_status_t1 wife_bw60 if survey_yr==2, row // 18.91%
tab marital_status_t1 wife_bw50 if survey_yr==2, row // 28.30%
tab marital_status_t1 wife_bw50_alt if survey_yr==2, row // 27.49%

tab marital_status_t1 wife_bw60 if year==2016, row // 18.7%
tab year wife_bw60 if marital_status_t1 ==1 & survey_yr==2, row
tab marital_status_t1 wife_bw50 if year==2016, row // 28.1%
tab marital_status_t1 wife_bw50_alt if year==2016, row // 27.6%

tab marital_status_t1 [aweight=wpfinwgt], gen(marst)

local colu "C D"
local i=1

foreach var in marst1 marst2 marst3{
		
		forvalues y=1/2{
			local col: word `y' of `colu'
			local row = `i'+19
			svy: mean `var' if survey_yr==`y'
			matrix `var'_`y' = e(b)
			putexcel `col'`row' = matrix(`var'_`y'), nformat(#.##%)
		}
		
		svy: mean `var'
		matrix `var' = e(b)
		putexcel B`row' = matrix(`var'), nformat(#.##%)
		svy: mean `var' if survey_yr==2 & ever_bw60==1
		matrix `var'_ever = e(b)
		putexcel F`row' = matrix(`var'_ever), nformat(#.##%)
		svy: mean `var' if survey_yr==2 & ever_bw60==0
		matrix `var'_never = e(b)
		putexcel G`row' = matrix(`var'_never), nformat(#.##%)
		local ++i
	}

* Age at first birth
tab ageb1_cat [aweight=wpfinwgt], gen(ageb1)
// test: svy: mean ageb11

local colu "C D"
local i=1

foreach var in ageb11 ageb12 ageb13 ageb14{
		
		forvalues y=1/2{
			local col: word `y' of `colu'
			local row = `i'+23
			svy: mean `var' if survey_yr==`y'
			matrix `var'_`y' = e(b)
			putexcel `col'`row' = matrix(`var'_`y'), nformat(#.##%)
		}
		
		svy: mean `var'
		matrix `var' = e(b)
		putexcel B`row' = matrix(`var'), nformat(#.##%)
		svy: mean `var' if survey_yr==2 & ever_bw60==1
		matrix `var'_ever = e(b)
		putexcel F`row' = matrix(`var'_ever), nformat(#.##%)
		svy: mean `var' if survey_yr==2 & ever_bw60==0
		matrix `var'_never = e(b)
		putexcel G`row' = matrix(`var'_never), nformat(#.##%)
		local ++i
	}
	
* Marital Status at first birth
tab status_b1 [aweight=wpfinwgt], gen(status_b1)
// test: svy: mean status_b11

local colu "C D"
local i=1

foreach var in status_b11 status_b12{
		
		forvalues y=1/2{
			local col: word `y' of `colu'
			local row = `i'+28
			svy: mean `var' if survey_yr==`y'
			matrix `var'_`y' = e(b)
			putexcel `col'`row' = matrix(`var'_`y'), nformat(#.##%)
		}
		
		svy: mean `var'
		matrix `var' = e(b)
		putexcel B`row' = matrix(`var'), nformat(#.##%)
		svy: mean `var' if survey_yr==2 & ever_bw60==1
		matrix `var'_ever = e(b)
		putexcel F`row' = matrix(`var'_ever), nformat(#.##%)
		svy: mean `var' if survey_yr==2 & ever_bw60==0
		matrix `var'_never = e(b)
		putexcel G`row' = matrix(`var'_never), nformat(#.##%)
		local ++i
	}


// Comparison to other mothers
* Race
local colu1 "I M"
local colu2 "J N"
local colu3 "K O"
local colu4 "L P"
local i=1

foreach var in race1 race2 race3 race4{
		
		forvalues y=1/2{
			local col1: word `y' of `colu1'
			local col2: word `y' of `colu2'
			local col3: word `y' of `colu3'
			local col4: word `y' of `colu4'
			local row = `i'+9
			
			svy: mean `var' if survey_yr==`y' & transitioned==1
			matrix `var'_`y' = e(b)
			putexcel `col1'`row' = matrix(`var'_`y'), nformat(#.##%)
			
			svy: mean `var' if survey_yr==`y' & bw_at_birth==1
			matrix `var'_`y' = e(b)
			putexcel `col2'`row' = matrix(`var'_`y'), nformat(#.##%)
			
			svy: mean `var' if survey_yr==`y' & bw_at_birth==1 & always_bw==1
			matrix `var'_`y' = e(b)
			putexcel `col3'`row' = matrix(`var'_`y'), nformat(#.##%)

			svy: mean `var' if survey_yr==`y' & always_bw==1
			matrix `var'_`y' = e(b)
			putexcel `col4'`row' = matrix(`var'_`y'), nformat(#.##%)
		}
		local ++i
}

* Education
local colu1 "I M"
local colu2 "J N"
local colu3 "K O"
local colu4 "L P"
local i=1

foreach var in educ1 educ2 educ3 educ4{
		
		forvalues y=1/2{
			local col1: word `y' of `colu1'
			local col2: word `y' of `colu2'
			local col3: word `y' of `colu3'
			local col4: word `y' of `colu4'
			local row = `i'+14
			
			svy: mean `var' if survey_yr==`y' & transitioned==1
			matrix `var'_`y' = e(b)
			putexcel `col1'`row' = matrix(`var'_`y'), nformat(#.##%)
			
			svy: mean `var' if survey_yr==`y' & bw_at_birth==1
			matrix `var'_`y' = e(b)
			putexcel `col2'`row' = matrix(`var'_`y'), nformat(#.##%)
			
			svy: mean `var' if survey_yr==`y' & bw_at_birth==1 & always_bw==1
			matrix `var'_`y' = e(b)
			putexcel `col3'`row' = matrix(`var'_`y'), nformat(#.##%)

			svy: mean `var' if survey_yr==`y' & always_bw==1
			matrix `var'_`y' = e(b)
			putexcel `col4'`row' = matrix(`var'_`y'), nformat(#.##%)
		}
		local ++i
}	

* Marital Status - December of prior year
local colu1 "I M"
local colu2 "J N"
local colu3 "K O"
local colu4 "L P"
local i=1

foreach var in marst1 marst2 marst3{
		
		forvalues y=1/2{
			local col1: word `y' of `colu1'
			local col2: word `y' of `colu2'
			local col3: word `y' of `colu3'
			local col4: word `y' of `colu4'
			local row = `i'+19
			
			svy: mean `var' if survey_yr==`y' & transitioned==1
			matrix `var'_`y' = e(b)
			putexcel `col1'`row' = matrix(`var'_`y'), nformat(#.##%)
			
			svy: mean `var' if survey_yr==`y' & bw_at_birth==1
			matrix `var'_`y' = e(b)
			putexcel `col2'`row' = matrix(`var'_`y'), nformat(#.##%)
			
			svy: mean `var' if survey_yr==`y' & bw_at_birth==1 & always_bw==1
			matrix `var'_`y' = e(b)
			putexcel `col3'`row' = matrix(`var'_`y'), nformat(#.##%)

			svy: mean `var' if survey_yr==`y' & always_bw==1
			matrix `var'_`y' = e(b)
			putexcel `col4'`row' = matrix(`var'_`y'), nformat(#.##%)
		}
		local ++i
}	

* Age at first birth
local colu1 "I M"
local colu2 "J N"
local colu3 "K O"
local colu4 "L P"
local i=1

foreach var in ageb11 ageb12 ageb13 ageb14{
		
		forvalues y=1/2{
			local col1: word `y' of `colu1'
			local col2: word `y' of `colu2'
			local col3: word `y' of `colu3'
			local col4: word `y' of `colu4'
			local row = `i'+23
			
			svy: mean `var' if survey_yr==`y' & transitioned==1
			matrix `var'_`y' = e(b)
			putexcel `col1'`row' = matrix(`var'_`y'), nformat(#.##%)
			
			svy: mean `var' if survey_yr==`y' & bw_at_birth==1
			matrix `var'_`y' = e(b)
			putexcel `col2'`row' = matrix(`var'_`y'), nformat(#.##%)
			
			svy: mean `var' if survey_yr==`y' & bw_at_birth==1 & always_bw==1
			matrix `var'_`y' = e(b)
			putexcel `col3'`row' = matrix(`var'_`y'), nformat(#.##%)

			svy: mean `var' if survey_yr==`y' & always_bw==1
			matrix `var'_`y' = e(b)
			putexcel `col4'`row' = matrix(`var'_`y'), nformat(#.##%)
		}
		local ++i
}	

	
* Marital Status at first birth
local colu1 "I M"
local colu2 "J N"
local colu3 "K O"
local colu4 "L P"
local i=1

foreach var in status_b11 status_b12{
		
		forvalues y=1/2{
			local col1: word `y' of `colu1'
			local col2: word `y' of `colu2'
			local col3: word `y' of `colu3'
			local col4: word `y' of `colu4'
			local row = `i'+28
			
			svy: mean `var' if survey_yr==`y' & transitioned==1
			matrix `var'_`y' = e(b)
			putexcel `col1'`row' = matrix(`var'_`y'), nformat(#.##%)
			
			svy: mean `var' if survey_yr==`y' & bw_at_birth==1
			matrix `var'_`y' = e(b)
			putexcel `col2'`row' = matrix(`var'_`y'), nformat(#.##%)
			
			svy: mean `var' if survey_yr==`y' & bw_at_birth==1 & always_bw==1
			matrix `var'_`y' = e(b)
			putexcel `col3'`row' = matrix(`var'_`y'), nformat(#.##%)

			svy: mean `var' if survey_yr==`y' & always_bw==1
			matrix `var'_`y' = e(b)
			putexcel `col4'`row' = matrix(`var'_`y'), nformat(#.##%)
		}
		local ++i
}	

/* Marital Status - change in year

gen married = no_status_chg==1 & end_marital_status==1
gen cohab = no_status_chg==1 & end_marital_status==2
gen single = no_status_chg==1 & inlist(end_marital_status,3,4,5)

local status_vars "married cohab single sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh"

forvalues w=1/10 {
	forvalues y=1/2{
		local col: word `y' of `colu'
		local row = `w'+19
		local var: word `w' of `status_vars'
		egen n_`var'_`y' = count(id) if survey_yr==`y' & `var'==1
		sum n_`var'_`y'
		replace n_`var'_`y' = r(mean)
		local n_`var'_`y' = n_`var'_`y'
		putexcel `col'`row'= `n_`var'_`y'', nformat(###,###)
		}
		
	egen n_`var' = count(id) if `var'==1
	sum n_`var'
	replace n_`var' = r(mean)
	local n_`var' = n_`var'
	putexcel B`row'= `n_`var'', nformat(###,###)
}

forvalues w=1/10 {
	forvalues y=1/2{
		local col: word `y' of `colu'
		local row = `w'+19
		local var: word `w' of `status_vars'
		sum `var' if survey_yr==`y'
		putexcel `col'`row' = `r(mean)', nformat(#.##%)
		}
		
	sum `var'
	putexcel B`row' =`r(mean)', nformat(#.##%)
}
*/

*** t-tests from 1996 to 2014
// https://www.kaichen.work/?p=1095
gen earnings_ratio_mis=earnings_ratio
replace earnings_ratio_mis=0 if earnings_ratio==.

median thearn_adj, by(survey)
median thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID, by(survey)
median earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID, by(survey)
median earnings_ratio_mis if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID, by(survey)

ttest race1, by(survey) // white
ttest race2, by(survey) // black
ttest race3, by(survey) // asian
ttest race4, by(survey) // hispanic

ttest educ1, by(survey)
ttest educ2, by(survey)
ttest educ3, by(survey)
ttest educ4, by(survey)

ttest marst1, by(survey) // married
ttest marst2, by(survey) // cohab
ttest marst3, by(survey) // single

ttest ageb11, by(survey)
ttest ageb12, by(survey)
ttest ageb13, by(survey)
ttest ageb14, by(survey)

ttest status_b11, by(survey) // married
ttest status_b12, by(survey) // not

tab survey ft_partner_leave if trans_bw60_alt2==1 & bw60lag==0, row
ttest ft_partner_leave if trans_bw60_alt2==1 & bw60lag==0, by(survey)
ttest mt_mom if trans_bw60_alt2==1 & bw60lag==0, by(survey)
ttest ft_partner_down_only if trans_bw60_alt2==1 & bw60lag==0, by(survey)
ttest ft_partner_down_mom if trans_bw60_alt2==1 & bw60lag==0, by(survey)
ttest lt_other_changes if trans_bw60_alt2==1 & bw60lag==0, by(survey)

**# Table 2
putexcel set "$results/Breadwinner_Predictor_Tables", sheet(Table2) modify
putexcel A1:J1 = "Table 2. Mothers' transition rates into primary-earner status and precipitating events", merge
putexcel C2 = "Total", border(bottom)
putexcel D2:F2 = "Education", merge border(bottom) hcenter
putexcel G2:J2 = "Race / ethnicity", merge border(bottom) hcenter
putexcel K2:N2 = "Age at first birth", merge border(bottom) hcenter
putexcel O2:P2 = "Marital status at birth", merge border(bottom) hcenter
putexcel C3 = "Total", border(bottom)
putexcel D3 = "HS Degree or Less", border(bottom)
putexcel E3 = "Some College", border(bottom)
putexcel F3 = "College Plus", border(bottom)
putexcel G3 = "NH White", border(bottom)
putexcel H3 = "Black", border(bottom)
putexcel I3 = "NH Asian", border(bottom)
putexcel J3 = "Hispanic", border(bottom)
putexcel K3 = "Younger than 20", border(bottom)
putexcel L3 = "20-24", border(bottom)
putexcel M3 = "25-29", border(bottom)
putexcel N3 = "Older than 30", border(bottom)
putexcel O3 = "Married", border(bottom)
putexcel P3 = "Never Married", border(bottom)
putexcel A4:J4 = "A: Transition rate to primary-earning status", merge
putexcel A8:J8 = "B: All Incidents among non primary-earning mothers", merge
putexcel A24:J24 = "C: Incident precipitated transition to primary-earning", merge
putexcel A9 = ("Partner left") A25 = ("Partner left")
putexcel A12 = ("Mothers increase in earnings") A28 = ("Mothers increase in earnings")
putexcel A15 = ("Partner lost earnings") A31 = ("Partner lost earnings")
putexcel A18 = ("Mothers increase in earnings & partner lost earnings") A34 = ("Mothers increase in earnings & partner lost earnings")
putexcel A21 = ("Other member lost earnings / left") A37 = ("Other member lost earnings / left")
putexcel B5 = ("Total") B6 = ("1996") B7 = ("2014") 
putexcel B10 = ("1996") B13 = ("1996") B16 = ("1996") B19 = ("1996") B22 = ("1996")
putexcel B11 = ("2014") B14 = ("2014") B17 = ("2014") B20 = ("2014") B23 = ("2014")
putexcel B26 = ("1996") B29 = ("1996") B32 = ("1996") B35 = ("1996") B38 = ("1996")
putexcel B27 = ("2014") B30 = ("2014") B33 = ("2014") B36 = ("2014") B39 = ("2014")


* Total transition rate
svy: mean trans_bw60_alt2 if bw60lag==0
matrix bw60_total = e(b)
putexcel C5 = matrix(bw60_total), nformat(#.##%)

putexcel C6 = $bw_rate_96, nformat(#.##%)
putexcel C7 = $bw_rate_14, nformat(#.##%)

forvalues e=1/3{
	local column1 "D E F"
	local col1: word `e' of `column1'
	svy: mean trans_bw60_alt2 if bw60lag==0 & educ_gp==`e'
	matrix bw60_total_e`e' = e(b)
	putexcel `col1'5 = matrix(bw60_total_e`e'), nformat(#.##%)
	
	putexcel `col1'6 = ${bw_rate_96_e`e'}, nformat(#.##%)
	putexcel `col1'7 = ${bw_rate_14_e`e'}, nformat(#.##%)
}

forvalues r=1/4{
	local column1 "G H I J"
	local col1: word `r' of `column1'
	svy: mean trans_bw60_alt2 if bw60lag==0 & race==`r'
	matrix bw60_total_r`r' = e(b)
	putexcel `col1'5 = matrix(bw60_total_r`r'), nformat(#.##%)
	
	putexcel `col1'6 = ${bw_rate_96_r`r'}, nformat(#.##%)
	putexcel `col1'7 = ${bw_rate_14_r`r'}, nformat(#.##%)
}

forvalues a=1/4{
	local column1 "K L M N"
	local col1: word `a' of `column1'
	svy: mean trans_bw60_alt2 if bw60lag==0 & ageb1_cat==`a'
	matrix bw60_total_a`a' = e(b)
	putexcel `col1'5 = matrix(bw60_total_a`a'), nformat(#.##%)
	
	putexcel `col1'6 = ${bw_rate_96_a`a'}, nformat(#.##%)
	putexcel `col1'7 = ${bw_rate_14_a`a'}, nformat(#.##%)
}

forvalues s=1/2{
	local column1 "O P"
	local col1: word `s' of `column1'
	svy: mean trans_bw60_alt2 if bw60lag==0 & status_b1==`s'
	matrix bw60_total_s`s' = e(b)
	putexcel `col1'5 = matrix(bw60_total_s`s'), nformat(#.##%)
	
	putexcel `col1'6 = ${bw_rate_96_s`s'}, nformat(#.##%)
	putexcel `col1'7 = ${bw_rate_14_s`s'}, nformat(#.##%)
}


* Equation pieces

local i=1
local row1x "10 13 16 19 22"
local row2x "26 29 32 35 38"

foreach var in ft_partner_leave mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
		local row1: word `i' of `row1x'
		local row2: word `i' of `row2x'
		putexcel C`row1' = matrix(`var'_1), nformat(#.##%)
		putexcel C`row2' = matrix(`var'_1_bw), nformat(#.##%)
		local ++i
}

local i=1
local row1x "11 14 17 20 23"
local row2x "27 30 33 36 39"

foreach var in ft_partner_leave mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
		local row1: word `i' of `row1x'
		local row2: word `i' of `row2x'
		putexcel C`row1' = matrix(`var'_2), nformat(#.##%)
		putexcel C`row2' = matrix(`var'_2_bw), nformat(#.##%)
		local ++i
}

forvalues e=1/3{
local colu1 "D E F"
local row1x "10 13 16 19 22 11 14 17 20 23"
local row2x "26 29 32 35 38 27 30 33 36 39"

local i=1

	foreach var in ft_partner_leave mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
		local row1: word `i' of `row1x'
		local row2: word `i' of `row2x'
		local col: word `e' of `colu1'
		putexcel `col'`row1' = matrix(`var'_e`e'_1), nformat(#.##%)
		putexcel `col'`row2' = matrix(`var'_e`e'_1_bw), nformat(#.##%)
		local ++i
	}

	foreach var in ft_partner_leave mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
		local row1: word `i' of `row1x'
		local row2: word `i' of `row2x'
		local col: word `e' of `colu1'
		putexcel `col'`row1' = matrix(`var'_e`e'_2), nformat(#.##%)
		putexcel `col'`row2' = matrix(`var'_e`e'_2_bw), nformat(#.##%)
		local ++i
	}
}

forvalues r=1/4{
local colu1 "G H I J"
local row1x "10 13 16 19 22 11 14 17 20 23"
local row2x "26 29 32 35 38 27 30 33 36 39"

local i=1

	foreach var in ft_partner_leave mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
		local row1: word `i' of `row1x'
		local row2: word `i' of `row2x'
		local col: word `r' of `colu1'
		putexcel `col'`row1' = matrix(`var'_r`r'_1), nformat(#.##%)
		putexcel `col'`row2' = matrix(`var'_r`r'_1_bw), nformat(#.##%)
		local ++i
	}

	
	foreach var in ft_partner_leave mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
		local row1: word `i' of `row1x'
		local row2: word `i' of `row2x'
		local col: word `r' of `colu1'
		putexcel `col'`row1' = matrix(`var'_r`r'_2), nformat(#.##%)
		putexcel `col'`row2' = matrix(`var'_r`r'_2_bw), nformat(#.##%)
		local ++i
	}
}

forvalues a=1/4{
local colu1 "K L M N"
local row1x "10 13 16 19 22 11 14 17 20 23"
local row2x "26 29 32 35 38 27 30 33 36 39"

local i=1

	foreach var in ft_partner_leave mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
		local row1: word `i' of `row1x'
		local row2: word `i' of `row2x'
		local col: word `a' of `colu1'
		putexcel `col'`row1' = matrix(`var'_a`a'_1), nformat(#.##%)
		putexcel `col'`row2' = matrix(`var'_a`a'_1_bw), nformat(#.##%)
		local ++i
	}

	
	foreach var in ft_partner_leave mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
		local row1: word `i' of `row1x'
		local row2: word `i' of `row2x'
		local col: word `a' of `colu1'
		putexcel `col'`row1' = matrix(`var'_a`a'_2), nformat(#.##%)
		putexcel `col'`row2' = matrix(`var'_a`a'_2_bw), nformat(#.##%)
		local ++i
	}
}

forvalues s=1/2{
local colu1 "O P"
local row1x "10 13 16 19 22 11 14 17 20 23"
local row2x "26 29 32 35 38 27 30 33 36 39"

local i=1

	foreach var in ft_partner_leave mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
		local row1: word `i' of `row1x'
		local row2: word `i' of `row2x'
		local col: word `s' of `colu1'
		putexcel `col'`row1' = matrix(`var'_s`s'_1), nformat(#.##%)
		putexcel `col'`row2' = matrix(`var'_s`s'_1_bw), nformat(#.##%)
		local ++i
	}

	
	foreach var in ft_partner_leave mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
		local row1: word `i' of `row1x'
		local row2: word `i' of `row2x'
		local col: word `s' of `colu1'
		putexcel `col'`row1' = matrix(`var'_s`s'_2), nformat(#.##%)
		putexcel `col'`row2' = matrix(`var'_s`s'_2_bw), nformat(#.##%)
		local ++i
	}
}

**# Table 3: Change Components

putexcel set "$results/Breadwinner_Predictor_Tables", sheet(Table3) modify
putexcel A1 = "Component"
putexcel B1 = "Total"
putexcel C1:E1 = "Education", merge
putexcel F1:I1 = "Race / Ethnicity", merge
putexcel J1:M1 = "Age at first birth", merge
putexcel N1:O1 = "Marital status at first birth", merge
putexcel C2 = ("HS or Less") D2 = ("Some College") E2 = ("College Plus") 
putexcel F2 = ("NH White") G2 = ("Black") H2 = ("NH Asian") I2 = ("Hispanic") 
putexcel J2 = ("<20") K2 = ("20-24") L2 = ("25-29") M2 = (">30") 
putexcel N2 = ("Married") O2 = ("Never Married")
putexcel A3 = "Total Gap to Explain"
putexcel A4 = "Rate Component"
putexcel A5 = "Composition Component"
putexcel A6 = "Partner left"
putexcel A7 = "Mothers increase in earnings"
putexcel A8 = "Partner lost earnings"
putexcel A9 = "Mothers increase in earnings & partner lost earnings"
putexcel A10 = "Other member lost earnings / left"
putexcel A12 = "Partner left - rate"
putexcel A13 = "Mothers increase in earnings - rate"
putexcel A14 = "Partner lost earnings - rate"
putexcel A15 = "Mothers increase in earnings & partner lost earnings - rate"
putexcel A16 = "Other member lost earnings / left - rate"
putexcel A18 = "Partner left - comp"
putexcel A19 = "Mothers increase in earnings - comp"
putexcel A20 = "Partner lost earnings - comp"
putexcel A21 = "Mothers increase in earnings & partner lost earnings - comp"
putexcel A22 = "Other member lost earnings / left - comp"


putexcel B3 = $total_gap, nformat(#.##%)
putexcel B4 = formula($rate_diff / $total_gap), nformat(#.##%)
putexcel B5 = formula($comp_diff / $total_gap), nformat(#.##%)
putexcel B6 = $partner_leave_compt_x, nformat(#.##%)
putexcel B7 = $mom_compt_x, nformat(#.##%)
putexcel B8 = $partner_down_only_compt_x, nformat(#.##%)
putexcel B9 = $partner_down_mom_compt_x, nformat(#.##%)
putexcel B10 = $other_hh_compt_x, nformat(#.##%)
putexcel B12 = $partner_leave_compt_r, nformat(#.##%)
putexcel B13 = $mom_compt_r, nformat(#.##%)
putexcel B14 = $partner_down_only_compt_r, nformat(#.##%)
putexcel B15 = $partner_down_mom_compt_r, nformat(#.##%)
putexcel B16 = $other_hh_compt_r, nformat(#.##%)
putexcel B18 = $partner_leave_compt_c, nformat(#.##%)
putexcel B19 = $mom_compt_c, nformat(#.##%)
putexcel B20 = $partner_down_only_compt_c, nformat(#.##%)
putexcel B21 = $partner_down_mom_compt_c, nformat(#.##%)
putexcel B22 = $other_hh_compt_c, nformat(#.##%)


* Education and Race

local col1 "C D E"

forvalues e=1/3{
    local col: word `e' of `col1'
	putexcel `col'3 = ${total_gap_e`e'}, nformat(#.##%)
	putexcel `col'4 = formula(${rate_diff_e`e'} / ${total_gap_e`e'}), nformat(#.##%)
	putexcel `col'5 = formula(${comp_diff_e`e'} / ${total_gap_e`e'}), nformat(#.##%)
	putexcel `col'6 = ${partner_leave_component_e`e'}, nformat(#.##%)
	putexcel `col'7 = ${mom_component_e`e'}, nformat(#.##%)
	putexcel `col'8 = ${partner_down_only_component_e`e'}, nformat(#.##%)
	putexcel `col'9 = ${partner_down_mom_component_e`e'}, nformat(#.##%)
	putexcel `col'10 = ${other_hh_component_e`e'}, nformat(#.##%)
	putexcel `col'12 = ${partner_leave_component_e`e'_rt}, nformat(#.##%)
	putexcel `col'13 = ${mom_component_e`e'_rt}, nformat(#.##%)
	putexcel `col'14 = ${partner_down_only_comp_e`e'_rt}, nformat(#.##%)
	putexcel `col'15 = ${partner_down_mom_component_e`e'_rt}, nformat(#.##%)
	putexcel `col'16 = ${other_hh_component_e`e'_rt}, nformat(#.##%)
	putexcel `col'18 = ${partner_leave_component_e`e'_cp}, nformat(#.##%)
	putexcel `col'19 = ${mom_component_e`e'_cp}, nformat(#.##%)
	putexcel `col'20 = ${partner_down_only_comp_e`e'_cp}, nformat(#.##%)
	putexcel `col'21 = ${partner_down_mom_component_e`e'_cp}, nformat(#.##%)
	putexcel `col'22 = ${other_hh_component_e`e'_cp}, nformat(#.##%)
}

local col1 "F G H I"

forvalues r=1/4{
    local col: word `r' of `col1'
	putexcel `col'3 = ${total_gap_r`r'}, nformat(#.##%)
	putexcel `col'4 = formula(${rate_diff_r`r'} / ${total_gap_r`r'}), nformat(#.##%)
	putexcel `col'5 = formula(${comp_diff_r`r'} / ${total_gap_r`r'}), nformat(#.##%)
	putexcel `col'6 = ${partner_leave_component_r`r'}, nformat(#.##%)
	putexcel `col'7 = ${mom_component_r`r'}, nformat(#.##%)
	putexcel `col'8 = ${partner_down_only_component_r`r'}, nformat(#.##%)
	putexcel `col'9 = ${partner_down_mom_component_r`r'}, nformat(#.##%)
	putexcel `col'10 = ${other_hh_component_r`r'}, nformat(#.##%)
	putexcel `col'12 = ${partner_leave_component_r`r'_rt}, nformat(#.##%)
	putexcel `col'13 = ${mom_component_r`r'_rt}, nformat(#.##%)
	putexcel `col'14 = ${partner_down_only_comp_r`r'_rt}, nformat(#.##%)
	putexcel `col'15 = ${partner_down_mom_component_r`r'_rt}, nformat(#.##%)
	putexcel `col'16 = ${other_hh_component_r`r'_rt}, nformat(#.##%)
	putexcel `col'18 = ${partner_leave_component_r`r'_cp}, nformat(#.##%)
	putexcel `col'19 = ${mom_component_r`r'_cp}, nformat(#.##%)
	putexcel `col'20 = ${partner_down_only_comp_r`r'_cp}, nformat(#.##%)
	putexcel `col'21 = ${partner_down_mom_component_r`r'_cp}, nformat(#.##%)
	putexcel `col'22 = ${other_hh_component_r`r'_cp}, nformat(#.##%)
}

local col1 "J K L M"

forvalues a=1/4{
    local col: word `a' of `col1'
	putexcel `col'3 = ${total_gap_a`a'}, nformat(#.##%)
	putexcel `col'4 = formula(${rate_diff_a`a'} / ${total_gap_a`a'}), nformat(#.##%)
	putexcel `col'5 = formula(${comp_diff_a`a'} / ${total_gap_a`a'}), nformat(#.##%)
	putexcel `col'6 = ${partner_leave_component_a`a'}, nformat(#.##%)
	putexcel `col'7 = ${mom_component_a`a'}, nformat(#.##%)
	putexcel `col'8 = ${partner_down_only_component_a`a'}, nformat(#.##%)
	putexcel `col'9 = ${partner_down_mom_component_a`a'}, nformat(#.##%)
	putexcel `col'10 = ${other_hh_component_a`a'}, nformat(#.##%)
	putexcel `col'12 = ${partner_leave_component_a`a'_rt}, nformat(#.##%)
	putexcel `col'13 = ${mom_component_a`a'_rt}, nformat(#.##%)
	putexcel `col'14 = ${partner_down_only_comp_a`a'_rt}, nformat(#.##%)
	putexcel `col'15 = ${partner_down_mom_component_a`a'_rt}, nformat(#.##%)
	putexcel `col'16 = ${other_hh_component_a`a'_rt}, nformat(#.##%)
	putexcel `col'18 = ${partner_leave_component_a`a'_cp}, nformat(#.##%)
	putexcel `col'19 = ${mom_component_a`a'_cp}, nformat(#.##%)
	putexcel `col'20 = ${partner_down_only_comp_a`a'_cp}, nformat(#.##%)
	putexcel `col'21 = ${partner_down_mom_component_a`a'_cp}, nformat(#.##%)
	putexcel `col'22 = ${other_hh_component_a`a'_cp}, nformat(#.##%)
}

local col1 "N O"

forvalues s=1/2{
    local col: word `s' of `col1'
	putexcel `col'3 = ${total_gap_s`s'}, nformat(#.##%)
	putexcel `col'4 = formula(${rate_diff_s`s'} / ${total_gap_s`s'}), nformat(#.##%)
	putexcel `col'5 = formula(${comp_diff_s`s'} / ${total_gap_s`s'}), nformat(#.##%)
	putexcel `col'6 = ${partner_leave_component_s`s'}, nformat(#.##%)
	putexcel `col'7 = ${mom_component_s`s'}, nformat(#.##%)
	putexcel `col'8 = ${partner_down_only_component_s`s'}, nformat(#.##%)
	putexcel `col'9 = ${partner_down_mom_component_s`s'}, nformat(#.##%)
	putexcel `col'10 = ${other_hh_component_s`s'}, nformat(#.##%)
	putexcel `col'12 = ${partner_leave_component_s`s'_rt}, nformat(#.##%)
	putexcel `col'13 = ${mom_component_s`s'_rt}, nformat(#.##%)
	putexcel `col'14 = ${partner_down_only_comp_s`s'_rt}, nformat(#.##%)
	putexcel `col'15 = ${partner_down_mom_component_s`s'_rt}, nformat(#.##%)
	putexcel `col'16 = ${other_hh_component_s`s'_rt}, nformat(#.##%)
	putexcel `col'18 = ${partner_leave_component_s`s'_cp}, nformat(#.##%)
	putexcel `col'19 = ${mom_component_s`s'_cp}, nformat(#.##%)
	putexcel `col'20 = ${partner_down_only_comp_s`s'_cp}, nformat(#.##%)
	putexcel `col'21 = ${partner_down_mom_component_s`s'_cp}, nformat(#.##%)
	putexcel `col'22 = ${other_hh_component_s`s'_cp}, nformat(#.##%)
}

**# Table 4: Median Income Change
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2, detail  // pre 2014
sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2, detail // post 2014

sum thearn_adj if bw60==0 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2, detail  // pre 2014 - all
sum thearn_adj if bw60==0, detail // & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2, detail  // or is this all? but want to know we can track them into next year, which is what above does?
sum thearn_adj if bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2, detail // post 2014 - all
sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2, detail // post 2014 - bw
sum thearn_adj if bw60==0 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2, detail // post 2014 - not bw

sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & mt_mom[_n+1]==1, detail  // pre 2014
sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & mt_mom==1, detail // post 2014
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1, detail  // pre 2014
sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1, detail // post 2014
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_only[_n+1]==1, detail  // pre 2014
sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_only==1, detail // post 2014
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_leave[_n+1]==1, detail  // pre 2014
sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_leave==1, detail // post 2014
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & lt_other_changes[_n+1]==1, detail  // pre 2014
sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & lt_other_changes==1, detail // post 2014

sum thearn_adj if bw60==0 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_leave[_n+1]==1, detail  // pre 2014 all HHs
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_leave[_n+1]==1, detail  // pre 2014 -- HHs that become BW
sum thearn_adj if bw60==0 & bw60[_n+1]==0 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_leave[_n+1]==1, detail  // pre 2014 -- HHs that don't become BW

sum thearn_adj if bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_leave==1, detail // post 2014 - all // is this post or pre?
sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_leave==1, detail // post 2014 - BW
sum thearn_adj if bw60==0 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_leave==1, detail // post 2014 - not BW

putexcel set "$results/Breadwinner_Impact_Tables", sheet(Table1) replace
putexcel A1 = "category"
putexcel B1 = "label"
putexcel C1 = "time"
putexcel D1 = "year"
putexcel E1 = "dollars_adj"
putexcel A2:A7 = "Education"
putexcel A8:A15 = "Race"
putexcel A16:A17 = "Total"
putexcel B2:B3 = ("HS or Less") B4:B5 = ("Some College") B6:B7 = ("College Plus") 
putexcel B8:B9 = ("NH White") B10:B11 = ("Black") B12:B13 = ("NH Asian") B14:B15 = ("Hispanic") 
putexcel B16:B17 = "Total"
putexcel C2 = ("Post") C4 = ("Post") C6 = ("Post") C8 = ("Post") C10 = ("Post") C12 = ("Post") C14 = ("Post") C16 = ("Post")
putexcel C3 = ("Pre") C5 = ("Pre") C7 = ("Pre") C9 = ("Pre") C11 = ("Pre") C13 = ("Pre") C15 = ("Pre") C17 = ("Pre")
putexcel D2:D17 = "1996"

putexcel A18:A23 = "Education"
putexcel A24:A31 = "Race"
putexcel A32:A33 = "Total"
putexcel B18:B19 = ("HS or Less") B20:B21 = ("Some College") B22:B23 = ("College Plus") 
putexcel B24:B25 = ("NH White") B26:B27 = ("Black") B28:B29 = ("NH Asian") B30:B31 = ("Hispanic") 
putexcel B32:B33 = "Total"
putexcel C18 = ("Post") C20 = ("Post") C22 = ("Post") C24 = ("Post") C26 = ("Post") C28 = ("Post") C30 = ("Post") C32 = ("Post")
putexcel C19 = ("Pre") C21 = ("Pre") C23 = ("Pre") C25 = ("Pre") C27 = ("Pre") C29 = ("Pre") C31 = ("Pre") C33 = ("Pre")
putexcel D18:D33 = "2014"

// putexcel I3 = (1) I4 = (2) I5 = (3)
// putexcel I6 = (4) I7 = (5) I8 = (6) I9 = (7) 

sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1, detail // post
putexcel E16=`r(p50)', nformat(###,###)
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1, detail // pre
putexcel E17=`r(p50)', nformat(###,###)
// putexcel E2=formula(=(D2-C2)/C2), nformat(#.##%)

sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2, detail // post
putexcel E32 =`r(p50)', nformat(###,###)
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2, detail  // pre
putexcel E33=`r(p50)', nformat(###,###)
// putexcel H2=formula(=(G2-F2)/F2), nformat(#.##%)


local row1x "2 4 6"
local row2x "3 5 7"
local row3x "18 20 22"
local row4x "19 21 23"

forvalues e=1/3{
    local row1: word `e' of `row1x'	
	local row2: word `e' of `row2x'
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & educ_gp==`e' & survey_yr==1, detail // post-1996
	putexcel E`row1'=`r(p50)', nformat(###,###)
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & educ_gp==`e' & survey_yr==1, detail // pre-1996
	putexcel E`row2'=`r(p50)', nformat(###,###)
	
	local row3: word `e' of `row3x'	
	local row4: word `e' of `row4x'
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & educ_gp==`e' & survey_yr==2, detail // post-2014
	putexcel E`row3'=`r(p50)', nformat(###,###)
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & educ_gp==`e' & survey_yr==2, detail // pre-2014
	putexcel E`row4'=`r(p50)', nformat(###,###)
	
	/*
	local col3: word `e' of `colu3'	
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & educ_gp==`e', detail // pre-total
	putexcel `col3'10=`r(p50)', nformat(###,###)
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & educ_gp==`e', detail // post-total
	putexcel `col3'11=`r(p50)', nformat(###,###)
	putexcel `col3'12=formula((`col3'11-`col3'10)/`col3'10), nformat(#.##%)
	*/
}

local row1x "8 10 12 14"
local row2x "9 11 13 15"
local row3x "24 26 28 30"
local row4x "25 27 29 31"

forvalues r=1/4{
    local row1: word `r' of `row1x'	
	local row2: word `r' of `row2x'	
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & race==`r' & survey_yr==1, detail // post-1996
	putexcel E`row1'=`r(p50)', nformat(###,###)
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & race==`r' & survey_yr==1, detail // pre-1996
	putexcel E`row2'=`r(p50)', nformat(###,###)

    local row3: word `r' of `row3x'	
	local row4: word `r' of `row4x'	
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & race==`r' & survey_yr==2, detail // post-2014
	putexcel E`row3'=`r(p50)', nformat(###,###)
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & race==`r' & survey_yr==2, detail // pre-2014
	putexcel E`row4'=`r(p50)', nformat(###,###)
		
	/*
	local col3: word `r' of `colu3'	
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & race==`r', detail // pre-total
	putexcel `col3'17=`r(p50)', nformat(###,###)
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & race==`r', detail // post-total
	putexcel `col3'18=`r(p50)', nformat(###,###)
	putexcel `col3'19=formula((`col3'18-`col3'17)/`col3'17), nformat(#.##%)
	*/
}

	**Exploratory: who's income goes up, down, stays the same
	// browse SSUID PNUM year thearn_adj bw60 bw60lag trans_bw60_alt2
	by SSUID PNUM (year), sort: gen hh_income_chg = ((thearn_adj-thearn_adj[_n-1])/thearn_adj[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & trans_bw60_alt2==1
	by SSUID PNUM (year), sort: gen hh_income_raw = ((thearn_adj-thearn_adj[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & trans_bw60_alt2==1
	browse SSUID PNUM year thearn_adj bw60 trans_bw60_alt2 hh_income_chg hh_income_raw
	
	by SSUID PNUM (year), sort: gen hh_income_raw_all = ((thearn_adj-thearn_adj[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & bw60lag==0
	
	inspect hh_income_raw // almost split 50/50 negative v. positive
	sum hh_income_raw, detail // i am now wondering - is this the better way to do it?
	gen hh_chg_value=.
	replace hh_chg_value = 0 if hh_income_raw <0
	replace hh_chg_value = 1 if hh_income_raw >0 & hh_income_raw!=.
	tab hh_chg_value
	sum hh_income_raw if hh_chg_value==0, detail
	sum hh_income_raw if hh_chg_value==1, detail
	
	histogram hh_income_raw if hh_income_raw > -50000 & hh_income_raw <50000, width(5000) addlabel addlabopts(yvarformat(%4.1f)) percent xlabel(-50000(10000)50000) title("Household income change upon transition to BW") xtitle("HH income change") // wait is this all years?! but needs to be just 2014???
	histogram hh_income_raw if hh_income_raw > -50000 & hh_income_raw <50000 & survey_yr==2, width(5000) addlabel addlabopts(yvarformat(%4.1f)) percent xlabel(-50000(10000)50000) title("2014 Household income change upon transition to BW") xtitle("HH income change") // wait is this all years?! but needs to be just 2014???
	graph export "$results/HH_Income_Change.png", as(png) name("Graph") replace
	
	recode hh_income_raw (-99999999/-50001=0)(-50000/-45000=-5
	
	// all
	histogram hh_income_raw_all if hh_income_raw_all > -50000 & hh_income_raw_all <50000, width(5000) addlabel addlabopts(yvarformat(%4.1f)) percent xlabel(-50000(10000)50000) title("Annual Household Income Change") xtitle("HH income change")
	
	// all - no transition
	histogram hh_income_raw_all if hh_income_raw_all > -50000 & hh_income_raw_all <50000 & bw60==0, width(5000) addlabel addlabopts(yvarformat(%4.1f)) percent xlabel(-50000(10000)50000) title("Annual Household Income Change - no transition") xtitle("HH income change")
	
	// all -transitioned
	histogram hh_income_raw_all if hh_income_raw_all > -50000 & hh_income_raw_all <50000 & bw60==1, width(5000) addlabel addlabopts(yvarformat(%4.1f)) percent xlabel(-50000(10000)50000) title("Annual Household Income Change - transition") xtitle("HH income change")
	
	*Mother
	by SSUID PNUM (year), sort: gen mom_income_raw = ((earnings_adj-earnings_adj[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & trans_bw60_alt2==1
	histogram mom_income_raw if mom_income_raw > -50000 & mom_income_raw <50000, percent xlabel(-50000(10000)50000) title("Mom's income change upon transition to BW") xtitle("Mom's income change")	
	graph export "$results/Mom_Income_Change.png", as(png) name("Graph") replace
	
	* raw earnings
	histogram earnings_adj if earnings_adj <75000, percent
	histogram earnings_adj if trans_bw60_alt2==1 & earnings_adj <100000, percent title("Mom's income when she is BW")
	graph export "$results/Mom_Income_BW.png", as(png) name("Graph") replace
	
	
	sum earnings_adj if trans_bw60_alt2==1 & thearn_adj[_n-1]==0 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1), detail
	histogram earnings_adj if trans_bw60_alt2==1 & thearn_adj[_n-1]==0 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & thearn_adj<60000, percent title("Mom's income when she is BW year after $0 in HH earnings")
	graph export "$results/Mom_Income_BW_Zero.png", as(png) name("Graph") replace
	
	tab trans_bw60_alt2, m
	tab trans_bw60_alt2 if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1),m  //2,903
	tab trans_bw60_alt2 if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & thearn_adj[_n-1]==0,m // 686 (24%) - also higher incidence of female becoming breadwinner following a $0 year than there is in other years
	tab trans_bw60_alt2 if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & thearn_adj[_n-1]>0,m  // 2,217
	
	* earnings after year of HH having 0 earnings
	
	*Partner
	by SSUID PNUM (year), sort: gen partner_income_raw = ((earnings_sp_adj-earnings_sp_adj[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & trans_bw60_alt2==1
	histogram partner_income_raw if partner_income_raw > -50000 & partner_income_raw <50000, percent xlabel(-50000(10000)50000) title("Partner's income change upon transition to BW") xtitle("Partner's income change")
	graph export "$results/Partner_Income_Change.png", as(png) name("Graph") replace

**# Table 4a: Partner's income change

putexcel set "$results/Breadwinner_Impact_Tables", sheet(Table1a) modify
putexcel A1:J1 = "Median Income Loss for Partners - Total", merge border(bottom) hcenter
putexcel A2 = "Category"
putexcel B2 = "Label"
putexcel C2 = ("Pre_1996") D2 = ("Post_1996") E2 = ("% Change_1996") F2 = ("$ Change_1996")
putexcel G2 = ("Pre_2014") H2 = ("Post_2014") I2 = ("% Change_2014") J2 = ("$ Change_2014")
putexcel A3 = ("Total") B3 = ("Total")
putexcel A4:A6 = "Education"
putexcel B4 = ("HS or Less") B5 = ("Some College") B6 = ("College Plus") 
//putexcel I3 = (1) I4 = (2) I5 = (3)
putexcel A7:A10 = "Race"
putexcel B7 = ("NH White") B8 = ("Black") B9 = ("NH Asian") B10 = ("Hispanic") 

putexcel L1:U1 = "Mean Income Loss for Partners - Total", merge border(bottom) hcenter
putexcel L2 = "Category"
putexcel M2 = "Label" 
putexcel N2 = ("Pre_1996") P2 = ("Post_1996") R2 = ("% Change_1996")  T2 = ("$ Change_1996")
putexcel O2 = ("Pre_2014") Q2 = ("Post_2014") S2 = ("% Change_2014") U2 = ("$ Change_2014")
putexcel L3 = ("Total") M3 = ("Total")
putexcel L4:L6 = "Education"
putexcel M4= ("HS or Less") M5 = ("Some College") M6 = ("College Plus") 
putexcel L7:L10 = "Race"
putexcel M7 = ("NH White") M8 = ("Black") M9 = ("NH Asian") M10 = ("Hispanic") 

putexcel A12:J12 = "Median Income Loss for Partners - Mother became BW", merge border(bottom) hcenter
putexcel A13 = "Category"
putexcel B13 = "Label"
putexcel C13 = ("Pre_1996") D13 = ("Post_1996") E13 = ("% Change_1996") F13 = ("$ Change_1996")
putexcel G13 = ("Pre_2014") H13 = ("Post_2014") I13 = ("% Change_2014") J13 = ("$ Change_2014")
putexcel A14 = ("Total") B14 = ("Total")
putexcel A15:A17 = "Education"
putexcel B15 = ("HS or Less") B16 = ("Some College") B17 = ("College Plus") 
putexcel A18:A21 = "Race"
putexcel B18 = ("NH White") B19 = ("Black") B20 = ("NH Asian") B21 = ("Hispanic") 

putexcel L12:U12 = "Mean Income Loss for Partners - Mother became BW", merge border(bottom) hcenter
putexcel L13 = "Category"
putexcel M13 = "Label"
putexcel N13 = ("Pre_1996") P13 = ("Post_1996") R13 = ("% Change_1996")  T13 = ("$ Change_1996")
putexcel O13 = ("Pre_2014") Q13 = ("Post_2014") S13 = ("% Change_2014") U13 = ("$ Change_2014")
putexcel L14 = ("Total") M14 = ("Total")
putexcel L15:L17 = "Education"
putexcel M15= ("HS or Less") M16 = ("Some College") M17 = ("College Plus") 
putexcel L18:L21 = "Race"
putexcel M18 = ("NH White") M19 = ("Black") M20 = ("NH Asian") M21 = ("Hispanic") 

* All partners who lost earnings
* do we want pre and post or can I just get the average change?
* like mean earn_change_raw if earn_change_raw < 0?

sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & earn_change_raw_sp[_n+1]<0, detail // pre
putexcel C3=`r(p50)', nformat(###,###)
putexcel N3=`r(mean)', nformat(###,###)
sum earnings_sp_adj if survey_yr==1 & earn_change_raw_sp<0, detail // post change
putexcel D3=`r(p50)', nformat(###,###)
putexcel O3=`r(mean)', nformat(###,###)
putexcel E3=formula(=(D3-C3)/C3), nformat(#.##%)
putexcel F3=formula(=D3-C3), nformat(###,###)
putexcel P3=formula(=(O3-N3)/N3), nformat(#.##%)
putexcel Q3=formula(=O3-N3), nformat(###,###)

sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & earn_change_raw_sp[_n+1]<0, detail // pre
putexcel G3=`r(p50)', nformat(###,###)
putexcel R3=`r(mean)', nformat(###,###)
sum earnings_sp_adj if survey_yr==2 & earn_change_raw_sp<0, detail // post change
putexcel H3=`r(p50)', nformat(###,###)
putexcel S3=`r(mean)', nformat(###,###)
putexcel I3=formula(=(H3-G3)/G3), nformat(#.##%)
putexcel J3=formula(=H3-G3), nformat(###,###)
putexcel T3=formula(=(S3-R3)/R3), nformat(#.##%)
putexcel U3=formula(=S3-R3), nformat(###,###)

local row1 "4 5 6"
forvalues e=1/3{
    local row: word `e' of `row1'	
	
	sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & earn_change_raw_sp[_n+1]<0 & educ_gp==`e', detail // pre
	putexcel C`row'=`r(p50)', nformat(###,###)
	putexcel N`row'=`r(mean)', nformat(###,###)
	sum earnings_sp_adj if survey_yr==1 & earn_change_raw_sp<0  & educ_gp==`e', detail // post change
	putexcel D`row'=`r(p50)', nformat(###,###)
	putexcel O`row'=`r(mean)', nformat(###,###)
	putexcel E`row'=formula((D`row'-C`row')/C`row'), nformat(#.##%)
	putexcel F`row'=formula((D`row'-C`row')), nformat(###,###)
	putexcel P`row'=formula((O`row'-N`row')/N`row'), nformat(#.##%)
	putexcel Q`row'=formula((O`row'-N`row')), nformat(###,###)
	
	sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & earn_change_raw_sp[_n+1]<0 & educ_gp==`e', detail // pre
	putexcel G`row'=`r(p50)', nformat(###,###)
	putexcel R`row'=`r(mean)', nformat(###,###)
	sum earnings_sp_adj if survey_yr==2 & earn_change_raw_sp<0  & educ_gp==`e', detail // post change
	putexcel H`row'=`r(p50)', nformat(###,###)
	putexcel S`row'=`r(mean)', nformat(###,###)
	putexcel I`row'=formula((H`row'-G`row')/G`row'), nformat(#.##%)
	putexcel J`row'=formula((H`row'-G`row')), nformat(###,###)
	putexcel T`row'=formula((S`row'-R`row')/R`row'), nformat(#.##%)
	putexcel U`row'=formula((S`row'-R`row')), nformat(###,###)
}

local row2 "7 8 9 10"
forvalues r=1/4{
    local row: word `r' of `row2'	
	sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & earn_change_raw_sp[_n+1]<0 & race==`r', detail // pre
	putexcel C`row'=`r(p50)', nformat(###,###)
	putexcel N`row'=`r(mean)', nformat(###,###)
	sum earnings_sp_adj if survey_yr==1 & earn_change_raw_sp<0  & race==`r', detail // post change
	putexcel D`row'=`r(p50)', nformat(###,###)
	putexcel O`row'=`r(mean)', nformat(###,###)
	putexcel E`row'=formula((D`row'-C`row')/C`row'), nformat(#.##%)
	putexcel F`row'=formula((D`row'-C`row')), nformat(###,###)
	putexcel P`row'=formula((O`row'-N`row')/N`row'), nformat(#.##%)
	putexcel Q`row'=formula((O`row'-N`row')), nformat(###,###)
	
	sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & earn_change_raw_sp[_n+1]<0 & race==`r', detail // pre
	putexcel G`row'=`r(p50)', nformat(###,###)
	putexcel R`row'=`r(mean)', nformat(###,###)
	sum earnings_sp_adj if survey_yr==2 & earn_change_raw_sp<0  & race==`r', detail // post change
	putexcel H`row'=`r(p50)', nformat(###,###)
	putexcel S`row'=`r(mean)', nformat(###,###)
	putexcel I`row'=formula((H`row'-G`row')/G`row'), nformat(#.##%)
	putexcel J`row'=formula((H`row'-G`row')), nformat(###,###)
	putexcel T`row'=formula((S`row'-R`row')/R`row'), nformat(#.##%)
	putexcel U`row'=formula((S`row'-R`row')), nformat(###,###)
}


* Just those where mother became BW (and partner had earnings loss)
sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & earn_change_raw_sp[_n+1]<0, detail // pre
putexcel C14=`r(p50)', nformat(###,###)
putexcel N14=`r(mean)', nformat(###,###)
sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & earn_change_raw_sp<0, detail // post
putexcel D14=`r(p50)', nformat(###,###)
putexcel O14=`r(mean)', nformat(###,###)
putexcel E14=formula(=(D14-C14)/C14), nformat(#.##%)
putexcel F14=formula(=D14-C14), nformat(###,###)
putexcel P14=formula(=(O14-N14)/N14), nformat(#.##%)
putexcel Q14=formula(=O14-N14), nformat(###,###)

sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & earn_change_raw_sp[_n+1]<0, detail  // pre
putexcel G14=`r(p50)', nformat(###,###)
putexcel R14=`r(mean)', nformat(###,###)
sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & earn_change_raw_sp<0, detail // post
putexcel H14=`r(p50)', nformat(###,###)
putexcel S14=`r(mean)', nformat(###,###)
putexcel I14=formula(=(H14-G14)/G14), nformat(#.##%)
putexcel J14=formula(=H14-G14), nformat(###,###)
putexcel T14=formula(=(S14-R14)/R14), nformat(#.##%)
putexcel U14=formula(=S14-R14), nformat(###,###)

local row1 "15 16 17"
forvalues e=1/3{
    local row: word `e' of `row1'	
	
	sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & educ_gp==`e' & survey_yr==1 & earn_change_raw_sp[_n+1]<0, detail // pre-1996
	putexcel C`row'=`r(p50)', nformat(###,###)
	putexcel N`row'=`r(mean)', nformat(###,###)
	sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & educ_gp==`e' & survey_yr==1 & earn_change_raw_sp<0, detail // post-1996
	putexcel D`row'=`r(p50)', nformat(###,###)
	putexcel O`row'=`r(mean)', nformat(###,###)
	putexcel E`row'=formula((D`row'-C`row')/C`row'), nformat(#.##%)
	putexcel F`row'=formula((D`row'-C`row')), nformat(###,###)
	putexcel P`row'=formula((O`row'-N`row')/N`row'), nformat(#.##%)
	putexcel Q`row'=formula((O`row'-N`row')), nformat(###,###)
		
	sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & educ_gp==`e' & survey_yr==2 & earn_change_raw_sp[_n+1]<0, detail // pre-2014
	putexcel G`row'=`r(p50)', nformat(###,###)
	putexcel R`row'=`r(mean)', nformat(###,###)
	sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & educ_gp==`e' & survey_yr==2 & earn_change_raw_sp<0, detail // post-2014
	putexcel H`row'=`r(p50)', nformat(###,###)
	putexcel S`row'=`r(mean)', nformat(###,###)
	putexcel I`row'=formula((H`row'-G`row')/G`row'), nformat(#.##%)
	putexcel J`row'=formula((H`row'-G`row')), nformat(###,###)
	putexcel T`row'=formula((S`row'-R`row')/R`row'), nformat(#.##%)
	putexcel U`row'=formula((S`row'-R`row')), nformat(###,###)
}

local row2 "18 19 20 21"
forvalues r=1/4{
    local row: word `r' of `row2'	
	sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & race==`r' & survey_yr==1 & earn_change_raw_sp[_n+1]<0, detail // pre-1996
	putexcel C`row'=`r(p50)', nformat(###,###)
	putexcel N`row'=`r(mean)', nformat(###,###)
	sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & race==`r' & survey_yr==1 & earn_change_raw_sp<0, detail // post-1996
	putexcel D`row'=`r(p50)', nformat(###,###)
	putexcel O`row'=`r(mean)', nformat(###,###)
	putexcel E`row'=formula((D`row'-C`row')/C`row'), nformat(#.##%)
	putexcel F`row'=formula((D`row'-C`row')), nformat(###,###)
	putexcel P`row'=formula((O`row'-N`row')/N`row'), nformat(#.##%)
	putexcel Q`row'=formula((O`row'-N`row')), nformat(###,###)
		
	sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & race==`r' & survey_yr==2 & earn_change_raw_sp[_n+1]<0, detail // pre-2014
	putexcel G`row'=`r(p50)', nformat(###,###)
	putexcel R`row'=`r(mean)', nformat(###,###)
	sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & race==`r' & survey_yr==2 & earn_change_raw_sp<0, detail // post-2014
	putexcel H`row'=`r(p50)', nformat(###,###)
	putexcel S`row'=`r(mean)', nformat(###,###)
	putexcel I`row'=formula((H`row'-G`row')/G`row'), nformat(#.##%)
	putexcel J`row'=formula((H`row'-G`row')), nformat(###,###)
	putexcel T`row'=formula((S`row'-R`row')/R`row'), nformat(#.##%)
	putexcel U`row'=formula((S`row'-R`row')), nformat(###,###)
}

**# Table 4b: Mother's Income Change

putexcel set "$results/Breadwinner_Impact_Tables", sheet(Table1b) modify
putexcel A1:J1 = "Median Income Gain for Mothers - Total", merge border(bottom) hcenter
putexcel A2 = "Category"
putexcel B2 = "Label"
putexcel C2 = ("Pre_1996") D2 = ("Post_1996") E2 = ("% Change_1996") F2 = ("$ Change_1996")
putexcel G2 = ("Pre_2014") H2 = ("Post_2014") I2 = ("% Change_2014") J2 = ("$ Change_2014")
putexcel A3 = ("Total") B3 = ("Total")
putexcel A4:A6 = "Education"
putexcel B4 = ("HS or Less") B5 = ("Some College") B6 = ("College Plus") 
putexcel A7:A10 = "Race"
putexcel B7 = ("NH White") B8 = ("Black") B9 = ("NH Asian") B10 = ("Hispanic") 

putexcel A12:J12 = "Median Income Gain for Mothers - Mother became BW", merge border(bottom) hcenter
putexcel A13 = "Category"
putexcel B13 = "Label"
putexcel C13 = ("Pre_1996") D13 = ("Post_1996") E13 = ("% Change_1996") F13 = ("$ Change_1996")
putexcel G13 = ("Pre_2014") H13 = ("Post_2014") I13 = ("% Change_2014") J13 = ("$ Change_2014")
putexcel A14 = ("Total") B14 = ("Total")
putexcel A15:A17 = "Education"
putexcel B15 = ("HS or Less") B16 = ("Some College") B17 = ("College Plus") 
putexcel A18:A21 = "Race"
putexcel B18 = ("NH White") B19 = ("Black") B20 = ("NH Asian") B21 = ("Hispanic") 

* All mothers who gained earnings
* do we want pre and post or can I just get the average change?
* like mean earn_change_raw if earn_change_raw < 0?

sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & earn_change_raw[_n+1]>0, detail // pre
putexcel C3=`r(p50)', nformat(###,###)
sum earnings_adj if survey_yr==1 & earn_change_raw>0, detail // post change
putexcel D3=`r(p50)', nformat(###,###)
putexcel E3=formula(=(D3-C3)/C3), nformat(#.##%)
putexcel F3=formula(=D3-C3), nformat(###,###)

sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & earn_change_raw[_n+1]>0, detail // pre
putexcel G3=`r(p50)', nformat(###,###)
sum earnings_adj if survey_yr==2 & earn_change_raw>0, detail // post change
putexcel H3=`r(p50)', nformat(###,###)
putexcel I3=formula(=(H3-G3)/G3), nformat(#.##%)
putexcel J3=formula(=H3-G3), nformat(###,###)

local row1 "4 5 6"
forvalues e=1/3{
    local row: word `e' of `row1'	
	
	sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & earn_change_raw[_n+1]>0 & educ_gp==`e', detail // pre
	putexcel C`row'=`r(p50)', nformat(###,###)
	sum earnings_adj if survey_yr==1 & earn_change_raw>0  & educ_gp==`e', detail // post change
	putexcel D`row'=`r(p50)', nformat(###,###)
	putexcel E`row'=formula((D`row'-C`row')/C`row'), nformat(#.##%)
	putexcel F`row'=formula((D`row'-C`row')), nformat(###,###)
	
	sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & earn_change_raw[_n+1]>0 & educ_gp==`e', detail // pre
	putexcel G`row'=`r(p50)', nformat(###,###)
	sum earnings_adj if survey_yr==2 & earn_change_raw>0  & educ_gp==`e', detail // post change
	putexcel H`row'=`r(p50)', nformat(###,###)
	putexcel I`row'=formula((H`row'-G`row')/G`row'), nformat(#.##%)
	putexcel J`row'=formula((H`row'-G`row')), nformat(###,###)
}

local row2 "7 8 9 10"
forvalues r=1/4{
    local row: word `r' of `row2'	
	sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & earn_change_raw[_n+1]>0 & race==`r', detail // pre
	putexcel C`row'=`r(p50)', nformat(###,###)
	sum earnings_adj if survey_yr==1 & earn_change_raw>0  & race==`r', detail // post change
	putexcel D`row'=`r(p50)', nformat(###,###)
	putexcel E`row'=formula((D`row'-C`row')/C`row'), nformat(#.##%)
	putexcel F`row'=formula((D`row'-C`row')), nformat(###,###)
	
	sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & earn_change_raw[_n+1]>0 & race==`r', detail // pre
	putexcel G`row'=`r(p50)', nformat(###,###)
	sum earnings_adj if survey_yr==2 & earn_change_raw>0  & race==`r', detail // post change
	putexcel H`row'=`r(p50)', nformat(###,###)
	putexcel I`row'=formula((H`row'-G`row')/G`row'), nformat(#.##%)
	putexcel J`row'=formula((H`row'-G`row')), nformat(###,###)
}


* Just those where mother became BW (and she gained earnings loss)
sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & earn_change_raw[_n+1]>0, detail // pre
putexcel C14=`r(p50)', nformat(###,###)
sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & earn_change_raw>0, detail // post
putexcel D14=`r(p50)', nformat(###,###)
putexcel E14=formula(=(D14-C14)/C14), nformat(#.##%)
putexcel F14=formula(=D14-C14), nformat(###,###)

sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & earn_change_raw[_n+1]>0, detail  // pre
putexcel G14=`r(p50)', nformat(###,###)
sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & earn_change_raw>0, detail // post
putexcel H14=`r(p50)', nformat(###,###)
putexcel I14=formula(=(H14-G14)/G14), nformat(#.##%)
putexcel J14=formula(=H14-G14), nformat(###,###)

local row1 "15 16 17"
forvalues e=1/3{
    local row: word `e' of `row1'	
	
	sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & educ_gp==`e' & survey_yr==1 & earn_change_raw[_n+1]>0, detail // pre-1996
	putexcel C`row'=`r(p50)', nformat(###,###)
	sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & educ_gp==`e' & survey_yr==1 & earn_change_raw>0, detail // post-1996
	putexcel D`row'=`r(p50)', nformat(###,###)
	putexcel E`row'=formula((D`row'-C`row')/C`row'), nformat(#.##%)
	putexcel F`row'=formula((D`row'-C`row')), nformat(###,###)
		
	sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & educ_gp==`e' & survey_yr==2 & earn_change_raw[_n+1]>0, detail // pre-2014
	putexcel G`row'=`r(p50)', nformat(###,###)
	sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & educ_gp==`e' & survey_yr==2 & earn_change_raw>0, detail // post-2014
	putexcel H`row'=`r(p50)', nformat(###,###)
	putexcel I`row'=formula((H`row'-G`row')/G`row'), nformat(#.##%)
	putexcel J`row'=formula((H`row'-G`row')), nformat(###,###)
}

local row2 "18 19 20 21"
forvalues r=1/4{
    local row: word `r' of `row2'	
	sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & race==`r' & survey_yr==1 & earn_change_raw[_n+1]>0, detail // pre-1996
	putexcel C`row'=`r(p50)', nformat(###,###)
	sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & race==`r' & survey_yr==1 & earn_change_raw>0, detail // post-1996
	putexcel D`row'=`r(p50)', nformat(###,###)
	putexcel E`row'=formula((D`row'-C`row')/C`row'), nformat(#.##%)
	putexcel F`row'=formula((D`row'-C`row')), nformat(###,###)
		
	sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & race==`r' & survey_yr==2 & earn_change_raw[_n+1]>0, detail // pre-2014
	putexcel G`row'=`r(p50)', nformat(###,###)
	sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & race==`r' & survey_yr==2 & earn_change_raw>0, detail // post-2014
	putexcel H`row'=`r(p50)', nformat(###,###)
	putexcel I`row'=formula((H`row'-G`row')/G`row'), nformat(#.##%)
	putexcel J`row'=formula((H`row'-G`row')), nformat(###,###)
}

**# Table 4c: HH Income-to-Poverty Change
browse SSUID year end_hhsize end_minorchildren threshold thearn_adj
gen inc_pov = thearn_adj / threshold

by SSUID PNUM (year), sort: gen inc_pov_change = ((inc_pov-inc_pov[_n-1])/inc_pov[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==year[_n-1]+1
by SSUID PNUM (year), sort: gen inc_pov_change_raw = (inc_pov-inc_pov[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==year[_n-1]+1

replace inc_pov_change = 1 if inc_pov_change==. & inc_pov_change_raw > 0 & inc_pov_change_raw!=.
gen inc_pov_up =.
replace inc_pov_up = 1 if inc_pov_change_raw > 0 & inc_pov_change_raw!=.
replace inc_pov_up = 2 if inc_pov_change==1
replace inc_pov_up = 0 if inc_pov_change_raw < 0 & inc_pov_change_raw!=.

tab inc_pov_up if trans_bw60_alt2==1
sum inc_pov_change_raw if inc_pov_up==1 & trans_bw60_alt2==1, detail
sum inc_pov_change_raw if inc_pov_up==0 & trans_bw60_alt2==1, detail

gen inc_pov_percent=.
replace inc_pov_percent = 1 if inc_pov_change > 0 & inc_pov_change <0.5
replace inc_pov_percent = 2 if inc_pov_change > 0.5 & inc_pov_change!=.
replace inc_pov_percent = 3 if inc_pov_change < 0 & inc_pov_change > -0.5
replace inc_pov_percent = 4 if inc_pov_change < -0.5
replace inc_pov_percent = 5 if inc_pov_change == 1 & inc_pov_change_raw < 1 & inc_pov_change_raw!=.
replace inc_pov_percent = 6 if inc_pov_change == 1 & inc_pov_change_raw >= 1 & inc_pov_change_raw!=.

label define inc_pov_percent 1 "<50% Up" 2 ">50% Up" 3 "<50% Down" 4 ">50% Down" 5 "Change from 0: below 1" 6 "Change from 0: above 1"
label values inc_pov_percent inc_pov_percent

gen inc_pov_move=.
replace inc_pov_move = 1 if inc_pov_change > 0 & inc_pov_change!=.
replace inc_pov_move = 2 if inc_pov_change < 0 & inc_pov_change!=.
replace inc_pov_move = 3 if inc_pov_change == 1

label define inc_pov_move 1 "Ratio Up" 2 "Ratio Down" 3 "Change from 0"
label values inc_pov_move inc_pov_move

gen inc_pov_flag=.
replace inc_pov_flag=1 if inc_pov >=1.5 & inc_pov!=.
replace inc_pov_flag=0 if inc_pov <1.5 & inc_pov!=.

browse SSUID year end_hhsize end_minorchildren threshold thearn_adj inc_pov trans_bw60_alt2 bw60 inc_pov_change inc_pov_change_raw inc_pov_move inc_pov_flag // inc_pov_percent inc_pov_up

tab inc_pov_percent, gen(inc_pov_pct)
tab inc_pov_move, gen(inc_pov_mv)

// 3 buckets we created for FAMDEM
gen inc_pov_summary=.
replace inc_pov_summary=1 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. & inc_pov >=1.5
replace inc_pov_summary=2 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. & inc_pov <1.5
replace inc_pov_summary=3 if inc_pov_change_raw < 0 & inc_pov_change_raw!=.
replace inc_pov_summary=4 if inc_pov_change_raw==0

label define summary 1 "Up, Above Pov" 2 "Up, Not above pov" 3 "Down" 4 "No Change"
label values inc_pov_summary summary

// Breaking out income down to above v. below poverty
gen inc_pov_summary2=.
replace inc_pov_summary2=1 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. & inc_pov >=1.5
replace inc_pov_summary2=2 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. & inc_pov <1.5
replace inc_pov_summary2=3 if inc_pov_change_raw < 0 & inc_pov_change_raw!=. & inc_pov >=1.5
replace inc_pov_summary2=4 if inc_pov_change_raw < 0 & inc_pov_change_raw!=. & inc_pov <1.5
replace inc_pov_summary2=5 if inc_pov_change_raw==0

label define summary2 1 "Up, Above Pov" 2 "Up, Below Pov" 3 "Down, Above Pov" 4 "Down, Below Pov" 5 "No Change"
label values inc_pov_summary2 summary2

browse SSUID year end_hhsize end_minorchildren threshold thearn_adj inc_pov trans_bw60_alt2 bw60 inc_pov_change inc_pov_change_raw inc_pov_move inc_pov_summary // inc_pov_percent inc_pov_up

tab inc_pov_summary if trans_bw60_alt2==1
tab inc_pov_summary if trans_bw60_alt2==1 & survey_yr==1
tab inc_pov_summary if trans_bw60_alt2==1 & survey_yr==2


putexcel set "$results/Breadwinner_Impact_Tables", sheet(Table2) modify

putexcel A1:H1 = "Median HH Income-to-Poverty Change - Mother became BW", merge border(bottom) hcenter
putexcel A2 = "Category"
putexcel B2 = "Label"
putexcel C2 = ("Pre_1996") D2 = ("Post_1996") E2 = ("% Change_1996")
putexcel F2 = ("Pre_2014") G2 = ("Post_2014") H2 = ("% Change_2014")
putexcel A3 = ("Total") B3 = ("Total")
putexcel A4:A6 = "Education"
putexcel B4 = ("HS or Less") B5 = ("Some College") B6 = ("College Plus") 
//putexcel I3 = (1) I4 = (2) I5 = (3)
putexcel A7:A10 = "Race"
putexcel B7 = ("NH White") B8 = ("Black") B9 = ("NH Asian") B10 = ("Hispanic") 

putexcel J1:Q1 = "Mean HH Income-to-Poverty Change - Mother became BW", merge border(bottom) hcenter
putexcel J2 = "Category"
putexcel K2 = "Label" 
putexcel L2 = ("Pre_1996") M2 = ("Post_1996") N2 = ("% Change_1996") 
putexcel O2 = ("Pre_2014") P2 = ("Post_2014") Q2 = ("% Change_2014")
putexcel J3 = ("Total") K3 = ("Total")
putexcel J4:J6 = "Education"
putexcel K4= ("HS or Less") K5 = ("Some College") K6 = ("College Plus") 
putexcel J7:J10 = "Race"
putexcel K7 = ("NH White") K8 = ("Black") K9 = ("NH Asian") K10 = ("Hispanic") 

sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1, detail // pre
putexcel C3=`r(p50)', nformat(###,###.#)
putexcel L3=`r(mean)', nformat(###,###.#)
sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1, detail // post
putexcel D3=`r(p50)', nformat(###,###.#)
putexcel M3=`r(mean)', nformat(###,###.#)
putexcel E3=formula(=(D3-C3)/C3), nformat(#.##%)
putexcel N3=formula(=(M3-L3)/L3), nformat(#.##%)

sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2, detail  // pre
putexcel F3=`r(p50)', nformat(###,###.#)
putexcel O3=`r(mean)', nformat(###,###.#)
sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2, detail // post
putexcel G3=`r(p50)', nformat(###,###.#)
putexcel P3=`r(mean)', nformat(###,###.#)
putexcel H3=formula(=(G3-F3)/F3), nformat(#.##%)
putexcel Q3=formula(=(P3-O3)/O3), nformat(#.##%)

local row1 "4 5 6"
forvalues e=1/3{
    local row: word `e' of `row1'	
	
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & educ_gp==`e' & survey_yr==1, detail // pre-1996
	putexcel C`row'=`r(p50)', nformat(###,###.#)
	putexcel L`row'=`r(mean)', nformat(###,###.#)
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & educ_gp==`e' & survey_yr==1, detail // post-1996
	putexcel D`row'=`r(p50)', nformat(###,###.#)
	putexcel M`row'=`r(mean)', nformat(###,###.#)
	putexcel E`row'=formula((D`row'-C`row')/C`row'), nformat(#.##%)
	putexcel N`row'=formula((M`row'-L`row')/L`row'), nformat(#.##%)
		
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & educ_gp==`e' & survey_yr==2, detail // pre-2014
	putexcel F`row'=`r(p50)', nformat(###,###.#)
	putexcel O`row'=`r(mean)', nformat(###,###.#)
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & educ_gp==`e' & survey_yr==2, detail // post-2014
	putexcel G`row'=`r(p50)', nformat(###,###.#)
	putexcel P`row'=`r(mean)', nformat(###,###.#)
	putexcel H`row'=formula((G`row'-F`row')/F`row'), nformat(#.##%)
	putexcel Q`row'=formula((P`row'-O`row')/O`row'), nformat(#.##%)
}

local row2 "7 8 9 10"
forvalues r=1/4{
    local row: word `r' of `row2'	
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & race==`r' & survey_yr==1, detail // pre-1996
	putexcel C`row'=`r(p50)', nformat(###,###.#)
	putexcel L`row'=`r(mean)', nformat(###,###.#)
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & race==`r' & survey_yr==1, detail // post-1996
	putexcel D`row'=`r(p50)', nformat(###,###.#)
	putexcel M`row'=`r(mean)', nformat(###,###.#)
	putexcel E`row'=formula((D`row'-C`row')/C`row'), nformat(#.##%)
	putexcel N`row'=formula((M`row'-L`row')/L`row'), nformat(#.##%)
		
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & race==`r' & survey_yr==2, detail // pre-2014
	putexcel F`row'=`r(p50)', nformat(###,###.#)
	putexcel O`row'=`r(mean)', nformat(###,###.#)
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & race==`r' & survey_yr==2, detail // post-2014
	putexcel G`row'=`r(p50)', nformat(###,###.#)
	putexcel P`row'=`r(mean)', nformat(###,###.#)
	putexcel H`row'=formula((G`row'-F`row')/F`row'), nformat(#.##%)
	putexcel Q`row'=formula((P`row'-O`row')/O`row'), nformat(#.##%)
}


putexcel C13:H13 = "1996", merge border(bottom) hcenter
putexcel I13:N13 = "2014", merge border(bottom) hcenter
putexcel A14 = "Category"
putexcel B14 = "Label" 
putexcel A15 = ("Total") B15 = ("Total")
putexcel A16:A18 = "Education"
putexcel B16= ("HS or Less") B17 = ("Some College") B18 = ("College Plus") 
putexcel A19:A22 = "Race"
putexcel B19 = ("NH White") B20 = ("Black") B21 = ("NH Asian") B22 = ("Hispanic") 
putexcel C14= ("<50% Up") D14 = (">50% Up") E14 = ("<50% Down") F14 = (">50% Down") G14 = ("Change from 0: below 1") H14 = ("Change from 0: above 1") 
putexcel I14= ("<50% Up") J14 = (">50% Up") K14 = ("<50% Down") L14 = (">50% Down") M14 = ("Change from 0: below 1") N14 = ("Change from 0: above 1") 

local colu1 "C D E F G H"
local colu2 "I J K L M N"

forvalues i=1/6{
	local col1: word `i' of `colu1'
	local col2: word `i' of `colu2'
	sum inc_pov_pct`i' if trans_bw60_alt2==1 & survey_yr==1, detail // 1996
	putexcel `col1'15=`r(mean)', nformat(#.##%)
	sum inc_pov_pct`i' if trans_bw60_alt2==1 & survey_yr==2, detail // 2014
	putexcel `col2'15=`r(mean)', nformat(#.##%)
}

local row1 "16 17 18"
forvalues e=1/3{
	local row: word `e' of `row1'
		forvalues i=1/6{
		local col1: word `i' of `colu1'
		local col2: word `i' of `colu2'
		sum inc_pov_pct`i' if trans_bw60_alt2==1 & survey_yr==1 & educ_gp==`e', detail // 1996
		putexcel `col1'`row'=`r(mean)', nformat(#.##%)
		sum inc_pov_pct`i' if trans_bw60_alt2==1 & survey_yr==2 & educ_gp==`e', detail // 2014
		putexcel `col2'`row'=`r(mean)', nformat(#.##%)
	}	
}

local row1 "19 20 21 22"
forvalues r=1/4{
	local row: word `r' of `row1'
		forvalues i=1/6{
		local col1: word `i' of `colu1'
		local col2: word `i' of `colu2'
		sum inc_pov_pct`i' if trans_bw60_alt2==1 & survey_yr==1 & race==`r', detail // 1996
		putexcel `col1'`row'=`r(mean)', nformat(#.##%)
		sum inc_pov_pct`i' if trans_bw60_alt2==1 & survey_yr==2 & race==`r', detail // 2014
		putexcel `col2'`row'=`r(mean)', nformat(#.##%)
	}	
}
	
/*
forvalues y=1/2{
	tab inc_pov_percent if trans_bw60_alt2==1 & survey_yr==`y'
	forvalues e=1/3{
		display "`y'," "`e'"
		tab inc_pov_percent if trans_bw60_alt2==1 & survey_yr==`y' & educ_gp==`e'
	}
	forvalues r=1/4{
		display "`y'," "`r'"
		tab inc_pov_percent if trans_bw60_alt2==1 & survey_yr==`y' & race==`r'
	}
}
*/

**# Table 5:  HH raw income change with each breadwinner component
putexcel set "$results/Breadwinner_Impact_Tables", sheet(Table3-raw) modify
putexcel A3 = "Event"
putexcel B3 = "Year"
putexcel C3 = ("All_events") E3 = ("All_events") G3 = ("All_events") I3 = ("All_events") K3 = ("All_events") M3 = ("All_events") O3 = ("All_events") Q3 = ("All_events") S3 = ("All_events") U3 = ("All_events") W3 = ("All_events") Y3 = ("All_events") AA3 = ("All_events") AC3 = ("All_events")
putexcel D3 = ("Event_precipitated") F3 = ("Event_precipitated") H3 = ("Event_precipitated") J3 = ("Event_precipitated") L3 = ("Event_precipitated") N3 = ("Event_precipitated") ///
		P3 = ("Event_precipitated") R3 = ("Event_precipitated") T3 = ("Event_precipitated") V3 = ("Event_precipitated") X3 = ("Event_precipitated") Z3 = ("Event_precipitated") AB3 = ("Event_precipitated") AD3 = ("Event_precipitated")
putexcel C1:D1 = "Total", merge border(bottom)
putexcel E1:J1 = "Education", merge border(bottom)
putexcel K1:R1 = "Race / ethnicity", merge border(bottom)
putexcel S1:Z1 = "Age at first birth", merge border(bottom)
putexcel AA1:AD1 = "Marital Status at birth", merge border(bottom)
putexcel C2:D2 = "Total", merge border(bottom)
putexcel E2:F2 = "HS Degree or Less", merge border(bottom)
putexcel G2:H2 = "Some College", merge border(bottom)
putexcel I2:J2 = "College Plus", merge border(bottom)
putexcel K2:L2 = "NH White", merge border(bottom)
putexcel M2:N2 = "Black", merge border(bottom)
putexcel O2:P2 = "NH Asian", merge border(bottom)
putexcel Q2:R2 = "Hispanic", merge border(bottom)
putexcel S2:T2 = "< 20", merge border(bottom)
putexcel U2:V2 = "20-24", merge border(bottom)
putexcel W2:X2 = "25-29", merge border(bottom)
putexcel Y2:Z2 = "30+", merge border(bottom)
putexcel AA2:AB2 = "Married", merge border(bottom)
putexcel AC2:AD2 = "Never Married", merge border(bottom)
putexcel A4:A5 = "Mothers only an increase in earnings"
putexcel A6:A7 = "Mothers increase in earnings and partner lost earnings"
putexcel A8:A9 = "Partner lost earnings only"
putexcel A10:A11 = "Partner left"
putexcel A12:A13 = "Other member lost earnings / left"
putexcel A15 = "Mothers increase in earnings and partner lost earnings"
putexcel A16:A17 = "Mother earnings gain"
putexcel A18:A19 = "Partner earnings loss"
putexcel B4 = ("1996") B6 = ("1996") B8 = ("1996") B10 = ("1996") B12 = ("1996") B16 = ("1996") B18 = ("1996")
putexcel B5 = ("2014") B7 = ("2014") B9 = ("2014") B11 = ("2014") B13 = ("2014") B17 = ("2014") B19 = ("2014")

* All mothers who experienced a change
local i=1

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	local row1 = `i'*2+2
		
	sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1, detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1, detail // post - is this the same as bw60lag==0? okay yes
	local p50_post =`r(p50)'
	putexcel C`row1'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)

	local row2 = `i'*2+3
	sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1, detail  // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1, detail // post
	local p50_post =`r(p50)'
	putexcel C`row2'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)

	local ++i
}

* Mothers who experienced change AND became BW
local i=1

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	local row1 = `i'*2+2
		
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1, detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1, detail // post
	local p50_post =`r(p50)'
	putexcel D`row1'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)

	local row2 = `i'*2+3
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1, detail  // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1, detail // post
	local p50_post =`r(p50)'
	putexcel D`row2'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	
	local ++i
}

// Mother's change only for when mom up but partner down
* All
	sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1, detail // pre
	local p50_pre =`r(p50)'
	sum earnings_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1, detail // post - is this the same as bw60lag==0? okay yes
	local p50_post =`r(p50)'
	putexcel C16=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1, detail  // pre
	local p50_pre =`r(p50)'
	sum earnings_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1, detail // post
	local p50_post =`r(p50)'
	putexcel C17=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
*BW only
	sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1, detail // pre
	local p50_pre =`r(p50)'
	sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1, detail // post
	local p50_post =`r(p50)'
	putexcel D16=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1, detail  // pre
	local p50_pre =`r(p50)'
	sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1, detail // post
	local p50_post =`r(p50)'
	putexcel D17=formula(=(`p50_post' - `p50_pre')), nformat(###,###)

// Partners's change only for when mom up but partner down
* All
	sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1, detail // pre
	local p50_pre =`r(p50)'
	sum earnings_sp_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1, detail // post - is this the same as bw60lag==0? okay yes
	local p50_post =`r(p50)'
	putexcel C18=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1, detail  // pre
	local p50_pre =`r(p50)'
	sum earnings_sp_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1, detail // post
	local p50_post =`r(p50)'
	putexcel C19=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
*BW only
	sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1, detail // pre
	local p50_pre =`r(p50)'
	sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1, detail // post
	local p50_post =`r(p50)'
	putexcel D18=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1, detail  // pre
	local p50_pre =`r(p50)'
	sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1, detail // post
	local p50_post =`r(p50)'
	putexcel D19=formula(=(`p50_post' - `p50_pre')), nformat(###,###)


local col1x "E G I"
local col2x "F H J"
forvalues e=1/3{
local i = 1
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
    local col1: word `e' of `col1x'	
	local col2: word `e' of `col2x'
	local row1 = `i'*2+2
	local row2 = `i'*2+3
	
* All changes - 1996	
	sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1  & educ_gp==`e', detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1  & educ_gp==`e', detail // post 
	local p50_post =`r(p50)'
	putexcel `col1'`row1'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	
* BW changes - 1996
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1 & educ_gp==`e', detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1 & educ_gp==`e', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'`row1'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)

* All changes - 2014
	sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1 & educ_gp==`e', detail  // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1 & educ_gp==`e', detail // post
	local p50_post =`r(p50)'
	putexcel `col1'`row2'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	
* BW changes - 2014
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1 & educ_gp==`e', detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1 & educ_gp==`e', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'`row2'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	
	local ++i
	}
	
// Mother's change only for when mom up but partner down
* All
	sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1 & educ_gp==`e', detail // pre
	local p50_pre =`r(p50)'
	sum earnings_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1 & educ_gp==`e', detail // post
	local p50_post =`r(p50)'
	putexcel `col1'16=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1 & educ_gp==`e', detail  // pre
	local p50_pre =`r(p50)'
	sum earnings_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1 & educ_gp==`e', detail // post
	local p50_post =`r(p50)'
	putexcel `col1'17=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
*BW only
	sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1 & educ_gp==`e', detail // pre
	local p50_pre =`r(p50)'
	sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1 & educ_gp==`e', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'16=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1 & educ_gp==`e', detail  // pre
	local p50_pre =`r(p50)'
	sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1 & educ_gp==`e', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'17=formula(=(`p50_post' - `p50_pre')), nformat(###,###)

// Partners's change only for when mom up but partner down
* All
	sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1 & educ_gp==`e', detail // pre
	local p50_pre =`r(p50)'
	sum earnings_sp_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1 & educ_gp==`e', detail // post - is this the same as bw60lag==0? okay yes
	local p50_post =`r(p50)'
	putexcel `col1'18=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1 & educ_gp==`e', detail  // pre
	local p50_pre =`r(p50)'
	sum earnings_sp_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1 & educ_gp==`e', detail // post
	local p50_post =`r(p50)'
	putexcel `col1'19=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
*BW only
	sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1 & educ_gp==`e', detail // pre
	local p50_pre =`r(p50)'
	sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1 & educ_gp==`e', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'18=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1 & educ_gp==`e', detail  // pre
	local p50_pre =`r(p50)'
	sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1 & educ_gp==`e', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'19=formula(=(`p50_post' - `p50_pre')), nformat(###,###)

}

local col1x "K M O Q"
local col2x "L N P R"
forvalues r=1/4{
local i = 1
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
    local col1: word `r' of `col1x'	
	local col2: word `r' of `col2x'
	local row1 = `i'*2+2
	local row2 = `i'*2+3
	
* All changes - 1996	
	sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1  & race==`r', detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1  & race==`r', detail // post 
	local p50_post =`r(p50)'
	putexcel `col1'`row1'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	
* BW changes - 1996
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1 & race==`r', detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1 & race==`r', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'`row1'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)

* All changes - 2014
	sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1 & race==`r', detail  // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1 & race==`r', detail // post
	local p50_post =`r(p50)'
	putexcel `col1'`row2'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	
* BW changes - 2014; there is a capture here because race of 3 has no observations for partner-left and became BW
	capture sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1 & race==`r', detail // pre
	capture local p50_pre =`r(p50)'
	capture sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1 & race==`r', detail // post
	capture local p50_post =`r(p50)'
	capture putexcel `col2'`row2'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	
	local ++i
	}
	
// Mother's change only for when mom up but partner down
* All
	sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1 & race==`r', detail // pre
	local p50_pre =`r(p50)'
	sum earnings_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1 & race==`r', detail // post
	local p50_post =`r(p50)'
	putexcel `col1'16=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1 & race==`r', detail  // pre
	local p50_pre =`r(p50)'
	sum earnings_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1 & race==`r', detail // post
	local p50_post =`r(p50)'
	putexcel `col1'17=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
*BW only
	sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1 & race==`r', detail // pre
	local p50_pre =`r(p50)'
	sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1 & race==`r', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'16=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1 & race==`r', detail  // pre
	local p50_pre =`r(p50)'
	sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1 & race==`r', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'17=formula(=(`p50_post' - `p50_pre')), nformat(###,###)

// Partners's change only for when mom up but partner down
* All
	sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1 & race==`r', detail // pre
	local p50_pre =`r(p50)'
	sum earnings_sp_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1 & race==`r', detail // post - is this the same as bw60lag==0? okay yes
	local p50_post =`r(p50)'
	putexcel `col1'18=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1 & race==`r', detail  // pre
	local p50_pre =`r(p50)'
	sum earnings_sp_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1 & race==`r', detail // post
	local p50_post =`r(p50)'
	putexcel `col1'19=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
*BW only
	sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1 & race==`r', detail // pre
	local p50_pre =`r(p50)'
	sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1 & race==`r', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'18=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1 & race==`r', detail  // pre
	local p50_pre =`r(p50)'
	sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1 & race==`r', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'19=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
}

putexcel P11 = 0 // this is to cover the above point about no observations

local col1x "S U W Y"
local col2x "T V X Z"
forvalues a=1/4{
local i = 1
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
    local col1: word `a' of `col1x'	
	local col2: word `a' of `col2x'
	local row1 = `i'*2+2
	local row2 = `i'*2+3
	
* All changes - 1996	
	sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1  & ageb1_cat==`a', detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1  & ageb1_cat==`a', detail // post 
	local p50_post =`r(p50)'
	putexcel `col1'`row1'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	
* BW changes - 1996
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1 & ageb1_cat==`a', detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1 & ageb1_cat==`a', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'`row1'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)

* All changes - 2014
	sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1 & ageb1_cat==`a', detail  // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1 & ageb1_cat==`a', detail // post
	local p50_post =`r(p50)'
	putexcel `col1'`row2'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	
* BW changes - 2014
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1 & ageb1_cat==`a', detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1 & ageb1_cat==`a', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'`row2'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	
	local ++i
	}
	
// Mother's change only for when mom up but partner down
* All
	sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1 & ageb1_cat==`a', detail // pre
	local p50_pre =`r(p50)'
	sum earnings_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1 & ageb1_cat==`a', detail // post
	local p50_post =`r(p50)'
	putexcel `col1'16=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1 & ageb1_cat==`a', detail  // pre
	local p50_pre =`r(p50)'
	sum earnings_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1 & ageb1_cat==`a', detail // post
	local p50_post =`r(p50)'
	putexcel `col1'17=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
*BW only
	sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1 & ageb1_cat==`a', detail // pre
	local p50_pre =`r(p50)'
	sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1 & ageb1_cat==`a', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'16=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1 & ageb1_cat==`a', detail  // pre
	local p50_pre =`r(p50)'
	sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1 & ageb1_cat==`a', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'17=formula(=(`p50_post' - `p50_pre')), nformat(###,###)

// Partners's change only for when mom up but partner down
* All
	sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1 & ageb1_cat==`a', detail // pre
	local p50_pre =`r(p50)'
	sum earnings_sp_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1 & ageb1_cat==`a', detail // post - is this the same as bw60lag==0? okay yes
	local p50_post =`r(p50)'
	putexcel `col1'18=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1 & ageb1_cat==`a', detail  // pre
	local p50_pre =`r(p50)'
	sum earnings_sp_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1 & ageb1_cat==`a', detail // post
	local p50_post =`r(p50)'
	putexcel `col1'19=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
*BW only
	sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1 & ageb1_cat==`a', detail // pre
	local p50_pre =`r(p50)'
	sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1 & ageb1_cat==`a', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'18=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1 & ageb1_cat==`a', detail  // pre
	local p50_pre =`r(p50)'
	sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1 & ageb1_cat==`a', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'19=formula(=(`p50_post' - `p50_pre')), nformat(###,###)

}

local col1x "AA AC"
local col2x "AB AD"
forvalues s=1/2{
local i = 1
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
    local col1: word `s' of `col1x'	
	local col2: word `s' of `col2x'
	local row1 = `i'*2+2
	local row2 = `i'*2+3
	
* All changes - 1996	
	sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1  & status_b1==`s', detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1  & status_b1==`s', detail // post 
	local p50_post =`r(p50)'
	putexcel `col1'`row1'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	
* BW changes - 1996
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1 & status_b1==`s', detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1 & status_b1==`s', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'`row1'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)

* All changes - 2014
	sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1 & status_b1==`s', detail  // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1 & status_b1==`s', detail // post
	local p50_post =`r(p50)'
	putexcel `col1'`row2'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	
* BW changes - 2014
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1 & status_b1==`s', detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1 & status_b1==`s', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'`row2'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	
	local ++i
	}
	
// Mother's change only for when mom up but partner down
* All
	sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1 & status_b1==`s', detail // pre
	local p50_pre =`r(p50)'
	sum earnings_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1 & status_b1==`s', detail // post
	local p50_post =`r(p50)'
	putexcel `col1'16=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1 & status_b1==`s', detail  // pre
	local p50_pre =`r(p50)'
	sum earnings_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1 & status_b1==`s', detail // post
	local p50_post =`r(p50)'
	putexcel `col1'17=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
*BW only
	sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1 & status_b1==`s', detail // pre
	local p50_pre =`r(p50)'
	sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1 & status_b1==`s', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'16=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1 & status_b1==`s', detail  // pre
	local p50_pre =`r(p50)'
	sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1 & status_b1==`s', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'17=formula(=(`p50_post' - `p50_pre')), nformat(###,###)

// Partners's change only for when mom up but partner down
* All
	sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1 & status_b1==`s', detail // pre
	local p50_pre =`r(p50)'
	sum earnings_sp_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1 & status_b1==`s', detail // post - is this the same as bw60lag==0? okay yes
	local p50_post =`r(p50)'
	putexcel `col1'18=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1 & status_b1==`s', detail  // pre
	local p50_pre =`r(p50)'
	sum earnings_sp_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1 & status_b1==`s', detail // post
	local p50_post =`r(p50)'
	putexcel `col1'19=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
*BW only
	sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1 & status_b1==`s', detail // pre
	local p50_pre =`r(p50)'
	sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1 & status_b1==`s', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'18=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1 & status_b1==`s', detail  // pre
	local p50_pre =`r(p50)'
	sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1 & status_b1==`s', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'19=formula(=(`p50_post' - `p50_pre')), nformat(###,###)

}

**# Table 5a:  HH income-to-poverty change with each breadwinner component
putexcel set "$results/Breadwinner_Impact_Tables", sheet(Table3) modify
putexcel C1:J1 = "Overview", merge border(bottom) hcenter
putexcel C2:D2 = "Total", merge border(bottom) hcenter
putexcel E2:F2 = "Ratio Up", merge border(bottom) hcenter
putexcel G2:H2 = "Ratio Down", merge border(bottom) hcenter
putexcel I2:J2 = "Change from 0", merge border(bottom) hcenter
putexcel C3 = ("Incidence") E3 = ("% of Total") G3 = ("% of Total") I3 = ("% of Total")
putexcel D3 = ("Change") F3 = ("Change") H3 = ("Change") J3 = ("Change")
putexcel K1:P1 = "Total", merge border(bottom) hcenter
putexcel K2:M2 = "Pre Transition", merge border(bottom) hcenter
putexcel N2:P2 = "Post Transition", merge border(bottom) hcenter
putexcel K3 = ("Median") L3 = ("% Above 1.5") M3 = ("% Below 1.5")
putexcel N3 = ("Median") O3 = ("% Above 1.5") P3 = ("% Below 1.5")
putexcel Q1:V1 = "Ratio went up", merge border(bottom) hcenter
putexcel Q2:S2 = "Pre Transition", merge border(bottom) hcenter
putexcel T2:V2 = "Post Transition", merge border(bottom) hcenter
putexcel Q3 = ("Median") R3 = ("% Above 1.5") S3 = ("% Below 1.5")
putexcel V3 = ("Median") U3 = ("% Above 1.5") V3 = ("% Below 1.5")
putexcel W1:AB1 = "Ratio went down", merge border(bottom) hcenter
putexcel W2:Y2 = "Pre Transition", merge border(bottom) hcenter
putexcel Z2:AB2 = "Post Transition", merge border(bottom) hcenter
putexcel W3 = ("Median") X3 = ("% Above 1.5") Y3 = ("% Below 1.5")
putexcel Z3 = ("Median") AA3 = ("% Above 1.5") AB3 = ("% Below 1.5")
putexcel AC1:AH1 = "Change from 0", merge border(bottom) hcenter
putexcel AC2:AE2 = "Pre Transition", merge border(bottom) hcenter
putexcel AF2:AH2 = "Post Transition", merge border(bottom) hcenter
putexcel AC3 = ("Median") AD3 = ("% Above 1.5") AE3 = ("% Below 1.5")
putexcel AF3 = ("Median") AG3 = ("% Above 1.5") AH3 = ("% Below 1.5")
putexcel A3 = "Event"
putexcel B3 = "Year"
putexcel A4:A5 = "Mothers only an increase in earnings"
putexcel A6:A7 = "Mothers increase in earnings and partner lost earnings"
putexcel A8:A9 = "Partner lost earnings only"
putexcel A10:A11 = "Partner left"
putexcel A12:A13 = "Other member lost earnings / left"
putexcel B4 = ("1996") B6 = ("1996") B8 = ("1996") B10 = ("1996") B12 = ("1996")
putexcel B5 = ("2014") B7 = ("2014") B9 = ("2014") B11 = ("2014") B13 = ("2014")


* Mothers who experienced change AND became BW
* Overview
local x=1

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	local row1 = `x'*2+2
	sum `var' if trans_bw60_alt2==1 & survey_yr==1 // 1996
	putexcel C`row1'=`r(mean)', nformat(#.##%)
	
	local row2 = `x'*2+3
	sum `var' if trans_bw60_alt2==1 & survey_yr==2 // 2014
	putexcel C`row2'=`r(mean)', nformat(#.##%)

	local ++x
}

* Percent change
//tab inc_pov_move if trans_bw60_alt2==1 & survey_yr==1 & mt_mom==1

local x=1
local colu1 "E G I"

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	forvalues i=1/3{
		local col1: word `i' of `colu1'
		local row1 = `x'*2+2
		sum inc_pov_mv`i' if trans_bw60_alt2==1 & survey_yr==1 & `var'==1, detail // 1996
		putexcel `col1'`row1'=`r(mean)', nformat(#.##%)
		
		local row2 = `x'*2+3
		sum inc_pov_mv`i' if trans_bw60_alt2==1 & survey_yr==2 & `var'==1, detail // 2014
		putexcel `col1'`row2'=`r(mean)', nformat(#.##%)
	}
local ++x
}

*Total Change
sum inc_pov_flag if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2, detail // pre 2014 - gets me above, subtract from 1 to get below
sum inc_pov_flag if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2, detail  // post 2014

//educ
sum inc_pov_flag if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & educ_gp==1, detail // pre 2014 - gets me above, subtract from 1 to get below
sum inc_pov_flag if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & educ_gp==1, detail  // post 2014
sum inc_pov_flag if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & educ_gp==2, detail // pre 2014 - gets me above, subtract from 1 to get below
sum inc_pov_flag if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & educ_gp==2, detail  // post 2014
sum inc_pov_flag if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & educ_gp==3, detail // pre 2014 - gets me above, subtract from 1 to get below
sum inc_pov_flag if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & educ_gp==3, detail  // post 2014

//race
sum inc_pov_flag if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & race==1, detail // pre 2014 - gets me above, subtract from 1 to get below
sum inc_pov_flag if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & race==1, detail  // post 2014
sum inc_pov_flag if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & race==2, detail // pre 2014 - gets me above, subtract from 1 to get below
sum inc_pov_flag if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & race==2, detail  // post 2014
sum inc_pov_flag if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & race==4, detail // pre 2014 - gets me above, subtract from 1 to get below
sum inc_pov_flag if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & race==4, detail  // post 2014

local i=1

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	local row1 = `i'*2+2
		
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1, detail // pre 1996
	putexcel K`row1' =`r(p50)', nformat(#.#)
	sum inc_pov_flag if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1, detail
	putexcel L`row1' = `r(mean)', nformat(#.##%)
	putexcel M`row1' = (1-`r(mean)'), nformat(#.##%)
	
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1, detail // post 1996
	putexcel N`row1'  =`r(p50)', nformat(#.#)
	sum inc_pov_flag if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1, detail 
	putexcel O`row1' = `r(mean)', nformat(#.##%)
	putexcel P`row1' = (1-`r(mean)'), nformat(#.##%)

	local row2 = `i'*2+3
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1, detail  // pre 2014
	putexcel K`row2' =`r(p50)', nformat(#.#)
	sum inc_pov_flag if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1, detail
	putexcel L`row2' = `r(mean)', nformat(#.##%)
	putexcel M`row2' = (1-`r(mean)'), nformat(#.##%)	
	
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1, detail // post 2014
	putexcel N`row2' =`r(p50)', nformat(#.#)
	sum inc_pov_flag if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1, detail 
	putexcel O`row2' = `r(mean)', nformat(#.##%)
	putexcel P`row2' = (1-`r(mean)'), nformat(#.##%)
	
	local ++i
}

// browse SSUID year end_hhsize end_minorchildren threshold thearn_adj inc_pov trans_bw60_alt2 bw60 inc_pov_change inc_pov_change_raw inc_pov_move inc_pov_flag

*Ratio went up
local i=1

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	local row1 = `i'*2+2
		
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1 & inc_pov_move[_n+1]==1, detail // pre 1996
	putexcel Q`row1' =`r(p50)', nformat(#.#)
	sum inc_pov_flag if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1 & inc_pov_move[_n+1]==1, detail
	putexcel R`row1' = `r(mean)', nformat(#.##%)
	putexcel S`row1' = (1-`r(mean)'), nformat(#.##%)
	
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1 & inc_pov_move==1, detail // post 1996
	putexcel T`row1'  =`r(p50)', nformat(#.#)
	sum inc_pov_flag if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1 & inc_pov_move==1, detail 
	putexcel U`row1' = `r(mean)', nformat(#.##%)
	putexcel V`row1' = (1-`r(mean)'), nformat(#.##%)

	local row2 = `i'*2+3
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1 & inc_pov_move[_n+1]==1, detail  // pre 2014
	putexcel Q`row2' =`r(p50)', nformat(#.#)
	sum inc_pov_flag if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1 & inc_pov_move[_n+1]==1, detail
	putexcel R`row2' = `r(mean)', nformat(#.##%)
	putexcel S`row2' = (1-`r(mean)'), nformat(#.##%)	
	
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1 & inc_pov_move==1, detail // post 2014
	putexcel T`row2' =`r(p50)', nformat(#.#)
	sum inc_pov_flag if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1 & inc_pov_move==1, detail 
	putexcel U`row2' = `r(mean)', nformat(#.##%)
	putexcel V`row2' = (1-`r(mean)'), nformat(#.##%)
	
	local ++i
}

*Ratio went down
local i=1

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	local row1 = `i'*2+2
		
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1 & inc_pov_move[_n+1]==2, detail // pre 1996
	putexcel W`row1' =`r(p50)', nformat(#.#)
	sum inc_pov_flag if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1 & inc_pov_move[_n+1]==2, detail
	putexcel X`row1' = `r(mean)', nformat(#.##%)
	putexcel Y`row1' = (1-`r(mean)'), nformat(#.##%)
	
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1 & inc_pov_move==2, detail // post 1996
	putexcel Z`row1'  =`r(p50)', nformat(#.#)
	sum inc_pov_flag if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1 & inc_pov_move==2, detail 
	putexcel AA`row1' = `r(mean)', nformat(#.##%)
	putexcel AB`row1' = (1-`r(mean)'), nformat(#.##%)

	local row2 = `i'*2+3
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1 & inc_pov_move[_n+1]==2, detail  // pre 2014
	putexcel W`row2' =`r(p50)', nformat(#.#)
	sum inc_pov_flag if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1 & inc_pov_move[_n+1]==2, detail
	putexcel X`row2' = `r(mean)', nformat(#.##%)
	putexcel Y`row2' = (1-`r(mean)'), nformat(#.##%)	
	
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1 & inc_pov_move==2, detail // post 2014
	putexcel Z`row2' =`r(p50)', nformat(#.#)
	sum inc_pov_flag if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1 & inc_pov_move==2, detail 
	putexcel AA`row2' = `r(mean)', nformat(#.##%)
	putexcel AB`row2' = (1-`r(mean)'), nformat(#.##%)
	
	local ++i
}

*Change from 0
// have to split this because partner down / partner down + mom up don't have any observations for change from 0

sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & mt_mom[_n+1]==1 & inc_pov_move[_n+1]==3, detail // pre 1996
putexcel AC4 =`r(p50)', nformat(#.#)
sum inc_pov_flag if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & mt_mom[_n+1]==1 & inc_pov_move[_n+1]==3, detail
putexcel AD4 = `r(mean)', nformat(#.##%)
putexcel AE4 = (1-`r(mean)'), nformat(#.##%)

sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & mt_mom==1 & inc_pov_move==3, detail // post 1996
putexcel AF4  =`r(p50)', nformat(#.#)
sum inc_pov_flag if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & mt_mom==1 & inc_pov_move==3, detail 
putexcel AG4 = `r(mean)', nformat(#.##%)
putexcel AH4 = (1-`r(mean)'), nformat(#.##%)

sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & mt_mom[_n+1]==1 & inc_pov_move[_n+1]==3, detail  // pre 2014
putexcel AC5 =`r(p50)', nformat(#.#)
sum inc_pov_flag if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & mt_mom[_n+1]==1 & inc_pov_move[_n+1]==3, detail
putexcel AD5 = `r(mean)', nformat(#.##%)
putexcel AE5 = (1-`r(mean)'), nformat(#.##%)

sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & mt_mom==1 & inc_pov_move==3, detail // post 2014
putexcel AF5 =`r(p50)', nformat(#.#)
sum inc_pov_flag if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & mt_mom==1 & inc_pov_move==3, detail 
putexcel AG5 = `r(mean)', nformat(#.##%)
putexcel AH5 = (1-`r(mean)'), nformat(#.##%)

	
local i=4

foreach var in ft_partner_leave lt_other_changes{
	local row1 = `i'*2+2
		
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1 & inc_pov_move[_n+1]==3, detail // pre 1996
	putexcel AC`row1' =`r(p50)', nformat(#.#)
	sum inc_pov_flag if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1 & inc_pov_move[_n+1]==3, detail
	putexcel AD`row1' = `r(mean)', nformat(#.##%)
	putexcel AE`row1' = (1-`r(mean)'), nformat(#.##%)
	
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1 & inc_pov_move==3, detail // post 1996
	putexcel AF`row1'  =`r(p50)', nformat(#.#)
	sum inc_pov_flag if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1 & inc_pov_move==3, detail 
	putexcel AG`row1' = `r(mean)', nformat(#.##%)
	putexcel AH`row1' = (1-`r(mean)'), nformat(#.##%)

	local row2 = `i'*2+3
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1 & inc_pov_move[_n+1]==3, detail  // pre 2014
	putexcel AC`row2' =`r(p50)', nformat(#.#)
	sum inc_pov_flag if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1 & inc_pov_move[_n+1]==3, detail
	putexcel AD`row2' = `r(mean)', nformat(#.##%)
	putexcel AE`row2' = (1-`r(mean)'), nformat(#.##%)	
	
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1 & inc_pov_move==3, detail // post 2014
	putexcel AF`row2' =`r(p50)', nformat(#.#)
	sum inc_pov_flag if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1 & inc_pov_move==3, detail 
	putexcel AG`row2' = `r(mean)', nformat(#.##%)
	putexcel AH`row2' = (1-`r(mean)'), nformat(#.##%)
	
	local ++i
}

* putting in income-needs ratio change to summarize
forvalues r=4/13{
	putexcel D`r' = formula(=N`r'-K`r'), nformat(#.#)
	putexcel F`r' = formula(=T`r'-Q`r'), nformat(#.#)
	putexcel H`r' = formula(=Z`r'-W`r'), nformat(#.#)
	putexcel J`r' = formula(=AF`r'-AC`r'), nformat(#.#)
}


**Additional analyses

*splitting mother's earnings up only into partnered v. single moms
// tab marital_status_t1 if trans_bw60_alt2==1 & mt_mom==1 // 52% single
// tab marital_status_t1 if trans_bw60_alt2==1 // 42% single
// tab marital_status_t1 if mt_mom==1 // 32% single
// tab marital_status_t1 // 28% single

recode marital_status_t1 (1/2=1)(3=0), gen(partnered)
recode partnered (0=1)(1=0), gen(single)

putexcel A16 = "Mothers only an increase in earnings: partner status breakdown"
putexcel A17 = ("Partnered") A19 = ("Partnered")
putexcel A18 = ("Single") A20 = ("Single")
putexcel B17 = ("1996") B18 = ("1996")
putexcel B19 = ("2014") B20 = ("2014")

sum partnered if trans_bw60_alt2==1 & mt_mom==1 & survey_yr==1 
putexcel C17=`r(mean)', nformat(#.##%)
sum single if trans_bw60_alt2==1 & mt_mom==1 & survey_yr==1 
putexcel C18=`r(mean)', nformat(#.##%)
sum partnered if trans_bw60_alt2==1 & mt_mom==1 & survey_yr==2
putexcel C19=`r(mean)', nformat(#.##%)
sum single if trans_bw60_alt2==1 & mt_mom==1 & survey_yr==2
putexcel C20=`r(mean)', nformat(#.##%)

//tab inc_pov_move if trans_bw60_alt2==1 & survey_yr==1 & mt_mom==1 & partnered==1

local colu1 "E G I"

forvalues i=1/3{
	local col1: word `i' of `colu1'
	sum inc_pov_mv`i' if trans_bw60_alt2==1 & survey_yr==1 & mt_mom==1 & partnered==1, detail // 1996
	putexcel `col1'17=`r(mean)', nformat(#.##%)
	sum inc_pov_mv`i' if trans_bw60_alt2==1 & survey_yr==1 & mt_mom==1 & single==1, detail // 1996
	putexcel `col1'18=`r(mean)', nformat(#.##%)
		
	sum inc_pov_mv`i' if trans_bw60_alt2==1 & survey_yr==2 & mt_mom==1 & partnered==1, detail // 2014
	putexcel `col1'19=`r(mean)', nformat(#.##%)
	sum inc_pov_mv`i' if trans_bw60_alt2==1 & survey_yr==2 & mt_mom==1 & single==1, detail // 2014
	putexcel `col1'20=`r(mean)', nformat(#.##%)
}

*Total Change
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & partnered==1 & mt_mom[_n+1]==1, detail // pre 1996 partnered
	local pre96p = `r(p50)'
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & partnered==1 & mt_mom==1, detail // post 1996 partnered
	local post96p= `r(p50)'
	putexcel D17=(`post96p'-`pre96p'), nformat(#.#)
	
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & single==1 & mt_mom[_n+1]==1, detail // pre 1996 single
	local pre96s = `r(p50)'
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & single==1 & mt_mom==1, detail // post 1996 single
	local post96s= `r(p50)'
	putexcel D18=(`post96s'-`pre96s'), nformat(#.#)	
	
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & partnered==1 & mt_mom[_n+1]==1, detail  // pre 2014
	local pre14p = `r(p50)'
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & partnered==1 & mt_mom==1, detail // post 2014
	local post14p= `r(p50)'
	putexcel D19=(`post14p'-`pre14p'), nformat(#.#)
	
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & single==1 & mt_mom[_n+1]==1, detail  // pre 2014 single
	local pre14s = `r(p50)'
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & single==1 & mt_mom==1, detail // post 2014 single
	local post14s= `r(p50)'
	putexcel D20=(`post14s'-`pre14s'), nformat(#.#)
	
*by ratio change		
local colu1 "F H J"
forvalues i=1/3{
	local col1: word `i' of `colu1'
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & mt_mom[_n+1]==1 & partnered==1 & inc_pov_move[_n+1]==`i', detail // pre 1996 partnered
	local pre96p`i' = `r(p50)'
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & mt_mom==1 & partnered==1 & inc_pov_move==`i', detail // post 1996 partnered
	local post96p`i'= `r(p50)'
	putexcel `col1'17=(`post96p`i''-`pre96p`i''), nformat(#.#)
	
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & mt_mom[_n+1]==1 & single==1 & inc_pov_move[_n+1]==`i', detail // pre 1996 single
	local pre96s`i' = `r(p50)'
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & mt_mom==1 & single==1 & inc_pov_move==`i', detail // post 1996 single
	local post96s`i'= `r(p50)'
	putexcel `col1'18=(`post96s`i''-`pre96s`i''), nformat(#.#)
	
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & mt_mom[_n+1]==1 & partnered==1 & inc_pov_move[_n+1]==`i', detail  // pre 2014 partnered
	local pre14p`i' = `r(p50)'
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & mt_mom==1 & partnered==1 & inc_pov_move==`i', detail // post 2014 partnered
	local post14p`i'= `r(p50)'
	putexcel `col1'19=(`post14p`i''-`pre14p`i''), nformat(#.#)
	
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & mt_mom[_n+1]==1 & single==1 & inc_pov_move[_n+1]==`i', detail  // pre 2014 single
	local pre14s`i' = `r(p50)'
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & mt_mom==1 & single==1 & inc_pov_move==`i', detail // post 2014 single
	local post14s`i'= `r(p50)'
	putexcel `col1'20=(`post14s`i''-`pre14s`i''), nformat(#.#)
}

*Getting mom's income change specifically for one's where partner earnings went down

gen mom_zero_earn=0
replace mom_zero_earn=1 if earnings_adj==0
browse SSUID year earnings_adj mom_zero_earn earnings_sp_adj thearn_adj trans_bw60_alt2 mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes

tab mom_zero_earn if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & ft_partner_down_mom[_n+1]==1
tab mom_zero_earn if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & ft_partner_down_only[_n+1]==1
tab mom_zero_earn if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & mt_mom[_n+1]==1

tab mom_zero_earn if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & ft_partner_down_mom[_n+1]==1 & survey_yr==1 // 11.76%
tab mom_zero_earn if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & ft_partner_down_mom[_n+1]==1 & survey_yr==2 // 15.33%

recode mom_zero_earn (0=1)(1=0), gen(mom_earn)

putexcel A23 = "Mothers increase in earnings and partner lost earnings: breakdown by mom's prior earning status"
putexcel A24 = ("Not Earning") A26 = ("Not Earning")
putexcel A25 = ("Earning") A27 = ("Earning")
putexcel B24 = ("1996") B25 = ("1996")
putexcel B26 = ("2014") B27 = ("2014")

sum mom_zero_earn if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & ft_partner_down_mom[_n+1]==1 & survey_yr==1
putexcel C24=`r(mean)', nformat(#.##%)
sum mom_earn if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & ft_partner_down_mom[_n+1]==1 & survey_yr==1
putexcel C25=`r(mean)', nformat(#.##%)
sum mom_zero_earn if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & ft_partner_down_mom[_n+1]==1 & survey_yr==2
putexcel C26=`r(mean)', nformat(#.##%)
sum mom_earn if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & ft_partner_down_mom[_n+1]==1 & survey_yr==2
putexcel C27=`r(mean)', nformat(#.##%)

//tab inc_pov_move if trans_bw60_alt2==1 & survey_yr==1 & ft_partner_down_mom==1 & mom_zero_earn[_n-1]==1

local colu1 "E G I"

forvalues i=1/3{
	local col1: word `i' of `colu1'
	sum inc_pov_mv`i' if trans_bw60_alt2==1 & survey_yr==1 & ft_partner_down_mom==1 & mom_zero_earn[_n-1]==1 & year==(year[_n-1]+1) & SSUID[_n-1]==SSUID, detail // 1996 not earning
	putexcel `col1'24=`r(mean)', nformat(#.##%)
	sum inc_pov_mv`i' if trans_bw60_alt2==1 & survey_yr==1 & ft_partner_down_mom==1 & mom_zero_earn[_n-1]==0 & year==(year[_n-1]+1) & SSUID[_n-1]==SSUID, detail // 1996 earning
	putexcel `col1'25=`r(mean)', nformat(#.##%)
		
	sum inc_pov_mv`i' if trans_bw60_alt2==1 & survey_yr==2 & ft_partner_down_mom==1 & mom_zero_earn[_n-1]==1 & year==(year[_n-1]+1) & SSUID[_n-1]==SSUID, detail // 2014 not earning
	putexcel `col1'26=`r(mean)', nformat(#.##%)
	sum inc_pov_mv`i' if trans_bw60_alt2==1 & survey_yr==2 & ft_partner_down_mom==1 & mom_zero_earn[_n-1]==0 & year==(year[_n-1]+1) & SSUID[_n-1]==SSUID, detail // 2014 earning
	putexcel `col1'27=`r(mean)', nformat(#.##%)
}

*Total Change
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & mom_zero_earn==1 & ft_partner_down_mom[_n+1]==1, detail // pre 1996 not earning
	local pre96p = `r(p50)'
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & mom_zero_earn[_n-1]==1 & ft_partner_down_mom==1, detail // post 1996 not earning
	local post96p= `r(p50)'
	putexcel D24=(`post96p'-`pre96p'), nformat(#.#)
	
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & mom_zero_earn==0 & ft_partner_down_mom[_n+1]==1, detail // pre 1996 earning
	local pre96s = `r(p50)'
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & mom_zero_earn[_n-1]==0 & ft_partner_down_mom==1, detail // post 1996 earning
	local post96s= `r(p50)'
	putexcel D25=(`post96s'-`pre96s'), nformat(#.#)	
	
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & mom_zero_earn==1 & ft_partner_down_mom[_n+1]==1, detail  // pre 2014 not earning
	local pre14p = `r(p50)'
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & mom_zero_earn[_n-1]==1 & ft_partner_down_mom==1, detail // post 2014 earning
	local post14p= `r(p50)'
	putexcel D26=(`post14p'-`pre14p'), nformat(#.#)
	
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & mom_zero_earn==0 & ft_partner_down_mom[_n+1]==1, detail  // pre 2014 not earning
	local pre14s = `r(p50)'
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2  & mom_zero_earn[_n-1]==0 & ft_partner_down_mom==1, detail // post 2014 earning
	local post14s= `r(p50)'
	putexcel D27=(`post14s'-`pre14s'), nformat(#.#)
	
*by ratio change		
local colu1 "F H J"
forvalues i=1/2{
	local col1: word `i' of `colu1'
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1 & mom_zero_earn==1 & inc_pov_move[_n+1]==`i', detail // pre 1996 not earning
	local pre96p`i' = `r(p50)'
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1 & mom_zero_earn[_n-1]==1 & inc_pov_move==`i', detail // post 1996 not earning
	local post96p`i'= `r(p50)'
	putexcel `col1'24=(`post96p`i''-`pre96p`i''), nformat(#.#)
	
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & ft_partner_down_mom[_n+1]==1 & mom_zero_earn==0 & inc_pov_move[_n+1]==`i', detail // pre 1996 earning
	local pre96s`i' = `r(p50)'
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & ft_partner_down_mom==1 & mom_zero_earn[_n-1]==0 & inc_pov_move==`i', detail // post 1996 earning
	local post96s`i'= `r(p50)'
	putexcel `col1'25=(`post96s`i''-`pre96s`i''), nformat(#.#)
	
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1 & mom_zero_earn==1 & inc_pov_move[_n+1]==`i', detail  // pre 2014 not earning
	local pre14p`i' = `r(p50)'
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1 & mom_zero_earn[_n-1]==1 & inc_pov_move==`i', detail // post 2014 not earning
	local post14p`i'= `r(p50)'
	putexcel `col1'26=(`post14p`i''-`pre14p`i''), nformat(#.#)
	
	sum inc_pov if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1 & mom_zero_earn==0 & inc_pov_move[_n+1]==`i', detail  // pre 2014 earning
	local pre14s`i' = `r(p50)'
	sum inc_pov if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1 & mom_zero_earn[_n-1]==0 & inc_pov_move==`i', detail // post 2014 earning
	local post14s`i'= `r(p50)'
	putexcel `col1'27=(`post14s`i''-`pre14s`i''), nformat(#.#)
}

putexcel A32 = "Event"
putexcel B32 = "Year" 
putexcel A33:A34 = "Mothers only an increase in earnings"
putexcel A35:A36 = "Mothers increase in earnings and partner lost earnings"
putexcel A37:A38 = "Partner lost earnings only"
putexcel A39:A40 = "Partner left"
putexcel A41:A42 = "Other member lost earnings/left"
putexcel B33 = ("1996") B35 = ("1996") B37 = ("1996") B39 = ("1996") B41 = ("1996") 
putexcel B34 = ("2014") B36 = ("2014") B38 = ("2014") B40 = ("2014") B42 = ("2014") 
putexcel C32= ("<50% Up") D32 = (">50% Up") E32 = ("<50% Down") F32 = (">50% Down") G32 = ("Change from 0: below 1") H32 = ("Change from 0: above 1") 

* Percent change
//tab inc_pov_move if trans_bw60_alt2==1 & survey_yr==1 & mt_mom==1

local x=1
local colu1 "C D E F G H"

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	forvalues i=1/6{
		local col1: word `i' of `colu1'
		local row1 = `x'*2+31
		sum inc_pov_pct`i' if trans_bw60_alt2==1 & survey_yr==1 & `var'==1, detail // 1996
		putexcel `col1'`row1'=`r(mean)', nformat(#.##%)
		
		local row2 = `x'*2+32
		sum inc_pov_pct`i' if trans_bw60_alt2==1 & survey_yr==2 & `var'==1, detail // 2014
		putexcel `col1'`row2'=`r(mean)', nformat(#.##%)
	}
local ++x
}


********************************************************************************
**# Table 7: HH economic well-being change when mom becomes BW
********************************************************************************

/* 3 buckets we created for FAMDEM
label define summary 1 "Up, Above Pov" 2 "Up, Not above pov" 3 "Down" 4 "No Change"
label values inc_pov_summary summary

tab inc_pov_summary if trans_bw60_alt2==1
tab inc_pov_summary if trans_bw60_alt2==1 & survey_yr==1
tab inc_pov_summary if trans_bw60_alt2==1 & survey_yr==2
*/

// tab inc_pov_summary, gen(inc_pov_bucket) // 3 categories (Up Above; Up Below; Down)
tab inc_pov_summary2, gen(inc_pov_bucket) // 4 categores (Up Above; Up Below; Down Above; Down Below)

putexcel set "$results/Breadwinner_Impact_Tables", sheet(Table4) modify
putexcel A1:F1 = "Household Economic Well-Being Changes when Mom Becomes Primary Earner: 2014", merge border(bottom) hcenter
putexcel J1:M1 = "1996 Comparison", merge border(bottom) hcenter
putexcel A2 = "Category"
putexcel B2 = "Label"
putexcel A3 = ("Total") B3 = ("Total")
putexcel A4:A6 = "Education"
putexcel B4 = ("HS or Less") B5 = ("Some College") B6 = ("College Plus") 
putexcel A7:A10 = "Race"
putexcel B7 = ("NH White") B8 = ("Black") B9 = ("NH Asian") B10 = ("Hispanic") 
putexcel A11:A14 = "Age at First Birth"
putexcel B11 = ("Younger than 20") B12 = ("20-24") B13 = ("25-29") B14 = ("Older than 30") 
putexcel A15:A16 = "Marital Status at First Birth"
putexcel B15 = ("Married") B16 = ("Never Married")
putexcel A17:A21 = "Pathway"
putexcel B17 = ("Partner Left") B18 = ("Mom Up") B19 = ("Partner Down") B20 = ("Mom Up Partner Down") B21 = ("Other HH Member") 
putexcel C2 = ("Income Up: Above Threshold") D2 = ("Income Up: Below Threshold") E2 = ("Income Down: Above") F2 = ("Income Down: Below") 
putexcel J2 = ("Income Up: Above Threshold") K2 = ("Income Up: Below Threshold") L2 = ("Income Down: Above") M2 = ("Income Down: Below") 

/// split pathways by race / educ
putexcel A23:A27 = "HS or Less", merge hcenter
putexcel A28:A32 = "Some College", merge hcenter
putexcel A33:A37 = "College", merge hcenter
putexcel A38:A42 = "White", merge hcenter
putexcel A43:A47 = "Black", merge hcenter
putexcel A48:A52 = "Hispanic", merge hcenter
putexcel A53:A57 = "Partnered", merge hcenter
putexcel A58:A62 = "Single", merge hcenter
putexcel B23 = ("Partner Left") B24 = ("Mom Up") B25 = ("Partner Down") B26 = ("Mom Up Partner Down") B27 = ("Other HH Member")
putexcel B28 = ("Partner Left") B29 = ("Mom Up") B30 = ("Partner Down") B31 = ("Mom Up Partner Down") B32 = ("Other HH Member")
putexcel B33 = ("Partner Left") B34 = ("Mom Up") B35 = ("Partner Down") B36 = ("Mom Up Partner Down") B37 = ("Other HH Member")
putexcel B38 = ("Partner Left") B39 = ("Mom Up") B40 = ("Partner Down") B41 = ("Mom Up Partner Down") B42 = ("Other HH Member")
putexcel B43 = ("Partner Left") B44 = ("Mom Up") B45 = ("Partner Down") B46 = ("Mom Up Partner Down") B47 = ("Other HH Member")
putexcel B48 = ("Partner Left") B49 = ("Mom Up") B50 = ("Partner Down") B51 = ("Mom Up Partner Down") B52 = ("Other HH Member")
putexcel B53 = ("Partner Left") B54 = ("Mom Up") B55 = ("Partner Down") B56 = ("Mom Up Partner Down") B57 = ("Other HH Member")
putexcel B58 = ("Partner Left") B59 = ("Mom Up") B60 = ("Partner Down") B61 = ("Mom Up Partner Down") B62 = ("Other HH Member")

local colu "C D E F"

forvalues i=1/4{
	local col: word `i' of `colu'
	sum inc_pov_bucket`i' if trans_bw60_alt2==1 & survey_yr==2, detail // 2014
	putexcel `col'3=`r(mean)', nformat(#.##%)
}

local row1 "4 5 6"
forvalues e=1/3{
	local row: word `e' of `row1'
		forvalues i=1/4{
		local col: word `i' of `colu'
		sum inc_pov_bucket`i' if trans_bw60_alt2==1 & survey_yr==2 & educ_gp==`e', detail // 2014
		putexcel `col'`row'=`r(mean)', nformat(#.##%)
	}	
}

local row1 "7 8 9 10"
forvalues r=1/4{
	local row: word `r' of `row1'
		forvalues i=1/4{
		local col: word `i' of `colu'
		sum inc_pov_bucket`i' if trans_bw60_alt2==1 & survey_yr==2 & race==`r', detail // 2014
		putexcel `col'`row'=`r(mean)', nformat(#.##%)
	}	
}

local row1 "11 12 13 14"
forvalues a=1/4{
	local row: word `a' of `row1'
		forvalues i=1/4{
		local col: word `i' of `colu'
		sum inc_pov_bucket`i' if trans_bw60_alt2==1 & survey_yr==2 & ageb1_cat==`a', detail // 2014
		putexcel `col'`row'=`r(mean)', nformat(#.##%)
	}	
}


local row1 "15 16"
forvalues s=1/2{
	local row: word `s' of `row1'
		forvalues i=1/4{
		local col: word `i' of `colu'
		sum inc_pov_bucket`i' if trans_bw60_alt2==1 & survey_yr==2 & status_b1==`s', detail // 2014
		putexcel `col'`row'=`r(mean)', nformat(#.##%)
	}	
}

local row1 "17 18 19 20 21"
local x=1
foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
	local row: word `x' of `row1'
		forvalues i=1/4{
		local col: word `i' of `colu'
		sum inc_pov_bucket`i' if trans_bw60_alt2==1 & survey_yr==2 & `var'==1, detail // 2014
		putexcel `col'`row'=`r(mean)', nformat(#.##%)
	}
local ++x
}

local colu "C D E F"

forvalues e=1/3{
	local x=1
		foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
		local row = (`e' * 5) +17 + `x'
			forvalues i=1/4{
			local col: word `i' of `colu'
			sum inc_pov_bucket`i' if trans_bw60_alt2==1 & survey_yr==2 & `var'==1 &	educ_gp==`e', detail // 2014
			putexcel `col'`row'=`r(mean)', nformat(#.##%)
			}
		local ++x
	}
}


recode race (1=1) (2=2)(4=3)(3=4)(5=4), gen(race_gp)
label define race_gp 1 "White" 2 "Black" 3 "Hispanic"
label values race_gp race_gp

local colu "C D E F"

forvalues r=1/3{
	local x=1
		foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
		local row = (`r' * 5) +32 + `x'
			forvalues i=1/4{
			local col: word `i' of `colu'
			sum inc_pov_bucket`i' if trans_bw60_alt2==1 & survey_yr==2 & `var'==1 &	race_gp==`r', detail // 2014
			putexcel `col'`row'=`r(mean)', nformat(#.##%)
			}
		local ++x
	}
}

recode partnered(0=2) // make single two

local colu "C D E F"

forvalues p=1/2{
	local x=1
		foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
		local row = (`p' * 5) +47 + `x'
			forvalues i=1/4{
			local col: word `i' of `colu'
			sum inc_pov_bucket`i' if trans_bw60_alt2==1 & survey_yr==2 & `var'==1 &	partnered==`p', detail // 2014
			putexcel `col'`row'=`r(mean)', nformat(#.##%)
			}
		local ++x
	}
}

//1996
local colu "J K L M"

forvalues i=1/4{
	local col: word `i' of `colu'
	sum inc_pov_bucket`i' if trans_bw60_alt2==1 & survey_yr==1, detail // 1996
	putexcel `col'3=`r(mean)', nformat(#.##%)
}

local row1 "4 5 6"
forvalues e=1/3{
	local row: word `e' of `row1'
		forvalues i=1/4{
		local col: word `i' of `colu'
		sum inc_pov_bucket`i' if trans_bw60_alt2==1 & survey_yr==1 & educ_gp==`e', detail // 1996
		putexcel `col'`row'=`r(mean)', nformat(#.##%)
	}	
}

local row1 "7 8 9 10"
forvalues r=1/4{
	local row: word `r' of `row1'
		forvalues i=1/4{
		local col: word `i' of `colu'
		sum inc_pov_bucket`i' if trans_bw60_alt2==1 & survey_yr==1 & race==`r', detail // 1996
		putexcel `col'`row'=`r(mean)', nformat(#.##%)
	}	
}

local row1 "11 12 13 14"
forvalues a=1/4{
	local row: word `a' of `row1'
		forvalues i=1/4{
		local col: word `i' of `colu'
		sum inc_pov_bucket`i' if trans_bw60_alt2==1 & survey_yr==1 & ageb1_cat==`a', detail // 1996
		putexcel `col'`row'=`r(mean)', nformat(#.##%)
	}	
}


local row1 "15 16"
forvalues s=1/2{
	local row: word `s' of `row1'
		forvalues i=1/4{
		local col: word `i' of `colu'
		sum inc_pov_bucket`i' if trans_bw60_alt2==1 & survey_yr==1 & status_b1==`s', detail // 1996
		putexcel `col'`row'=`r(mean)', nformat(#.##%)
	}	
}

local row1 "17 18 19 20 21"
local x=1
foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
	local row: word `x' of `row1'
		forvalues i=1/4{
		local col: word `i' of `colu'
		sum inc_pov_bucket`i' if trans_bw60_alt2==1 & survey_yr==1 & `var'==1, detail // 1996
		putexcel `col'`row'=`r(mean)', nformat(#.##%)
	}
local ++x
}


********************************************************************************
**# Table 8a: description of mothers in each pathway
* All mothers, NOT just those who transition
********************************************************************************

putexcel set "$results/Breadwinner_Predictor_Tables", sheet(Table8a) modify
putexcel C1:G1 = "1996", merge border(bottom) hcenter
putexcel H1:L1 = "2014", merge border(bottom) hcenter
putexcel C2 = ("Partner Left") D2 = ("Mom Earnings Up") E2 = ("Partner Lost Earnings")  F2 = ("Mom Up Partner Down")  G2 = ("Other Member Changes") 
putexcel H2 = ("Partner Left") I2 = ("Mom Earnings Up") J2 = ("Partner Lost Earnings")  K2 = ("Mom Up Partner Down")  L2 = ("Other Member Changes") 
putexcel A2 = "Category"
putexcel B2 = "Label"
putexcel A3 = ("Total") B3 = ("Mothers (N)")
putexcel A4:A6 = "Education"
putexcel B4 = ("HS or Less") B5 = ("Some College") B6 = ("College Plus") 
putexcel A7:A10 = "Race"
putexcel B7 = ("NH White") B8 = ("Black") B9 = ("NH Asian") B10 = ("Hispanic") 
putexcel A11:A12 = "Current Partner Status"
putexcel B11 = ("Partnered") B12 = ("Single")
putexcel A13:A14 = "Marital Status at First Birth"
putexcel B13 = ("Married") B14 = ("Never Married")
putexcel A15:A18 = "Age at First Birth"
putexcel B15 = ("Younger than 20") B16 = ("20-24") B17 = ("25-29") B18 = ("Older than 30") 
putexcel A19:A21 = "Work characteristics"
putexcel B19 = ("Average work hours") B20 = ("Average hourly wage") B21 = ("Median annual earnings") 
putexcel A22:A24 = "Partner Education"
putexcel B22 = ("HS or Less") B23 = ("Some College") B24 = ("College Plus") 
putexcel A25:A28 = "Partner Race"
putexcel B25 = ("NH White") B26 = ("Black") B27 = ("NH Asian") B28 = ("Hispanic") 
putexcel A29:A31 = "Partner Work characteristics"
putexcel B29 = ("Average work hours") B30 = ("Average hourly wage") B31 = ("Median annual earnings") 

// creating variables needed that aren't above
recode educ_sp (1/2=1)(3=2)(4=3), gen(educ_gp_sp)
tab educ_gp_sp, gen(educ_gp_sp)

tab race_sp, gen(race_sp)

gen hourly_wage=earnings_adj/avg_mo_hrs/rmwkwjb
// browse SSUID PNUM year earnings_adj avg_mo_hrs rmwkwjb hourly_wage

gen hourly_wage_sp=earnings_sp_adj/avg_mo_hrs_sp/weeks_employed_sp

tab mt_mom if bw60lag==0 // all eligible
tab mt_mom if trans_bw60_alt2==1 & bw60lag==0 // those who transition

tab educ_gp if mt_mom==1 & bw60lag==0 // all eligible
tab educ_gp if mt_mom==1 & trans_bw60_alt2==1 & bw60lag==0 // those who transition

mean educ_gp1 if mt_mom==1 & bw60lag==0
mean educ_gp1 if mt_mom==1 & trans_bw60_alt2==1 & bw60lag==0

tab educ_gp if mt_mom==1 & bw60lag==0 & survey_yr==1 [aweight=wpfinwgt]
tab educ_gp if ft_partner_leave==1 & bw60lag==0 & survey_yr==1 [aweight=wpfinwgt]
tab race if ft_partner_down_mom==1 & bw60lag==0 & survey_yr==1 [aweight=wpfinwgt]

// 1996 estimates
local colu "C D E F G"
local z=1

foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
local col: word `z' of `colu'
local i=1
	foreach gp in educ_gp1 educ_gp2 educ_gp3{		
		local row =`i' + 3
		svy: mean `gp' if `var'==1 & bw60lag==0 & survey_yr==1
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	foreach gp in race1 race2 race3 race4{		
		local row =`i' + 3
		svy: mean `gp' if `var'==1 & bw60lag==0 & survey_yr==1
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	foreach gp in partnered single status_b11 status_b12 ageb11 ageb12 ageb13 ageb14{
		local row =`i' + 3
		svy: mean `gp' if `var'==1 & bw60lag==0 & survey_yr==1
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	foreach gp in avg_mo_hrs hourly_wage earnings_adj{
		local row =`i' + 3
		sum `gp' if `var'==1 & bw60lag==0 & survey_yr==1 [aweight=wpfinwgt], detail
		matrix `var' = `r(p50)'
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
		foreach gp in educ_gp_sp1 educ_gp_sp2 educ_gp_sp3 race_sp1 race_sp2 race_sp3 race_sp4{
		local row =`i' + 3
		svy: mean `gp' if `var'==1 & bw60lag==0 & survey_yr==1
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	foreach gp in avg_mo_hrs_sp hourly_wage_sp earnings_sp_adj{
		local row =`i' + 3
		sum `gp' if `var'==1 & bw60lag==0 & survey_yr==1 [aweight=wpfinwgt], detail
		matrix `var' = `r(p50)'
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
local ++z
}


// 2014 estimates
local colu "H I J K L"
local z=1

foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
local col: word `z' of `colu'
local i=1
	foreach gp in educ_gp1 educ_gp2 educ_gp3{		
		local row =`i' + 3
		svy: mean `gp' if `var'==1 & bw60lag==0 & survey_yr==2
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	foreach gp in race1 race2 race3 race4{		
		local row =`i' + 3
		svy: mean `gp' if `var'==1 & bw60lag==0 & survey_yr==2
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	foreach gp in partnered single status_b11 status_b12 ageb11 ageb12 ageb13 ageb14{
		local row =`i' + 3
		svy: mean `gp' if `var'==1 & bw60lag==0 & survey_yr==2
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	foreach gp in avg_mo_hrs hourly_wage earnings_adj{
		local row =`i' + 3
		sum `gp' if `var'==1 & bw60lag==0 & survey_yr==2 [aweight=wpfinwgt], detail
		matrix `var' = `r(p50)'
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
		foreach gp in educ_gp_sp1 educ_gp_sp2 educ_gp_sp3 race_sp1 race_sp2 race_sp3 race_sp4{
		local row =`i' + 3
		svy: mean `gp' if `var'==1 & bw60lag==0 & survey_yr==2
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	foreach gp in avg_mo_hrs_sp hourly_wage_sp earnings_sp_adj{
		local row =`i' + 3
		sum `gp' if `var'==1 & bw60lag==0 & survey_yr==2 [aweight=wpfinwgt], detail
		matrix `var' = `r(p50)'
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
local ++z
}

* count of N
// 1996
local colu "C D E F G"
local z=1

foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
	local col: word `z' of `colu'
	egen N_`var'1 = count(id) if `var'==1 & bw60lag==0 & survey_yr==1
	sum N_`var'1
	replace N_`var'1 = r(mean)
	local N_`var'1 = N_`var'1
	putexcel `col'3= `N_`var'1', nformat(###,###)
	local ++z
}

// 2014
local colu "H I J K L"
local z=1

foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
	local col: word `z' of `colu'
	egen N_`var'2 = count(id) if `var'==1 & bw60lag==0 & survey_yr==2
	sum N_`var'2
	replace N_`var'2 = r(mean)
	local N_`var'2 = N_`var'2
	putexcel `col'3= `N_`var'2', nformat(###,###)
	local ++z
}

********************************************************************************
**# Table 8b: description of mothers in each pathway
* JUST mothers who transition
********************************************************************************
putexcel set "$results/Breadwinner_Predictor_Tables", sheet(Table8b) modify
putexcel C1:H1 = "1996", merge border(bottom) hcenter
putexcel I1:N1 = "2014", merge border(bottom) hcenter
putexcel C2 = ("Partner Left") D2 = ("Mom Earnings Up") E2 = ("Partner Lost Earnings")  F2 = ("Mom Up Partner Down")  G2 = ("Other Member Changes") H2 = ("Became Mom in Panel")
putexcel I2 = ("Partner Left") J2 = ("Mom Earnings Up") K2 = ("Partner Lost Earnings")  L2 = ("Mom Up Partner Down")  M2 = ("Other Member Changes") N2 = ("Became Mom in Panel")
putexcel A2 = "Category"
putexcel B2 = "Label"
putexcel A3 = ("Total") B3 = ("Mothers (N)")
putexcel A4:A6 = "Education"
putexcel B4 = ("HS or Less") B5 = ("Some College") B6 = ("College Plus") 
putexcel A7:A10 = "Race"
putexcel B7 = ("NH White") B8 = ("Black") B9 = ("NH Asian") B10 = ("Hispanic") 
putexcel A11:A12 = "Current Partner Status"
putexcel B11 = ("Partnered") B12 = ("Single")
putexcel A13:A14 = "Marital Status at First Birth"
putexcel B13 = ("Married") B14 = ("Never Married")
putexcel A15:A18 = "Age at First Birth"
putexcel B15 = ("Younger than 20") B16 = ("20-24") B17 = ("25-29") B18 = ("Older than 30") 
putexcel A19:A21 = "Work characteristics"
putexcel B19 = ("Average work hours") B20 = ("Average hourly wage") B21 = ("Median annual earnings") 
putexcel A22:A24 = "Partner Education"
putexcel B22 = ("HS or Less") B23 = ("Some College") B24 = ("College Plus") 
putexcel A25:A28 = "Partner Race"
putexcel B25 = ("NH White") B26 = ("Black") B27 = ("NH Asian") B28 = ("Hispanic") 
putexcel A29:A31 = "Partner Work characteristics"
putexcel B29 = ("Average work hours") B30 = ("Average hourly wage") B31 = ("Median annual earnings") 


// 1996 estimates
local colu "C D E F G"
local z=1

foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
local col: word `z' of `colu'
local i=1
	foreach gp in educ_gp1 educ_gp2 educ_gp3{		
		local row =`i' + 3
		svy: mean `gp' if `var'==1 & bw60lag==0 & survey_yr==1 & trans_bw60_alt2==1
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		svy: mean `gp' if firstbirth==1 & mom_panel==1 & bw60_mom==1 & survey_yr==1
		matrix `var'=e(b)
		putexcel H`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	foreach gp in race1 race2 race3 race4{		
		local row =`i' + 3
		svy: mean `gp' if `var'==1 & bw60lag==0 & survey_yr==1 & trans_bw60_alt2==1
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		svy: mean `gp' if firstbirth==1 & mom_panel==1 & bw60_mom==1 & survey_yr==1
		matrix `var'=e(b)
		putexcel H`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	foreach gp in partnered single status_b11 status_b12 ageb11 ageb12 ageb13 ageb14{
		local row =`i' + 3
		svy: mean `gp' if `var'==1 & bw60lag==0 & survey_yr==1 & trans_bw60_alt2==1
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		svy: mean `gp' if firstbirth==1 & mom_panel==1 & bw60_mom==1 & survey_yr==1
		matrix `var'=e(b)
		putexcel H`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	foreach gp in avg_mo_hrs hourly_wage earnings_adj{
		local row =`i' + 3
		sum `gp' if `var'==1 & bw60lag==0 & survey_yr==1 & trans_bw60_alt2==1 [aweight=wpfinwgt], detail
		matrix `var' = `r(p50)'
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		sum `gp' if firstbirth==1 & mom_panel==1 & bw60_mom==1 & survey_yr==1 [aweight=wpfinwgt], detail
		matrix `var'=`r(p50)'
		putexcel H`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
		foreach gp in educ_gp_sp1 educ_gp_sp2 educ_gp_sp3 race_sp1 race_sp2 race_sp3 race_sp4{
		local row =`i' + 3
		svy: mean `gp' if `var'==1 & bw60lag==0 & survey_yr==1 & trans_bw60_alt2==1
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		svy: mean `gp' if firstbirth==1 & mom_panel==1 & bw60_mom==1 & survey_yr==1
		matrix `var'=e(b)
		putexcel H`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	foreach gp in avg_mo_hrs_sp hourly_wage_sp earnings_sp_adj{
		local row =`i' + 3
		sum `gp' if `var'==1 & bw60lag==0 & survey_yr==1 & trans_bw60_alt2==1 [aweight=wpfinwgt], detail
		matrix `var' = `r(p50)'
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		sum `gp' if firstbirth==1 & mom_panel==1 & bw60_mom==1 & survey_yr==1 [aweight=wpfinwgt], detail
		matrix `var'=`r(p50)'
		putexcel H`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
local ++z
}

// 2014 estimates
local colu "I J K L M"
local z=1

foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
local col: word `z' of `colu'
local i=1
	foreach gp in educ_gp1 educ_gp2 educ_gp3{		
		local row =`i' + 3
		svy: mean `gp' if `var'==1 & bw60lag==0 & survey_yr==2 & trans_bw60_alt2==1
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		svy: mean `gp' if firstbirth==1 & mom_panel==1 & bw60_mom==1 & survey_yr==2
		matrix `var'=e(b)
		putexcel N`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	foreach gp in race1 race2 race3 race4{		
		local row =`i' + 3
		svy: mean `gp' if `var'==1 & bw60lag==0 & survey_yr==2 & trans_bw60_alt2==1
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		svy: mean `gp' if firstbirth==1 & mom_panel==1 & bw60_mom==1 & survey_yr==2
		matrix `var'=e(b)
		putexcel N`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	foreach gp in partnered single status_b11 status_b12 ageb11 ageb12 ageb13 ageb14{
		local row =`i' + 3
		svy: mean `gp' if `var'==1 & bw60lag==0 & survey_yr==2 & trans_bw60_alt2==1
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		svy: mean `gp' if firstbirth==1 & mom_panel==1 & bw60_mom==1 & survey_yr==2
		matrix `var'=e(b)
		putexcel N`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	foreach gp in avg_mo_hrs hourly_wage earnings_adj{
		local row =`i' + 3
		sum `gp' if `var'==1 & bw60lag==0 & survey_yr==2 & trans_bw60_alt2==1 [aweight=wpfinwgt], detail
		matrix `var' = `r(p50)'
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		sum `gp' if firstbirth==1 & mom_panel==1 & bw60_mom==1 & survey_yr==2 [aweight=wpfinwgt], detail
		matrix `var'=`r(p50)'
		putexcel N`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
		foreach gp in educ_gp_sp1 educ_gp_sp2 educ_gp_sp3 race_sp1 race_sp2 race_sp3 race_sp4{
		local row =`i' + 3
		svy: mean `gp' if `var'==1 & bw60lag==0 & survey_yr==2 & trans_bw60_alt2==1
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		svy: mean `gp' if firstbirth==1 & mom_panel==1 & bw60_mom==1 & survey_yr==2
		matrix `var'=e(b)
		putexcel N`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	foreach gp in avg_mo_hrs_sp hourly_wage_sp earnings_sp_adj{
		local row =`i' + 3
		sum `gp' if `var'==1 & bw60lag==0 & survey_yr==2 & trans_bw60_alt2==1 [aweight=wpfinwgt], detail
		matrix `var' = `r(p50)'
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		sum `gp' if firstbirth==1 & mom_panel==1 & bw60_mom==1 & survey_yr==2 [aweight=wpfinwgt], detail
		matrix `var'=`r(p50)'
		putexcel N`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
local ++z
}

* count of N
// 1996
local colu "C D E F G"
local z=1

foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
	local col: word `z' of `colu'
	egen N_`var'1bw = count(id) if `var'==1 & bw60lag==0 & survey_yr==1 & trans_bw60_alt2==1
	sum N_`var'1bw
	replace N_`var'1bw = r(mean)
	local N_`var'1bw = N_`var'1bw
	putexcel `col'3= `N_`var'1bw', nformat(###,###)
	local ++z
}

egen N_mom_panel1bw = count(id) if firstbirth==1 & mom_panel==1 & bw60_mom==1 & survey_yr==1 
sum N_mom_panel1bw
replace N_mom_panel1bw = r(mean)
local N_mom_panel1bw = N_mom_panel1bw
putexcel H3= `N_mom_panel1bw', nformat(###,###)

// 2014
local colu "I J K L M"
local z=1

foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
	local col: word `z' of `colu'
	egen N_`var'2bw = count(id) if `var'==1 & bw60lag==0 & survey_yr==2  & trans_bw60_alt2==1
	sum N_`var'2bw
	replace N_`var'2bw = r(mean)
	local N_`var'2bw = N_`var'2bw
	putexcel `col'3= `N_`var'2bw', nformat(###,###)
	local ++z
}

egen N_mom_panel2bw = count(id) if firstbirth==1 & mom_panel==1 & bw60_mom==1 & survey_yr==2
sum N_mom_panel2bw
replace N_mom_panel2bw = r(mean)
local N_mom_panel2bw = N_mom_panel2bw
putexcel N3= `N_mom_panel2bw', nformat(###,###)

********************************************************************************
**# Table 9: Distribution of Pathways by Demographic Characteristics
********************************************************************************

putexcel set "$results/Breadwinner_Predictor_Tables", sheet(Table9) modify
putexcel A1:G1 = "Distribution of Pathways by Demographic Characteristics: 2014", merge border(bottom) hcenter
putexcel A2 = "Category"
putexcel B2 = "Label"
putexcel A3 = ("Total") B3 = ("Total")
putexcel A4:A6 = "Education"
putexcel B4 = ("HS or Less") B5 = ("Some College") B6 = ("College Plus") 
putexcel A7:A10 = "Race"
putexcel B7 = ("NH White") B8 = ("Black") B9 = ("NH Asian") B10 = ("Hispanic") 
putexcel A11:A14 = "Age at First Birth"
putexcel B11 = ("Younger than 20") B12 = ("20-24") B13 = ("25-29") B14 = ("Older than 30") 
putexcel A15:A16 = "Marital Status at First Birth"
putexcel B15 = ("Married") B16 = ("Never Married")
putexcel C2 = ("Partner Left") D2 = ("Mom Up") E2 = ("Partner Down") F2 = ("Mom Up Partner Down") G2 = ("Other HH Member") 

local colu "C D E F G"

local x=1
foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
	local col: word `x' of `colu'
	sum `var' if trans_bw60_alt2==1 & survey_yr==2, detail // 2014
	putexcel `col'3=`r(mean)', nformat(#.##%)
	local ++x
}

local row1 "4 5 6"
local x=1
foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
	forvalues e=1/3{
		local row: word `e' of `row1'
		local col: word `x' of `colu'
		sum `var' if trans_bw60_alt2==1 & survey_yr==2 & educ_gp==`e', detail // 2014
		putexcel `col'`row'=`r(mean)', nformat(#.##%)
	}	
local ++x
}

local row1 "7 8 9 10"
local x=1
foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
	forvalues r=1/4{
		local row: word `r' of `row1'
		local col: word `x' of `colu'
		sum `var' if trans_bw60_alt2==1 & survey_yr==2 & race==`r', detail // 2014
		putexcel `col'`row'=`r(mean)', nformat(#.##%)
	}	
local ++x
}

local row1 "11 12 13 14"
local x=1
foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
	forvalues a=1/4{
		local row: word `a' of `row1'
		local col: word `x' of `colu'
		sum `var' if trans_bw60_alt2==1 & survey_yr==2 & ageb1_cat==`a', detail // 2014
		putexcel `col'`row'=`r(mean)', nformat(#.##%)
	}	
local ++x
}


local row1 "15 16"
local x=1
foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
	forvalues s=1/2{
		local row: word `s' of `row1'
		local col: word `x' of `colu'
		sum `var' if trans_bw60_alt2==1 & survey_yr==2 & status_b1==`s', detail // 2014
		putexcel `col'`row'=`r(mean)', nformat(#.##%)
	}	
local ++x
}


********************************************************************************
**# Table 10: Description of mothers in each income change bucket
********************************************************************************
putexcel set "$results/Breadwinner_Impact_Tables", sheet(Table5) modify
putexcel C1:F1 = "2014", merge border(bottom) hcenter
putexcel C2 = ("Income Up: Above") D2 = ("Income Up: Below") E2 = ("Income Down: Above")  F2 = ("Income Down: Below")
putexcel A2 = "Category"
putexcel B2 = "Label"
putexcel A3 = ("Total") B3 = ("Mothers (N)")
putexcel A4:A6 = "Education"
putexcel B4 = ("HS or Less") B5 = ("Some College") B6 = ("College Plus") 
putexcel A7:A10 = "Race"
putexcel B7 = ("NH White") B8 = ("Black") B9 = ("NH Asian") B10 = ("Hispanic") 
putexcel A11:A12 = "Current Partner Status"
putexcel B11 = ("Partnered") B12 = ("Single")
putexcel A13:A14 = "Marital Status at First Birth"
putexcel B13 = ("Married") B14 = ("Never Married")
putexcel A15:A18 = "Age at First Birth"
putexcel B15 = ("Younger than 20") B16 = ("20-24") B17 = ("25-29") B18 = ("Older than 30") 
putexcel A19:A21 = "Work characteristics"
putexcel B19 = ("Average work hours") B20 = ("Average hourly wage") B21 = ("Median annual earnings") 
putexcel A22:A24 = "Partner Education"
putexcel B22 = ("HS or Less") B23 = ("Some College") B24 = ("College Plus") 
putexcel A25:A28 = "Partner Race"
putexcel B25 = ("NH White") B26 = ("Black") B27 = ("NH Asian") B28 = ("Hispanic") 
putexcel A29:A31 = "Partner Work characteristics"
putexcel B29 = ("Average work hours") B30 = ("Average hourly wage") B31 = ("Median annual earnings") 

// 2014 estimates
local colu "C D E F"
local z=1

foreach var in inc_pov_bucket1 inc_pov_bucket2 inc_pov_bucket3 inc_pov_bucket4{
local col: word `z' of `colu'
local i=1
	foreach gp in educ_gp1 educ_gp2 educ_gp3{		
		local row =`i' + 3
		svy: mean `gp' if `var'==1 & bw60lag==0 & survey_yr==2 & trans_bw60_alt2==1
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	foreach gp in race1 race2 race3 race4{		
		local row =`i' + 3
		svy: mean `gp' if `var'==1 & bw60lag==0 & survey_yr==2 & trans_bw60_alt2==1
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	foreach gp in partnered single status_b11 status_b12 ageb11 ageb12 ageb13 ageb14{
		local row =`i' + 3
		svy: mean `gp' if `var'==1 & bw60lag==0 & survey_yr==2 & trans_bw60_alt2==1
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	foreach gp in avg_mo_hrs hourly_wage earnings_adj{
		local row =`i' + 3
		sum `gp' if `var'==1 & bw60lag==0 & survey_yr==2 & trans_bw60_alt2==1 [aweight=wpfinwgt], detail
		matrix `var' = `r(p50)'
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
		foreach gp in educ_gp_sp1 educ_gp_sp2 educ_gp_sp3 race_sp1 race_sp2 race_sp3 race_sp4{
		local row =`i' + 3
		svy: mean `gp' if `var'==1 & bw60lag==0 & survey_yr==2 & trans_bw60_alt2==1
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	foreach gp in avg_mo_hrs_sp hourly_wage_sp earnings_sp_adj{
		local row =`i' + 3
		sum `gp' if `var'==1 & bw60lag==0 & survey_yr==2 & trans_bw60_alt2==1 [aweight=wpfinwgt], detail
		matrix `var' = `r(p50)'
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
local ++z
}

* count of N
// 2014
local colu "C D E F"
local z=1

foreach var in inc_pov_bucket1 inc_pov_bucket2 inc_pov_bucket3 inc_pov_bucket4{
	local col: word `z' of `colu'
	egen N_`var' = count(id) if `var'==1 & bw60lag==0 & survey_yr==2  & trans_bw60_alt2==1
	sum N_`var'
	replace N_`var' = r(mean)
	local N_`var' = N_`var'
	putexcel `col'3= `N_`var'', nformat(###,###)
	local ++z
}

********************************************************************************
**#  Misc things
********************************************************************************
* For paper, % prevalence of breadwinning over time
	* Just wave 1
	tab survey bw60 if year==1996 | year==2013, row // 25.09% to 28.11%
	* Total
	tab survey bw60, row // 25.42% to 27.56%
	
* Ratio of mother's earnings to partner earnings specifically
egen couple_earnings = rowtotal(earnings earnings_sp)
gen mom_part = earnings / earnings_sp if earnings_sp!=.
sum mom_part, detail // 31.6%
sum mom_part if marital_status_t1==1, detail // married: 30.6%
sum mom_part if marital_status_t1==2, detail // cohab: 38.2%
sum mom_part if survey==2014, detail // 31.6%

sum earnings if earnings_sp!=. & survey==2014, detail // p50: 15608, mean: 26548
sum earnings_sp if earnings_sp!=. & survey==2014, detail // p50: 44423, mean: 63367

gen earnings_ratio_partner = earnings / couple_earnings

// browse SSUID PNUM year earnings earnings_sp couple_earnings mom_part earnings_ratio_partner  

* Total ratio by year
gen earnings_ratio_mis=earnings_ratio
replace earnings_ratio_mis=0 if earnings_ratio==.

tabstat earnings_ratio_mis, by(survey) stats(mean p50)
* Mean: 37.4% to 38.4% P50: 30.1% to 30.9%
tabstat earnings_ratio_mis if trans_bw60_alt2==1, by(survey) stats(mean p50)
* Mean: 84.6% to 84.0% P50: 88.2% to 84.9%
tabstat earnings_ratio_partner, by(survey) stats(mean p50)
tabstat mom_part, by(survey) stats(mean p50)

tabstat mom_part if survey==1996, by(educ_gp) stats(mean p50)
tabstat mom_part if survey==2014, by(educ_gp) stats(mean p50)

// to compare to child support exercise
tabstat earnings_ratio_mis if race==3, by(survey) stats(mean p50) // okay yes, is also going down here
tabstat mom_part if race==3, by(survey) stats(mean p50) // oh wow, really going down here
tab survey trans_bw60_alt2 if race==3 & bw60lag==0, row // even though more becoming BW...
tab survey bw60 if race==3, row // interesting...

* ttest
svyset [pweight=scaled_weight]
tab survey trans_bw60_alt2 if bw60lag==0, row
svy: tab survey trans_bw60_alt2 if bw60lag==0, row
ttest trans_bw60_alt2 if bw60lag==0, by(survey)
// svy: ttest trans_bw60_alt2 if bw60lag==0, by(survey)
logit trans_bw60_alt2 if bw60lag==0
logit trans_bw60_alt2 i.survey if bw60lag==0
margins survey
svy: logit trans_bw60_alt2 i.survey if bw60lag==0
margins survey

// eligible mothers
tab survey_yr bw60

// Distributions
browse SSUID PNUM year bw60 bw60lag trans_bw60_alt2

* All mothers eligible to transition to BW: HH earnings distribution in year she isn't BW (aka can then become)
histogram thearn_adj if bw60==0 & thearn_adj<=100000, width(5000) percent addlabel addlabopts(mlabsize(vsmall)) xlabel(0(5000)100000,  angle(45)) title("Household earnings when mother eligible to transition") xtitle("HH earnings") // with 0 earnings included
graph export "$results/income_all_eligible_moms_0.png", as(png) name("Graph") replace

histogram thearn_adj if bw60==0 & thearn_adj>0 & thearn_adj<=100000, width(5000) percent addlabel addlabopts(mlabsize(vsmall)) xlabel(0(5000)100000,  angle(45)) title("Household earnings when mother eligible to transition") xtitle("HH earnings") // with 0 earnings excluded
graph export "$results/income_all_eligible_moms_no0.png", as(png) name("Graph") replace

* Mothers who do transition: HH earnings distribution year prior to transition
histogram thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & thearn_adj<=100000, width(5000) percent addlabel addlabopts(mlabsize(vsmall)) xlabel(0(5000)100000,  angle(45)) title("Household earnings year prior to transition") xtitle("HH earnings") // with 0 earnings included
graph export "$results/income_year_prior_0.png", as(png) name("Graph") replace

histogram thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & thearn_adj>0 & thearn_adj<=100000, width(5000) percent addlabel addlabopts(mlabsize(vsmall)) xlabel(0(5000)100000,  angle(45)) title("Household earnings year prior to transition") xtitle("HH earnings") // with 0 earnings excluded
graph export "$results/income_year_prior_no0.png", as(png) name("Graph") replace

* Mothers who do transition: HH earnings distribution year of transition
histogram thearn_adj if trans_bw60_alt2==1 & bw60lag==0 & thearn_adj<=100000, width(5000) percent addlabel addlabopts(mlabsize(vsmall)) xlabel(0(5000)100000,  angle(45)) title("Household earnings when mother becomes primary earner") xtitle("HH earnings")
graph export "$results/income_post_transition.png", as(png) name("Graph") replace

* All eligible mothers: mom's % earnings distribution
histogram earnings_ratio if bw60==0, width(.10) percent addlabel xlabel(0(.1)1) title("Earnings ratio when mother eligible to transition") xtitle("Mom Earnings Ratio") 
graph export "$results/ratio_all_eligible_moms.png", as(png) name("Graph") replace

histogram earnings_ratio if bw60==0 & survey==1996, width(.10) percent addlabel xlabel(0(.1)1) title("Earnings ratio when mother eligible to transition") xtitle("Mom Earnings Ratio") 
histogram earnings_ratio if bw60==0 & survey==2014, width(.10) percent addlabel xlabel(0(.1)1) title("Earnings ratio when mother eligible to transition") xtitle("Mom Earnings Ratio") 

* Mothers who transition: mom's % earnings distribution year prior to transition
histogram earnings_ratio if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID, width(.10) percent addlabel xlabel(0(.1)1) title("Earnings ratio year prior to transition") xtitle("Mom Earnings Ratio")
graph export "$results/ratio_year_prior.png", as(png) name("Graph") replace

histogram earnings_ratio if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey==1996, width(.10) percent addlabel xlabel(0(.1)1) title("1996 Earnings ratio year prior to transition") xtitle("Mom Earnings Ratio")
graph export "$results/ratio_year_prior_1996.png", as(png) name("Graph") replace

histogram earnings_ratio if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey==2014, width(.10) percent addlabel xlabel(0(.1)1) title("2014 Earnings ratio year prior to transition") xtitle("Mom Earnings Ratio")
graph export "$results/ratio_year_prior_2014.png", as(png) name("Graph") replace

* Mothers who transition: mom's % earnings distribution the year she transitions
histogram earnings_ratio if trans_bw60_alt2==1 & bw60lag==0, width(.10) percent addlabel xlabel(0(.1)1) title("Earnings ratio year mom transitions") xtitle("Mom Earnings Ratio")
graph export "$results/ratio_post_transition.png", as(png) name("Graph") replace

histogram earnings_ratio if trans_bw60_alt2==1 & bw60lag==0 & survey==1996, width(.10) percent addlabel xlabel(0(.1)1) title("1996 Earnings ratio year mom transitions") xtitle("Mom Earnings Ratio")
graph export "$results/ratio_post_transition_1996.png", as(png) name("Graph") replace

histogram earnings_ratio if trans_bw60_alt2==1 & bw60lag==0 & survey==2014, width(.10) percent addlabel xlabel(0(.1)1) title("2014 Earnings ratio year mom transitions") xtitle("Mom Earnings Ratio")
graph export "$results/ratio_post_transition_2014.png", as(png) name("Graph") replace

* Income poverty ratio for women who became moms in SIPP
tab inc_pov_flag if firstbirth==1 & mom_panel==1 // this is just moms who had first birth during SIPP, didn't have to be BW
tab inc_pov_flag if firstbirth==1 & mom_panel==1 & bw60_mom==1 // moms had first birth during SIPP and were BW at time
tab inc_pov_flag if firstbirth==1 & mom_panel==1 & bw60_mom==1 & survey==1996
tab inc_pov_flag if firstbirth==1 & mom_panel==1 & bw60_mom==1 & survey==2014

********************************************************************************
* Pathway comparison
********************************************************************************
gen pathway=0
replace pathway=1 if mt_mom==1
replace pathway=2 if ft_partner_down_mom==1
replace pathway=3 if ft_partner_down_only==1
replace pathway=4 if ft_partner_leave==1
replace pathway=5 if lt_other_changes==1

label define pathway 0 "None" 1 "Mom Up" 2 "Mom Up Partner Down" 3 "Partner Down" 4 "Partner Left" 5 "Other HH Change"
label values pathway pathway

tab survey_yr pathway if trans_bw60_alt2==1 & bw60lag==0, row
tab survey_yr pathway if trans_bw60_alt2==1 & bw60lag==0 & durmom_1st <=18 & durmom_1st >=0, row // compare to if oldest child is under 18

tab survey_yr trans_bw60_alt2 if bw60lag==0 [aweight=wpfinwgt], row
tab survey_yr trans_bw60_alt2 if bw60lag==0 & durmom_1st <=18 & durmom_1st >=0 [aweight=wpfinwgt], row

/*
********************************************************************************
* Figures
********************************************************************************

// Figure 1: Pie Chart for Incidence
putexcel set "$results/Breadwinner_Predictor_Fig1", sheet(Fig1) replace
putexcel A1 = "Event"
putexcel B1 = "Year"
putexcel C1 = "All_events"
putexcel D1 = "Event_precipitated"
putexcel A2:A3 = "Mothers only an increase in earnings"
putexcel A4:A5 = "Mothers increase in earnings and partner lost earnings"
putexcel A6:A7 = "Partner lost earnings only"
putexcel A8:A9 = "Partner left"
putexcel A10:A11 = "Other member lost earnings / left"
putexcel A12:A13 = "No Changes"
putexcel B2 = ("1996") B4 = ("1996") B6 = ("1996") B8 = ("1996") B10 = ("1996") B12 = ("1996") 
putexcel B3 = ("2014") B5 = ("2014") B7 = ("2014") B9 = ("2014") B11 = ("2014") B13 = ("2014")

local i=1
local row1 "2 4 6 8 10 3 5 7 9 11"

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local row: word `i' of `row1'
		putexcel C`row' = matrix(`var'_1), nformat(#.##%)
		putexcel D`row' = matrix(`var'_1_bw), nformat(#.##%)
		local ++i
}

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local row: word `i' of `row1'
		putexcel C`row' = matrix(`var'_2), nformat(#.##%)
		putexcel D`row' = matrix(`var'_2_bw), nformat(#.##%)
		local ++i
}

putexcel C12 = formula(1-(C2+C4+C6+C8+C10)), nformat(#.##%)
putexcel C13 = formula(1-(C3+C5+C7+C9+C11)), nformat(#.##%)

import excel "$results/Breadwinner_Predictor_Fig1", sheet(Fig1) firstrow case(lower) clear

graph pie all_events if year=="1996", over(event) title("1996 Incidence of Precipitating Events") plabel(_all percent, color(white) format(%4.1f)) sort descending ///
pie(1, color(gs10)) pie(2, color(navy)) pie(3, color(green)) pie(4, color(orange)) pie(5, color(maroon)) pie(6, color(purple))
graph export "$results/Events_1996.png", as(png) name("Graph") replace

graph pie all_events if year=="2014", over(event) title("2014 Incidence of Precipitating Events") plabel(_all percent, color(white) format(%4.1f)) sort descending ///
pie(1, color(gs10)) pie(2, color(navy)) pie(3, color(green)) pie(4, color(orange)) pie(5, color(maroon)) pie(6, color(purple))
graph export "$results/Events_2014.png", as(png) name("Graph") replace

// Figure 2: Bar Chart for income

/* commenting out - moving to R
***************************************** NOTE: sometimes this is working for me directly and othertimes, it is not. The best way I have found at the moment is to have to open and paste the formulas in Table 4 as values. I appreciate this is not sustainable. I am going to work on hardcoding so this step is not necessary, but I need a break from attempting to figure this out. Clearing doesn't work, putexcel save / clear doesn't work. I can't figure out what I am doing when it does work and when it doesn't**************88

import excel "$results/Breadwinner_Predictor_Tables", sheet(Table4) firstrow case(lower) clear

label define categories 1 "HS or Less" 2 "Some College" 3 "College Plus" 4 "NH White" 5 "Black" 6 "NH Asian" 7 "Hispanic"
label values value categories

graph bar change_1996 change_2014 if category=="Education", over(value) blabel(bar, format(%9.2f)) title ("Change in Median Household Income upon BW Transition") subtitle("by education") ytitle("Percentage Change post-Transition")  legend(label(1 "1996") label(2 "2014") size(small)) plotregion(fcolor(white)) graphregion(fcolor(white)) ylabel(-.6(.2).2, labsize(small))
graph export "$results/Income_Education.png", as(png) name("Graph") replace

graph bar change_1996 change_2014 if category=="Race", over(value) blabel(bar, format(%9.2f)) title ("Change in Median Household Income upon BW Transition") subtitle("by race / ethnicity") ytitle("Percentage Change post-Transition")  legend(label(1 "1996") label(2 "2014") size(small)) plotregion(fcolor(white)) graphregion(fcolor(white)) ylabel(-.6(.2).2, labsize(small))
graph export "$results/Income_Race.png", as(png) name("Graph") replace

graph bar change_1996 change_2014 if category=="Total", blabel(bar, format(%9.2f)) title ("Change in Median Household Income upon BW Transition") subtitle("overall") ytitle("Percentage Change post-Transition")  legend(label(1 "1996") label(2 "2014") size(small)) plotregion(fcolor(white)) graphregion(fcolor(white)) ylabel(-.6(.2).2, labsize(small)) bargap(10)  outergap(*5) 
graph export "$results/Income_Total.png", as(png) name("Graph") replace
*/
*/

/*
********************************************************************************
* Limited to children in residence at start and end of year
********************************************************************************

*Dt-l: mothers not breadwinning at t-1
tab survey bw60 if minors_fy==1 // want those with a 0

*Mt = The proportion of mothers who experienced an increase in earnings. This is equal to the number of mothers who experienced an increase in earnings divided by Dt-1. Mothers only included if no one else in the HH experienced a change.
	
tab survey mt_mom if minors_fy==1
tab survey momup_only if minors_fy==1

*Bmt = the proportion of mothers who experience an increase in earnings that became breadwinners. This is equal to the number of mothers who experience an increase in earnings and became breadwinners divided by Mt.

tab mt_mom trans_bw60_alt2 if survey==1996 & minors_fy==1
tab mt_mom trans_bw60_alt2 if survey==2014 & minors_fy==1

tab momup_only trans_bw60_alt2 if survey==1996 & minors_fy==1
tab momup_only trans_bw60_alt2 if survey==2014 & minors_fy==1

*Ft = the proportion of mothers who had another household member lose earnings. If mothers earnings also went up, they are captured here, not above.

tab survey ft_hh if minors_fy==1

*Bft = the proportion of mothers who had another household member lose earnings that became breadwinners

tab ft_hh trans_bw60_alt2 if survey==1996 & minors_fy==1
tab ft_hh trans_bw60_alt2 if survey==2014 & minors_fy==1

*Lt = the proportion of mothers who stopped living with someone who was an earner. This is the main category, such that if mother's earnings went up or HH earnings went down AND someone left, they will be here.
	
tab survey earn_lose if minors_fy==1

*BLt = the proportion of mothers who stopped living with someone who was an earner that became a Breadwinner
tab earn_lose trans_bw60_alt2 if survey==1996 & minors_fy==1
tab earn_lose trans_bw60_alt2 if survey==2014 & minors_fy==1

*validate
tab survey trans_bw60_alt if minors_fy==1
tab survey trans_bw60_alt2 if minors_fy==1
*/

/* Old Table 2 options
// 2a

putexcel set "$results/Breadwinner_Predictor_Tables", sheet(Table2) modify
putexcel B1:C1 = "Total", merge border(bottom)
putexcel D1:I1 = "Education", merge border(bottom)
putexcel J1:Q1 = "Race / ethnicity", merge border(bottom)
putexcel B2:C2 = "Total", merge border(bottom)
putexcel D2:E2 = "HS Degree or Less", merge border(bottom)
putexcel F2:G2 = "Some College", merge border(bottom)
putexcel H2:I2 = "College Plus", merge border(bottom)
putexcel J2:K2 = "NH White", merge border(bottom)
putexcel L2:M2 = "Black", merge border(bottom)
putexcel N2:O2 = "NH Asian", merge border(bottom)
putexcel P2:Q2 = "Hispanic", merge border(bottom)
putexcel A3:Q3 = "1996 precipitating events", merge hcenter bold border(bottom)
putexcel A4 = "Event"
putexcel B4 = ("All events") D4 = ("All events") F4 = ("All events") H4 = ("All events") J4 = ("All events") L4 = ("All events") N4 = ("All events") P4 = ("All events")
putexcel C4 = ("Event precipitated") E4 = ("Event precipitated") G4 = ("Event precipitated") I4 = ("Event precipitated") K4 = ("Event precipitated") M4 = ("Event precipitated") O4 = ("Event precipitated") Q4 = ("Event precipitated")
putexcel A5 = "Mothers only an increase in earnings"
putexcel A6 = "Mothers increase in earnings and partner lost earnings"
putexcel A7 = "Partner lost earnings only"
putexcel A8 = "Partner left"
putexcel A9 = "Other member lost earnings / left"
putexcel A10 = "Rate of transition to BW"

putexcel A11:Q11 = "2014 precipitating events", merge hcenter bold border(bottom)
putexcel A12 = "Event"
putexcel B12 = ("All events") D12 = ("All events") F12 = ("All events") H12 = ("All events") J12 = ("All events") L12 = ("All events") N12 = ("All events") P12 = ("All events")
putexcel C12 = ("Event precipitated") E12 = ("Event precipitated") G12 = ("Event precipitated") I12 = ("Event precipitated") K12 = ("Event precipitated") M12 = ("Event precipitated") O12 = ("Event precipitated") Q12 = ("Event precipitated")
putexcel A13 = "Mothers only an increase in earnings"
putexcel A14 = "Mothers increase in earnings and partner lost earnings"
putexcel A15 = "Partner lost earnings only"
putexcel A16 = "Partner left"
putexcel A17 = "Other member lost earnings / left"
putexcel A18 = "Rate of transition to BW"

local i=1

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local row = `i'+4
		putexcel B`row' = matrix(`var'_1), nformat(#.##%)
		putexcel C`row' = matrix(`var'_1_bw), nformat(#.##%)
		local ++i
}

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local row = `i'+7
		putexcel B`row' = matrix(`var'_2), nformat(#.##%)
		putexcel C`row' = matrix(`var'_2_bw), nformat(#.##%)
		local ++i
}

putexcel C10 = $bw_rate_96, nformat(#.##%)
putexcel C18 = $bw_rate_14, nformat(#.##%)

forvalues e=1/3{
local colu1 "D F H"
local colu2 "E G I"
local i=1

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local col1: word `e' of `colu1'
		local col2: word `e' of `colu2'
		local row=`i'+4
		putexcel `col1'`row' = matrix(`var'_e`e'_1), nformat(#.##%)
		putexcel `col2'`row' = matrix(`var'_e`e'_1_bw), nformat(#.##%)
		local ++i
	}

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local col1: word `e' of `colu1'
		local col2: word `e' of `colu2'
		local row=`i'+7
		putexcel `col1'`row' = matrix(`var'_e`e'_2), nformat(#.##%)
		putexcel `col2'`row' = matrix(`var'_e`e'_2_bw), nformat(#.##%)
		local ++i
	}
}


forvalues e=1/3{
	local column1 "E G I"
	local col1: word `e' of `column1'
	putexcel `col1'10 = ${bw_rate_96_e`e'}, nformat(#.##%)
	putexcel `col1'18 = ${bw_rate_14_e`e'}, nformat(#.##%)
}

forvalues r=1/4{
local colu1 "J L N P"
local colu2 "K M O Q"

local i=1

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local col1: word `r' of `colu1'
		local col2: word `r' of `colu2'
		local row=`i'+4
		putexcel `col1'`row' = matrix(`var'_r`r'_1), nformat(#.##%)
		putexcel `col2'`row' = matrix(`var'_r`r'_1_bw), nformat(#.##%)
		local ++i
	}

	
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local col1: word `r' of `colu1'
		local col2: word `r' of `colu2'
		local row=`i'+7
		putexcel `col1'`row' = matrix(`var'_r`r'_2), nformat(#.##%)
		putexcel `col2'`row' = matrix(`var'_r`r'_2_bw), nformat(#.##%)
		local ++i
	}
}


forvalues r=1/4{
	local column1 "K M O Q"

	local col1: word `r' of `column1'
	putexcel `col1'10 = ${bw_rate_96_r`r'}, nformat(#.##%)
	putexcel `col1'18 = ${bw_rate_14_r`r'}, nformat(#.##%)
}

// Table 2: Option 2b
putexcel set "$results/Breadwinner_Predictor_Tables", sheet(Table2-option2) modify
putexcel A3 = "Event"
putexcel B3 = "Year"
putexcel C3 = ("All_events") E3 = ("All_events") G3 = ("All_events") I3 = ("All_events") K3 = ("All_events") M3 = ("All_events") O3 = ("All_events") Q3 = ("All_events")
putexcel D3 = ("Event_precipitated") F3 = ("Event_precipitated") H3 = ("Event_precipitated") J3 = ("Event_precipitated") L3 = ("Event_precipitated") N3 = ("Event_precipitated") ///
		P3 = ("Event_precipitated") R3 = ("Event_precipitated")
putexcel C1:D1 = "Total", merge border(bottom)
putexcel E1:J1 = "Education", merge border(bottom)
putexcel K1:R1 = "Race / ethnicity", merge border(bottom)
putexcel C2:D2 = "Total", merge border(bottom)
putexcel E2:F2 = "HS Degree or Less", merge border(bottom)
putexcel G2:H2 = "Some College", merge border(bottom)
putexcel I2:J2 = "College Plus", merge border(bottom)
putexcel K2:L2 = "NH White", merge border(bottom)
putexcel M2:N2 = "Black", merge border(bottom)
putexcel O2:P2 = "NH Asian", merge border(bottom)
putexcel Q2:R2 = "Hispanic", merge border(bottom)
putexcel A4:A5 = "Mothers only an increase in earnings"
putexcel A6:A7 = "Mothers increase in earnings and partner lost earnings"
putexcel A8:A9 = "Partner lost earnings only"
putexcel A10:A11 = "Partner left"
putexcel A12:A13 = "Other member lost earnings / left"
putexcel A14:A15 = "Transition rate to BW"
putexcel B4 = ("1996") B6 = ("1996") B8 = ("1996") B10 = ("1996") B12 = ("1996") B14= ("1996")
putexcel B5 = ("2014") B7 = ("2014") B9 = ("2014") B11 = ("2014") B13 = ("2014") B15 = ("2014")

local i=1
local row1 "4 6 8 10 12 5 7 9 11 13"

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local row: word `i' of `row1'
		putexcel C`row' = matrix(`var'_1), nformat(#.##%)
		putexcel D`row' = matrix(`var'_1_bw), nformat(#.##%)
		local ++i
}

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local row: word `i' of `row1'
		putexcel C`row' = matrix(`var'_2), nformat(#.##%)
		putexcel D`row' = matrix(`var'_2_bw), nformat(#.##%)
		local ++i
}

putexcel D14 = $bw_rate_96, nformat(#.##%)
putexcel D15 = $bw_rate_14, nformat(#.##%)

forvalues e=1/3{
local colu1 "E G I"
local colu2 "F H J"
local row1 "4 6 8 10 12 5 7 9 11 13"
local i=1

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local row: word `i' of `row1'
		local col1: word `e' of `colu1'
		local col2: word `e' of `colu2'
		putexcel `col1'`row' = matrix(`var'_e`e'_1), nformat(#.##%)
		putexcel `col2'`row' = matrix(`var'_e`e'_1_bw), nformat(#.##%)
		local ++i
	}

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local row: word `i' of `row1'
		local col1: word `e' of `colu1'
		local col2: word `e' of `colu2'
		putexcel `col1'`row' = matrix(`var'_e`e'_2), nformat(#.##%)
		putexcel `col2'`row' = matrix(`var'_e`e'_2_bw), nformat(#.##%)
		local ++i
	}
}

forvalues e=1/3{
	local column1 "F H J"
	local col1: word `e' of `column1'
	putexcel `col1'14 = ${bw_rate_96_e`e'}, nformat(#.##%)
	putexcel `col1'15 = ${bw_rate_14_e`e'}, nformat(#.##%)
}

forvalues r=1/4{
local colu1 "K M O Q"
local colu2 "L N P R"
local row1 "4 6 8 10 12 5 7 9 11 13"

local i=1

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local row: word `i' of `row1'
		local col1: word `r' of `colu1'
		local col2: word `r' of `colu2'
		putexcel `col1'`row' = matrix(`var'_r`r'_1), nformat(#.##%)
		putexcel `col2'`row' = matrix(`var'_r`r'_1_bw), nformat(#.##%)
		local ++i
	}

	
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local row: word `i' of `row1'
		local col1: word `r' of `colu1'
		local col2: word `r' of `colu2'
		putexcel `col1'`row' = matrix(`var'_r`r'_2), nformat(#.##%)
		putexcel `col2'`row' = matrix(`var'_r`r'_2_bw), nformat(#.##%)
		local ++i
	}
}


forvalues r=1/4{
	local column1 "L N P R"

	local col1: word `r' of `column1'
	putexcel `col1'14 = ${bw_rate_96_r`r'}, nformat(#.##%)
	putexcel `col1'15 = ${bw_rate_14_r`r'}, nformat(#.##%)
}

*/
