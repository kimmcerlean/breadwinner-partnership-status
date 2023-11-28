* This is an example setup file. You should create your own setup file named
* setup_username.do that replaces the directories for project code, log files,
* etc to the location for these files on your computer

global homedir "T:"

* STANDARD PROJECT MACROS-------------------------------------------------------
global projcode 		"$homedir/github/Breadwinner-predictors"
global logdir 			"$homedir/Research Projects/Breadwinner-predictors/logs"
global tempdir 			"$homedir/Research Projects/Breadwinner-predictors/data/temp"

// Where you want produced tables, html or putdoc output files to go (NOT SHARED)
global results 		    "$homedir/Research Projects/Breadwinner-predictors/results"

* PROJECT SPECIFIC MACROS-------------------------------------------------------
// SIPP 2014
global SIPP2014 		"/data/sipp/2014"
global SIPP2014_code 	"$projcode/stata/2014"
global SIPP14keep 		"$homedir/Research Projects/Breadwinner-predictors/data"

// SIPP 1996
global SIPP1996			"/data/sipp/1996"
global SIPP1996tm 		"/data/sipp/1996_TM"
global SIPP1996_code 	"$projcode/stata/1996"
global SIPP96keep 		"$homedir/Research Projects/Breadwinner-predictors/data"

// CPS / ACS
global CPS 				"/data/CPS"
global ACS 				"/data/ACS"

// combined data
global combined_data 		"$homedir/Research Projects/Breadwinner-predictors/data/combined"

