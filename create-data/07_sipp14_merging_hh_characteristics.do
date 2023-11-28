********************************************************************************
* DESCRIPTION
********************************************************************************
* Create a file that add to the final women file their relationships as well as
* characteristics of each person in their HH
* The data file used in this script was produced by compute_relationships.do
* and measures_and_sample.do

* This file also merges the SSA Supplement onto the annualized file to get 
* detailed marital history - to calculate marital status at first birth

********************************************************************************
* Create file that retains information for those who match
* to a mother in final sample
********************************************************************************
* To get relationships / attributes

use "$tempdir/relationship_pairs_bymonth.dta", clear

drop RRELIG


reshape wide to_num relationship RREL to_sex from_age to_age pairtype from_sex from_race to_race from_educ to_educ from_employ to_employ from_TAGE_FB to_TAGE_FB from_EMS to_EMS from_TPEARN to_TPEARN from_earnings to_earnings from_TMWKHRS to_TMWKHRS from_ft_pt to_ft_pt from_occ_1 to_occ_1 from_occ_2 to_occ_2 from_occ_3 to_occ_3 from_occ_4 to_occ_4 from_occ_5 to_occ_5 from_occ_6 to_occ_6 from_occ_7 to_occ_7 from_EINTTYPE to_EINTTYPE from_whynowork to_whynowork from_leave_job1 to_leave_job1 from_leave_job2 to_leave_job2 from_leave_job3 to_leave_job3 from_leave_job4 to_leave_job4 from_leave_job5 to_leave_job5 from_leave_job6 to_leave_job6 from_leave_job7 to_leave_job7 from_jobchange_1 to_jobchange_1 from_jobchange_2 to_jobchange_2 from_jobchange_3 to_jobchange_3 from_jobchange_4 to_jobchange_4 from_jobchange_5 to_jobchange_5 from_jobchange_6 to_jobchange_6 from_jobchange_7 to_jobchange_7 from_jobtype_1 to_jobtype_1 from_jobtype_2 to_jobtype_2 from_jobtype_3 to_jobtype_3 from_jobtype_4 to_jobtype_4 from_jobtype_5 to_jobtype_5 from_jobtype_6 to_jobtype_6 from_jobtype_7 to_jobtype_7 from_better_job to_better_job from_RMNUMJOBS to_RMNUMJOBS from_EFINDJOB to_EFINDJOB from_EDISABL to_EDISABL from_RDIS_ALT to_RDIS_ALT from_programs to_programs from_ECHLD_MNYN to_ECHLD_MNYN from_ELIST to_ELIST from_EWORKMORE to_EWORKMORE from_hh_move to_hh_move from_RENROLL to_RENROLL from_ENJ_NOWRK5 to_ENJ_NOWRK5 from_EJB1_PAYHR1 to_EJB1_PAYHR1 from_TJB1_ANNSAL1 to_TJB1_ANNSAL1 from_TJB1_HOURLY1 to_TJB1_HOURLY1 from_TJB1_WKLY1 to_TJB1_WKLY1 from_TJB1_BWKLY1 to_TJB1_BWKLY1 from_TJB1_MTHLY1 to_TJB1_MTHLY1 from_TJB1_SMTHLY1 to_TJB1_SMTHLY1 from_TJB1_OTHER1 to_TJB1_OTHER1 from_TJB1_GAMT1 to_TJB1_GAMT1 from_EJB2_PAYHR1 to_EJB2_PAYHR1 from_TJB2_ANNSAL1 to_TJB2_ANNSAL1 from_TJB2_HOURLY1 to_TJB2_HOURLY1 from_TJB2_WKLY1 to_TJB2_WKLY1 from_TJB2_BWKLY1 to_TJB2_BWKLY1 from_TJB2_MTHLY1 to_TJB2_MTHLY1 from_TJB2_SMTHLY1 to_TJB2_SMTHLY1 from_TJB2_OTHER1 to_TJB2_OTHER1 from_TJB2_GAMT1 to_TJB2_GAMT1 from_EJB3_PAYHR1 to_EJB3_PAYHR1 from_TJB3_ANNSAL1 to_TJB3_ANNSAL1 from_TJB3_HOURLY1 to_TJB3_HOURLY1 from_TJB3_WKLY1 to_TJB3_WKLY1 from_TJB3_BWKLY1 to_TJB3_BWKLY1 from_TJB3_MTHLY1 to_TJB3_MTHLY1 from_TJB3_SMTHLY1 to_TJB3_SMTHLY1 from_TJB3_OTHER1 to_TJB3_OTHER1 from_TJB3_GAMT1 to_TJB3_GAMT1 from_EJB4_PAYHR1 to_EJB4_PAYHR1 from_TJB4_ANNSAL1 to_TJB4_ANNSAL1 from_TJB4_HOURLY1 to_TJB4_HOURLY1 from_TJB4_WKLY1 to_TJB4_WKLY1 from_TJB4_BWKLY1 to_TJB4_BWKLY1 from_TJB4_MTHLY1 to_TJB4_MTHLY1 from_TJB4_SMTHLY1 to_TJB4_SMTHLY1 from_TJB4_OTHER1 to_TJB4_OTHER1 from_TJB4_GAMT1 to_TJB4_GAMT1 from_EJB5_PAYHR1 to_EJB5_PAYHR1 from_TJB5_ANNSAL1 to_TJB5_ANNSAL1 from_TJB5_HOURLY1 to_TJB5_HOURLY1 from_TJB5_WKLY1 to_TJB5_WKLY1 from_TJB5_BWKLY1 to_TJB5_BWKLY1 from_TJB5_MTHLY1 to_TJB5_MTHLY1 from_TJB5_SMTHLY1 to_TJB5_SMTHLY1 from_TJB5_OTHER1 to_TJB5_OTHER1 from_TJB5_GAMT1 to_TJB5_GAMT1 from_RMWKWJB to_RMWKWJB,i(SSUID ERESIDENCEID from_num panelmonth) j(lno)

rename from_num PNUM

save "$tempdir/relationship_details_wide", replace 

* Final sample file:
use "$SIPP14keep/sipp14tpearn_all", clear

// Make the six digit identifier for residence addresses numeric to match the merge file
replace ERESIDENCEID=subinstr(ERESIDENCEID,"A","1",.)
replace ERESIDENCEID=subinstr(ERESIDENCEID,"B","2",.)
replace ERESIDENCEID=subinstr(ERESIDENCEID,"C","3",.)
replace ERESIDENCEID=subinstr(ERESIDENCEID,"D","4",.)
replace ERESIDENCEID=subinstr(ERESIDENCEID,"E","5",.)
replace ERESIDENCEID=subinstr(ERESIDENCEID,"F","6",.)
        
destring ERESIDENCEID, replace
	
merge 1:1 SSUID ERESIDENCEID panelmonth PNUM using "$tempdir/relationship_details_wide.dta"

drop if _merge==2

tab hhsize if _merge==1 // confirming that the unmatched in master are all people who live alone, so that is fine.

drop from_* // just want to use the "to" attributes aka others in HH. Will use original file for respondent's characteristics. This will help simplify

save "$SIPP14keep/sipp14tpearn_rel.dta", replace

// union status recodes - compare these to using simplistic gain or lose partner / gain or lose spouse later on

label define ems 1 "Married, spouse present" 2 "Married, spouse absent" 3 "Widowed" 4 "Divorced" 5 "Separated" 6 "Never Married"
label values ems_ehc ems
label values ems ems

tab ems_ehc spouse // some people are "married - spouse absent" - currently not in "spouse" tally, (but they are also not SEPARATED according to them), we are considering them married. Worth noting that some of these women also have unmarried partner living there
tab ems_ehc partner
// browse SSUID PNUM panelmonth ems_ehc ems spouse partner relationship* if ems_ehc==2

gen marital_status=.
replace marital_status=1 if inlist(ems_ehc,1,2) // for now - considered all married as married
replace marital_status=2 if inlist(ems_ehc,3,4,5,6) & partner>=1 // for now, if married spouse absent and having a partner - considering you married and not counting here. Cohabiting will override if divorced / separated in given month
replace marital_status=3 if ems_ehc==3 & partner==0
replace marital_status=4 if inlist(ems_ehc,4,5) & partner==0
replace marital_status=5 if ems_ehc==6 & partner==0

label define marital_status 1 "Married" 2 "Cohabiting" 3 "Widowed" 4 "Dissolved-Unpartnered" 5 "Never Married- Not partnered"
label values marital_status marital_status

* tab relationship2 if pairtype2==2
* browse SSUID PNUM partner spouse relationship2 pairtype2 marital_status if pairtype2==2

// earner status recodes
gen other_earner=numearner if tpearn==.
replace other_earner=(numearner-1) if tpearn!=.

// browse panelmonth numearner other_earner tpearn to_TPEARN*

// job changes
egen jobchange = rowtotal(jobchange_1-jobchange_7)
replace jobchange=1 if jobchange>=1 & jobchange!=.
replace jobchange=. if tmwkhrs==.

forvalues n=1/22{
	egen to_jobchange`n' = rowtotal(to_jobchange_1`n'-to_jobchange_7`n')
	replace to_jobchange`n'=1 if to_jobchange`n'>=1 & to_jobchange`n'!=.
	replace to_jobchange`n'=. if to_TMWKHRS`n'==.
}

********************************************************************************
* Merge on SSA to get marital history
********************************************************************************
rename SSUID ssuid // ssa currently in lowercare
rename PNUM pnum

drop _merge

merge m:1 ssuid pnum using "$SIPP2014/pu2014ssa.dta", keepusing(ems_s exmar_s tmar?_yr twid?_yr tdiv?_yr tsep?_yr ewidiv*)

drop if _merge==2 // don't want people JUST in SSA, bc likely means they are not in our sample

rename ssuid SSUID
rename pnum PNUM

/* a LOT unmatched, some to look at: ssuid	pnum
000418185142	101
000418209291	102
667860945880	102
667860967919	101

browse if inlist(ssuid, "000418185142", "000418209291", "667860945880", "667860967919")
*/

tab ems_ehc _merge // not a function of marital status
tab first_wave _merge // SSA after wave 1, but still a lot of people in wave 1 unmatched

/// creating indicator of marital status at first birth
browse SSUID PNUM exmar exmar_s ems tyrcurrmarr tyrfirstmarr tmar1_yr tdiv1_yr tmar2_yr tmar3_yr yrfirstbirth _merge

//
gen status_b1=.
replace status_b1 = 1 if inlist(ems,1,2) & exmar==1 & yrfirstbirth >= tyrfirstmarr // assuming if birth happened IN year, they were married, especially bc it's birth NOT conception
replace status_b1 = 1 if yrfirstbirth >= tyrcurrmarr 
replace status_b1 = 1 if ems!=6 & yrfirstbirth >= tyrfirstmarr & tyrfirstmarr!=. & ((yrfirstbirth < tdiv1_yr & tdiv1_yr!=.) | (yrfirstbirth < twid1_yr & twid1_yr!=.) | (yrfirstbirth < tsep1_yr & tsep1_yr!=.)) // trying to use the actual data v. SSA whenever possible
replace status_b1 = 1 if exmar>1 & yrfirstbirth >= tmar2_yr & tmar2_yr!=. & ((yrfirstbirth < tdiv2_yr & tdiv2_yr!=.) | (yrfirstbirth < twid2_yr & twid2_yr!=.) | (yrfirstbirth < tsep2_yr & tsep2_yr!=.))
replace status_b1 = 1 if exmar>2 & yrfirstbirth >= tmar3_yr & tmar3_yr!=. & ((yrfirstbirth < tdiv3_yr & tdiv3_yr!=.) | (yrfirstbirth < twid3_yr & twid3_yr!=.) | (yrfirstbirth < tsep3_yr & tsep3_yr!=.))
replace status_b1 = 2 if ems==6
replace status_b1 = 2 if yrfirstbirth < tyrfirstmarr
replace status_b1 = 2 if inlist(ems,1,2) & exmar==1 & yrfirstbirth < tyrfirstmarr
replace status_b1 = 3 if ems!=6 & yrfirstbirth > twid1_yr & yrfirstbirth < tmar2_yr & twid1_yr!=. & tmar2_yr!=.
replace status_b1 = 3 if ems!=6 & yrfirstbirth > twid2_yr & yrfirstbirth < tmar3_yr & twid2_yr!=. & tmar3_yr!=.
replace status_b1 = 3 if exmar==1 & ems==3 &  (yrfirstbirth > twid1_yr & twid1_yr!=.)
replace status_b1 = 4 if ems!=6 & yrfirstbirth > tdiv1_yr & yrfirstbirth < tmar2_yr & tdiv1_yr!=. & tmar2_yr!=.
replace status_b1 = 4 if ems!=6 & yrfirstbirth > tsep1_yr & yrfirstbirth < tmar2_yr & tsep1_yr!=. & tmar2_yr!=.
replace status_b1 = 4 if ems!=6 & yrfirstbirth > tdiv2_yr & yrfirstbirth < tmar3_yr & tdiv2_yr!=. & tmar3_yr!=.
replace status_b1 = 4 if ems!=6 & yrfirstbirth > tsep2_yr & yrfirstbirth < tmar3_yr & tsep2_yr!=. & tmar3_yr!=.
replace status_b1 = 4 if exmar==1 & inlist(ems,4,5) &  ((yrfirstbirth > tdiv1_yr & tdiv1_yr!=.) | (yrfirstbirth > tsep1_yr & tsep1_yr!=.))

// filling in ones I have to guesstimate
replace status_b1 = 1 if (yrfirstbirth-tyrfirstmarr) <=3 & status_b1==. // assuming if birth within 3 years of married date, you were married
// my concern with using a longer timeline is, for those who it was a while and are divorced, it COULD be with a partner, but we don't have that info, so feel less sure

label define birth_status 1 "Married" 2 "Never Married" 3  "Widowed" 4 "Divorced or Separated"
label values status_b1 birth_status

browse SSUID PNUM exmar ems tyrcurrmarr tyrfirstmarr tmar1_yr tdiv1_yr tmar2_yr tmar3_yr yrfirstbirth status_b1 _merge

* browse SSUID PNUM exmar ems tyrcurrmarr tyrfirstmarr tmar1_yr tdiv1_yr tmar2_yr tmar3_yr yrfirstbirth status_b1 if status_b1==.
* browse SSUID PNUM exmar ems tyrcurrmarr tyrfirstmarr tmar1_yr tdiv1_yr tmar2_yr tmar3_yr yrfirstbirth status_b1 if _merge==3 & status_b1==. // have detail but can't; find
* browse SSUID PNUM exmar ems tyrcurrmarr tyrfirstmarr tmar1_yr tdiv1_yr tmar2_yr tmar3_yr yrfirstbirth status_b1 if _merge==1 & status_b1==. // no detail and can't find
// like this person for example: 000995185903	101 - first marriage 1992, second marriage 2006, birth in 2001, no info on when marriage ended. assume IN marriage? or make a catch-all EVER-married, when don't know if married or divorced but know they had their baby at least after ONE marriage?

save "$SIPP14keep/sipp14tpearn_rel.dta", replace
