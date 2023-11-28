*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* predicting_consequences.do
* Kim McErlean
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* This file....

use "$tempdir/combined_bw_equation.dta", clear
keep if survey == 2014

********************************************************************************
* CREATE SAMPLE AND VARIABLES
********************************************************************************

* Create dependent variable: income / pov change change
gen inc_pov = thearn_adj / threshold
sort SSUID PNUM year
by SSUID PNUM (year), sort: gen inc_pov_change = ((inc_pov-inc_pov[_n-1])/inc_pov[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==year[_n-1]+1
by SSUID PNUM (year), sort: gen inc_pov_change_raw = (inc_pov-inc_pov[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==year[_n-1]+1

gen in_pov=.
replace in_pov=0 if inc_pov>=1.5 & inc_pov!=.
replace in_pov=1 if inc_pov <1.5

gen inc_pov_lag = inc_pov[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen pov_lag=.
replace pov_lag=0 if inc_pov_lag>=1.5 & inc_pov_lag!=.
replace pov_lag=1 if inc_pov_lag <1.5

* poverty change outcome to use
gen pov_change=.
replace pov_change=0 if in_pov==pov_lag
replace pov_change=1 if in_pov==1 & pov_lag==0
replace pov_change=2 if in_pov==0 & pov_lag==1

label define pov_change 0 "No" 1 "Moved into" 2 "Moved out of"
label values pov_change pov_change

gen pov_change_detail=.
replace pov_change_detail=1 if in_pov==0 & pov_lag==1 // moved out of poverty
replace pov_change_detail=2 if in_pov==pov_lag & pov_lag==0 // stayed out of poverty
replace pov_change_detail=3 if in_pov==pov_lag & pov_lag==1 // stay IN poverty
replace pov_change_detail=4 if in_pov==1 & pov_lag==0 // moved into

label define pov_change_detail 1 "Moved Out" 2 "Stayed out" 3 "Stayed in" 4 "Moved in"
label values pov_change_detail pov_change_detail

// some lagged measures I need
sort SSUID PNUM year
gen earnings_lag = earnings[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen thearn_lag = thearn_adj[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)

* Creating necessary independent variables
 // one variable for all pathways
egen validate = rowtotal(mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes) // make sure moms only have 1 event
browse SSUID PNUM validate mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes trans_bw60_alt2 bw60_mom

gen pathway_v1=0
replace pathway_v1=1 if mt_mom==1
replace pathway_v1=2 if ft_partner_down_mom==1
replace pathway_v1=3 if ft_partner_down_only==1
replace pathway_v1=4 if ft_partner_leave==1
replace pathway_v1=5 if lt_other_changes==1

label define pathway_v1 0 "None" 1 "Mom Up" 2 "Mom Up Partner Down" 3 "Partner Down" 4 "Partner Left" 5 "Other HH Change"
label values pathway_v1 pathway_v1

// more detailed pathway
gen start_from_0 = 0
replace start_from_0=1 if earnings_lag==0

gen hh_from_0 = 0
replace hh_from_0 = 1 if thearn_lag==0

gen pathway=0
replace pathway=1 if mt_mom==1 & start_from_0==1
replace pathway=2 if mt_mom==1 & start_from_0==0
replace pathway=3 if ft_partner_down_mom==1
replace pathway=4 if ft_partner_down_only==1
replace pathway=5 if ft_partner_leave==1
replace pathway=6 if lt_other_changes==1

label define pathway 0 "None" 1 "Mom Up, Not employed" 2 "Mom Up, employed" 3 "Mom Up Partner Down" 4 "Partner Down" 5 "Partner Left" 6 "Other HH Change"
label values pathway pathway

// program variables
gen tanf=0
replace tanf=1 if tanf_amount > 0

// need to get tanf in year prior and then eitc in year after - but this is not really going to work for 2016, so need to think about that
sort SSUID PNUM year
browse SSUID PNUM year rtanfcov tanf tanf_amount program_income eeitc
gen tanf_lag = tanf[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen tanf_amount_lag = tanf_amount[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen program_income_lag = program_income[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen eitc_after = eeitc[_n+1] if SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1] & year==(year[_n+1]-1)

replace earnings_ratio=0 if earnings_ratio==. & earnings==0 & thearn_alt > 0 // wasn't counting moms with 0 earnings -- is this an issue elsewhere?? BUT still leaving as missing if NO earnings. is that right?
gen earnings_ratio_alt=earnings_ratio
replace earnings_ratio_alt=0 if earnings_ratio_alt==. // count as 0 if no earnings (instead of missing)

gen earnings_ratio_lag = earnings_ratio[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen earnings_ratio_alt_lag = earnings_ratio_alt[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)

gen zero_earnings=0
replace zero_earnings=1 if earnings_lag==0

// last_status
recode last_marital_status (1=1) (2=2) (3/5=3), gen(marital_status_t1)
label define marr 1 "Married" 2 "Cohabiting" 3 "Single"
label values marital_status_t1 marr
recode marital_status_t1 (1/2=1)(3=0), gen(partnered_t1)

// first_status
recode start_marital_status (1=1) (2=2) (3/5=3), gen(marital_status_t)
label values marital_status_t marr
recode marital_status_t (1/2=1)(3=0), gen(partnered_t)

// race recode
recode race (1=1) (2=2)(4=3)(3=4)(5=4), gen(race_gp)
label define race_gp 1 "White" 2 "Black" 3 "Hispanic"
label values race_gp race_gp

// household income change
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

gen end_as_sole=0
replace end_as_sole=1 if earnings_ratio==1

gen partner_zero=0
replace partner_zero=1 if end_partner_earn==0
tab pathway partner_zero, row

** use the single / partnered I created before: single needs to be ALL YEAR
gen single_all=0
replace single_all=1 if partnered_t==0 & no_status_chg==1

gen partnered_all=0
replace partnered_all=1 if partnered_t==1 | single_all==0

gen partnered_no_chg=0
replace partnered_no_chg=1 if partnered_t==1 & no_status_chg==1

gen relationship=.
replace relationship=1 if start_marital_status==1 & partnered_all==1 // married
replace relationship=2 if start_marital_status==2 & partnered_all==1 // cohab
label values relationship marr

gen rel_status=.
replace rel_status=1 if single_all==1
replace rel_status=2 if partnered_all==1
label define rel 1 "Single" 2 "Partnered"
label values rel_status rel

gen rel_status_detail=.
replace rel_status_detail=1 if single_all==1
replace rel_status_detail=2 if partnered_no_chg==1
replace rel_status_detail=3 if pathway==5 // why was this 4 at one point (which was partner down) did I change this?
replace rel_status_detail=2 if partnered_all==1 & rel_status_detail==.

label define rel_detail 1 "Single" 2 "Partnered" 3 "Dissolved"
label values rel_status_detail rel_detail


* Get percentiles
//browse SSUID year bw60 bw60lag

sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID  [aweight=wpfinwgt], detail // is this t-1? this is in demography paper
sum thearn_adj, detail // then this would be t?
sum thearn_adj if bw60lag==0, detail // is this t-1?
sum thearn_adj if bw60==1, detail // is this t? okay definitely not

xtile percentile = thearn_adj, nq(10)

forvalues p=1/10{
	sum thearn_adj if percentile==`p'
}

/*
1 0 		4942
2 4950 		18052
3 18055		28058
4 28061		38763
5 38769		51120
6 51136		65045
7 65051		82705
8 82724		107473
9 107478	151012
10 151072	2000316
*/

gen pre_percentile=. // okay duh a lot of missing because thearn_lag not there for everyone
replace pre_percentile=1 if thearn_lag>=0 & thearn_lag<= 4942
replace pre_percentile=2 if thearn_lag>= 4950 & thearn_lag<= 18052
replace pre_percentile=3 if thearn_lag>= 18055 & thearn_lag<= 28058
replace pre_percentile=4 if thearn_lag>= 28061	& thearn_lag<=38763
replace pre_percentile=5 if thearn_lag>= 38769 & thearn_lag<= 51120
replace pre_percentile=6 if thearn_lag>= 51136	& thearn_lag<=	65045
replace pre_percentile=7 if thearn_lag>= 65051	& thearn_lag<=	82705
replace pre_percentile=8 if thearn_lag>= 82724	& thearn_lag<=	107473
replace pre_percentile=9 if thearn_lag>= 107478	& thearn_lag<=151012
replace pre_percentile=10 if thearn_lag>= 151072 & thearn_lag<= 2000316

gen post_percentile=.
replace post_percentile=1 if thearn_adj>=0 & thearn_adj<= 4942
replace post_percentile=2 if thearn_adj>= 4950 & thearn_adj<= 18052
replace post_percentile=3 if thearn_adj>= 18055 & thearn_adj<= 28058
replace post_percentile=4 if thearn_adj>= 28061	& thearn_adj<=38763
replace post_percentile=5 if thearn_adj>= 38769 & thearn_adj<= 51120
replace post_percentile=6 if thearn_adj>= 51136	& thearn_adj<=	65045
replace post_percentile=7 if thearn_adj>= 65051	& thearn_adj<=	82705
replace post_percentile=8 if thearn_adj>= 82724	& thearn_adj<=	107473
replace post_percentile=9 if thearn_adj>= 107478	& thearn_adj<=151012
replace post_percentile=10 if thearn_adj>= 151072 & thearn_adj<= 2000316

gen percentile_chg = post_percentile-pre_percentile

* other income measures
gen income_change=.
replace income_change=1 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. // up
replace income_change=2 if inc_pov_change_raw < 0 & inc_pov_change_raw!=. // down
label define income 1 "Up" 2 "Down"
label values income_change income

// drop if inlist(status_b1, 3,4) 

// topcode income change to stabilize outliers - use 1% / 99% or 5% / 95%? should I topcode here or once I restrict sample?
sum hh_income_raw_all, detail
gen hh_income_topcode=hh_income_raw_all
replace hh_income_topcode = `r(p5)' if hh_income_raw_all<`r(p5)'
replace hh_income_topcode = `r(p95)' if hh_income_raw_all>`r(p95)'

gen income_chg_top = hh_income_topcode / thearn_lag

// browse SSUID thearn_adj thearn_lag hh_income_raw_all hh_income_topcode hh_income_chg income_chg_top
sum hh_income_chg, detail
sum income_chg_top, detail

gen hh_income_pos = hh_income_raw_all 
replace hh_income_pos = hh_income_raw_all *-1 if hh_income_raw_all<0
gen log_income = ln(hh_income_pos) // ah does not work with negative numbers
gen log_income_change = log_income
replace log_income_change = log_income*-1 if hh_income_raw_all<0
browse hh_income_raw_all hh_income_pos log_income log_income_change

// keep if trans_bw60_alt2==1 & bw60lag==0 - want to get comparison to mothers who are NOT the primary earner

sum avg_hhsize if trans_bw60_alt2==1 & bw60lag==0
sum avg_hhsize if rel_status_detail==1 & trans_bw60_alt2==1 & bw60lag==0 // single
sum avg_hhsize if rel_status_detail==2 & trans_bw60_alt2==1 & bw60lag==0
sum avg_hhsize if rel_status_detail==3 & trans_bw60_alt2==1 & bw60lag==0
sum avg_hhsize if trans_bw60_alt2==0 & bw60lag==0

sum st_minorchildren if trans_bw60_alt2==1 & bw60lag==0
sum st_minorchildren if rel_status_detail==1 & trans_bw60_alt2==1 & bw60lag==0 // single
sum st_minorchildren if rel_status_detail==2 & trans_bw60_alt2==1 & bw60lag==0
sum st_minorchildren if rel_status_detail==3 & trans_bw60_alt2==1 & bw60lag==0
sum st_minorchildren if trans_bw60_alt2==0 & bw60lag==0

********************************************************************************
* Relationship status descriptives for JFEI paper
********************************************************************************
putexcel set "$results/Breadwinner_Impact_Tables", sheet(sample) modify
putexcel A1 = "Descriptive Statistics", border(bottom) hcenter bold
putexcel B1 = "Total Sample"
putexcel C1 = "Single Mothers"
putexcel D1 = "Partnered Mothers"
putexcel E1 = "Relationship Dissolved"
putexcel F1 = "Non-Primary-Earning Mothers"
putexcel A2 = "Median HH income at time t-1"
putexcel A3 = "Mothers' median income at time t-1 (employed mothers only)"
putexcel A4 = "Race/ethnicity (time-invariant)"
putexcel A5 = "Non-Hispanic White", txtindent(4)
putexcel A6 = "Black", txtindent(4)
putexcel A7 = "Non-Hispanic Asian", txtindent(4)
putexcel A8 = "Hispanic", txtindent(4)
putexcel A9 = "Education (time-varying)"
putexcel A10 = "HS Degree or Less", txtindent(4)
putexcel A11 = "Some College", txtindent(4)
putexcel A12 = "College Plus", txtindent(4)
putexcel A13 = "Relationship Status (time-varying)"
putexcel A14 = "Married", txtindent(4)
putexcel A15 = "Cohabitating", txtindent(4)
putexcel A16 = "Single", txtindent(4)
putexcel A17 = "Pathway into primary earning (time-varying)"
putexcel A18 = "Partner separation", txtindent(4)
putexcel A19 = "Mothers increase in earnings", txtindent(4)
putexcel A20 = "Partner lost earnings", txtindent(4)
putexcel A21 = "Mothers increase in earnings & partner lost earnings", txtindent(4)
putexcel A22 = "Other member exit | lost earnings", txtindent(4)
putexcel A23 = "Poverty and welfare"
putexcel A24 = "HH had Zero Earnings in Year Prior", txtindent(4)
putexcel A25 = "Mom had Zero Earnings in Year Prior", txtindent(4)
putexcel A26 = "TANF in Year Prior", txtindent(4)
putexcel A27 = "EITC in Year Prior", txtindent(4)
putexcel A28 = "EITC in Year Became Primary Earner (reduced sample)", txtindent(4)

*Income 
* HH
sum thearn_lag if thearn_lag!=0 & trans_bw60_alt2==1 & bw60lag==0, detail
putexcel B2=`r(p50)', nformat(###,###)
sum thearn_lag if rel_status_detail==1 & thearn_lag!=0 & trans_bw60_alt2==1 & bw60lag==0, detail
putexcel C2=`r(p50)', nformat(###,###)
sum thearn_lag if rel_status_detail==2 & thearn_lag!=0 & trans_bw60_alt2==1 & bw60lag==0, detail
putexcel D2=`r(p50)', nformat(###,###)
sum thearn_lag if rel_status_detail==3 & thearn_lag!=0 & trans_bw60_alt2==1 & bw60lag==0, detail
putexcel E2=`r(p50)', nformat(###,###)
sum thearn_lag if thearn_lag!=0 & trans_bw60_alt2==0 & bw60lag==0, detail
putexcel F2=`r(p50)', nformat(###,###)

// or?
sum thearn_lag if thearn_lag!=0 & bw60==0, detail // okay not that different

*Mother
/*
sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & trans_bw60_alt2[_n+1]==1 & bw60lag[_n+1]==0, detail  // okay yes this is right, but before I had the below - which is wrong, because need the earnings to lag the bw
sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & trans_bw60_alt2==1 & bw60lag==0, detail
*/
sum earnings_lag if earnings_lag!=0 & trans_bw60_alt2==1 & bw60lag==0, detail 
putexcel B3=`r(p50)', nformat(###,###)
sum earnings_lag if rel_status_detail==1 & earnings_lag!=0 & trans_bw60_alt2==1 & bw60lag==0, detail 
putexcel C3=`r(p50)', nformat(###,###)
sum earnings_lag if rel_status_detail==2 & earnings_lag!=0 & trans_bw60_alt2==1 & bw60lag==0, detail 
putexcel D3=`r(p50)', nformat(###,###)
sum earnings_lag if rel_status_detail==3 & earnings_lag!=0 & trans_bw60_alt2==1 & bw60lag==0, detail 
putexcel E3=`r(p50)', nformat(###,###)
sum earnings_lag if earnings_lag!=0 & trans_bw60_alt2==0 & bw60lag==0, detail 
putexcel F3=`r(p50)', nformat(###,###)

* Race
tab race, gen(race)

local i=1

foreach var in race1 race2 race3 race4{
	local row = `i'+4
	mean `var' if survey_yr==2 & trans_bw60_alt2==1 & bw60lag==0
	matrix `var'_bw14 = e(b)
	putexcel B`row' = matrix(`var'_bw14), nformat(#.##%)
	mean `var' if survey_yr==2 & trans_bw60_alt2==0 & bw60lag==0
	matrix `var'_nobw = e(b)
	putexcel F`row' = matrix(`var'_nobw), nformat(#.##%)
	local ++i
}
		

* Education
tab educ_gp, gen(educ_gp)

local i=1

foreach var in educ_gp1 educ_gp2 educ_gp3{
	local row = `i'+9
	mean `var' if survey_yr==2 & trans_bw60_alt2==1 & bw60lag==0
	matrix `var'_bw14 = e(b)
	putexcel B`row' = matrix(`var'_bw14), nformat(#.##%)
	mean `var' if survey_yr==2 & trans_bw60_alt2==0 & bw60lag==0
	matrix `var'_nobw = e(b)
	putexcel F`row' = matrix(`var'_nobw), nformat(#.##%)
	local ++i
}
		
	
* Marital Status - December
tab marital_status_t1, gen(marst)

local i=1

foreach var in marst1 marst2 marst3{
	local row = `i'+13
	mean `var' if survey_yr==2 & trans_bw60_alt2==1 & bw60lag==0
	matrix `var'_bw14 = e(b)
	putexcel B`row' = matrix(`var'_bw14), nformat(#.##%)
	mean `var' if survey_yr==2 & trans_bw60_alt2==0 & bw60lag==0
	matrix `var'_nobw = e(b)
	putexcel F`row' = matrix(`var'_nobw), nformat(#.##%)
	local ++i
}

* Pathway into breadwinning

local i=1

foreach var in ft_partner_leave mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
	local row = `i'+17
	mean `var' if survey_yr==2 & trans_bw60_alt2==1 & bw60lag==0 // remove svy to see if matches paper 1
	matrix `var'_bw14 = e(b)
	putexcel B`row' = matrix(`var'_bw14), nformat(#.##%)
	mean `var' if survey_yr==2 & trans_bw60_alt2==0 & bw60lag==0
	matrix `var'_nobw = e(b)
	putexcel F`row' = matrix(`var'_nobw), nformat(#.##%)
	local ++i
}

local i=1

* Poverty and welfare
foreach var in hh_from_0 start_from_0 tanf_lag eeitc eitc_after{
	local row = `i'+23
	mean `var' if survey_yr==2 & trans_bw60_alt2==1 & bw60lag==0
	matrix `var'_bw14 = e(b)
	putexcel B`row' = matrix(`var'_bw14), nformat(#.##%)
	mean `var' if survey_yr==2 & trans_bw60_alt2==0 & bw60lag==0
	matrix `var'_nobw = e(b)
	putexcel F`row' = matrix(`var'_nobw), nformat(#.##%)
	local ++i
}


//// by partnership status

* Race
local i=1
local colu "C D E"

foreach var in race1 race2 race3 race4{
	forvalues p=1/3{
		local row = `i'+4
		local col: word `p' of `colu'
		mean `var' if rel_status_detail==`p' & trans_bw60_alt2==1 & bw60lag==0
		matrix `var'_`p' = e(b)
		putexcel `col'`row' = matrix(`var'_`p'), nformat(#.##%)
	}
	local ++i
}


* Education
local i=1
local colu "C D E"

foreach var in educ_gp1 educ_gp2 educ_gp3{
	forvalues p=1/3{
		local row = `i'+9
		local col: word `p' of `colu'
		mean `var' if rel_status_detail==`p' & trans_bw60_alt2==1 & bw60lag==0
		matrix `var'_`p' = e(b)
		putexcel `col'`row' = matrix(`var'_`p'), nformat(#.##%)
	}
	local ++i
}
		
	
* Marital Status - December of prior year
local i=1
local colu "C D E"

foreach var in marst1 marst2 marst3{
	forvalues p=1/3{
		local row = `i'+13
		local col: word `p' of `colu'
		mean `var' if rel_status_detail==`p' & trans_bw60_alt2==1 & bw60lag==0
		matrix `var'_`p' = e(b)
		putexcel `col'`row' = matrix(`var'_`p'), nformat(#.##%)
	}
	local ++i
}

* Pathway into breadwinning
local i=1
local colu "C D E"

foreach var in ft_partner_leave mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
	forvalues p=1/3{
		local row = `i'+17
		local col: word `p' of `colu'
		mean `var' if rel_status_detail==`p' & trans_bw60_alt2==1 & bw60lag==0
		matrix `var'_`p' = e(b)
		putexcel `col'`row' = matrix(`var'_`p'), nformat(#.##%)
	}
	local ++i
}

* Poverty and welfare
local i=1
local colu "C D E"

foreach var in hh_from_0 start_from_0 tanf_lag eeitc eitc_after{
	forvalues p=1/3{
		local row = `i'+23
		local col: word `p' of `colu'
		mean `var' if rel_status_detail==`p' & trans_bw60_alt2==1 & bw60lag==0
		matrix `var'_`p' = e(b)
		putexcel `col'`row' = matrix(`var'_`p'), nformat(#.##%)
	}
	local ++i
}
