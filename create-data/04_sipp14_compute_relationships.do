*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* compute_relationships.do
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* This script uses the RREL and RRELPUM variables to describe each person's relationship 
* to every other person in the household by month

* The RREL variables RREL1-RREL20 are for type 1 persons and RREL21-RREL30 are for type 2 persons

* The data file used in this script was produced by merge_waves.do

********************************************************************************
* Reshape relationship data from a file with one record for each (type 1) person
* to a file with one record for each person a type 1 individual lives with
* (including type 2 people).
********************************************************************************

// Import relationship data
use "$SIPP14keep/allmonths14_rec.dta", clear

// Select only necessary variables
keep SSUID ERESIDENCEID PNUM RREL* RREL_PNUM* panelmonth

// Reshape the data
reshape long RREL_PNUM RREL,i(SSUID ERESIDENCEID PNUM panelmonth) j(lno) 

// Don't keep relationship to self or empty lines
keep if RREL !=99 & !missing(RREL) 

// Add value labels to relationship variables
#delimit ;
label define rel  1 " Opposite sex spouse"
                  2 " Opposite sex unmarried partner"
                  3 "Same sex spouse"
                  4 "Same sex unmarried partner"
                  5 "Biological parent/child"
                  6 "Step parent/child"
                  7 "Adoptive parent/child"
                  8 "Grandparent/Grandchild"
                  9 "Biological siblings"
                 10 "Half siblings"
                 11 "Step siblings"
                 12 "Adopted siblings"
                 13 "Other siblings"
                 14 "Parent/Child-in-law"
                 15 "Brother/Sister-in-law"
                 16 "Aunt, Uncle, Niece, Nephew"
                 17 "Other relative"
                 18 "Foster parent/Child"
                 19 "Other non-relative"
                 99 "self" ;

#delimit cr

label values RREL  rel

// Peek at the labels and values
fre RREL

// Rename vars
rename PNUM from_num
rename RREL_PNUM to_num

save "$tempdir/rel_pairs_bymonth.dta", replace

********************************************************************************
* Reshape data on type 1 individuals,
* creating two records for each pair of coresident
* type 1 people using joinby
********************************************************************************

// Import relationship data, a file with one record per type 1 individual 
use "$SIPP14keep/allmonths14_rec.dta", clear

// Select only necessary variables
keep SSUID ERESIDENCEID PNUM panelmonth TAGE ESEX race educ employ TAGE_FB EMS TPEARN earnings TMWKHRS ft_pt occ* EINTTYPE whynowork leave_job* jobchange_* jobtype_* better_job RMNUMJOBS EFINDJOB EDISABL RDIS_ALT programs ECHLD_MNYN ELIST EWORKMORE hh_move RENROLL ENJ_NOWRK5 EJB*_PAYHR1 TJB*_ANNSAL1 TJB*_HOURLY*1 TJB*_WKLY1 TJB*_BWKLY1 TJB*_MTHLY1 TJB*_SMTHLY1 TJB*_OTHER1 TJB*_GAMT1 RMWKWJB

save "$tempdir/onehalf.dta", replace

foreach var in PNUM TAGE ESEX race educ employ TAGE_FB EMS TPEARN earnings TMWKHRS ft_pt occ_1 occ_2 occ_3 occ_4 occ_5 occ_6 occ_7 EINTTYPE whynowork leave_job1 leave_job2 leave_job3 leave_job4 leave_job5 leave_job6 leave_job7 jobchange_1 jobchange_2 jobchange_3 jobchange_4 jobchange_5 jobchange_6 jobchange_7 jobtype_1 jobtype_2 jobtype_3 jobtype_4 jobtype_5 jobtype_6 jobtype_7  better_job RMNUMJOBS EFINDJOB EDISABL RDIS_ALT programs ECHLD_MNYN ELIST EWORKMORE hh_move RENROLL ENJ_NOWRK5 EJB1_PAYHR1 TJB1_ANNSAL1 TJB1_HOURLY1 TJB1_WKLY1 TJB1_BWKLY1 TJB1_MTHLY1 TJB1_SMTHLY1 TJB1_OTHER1 TJB1_GAMT1 EJB2_PAYHR1 TJB2_ANNSAL1 TJB2_HOURLY1 TJB2_WKLY1 TJB2_BWKLY1 TJB2_MTHLY1 TJB2_SMTHLY1 TJB2_OTHER1 TJB2_GAMT1 EJB3_PAYHR1 TJB3_ANNSAL1 TJB3_HOURLY1 TJB3_WKLY1 TJB3_BWKLY1 TJB3_MTHLY1 TJB3_SMTHLY1 TJB3_OTHER1 TJB3_GAMT1 EJB4_PAYHR1 TJB4_ANNSAL1 TJB4_HOURLY1 TJB4_WKLY1 TJB4_BWKLY1 TJB4_MTHLY1 TJB4_SMTHLY1 TJB4_OTHER1 TJB4_GAMT1 EJB5_PAYHR1 TJB5_ANNSAL1 TJB5_HOURLY1 TJB5_WKLY1 TJB5_BWKLY1 TJB5_MTHLY1 TJB5_SMTHLY1 TJB5_OTHER1 TJB5_GAMT1 RMWKWJB{
rename `var' from_`var'
}

// Reshape the data
joinby SSUID ERESIDENCEID panelmonth using "$tempdir/onehalf.dta" 

foreach var in PNUM TAGE ESEX race educ employ TAGE_FB EMS TPEARN earnings TMWKHRS ft_pt occ_1 occ_2 occ_3 occ_4 occ_5 occ_6 occ_7 EINTTYPE whynowork leave_job1 leave_job2 leave_job3 leave_job4 leave_job5 leave_job6 leave_job7 jobchange_1 jobchange_2 jobchange_3 jobchange_4 jobchange_5 jobchange_6 jobchange_7 jobtype_1 jobtype_2 jobtype_3 jobtype_4 jobtype_5 jobtype_6 jobtype_7 better_job RMNUMJOBS EFINDJOB EDISABL RDIS_ALT programs ECHLD_MNYN ELIST EWORKMORE hh_move RENROLL ENJ_NOWRK5 EJB1_PAYHR1 TJB1_ANNSAL1 TJB1_HOURLY1 TJB1_WKLY1 TJB1_BWKLY1 TJB1_MTHLY1 TJB1_SMTHLY1 TJB1_OTHER1 TJB1_GAMT1 EJB2_PAYHR1 TJB2_ANNSAL1 TJB2_HOURLY1 TJB2_WKLY1 TJB2_BWKLY1 TJB2_MTHLY1 TJB2_SMTHLY1 TJB2_OTHER1 TJB2_GAMT1 EJB3_PAYHR1 TJB3_ANNSAL1 TJB3_HOURLY1 TJB3_WKLY1 TJB3_BWKLY1 TJB3_MTHLY1 TJB3_SMTHLY1 TJB3_OTHER1 TJB3_GAMT1 EJB4_PAYHR1 TJB4_ANNSAL1 TJB4_HOURLY1 TJB4_WKLY1 TJB4_BWKLY1 TJB4_MTHLY1 TJB4_SMTHLY1 TJB4_OTHER1 TJB4_GAMT1 EJB5_PAYHR1 TJB5_ANNSAL1 TJB5_HOURLY1 TJB5_WKLY1 TJB5_BWKLY1 TJB5_MTHLY1 TJB5_SMTHLY1 TJB5_OTHER1 TJB5_GAMT1 RMWKWJB{
rename `var' to_`var'
}

rename from_PNUM from_num
rename to_PNUM to_num

rename from_TAGE from_age
rename to_TAGE to_age

rename from_ESEX from_sex
rename to_ESEX to_sex

// Organize the data to make it easier to see the merged results
sort SSUID ERESIDENCEID panelmonth from_num to_num
order  SSUID ERESIDENCEID panelmonth from_num to_num from_age to_age from_sex to_sex from_race to_race from_educ to_educ from_employ to_employ from_TAGE_FB to_TAGE_FB from_EMS to_EMS from_TPEARN to_TPEARN from_earnings to_earnings from_TMWKHRS to_TMWKHRS from_ft_pt to_ft_pt from_occ_1 to_occ_1 from_occ_2 to_occ_2 from_occ_3 to_occ_3 from_occ_4 to_occ_4 from_occ_5 to_occ_5 from_occ_6 to_occ_6 from_occ_7 to_occ_7 from_EINTTYPE to_EINTTYPE from_whynowork to_whynowork from_leave_job1 to_leave_job1 from_leave_job2 to_leave_job2 from_leave_job3 to_leave_job3 from_leave_job4 to_leave_job4 from_leave_job5 to_leave_job5 from_leave_job6 to_leave_job6 from_leave_job7 to_leave_job7 from_jobchange_1 to_jobchange_1 from_jobchange_2 to_jobchange_2 from_jobchange_3 to_jobchange_3 from_jobchange_4 to_jobchange_4 from_jobchange_5 to_jobchange_5 from_jobchange_6 to_jobchange_6 from_jobchange_7 to_jobchange_7 from_jobtype_1 to_jobtype_1 from_jobtype_2 to_jobtype_2 from_jobtype_3 to_jobtype_3 from_jobtype_4 to_jobtype_4 from_jobtype_5 to_jobtype_5 from_jobtype_6 to_jobtype_6 from_jobtype_7 to_jobtype_7 from_better_job to_better_job from_RMNUMJOBS to_RMNUMJOBS from_EFINDJOB to_EFINDJOB from_EDISABL to_EDISABL from_RDIS_ALT to_RDIS_ALT from_programs to_programs from_ECHLD_MNYN to_ECHLD_MNYN from_ELIST to_ELIST from_EWORKMORE to_EWORKMORE from_hh_move to_hh_move from_RENROLL to_RENROLL from_ENJ_NOWRK5 to_ENJ_NOWRK5 from_EJB1_PAYHR1 to_EJB1_PAYHR1 from_TJB1_ANNSAL1 to_TJB1_ANNSAL1 from_TJB1_HOURLY1 to_TJB1_HOURLY1 from_TJB1_WKLY1 to_TJB1_WKLY1 from_TJB1_BWKLY1 to_TJB1_BWKLY1 from_TJB1_MTHLY1 to_TJB1_MTHLY1 from_TJB1_SMTHLY1 to_TJB1_SMTHLY1 from_TJB1_OTHER1 to_TJB1_OTHER1 from_TJB1_GAMT1 to_TJB1_GAMT1 from_EJB2_PAYHR1 to_EJB2_PAYHR1 from_TJB2_ANNSAL1 to_TJB2_ANNSAL1 from_TJB2_HOURLY1 to_TJB2_HOURLY1 from_TJB2_WKLY1 to_TJB2_WKLY1 from_TJB2_BWKLY1 to_TJB2_BWKLY1 from_TJB2_MTHLY1 to_TJB2_MTHLY1 from_TJB2_SMTHLY1 to_TJB2_SMTHLY1 from_TJB2_OTHER1 to_TJB2_OTHER1 from_TJB2_GAMT1 to_TJB2_GAMT1 from_EJB3_PAYHR1 to_EJB3_PAYHR1 from_TJB3_ANNSAL1 to_TJB3_ANNSAL1 from_TJB3_HOURLY1 to_TJB3_HOURLY1 from_TJB3_WKLY1 to_TJB3_WKLY1 from_TJB3_BWKLY1 to_TJB3_BWKLY1 from_TJB3_MTHLY1 to_TJB3_MTHLY1 from_TJB3_SMTHLY1 to_TJB3_SMTHLY1 from_TJB3_OTHER1 to_TJB3_OTHER1 from_TJB3_GAMT1 to_TJB3_GAMT1 from_EJB4_PAYHR1 to_EJB4_PAYHR1 from_TJB4_ANNSAL1 to_TJB4_ANNSAL1 from_TJB4_HOURLY1 to_TJB4_HOURLY1 from_TJB4_WKLY1 to_TJB4_WKLY1 from_TJB4_BWKLY1 to_TJB4_BWKLY1 from_TJB4_MTHLY1 to_TJB4_MTHLY1 from_TJB4_SMTHLY1 to_TJB4_SMTHLY1 from_TJB4_OTHER1 to_TJB4_OTHER1 from_TJB4_GAMT1 to_TJB4_GAMT1 from_EJB5_PAYHR1 to_EJB5_PAYHR1 from_TJB5_ANNSAL1 to_TJB5_ANNSAL1 from_TJB5_HOURLY1 to_TJB5_HOURLY1 from_TJB5_WKLY1 to_TJB5_WKLY1 from_TJB5_BWKLY1 to_TJB5_BWKLY1 from_TJB5_MTHLY1 to_TJB5_MTHLY1 from_TJB5_SMTHLY1 to_TJB5_SMTHLY1 from_TJB5_OTHER1 to_TJB5_OTHER1 from_TJB5_GAMT1 to_TJB5_GAMT1 from_RMWKWJB to_RMWKWJB

* browse // look at the results

// Delete record of individual living with herself
drop if from_num==to_num 

save "$tempdir/allt1pairs.dta", replace

********************************************************************************
* Identify Type 1 people
********************************************************************************
* all in rel_pairs_bymonth are matched in allt1pairs, but not vice versa.
* This is because type 2 people don't have observations in allt1pairs

use "$tempdir/rel_pairs_bymonth.dta", clear

// Combine relationship data with Type 1 data
merge 1:1 SSUID ERESIDENCEID panelmonth from_num to_num using "$tempdir/allt1pairs.dta"

keep if _merge==3
drop 	_merge

// Create a variable identifying these individuals as Type 1
gen pairtype =1

save "$tempdir/t1.dta", replace

********************************************************************************
* Reshape Type 2 data
********************************************************************************

** Import data on type 2 people
use "$SIPP14keep/allmonths14_type2.dta", clear

** Select only necessary variables
keep SSUID ERESIDENCEID panelmonth PNUM ET2_LNO* ET2_SEX* TT2_AGE* TAGE

** reshape the data to have one record for each type 2 person living in a type 1 person's household
reshape long ET2_LNO ET2_SEX TT2_AGE, i(SSUID ERESIDENCEID panelmonth PNUM) j(lno)

rename PNUM from_num
rename TAGE from_age
rename ET2_LNO to_num
rename ET2_SEX to_sex
rename TT2_AGE to_age

** delete variables no longer needed
drop if missing(to_num)

save "$tempdir/type2_pairs.dta", replace

********************************************************************************
* Add type 2 people's demographic information
********************************************************************************

use "$tempdir/rel_pairs_bymonth.dta", clear

// Combine datasets
merge 1:1 SSUID ERESIDENCEID panelmonth from_num to_num using "$tempdir/type2_pairs.dta"

keep if _merge	==3
drop 	_merge

// Create a variable identifying these individuals at Type 1
gen pairtype=2

// Merge type 2 people's data with type 1 people
append using "$tempdir/t1.dta"

label variable pairtype "Is the person a type 1 or type 2 individual?"

tab from_age pairtype

// Recode relationship variable
recode RREL (1=1)(2=2)(3=1)(4=2)(5/19=.), gen(relationship) 
replace relationship=RREL+2 if RREL >=9 & RREL <=13 		// bump rarer codes up to make room for common ones
replace relationship=16 	if RREL==14 | RREL==15 			// combine in-law categories
replace relationship=RREL+1 if RREL >=16 & RREL <=19 		// bump rarer codes up to make room for common ones
replace relationship=3  	if RREL==5 & to_age > from_age 	// parents must be older than children
replace relationship=4  	if RREL==5 & to_age < from_age	// bio child
replace relationship=5  	if RREL==6 & to_age > from_age 	// Step
replace relationship=6  	if RREL==6 & to_age < from_age 	// There are a small number of cases where ages are equal
replace relationship=7  	if RREL==7 & to_age > from_age 	// Adoptive
replace relationship=8  	if RREL==7 & to_age < from_age 	// There are a small number of cases where ages are equal
replace relationship=9  	if RREL==8 & to_age > from_age 	// Grandparent
replace relationship=10 	if RREL==8 & to_age < from_age	// Grandchild

#delimit ;
label define arel 1 "Spouse"
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
                 99 "self" ;

#delimit cr

label values relationship arel

// Peek at the labels and values
fre relationship
fre relationship if to_num < 100

save "$tempdir/relationship_pairs_bymonth.dta", replace
