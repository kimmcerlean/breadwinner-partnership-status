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

/* old dependent variables
gen inc_pov_summary2=.
replace inc_pov_summary2=1 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. & inc_pov >=1.5
replace inc_pov_summary2=2 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. & inc_pov <1.5
replace inc_pov_summary2=3 if inc_pov_change_raw < 0 & inc_pov_change_raw!=. & inc_pov >=1.5
replace inc_pov_summary2=4 if inc_pov_change_raw < 0 & inc_pov_change_raw!=. & inc_pov <1.5
replace inc_pov_summary2=5 if inc_pov_change_raw==0

label define summary2 1 "Up, Above Pov" 2 "Up, Below Pov" 3 "Down, Above Pov" 4 "Down, Below Pov" 5 "No Change"
label values inc_pov_summary2 summary2

gen mechanism=.
replace mechanism=1 if inc_pov_summary2==4
replace mechanism=2 if inc_pov_summary2==2 | inc_pov_summary2==3
replace mechanism=3 if inc_pov_summary2==1

label define mechanism 1 "Default" 2 "Reserve" 3 "Empowerment"
label values mechanism mechanism
*/

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

// making a variable to combine education and race
gen educ_x_race=.
replace educ_x_race=1 if educ_gp==1 & race_gp==1
replace educ_x_race=2 if educ_gp==1 & race_gp==2
replace educ_x_race=3 if educ_gp==1 & race_gp==3
replace educ_x_race=4 if educ_gp==2 & race_gp==1
replace educ_x_race=5 if educ_gp==2 & race_gp==2
replace educ_x_race=6 if educ_gp==2 & race_gp==3
replace educ_x_race=7 if educ_gp==3 & race_gp==1
replace educ_x_race=8 if educ_gp==3 & race_gp==2
replace educ_x_race=9 if educ_gp==3 & race_gp==3
replace educ_x_race=10 if race_gp==4

label define educ_x_race 1 "HS x White" 2 "HS x Black" 3 "HS x Hisp" 4 "Some COll x White" 5 "Some COll x Black" 6 "Some COll x Hisp" 7 "College x White" 8 "College x Black" 9 "College x Hisp" 10 "Other"
label values educ_x_race educ_x_race

// adding info on HH composition (created file 10 in 2014 folder) 
merge 1:1 SSUID PNUM year using "$tempdir/household_lookup.dta"
drop if _merge==2
drop _merge

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

** Should I restrict sample to just mothers who transitioned into breadwinning for this step? Probably. or just subpop?
keep if bw60lag==0 // first want to see the effect of transitioning on income AMONG eligible mothers
browse SSUID PNUM year hh_income_chg hh_income_raw hh_income_raw_all // k so the first two are just those who transition, the last one is all mothers - so would need that for comparison. for those who transition, they match

gen hh_income_pos = hh_income_raw_all 
replace hh_income_pos = hh_income_raw_all *-1 if hh_income_raw_all<0
gen log_income = ln(hh_income_pos) // ah does not work with negative numbers
gen log_income_change = log_income
replace log_income_change = log_income*-1 if hh_income_raw_all<0
browse hh_income_raw_all hh_income_pos log_income log_income_change

regress hh_income_raw_all i.trans_bw60_alt2 // so when you become BW, lose income?
regress hh_income_raw_all i.trans_bw60_alt2 i.educ_gp i.race i.rel_status ageb1 i.status_b1 // controls for those most likely to become BW

regress log_income_change i.trans_bw60_alt2 // so when you become BW, lose income?
regress log_income_change i.trans_bw60_alt2 i.educ_gp i.race i.rel_status ageb1 i.status_b1 // controls for those most likely to become BW

keep if trans_bw60_alt2==1 & bw60lag==0

** exploratory things
// browse SSUID PNUM year thearn_adj thearn_lag hh_income_chg hh_income_raw
inspect hh_income_chg // so about 200 are missing, which means hh income was 0 in the year prior to her becoming BW, make those 100%?
gen hh_income_chg_x = hh_income_chg
replace hh_income_chg_x = 1 if hh_income_chg==.

sum hh_income_chg, detail
sum hh_income_chg_x, detail
// the means are very similar, which makes sense, it is the medians that are different

tabstat hh_income_chg, by(pathway) stats(mean p50)
tabstat hh_income_chg_x, by(pathway) stats(mean p50)
* right this mainly affects the mom up, unemployed pathway, since that is primarily where hh income is starting from 0. I think if I use recoded and mean it should be fine?

tab rel_status pathway if mt_mom==1, row // 90% of single are in mom up not employed; 60% of partnered are in mom up employed
tab rel_status pathway if mt_mom==1, col // 70% of unemployed = single; 88% of employed = partnered

// average change for motivation for heterogeneity paper
tabstat hh_income_raw if hh_chg_value==0, stats(mean p50)
tabstat hh_income_raw if hh_chg_value==1, stats(mean p50)

tabstat hh_income_topcode if hh_chg_value==0, stats(mean p50)
tabstat hh_income_chg if hh_chg_value==0, stats(mean p50)
tabstat hh_income_topcode if hh_chg_value==1, stats(mean p50)

sum thearn_adj, detail
gen thearn_topcode=thearn_adj
replace thearn_topcode = `r(p99)' if thearn_adj>`r(p99)'
sum thearn_topcode, detail

sum thearn_lag, detail
gen thearn_lag_topcode=thearn_lag
replace thearn_lag_topcode = `r(p99)' if thearn_lag>`r(p99)'
sum thearn_lag_topcode, detail

browse id earnings earnings_lag earn_change_raw
gen earn_change_raw_x = earn_change_raw
replace earn_change_raw = earnings-earnings_lag
browse id earnings earnings_lag earn_change_raw

browse id earnings earnings_lag earn_change_raw earn_change_raw_x

**# Start here

********************************************************************************
* Relationship status descriptives
********************************************************************************
tab single_all start_from_0, row
tab single_all end_as_sole, row

sum avg_hhsize
sum avg_hhsize if rel_status_detail==1 // single
sum avg_hhsize if rel_status_detail==2
sum avg_hhsize if rel_status_detail==3
sum avg_hhsize if single_all==1
sum avg_hhsize if partnered_all==1

sum st_minorchildren
sum st_minorchildren if rel_status_detail==1 // single
sum st_minorchildren if rel_status_detail==2
sum st_minorchildren if rel_status_detail==3
sum st_minorchildren if single_all==1
sum st_minorchildren if partnered_all==1

sum hh_income_raw
sum hh_income_raw if in_pov==0, detail
sum hh_income_raw if in_pov==1, detail
sum hh_income_raw if hh_income_raw >=-50000 & hh_income_raw <=50000, detail
sum hh_income_raw if in_pov==0 & hh_income_raw >=-50000 & hh_income_raw <=50000, detail
sum hh_income_raw if in_pov==1 & hh_income_raw >=-50000 & hh_income_raw <=50000, detail

tab rel_status_detail hh_chg_value, row

tabstat hh_income_raw, by(rel_status_detail) stats(mean p50) // mean is in paper
tabstat earn_change_raw, by(rel_status_detail) stats(p50 mean)

// tabstat hh_income_topcode, by(rel_status_detail) stats(mean p50) // let's replace with p50
tabstat hh_income_topcode, by(educ_gp) stats(mean p50) // let's replace with p50
tabstat hh_income_topcode, by(race_gp) stats(mean p50) // let's replace with p50

tabstat hh_income_topcode if educ_gp==1, by(rel_status_detail) stats(mean p50) // let's replace with p50
tabstat hh_income_topcode if educ_gp==2, by(rel_status_detail) stats(mean p50) // let's replace with p50
tabstat hh_income_topcode if educ_gp==3, by(rel_status_detail) stats(mean p50) // let's replace with p50
tabstat hh_income_topcode if race_gp==1, by(rel_status_detail) stats(mean p50) // let's replace with p50
tabstat hh_income_topcode if race_gp==2, by(rel_status_detail) stats(mean p50) // let's replace with p50
tabstat hh_income_topcode if race_gp==3, by(rel_status_detail) stats(mean p50) // let's replace with p50

// both more likely to start from 0 AND end up as 100% contributor

tabstat earnings_ratio if trans_bw60_alt2==1 & bw60lag==0, stats(mean p50)
tabstat earnings_ratio if trans_bw60_alt2==1 & bw60lag==0 & single_all==1, stats(mean p50)
tabstat earnings_ratio if trans_bw60_alt2==1 & bw60lag==0 & partnered_all==1, stats(mean p50)
tabstat earnings_ratio if trans_bw60_alt2==1 & bw60lag==0 & relationship==1, stats(mean p50)
tabstat earnings_ratio if trans_bw60_alt2==1 & bw60lag==0 & relationship==2, stats(mean p50)

tabstat earnings_ratio_lag if trans_bw60_alt2==1 & bw60lag==0, stats(mean p50)
tabstat earnings_ratio_lag if trans_bw60_alt2==1 & bw60lag==0 & single_all==1, stats(mean p50)
tabstat earnings_ratio_lag if trans_bw60_alt2==1 & bw60lag==0 & partnered_all==1, stats(mean p50)

tabstat earnings_ratio_alt_lag if trans_bw60_alt2==1 & bw60lag==0, stats(mean p50)
tabstat earnings_ratio_alt_lag if trans_bw60_alt2==1 & bw60lag==0 & single_all==1, stats(mean p50)
tabstat earnings_ratio_alt_lag if trans_bw60_alt2==1 & bw60lag==0 & partnered_all==1, stats(mean p50)
tabstat earnings_ratio_alt_lag if trans_bw60_alt2==1 & bw60lag==0 & relationship==1, stats(mean p50)
tabstat earnings_ratio_alt_lag if trans_bw60_alt2==1 & bw60lag==0 & relationship==2, stats(mean p50)

tab pov_lag // pre
tab in_pov // post

tab partnered_all pov_lag, row // pre
tab partnered_all in_pov, row // post

tab relationship pov_lag, row // pre
tab relationship in_pov, row // post

* Race
tab race, gen(race)

* Education
tab educ_gp, gen(educ_gp)
	
* Marital Status - December
tab marital_status_t1, gen(marst)

********************************************************************************
* ANALYSIS
********************************************************************************
/* this doesn't make sense because this variable now takes into account prior pov status
tab pov_lag pov_change_detail, row
tab pov_change_detail pov_lag, row

forvalues p=1/5{
	display `p'
	tab pov_change_detail pov_lag if pathway==`p', row
}

forvalues e=1/3{
	display `e'
	tab pov_change_detail pov_lag if educ_gp==`e', row
}

forvalues r=1/5{
	display `r'
	tab pov_change_detail pov_lag if race==`r', row
}

forvalues rs=1/3{
	display `rs'
	tab pov_change_detail pov_lag if rel_status_detail==`rs', row
}

forvalues rs=1/2{
	display `rs'
	tab pov_change_detail pov_lag if rel_status==`rs', row
}

tab pathway pov_change_detail if pov_lag==0, row nofreq
tab pathway pov_change_detail if pov_lag==1, row nofreq

tab race pov_change_detail if pov_lag==0, row nofreq
tab race pov_change_detail if pov_lag==1, row nofreq

tab educ_gp pov_change_detail if pov_lag==0, row nofreq
tab educ_gp pov_change_detail if pov_lag==1, row nofreq
*/

tabstat inc_pov, by(pov_lag)
tabstat inc_pov_lag, by(pov_lag)
tab educ_gp pov_lag, row

tab single_all pov_change_detail, row nofreq
tab single_all pov_change_detail if start_from_0==1, row nofreq
tab single_all pov_change_detail if start_from_0==0, row nofreq

tab relationship pov_change_detail, row nofreq

sum thearn_lag, detail  // pre 2014 -- matches paper
sum thearn_adj, detail // post 2014 -- matches paper

sum thearn_lag if single_all==1, detail
sum thearn_adj if single_all==1, detail

sum thearn_lag if partnered_all==1, detail
sum thearn_adj if partnered_all==1, detail

sum thearn_lag if relationship==1, detail
sum thearn_adj if relationship==1, detail

sum thearn_lag if relationship==2, detail
sum thearn_adj if relationship==2, detail

********************************************************************************
* Demographics by outcome and pathway
********************************************************************************

tab pov_change_detail tanf, row
tab pov_change_detail tanf_lag, row
tab pov_change_detail eeitc, row
tab pov_change_detail eitc_after, row

tab pathway tanf, row
tab pathway tanf_lag, row
tab pathway eeitc, row
tab pathway eitc_after, row
tab pathway_v1 pov_change_detail, row
tab pathway pov_change_detail, row
//tab pathway pov_change_detail if partnered==0, row
//tab pathway pov_change_detail if partnered==1, row

tab pov_change_detail educ_gp, row nofreq
tab pov_change_detail race, row nofreq
//tab pov_change_detail partnered, row nofreq
tab pov_change_detail tanf_lag, row nofreq
tab pov_change_detail eeitc, row nofreq
tab pov_change_detail eitc_after, row nofreq
tab pov_change_detail zero_earnings, row nofreq

//tab pov_change_detail tanf_lag if partnered==0, row

tab pathway pov_change_detail if educ_gp==1, row
//tab pathway pov_change_detail if partnered==1, row

	
histogram hh_income_raw if hh_income_raw > -50000 & hh_income_raw <50000, kdensity width(5000) addlabel addlabopts(yvarformat(%4.1f)) percent xlabel(-50000(10000)50000) title("Household income change upon transition to BW") xtitle("HH income change")
histogram inc_pov_change_raw if inc_pov_change_raw < 5 & inc_pov_change_raw >-5, width(.5) xlabel(-5(0.5)5) addlabel addlabopts(yvarformat(%4.1f)) percent

browse SSUID PNUM year earnings_adj earnings_lag thearn_adj thearn_lag hh_income_raw inc_pov inc_pov_lag inc_pov_change_raw

histogram hh_income_raw if hh_income_raw > -50000 & hh_income_raw <50000 & single_all==1, kdensity width(5000) addlabel addlabopts(yvarformat(%4.1f)) percent xlabel(-50000(10000)50000) title("Household income change upon transition to BW") xtitle("HH income change") // single moms

histogram hh_income_raw if hh_income_raw > -50000 & hh_income_raw <50000 & partnered_all==1, kdensity width(5000) addlabel addlabopts(yvarformat(%4.1f)) percent xlabel(-50000(10000)50000) title("Household income change upon transition to BW") xtitle("HH income change") // partnered

********************************************************************************
* Pathway descriptives
********************************************************************************
gen mom_earn_change=.
replace mom_earn_change=-1 if mom_lose_earn==1 | earn_change <0
replace mom_earn_change=0 if mom_gain_earn==0 & earnup8_all==0 & mom_lose_earn==0 & earn_change==0
replace mom_earn_change=1 if earnup8_all==1
replace mom_earn_change=0 if mom_earn_change==. // the very small mom ups - want to be considered no change
replace mom_earn_change=1 if mom_earn_change==0 & mt_mom==1 // BUT want the very small moms if ONLY mom's earnings went up, because there is nowhere else to put
/*
gen pathway_detail=.
replace pathway_detail=1 if pathway==1 // no earnings prior
replace pathway_detail=2 if pathway==2 // she had earnings
replace pathway_detail=3 if pathway==4 & earnings_sp_adj==0 // partner down to 0
replace pathway_detail=4 if pathway==4 & earnings_sp_adj!=0 // partner not down to 0
replace pathway_detail=5 if pathway==3
replace pathway_detail=6 if pathway==6 & inlist(mom_earn_change,-1,0) & end_as_sole==1 // just other, down to 0
replace pathway_detail=7 if pathway==6 & inlist(mom_earn_change,-1,0) & end_as_sole==0 // just other, not down to 0
replace pathway_detail=8 if pathway==6 & mom_earn_change==1 // both
replace pathway_detail=9 if pathway==5 & inlist(mom_earn_change,-1,0) // just partner left
replace pathway_detail=10 if pathway==5 & mom_earn_change==1 // partner left and her earnings up

label define pathway_detail 1 "Mom Up from 0" 2 "Mom Up" 3 "Partner Down to 0" 4 "Partner Down" 5 "Mom Up Partner Down" 6 "Other Down to 0" 7 "Other Down" 8 "Mom Up Other Down" 9 "Dissolution" 10 "Dissolution Mom Up"
label values pathway_detail pathway_detail

browse SSUID PNUM earnings_adj earnings_lag earnings_sp_adj thearn_adj thearn_lag pathway_detail earnings_ratio end_as_sole mom_earn_change
sum earn_change_sp
sum earn_change_raw_sp
sum earn_change_raw_sp if pathway_detail==3
sum earn_change_raw_sp if pathway_detail==4
sum earnings_sp_adj if pathway_detail==3
sum earnings_sp_adj if pathway_detail==4

tabstat hh_income_raw, by(pathway) stats(mean p50)
tabstat thearn_adj, by(pathway) stats(mean p50)
tabstat hh_income_raw, by(pathway_detail) stats(mean p50)
tabstat thearn_adj, by(pathway_detail) stats(mean p50)
tabstat hh_income_topcode, by(pathway) stats(mean p50)
tabstat hh_income_topcode, by(pathway_detail) stats(mean p50)

gen pathway_final=.
replace pathway_final=1 if pathway_detail==1 // mom up from 0
replace pathway_final=2 if pathway_detail==2 // mom up
replace pathway_final=3 if inlist(pathway_detail,3,4,9) // partner down or left, mom no change
replace pathway_final=4 if inlist(pathway_detail,6,7) // other down, mom no change
replace pathway_final=5 if inlist(pathway_detail,5,10) // partner down or left, mom up
replace pathway_final=6 if pathway_detail==8 // other down, mom up

label define pathway_final 1 "Mom Up from 0" 2 "Mom up" 3 "Partner Down" 4 "Other Down" 5 "Partner Down Mom Up" 6 "Other Down Mom Up"
label values pathway_final pathway_final

tabstat hh_income_raw, by(pathway_final) stats(mean p50)
tabstat thearn_adj, by(pathway_final) stats(mean p50)
*/
tabstat hh_income_raw, by(educ_gp) stats(mean p50)
tabstat hh_income_topcode, by(educ_gp) stats(mean p50)
tabstat thearn_adj, by(educ_gp) stats(mean p50)

tabstat hh_income_raw, by(race) stats(mean p50)
tabstat hh_income_topcode, by(race) stats(mean p50)
tabstat thearn_adj, by(race) stats(mean p50)

********************************************************************************
**# Descriptives to use
******************************************************************************** 
// log using "$logdir\impact_stats.log", replace
* Table 1
tabstat earnings_lag if earnings_lag > 0, stats(mean p50 sd semean) 
tabstat earnings_lag if start_from_0==0, stats(mean p50 sd semean)
tab start_from_0
tabstat thearn_lag if thearn_lag > 0, stats(mean p50 sd semean)
tabstat thearn_lag, stats(mean p50 sd semean)
tab extended_hh
sum avg_hhsize
// tab partnered_t
// tab partnered_t1
tab marital_status_t1
tab relationship, m

tabstat hh_income_raw, stats(mean p50)
tabstat hh_income_topcode, stats(mean p50)
tabstat hh_income_chg_x, stats(mean p50)
tabstat income_chg_top, stats(mean p50)
tabstat hh_income_raw if hh_chg_value==0, stats(mean p50) // average decrease
tabstat hh_income_raw if hh_chg_value==1, stats(mean p50) // average increase
tabstat hh_income_topcode if hh_chg_value==0, stats(mean p50) // average decrease
tabstat hh_income_topcode if hh_chg_value==1, stats(mean p50) // average increase

tabstat hh_income_raw if hh_income_raw < 0, stats(mean p50) // -$45000
tabstat income_chg_top if income_chg_top < 0, stats(mean p50) // -42%

tabstat hh_income_raw, by(educ_gp) stats(mean p50)
tabstat hh_income_topcode, by(educ_gp) stats(mean p50)
tabstat hh_income_chg_x, by(educ_gp) stats(mean p50)
tabstat thearn_lag, by(educ_gp) stats(mean p50)
tabstat pre_percentile, by(educ_gp) stats(mean p50)
tabstat percentile_chg, by(educ_gp) stats(mean p50)
tab educ_gp hh_chg_value, row
tabstat hh_income_raw if hh_chg_value==0, by(educ_gp) stats(mean p50) // average decrease
tabstat hh_income_raw if hh_chg_value==1, by(educ_gp) stats(mean p50) // average increase

tabstat hh_income_raw, by(race) stats(mean p50)
tabstat hh_income_topcode, by(race) stats(mean p50)
tabstat hh_income_chg_x, by(race) stats(mean p50)
tabstat thearn_lag, by(race) stats(mean p50)
tabstat pre_percentile, by(race) stats(mean p50)
tabstat percentile_chg, by(race) stats(mean p50)
tab race_gp hh_chg_value, row
tabstat hh_income_raw if hh_chg_value==0, by(race_gp) stats(mean p50) // average decrease
tabstat hh_income_raw if hh_chg_value==1, by(race_gp) stats(mean p50) // average increase

tabstat hh_income_raw, by(pathway) stats(mean p50)
tabstat hh_income_topcode, by(pathway) stats(mean p50)
tabstat hh_income_chg_x, by(pathway) stats(mean p50)
tabstat thearn_lag, by(pathway) stats(mean p50)
tabstat pre_percentile, by(pathway) stats(mean p50)
tabstat percentile_chg, by(pathway) stats(mean p50)
tab pathway hh_chg_value, row
tabstat hh_income_raw if hh_chg_value==0, by(pathway) stats(mean p50) // average decrease
tabstat hh_income_raw if hh_chg_value==1, by(pathway) stats(mean p50) // average increase

tabstat hh_income_raw, by(educ_x_race) stats(mean p50)
tabstat hh_income_topcode, by(educ_x_race) stats(mean p50)
tabstat hh_income_chg_x, by(educ_x_race) stats(mean p50) // p50
tabstat thearn_lag, by(educ_x_race) stats(mean p50)
tabstat pre_percentile, by(educ_x_race) stats(mean p50)
tabstat percentile_chg, by(educ_x_race) stats(mean p50)
tab educ_x_race hh_chg_value, row
tabstat hh_income_raw if hh_chg_value==0, by(educ_x_race) stats(mean p50) // average decrease
tabstat hh_income_raw if hh_chg_value==1, by(educ_x_race) stats(mean p50) // average increase

// variance pre / post (for these households or for ALL)
tabstat thearn_lag thearn_adj, stats(mean p50 sd var cv range)

tab pathway_v1  pov_change_detail, row
tab pathway pov_change_detail, row
tab educ_gp pov_change_detail, row
tab race pov_change_detail, row
tab rel_status_detail pov_change_detail, row
tab rel_status pov_change_detail, row

tab pov_change_detail income_change, row

tab educ_gp pathway, row nofreq
tab race pathway, row nofreq

tab educ_gp pathway, row nofreq chi2 // Pearson chi2(10) =  99.1910   Pr = 0.000
tab race pathway, row nofreq chi2 // Pearson chi2(20) =  90.6400   Pr = 0.000

tab educ_gp pathway, row nofreq cchi2 // Pearson chi2(10) =  99.1910   Pr = 0.000
tab race pathway, row nofreq cchi2 // Pearson chi2(20) =  90.6400   Pr = 0.000

forvalues x=1/3{
	display "Educ = `x'"
	tabstat hh_income_raw if educ_gp==`x', by(pathway) stats(mean p50)
	display "Race = `x'"
	tabstat hh_income_raw if race_gp==`x', by(pathway) stats(mean p50)
}

forvalues x=1/3{
	display "Educ = `x'"
	tabstat percentile_chg if educ_gp==`x', by(pathway) stats(mean p50)
	display "Race = `x'"
	tabstat percentile_chg if race_gp==`x', by(pathway) stats(mean p50)
}




forvalues p=1/6{
	display `p'
	tab pov_change_detail income_change if pathway==`p', row
}

forvalues e=1/3{
	display `e'
	tab pov_change_detail income_change if educ_gp==`e', row
}

forvalues r=1/5{
	display `r'
	tab pov_change_detail income_change if race==`r', row
}

forvalues rs=1/3{
	display `rs'
	tab pov_change_detail income_change if rel_status_detail==`rs', row
}

forvalues rs=1/2{
	display `rs'
	tab pov_change_detail income_change if rel_status==`rs', row
}

forvalues e=1/3{
	display `e'
	tab pathway_final pov_change_detail if educ_gp==`e', row nofreq
}

forvalues r=1/5{
	display `r'
	tab pathway_final pov_change_detail if race==`r', row nofreq
}

****************************************************************************
* Descriptives for potential decomp
****************************************************************************
tabstat hh_income_raw if educ_gp==1, by(pathway) stats(mean p50)
tabstat hh_income_raw if educ_gp==2, by(pathway) stats(mean p50)
tabstat hh_income_raw if educ_gp==3, by(pathway) stats(mean p50)

tabstat percentile_chg if educ_gp==1, by(pathway) stats(mean p50)
tabstat percentile_chg if educ_gp==2, by(pathway) stats(mean p50)
tabstat percentile_chg if educ_gp==3, by(pathway) stats(mean p50)

tabstat hh_income_raw if race_gp==1, by(pathway) stats(mean p50)
tabstat hh_income_raw if race_gp==2, by(pathway) stats(mean p50)
tabstat hh_income_raw if race_gp==3, by(pathway) stats(mean p50)

tabstat percentile_chg if race_gp==1, by(pathway) stats(mean p50)
tabstat percentile_chg if race_gp==2, by(pathway) stats(mean p50)
tabstat percentile_chg if race_gp==3, by(pathway) stats(mean p50)

// * these are appendix table in JFEI paper - using p50
tabstat hh_income_raw if educ_gp==1, by(rel_status_detail) stats(mean p50)
tabstat hh_income_raw if educ_gp==2, by(rel_status_detail) stats(mean p50)
tabstat hh_income_raw if educ_gp==3, by(rel_status_detail) stats(mean p50)

tabstat hh_income_raw if race_gp==1, by(rel_status_detail) stats(mean p50)
tabstat hh_income_raw if race_gp==2, by(rel_status_detail) stats(mean p50)
tabstat hh_income_raw if race_gp==3, by(rel_status_detail) stats(mean p50)

tab rel_status_detail in_pov if educ_gp==1, row
tab rel_status_detail in_pov if educ_gp==2, row
tab rel_status_detail in_pov if educ_gp==3, row

tab rel_status_detail in_pov if race_gp==1, row
tab rel_status_detail in_pov if race_gp==2, row
tab rel_status_detail in_pov if race_gp==3, row

********************************************************************************
**# Bookmark #1
* Models to use
********************************************************************************
** In JFEI paper
*regress hh_income_raw_all ib2.rel_status_detail i.educ_gp i.race //// okay this matches the 11/8 file but NOT the paper - did the numbers get updated somewhere?
regress hh_income_topcode ib2.rel_status_detail i.educ_gp i.race // okay I am dumb - this IS what is in the paper, the topcode, okay.

*regress hh_income_raw_all ib2.rel_status_detail i.educ_gp i.race i.pov_lag // didn't include but should I?
regress hh_income_topcode ib2.rel_status_detail i.educ_gp i.race i.pov_lag // add to table

logit in_pov ib2.rel_status_detail i.educ_gp i.race, or
logit in_pov ib2.rel_status_detail i.educ_gp i.race i.pov_lag, or

*regress hh_income_topcode ib2.rel_status_detail i.educ_gp i.race i.pathway // controlling for pathway is weird

*Moderation effects?
regress hh_income_topcode ib2.rel_status_detail##i.race_gp i.educ_gp // think it's just only sig for whites bc sample - only 6 Blacks dissolved
margins rel_status_detail#race_gp

regress hh_income_topcode ib2.rel_status_detail##i.educ_gp i.race_gp // literally nothing is significant.
margins rel_status_detail#educ_gp

** For other paper - raw income change
regress hh_income_raw_all i.educ_gp
regress hh_income_raw_all i.race
regress hh_income_raw_all i.pathway
regress hh_income_raw_all i.pathway_v1 i.race i.educ_gp
regress hh_income_raw_all i.pathway i.race i.educ_gp
regress hh_income_raw_all i.pathway i.race i.educ_gp i.pov_lag

regress hh_income_topcode i.educ_gp
regress hh_income_topcode i.race
regress hh_income_topcode i.pathway
regress hh_income_topcode i.pathway i.race i.educ_gp
regress hh_income_topcode i.pathway i.race i.educ_gp i.pov_lag

regress hh_income_chg i.educ_gp
regress hh_income_chg i.race
regress hh_income_chg i.pathway_v1
regress hh_income_chg i.pathway
regress hh_income_chg ib3.pathway
regress hh_income_chg ib3.pathway i.race i.educ_gp
regress hh_income_chg ib3.pathway i.race i.educ_gp i.pov_lag

// use
regress hh_income_chg_x i.educ_gp
regress hh_income_chg_x i.race
regress hh_income_chg_x i.pathway_v1
regress hh_income_chg_x i.pathway
regress hh_income_chg_x ib3.pathway
regress hh_income_chg_x ib3.pathway i.race i.educ_gp
regress hh_income_chg_x ib3.pathway i.race i.educ_gp i.pov_lag

regress income_chg_top_x ib3.pathway i.race_gp i.educ_gp
regress income_chg_top_x ib3.pathway i.race_gp i.educ_gp i.pov_lag

// topcoding change
sum hh_income_chg_x, detail
gen income_chg_top_x=hh_income_chg_x
replace income_chg_top_x = `r(p1)' if hh_income_chg_x<`r(p1)'
replace income_chg_top_x = `r(p99)' if hh_income_chg_x>`r(p99)'

browse income_chg_top_x hh_income_chg_x

regress income_chg_top_x ib3.pathway i.race_gp i.educ_gp 

// test
regress income_chg_top_x i.educ_gp
estimates store m1 
outreg2 using "$results/regression_percent_change.xls", sideway stats(coef) label ctitle(M1) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace

regress income_chg_top_x i.race_gp
estimates store m2
outreg2 using "$results/regression_percent_change.xls", sideway stats(coef) label ctitle(M2) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

regress income_chg_top_x ib3.pathway
estimates store m3
outreg2 using "$results/regression_percent_change.xls", sideway stats(coef) label ctitle(M3) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

regress income_chg_top_x ib3.pathway i.race_gp
estimates store m4
outreg2 using "$results/regression_percent_change.xls", sideway stats(coef) label ctitle(M4) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

regress income_chg_top_x ib3.pathway i.educ_gp
estimates store m5
outreg2 using "$results/regression_percent_change.xls", sideway stats(coef) label ctitle(M5) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

regress income_chg_top_x ib3.pathway i.race_gp i.educ_gp 
estimates store m6
outreg2 using "$results/regression_percent_change.xls", sideway stats(coef) label ctitle(M6) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

regress income_chg_top_x ib3.pathway i.race_gp i.educ_gp i.pov_lag
estimates store m7 
outreg2 using "$results/regression_percent_change.xls", sideway stats(coef) label ctitle(M7) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

regress income_chg_top_x ib3.pathway##i.race i.educ_gp i.pov_lag
regress income_chg_top_x ib3.pathway##i.race i.educ_gp i.pov_lag if inlist(race,1,2,4) // r-squared is sig reduced if I don't include asian or other...
regress income_chg_top_x ib3.pathway##i.race_gp i.educ_gp i.pov_lag // r-squared is sig reduced if I don't split asian or other...
estimates store m8
outreg2 using "$results/regression_percent_change.xls", sideway stats(coef) label ctitle(M8) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

regress income_chg_top_x ib3.pathway##i.educ_gp i.race_gp i.pov_lag
estimates store m9
outreg2 using "$results/regression_percent_change.xls", sideway stats(coef) label ctitle(M9) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

//estimates table m1 m2 m3 m4 m5 m6 m7 m8 m9, star b(%9.3f)
//estout m1 m2 m3 m4 m5 m6 m7 m8 m9, stats(r2_a)

* In poverty as outcome
logit in_pov i.educ_gp, or
logit in_pov i.race, or
logit in_pov i.pathway, or
logit in_pov ib3.pathway i.race i.educ_gp, or

logit in_pov i.educ_gp i.pov_lag, or
logit in_pov i.race i.pov_lag, or
logit in_pov i.pathway i.pov_lag, or
logit in_pov ib3.pathway i.race i.educ_gp i.pov_lag, or

// log close

********************************************************************************
* Percentiles
********************************************************************************
regress percentile_chg i.educ_gp
regress percentile_chg i.race_gp
regress percentile_chg ib3.pathway

regress percentile_chg i.educ_gp##ib3.pathway
margins educ_gp#pathway

regress percentile_chg i.race_gp##ib3.pathway
margins race_gp#pathway

regress post_percentile i.educ_gp pre_percentile


********************************************************************************
* Other
********************************************************************************
*Descriptive for comparison

tabstat hh_income_raw_all, stats(mean p50)
tabstat hh_income_raw_all, by(pathway) stats(mean p50)
tabstat hh_income_raw_all, by(race) stats(mean p50)
tabstat hh_income_raw_all, by(educ_gp) stats(mean p50)
tabstat hh_income_raw_all, by(rel_status_detail) stats(mean p50)
tabstat hh_income_raw_all, by(rel_status) stats(mean p50)

regress hh_income_raw_all 
regress hh_income_raw_all i.trans_bw60_alt2 i.educ_gp i.race i.rel_status ageb1 i.status_b1 // controls for those most likely to become BW
regress hh_income_raw_all i.pathway
regress hh_income_raw_all ib2.pathway
regress hh_income_raw_all i.race if inlist(race,1,2,4) // okay so none of these significant.
regress hh_income_raw_all i.race if rel_status==2
regress hh_income_raw_all i.educ_gp // also these
regress hh_income_raw_all i.educ_gp if rel_status==2
regress hh_income_raw_all ib2.rel_status // or these
regress hh_income_raw_all ib2.rel_status_detail
regress hh_income_raw_all ib2.rel_status i.educ_gp i.race // or these

regress hh_income_raw_all ib2.rel_status_detail i.educ_gp i.race // but I think this is what is in the paper?regress hh_income_raw_all ib2.rel_status_detail i.educ_gp i.race // but I think this is what is in the paper?
regress hh_income_topcode ib2.rel_status_detail i.educ_gp i.race // USE
regress hh_income_raw_all ib2.rel_status_detail i.educ_gp i.race i.pov_lag // do I need to do this?

margins rel_status_detail
margins educ_gp
margins race
regress hh_income_raw_all ib2.rel_status_detail i.educ_gp i.race i.pov_lag // wait do I need to control for poverty lag here? when I do this, education becomes significant

regress hh_income_raw_all i.educ_gp i.race i.rel_status ageb1 i.status_b1 // do I need to put all in same model? or is this wild. how to control? do need to control for each other?

regress hh_income_topcode ib2.rel_status_detail // not sig with controls
regress hh_income_topcode ib2.rel_status_detail i.educ_gp i.race // single is marginally signifcant here (p=.06)
regress hh_income_raw_all ib2.rel_status_detail i.educ_gp i.race // single is marginally signifcant here (p=.06)

**** Pathway analysis
// what if I put in 1000s?
gen hh_income_1000s = hh_income_topcode / 1000

regress hh_income_topcode ib6.pathway_final
regress hh_income_topcode ib6.pathway_final ib2.rel_status_detail i.educ_gp i.race // use these coefficients for pathway, education, and race
regress hh_income_1000s ib6.pathway_final

// interactions
regress hh_income_topcode ib6.pathway_final
regress hh_income_topcode i.educ_gp // nothing sig
regress hh_income_topcode ib6.pathway_final##i.educ_gp // college plus main effect becomes sig. few interactions sig except college plus partner down and other down (more negative)
margins pathway_final#educ_gp
marginsplot

regress hh_income_topcode i.race // nothing sig
regress hh_income_topcode ib6.pathway_final##i.race if inlist(race,1,2,4) // black main effect becomes marginally sig.  some interactions with Black and other down, partner down (more positive?)
margins pathway_final#race
marginsplot

/*
regress log_income_change
regress log_income_change ib2.pathway
regress log_income_change ib2.pathway if rel_status==2
regress log_income_change i.race // nope still not
regress log_income_change i.race if rel_status==2
regress log_income_change ib2.pathway##i.race if inlist(race,1,2,4)
regress log_income_change i.educ_gp // also these
regress log_income_change i.educ_gp if rel_status==2
regress log_income_change ib2.pathway##i.educ_gp // okay also not
regress log_income_change i.rel_status_detail // okay these are significant
regress log_income_change i.educ_gp i.race i.rel_status ageb1 i.status_b1 // do I need to put all in same model? or is this wild. how to control? do need to control for each other?


regress inc_pov_change_raw ib2.pathway
regress inc_pov_change_raw i.race // nope
regress inc_pov_change_raw i.educ_gp // nope

mlogit pov_change_detail, rrr

mlogit pov_change_detail i.pathway, rrr 
margins i.pathway

mlogit pov_change_detail i.pathway i.pov_lag, rrr
margins i.pathway

mlogit pov_change_detail i.educ_gp, rrr
margins i.educ_gp
marginsplot
mlogit pov_change_detail i.educ_gp i.pov_lag, rrr
margins i.educ_gp

mlogit pov_change_detail i.race if inlist(race,1,2,4), rrr
margins i.race
marginsplot
mlogit pov_change_detail i.race i.pov_lag if inlist(race,1,2,4), rrr
margins i.race

mlogit pov_change_detail i.rel_status i.educ_gp i.race, rrr
margins i.rel_status
mlogit pov_change_detail i.rel_status i.educ_gp i.race i.pov_lag, rrr
margins i.rel_status

mlogit pov_change_detail i.rel_status_detail i.educ_gp i.race, rrr
margins i.rel_status_detail
mlogit pov_change_detail i.rel_status_detail i.educ_gp i.race i.pov_lag, rrr
margins i.rel_status_detail
*/

// okay so poverty is kind of interesting
logit in_pov, or
logit in_pov ib2.pathway i.educ_gp i.race, or
logit in_pov ib2.pathway, or
logit in_pov i.race if inlist(race,1,2,4), or
logit in_pov i.race##ib2.pathway if inlist(race,1,2,4), or // this is actually interesting, but is this really about who is already likely?
logit in_pov i.educ_gp, or
logit in_pov i.educ_gp##ib2.pathway, or
logit in_pov ib2.rel_status i.educ_gp i.race
logit in_pov ib2.rel_status_detail i.educ_gp i.race, or
margins rel_status_detail
margins educ_gp
margins race

logit in_pov ib2.pathway i.pov_lag, or
logit in_pov i.race i.pov_lag if inlist(race,1,2,4), or
logit in_pov i.educ_gp i.pov_lag, or
logit in_pov ib2.rel_status i.educ_gp i.race i.pov_lag
logit in_pov ib2.rel_status_detail i.educ_gp i.race i.pov_lag, or
margins rel_status_detail
margins educ_gp
margins race

logit in_pov ib6.pathway_final ib2.rel_status_detail i.educ_gp i.race, or // use these for pathway, race, educ
logit in_pov ib6.pathway_final ib2.rel_status_detail i.educ_gp i.race i.pov_lag, or

/// OKAY, effect of transitioning - interaction
regress log_income_change i.trans_bw60_alt2 if pathway!=0
regress hh_income_raw_all i.trans_bw60_alt2 if pathway!=0 // okay once I restrict to those who DID not experience an event, it goes away. DUH
regress hh_income_raw_all i.trans_bw60_alt2 i.educ_gp i.race i.status_b1 i.rel_status if pathway!=0

regress log_income_change i.trans_bw60_alt2##i.race if inlist(race,1,2,4) & pathway!=0
regress hh_income_raw_all i.trans_bw60_alt2##i.race if inlist(race,1,2,4) & pathway!=0 // still not sig
margins trans_bw60_alt2#race

regress log_income_change i.trans_bw60_alt2##i.educ_gp 
regress hh_income_raw_all i.trans_bw60_alt2##i.educ_gp if pathway!=0
margins trans_bw60_alt2#educ_gp // college is significant

regress hh_income_raw_all i.trans_bw60_alt2##ib2.pathway if pathway!=0
margins trans_bw60_alt2#pathway

logit in_pov i.trans_bw60_alt2 i.pov_lag, or
logit in_pov i.trans_bw60_alt2##i.race i.pov_lag, or // not sig when I control for prior poverty
logit in_pov i.trans_bw60_alt2##i.educ_gp i.pov_lag, or // okay education BECOMES sig when i control for prior poverty (for college)
margins trans_bw60_alt2#educ_gp

tab pov_lag in_pov, row // is it really that maternal BW reinforces not actually alters path? that is why I think movement in and out of poverty is more intersting. maybe do like three - income, 4 category, then movements across the two?
tab pov_lag in_pov if trans_bw60_alt2==1, row

tab race pov_change_detail, row
tab educ_gp pov_change_detail, row
tab rel_status pov_change_detail, row
tab partnered_no_chg pov_change_detail, row // to get those partnered all year
tab pathway end_as_sole, row nofreq // proxy for partner going down to 0? (or whoever lost earnings)
tab pathway pov_change_detail, row nofreq
tab pathway_detail pov_change_detail, row nofreq
tab pathway_final pov_change_detail, row nofreq

mlogit pov_change i.race, rrr
mlogit pov_change i.educ_gp, rrr

mlogit pov_change_detail i.pathway, rrr
margins i.pathway

mlogit pov_change_detail i.pathway i.race i.educ_gp, rrr
margins i.pathway

mlogit pov_change_detail i.educ_gp, rrr
margins i.educ_gp

mlogit pov_change_detail i.race if inlist(race,1,2,4), rrr
margins i.race

mlogit pov_change_detail i.rel_status i.educ_gp i.race, rrr
margins i.rel_status

mlogit pov_change_detail i.rel_status_detail i.educ_gp i.race, rrr
margins i.rel_status_detail


// end pov
histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000, percent addlabel width(5000) // all
graph export "$results\all_income_changes.png", as(png) name("Graph")
histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & in_pov==1, percent addlabel width(5000) // in pov
graph export "$results\all_income_changes_inpov.png", as(png) name("Graph")
histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & in_pov==0, percent addlabel width(5000) // not in pov
graph export "$results\all_income_changes_notinpov.png", as(png) name("Graph")

// mlabformat(%fmt)

twoway (histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & in_pov==1, percent width(5000) color(red%30)) ///
(histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & in_pov==0, percent width(5000) color(dkgreen%30)), ///
legend(order(1 "In financial hardship" 2 "Not in financial hardship" )) xlabel(-50000(5000)50000, labsize(vsmall) angle(forty_five) valuelabel) xtitle("Household Income Change") ytitle("Percent Distribution") graphregion(fcolor(white))
graph export "$results\income_change_by_pov.png", as(png) name("Graph")


// started in pov
histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000, percent addlabel width(5000) // all
histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & pov_lag==1, percent addlabel width(5000) // in pov
histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & pov_lag==0, percent addlabel width(5000) // not in pov


********************************************************************************
**# Bookmark #2
* Descriptive: pathway by race / educ + categorical outcome
********************************************************************************
tab pov_change_detail, gen(outcome)

putexcel set "$results/Breadwinner_Impact_Tables", sheet(Table5) modify
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
			sum outcome`i' if trans_bw60_alt2==1 & survey_yr==2 & `var'==1 &	educ_gp==`e', detail // 2014
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
			sum outcome`i' if trans_bw60_alt2==1 & survey_yr==2 & `var'==1 &	race_gp==`r', detail // 2014
			putexcel `col'`row'=`r(mean)', nformat(#.##%)
			}
		local ++x
	}
}

// validate
tab pathway outcome if educ_gp==1, row nofreq

********************************************************************************
**# Figures
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

********************************************************************************
**# Models to use for heterogeneity paper
* Multilevel models
********************************************************************************
// alt income
gen thearn_lag_1000s = thearn_lag / 1000
gen thearn_lag_ln = ln(thearn_lag + 0.01)
drop thearn_lag_topcode
gen thearn_lag_topcode=thearn_lag
sum thearn_lag, detail
replace thearn_lag_topcode = `r(p90)' if thearn_lag > `r(p90)'

tab pre_percentile, gen(pre)

mixed percentile_chg 
mixed percentile_chg || pre_percentile: , stddev
mixed percentile_chg ib3.educ_gp || pre_percentile: 
mixed percentile_chg ib3.educ_gp i.pre_percentile || pre_percentile: , stddev
mixed percentile_chg ib3.pathway || pre_percentile: , stddev

*Education
mixed percentile_chg ib3.educ_gp || pre_percentile: // pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10
predict r_educ, reffects
predict r_educ_se, reses
margins educ_gp
outreg2 using "$results/heterogeneity_models_mlm.xls", stats(coef se pval) label ctitle(M1) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace

mixed percentile_chg ib3.educ_gp || pre_percentile:
mixed percentile_chg ib3.educ_gp i.pre_percentile || pre_percentile:
predict r_educ_test, reffects
regress percentile_chg ib3.educ_gp i.pre_percentile

*Race
mixed percentile_chg i.race_gp || pre_percentile: // pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10
margins race_gp
predict r_race, reffects
predict r_race_se, reses
outreg2 using "$results/heterogeneity_models_mlm.xls", stats(coef se pval) label ctitle(M2) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

*Pathway
mixed percentile_chg ib3.pathway || pre_percentile: // pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10
margins pathway
predict r_pathway, reffects
predict r_pathway_se, reses
outreg2 using "$results/heterogeneity_models_mlm.xls", stats(coef se pval) label ctitle(M3) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
mixed percentile_chg ib2.pathway || pre_percentile: pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10

*Race + Educ
mixed percentile_chg i.race_gp ib3.educ_gp || pre_percentile: // pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10
margins educ_gp
margins race_gp
predict r_race_educ, reffects
predict r_race_educ_se, reses
outreg2 using "$results/heterogeneity_models_mlm.xls", stats(coef se pval) label ctitle(M4) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

*Race + Educ + Pathway
mixed percentile_chg i.race_gp ib3.educ_gp ib3.pathway || pre_percentile: // pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10
margins educ_gp
margins race_gp
margins pathway
predict r_race_educ_pathway, reffects
predict r_race_educ_pathway_se, reses
outreg2 using "$results/heterogeneity_models_mlm.xls", stats(coef se pval) label ctitle(M5) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

* Get random effects for above
browse pre_percentile r_educ r_race r_pathway r_race_educ r_race_educ_pathway r_educ_se r_race_se r_pathway_se r_race_educ_se r_race_educ_pathway_se
tabstat r_educ r_race r_pathway r_race_educ r_race_educ_pathway, by(pre_percentile)
tabstat r_educ_se r_race_se r_pathway_se r_race_educ_se r_race_educ_pathway_se, by(pre_percentile)

*Interactions: Just Education
mixed percentile_chg i.race_gp ib3.educ_gp##ib3.pathway || pre_percentile: // pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10
predict r_educ_int, reffects
margins educ_gp#pathway, nofvlabel
outreg2 using "$results/heterogeneity_models_mlm.xls", stats(coef se pval) label ctitle(Int1) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
contrast pathway@educ_gp, effects
pwcompare educ_gp#pathway
pwcompare educ_gp#pathway, nofvlabel

mixed percentile_chg i.race_gp ib3.educ_gp##ib2.pathway || pre_percentile:  // okay so changing pathway reference group DOES matter
outreg2 using "$results/heterogeneity_models_mlm.xls", stats(coef se pval) label ctitle(Int1) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
mixed percentile_chg i.race_gp ib3.pathway##ib3.educ_gp || pre_percentile:
mixed percentile_chg i.race_gp ib3.pathway##ib1.educ_gp || pre_percentile:

*Interactions: Just Race
mixed percentile_chg i.race_gp##ib3.pathway ib3.educ_gp || pre_percentile: // pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10
predict r_race_int, reffects
margins race_gp#pathway, nofvlabel
outreg2 using "$results/heterogeneity_models_mlm.xls", stats(coef se pval) label ctitle(Int2) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

mixed percentile_chg i.race_gp##ib2.pathway ib3.educ_gp || pre_percentile: // okay so changing pathway reference group DOES matter
outreg2 using "$results/heterogeneity_models_mlm.xls", stats(coef se pval) label ctitle(Int2) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

browse pre_percentile r_educ_int r_race_int
tabstat r_educ_int r_race_int, by(pre_percentile)

*Interactions: All
mixed percentile_chg i.race_gp ib3.educ_gp ib3.pathway i.race_gp#ib3.pathway ib3.educ_gp#ib3.pathway || pre_percentile: // pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10
margins educ_gp#pathway, nofvlabel
pwcompare educ_gp#pathway, nofvlabel
margins race_gp#pathway, nofvlabel
pwcompare race_gp#pathway, nofvlabel
outreg2 using "$results/heterogeneity_models_mlm.xls", stats(coef se pval) label ctitle(Int3) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

mixed percentile_chg i.race_gp ib3.educ_gp ib2.pathway i.race_gp#ib2.pathway ib3.educ_gp#ib2.pathway || pre_percentile: // pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10
outreg2 using "$results/heterogeneity_models_mlm.xls", stats(coef se pval) label ctitle(Int3) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

*Does education mediate race?
regress percentile_chg i.race_gp i.pre_percentile
est store r1
regress percentile_chg i.race_gp ib3.educ_gp i.pre_percentile
est store r2

suest r1 r2 // can't use suest with mixed
test [r1_mean]2.race_gp=[r2_mean]2.race_gp
test [r1_mean]3.race_gp=[r2_mean]3.race_gp

/// https://stats.oarc.ucla.edu/stata/faq/how-can-i-do-mediation-analysis-with-a-categorical-iv-in-stata/

*Does pathway mediate education?
regress percentile_chg i.race_gp ib3.educ_gp i.pre_percentile
est store e1
regress percentile_chg i.race_gp ib3.educ_gp ib3.pathway i.pre_percentile
est store e2

suest e1 e2
test [e1_mean]1.educ_gp=[e2_mean]1.educ_gp
test [e1_mean]2.educ_gp=[e2_mean]2.educ_gp

*Does pathway mediate race? I guess these are the same model as above since need all three in model
test [e1_mean]2.race_gp=[e2_mean]2.race_gp // sig at 0.09
test [e1_mean]3.race_gp=[e2_mean]3.race_gp // not sig

	*but also test this
	est replay r1
	regress percentile_chg i.race_gp ib3.pathway i.pre_percentile
	est store r3
	
	suest r1 r3
	test [r1_mean]2.race_gp=[r3_mean]2.race_gp // sig
	test [r1_mean]3.race_gp=[r3_mean]3.race_gp


********************************************************************************
**# Alternative models to use for heterogeneity paper
* OLS
********************************************************************************
regress percentile_chg ib3.educ_gp // option 1
regress percentile_chg ib3.educ_gp i.pre_percentile // option 2
regress percentile_chg ib3.educ_gp thearn_lag_ln // option 3
regress percentile_chg ib3.educ_gp thearn_lag_ln i.start_from_0 // option 4

// Models
*Education
regress percentile_chg ib3.educ_gp
outreg2 using "$results/heterogeneity_models_change.xls", stats(coef se pval) label ctitle(Educ1) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
regress percentile_chg ib3.educ_gp i.pre_percentile
outreg2 using "$results/heterogeneity_models_change.xls", stats(coef se pval) label ctitle(Educ2) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
regress percentile_chg ib3.educ_gp thearn_lag_ln
outreg2 using "$results/heterogeneity_models_change.xls", stats(coef se pval) label ctitle(Educ3) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

*Race
regress percentile_chg i.race_gp
outreg2 using "$results/heterogeneity_models_change.xls", stats(coef se pval) label ctitle(Race1) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
regress percentile_chg i.race_gp i.pre_percentile
outreg2 using "$results/heterogeneity_models_change.xls", stats(coef se pval) label ctitle(Race2) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
regress percentile_chg i.race_gp thearn_lag_ln
outreg2 using "$results/heterogeneity_models_change.xls", stats(coef se pval) label ctitle(Race3) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

*Pathway
regress percentile_chg ib3.pathway
outreg2 using "$results/heterogeneity_models_change.xls", stats(coef se pval) label ctitle(Path1) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
regress percentile_chg ib3.pathway i.pre_percentile
outreg2 using "$results/heterogeneity_models_change.xls", stats(coef se pval) label ctitle(Path2) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
regress percentile_chg ib3.pathway thearn_lag_ln
outreg2 using "$results/heterogeneity_models_change.xls", stats(coef se pval) label ctitle(Path3) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

*Race + Educ
regress percentile_chg i.race_gp ib3.educ_gp
outreg2 using "$results/heterogeneity_models_change.xls", stats(coef se pval) label ctitle(RE1) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
regress percentile_chg i.race_gp ib3.educ_gp i.pre_percentile
outreg2 using "$results/heterogeneity_models_change.xls", stats(coef se pval) label ctitle(RE2) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
regress percentile_chg i.race_gp ib3.educ_gp thearn_lag_ln
outreg2 using "$results/heterogeneity_models_change.xls", stats(coef se pval) label ctitle(RE3) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

*Race + Educ + Pathway
regress percentile_chg i.race_gp ib3.educ_gp ib3.pathway
outreg2 using "$results/heterogeneity_models_change.xls", stats(coef se pval) label ctitle(REP1) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
regress percentile_chg i.race_gp ib3.educ_gp ib3.pathway i.pre_percentile
outreg2 using "$results/heterogeneity_models_change.xls", stats(coef se pval) label ctitle(REP2) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
regress percentile_chg i.race_gp ib3.educ_gp ib3.pathway thearn_lag_ln
outreg2 using "$results/heterogeneity_models_change.xls", stats(coef se pval) label ctitle(REP3) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

*Interactions
regress percentile_chg i.race_gp ib3.educ_gp##ib3.pathway thearn_lag_ln
outreg2 using "$results/heterogeneity_models_change.xls", stats(coef se pval) label ctitle(Int1) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
margins educ_gp#pathway, nofvlabel

regress percentile_chg i.race_gp##ib3.pathway ib3.educ_gp thearn_lag_ln
outreg2 using "$results/heterogeneity_models_change.xls", stats(coef se pval) label ctitle(Int2) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
margins race_gp#pathway, nofvlabel

regress percentile_chg i.race_gp ib3.educ_gp ib3.pathway i.race_gp#ib3.pathway ib3.educ_gp#ib3.pathway thearn_lag_ln
outreg2 using "$results/heterogeneity_models_change.xls", stats(coef se pval) label ctitle(Int3) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
margins educ_gp#pathway, nofvlabel
margins race_gp#pathway, nofvlabel

regress percentile_chg i.race_gp ib3.educ_gp ib3.pathway i.race_gp#ib3.pathway ib3.educ_gp#ib3.pathway i.pre_percentile
outreg2 using "$results/heterogeneity_models_change.xls", stats(coef se pval) label ctitle(Int3) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
margins educ_gp#pathway, nofvlabel
margins race_gp#pathway, nofvlabel

// separately for moms employed at t0 v. not
regress percentile_chg ib3.educ_gp thearn_lag_ln
regress percentile_chg ib3.educ_gp thearn_lag_ln if start_from_0==1 // mom not employed at t0
regress percentile_chg ib3.educ_gp thearn_lag_ln if start_from_0==0 // mom employed at t0
regress percentile_chg ib3.educ_gp##i.start_from_0 thearn_lag_ln
margins educ_gp#start_from_0
margins start_from_0#educ_gp

// is this how to test for mediation? (see: https://stats.oarc.ucla.edu/stata/code/comparing-regression-coefficients-across-groups-using-suest/)
*Does education mediate race?
regress percentile_chg i.race_gp thearn_lag_ln
est store r1
regress percentile_chg i.race_gp ib3.educ_gp thearn_lag_ln
est store r2

suest r1 r2
test [r1_mean]2.race_gp=[r2_mean]2.race_gp
test [r1_mean]3.race_gp=[r2_mean]3.race_gp

*Does pathway mediate education?
regress percentile_chg ib3.educ_gp i.race_gp thearn_lag_ln
est store e1
regress percentile_chg ib3.educ_gp i.race_gp ib3.pathway thearn_lag_ln
est store e2

suest e1 e2
test [e1_mean]1.educ_gp=[e2_mean]1.educ_gp
test [e1_mean]2.educ_gp=[e2_mean]2.educ_gp

*Does pathway mediate race? I guess these are the same model as above since need all three in model
test [e1_mean]2.race_gp=[e2_mean]2.race_gp // not sig
test [e1_mean]3.race_gp=[e2_mean]3.race_gp // not sig

	*but also test this
	est replay r1
	regress percentile_chg i.race_gp ib3.pathway thearn_lag_ln
	est store r3
	
	suest r1 r3
	test [r1_mean]2.race_gp=[r3_mean]2.race_gp
	test [r1_mean]3.race_gp=[r3_mean]3.race_gp

* Some of the pathway coefficients changed? what does this mean? does this indicate potential moderation?
regress percentile_chg ib3.pathway thearn_lag_ln
est store p1
regress percentile_chg ib3.educ_gp i.race_gp ib3.pathway thearn_lag_ln
est store p2

suest p1 p2
test [p1_mean]1.pathway=[p2_mean]1.pathway // sig diff
test [p1_mean]2.pathway=[p2_mean]2.pathway // sig diff
test [p1_mean]4.pathway=[p2_mean]4.pathway // not
test [p1_mean]5.pathway=[p2_mean]5.pathway // not
test [p1_mean]6.pathway=[p2_mean]6.pathway // sig at 0.06
	
********************************************************************************
**# Model exploration 
* Trying fixed effects models here instead of multilevel models
********************************************************************************
// https://www.jstor.org/stable/pdf/271083.pdf: Change score method and the regressor variable method. In the change score method, Y2 - Y, is regressed on X. In the regressor variable method, Y2 is regressed on both Y, and X.   First, the  regression of Y2 - Y, on both Y, and X is equivalent to the regressor variable method. So yes, I prove this out below. But confused if, at this point, I am predicting CHANGE or am I predicting time 2 incole decile controlling for time 1, then I somehow need to work out what change would  be??

gen id_use = _n	

browse pre_percentile post_percentile percentile_chg thearn_lag thearn_adj  hh_income_raw
tabstat pre_percentile, by(educ_gp)
tabstat post_percentile, by(educ_gp)
tabstat percentile_chg, by(educ_gp)

regress percentile_chg i.educ_gp
regress percentile_chg ib3.educ_gp // this exactly matches multi-level models and the above tabstat. This is change score method per Allison
margins educ_gp
regress percentile_chg ib3.educ_gp thearn_lag // this is wildly different
margins educ_gp
regress percentile_chg ib3.educ_gp pre_percentile // this is also wildly different
margins educ_gp

regress post_percentile ib3.educ_gp pre_percentile // see Allison 1990 - okay so THIS matches regress percentile_chg ib3.educ_gp pre_percentile. These are regressor variable methods

// alt income
regress percentile_chg ib3.educ_gp
margins educ_gp
regress percentile_chg ib3.educ_gp thearn_lag
margins educ_gp
regress percentile_chg ib3.educ_gp thearn_lag_ln
margins educ_gp
margins educ_gp, atmeans
margins educ_gp, at(thearn_lag_ln=(-4(4)12))
regress percentile_chg ib3.educ_gp thearn_lag_1000s
margins educ_gp
regress percentile_chg ib3.educ_gp thearn_lag_topcode
margins educ_gp

regress percentile_chg ib3.educ_gp##c.thearn_lag_ln //r-squared does not improve - is this what she is asking for? Is this fixed effects? idk anymore.
margins educ_gp // this is exactly the same - just the coefficients much harder to interpret
margins educ_gp, at(thearn_lag_ln=(6(1)12))
margins educ_gp, at(thearn_lag_ln=(6(2)20))
tabstat thearn_lag_ln, by(educ_gp)
regress percentile_chg ib3.educ_gp##c.thearn_lag_ln, nocons

sum thearn_lag, detail
sum thearn_lag if educ_gp==1, detail
sum thearn_lag if educ_gp==3, detail

// regress percentile_chg i.educ_gp i.id_use
// areg percentile_chg ib3.educ_gp, absorb(id_use) //
// regress percentile_chg ib3.educ_gp thearn_lag i.id // wait do I need to control for ID to make these fixed effects?!?! im so confused. okay no (prob not bc wide not long)

regress percentile_chg ib3.educ_gp thearn_lag ib3.pathway // NOW is there mediation?

tabstat pre_percentile, by(race_gp)
tabstat post_percentile, by(race_gp)
tabstat percentile_chg, by(race_gp)

regress percentile_chg i.race_gp
margins race_gp
regress percentile_chg i.race_gp thearn_lag // this is wildly different
margins race_gp
regress percentile_chg i.race_gp pre_percentile
margins race_gp

// alt income
regress percentile_chg i.race_gp
margins race_gp
regress percentile_chg i.race_gp thearn_lag
margins race_gp
regress percentile_chg i.race_gp thearn_lag_ln
margins race_gp

********************************************************************************
* Okay multilevel with percentile - I am very confused
********************************************************************************
// https://www3.nd.edu/~rwilliam/stats3/Multilevel.pdf
regress percentile_chg
mean percentile_chg
mixed percentile_chg 

regress percentile_chg ib3.educ_gp 
mixed percentile_chg ib3.educ_gp
mixed percentile_chg || educ_gp:
mixed percentile_chg ib3.educ_gp || educ_gp:
mixed percentile_chg ib3.educ_gp || pre_percentile: // these are similar but I am still not getting coefficients for each of the deciles
regress percentile_chg ib3.educ_gp pre_percentile
regress percentile_chg ib3.educ_gp i.pre_percentile
est store reg

tab pre_percentile, gen(pre)
mixed percentile_chg ib3.educ_gp || pre_percentile: pre1 pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10 // is this what i want?
mixed percentile_chg ib3.educ_gp || pre_percentile: pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10 // do I need to omit a category, duh kim - yes
mixed percentile_chg ib3.educ_gp || pre_percentile: pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10
est store mlm

lrtest reg mlm, force

// i have to do the math? https://www.princeton.edu/~otorres/Multilevel101.pdf
// https://errickson.net/stata2/mixed-models.html
// https://stats.oarc.ucla.edu/stata/faq/how-can-i-fit-a-random-intercept-or-mixed-effects-model-with-heteroskedastic-errors-in-stata/
mixed percentile_chg ib3.educ_gp || pre_percentile: pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10
mixed percentile_chg ib3.educ_gp || pre_percentile: pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10, nocons
est store mlm1

est table mlm // lol what are these?

nlcom   (decile1: exp(2 * [lnsig_e]_cons)) ///
        (decile2: exp(2 * [lnsig_e]_cons) + exp(2 * [lns1_1_1]_cons)) ///
        (decile3: exp(2 * [lnsig_e]_cons) + exp(2 * [lns1_1_2]_cons)) ///
        (decile4: exp(2 * [lnsig_e]_cons) + exp(2 * [lns1_1_3]_cons)) ///
        (decile5: exp(2 * [lnsig_e]_cons) + exp(2 * [lns1_1_4]_cons)) ///
		(decile6: exp(2 * [lnsig_e]_cons) + exp(2 * [lns1_1_5]_cons)) ///
        (decile7: exp(2 * [lnsig_e]_cons) + exp(2 * [lns1_1_6]_cons)) ///
        (decile8: exp(2 * [lnsig_e]_cons) + exp(2 * [lns1_1_7]_cons)) ///
        (decile9: exp(2 * [lnsig_e]_cons) + exp(2 * [lns1_1_8]_cons)) ///
	    (decile10: exp(2 * [lnsig_e]_cons) + exp(2 * [lns1_1_9]_cons))


// https://www.princeton.edu/~otorres/Multilevel101.pdf
mixed percentile_chg ib3.educ_gp || pre_percentile: // pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10
predict u*, reffects
predict r_int, reffects
bysort pre_percentile: generate groups=(_n==1) 
list pre_percentile u1 if pre_percentile<=10 & groups
predict yhat_fit, fitted
list pre_percentile yhat_fit if pre_percentile<=10 & groups // okay for this, the yhat changes based on education - so there are three different yhats, one each for college, some college, lths

browse pre_percentile educ_gp yhat_fit

gen intercept = _b[_cons] + u1
// gen slope = _b[x1] + u1
list pre_percentile u1 intercept if pre_percentile<=10 & groups

/*
     +----------------------------------+
     | pre_pe~e          u1   intercept |
     |----------------------------------|
  1. |        1     2.07828    2.627899 |
212. |        2      1.8007    2.350319 |
272. |        3    1.109131     1.65875 |
332. |        4    .6453322    1.194951 |
410. |        5   -.0555898    .4940293 |
     |----------------------------------|
504. |        6   -.4251452    .1244738 |
607. |        7   -.4316003    .1180188 |
713. |        8   -1.016974   -.4673554 |
817. |        9   -1.552805   -1.003186 |
905. |       10   -2.151328   -1.601709 |


     +----------------------+
     | pre_pe~e    yhat_fit |
     |----------------------|
  1. |        1    .8707072 |
212. |        2    2.350319 |
272. |        3    .2533723 |
332. |        4   -.2104262 |
410. |        5    .4940293 |
     |----------------------|
504. |        6   -1.632718 |
607. |        7   -1.287359 |
713. |        8   -.4673553 |
817. |        9   -2.408564 |
905. |       10   -1.601708 |


*/

// attempting to figure out what all these postestimation things do
mixed percentile_chg ib3.educ_gp || pre_percentile:

predict r_int, reffects
predict yhat
predict yhat_fit, fitted
gen intercept = _b[_cons] + r_int

browse pre_percentile r_int yhat yhat_fit intercept

mixed percentile_chg || pre_percentile:

predict r_int_base, reffects
predict yhat_base
predict yhat_base_fit, fitted
gen intercept_base = _b[_cons] + r_int_base

browse pre_percentile r_int_base yhat_base yhat_base_fit intercept_base

regress percentile_chg ib3.educ_gp i.pre_percentile
margins pre_percentile // is this also similar?

mixed percentile_chg ib3.educ_gp || pre_percentile: pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10
predict yhat_fit2, fitted
browse pre_percentile educ_gp yhat_fit yhat_fit2

regress percentile_chg ib3.educ_gp##i.pre_percentile // I feel like these things are essentially similar. okay yes
margins educ_gp#pre_percentile

mixed percentile_chg || pre_percentile: pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10
predict yhat_fit3, fitted
browse pre_percentile educ_gp yhat_fit yhat_fit2 yhat_fit3

mixed percentile_chg ib3.educ_gp || pre_percentile: educ_gp // pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10
predict u*, reffects
bysort pre_percentile: generate groups=(_n==1) 
list pre_percentile u2 u1 if pre_percentile<=10 & groups

gen intercept = _b[_cons] + u2
gen slope = _b[educ_gp] + u1 // wait this won't work bc categorical
list pre_percentile u2 u1 intercept slope if pre_percentile<=10 & groups

// is the real value seeing if the residual decreases between this and empty model?
mixed percentile_chg ib3.educ_gp 
mixed percentile_chg ib3.educ_gp || pre_percentile: pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10
		
/*
mixed percentile_chg ib3.educ_gp || pre_percentile: pre2 pre3 pre4 pre5 pre6 pre7 pre8 pre9 pre10, nocons

mixed percentile_chg ib3.educ_gp || pre_percentile:, mle var 
mixed percentile_chg ib3.educ_gp || pre_percentile: ib3.educ_gp, mle var 
// mixed percentile_chg ib3.educ_gp || i.pre_percentile:

mixed percentile_chg ib3.educ_gp || pre_percentile:, nocons // Note: all random-effects equations are empty; model is linear regression

regress percentile_chg i.pre_percentile
mixed percentile_chg i.pre_percentile || pre_percentile: // these are the same

mixed percentile_chg ib3.educ_gp i.pre_percentile || educ_gp: i.pre_percentile // is this what I want?
// i have to do the math? https://www.princeton.edu/~otorres/Multilevel101.pdf
// https://errickson.net/stata2/mixed-models.html
/*
Random effects: These are the "grouping" variables, and must be categorical (Stata will force every variable used to produce random effects as if it were prefaced by i.). These are essentially just predictors as well, however, we do not obtain coefficients to test or interpret. We do get a measure of the variability across groups, and a test of whether the random effect is benefiting the model
*/

tab pre_percentile, gen(pre)

xtset pre_percentile
xtreg percentile_chg ib3.educ_gp
xtreg percentile_chg ib3.educ_gp, fe
*/

********************************************************************************
* Exploring mediation / moderation (before going into MLM)
********************************************************************************
// regress hh_income_topcode ib2.rel_status_detail i.educ_gp i.race
//medeff (regress hh_income_topcode race) (regress hh_income_topcode race rel_status_detail) [if] [in] [weight], mediate(rel_status_detail) treat(varname [# #]) [sims(#) seed(#) vce(vcetype) level(#) interact(varname)]
// medeff (regress M T x) (regress Y T M x), mediate(M) treat(T) sims(1000) seed(1)

*M = partnered_all
*T = race
*are x other controls?

logit partnered_all i.educ_gp // sig diffs
logit in_pov i.educ_gp
logit in_pov i.partnered_all
logit in_pov i.partnered_all i.educ_gp

regress hh_income_topcode i.educ_gp
regress hh_income_topcode i.partnered_all
regress hh_income_topcode i.partnered_all i.educ_gp // educ becomes sig here (like it does in my MLMs with pathway)

medeff (logit partnered_all i.educ_gp) (logit in_pov i.partnered_all i.educ_gp), mediate(i.partnered_all) treat(i.educ_gp)

sgmediation hh_income_topcode, mv(partnered_all) iv(educ_gp)
sgmediation hh_income_topcode, mv(i.partnered_all) iv(i.educ_gp) // okay can't have factor variables, so just treats as continuous is the only way it works

oaxaca hh_income_topcode i.partnered_all, by(educ_gp) noisily // I think I have to do this by hand
oaxaca hh_income_topcode i.partnered_all, by(partnered_all) omega noisily
oaxaca hh_income_topcode i.partnered_all, by(partnered_all) pooled noisily
oaxaca hh_income_topcode i.partnered_all, by(partnered_all) weight(0.5) noisily

* omega takes the coefficient on education from a pooled regression without an indicator for rural, the group var
* pooled takes the coefficient on education from a pooled regression with an indicator for rural, the group var
* weight(0.5) makes a coefficient on education as a 50-50 combination of the coefficients from separate rural and urban regression

tab educ_gp pathway, row
mlogit pathway i.educ_gp, base(3) // this is no different to a chi-squared, though, right? without controls?

regress percentile_chg i.educ_gp // this is the same rate of change from multilevel models - just doesn't provide starting point - Model 1 (MLM)
regress percentile_chg i.educ_gp ib3.pathway // this is the same rate of change from multilevel models - just doesn't provide starting point - Model 4 (MLM)

tabstat percentile_chg, by(educ_gp) // raw effects
oneway percentile_chg educ_gp // anova
anova percentile_chg educ_gp
margins educ_gp
anova percentile_chg pathway
anova percentile_chg educ_gp pathway
anova percentile_chg educ_gp pathway educ_gp#pathway // honestly not quite sure what's happening here
margins educ_gp // wait okay this is the same as if I standardized to pathway (Table 3A)
margins educ_gp, asbalanced // wait confused, is this meant to match Model 4 - just controlling for pathway? because it doesn't. I am so confused

/*These adjusted marginal predictions are not equal to the simple drug means (see the totals from the
table command); they are based upon predictions from our ANOVA model. The asbalanced option
of margins corresponds with the interpretation of the F statistic produced by ANOVA—each cell is
given equal weight regardless of its sample size (see the following three technical notes). You can
omit the asbalanced option and obtain predictive margins that take into account the unequal sample
sizes of the cells.
*/

margins pathway // not sure what this is..

anova percentile_chg race_gp
margins race_gp // measured
anova percentile_chg race_gp pathway race_gp#pathway // honestly not quite sure what's happening here
margins race_gp // wait okay this is the same as if I standardized to pathway (Table 3A)
margins race_gp, asbalanced // wait confused, is this meant to match Model 4 - just controlling for pathway? because it doesn't


table educ_gp pathway, statistic(mean percentile_chg) nformat(%8.2f) // essentially the interaction? so this is more moderation?

regress percentile_chg ib3.pathway##i.educ_gp
margins pathway#educ_gp
marginsplot, recast(bar)
marginsplot

***R-squared - since can't get in MLM
regress percentile_chg i.race_gp // (M2) - .22%
estimates store m1

regress percentile_chg ib3.pathway // (M3) - 34.67%
regress percentile_chg i.race_gp ib3.pathway // (M5) - 35.00%
estimates store m2

regress percentile_chg ib3.pathway##i.race_gp // (M7) - 36.01%

suest m1 m2
test [m1_mean]2.race_gp=[m2_mean]2.race_gp
lincom [m1_mean]2.race_gp - [m2_mean]2.race_gp // =0.05

regress percentile_chg i.educ_gp // (M1) - .58%
estimates store m3
regress percentile_chg ib3.pathway // (M3) - 34.67%
regress percentile_chg i.educ_gp ib3.pathway // (M4) - 35.34%
estimates store m4
regress percentile_chg ib3.pathway##i.educ_gp // (M6) - 37.54%

suest m3 m4
test [m3_mean]2.educ_gp=[m4_mean]2.educ_gp
lincom [m3_mean]2.educ_gp - [m4_mean]2.educ_gp // not sig - some college

test [m3_mean]3.educ_gp=[m4_mean]3.educ_gp
lincom [m3_mean]3.educ_gp - [m4_mean]3.educ_gp // not sig - college


********************************************************************************
**# Bookmark #3
* Create dataset to save for MLM
********************************************************************************
//1=lag, 2=year
rename bw60 bw60_2
rename bw60lag bw60_1
rename earnings_adj earnings_2
rename earnings_lag earnings_1
rename thearn_adj thearn_2
rename thearn_lag thearn_1
rename earnings_ratio earnings_ratio_2
rename earnings_ratio_lag earnings_ratio_1
rename inc_pov inc_pov_2
rename inc_pov_lag inc_pov_1
rename in_pov in_pov_2
rename pov_lag in_pov_1
rename post_percentile percentile_2
gen percentile_1 = pre_percentile
// rename pre_percentile percentile_1
rename marital_status_t marital_status_2
rename marital_status_t1 marital_status_1
rename partnered_t partnered_2
rename partnered_t1 partnered_1

keep SSUID PNUM year pre_percentile bw60_2 bw60_1 earnings_2 earnings_1 thearn_2 thearn_1 earnings_ratio_2 earnings_ratio_1 inc_pov_2 inc_pov_1 in_pov_2 in_pov_1 percentile_2 percentile_1 marital_status_2 marital_status_1 partnered_2 partnered_1 ///
 trans_bw60_alt2 wpfinwgt  scaled_weight race educ race_gp educ_gp pathway_v1 pathway tage ageb1 status_b1 yrfirstbirth ageb1_gp rel_status_detail earn_change earn_change_raw inc_pov_change inc_pov_change_raw pov_change_detail hh_income_chg hh_income_raw percentile_chg income_change hh_income_topcode  income_chg_top hh_income_chg_x    // mom_earn_change income_chg_top_x
 
gen id = _n

reshape long bw60_ earnings_ thearn_ earnings_ratio_ inc_pov_ in_pov_ percentile_ marital_status_ partnered_, ///
i(id) j(time)

save "$tempdir/bw_consequences_long.dta", replace


********************************************************************************
**# To get descriptives for comparison to all eligible mothers
********************************************************************************
use "$tempdir/combined_bw_equation.dta", clear // created in step ab
drop if survey_yr==1

tab trans_bw60_alt2 if bw60lag==0 // the 1s here are my 981
// the comparison, then, are bw60lag == 0 BUT trans_bw60_alt2==0

unique id if bw60lag==0, by(trans_bw60_alt2)

tab educ_gp if trans_bw60_alt2==1 & bw60lag==0
tab educ_gp if trans_bw60_alt2==0 & bw60lag==0

tab trans_bw60_alt2 educ_gp if bw60lag==0, row
tab trans_bw60_alt2 educ_gp if bw60lag==0, chi2
tab educ_gp, gen(educ)
ttest educ1 if bw60lag==0, by(trans_bw60_alt2)
ttest educ2 if bw60lag==0, by(trans_bw60_alt2)
ttest educ3 if bw60lag==0, by(trans_bw60_alt2)

recode race (1=1)(2=2)(4=3)(3=4)(5=4), gen(race_gp)
label define race_gp 1 "White" 2 "Black" 3 "Hispanic" 4 "Other"
label values race_gp race_gp

tab race_gp if trans_bw60_alt2==1 & bw60lag==0
tab race_gp if trans_bw60_alt2==0 & bw60lag==0

tab trans_bw60_alt2 race_gp if bw60lag==0, chi2
tab race_gp, gen(race)
ttest race1 if bw60lag==0, by(trans_bw60_alt2) // White
ttest race2 if bw60lag==0, by(trans_bw60_alt2) // Black
ttest race3 if bw60lag==0, by(trans_bw60_alt2) // Hispanic
ttest race4 if bw60lag==0, by(trans_bw60_alt2) // Other

recode last_marital_status (1=1) (2=2) (3/5=3), gen(marital_status_t1)
label define marr 1 "Married" 2 "Cohabiting" 3 "Single"
label values marital_status_t1 marr

tab marital_status_t1 if trans_bw60_alt2==1 & bw60lag==0
tab marital_status_t1 if trans_bw60_alt2==0 & bw60lag==0

tab trans_bw60_alt2 marital_status_t1 if bw60lag==0, chi2
tab marital_status_t1, gen(marital)
ttest marital1 if bw60lag==0, by(trans_bw60_alt2) // Married
ttest marital2 if bw60lag==0, by(trans_bw60_alt2) // Cohab
ttest marital3 if bw60lag==0, by(trans_bw60_alt2) // Single

// create pathway
sort SSUID PNUM year
gen earnings_lag = earnings[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen thearn_lag = thearn_adj[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)

gen start_from_0 = 0
replace start_from_0=1 if earnings_lag==0

gen pathway=0
replace pathway=1 if mt_mom==1 & start_from_0==1
replace pathway=2 if mt_mom==1 & start_from_0==0
replace pathway=3 if ft_partner_down_mom==1
replace pathway=4 if ft_partner_down_only==1
replace pathway=5 if ft_partner_leave==1
replace pathway=6 if lt_other_changes==1

label define pathway 0 "None" 1 "Mom Up, Not employed" 2 "Mom Up, employed" 3 "Mom Up Partner Down" 4 "Partner Down" 5 "Partner Left" 6 "Other HH Change"
label values pathway pathway

tab pathway if trans_bw60_alt2==1 & bw60lag==0
tab pathway if trans_bw60_alt2==0 & bw60lag==0

tab trans_bw60_alt2 pathway if bw60lag==0, chi2 // path 1 = None, for those who didn't transition
// or
tab pathway, gen(path)

ttest path2 if bw60lag==0, by(trans_bw60_alt2) // mom up unemployed
ttest path3 if bw60lag==0, by(trans_bw60_alt2)
ttest path4 if bw60lag==0, by(trans_bw60_alt2)
ttest path5 if bw60lag==0, by(trans_bw60_alt2)
ttest path6 if bw60lag==0, by(trans_bw60_alt2)
ttest path7 if bw60lag==0, by(trans_bw60_alt2) // other HH change


// 
tab start_from_0 if trans_bw60_alt2==1 & bw60lag==0
tab start_from_0 if trans_bw60_alt2==0 & bw60lag==0

gen employed_t0=0
replace employed_t0=1 if start_from_0==0

tab trans_bw60_alt2 employed_t0 if bw60lag==0, row
ttest employed_t0 if bw60lag==0, by(trans_bw60_alt2) 

sum earnings_lag if trans_bw60_alt2==1 & bw60lag==0 & earnings_lag!=0, detail
sum earnings_lag if trans_bw60_alt2==0 & bw60lag==0 & earnings_lag!=0, detail
ttest earnings_lag if bw60lag==0 & earnings_lag!=0, by(trans_bw60_alt2) 

sum thearn_lag if trans_bw60_alt2==1 & bw60lag==0 & thearn_lag!=0, detail
sum thearn_lag if trans_bw60_alt2==0 & bw60lag==0 & thearn_lag!=0, detail
sum thearn_lag if trans_bw60_alt2==1 & bw60lag==0
sum thearn_lag if trans_bw60_alt2==0 & bw60lag==0

ttest thearn_lag if bw60lag==0, by(trans_bw60_alt2) 

// adding info on HH composition (created file 10 in 2014 folder) 
merge 1:1 SSUID PNUM year using "$tempdir/household_lookup.dta"
drop if _merge==2
drop _merge

tab extended_hh if trans_bw60_alt2==1 & bw60lag==0
tab extended_hh if trans_bw60_alt2==0 & bw60lag==0
ttest extended_hh if bw60lag==0, by(trans_bw60_alt2) 

sum avg_hhsize if trans_bw60_alt2==1 & bw60lag==0
sum avg_hhsize if trans_bw60_alt2==0 & bw60lag==0
ttest avg_hhsize if bw60lag==0, by(trans_bw60_alt2) 

ttest st_minorchildren if bw60lag==0, by(trans_bw60_alt2) 
ttest end_minorchildren if bw60lag==0, by(trans_bw60_alt2) 

// get income decile distribution
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

gen pre_percentile=. // okay duh a lot of missing because thearn_lag not there for everyone - should they be 1? no, okay, duh it's people who we do not have the prior year for because not yet in panel (like 2012, say)
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

tab trans_bw60_alt2 pre_percentile if bw60lag==0, row chi2
tab pre_percentile trans_bw60_alt2 if bw60lag==0, col

tab pre_percentile, gen(percentile)
ttest percentile1 if bw60lag==0, by(trans_bw60_alt2) 
ttest percentile2 if bw60lag==0, by(trans_bw60_alt2) 
ttest percentile3 if bw60lag==0, by(trans_bw60_alt2) 
ttest percentile4 if bw60lag==0, by(trans_bw60_alt2) 
ttest percentile5 if bw60lag==0, by(trans_bw60_alt2) 
ttest percentile6 if bw60lag==0, by(trans_bw60_alt2) 
ttest percentile7 if bw60lag==0, by(trans_bw60_alt2) 
ttest percentile8 if bw60lag==0, by(trans_bw60_alt2) 
ttest percentile9 if bw60lag==0, by(trans_bw60_alt2) 
ttest percentile10 if bw60lag==0, by(trans_bw60_alt2) 

/*
browse SSUID PNUM educ_gp pathway mechanism inc_pov

preserve

collapse (p50) inc_pov, by(educ_gp pathway)
export excel using "$results\class_pathway_poverty.xls", firstrow(variables) replace

restore
preserve

collapse (p50) inc_pov, by(race pathway)
export excel using "$results\race_pathway_poverty.xls", firstrow(variables) replace

restore

// not topcoded output
regress hh_income_chg_x i.educ_gp
estimates store m1 
outreg2 using "$results/regression_percent_change.xls", sideway stats(coef) label ctitle(M1) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace

regress hh_income_chg_x i.race_gp
estimates store m2
outreg2 using "$results/regression_percent_change.xls", sideway stats(coef) label ctitle(M2) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

regress hh_income_chg_x ib3.pathway
estimates store m3
outreg2 using "$results/regression_percent_change.xls", sideway stats(coef) label ctitle(M3) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

regress hh_income_chg_x ib3.pathway i.race_gp
estimates store m4
outreg2 using "$results/regression_percent_change.xls", sideway stats(coef) label ctitle(M4) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

regress hh_income_chg_x ib3.pathway i.educ_gp
estimates store m5
outreg2 using "$results/regression_percent_change.xls", sideway stats(coef) label ctitle(M5) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

regress hh_income_chg_x ib3.pathway i.race_gp i.educ_gp 
estimates store m6
outreg2 using "$results/regression_percent_change.xls", sideway stats(coef) label ctitle(M6) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

regress hh_income_chg_x ib3.pathway i.race_gp i.educ_gp i.pov_lag
estimates store m7 
outreg2 using "$results/regression_percent_change.xls", sideway stats(coef) label ctitle(M7) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

regress hh_income_chg_x ib3.pathway##i.race i.educ_gp i.pov_lag
regress hh_income_chg_x ib3.pathway##i.race i.educ_gp i.pov_lag if inlist(race,1,2,4) // r-squared is sig reduced if I don't include asian or other...
regress hh_income_chg_x ib3.pathway##i.race_gp i.educ_gp i.pov_lag // r-squared is sig reduced if I don't split asian or other...
estimates store m8
outreg2 using "$results/regression_percent_change.xls", sideway stats(coef) label ctitle(M8) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

regress hh_income_chg_x ib3.pathway##i.educ_gp i.race_gp i.pov_lag
estimates store m9
outreg2 using "$results/regression_percent_change.xls", sideway stats(coef) label ctitle(M9) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
*/