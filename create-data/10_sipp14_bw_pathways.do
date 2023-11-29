*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* bw_pathways.do
* Kim McErlean
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* This file cleans up the 2014 data and adds our BW pathways

* Files used were created in sipp14_bw_descriptives

********************************************************************************
* First do some final clean up on 2014 files
********************************************************************************
use "$SIPP14keep/bw_descriptives.dta", clear

rename avg_hrs 		avg_mo_hrs
rename hours_sp		avg_mo_hrs_sp
rename tage_fb 		ageb1_mon

gen survey=2014

// Missing value check - key IVs (DV handled elsewhere / meant to have missing because not always eligible, etc.)
tab race, m
tab educ, m // .02%
drop if educ==.
tab last_marital_status, m // .02%
drop if last_marital_status==.

// adding in lookups for poverty thresholds
browse year SSUID end_hhsize end_minorchildren

merge m:1 year end_hhsize end_minorchildren using "$projcode/poverty_thresholds.dta"

browse year SSUID end_hhsize end_minorchildren threshold

drop if _merge==2
drop _merge

********************************************************************************
* Add variables for pathways, following Pepin et al. 
********************************************************************************
sort SSUID PNUM year

browse SSUID PNUM year bw60 trans_bw60 earnup8_all momup_only earn_lose earndown8_hh_all

// ensure those who became mothers IN panel removed from sample in years they hadn't yet had a baby
browse SSUID PNUM year bw60 trans_bw60 firstbirth yrfirstbirth if mom_panel==1
browse SSUID PNUM year bw60 trans_bw60 firstbirth yrfirstbirth mom_panel
gen bw60_mom=bw60  // need to retain this for future calculations for women who became mom in panel
replace bw60=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60_alt=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60_alt2=. if year < yrfirstbirth & mom_panel==1

svyset [pweight = wpfinwgt]

recode partner_lose (2/6=1)

*Dt-l: mothers not breadwinning at t-1
gen bw60lag = 0 if bw60[_n-1]==0 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
replace bw60lag =1 if  bw60[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)

*Mt = The proportion of mothers who experienced an increase in earnings. This is equal to the number of mothers who experienced an increase in earnings divided by Dt-1. Mothers only included if no one else in the HH experienced a change.

gen mt_mom = 0
replace mt_mom = 1 if earnup8_all==1 & earn_lose==0 & earndown8_hh_all==0
replace mt_mom = 1 if earn_change > 0 & earn_lose==0 & earn_change_hh==0 & mt_mom==0 // to capture those outside the 8% threshold (v. small amount) - and ONLY if no other household changes happened

svy: tab mt_mom if bw60lag==0
tab mt_mom if bw60lag==0 [aweight = wpfinwgt] // validating this is the same as svy

*Bmt = the proportion of mothers who experience an increase in earnings that became breadwinners. This is equal to the number of mothers who experience an increase in earnings and became breadwinners divided by Mt.

svy: tab mt_mom trans_bw60_alt2 if bw60lag==0, row

*Ft = the proportion of mothers who had their partner lose earnings OR leave. If mothers earnings also went up, they are captured here, not above.
gen ft_partner_down = 0
replace ft_partner_down = 1 if earndown8_sp_all==1 & mt_mom==0 & partner_lose==0 // if partner left, want them there, not here
replace ft_partner_down = 1 if earn_change_sp <0 & earn_change_sp >-.08 & mt_mom==0 & ft_partner_down==0 & partner_lose==0

svy: tab ft_partner_down if bw60lag==0

	* splitting partner down into just partner down, or also mom up - we are going to use these more detailed categories
	gen ft_partner_down_only=0
	replace ft_partner_down_only = 1 if earndown8_sp_all==1 & earnup8_all==0 & mt_mom==0 & partner_lose==0 & ft_partner_down==1
	replace ft_partner_down_only = 1 if earn_change_sp <0 & earn_change_sp >-.08 & earnup8_all==0 & mt_mom==0 & ft_partner_down==1 & partner_lose==0 // so if only changed 8% (mom), still considered partner down only
	
	gen ft_partner_down_mom=0
	replace ft_partner_down_mom = 1 if earndown8_sp_all==1 & earnup8_all==1 & mt_mom==0 & partner_lose==0 & ft_partner_down==1
	replace ft_partner_down_mom = 1 if earn_change_sp <0 & earn_change_sp >-.08 & earnup8_all==1 & mt_mom==0 & ft_partner_down==1 & partner_lose==0
	
	svy: tab ft_partner_down_only if bw60lag==0
	svy: tab ft_partner_down_mom if bw60lag==0
	
	
gen ft_partner_leave = 0
replace ft_partner_leave = 1 if partner_lose==1 & mt_mom==0

svy: tab ft_partner_leave if bw60lag==0

gen ft_overlap=0
replace ft_overlap = 1 if earn_lose==0 & earnup8_all==1 & earndown8_sp_all==1

*Bft = the proportion of mothers who had another household member lose earnings that became breadwinners
svy: tab ft_partner_down trans_bw60_alt2 if bw60lag==0, row 

svy: tab ft_partner_leave trans_bw60_alt2 if bw60lag==0, row 

svy: tab ft_partner_down_only trans_bw60_alt2 if bw60lag==0, row 

svy: tab ft_partner_down_mom trans_bw60_alt2 if bw60lag==0, row 

*Lt = the proportion of mothers who either stopped living with someone (besides their partner) who was an earner OR someone else in the household's earnings went down (again besides her partner). Partner is main category, so if a partner experienced changes as well as someone else in HH, they are captured above.
gen lt_other_changes = 0
replace lt_other_changes = 1 if (earn_lose==1 | earndown8_oth_all==1) & (mt_mom==0 & ft_partner_down==0 & ft_partner_leave==0)
	
svy: tab lt_other_changes if bw60lag==0

*BLt = the proportion of mothers who stopped living with someone who was an earner that became a Breadwinner
svy: tab lt_other_changes trans_bw60_alt2 if survey==2014 & bw60lag==0, row


*validate
svy: tab trans_bw60_alt2 if bw60lag==0
tab trans_bw60_alt2 if bw60lag==0 // unweighted
tab trans_bw60_alt2 if bw60lag==0 [aweight = wpfinwgt]  // validating this is same as svy

// figuring out how to add in mothers who had their first birth in a panel
browse SSUID PNUM year firstbirth bw60 trans_bw60

svy: tab firstbirth
svy: tab firstbirth if bw60_mom==1 & bw60_mom[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) in 2/-1
tab firstbirth if bw60_mom==1 & bw60_mom[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) in 2/-1 [aweight = wpfinwgt]
unique SSUID if firstbirth==1, by(bw60_mom)

// Counts
foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	tab `var' trans_bw60_alt2 if bw60lag==0 [aweight = wpfinwgt], row
}

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	tab `var' trans_bw60_alt2 if bw60lag==0, row
}

egen id = concat (SSUID PNUM)
destring id, replace

save "$SIPP14keep/annual_bw_status2014.dta", replace