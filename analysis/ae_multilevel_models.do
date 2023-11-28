*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* predicting_consequences.do
* Kim McErlean
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
* Multi-level models - this actually allows us to predict BOTH initial level and rate of change?? So is this actually BETTER?!
********************************************************************************
* I am currently following Lecture 2 and 3-4 from Dan's class

use "$tempdir/bw_consequences_long.dta", clear

gen percentile_chg_real = percentile_chg
replace percentile_chg_real = . if time==1

// spagplot percentile_ time, id(id) nofit

// spagplot percentile_ time if id>100 & id <200, id(id) nofit

gen time2 = time-1
sum percentile_chg

mixed thearn_ i.educ_gp|| id: time2, mle var
mixed thearn_ i.time2 i.educ_gp|| id: time2, mle var
mixed thearn_ i.time2##i.educ_gp|| id: time2, mle var
mixed thearn_ i.time2##i.race_gp|| id: time2, mle var
mixed thearn_ i.time2##ib3.pathway|| id: time2, mle var

********************************************************************************
* Models for heterogeneity paper
********************************************************************************
*Just education
mixed percentile_ i.time2##ib3.educ_gp|| id: time2, mle var
estimates store m1
outreg2 using "$results/heterogeneity_models.xls", sideway stats(coef) label ctitle(M1) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace

mixed percentile_ i.time2##ib3.educ_gp thearn_|| id: time2, mle var // do I control for income or is that collinear?

*Just race
mixed percentile_ i.time2##i.race_gp|| id: time2, mle var
estimates store m2
outreg2 using "$results/heterogeneity_models.xls", sideway stats(coef) label ctitle(M2) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

*Race + education
mixed percentile_ i.time2 i.race_gp ib3.educ_gp i.time2#i.race_gp i.time2#ib3.educ_gp || id: time2, mle var
estimates store m3
outreg2 using "$results/heterogeneity_models.xls", sideway stats(coef) label ctitle(M3) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

* Race + education + pathway (mediation)
mixed percentile_ i.time2 ib3.educ_gp i.race_gp ib3.pathway i.time2#ib3.educ_gp i.time2#i.race_gp i.time2#ib3.pathway || id: time2, mle var
estimates store m4
outreg2 using "$results/heterogeneity_models.xls", sideway stats(coef) label ctitle(M4) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

* three way interaction for moderation
mixed percentile_ i.time2 ib3.educ_gp ib3.pathway i.time2##i.race_gp##ib3.pathway i.time2##ib3.educ_gp##ib3.pathway || id: time2, mle var
estimates store m5
outreg2 using "$results/heterogeneity_models.xls", sideway stats(coef) label ctitle(M5) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

estimates stats m1 m2 m3 m4 m5

********************************************************************************
* Exploration
********************************************************************************
// okay don't get r-squared but can do LR tests?

// unconditional means model 
mixed percentile_ || id: , mle var // 4.95 - this is the same as doing sum percentile_
estimates store m0a

// unconditional growth model
mixed percentile_ time2 || id: time2, cov(un) mle var // this is the same as below individual

/*

------------------------------------------------------------------------------
 percentile_ | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
       time2 |  -.3730887   .0760333    -4.91   0.000    -.5221111   -.2240662
       _cons |    5.14475   .0967562    53.17   0.000     4.955112    5.334389
------------------------------------------------------------------------------
*/


mixed percentile_ time2 || id: time2, mle var // results same as above, it's the random effects parameters that are different
estimates store m0

// adding predictors - okay but probably need to INTERACT with time?! (see slide 35 - and I think what I did for growth curves?)
mixed percentile_ time2 i.educ_gp || id: time2, mle var

/* is this the same as this? tabstat percentile_, by(educ_gp)
Okay YES - so this is TOTAL difference

-------------------------------------------------------------------------------
  percentile_ | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
        time2 |  -.3730887   .0760332    -4.91   0.000     -.522111   -.2240664
              |
      educ_gp |
Some College  |   .9912778   .1782986     5.56   0.000     .6418188    1.340737
College Plus  |   3.377979   .1809451    18.67   0.000     3.023334    3.732625
              |
        _cons |   3.750312   .1300565    28.84   0.000     3.495406    4.005219
-------------------------------------------------------------------------------


     educ_gp |      Mean
-------------+----------
  Hs or Less |  3.563768
Some College |  4.555046
College Plus |  6.941748
-------------+----------
       Total |  4.958206
------------------------
SC - HS = 0.995
College - HS  = 3.38 

*/

mixed percentile_ time2 i.race_gp || id: time2, mle var
mixed percentile_ time2 i.pathway || id: time2, mle var

// gen path_time = pathway*time
// gen educ_time = educ_gp*time
// gen race_time = race_gp*time

mixed percentile_ i.time2##i.educ_gp|| id: time2, mle var
estimates store m1

/*
---------------------------------------------------------------------------------
    percentile_ | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
----------------+----------------------------------------------------------------
        1.time2 |  -.4318841   .1278405    -3.38   0.001    -.6824468   -.1813213
                |
        educ_gp |
  Some College  |   1.052094   .2004667     5.25   0.000     .6591866    1.445002
  College Plus  |    3.22029   .2034423    15.83   0.000      2.82155    3.619029
                |
  time2#educ_gp |
1#Some College  |  -.1216328   .1832649    -0.66   0.507    -.4808253    .2375598
1#College Plus  |   .3153792   .1859851     1.70   0.090    -.0491448    .6799032
                |
          _cons |    3.77971     .13984    27.03   0.000     3.505629    4.053792
---------------------------------------------------------------------------------

so the coefficients on own are differences in INITIAL level
then the interaction is the difference in AVERAGE change

tabstat percentile_ if time==1, by(educ_gp)
sc-hs = 1.05
coll-hs = 3.22

     educ_gp |      Mean
-------------+----------
  Hs or Less |   3.77971
Some College |  4.831804
College Plus |         7
-------------+----------
       Total |   5.14475
	   
regress percentile_chg i.educ_gp // these are the same
mixed percentile_ i.time2##i.educ_gp|| id: time2, mle var // these are the same
tabstat percentile_chg, by(educ_gp)
sc-hs = -0.12
coll-hs = 0.314

     educ_gp |      Mean
-------------+----------
  Hs or Less | -.4318841
Some College | -.5535168
College Plus | -.1165049
-------------+----------
       Total | -.3730887
------------------------


tabstat percentile_ if time==2, by(educ_gp)	

     educ_gp |      Mean
-------------+----------
  Hs or Less |  3.347826
Some College |  4.278287
College Plus |  6.883495
-------------+----------
       Total |  4.771662
------------------------

*/

mixed percentile_ i.time2##i.race_gp|| id: time2, mle var
estimates store m2

mixed percentile_ i.time2##i.race_gp i.educ_gp|| id: time2, mle var // control for education
mixed percentile_ i.time2 i.race_gp i.educ_gp i.time2#i.race_gp i.time2#i.educ_gp || id: time2, mle var // control for education
estimates store m2a

/*
-------------------------------------------------------------------------------
  percentile_ | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
      1.time2 |  -.4158607   .1046219    -3.97   0.000    -.6209159   -.2108055
              |
      race_gp |
       Black  |  -1.743542   .2505271    -6.96   0.000    -2.234567   -1.252518
    Hispanic  |  -1.393981   .2376892    -5.86   0.000    -1.859843   -.9281186
           4  |  -.5880744   .3319552    -1.77   0.076    -1.238695    .0625459
              |
time2#race_gp |
     1#Black  |  -.0469964   .2080447    -0.23   0.821    -.4547566    .3607638
  1#Hispanic  |   .2574449   .1973838     1.30   0.192    -.1294202      .64431
         1 4  |  -.0209209    .275665    -0.08   0.940    -.5612143    .5193725
              |
        _cons |   5.794971   .1259855    46.00   0.000     5.548044    6.041898
-------------------------------------------------------------------------------
*/


mixed percentile_ i.time2##ib3.pathway|| id: time2, mle var
estimates store m3

/*
-----------------------------------------------------------------------------------------
            percentile_ | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
------------------------+----------------------------------------------------------------
                1.time2 |  -.4236641   .1189191    -3.56   0.000    -.6567412   -.1905871
                        |
                pathway |
  Mom Up, Not employed  |  -4.939376   .1928794   -25.61   0.000    -5.317413   -4.561339
      Mom Up, employed  |   .8208374   .2425991     3.38   0.001     .3453519    1.296323
          Partner Down  |   1.499158   .2143926     6.99   0.000     1.078956    1.919359
          Partner Left  |   .0251105   .2480669     0.10   0.919    -.4610917    .5113127
       Other HH Change  |   -1.17899   .2032718    -5.80   0.000    -1.577395   -.7805844
                        |
          time2#pathway |
1#Mom Up, Not employed  |   1.758616   .1792424     9.81   0.000     1.407307    2.109924
    1#Mom Up, employed  |   2.116733   .2254468     9.39   0.000     1.674866    2.558601
        1#Partner Down  |  -2.134957   .1992346   -10.72   0.000    -2.525449   -1.744464
        1#Partner Left  |  -.9868622    .230528    -4.28   0.000    -1.438689   -.5350355
     1#Other HH Change  |  -.7158708   .1889001    -3.79   0.000    -1.086108   -.3456334
                        |
                  _cons |   6.080153   .1279666    47.51   0.000     5.829343    6.330963
-----------------------------------------------------------------------------------------
*/

// but am I meant to test these over the unconditional means / growth? actually maybe
lrtest m1 m2 // not
lrtest m1 m3 // sig diff
lrtest m2 m3 // sig diff
lrtest m0 m1 // sig diff
lrtest m0 m2 // sig diff
lrtest m0 m3 // sig diff

estimates stats m0 m1 m2 m3 // unconditional, educ, race, pathway
/*


-----------------------------------------------------------------------------
       Model |          N   ll(null)  ll(model)      df        AIC        BIC
-------------+---------------------------------------------------------------
          m0 |      1,962          .  -4611.181       5   9232.362   9260.271
          m1 |      1,962          .  -4453.745       9    8925.49   8975.726
          m2 |      1,962          .  -4573.731      11   9169.463   9230.862
          m3 |      1,962          .  -4079.851      15   8189.702   8273.428
-----------------------------------------------------------------------------

To compare models using AIC, you need to calculate the AIC of each model. If a model is more than 2 AIC units lower than another, then it is considered significantly better than that model.

*/


*Attempting 3-way interaction (I could also interact time and pathway and do for each education group separately?)
mixed percentile_ i.time2 i.educ_gp ib3.pathway i.time2##i.educ_gp##ib3.pathway || id: time2, mle var // Model 6
estimates store m4
outreg2 using "$results/multilevel_interactions.xls", sideway stats(coef) label ctitle(Educ) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace

lrtest m1 m4 // compare interaction to just educ - sig
lrtest m3 m4 // compare interaction to just path - sig

estimates stats m1 m3 m4 // AIC is lowest with interaction...

mixed percentile_ i.time2 i.race_gp ib3.pathway i.time2##i.race_gp##ib3.pathway || id: time2, mle var // Model 7
estimates store m5
outreg2 using "$results/multilevel_interactions.xls", sideway stats(coef) label ctitle(Race) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

mixed percentile_ i.time2 i.educ_gp ib3.pathway i.time2##i.race_gp##ib3.pathway i.time2##i.educ_gp##ib3.pathway || id: time2, mle var // Model 7a - want race and educ in same model
outreg2 using "$results/multilevel_interactions.xls", sideway stats(coef) label ctitle(Both) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

lrtest m2 m5 // compare interaction to just race - sig
lrtest m3 m5 // compare interaction to just path - sig

estimates stats m2 m3 m5 // no real differences between m3 and m5 (BIC actually higher for m5, AIC very similar)

estimates stats m1 m2 m3 m4 m5


mixed percentile_ i.time2##ib3.pathway if educ_gp==1 || id: time2, mle var
mixed percentile_ i.time2##ib3.pathway if educ_gp==2 || id: time2, mle var // makes easier to compare across
mixed percentile_ i.time2##ib3.pathway if educ_gp==3 || id: time2, mle var

mixed percentile_ i.time2##ib3.pathway if race_gp==1 || id: time2, mle var
mixed percentile_ i.time2##ib3.pathway if race_gp==2 || id: time2, mle var
mixed percentile_ i.time2##ib3.pathway if race_gp==3 || id: time2, mle var

** Do need to put pathway and demos in same model
mixed percentile_ i.time2 i.educ_gp ib3.pathway i.time2#i.educ_gp i.time2#ib3.pathway || id: time2, mle var
estimates store m6
outreg2 using "$results/multilevel_interactions.xls", sideway stats(coef) label ctitle(Educ_Path) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

mixed percentile_ i.time2 i.race_gp ib3.pathway i.time2#i.race_gp i.time2#ib3.pathway || id: time2, mle var
estimates store m7 // but this is actually model 5
// can I compare race coefficient between model 2 and 5? (as indicator of change)
outreg2 using "$results/multilevel_interactions.xls", sideway stats(coef) label ctitle(Race_Path) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

mixed percentile_ i.time2 i.race_gp ib3.pathway i.educ_gp i.time2#i.race_gp i.time2#ib3.pathway i.time2#i.educ_gp  || id: time2, mle var // also add education
estimates store m7a

estimates stats m1 m2 m6 m7

/* test _b[m2]2.race_gp = _b[m7]2.race_gp
test [m2_mean]2.race_gp = [m7_mean]2.race_gp
lincom [m2]2.race_gp - [m7]2.race_gp
suest m2 m7
*/

// descriptive things
tabstat percentile_ if time==1, by(educ_gp) stats(p50 mean)
tabstat percentile_ if time==2, by(educ_gp) stats(p50 mean)

tabstat percentile_ if time==1, by(race_gp) stats(p50 mean)
tabstat percentile_ if time==2, by(race_gp) stats(p50 mean)

tabstat percentile_ if time==1, by(pathway) stats(p50 mean)
tabstat percentile_ if time==2, by(pathway) stats(p50 mean)

***********************************************************
**# Bookmark #1
* For JFEI
***********************************************************

mixed thearn_ i.time2##ib2.rel_status_detail || id: time2, mle var
mixed thearn_ i.time2 i.educ_gp i.race_gp ib2.rel_status_detail i.time2#i.educ_gp i.time2#i.race_gp i.time2#ib2.rel_status_detail || id: time2, mle var // okay one thing is that there is no way to topcode change, so these numbers are a little different

sum thearn_, detail
gen thearn_topcode=thearn_
replace thearn_topcode = `r(p99)' if thearn_>`r(p99)'
sum thearn_topcode, detail

mixed thearn_topcode i.time2##ib2.rel_status_detail || id: time2, mle var
outreg2 using "$results/multilevel_jfei.xls", sideway stats(coef) label ctitle(M1) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
mixed thearn_topcode i.time2 i.educ_gp i.race_gp ib2.rel_status_detail i.time2#i.educ_gp i.time2#i.race_gp i.time2#ib2.rel_status_detail || id: time2, mle var
outreg2 using "$results/multilevel_jfei.xls", sideway stats(coef) label ctitle(M2) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

tabstat percentile_ if time==1, by(rel_status_detail)	
tabstat percentile_ if time==2, by(rel_status_detail)	

tabstat thearn_topcode if time==1, by(rel_status_detail)	
tabstat thearn_topcode if time==2, by(rel_status_detail)	

tabstat earnings_ if time==1, by(rel_status_detail)	
tabstat earnings_ if time==2, by(rel_status_detail)	

tab rel_status_detail in_pov_ if time==1, row
tab rel_status_detail in_pov_ if time==2, row

mixed percentile_ i.time2##ib2.rel_status_detail || id: time2, mle var
outreg2 using "$results/multilevel_jfei.xls", sideway stats(coef) label ctitle(M3) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
mixed percentile_ i.time2 i.educ_gp i.race_gp ib2.rel_status_detail i.time2#i.educ_gp i.time2#i.race_gp i.time2#ib2.rel_status_detail || id: time2, mle var
outreg2 using "$results/multilevel_jfei.xls", sideway stats(coef) label ctitle(M4) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

// melogit in_pov_ i.time2##ib2.rel_status_detail || id: time2, or
//meqrlogit in_pov_ i.time2##ib2.rel_status_detail || id: time2, or

melogit in_pov_ i.time2##ib2.rel_status_detail || id: //, or
outreg2 using "$results/multilevel_jfei.xls", sideway stats(coef) label ctitle(M5) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
melogit in_pov_ i.time2 i.educ_gp i.race_gp ib2.rel_status_detail i.time2#i.educ_gp i.time2#i.race_gp i.time2#ib2.rel_status_detail || id: , or
outreg2 using "$results/multilevel_jfei.xls", sideway stats(coef) label ctitle(M6) dec(2) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

// three-way interactions
mixed thearn_topcode i.time2 i.educ_gp ib3.rel_status_detail i.time2##i.educ_gp##ib3.rel_status_detail || id: time2, mle var // college single = sig higher gains, which makes sense
mixed thearn_topcode i.time2 i.race_gp ib3.rel_status_detail i.time2##i.race_gp##ib3.rel_status_detail || id: time2, mle var // none of this is sig

melogit in_pov_ i.time2 i.educ_gp ib3.rel_status_detail i.time2##i.educ_gp##ib3.rel_status_detail  || id: //, or - same here, sig less likely to move into pov
melogit in_pov_ i.time2 i.race_gp ib3.rel_status_detail i.time2##i.race_gp##ib3.rel_status_detail  || id: //, or - nothing sig here

// descriptives
tab rel_status_detail in_pov_ if time==1 & educ_gp==1, row // pre
tab rel_status_detail in_pov_ if time==1 & educ_gp==2, row // pre
tab rel_status_detail in_pov_ if time==1 & educ_gp==3, row // pre
tab rel_status_detail in_pov_ if time==1 & race_gp==1, row // pre
tab rel_status_detail in_pov_ if time==1 & race_gp==2, row // pre
tab rel_status_detail in_pov_ if time==1 & race_gp==3, row // pre

tab rel_status_detail in_pov_ if time==2 & educ_gp==1, row // post
tab rel_status_detail in_pov_ if time==2 & educ_gp==2, row // post
tab rel_status_detail in_pov_ if time==2 & educ_gp==3, row // post
tab rel_status_detail in_pov_ if time==2 & race_gp==1, row // post
tab rel_status_detail in_pov_ if time==2 & race_gp==2, row // post
tab rel_status_detail in_pov_ if time==2 & race_gp==3, row // post
/*
save "$tempdir/bw_consequences_long.dta", replace

statsby "regress percentile_ time2" _b[_cons] _se[_cons] _b[time] ///
 _se[time] (e(rmse)^2) e(r2), by(id)
gen b0 = _stat_1
gen seb0 = _stat_2
gen b1 = _stat_3
gen seb1 = _stat_4
gen sigma2 = _stat_5
gen r2 = _stat_6
label var b0 "intercept"
label var b1 "slope"
sum b0 b1 sigma2
corr b0 b1
list b0 b1 sigma2 r2, clean

/*
. sum b0 b1 sigma2


    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
          b0 |        981     5.14475    3.032047          1         10
          b1 |        981   -.3730887    2.382643         -9          8
      sigma2 |        981           0           0          0          0

	 
	 
sum percentile_ if time==1 // mean = 5.14 // okay it becomes a match when I update time (need it to startat 0, not 1)
sum percentile_ if time==2 // mean = 4.77 - okay so that difference is -0.37
sum percentile_chg // -0.37	  

this correlation is that higher initial levels have faster decline?


             |       b0       b1
-------------+------------------
          b0 |   1.0000
          b1 |  -0.4555   1.0000

*/

*/
********************************************************************************
**# Exploring other models
********************************************************************************
*Original model:
mixed percentile_ i.time2##ib3.educ_gp|| id: time2, mle var
mixed percentile_ i.time2##ib3.educ_gp thearn_|| id: , mle var // these the same
mixed percentile_ i.time2 ib3.educ_gp thearn_ i.time2#ib3.educ_gp c.thearn_#ib3.educ_gp  || id: time2, mle var // i have no idea what is happening here to be honest

tab percentile_ if time2==0 // probably have enough to do what she said, I am just confused
 
mixed percentile_ i.time2##ib3.educ_gp|| id: time2, mle var

mixed percentile_ i.time2|| id: , mle var
mixed percentile_ i.time2|| id: time2 , mle var

mixed percentile_ i.time2##ib3.educ_gp|| pre_percentile:, mle var // is this what she means? or do I also need ot interact?
mixed percentile_ i.time2##ib3.educ_gp pre_percentile##ib3.educ_gp || pre_percentile:, mle var // is this what she means? or do I also need ot interact?

mixed percentile_chg ib3.educ_gp|| pre_percentile: , mle var // is this what she means? this sort of matches when I ran regression and controlled for t0 income
mixed percentile_chg ib3.educ_gp##pre_percentile || pre_percentile: , mle var // is this what she means? this sort of matches when I ran regression and controlled for t0 income

***********************************************************
*XT reg
***********************************************************
// xtset pvar tvar1
xtset id time
xtreg percentile_ ib3.educ_gp, fe // is this not working bc education is fixed?
xtreg percentile_ ib3.educ_gp i.time // I think this is truly just estimating the effect of percentile across panels, but i want CHANGE - but not working because my variables are not time varying
xtreg percentile_ ib3.educ_gp##i.time  // this is exactly the same as MLM. Is this mixed effects?
mixed percentile_ i.time2##ib3.educ_gp|| id: time2, mle var 

xtreg percentile_ ib3.educ_gp##i.time ib3.educ_gp##c.thearn_, fe
xtreg percentile_ ib3.educ_gp##i.time ib3.educ_gp##c.thearn_

areg percentile_ ib3.educ_gp, absorb(id)