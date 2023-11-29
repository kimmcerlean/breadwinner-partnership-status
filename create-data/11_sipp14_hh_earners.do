*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* hh_earners.do
* Kim McErlean
*-------------------------------------------------------------------------------
di "$S_DATE"
version 16
********************************************************************************
* DESCRIPTION
********************************************************************************
* Create basic descriptive statistics of other earners in the HH

* The data file used in this script was produced by bw_descriptives.do (file 9)

********************************************************************************
* Import data
********************************************************************************
use "$SIPP14keep/bw_descriptives.dta", clear

********************************************************************************
* Calculating who is primary earner in each HH
********************************************************************************
egen hh_earn_max = rowmax (to_earnings1-to_earnings22)
// browse SSUID PNUM year hh_earn_max earnings to_earnings* 

gen who_max_earn=.
forvalues n=1/22{
replace who_max_earn=relationship`n' if to_earnings`n'==hh_earn_max
}

// browse SSUID PNUM year who_max_earn hh_earn_max earnings to_earnings* relationship*

gen total_max_earner=.
replace total_max_earner=who_max_earn if (earnings==. & hh_earn_max>0 & hh_earn_max!=.) | (hh_earn_max >= earnings & earnings!=. & hh_earn_max!=. & (earnings+hh_earn_max>0))
replace total_max_earner=99 if (earnings>0 & earnings!=. & hh_earn_max==.) | (hh_earn_max < earnings & earnings!=. & hh_earn_max!=.)

gen total_max_earner2=total_max_earner
replace total_max_earner2=100 if total_max_earner==99 & (hh_earn_max==0 | hh_earn_max==.) // splitting out the "self" view to delineate between hh where mother is primary earner because she is the only earner

sort SSUID PNUM year
browse SSUID PNUM year who_max_earn hh_earn_max earnings total_max_earner total_max_earner2 to_earnings* 
replace total_max_earner2=0 if total_max_earner2==.


#delimit ;
label define rel2 1 "Spouse"
                  2 "Unmarried partner"
                  3 "Biological parent"
                  4 "Biological child"
                  5 "Step parent"
                  6 "Step child"
                  7 "Adoptive parent"
                  8 "Adoptive child"
                  9 "Grandparent"
                 10 "Grandchild"
                 11 "Biological siblings"
                 12 "Half siblings"
                 13 "Step siblings"
                 14 "Adopted siblings"
                 15 "Other siblings"
                 16 "In-law"
                 17 "Aunt, Uncle, Niece, Nephew"
                 18 "Other relationship"   
                 19 "Foster parent/Child"
                 20 "Other non-relative"
				 0 "no earners"
                 99 "self" 
				 100 "self - no other earners" ;

#delimit cr

label values who_max_earn total_max_earner* rel2

// put in excel

tabout total_max_earner2 using "$results/Breadwinner_Distro.xls", c(freq col) clab(N Percent) f(0c 1p) replace

forvalues e=1/4{
	tabout total_max_earner2 using "$results/Breadwinner_Distro.xls" if educ==`e', c(freq col) clab(Educ=`e' Percent) f(0c 1p) append 
}


label define marital_status 1 "Married" 2 "Cohabiting" 3 "Widowed" 4 "Dissolved-Unpartnered" 5 "Never Married- Not partnered"
label values st_marital_status end_marital_status marital_status

tab total_max_earner2 if inlist(end_marital_status,3,4,5)

// creating an indicator of whether or not mom lives in extended household, then making a lookup table to match later
gen extended_hh=0

forvalues n=1/22{
replace extended_hh=1 if inlist(relationship`n',3,5,7,9,10,11,12,13,14,15,16,17,18,19,20) // anyone who is not spouse, partner, or child (1,2,4,6,8)
}

preserve
keep SSUID PNUM year total_max_earner2 extended_hh
save "$tempdir/household_lookup.dta", replace
restore

// for impact paper to get earner prior to transition (steps I did in ab)
* Missing value check
tab race, m
tab educ, m // .02%
drop if educ==.
tab last_marital_status, m // .02%
drop if last_marital_status==.

* ensure those who became mothers IN panel removed from sample in years they hadn't yet had a baby
gen bw60_mom=bw60  // need to retain this for future calculations for women who became mom in panel
replace bw60=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60_alt=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60_alt2=. if year < yrfirstbirth & mom_panel==1

sort SSUID PNUM year
gen bw60lag = 0 if bw60[_n-1]==0 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
replace bw60lag =1 if  bw60[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)

tab trans_bw60_alt2 if bw60lag==0

tab total_max_earner2 if trans_bw60_alt2==1 & bw60lag==0 // should be all mom? - OKAY IT IS weeeee. so need to get LAGGED max earner?

gen max_earner_lag = total_max_earner2[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
label values max_earner_lag rel2
browse SSUID PNUM year trans_bw60_alt2  total_max_earner total_max_earner2 max_earner_lag to_earnings* 

tab max_earner_lag if trans_bw60_alt2==1 & bw60lag==0 // so she could be MAX earner, but at like 51% not 60%. or she could be  30, someone else 20, someone else 20, etc. etc.

gen partnered=0
replace partnered=1 if inlist(last_marital_status,1,2)

gen partnered_st=0
replace partnered_st=1 if inlist(start_marital_status,1,2)

gen single_all=0
replace single_all=1 if partnered==0 & no_status_chg==1

gen partnered_all=0
replace partnered_all=1 if partnered_st==1 | single_all==0

gen partnered_no_chg=0
replace partnered_no_chg=1 if partnered_st==1 & no_status_chg==1

* gah
gen rel_status=.
replace rel_status=1 if single_all==1
replace rel_status=2 if partnered_all==1
label define rel 1 "Single" 2 "Partnered"
label values rel_status rel

gen rel_status_detail=.
replace rel_status_detail=1 if single_all==1
replace rel_status_detail=2 if partnered_no_chg==1
replace rel_status_detail=3 if partner_lose==1
replace rel_status_detail=2 if partnered_all==1 & rel_status_detail==.

label define rel_detail 1 "Single" 2 "Partnered" 3 "Dissolved"
label values rel_status_detail rel_detail

tab max_earner_lag if trans_bw60_alt2==1 & bw60lag==0 & partnered==0 // single
tab max_earner_lag if trans_bw60_alt2==1 & bw60lag==0 & partnered_st==0
tab max_earner_lag if trans_bw60_alt2==1 & bw60lag==0 & partnered==0 & no_status_chg==1 // single ALL YEAR, probably cleanest?

tab max_earner_lag if trans_bw60_alt2==1 & bw60lag==0 & partnered==1 // partnered -- need to make this partnered at SOME POINT? maybe get single all year and subtract?
tab max_earner_lag if trans_bw60_alt2==1 & bw60lag==0 & (partnered==1 | single_all==0) // partnered -- need to make this partnered at SOME POINT? maybe get single all year and subtract?

tab max_earner_lag if trans_bw60_alt2==1 & bw60lag==0 
tab max_earner_lag if trans_bw60_alt2==1 & bw60lag==0 & rel_status_detail==1 // single
tab max_earner_lag if trans_bw60_alt2==1 & bw60lag==0 & rel_status_detail==2 // partnered 
tab max_earner_lag if trans_bw60_alt2==1 & bw60lag==0 & rel_status_detail==3 // relationship dissolved

* get percentage of mom's earnings in year prior?  browse SSUID PNUM year thearn_alt earnings earnings_ratio to_earnings* should I do average HH, average mothers OR get the percentage by household, then average? I already have - earnings_ratio
tabstat thearn_alt, stats(mean p50)
tabstat earnings, stats(mean p50)
replace earnings_ratio=0 if earnings_ratio==. & earnings==0 & thearn_alt > 0 // wasn't counting moms with 0 earnings -- is this an issue elsewhere?? BUT still leaving as missing if NO earnings. is that right?
gen earnings_ratio_alt=earnings_ratio
replace earnings_ratio_alt=0 if earnings_ratio_alt==. // count as 0 if no earnings (instead of missing)

gen earnings_ratio_lag = earnings_ratio[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
tabstat earnings_ratio_lag if trans_bw60_alt2==1 & bw60lag==0, stats(mean p50)
tabstat earnings_ratio_lag if trans_bw60_alt2==1 & bw60lag==0 & partnered==0 & no_status_chg==1, stats(mean p50)
tabstat earnings_ratio_lag if trans_bw60_alt2==1 & bw60lag==0 & (partnered==1 | single_all==0), stats(mean p50)

gen earnings_ratio_alt_lag = earnings_ratio_alt[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
tabstat earnings_ratio_alt_lag if trans_bw60_alt2==1 & bw60lag==0, stats(mean p50)
tabstat earnings_ratio_alt_lag if trans_bw60_alt2==1 & bw60lag==0 & partnered==0 & no_status_chg==1, stats(mean p50)
tabstat earnings_ratio_alt_lag if trans_bw60_alt2==1 & bw60lag==0 & (partnered==1 | single_all==0), stats(mean p50)
