*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* breadwinnner-predictorsSIPP14.do
* Kelly Raley, Joanna Pepin, and Kim McErlean
*-------------------------------------------------------------------------------
* The goal of these files is to create estimates of breadwinning over time and
* what determines entrance into breadwinning

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

* The current directory is assumed to be the stata sub-directory.
* cd ".../Breadwinner-predictors/stata" 

clear all 

set maxvar 5500

********************************************************************************
* A2. DATA
********************************************************************************
* This project uses Wave 1-4 of the 2014 SIPP data files as well as the
* Social Security Supplement file. The files can be downloaded here:
* https://www.census.gov/programs-surveys/sipp/data/datasets.html

// Extract the variables for this project
    log using "$logdir/extract_and_format.log",	replace 
    do "$SIPP2014_code/01_sipp14_extract_and_format.do"
    log close

// Merge the waves of data to create two datafiles (type 1 and type 2 records)
    log using "$logdir/merge_waves.log", replace
    do "$SIPP2014_code/02_sipp14_merge_waves.do"
    log close
	
// Recode variables as needed to simplify
	log using "$logdir/variable_recodes.log", replace
	do "$SIPP2014_code/03_sipp14_variable_recodes.do"
	log close

********************************************************************************
* B1. DEMOGRAPHICS AND ANALYTIC SAMPLE
********************************************************************************
* Execute a series of scripts to develop measures of household composition
* This script was adapted from the supplementary materials for the journal article 
* [10.1007/s13524-019-00806-1]
* (https://link.springer.com/article/10.1007/s13524-019-00806-1#SupplementaryMaterial).

// Create a file with demographic information and relationship types
    log using "$logdir/compute_relationships.log", replace
    do "$SIPP2014_code/04_sipp14_compute_relationships.do"
    log close

// Create a monthly file with just household composition, includes type2 people
	log using "$logdir/create_hhcomp.log", replace
	do "$SIPP2014_code/05_sipp14_create_hhcomp.do"
	log close
	
// Create a monthly file with earnings & demographic measures. Create analytic sample.
	log using "$logdir/measures_and_sample.log", replace
	do "$SIPP2014_code/06_sipp14_measures_and_sample.do"
	log close
	
// Merging with HH characteristics to use for predictions
	log using "$logdir/merging_hh_characteristics.log", replace
	do "$SIPP2014_code/07_sipp14_merging_hh_characteristics.do"
	log close
	
********************************************************************************
* B2. BREADWINNER INDICATORS
********************************************************************************
*Execute breadwinner scripts

// Create annual measures of breadwinning
	log using "$logdir/annualize.log", replace
	do "$SIPP2014_code/08_sipp14_annualize.do"
	log close
	
// Create descriptive statistics of who transitions to BW
	log using "$logdir/bw_descriptives.log", replace
	do "$SIPP2014_code/09_sipp14_bw_descriptives.do"
	log close
* 	do "$SIPP2014_code/09a_sipp14_bw_descriptives_matrix.do" // archived descriptives
	

// Create sample descriptive statistics
	log using "$logdir/sample_descriptives.log", replace
	do "$SIPP2014_code/10_sipp14_sample_descriptives.do"
	log close
