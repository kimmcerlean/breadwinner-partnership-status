*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* descriptive_table.do
* Kim McErlean
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* This file creates some variable recodes and Table 1: Descriptive statistics

use "$SIPP14keep/annual_bw_status2014.dta", clear // created in step 10

********************************************************************************
* CREATE SAMPLE AND VARIABLES
********************************************************************************

* Create dependent variable: income / pov change change
gen inc_pov = thearn_alt / threshold
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

// some lagged measures I need
sort SSUID PNUM year
gen earnings_lag = earnings[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen thearn_lag = thearn_alt[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)

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

// education recode
recode educ (1/2=1) (3=2) (4=3), gen(educ_gp)
label define educ_gp 1 "Hs or Less" 2 "Some College" 3 "College Plus"
label values educ_gp educ_gp

// age at first birth recode
recode ageb1 (-5/19=1) (20/24=2) (25/29=3) (30/55=4), gen(ageb1_cat)
label define ageb1_cat 1 "Under 20" 2 "A20-24" 3 "A25-29" 4 "Over 30"
label values ageb1_cat ageb1_cat

// marital status recode
recode marital_status_t1 (1/2=1)(3=0), gen(partnered)
recode partnered (0=1)(1=0), gen(single)

// household income change
by SSUID PNUM (year), sort: gen hh_income_chg = ((thearn_alt-thearn_alt[_n-1])/thearn_alt[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & trans_bw60_alt2==1
by SSUID PNUM (year), sort: gen hh_income_raw = ((thearn_alt-thearn_alt[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & trans_bw60_alt2==1
browse SSUID PNUM year thearn_alt bw60 trans_bw60_alt2 hh_income_chg hh_income_raw
	
by SSUID PNUM (year), sort: gen hh_income_raw_all = ((thearn_alt-thearn_alt[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & bw60lag==0
	
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

sum thearn_alt if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID  [aweight=wpfinwgt], detail // is this t-1? this is in demography paper
sum thearn_alt, detail // then this would be t?
sum thearn_alt if bw60lag==0, detail // is this t-1?
sum thearn_alt if bw60==1, detail // is this t? okay definitely not

xtile percentile = thearn_alt, nq(10)

forvalues p=1/10{
	sum thearn_alt if percentile==`p'
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
replace post_percentile=1 if thearn_alt>=0 & thearn_alt<= 4942
replace post_percentile=2 if thearn_alt>= 4950 & thearn_alt<= 18052
replace post_percentile=3 if thearn_alt>= 18055 & thearn_alt<= 28058
replace post_percentile=4 if thearn_alt>= 28061	& thearn_alt<=38763
replace post_percentile=5 if thearn_alt>= 38769 & thearn_alt<= 51120
replace post_percentile=6 if thearn_alt>= 51136	& thearn_alt<=	65045
replace post_percentile=7 if thearn_alt>= 65051	& thearn_alt<=	82705
replace post_percentile=8 if thearn_alt>= 82724	& thearn_alt<=	107473
replace post_percentile=9 if thearn_alt>= 107478	& thearn_alt<=151012
replace post_percentile=10 if thearn_alt>= 151072 & thearn_alt<= 2000316

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

// browse SSUID thearn_alt thearn_lag hh_income_raw_all hh_income_topcode hh_income_chg income_chg_top
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
**# Relationship status descriptives for JFEI paper
********************************************************************************
putexcel set "$results/Breadwinner_JFEI_Tables", sheet(sample) replace
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
sum earnings if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & trans_bw60_alt2[_n+1]==1 & bw60lag[_n+1]==0, detail  // okay yes this is right, but before I had the below - which is wrong, because need the earnings to lag the bw
sum earnings if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & trans_bw60_alt2==1 & bw60lag==0, detail
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
	mean `var' if trans_bw60_alt2==1 & bw60lag==0
	matrix `var'_bw14 = e(b)
	putexcel B`row' = matrix(`var'_bw14), nformat(#.##%)
	mean `var' if trans_bw60_alt2==0 & bw60lag==0
	matrix `var'_nobw = e(b)
	putexcel F`row' = matrix(`var'_nobw), nformat(#.##%)
	local ++i
}
		

* Education
tab educ_gp, gen(educ_gp)

local i=1

foreach var in educ_gp1 educ_gp2 educ_gp3{
	local row = `i'+9
	mean `var' if trans_bw60_alt2==1 & bw60lag==0
	matrix `var'_bw14 = e(b)
	putexcel B`row' = matrix(`var'_bw14), nformat(#.##%)
	mean `var' if trans_bw60_alt2==0 & bw60lag==0
	matrix `var'_nobw = e(b)
	putexcel F`row' = matrix(`var'_nobw), nformat(#.##%)
	local ++i
}
		
	
* Marital Status - December
tab marital_status_t1, gen(marst)

local i=1

foreach var in marst1 marst2 marst3{
	local row = `i'+13
	mean `var' if trans_bw60_alt2==1 & bw60lag==0
	matrix `var'_bw14 = e(b)
	putexcel B`row' = matrix(`var'_bw14), nformat(#.##%)
	mean `var' if trans_bw60_alt2==0 & bw60lag==0
	matrix `var'_nobw = e(b)
	putexcel F`row' = matrix(`var'_nobw), nformat(#.##%)
	local ++i
}

* Pathway into breadwinning

local i=1

foreach var in ft_partner_leave mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
	local row = `i'+17
	mean `var' if trans_bw60_alt2==1 & bw60lag==0 // remove svy to see if matches paper 1
	matrix `var'_bw14 = e(b)
	putexcel B`row' = matrix(`var'_bw14), nformat(#.##%)
	mean `var' if trans_bw60_alt2==0 & bw60lag==0
	matrix `var'_nobw = e(b)
	putexcel F`row' = matrix(`var'_nobw), nformat(#.##%)
	local ++i
}

local i=1

* Poverty and welfare
foreach var in hh_from_0 start_from_0 tanf_lag eeitc eitc_after{
	local row = `i'+23
	mean `var' if trans_bw60_alt2==1 & bw60lag==0
	matrix `var'_bw14 = e(b)
	putexcel B`row' = matrix(`var'_bw14), nformat(#.##%)
	mean `var' if trans_bw60_alt2==0 & bw60lag==0
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

********************************************************************************
**# HH economic well-being change when mom becomes BW
********************************************************************************

tab inc_pov_summary2, gen(inc_pov_bucket) // 4 categores (Up Above; Up Below; Down Above; Down Below)

putexcel set "$results/Breadwinner_JFEI_Tables", sheet(Table2) modify
putexcel A1:F1 = "Household Economic Well-Being Changes when Mom Becomes Primary Earner: 2014", merge border(bottom) hcenter
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
	sum inc_pov_bucket`i' if trans_bw60_alt2==1, detail
	putexcel `col'3=`r(mean)', nformat(#.##%)
}

local row1 "4 5 6"
forvalues e=1/3{
	local row: word `e' of `row1'
		forvalues i=1/4{
		local col: word `i' of `colu'
		sum inc_pov_bucket`i' if trans_bw60_alt2==1 & educ_gp==`e', detail
		putexcel `col'`row'=`r(mean)', nformat(#.##%)
	}	
}

local row1 "7 8 9 10"
forvalues r=1/4{
	local row: word `r' of `row1'
		forvalues i=1/4{
		local col: word `i' of `colu'
		sum inc_pov_bucket`i' if trans_bw60_alt2==1 & race==`r', detail 
		putexcel `col'`row'=`r(mean)', nformat(#.##%)
	}	
}

local row1 "11 12 13 14"
forvalues a=1/4{
	local row: word `a' of `row1'
		forvalues i=1/4{
		local col: word `i' of `colu'
		sum inc_pov_bucket`i' if trans_bw60_alt2==1 & ageb1_cat==`a', detail
		putexcel `col'`row'=`r(mean)', nformat(#.##%)
	}	
}


local row1 "15 16"
forvalues s=1/2{
	local row: word `s' of `row1'
		forvalues i=1/4{
		local col: word `i' of `colu'
		sum inc_pov_bucket`i' if trans_bw60_alt2==1 & status_b1==`s', detail
		putexcel `col'`row'=`r(mean)', nformat(#.##%)
	}	
}

local row1 "17 18 19 20 21"
local x=1
foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
	local row: word `x' of `row1'
		forvalues i=1/4{
		local col: word `i' of `colu'
		sum inc_pov_bucket`i' if trans_bw60_alt2==1 & `var'==1, detail
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
			sum inc_pov_bucket`i' if trans_bw60_alt2==1 & `var'==1 &	educ_gp==`e', detail
			putexcel `col'`row'=`r(mean)', nformat(#.##%)
			}
		local ++x
	}
}


local colu "C D E F"

forvalues r=1/3{
	local x=1
		foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
		local row = (`r' * 5) +32 + `x'
			forvalues i=1/4{
			local col: word `i' of `colu'
			sum inc_pov_bucket`i' if trans_bw60_alt2==1 & `var'==1 &	race_gp==`r', detail
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
			sum inc_pov_bucket`i' if trans_bw60_alt2==1 & `var'==1 &	partnered==`p', detail
			putexcel `col'`row'=`r(mean)', nformat(#.##%)
			}
		local ++x
	}
}

********************************************************************************
**# Descriptive: Final outcome: in and out of poverty
* Pathway by race / educ + categorical outcome
********************************************************************************
tab pov_change_detail, gen(outcome)

putexcel set "$results/Breadwinner_JFEI_Tables", sheet(Table3) modify
putexcel A1:F1 = "Household Economic Well-Being Changes when Mom Becomes Primary Earner: 2014", merge border(bottom) hcenter
putexcel A2 = "Category"
putexcel B2 = "Label"
putexcel C2 = ("Moved out") D2 = ("Stayed out") E2 = ("Stayed in") F2 = ("Moved in")

/// split pathways by race / educ
putexcel A3:A7 = "HS or Less", merge hcenter
putexcel A8:A12 = "Some College", merge hcenter
putexcel A13:A17 = "College", merge hcenter
putexcel A18:A22 = "White", merge hcenter
putexcel A23:A27 = "Black", merge hcenter
putexcel A28:A32 = "Hispanic", merge hcenter
putexcel B3 = ("Partner Left") B4 = ("Mom Up") B5 = ("Partner Down") B6 = ("Mom Up Partner Down") B7 = ("Other HH Member")
putexcel B8 = ("Partner Left") B9 = ("Mom Up") B10 = ("Partner Down") B11 = ("Mom Up Partner Down") B12 = ("Other HH Member")
putexcel B13 = ("Partner Left") B14 = ("Mom Up") B15 = ("Partner Down") B16 = ("Mom Up Partner Down") B17 = ("Other HH Member")
putexcel B18 = ("Partner Left") B19 = ("Mom Up") B20 = ("Partner Down") B21 = ("Mom Up Partner Down") B22 = ("Other HH Member")
putexcel B23 = ("Partner Left") B24 = ("Mom Up") B25 = ("Partner Down") B26 = ("Mom Up Partner Down") B27 = ("Other HH Member")
putexcel B28 = ("Partner Left") B29 = ("Mom Up") B30 = ("Partner Down") B31 = ("Mom Up Partner Down") B32 = ("Other HH Member")

local colu "C D E F"

forvalues e=1/3{
	local x=1
		foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
		local row = (`e' * 5) -3 + `x'
			forvalues i=1/4{
			local col: word `i' of `colu'
			sum outcome`i' if trans_bw60_alt2==1 & `var'==1 & educ_gp==`e', detail // 2014
			putexcel `col'`row'=`r(mean)', nformat(#.##%)
			}
		local ++x
	}
}

local colu "C D E F"

forvalues r=1/3{
	local x=1
		foreach var in ft_partner_leave	mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
		local row = (`r' * 5) +12 + `x'
			forvalues i=1/4{
			local col: word `i' of `colu'
			sum outcome`i' if trans_bw60_alt2==1 & `var'==1 &	race_gp==`r', detail // 2014
			putexcel `col'`row'=`r(mean)', nformat(#.##%)
			}
		local ++x
	}
}


********************************************************************************
**# Figures for JFEI
********************************************************************************
*Okay, so this is in JFEI, but I think I used the graph editor to change plottype to rarea. Okay i can recast duh kim
twoway (histogram hh_income_raw if hh_income_raw>=-75000 & hh_income_raw<=75000, width(2000) percent recast(rarea) xline(0,lcolor(black)) color(gray%60)), xlabel(-75000(5000)75000, labsize(small) angle(ninety) valuelabel) xtitle("Household Income Change")  ylabel(, labsize(small)) ytitle("Percent Distribution of Households") graphregion(fcolor(white))

twoway (histogram hh_income_raw if hh_income_raw>=-75000 & hh_income_raw<=75000, width(2000) percent recast(rarea) xline(0,lcolor(black)) color(gray%60)), xlabel(-70000(10000)70000, labsize(small) angle(ninety) valuelabel) xtitle("Household Income Change")  ylabel(, labsize(small)) ytitle("Percent Distribution of Households") graphregion(fcolor(white)) ysize(6) xsize(8)

* Education
twoway (histogram hh_income_raw if hh_income_raw>=-75000 & hh_income_raw<=75000 & educ_gp==1, width(4000) percent recast(rarea) xline(0,lcolor(black)) color(gray%40)), xlabel(-70000(70000)70000, labsize(small) angle(ninety) valuelabel) xtitle("Household Income Change")  ylabel(0(15)15, labsize(small)) ytitle("Percent Distribution") graphregion(fcolor(white)) ysize(4.5) xsize(6)

// twoway (histogram hh_income_raw if hh_income_raw>=-75000 & hh_income_raw<=75000 & educ_gp==1, width(4000) percent recast(rarea) xline(0,lcolor(black)) color(gray%40)), xlabel(-75000(5000)75000, labsize(small) angle(ninety) valuelabel) xtitle("Household Income Change")  ylabel(0(5)15, labsize(small)) ytitle("Percent Distribution") graphregion(fcolor(white)) ysize(4.5) xsize(8)

twoway (histogram hh_income_raw if hh_income_raw>=-75000 & hh_income_raw<=75000 & educ_gp==2, width(4000) percent recast(rarea) xline(0,lcolor(black)) color(gray%40)), xlabel(-70000(70000)70000, labsize(small) angle(ninety) valuelabel) xtitle("Household Income Change")  ysc(off) ylabel(0(15)15, labsize(small)) ytitle("") graphregion(fcolor(white)) ysize(4.5) xsize(6) // yscale(lstyle(none))

twoway (histogram hh_income_raw if hh_income_raw>=-75000 & hh_income_raw<=75000 & educ_gp==3, width(4000) percent recast(rarea) xline(0,lcolor(black)) color(gray%40)), xlabel(-70000(70000)70000, labsize(small) angle(ninety) valuelabel) xtitle("Household Income Change") ysc(off) ylabel(0(15)15, labsize(small))ytitle("Percent Distribution") graphregion(fcolor(white)) ysize(4.5) xsize(6)
/*
twoway (histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & educ_gp==1, percent width(1000) color(red%30) recast(area) xline(0)) ///
(histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & educ_gp==3, percent width(1000) color(blue%30) recast(area)), ///
legend(order(1 "LTHS" 2 "College" )) xlabel(-50000(5000)50000, labsize(vsmall) angle(forty_five) valuelabel) xtitle("Household Income Change") ytitle("Percent Distribution") graphregion(fcolor(white))

twoway (histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & educ_gp==1, percent width(4000) recast(area) color(red%30) xline(0)) ///
(histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & educ_gp==3, percent width(4000) recast(area) color(blue%30)), ///
legend(order(1 "LTHS" 2 "College" )) xlabel(-50000(5000)50000, labsize(vsmall) angle(forty_five) valuelabel) xtitle("Household Income Change") ytitle("Percent Distribution") graphregion(fcolor(white))
*/

twoway (histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & educ_gp==1, percent width(4000) color(red%30) recast(area) xline(0)) ///
(histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & educ_gp==2, percent width(4000) color(dkblue%30) recast(area)) ///
(histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & educ_gp==3, percent width(4000) color(blue%30) recast(area)), ///
legend(order(1 "LTHS" 2 "Some College" 3 "College" ) size(small) rows(1)) xlabel(-50000(5000)50000, labsize(vsmall) angle(forty_five) valuelabel) ylabel(, labsize(small)) xtitle("Household Income Change") ytitle("Percent Distribution") graphregion(fcolor(white))


*Race
twoway (histogram hh_income_raw if hh_income_raw>=-75000 & hh_income_raw<=75000 & race_gp==1, width(4000) percent recast(rarea) xline(0,lcolor(black)) color(gray%40)), xlabel(-70000(70000)70000, labsize(small) angle(ninety) valuelabel) xtitle("Household Income Change")  ylabel(0(15)15, labsize(small)) ytitle("Percent Distribution") graphregion(fcolor(white)) ysize(4.5) xsize(6)

twoway (histogram hh_income_raw if hh_income_raw>=-75000 & hh_income_raw<=75000 & race_gp==2, width(4000) percent recast(rarea) xline(0,lcolor(black)) color(gray%40)), xlabel(-70000(70000)70000, labsize(small) angle(ninety) valuelabel) xtitle("Household Income Change") ysc(off) ylabel(0(15)15, labsize(small)) ytitle("Percent Distribution") graphregion(fcolor(white)) ysize(4.5) xsize(6)  

twoway (histogram hh_income_raw if hh_income_raw>=-75000 & hh_income_raw<=75000 & race_gp==3, width(4000) percent recast(rarea) xline(0,lcolor(black)) color(gray%40)), xlabel(-70000(70000)70000, labsize(small) angle(ninety) valuelabel) xtitle("Household Income Change") ysc(off) ylabel(0(15)15, labsize(small)) ytitle("Percent Distribution") graphregion(fcolor(white)) ysize(4.5) xsize(6)

twoway (histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & race_gp==1, percent width(4000) color(red%30) recast(area) xline(0)) ///
(histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & race_gp==2, percent width(4000) color(dkblue%30) recast(area)) ///
(histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & race_gp==3, percent width(4000) color(blue%30) recast(area)), ///
legend(order(1 "White" 2 "Black" 3 "Hispanic" ) size(small) rows(1)) xlabel(-50000(5000)50000, labsize(vsmall) angle(forty_five) valuelabel) ylabel(, labsize(small)) xtitle("Household Income Change") ytitle("Percent Distribution") graphregion(fcolor(white))

* Pathway
forvalues p=1/6{
	local pathway_`p': label (pathway) `p'
	twoway (histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & pathway==`p', width(1000) percent recast(rarea) xline(0) color(gray%30)), xtitle("`pathway_`p''")
	graph export "$results\pathway_histogram_`p'.png", as(png) name("Graph") replace
}

local pathway_1: label (pathway) 1
display "`pathway_1'"

* Want to replicate with groups
twoway (histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & in_pov==1, percent width(5000) color(red%30)) ///
(histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & in_pov==0, percent width(5000) color(dkgreen%30)), ///
legend(order(1 "In financial hardship" 2 "Not in financial hardship" )) xlabel(-50000(5000)50000, labsize(vsmall) angle(forty_five) valuelabel) xtitle("Household Income Change") ytitle("Percent Distribution") graphregion(fcolor(white))

** Are box plots better?
graph box hh_income_raw if hh_income_raw>=-100000 & hh_income_raw<=100000, over(educ_gp)
graph box hh_income_raw if hh_income_raw>=-100000 & hh_income_raw<=100000 & race_gp<4, over(race_gp)

// violinplot hh_income_raw if hh_income_raw>=-100000 & hh_income_raw<=100000
