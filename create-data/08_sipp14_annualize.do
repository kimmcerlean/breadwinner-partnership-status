*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* annualize.do
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
di "$S_DATE"


********************************************************************************
* DESCRIPTION
********************************************************************************
* Create annual measures of breadwinning.

* The data file used in this script was produced by merging_hh_characteristics.do
* It is restricted to mothers living with minor children.


********************************************************************************
* Create descriptive statistics to prep for annualized variables
********************************************************************************
use "$SIPP14keep/sipp14tpearn_rel", clear

// Create variables with the first and last month of observation by year
   egen startmonth=min(monthcode), by(SSUID PNUM year)
   egen lastmonth =max(monthcode), by(SSUID PNUM year)
   
// Creating partner status variables needed for reshape

	egen statuses = nvals(marital_status),	by(SSUID ERESIDENCEID PNUM year) // first examining how many people have more than 2 statuses in a year (aka changed status more than 1 time)
	// browse SSUID PNUM panelmonth marital_status statuses // if statuses>2
	tab statuses // okay very small percent - will use last status change OR if I do as separate columns, she can get both captured?
	
	replace spouse	=1 	if spouse 	> 1 // one case has 2 spouses
	replace partner	=1 	if partner 	> 1 // 36 cases of 2-3 partners

	// Create a combined spouse & partner indicator
	gen 	spartner=1 	if spouse==1 | partner==1
	replace spartner=0 	if spouse==0 & partner==0
	
	// Create indicators of partner presence at the first and last month of observation by year
	gen 	start_spartner=spartner 			if monthcode==startmonth
	gen 	last_spartner=spartner 				if monthcode==lastmonth
	gen 	start_spouse=spouse 				if monthcode==startmonth
	gen 	last_spouse=spouse 					if monthcode==lastmonth
	gen 	start_partner=partner 				if monthcode==startmonth
	gen 	last_partner=partner 				if monthcode==lastmonth
	gen 	start_marital_status=marital_status if monthcode==startmonth
	gen 	last_marital_status=marital_status 	if monthcode==lastmonth
	
	// browse SSUID PNUM year monthcode startmonth lastmonth start_marital_status last_marital_status marital_status
	
	// get partner specific variables
	gen spousenum=.
	forvalues n=1/22{
	replace spousenum=`n' if relationship`n'==1
	}

	gen partnernum=.
	forvalues n=1/22{
	replace partnernum=`n' if relationship`n'==2
	}

	gen spart_num=spousenum
	replace spart_num=partnernum if spart_num==.

	gen ft_pt_sp=.
	gen educ_sp=.
	gen race_sp=.
	gen weeks_employed_sp=.
	gen sex_sp =.
	
	forvalues n=1/22{
	replace ft_pt_sp=to_ft_pt`n' if spart_num==`n'
	replace educ_sp=to_educ`n' if spart_num==`n'
	replace race_sp=to_race`n' if spart_num==`n'
	replace weeks_employed_sp=to_RMWKWJB`n' if spart_num==`n'
	replace sex_sp=to_sex`n' if spart_num==`n'	
	}

	
// getting ready to create indicators of various status changes THROUGHOUT the year
drop _merge
local reshape_vars marital_status hhsize other_earner earnings spartner ft_pt educ renroll ft_pt_sp educ_sp race_sp weeks_employed_sp

keep `reshape_vars' SSUID PNUM panelmonth
 
// Reshape the data wide (1 person per row)
reshape wide `reshape_vars', i(SSUID PNUM) j(panelmonth)

	// marital status variables
	gen sing_coh1=0
	gen sing_mar1=0
	gen coh_mar1=0
	gen coh_diss1=0
	gen marr_diss1=0
	gen marr_wid1=0
	gen marr_coh1=0

	forvalues m=2/48{
		local l				=`m'-1
		
		gen sing_coh`m'	=  marital_status`m'==2 & inlist(marital_status`l',3,4,5)
		gen sing_mar`m'	=  marital_status`m'==1 & inlist(marital_status`l',3,4,5)
		gen coh_mar`m'	=  marital_status`m'==1 & marital_status`l'==2
		gen coh_diss`m'	=  inlist(marital_status`m',3,4,5) & marital_status`l'==2
		gen marr_diss`m'=  marital_status`m'==4 & marital_status`l'==1
		gen marr_wid`m'	=  marital_status`m'==3 & marital_status`l'==1
		gen marr_coh`m'	=  marital_status`m'==2 & marital_status`l'==1
	}

	// browse marital_status2 marital_status3 sing_coh3 sing_mar3 coh_mar3 coh_diss3 marr_diss3 marr_wid3 marr_coh3
	
	// indicators of someone leaving or entering household DURING the year
		gen hh_lose1=0
		gen earn_lose1=0
		gen earn_non1=0
		gen hh_gain1=0
		gen earn_gain1=0
		gen non_earn1=0
		gen resp_earn1=0
		gen resp_non1=0
		gen partner_gain1=0
		gen partner_lose1=0

	forvalues m=2/48{
		local l				=`m'-1
		
		gen hh_lose`m'		=  hhsize`m' < hhsize`l'
		gen earn_lose`m'	=  other_earner`m' < other_earner`l' & hhsize`m' < hhsize`l'
		gen earn_non`m'		=  other_earner`m' < other_earner`l' & hhsize`m' == hhsize`l'
		gen hh_gain`m'		=  hhsize`m' > hhsize`l'
		gen earn_gain`m'	=  other_earner`m' > other_earner`l' & hhsize`m' > hhsize`l'
		gen non_earn`m'		=  other_earner`m' > other_earner`l' & hhsize`m' == hhsize`l'
		gen resp_earn`m'	= earnings`m'!=. & (earnings`l'==. | earnings`l'==0)
		gen resp_non`m'		=  (earnings`m'==. | earnings`m'==0) & earnings`l'!=.
		gen partner_gain`m'	=  spartner`m' ==1 & (spartner`l'==. | spartner`l'==0)
		gen partner_lose`m'	=  (spartner`m'==. | spartner`m'==0) & spartner`l' == 1
	}
	
	* egen partner_lose_sum = rowtotal(partner_lose*)
	* browse partner_lose* spartner* if partner_lose_sum > 0
	
	
	// create indicators of job / education changes: respondent
		gen full_part1=0
		gen full_no1=0
		gen part_no1=0
		gen part_full1=0
		gen no_part1=0
		gen no_full1=0
		gen educ_change1=0
		gen enrolled_yes1=0
		gen enrolled_no1=0
		
	forvalues m=2/48{
		local l				=`m'-1
		
		gen full_part`m'	=  ft_pt`m'==2 & ft_pt`l'==1
		gen full_no`m'		=  ft_pt`m'==. & ft_pt`l'==1
		gen part_no`m'		=  ft_pt`m'==. & ft_pt`l'==2
		gen part_full`m'	=  ft_pt`m'==1 & ft_pt`l'==2
		gen no_part`m'		=  ft_pt`m'==2 & ft_pt`l'==.
		gen no_full`m'		=  ft_pt`m'==1 & ft_pt`l'==.
		gen educ_change`m'	=  educ`m'>educ`l' // education only measured annually but I think this will capture if it changes in the first month of the year? which is fine?
		gen enrolled_yes`m'	=  renroll`m'==1 & renroll`l'==2
		gen enrolled_no`m'	=  renroll`m'==2 & renroll`l'==1
	}
	
	// create indicators of job / education changes: partner
		gen full_part_sp1=0
		gen full_no_sp1=0
		gen part_no_sp1=0
		gen part_full_sp1=0
		gen no_part_sp1=0
		gen no_full_sp1=0
		gen educ_change_sp1=0
		
	forvalues m=2/48{
		local l				=`m'-1
		
		gen full_part_sp`m'		=  ft_pt_sp`m'==2 & ft_pt_sp`l'==1
		gen full_no_sp`m'		=  ft_pt_sp`m'==. & ft_pt_sp`l'==1
		gen part_no_sp`m'		=  ft_pt_sp`m'==. & ft_pt_sp`l'==2
		gen part_full_sp`m'		=  ft_pt_sp`m'==1 & ft_pt_sp`l'==2
		gen no_part_sp`m'		=  ft_pt_sp`m'==2 & ft_pt_sp`l'==.
		gen no_full_sp`m'		=  ft_pt_sp`m'==1 & ft_pt_sp`l'==.
		gen educ_change_sp`m'	=  educ_sp`m'>educ_sp`l'
	}
		
// Reshape data back to long format
reshape long `reshape_vars' sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh ///
hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non partner_gain partner_lose ///
full_part full_no part_no part_full no_part no_full educ_change enrolled_yes enrolled_no ///
full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp no_full_sp educ_change_sp, i(SSUID PNUM) j(panelmonth)

save "$tempdir/reshape_transitions.dta", replace

// creating table to make the ratio to use for the weight correction

use "$SIPP14keep/sipp14tpearn_rel", clear

drop _merge
merge 1:1 SSUID PNUM panelmonth using "$tempdir/reshape_transitions.dta"
drop if _merge==2

// preserve
collapse 	(sum) partner_lose, by(monthcode)
egen total_N14=total(partner_lose)
gen distro14=partner_lose/total_N14
rename partner_lose partner_lose14

merge 1:1 monthcode using "$tempdir/96_partner_distro.dta"
drop _merge

gen ratio = distro / distro14

save "$tempdir/partner_distro_lookup.dta", replace

//*Back to original and testing match

use "$SIPP14keep/sipp14tpearn_rel", clear

drop _merge
merge 1:1 SSUID PNUM panelmonth using "$tempdir/reshape_transitions.dta"

tab marital_status _merge, m // all missing
tab educ _merge, m
drop if _merge==2

	* adding the ratio column to use for the weight correction
	drop _merge
	merge m:1 monthcode using "$tempdir/partner_distro_lookup.dta"

	
	* browse SSUID PNUM monthcode partner spouse relationship2 pairtype2 marital_status partner_lose if pairtype2==2

	
// Create variables with the first and last month of observation by year
   egen startmonth=min(monthcode), by(SSUID PNUM year)
   egen lastmonth =max(monthcode), by(SSUID PNUM year)
   
   * All months have the same number of observations (12) within year
   * so this wasn't necessary.
   order 	SSUID PNUM year startmonth lastmonth
   list 	SSUID PNUM year startmonth lastmonth in 1/5, clean
   sort 	SSUID PNUM year panelmonth

* Prep for counting the total number of months breadwinning for the year. 
* NOTE: This isn't our primary measure.
   gen mbw50=1 if earnings > .5*thearn_alt & !missing(earnings) & !missing(thearn_alt)	// 50% threshold
   gen mbw60=1 if earnings > .6*thearn_alt & !missing(earnings) & !missing(thearn_alt)	// 60% threshold
   
// Create indicator of birth during the year
	drop tcbyr_8-tcbyr_20 // suppressed variables, no observations
	gen birth=1 if (tcbyr_1==year | tcbyr_2==year | tcbyr_3==year | tcbyr_4==year | tcbyr_5==year | tcbyr_6==year | tcbyr_7==year)
	gen first_birth=1 if (yrfirstbirth==year)
	// browse birth year tcbyr*

// Readding partner status variables

	egen statuses = nvals(marital_status),	by(SSUID ERESIDENCEID PNUM year) // first examining how many people have more than 2 statuses in a year (aka changed status more than 1 time)
	// browse SSUID PNUM panelmonth marital_status statuses // if statuses>2
	tab statuses // okay very small percent - will use last status change OR if I do as separate columns, she can get both captured?
	
	replace spouse	=1 	if spouse 	> 1 // one case has 2 spouses
	replace partner	=1 	if partner 	> 1 // 36 cases of 2-3 partners
	
	
// adding column for weight adjustment for partner_lose
bysort SSUID PNUM (year): egen year_left = min(year) if partner_lose==1
bysort SSUID PNUM year (year_left): replace year_left = year_left[1]

browse SSUID PNUM year monthcode partner_lose year_left

gen correction=1
replace correction = ratio if year == year_left

browse SSUID PNUM year monthcode partner_lose year_left ratio correction

sum correction

gen spousenum=.
	forvalues n=1/22{
	replace spousenum=`n' if relationship`n'==1
}

gen partnernum=.
	forvalues n=1/22{
	replace partnernum=`n' if relationship`n'==2
}

gen spart_num=spousenum
replace spart_num=partnernum if spart_num==.

gen earnings_sp=.
gen sex_sp=.
// gen earnings_a_sp=.

forvalues n=1/22{
	// replace earnings_sp=to_TPEARN`n' if spart_num==`n'
	replace earnings_sp=to_earnings`n' if spart_num==`n' // use this one
	replace sex_sp=to_sex`n' if spart_num==`n'	
}

/* exploration
browse SSUID PNUM year monthcode panelmonth partner_lose
tab monthcode partner_lose, column

bysort SSUID PNUM year (monthcode): egen month_left = min(monthcode) if partner_lose==1
bysort SSUID PNUM year (month_left): replace month_left = month_left[1]
sort SSUID PNUM year monthcode
browse SSUID PNUM year monthcode panelmonth partner_lose month_left

gen timing_left=.
replace timing_left=0 if monthcode <= month_left & month_left!=.
replace timing_left=1 if monthcode > month_left & month_left!=.
browse SSUID PNUM year monthcode panelmonth partner_lose month_left timing_left

	gen spousenum=.
	forvalues n=1/22{
	replace spousenum=`n' if relationship`n'==1
	}

	gen partnernum=.
	forvalues n=1/22{
	replace partnernum=`n' if relationship`n'==2
	}

	gen spart_num=spousenum
	replace spart_num=partnernum if spart_num==.

	gen earnings_sp=.
	gen earnings_a_sp=.

	forvalues n=1/22{
	replace earnings_sp=to_TPEARN`n' if spart_num==`n'
	replace earnings_a_sp=to_earnings`n' if spart_num==`n' // use this one
	}
	
	gen pairtype_sp=.
	forvalues n=1/22{
	    replace pairtype_sp = pairtype`n' if spart_num==`n'
	}
	
	
sort SSUID PNUM panelmonth
replace pairtype_sp=pairtype_sp[_n-1] if partner_lose==1  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & panelmonth==(panelmonth[_n-1]+1)
	
browse SSUID PNUM year monthcode spartner partner_lose earnings earnings_a_sp thearn_alt mbw60 pairtype_sp //  ems ems_ehc

tab pairtype_sp if partner_lose==1
replace pairtype_sp =0 if pairtype_sp==.

bysort SSUID PNUM year (pairtype_sp): egen pairtype_sp_ch=max(pairtype_sp)
sort SSUID PNUM panelmonth
browse SSUID PNUM year monthcode spartner spart_num partner_lose earnings earnings_a_sp pairtype_sp pairtype_sp_ch

	* want examples of SSUIDs to investigate WHY there aren't all the person-months - do I have in main file and I lost along way, or were never there??
	* 000418209316 - only up to month 7, year 2014 - but that's nothing to do with partner, because partner left month 1...
	* 000860215173 - only up to month 2, year 2015 - partner left month 1

// troubleshooting why the distribution doesn't match 1996
browse monthcode SSUID year year_left partner_lose correction

tab monthcode partner_lose [aweight=correction], column
tab monthcode partner_lose if pairtype_sp_ch==2 [aweight=correction], column
tab monthcode partner_lose if pairtype_sp_ch==1 [aweight=correction], column

tab monthcode
tab monthcode [aweight=wpfinwgt]
tab monthcode if year == year_left [aweight=wpfinwgt]

tab monthcode if year == year_left & pairtype_sp_ch==2 // why is distribution RIGHT for type 2 but not type 1? Am i artificially doing this somehow?!
tab monthcode if year == year_left & pairtype_sp_ch==1

tab monthcode if year == year_left & year==2013
tab monthcode if year == year_left & year==2014
tab monthcode if year == year_left & year==2015
tab monthcode if year == year_left & year==2016

tab monthcode if year == year_left & year==2013 & pairtype_sp_ch==1
tab monthcode if year == year_left & year==2014 & pairtype_sp_ch==1 // 7.8-8.9
tab monthcode if year == year_left & year==2015 & pairtype_sp_ch==1  // 7.6-9.6
tab monthcode if year == year_left & year==2016 & pairtype_sp_ch==1 // gets WORSE with each year- is it just drop-off?? 7.0-9.7

// change in earnings within year
gen earnings_z = earnings
replace earnings_z = 0 if earnings==.

by SSUID PNUM (panelmonth), sort: gen earn_change = ((earnings_z -earnings_z[_n-1])/earnings_z [_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & panelmonth==panelmonth[_n-1]+1
by SSUID PNUM (panelmonth), sort: gen earn_change_raw = (earnings_z -earnings_z[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & panelmonth==panelmonth[_n-1]+1

browse SSUID PNUM year monthcode earnings earn_change earn_change_raw

gen earnings_z_sp = earnings_a_sp
replace earnings_z_sp = 0 if earnings_a_sp==.

by SSUID PNUM (panelmonth), sort: gen earn_change_sp = ((earnings_z_sp -earnings_z_sp[_n-1])/earnings_z_sp[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & panelmonth==panelmonth[_n-1]+1
by SSUID PNUM (panelmonth), sort: gen earn_change_raw_sp = (earnings_z_sp -earnings_z_sp[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & panelmonth==panelmonth[_n-1]+1

browse SSUID PNUM year monthcode earnings_z_sp earn_change_sp earn_change_raw_sp

bysort SSUID PNUM year (monthcode): egen month_lost10 = min(monthcode) if earn_change_sp<=-.10000000000000000000
bysort SSUID PNUM year (month_lost10): replace month_lost10 = month_lost10[1]
gen month_lost10_flag = 1 if month_lost10 == monthcode
sort SSUID PNUM year monthcode
browse SSUID PNUM year monthcode panelmonth earnings_z_sp earn_change_sp month_lost10 month_lost10_flag

bysort SSUID PNUM year (monthcode): egen month_lost50 = min(monthcode) if earn_change_sp<=-.5000000000000000000
bysort SSUID PNUM year (month_lost50): replace month_lost50 = month_lost50[1]
gen month_lost50_flag = 1 if month_lost50 == monthcode

bysort SSUID PNUM year (monthcode): egen month_lost100 = min(monthcode) if earn_change_sp<=-1
bysort SSUID PNUM year (month_lost100): replace month_lost100 = month_lost100[1]
gen month_lost100_flag = 1 if month_lost100 == monthcode

sort SSUID PNUM year monthcode
browse SSUID PNUM year monthcode panelmonth earnings_z_sp earn_change_sp month_lost10 month_lost10_flag month_lost50 month_lost50_flag month_lost100 month_lost100_flag

tab monthcode month_lost10_flag, column
tab monthcode month_lost50_flag, column
tab monthcode month_lost100_flag, column

sum earnings_z, detail
sum earn_change, detail
sum earn_change_raw, detail
sum earnings_z_sp, detail
sum earn_change_sp, detail
sum earn_change_raw_sp, detail

preserve

collapse 	(sum) earnings earnings_a_sp thearn_alt to_earnings* /// 
			(mean) partner_lose partner_gain 					///
			(max) relationship*, ///
			by(SSUID PNUM year timing_left)
			

egen hh_earn_max = rowmax (to_earnings1-to_earnings22)
// browse SSUID PNUM year hh_earn_max earnings to_earnings* 

gen who_max_earn=.
forvalues n=1/22{
replace who_max_earn=relationship`n' if to_earnings`n'==hh_earn_max
}

// browse SSUID PNUM year who_max_earn hh_earn_max earnings to_earnings* relationship*

gen total_max_earner=.
replace total_max_earner=who_max_earn if (earnings==. & hh_earn_max>0 & hh_earn_max!=.) | (hh_earn_max > earnings & earnings!=. & hh_earn_max!=.)
replace total_max_earner=99 if (earnings>0 & earnings!=. & hh_earn_max==.) | (hh_earn_max < earnings & earnings!=. & hh_earn_max!=.)

gen total_max_earner2=total_max_earner
replace total_max_earner2=100 if total_max_earner==99 & (hh_earn_max==0 | hh_earn_max==.) // splitting out the "self" view to delineate between hh where mother is primary earner because she is the only earner

browse SSUID PNUM year who_max_earn hh_earn_max earnings total_max_earner total_max_earner2 to_earnings*


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
                 99 "self" 
				 100 "self - no other earners" ;

#delimit cr

label values who_max_earn total_max_earner* relationship* rel2

gen parent=0
forvalues r=1/22{
    replace parent=parent+1 if inlist(relationship`r',3,5,7)
}

gen other_rel=0
forvalues r=1/22{
    replace other_rel=other_rel+1 if inrange(relationship`r',9,19)
}

gen other_non_rel=0
forvalues r=1/22{
    replace other_non_rel=other_non_rel+1 if relationship`r'==20
}

browse SSUID PNUM year timing_left parent other_rel other_non_rel

sum parent if timing_left==0
sum parent if timing_left==1
sum other_rel if timing_left==0
sum other_rel if timing_left==1
sum other_non_rel if timing_left==0
sum other_non_rel if timing_left==1

gen parent_enter=0
replace parent_enter=1 if timing_left==1 & timing_left[_n-1]==0 & parent > parent[_n-1]
replace parent_enter=. if timing_left==.

gen rel_enter=0
replace rel_enter=1 if timing_left==1 & timing_left[_n-1]==0 & other_rel > other_rel[_n-1]
replace rel_enter=. if timing_left==.

gen non_rel_enter=0
replace non_rel_enter=1 if timing_left==1 & timing_left[_n-1]==0 & other_non_rel > other_non_rel[_n-1]
replace non_rel_enter=. if timing_left==.

browse SSUID PNUM year timing_left parent other_rel other_non_rel parent_enter rel_enter non_rel_enter

tab parent_enter if timing_left==1
tab rel_enter if timing_left==1
tab non_rel_enter if timing_left==1

gen bw60 = (earnings > .6*thearn_alt) 
gen earnings_ratio = earnings / thearn_alt

sum earnings_ratio if timing_left==1, detail

tab who_max_earn if bw60==1
replace who_max_earn=99 if who_max_earn==. & bw60==1

tab who_max_earn if timing_left==1

bysort SSUID PNUM year: egen total_earnings = total(earnings)
bysort SSUID PNUM year: egen total_hh_earn = total(thearn_alt)
gen total_ratio = total_earnings / total_hh_earn
gen total_bw = (total_ratio>.6)

tab bw60 total_bw if timing_left==1, row

browse SSUID PNUM year timing_left who_max_earn hh_earn_max earnings thearn_alt earnings_a_sp earnings_ratio total_ratio partner_lose partner_gain bw60 if timing_left!=.

restore
*/

	// Create a combined spouse & partner indicator
*	gen 	spartner=1 	if spouse==1 | partner==1
*	replace spartner=0 	if spouse==0 & partner==0
	
	// Create indicators of partner presence and earnings at the first and last month of observation by year
	gen 	start_spartner=spartner if monthcode==startmonth
	gen 	last_spartner=spartner 	if monthcode==lastmonth
	gen 	start_spouse=spouse if monthcode==startmonth
	gen 	last_spouse=spouse 	if monthcode==lastmonth
	gen 	start_partner=partner if monthcode==startmonth
	gen 	last_partner=partner 	if monthcode==lastmonth
	gen 	start_marital_status=marital_status if monthcode==startmonth
	gen 	last_marital_status=marital_status 	if monthcode==lastmonth
	gen 	st_partner_earn=earnings_sp if monthcode==startmonth
	gen 	end_partner_earn=earnings_sp 	if monthcode==lastmonth
	
// Create basic indictor to identify months observed when data is collapsed
	gen one=1
	
********************************************************************************
* Create annual measures
********************************************************************************
// Creating variables to prep for annualizing

foreach var of varlist employ ft_pt ems_ehc rmnumjobs marital_status occ_code* tjb*_occ{ 
    gen st_`var'=`var'
    gen end_`var'=`var'
}

forvalues r=1/22{
gen avg_to_tpearn`r'=to_TPEARN`r' // using the same variable in sum and avg and can't use wildcards in below, so renaming first to use renamed variable for avg
gen avg_to_hrs`r'=to_TMWKHRS`r'
gen avg_to_earn`r'=to_earnings`r'
gen to_mis_TPEARN`r'=to_TPEARN`r'
gen to_mis_earnings`r'=to_earnings`r'
gen to_mis_TMWKHRS`r'=to_TMWKHRS`r'
	foreach var of varlist to_employ`r' to_ft_pt`r' to_EMS`r'{
		gen st_`var'=`var'
		gen end_`var'=`var'
	}
}

foreach var of varlist hhsize minorchildren{
	gen st_`var' = `var'
	gen end_`var' = `var'
}

recode eeitc (.=0)
recode rtanfyn (.=0)
recode rtanfcov (.=0)

// need to retain missings for earnings when annualizing (sum treats missing as 0)

bysort SSUID PNUM year (tpearn): egen tpearn_mis = min(tpearn)
// browse SSUID PNUM year panelmonth tpearn tpearn_mis // can I just do this with min in collapse? if all missing, missing will be min?
bysort SSUID PNUM year (earnings): egen earnings_mis = min(earnings)
bysort SSUID PNUM year (tmwkhrs): egen tmwkhrs_mis = min(tmwkhrs)

// Collapse the data by year to create annual measures
collapse 	(count) monthsobserved=one  nmos_bw50=mbw50 nmos_bw60=mbw60 				/// mother char.
			(sum) 	tpearn thearn thearn_alt tmwkhrs earnings enjflag					///
					sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh 		///
					hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn		///
					resp_non partner_gain partner_lose first_birth						///
					full_part full_no part_no part_full no_part no_full educ_change		///
					full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp			///
					no_full_sp educ_change_sp rmwkwjb weeks_employed_sp					///
					program_income tanf_amount rtanfyn									///
			(mean) 	spouse partner numtype2 wpfinwgt scaled_weight correction birth 	/// 
					mom_panel avg_hhsize = hhsize avg_hrs=tmwkhrs avg_earn=earnings  	///
					numearner other_earner thincpovt2 pov_level start_marital_status 	///
					last_marital_status tjb*_annsal1 tjb*_hourly1 tjb*_wkly1  			///
					tjb*_bwkly1 tjb*_mthly1 tjb*_smthly1 tjb*_other1 tjb*_gamt1			///
					eeitc rtanfcov thinc_bank thinc_stmf thinc_bond thinc_rent 			///
					thinc_oth thinc_ast 												///
			(max) 	minorchildren minorbiochildren preschoolchildren minors_fy			///
					prebiochildren race educ race_sp educ_sp sex_sp tceb oldest_age 	///
					ejb*_payhr1 start_spartner last_spartner start_spouse last_spouse	///
					start_partner last_partner tage ageb1 status_b1 tcbyr_1-tcbyr_7		///
					yrfirstbirth														///
			(min) 	tage_fb durmom durmom_1st youngest_age first_wave					///
					tpearn_mis tmwkhrs_mis earnings_mis									///
					to_mis_TPEARN* to_mis_TMWKHRS* to_mis_earnings*						///
			(max) 	relationship* to_num* to_sex* to_age* to_race* to_educ*				/// other hh members char.
			(sum) 	to_TPEARN* to_TMWKHRS* to_earnings*			 						///
			(mean) 	avg_to_tpearn* avg_to_hrs* avg_to_earn*								///
					to_EJB*_PAYHR1* to_TJB*_ANNSAL1* to_TJB*_HOURLY1* to_TJB*_WKLY1* 	///
					to_TJB*_BWKLY1* to_TJB*_MTHLY1* to_TJB*_SMTHLY1* to_TJB*_OTHER1*	///
					to_TJB*_GAMT1* to_RMNUMJOBS*										///
			(firstnm) st_*																/// will cover all (mother + hh per recodes) 
			(lastnm) end_*,																///
			by(SSUID PNUM year)
			


// Fix Type 2 people identifier
	gen 	anytype2 = (numtype2 > 0)
	drop 	numtype2
	gen 	firstbirth = (first_birth>0)
	drop	first_birth

// Create indicators for partner changes -- note to KM: revisit this, needs more categories (like differentiate spouse v. partner)
	gen 	gain_partner=0 				if !missing(start_spartner) & !missing(last_spartner)
	replace gain_partner=1 				if start_spartner==0 		& last_spartner==1

	gen 	lost_partner=0 				if !missing(start_spartner) & !missing(last_spartner)
	replace lost_partner=1 				if start_spartner==1 		& last_spartner==0
	
	gen		no_status_chg=0
	replace no_status_chg=1 if (sing_coh + sing_mar + coh_mar + coh_diss + marr_diss + marr_wid + marr_coh)==0
	
	gen no_job_chg=0
	replace no_job_chg=1 if (full_part + full_no + part_no + part_full + no_part + no_full)==0
	
	gen no_job_chg_sp=0
	replace no_job_chg_sp=1 if (full_part_sp + full_no_sp + part_no_sp + part_full_sp + no_part_sp + no_full_sp)==0
	
// Create indicator for incomple annual observations
	gen partial_year= (monthsobserved < 12)
	
// update earnings / hours to be missing if missing all 12 months
replace earnings=. if earnings_mis==.
replace tpearn=. if tpearn_mis==.
replace tmwkhrs=. if tmwkhrs_mis==.

forvalues r=1/22{
replace to_TPEARN`r'=. if to_mis_TPEARN`r'==.
replace to_earnings`r'=. if to_mis_earnings`r'==.
replace to_TMWKHRS`r'=. if to_mis_TMWKHRS`r'==.
}

// label define occupation 1 "Management" 2 "STEM" 3 "Education / Legal / Media" 4 "Healthcare" 5 "Service" 6 "Sales" 7 "Office / Admin" 8 "Farming" 9 "Construction" 10 "Maintenance" 11 "Production" 12 "Transportation" 13 "Military" 
label values st_occ_* end_occ_* occupation
label values st_tjb*_occ end_tjb*_occ occ

// Create annual breadwinning indicators

	// Create indicator for negative household earnings & no earnings. 
	gen hh_noearnings= (thearn_alt <= 0)
	
	gen earnings_ratio=earnings/thearn_alt if hh_noearnings !=1 

	// 50% breadwinning threshold
	* Note that this measure was missing for no (or negative) earnings households, but that is now changed
	gen 	bw50= (earnings > .5*thearn_alt) 	if hh_noearnings !=1 // if earnings missing, techincally larger than this ratio so was getting a 1 here when I removed the missing restriction above, so need to add below
	replace bw50= 0 					if hh_noearnings==1 | earnings==.

	// 60% breadwinning threshold
	gen 	bw60= (earnings > .6*thearn_alt) 	if hh_noearnings !=1
	replace bw60= 0 					if hh_noearnings==1 | earnings==.
	
gen wave=year-2012
	
save "$SIPP14keep/annual_bw_status.dta", replace

// answer question about wealth-generation
browse SSUID PNUM year thinc_ast

gen anywealthincome=0
replace anywealthincome=1 if thinc_ast>0 & thinc_ast!=.
tab anywealthincome

gen wealthincome_100=0
replace wealthincome_100=1 if thinc_ast>=100 & thinc_ast!=.
tab wealthincome_100

gen wealthincome_1000=0
replace wealthincome_1000=1 if thinc_ast>=1000 & thinc_ast!=.
tab  wealthincome_1000