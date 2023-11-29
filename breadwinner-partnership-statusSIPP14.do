*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* breadwinnner-partnership-statusSIPP14.do
* Kim McErlean
*-------------------------------------------------------------------------------

* Before running this code, be sure to look at the README.md files

********************************************************************************
* A1. ENVIRONMENT
********************************************************************************
* There are two scripts users need to run before running the first .do file. 
	* First, create a personal setup file using the setup_example.do script as a 
	* template and save this file in the base project directory.

	* Second, run the 00_setup_breadwinner_environment script to set the project 
	* filepaths and macros.

//------------------------------------------------------------------------------

* The current directory is assumed to be the directory where the code is stored
* cd ".../breadwinner-partnership-status" 

clear all 

set maxvar 5500

********************************************************************************
* A2. CREATE DATA FOR ANALYSIS
********************************************************************************
* This project uses Wave 1-4 of the 2014 SIPP data files as well as the
* Social Security Supplement file. The files can be downloaded here:
* https://www.census.gov/programs-surveys/sipp/data/datasets.html

// Extract the variables for this project
    log using "$logdir/extract_and_format.log",	replace 
    do "$projcode/create-data/01_sipp14_extract_and_format.do"
    log close

// Merge the waves of data to create two datafiles (type 1 and type 2 records)
    log using "$logdir/merge_waves.log", replace
    do "$projcode/create-data/02_sipp14_merge_waves.do"
    log close
	
// Recode variables as needed to simplify
	log using "$logdir/variable_recodes.log", replace
	do "$projcode/create-data/03_sipp14_variable_recodes.do"
	log close

// Create a file with demographic information and relationship types
    log using "$logdir/compute_relationships.log", replace
    do "$projcode/create-data/04_sipp14_compute_relationships.do"
    log close

// Create a monthly file with just household composition, includes type2 people
	log using "$logdir/create_hhcomp.log", replace
	do "$projcode/create-data/05_sipp14_create_hhcomp.do"
	log close
	
// Create a monthly file with earnings & demographic measures. Create analytic sample.
	log using "$logdir/measures_and_sample.log", replace
	do "$projcode/06_sipp14_measures_and_sample.do"
	log close
	
// Merging with HH characteristics to use for predictions
	log using "$logdir/merging_hh_characteristics.log", replace
	do "$projcode/create-data/07_sipp14_merging_hh_characteristics.do"
	log close

// Create annual measures of breadwinning
	log using "$logdir/annualize.log", replace
	do "$projcode/create-data/08_sipp14_annualize.do"
	log close
	
// Create descriptive statistics of changes in status within year
	log using "$logdir/bw_descriptives.log", replace
	do "$projcode/create-data/09_sipp14_bw_descriptives.do"
	log close
	
// Create variables for pathways
	log using "$logdir/bw_pathways.log", replace
	do "$projcode/create-data/10_sipp14_bw_pathways.do"
	log close
	
// Create file indicating hh earners
	log using "$logdir/bw_hh_earners.log", replace
	do "$projcode/create-data/11_sipp14_hh_earners.do"
	log close
	
********************************************************************************
* A3. EXECUTE ANALYSIS
********************************************************************************
// Create descriptive tables
	log using "$logdir/bw_descriptive_tables.log", replace
	do "$projcode/analysis/a_descriptive_tables.do"
	log close
	
// Run models
	log using "$logdir/bw_models.log", replace
	do "$projcode/analysis/b_models.do"
	log close

// Run multilevel models
	log using "$logdir/bw_multilevel_models.log", replace
	do "$projcode/analysis/c_multilevel_models.do"
	log close
