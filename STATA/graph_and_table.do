clear all
***setup environment***
cd "D:\Documents\Dropbox\Dropbox\ATUS 2020 project\working_yb\reorganization"
global wkdir `c(pwd)' 

cap mkdir output
cap mkdir cleaned_data

cd "$wkdir\cleaned_data"

log close _all
log using "reorganization $S_DATE",replace

gl datapath = "$wkdir\cleaned_data" 
gl outpath="$wkdir\output"
gl graphpath="$outpath\graph"
gl tablepath="$outpath\table"

************global variable***************
global parenting   childcare childeduc childmed childcare_passive childcare_passive13 
global parentingi  childcarei childeduci childmedi childcare_passivei childcare_passive13i
* playingwith
global parentingdt physicalcare readingto artscrafts sportswith planningfor lookingafter 
global parentingdti physicalcarei readingtoi playingwithi artscraftsi sportswithi planningfori lookingafteri 

gl work t_work t_work2 t_work3 commute
gl domesticlabor housework maintenance foodprep householdmanagement
gl selfcare asleep sleepless sleep grooming hlthselfcare personalactivity personalcare
gl leisure leisure social leisuret
gl sports sports sportsparticipate

gl hetero male hsgrad somecol colgrad month1_3 fulltime labourstatus

gl schoolopeni county_openi cbsa_openi
gl schooldistance  county_distance  cbsa_distance 
gl control male childnum eduy  i.occupation_cps married

gl outcome childcare childeduc childpassive childmed  housework maintenance  foodprep leisuret sports work
*labourstatus
*labourstatus wfh famstructure
gl FE tumonth
// gl countyopeni_teach_county countyopeni_hybrid countyopeni_in_person countyopeni_online teach_county_hybrid teach_county_online
// gl cbsaopeni_teach_cbsa cbsaopeni_hybrid cbsaopeni_in_person cbsaopeni_online teach_cbsa_hybrid teach_cbsa_online


use "sample4_reorganized.dta",clear
******************graph***************
***mean by different samples

cd "$tablepath"
gl heter male hsgrad
gl outcome childcare childeduc childcare_passive childmed  housework maintenance  foodprep leisuret sports t_work3 



label var childeduc "Schooling care" 
label var childcare_passive "Passive care"
label var childcare "Active care"
label var childmed "Medical care"
label var maintenance "Maintenance"  
label var  leisuret "Socializing"
label var sports "Sports"
label var covidyr "COVID year"
label var bts "back-to-school month"

replace childnum=. if childnum<0
drop if childnum==.
keep if occupation_c!=.
drop if missing(fips)
drop if missing(teach_county)
save "$datapath\county_sample.dta",replace

use "$datapath\county_sample.dta",clear
clonevar childpassive=childcare_passive
clonevar work=t_work3


cap erase "sample4sum_county.rtf"
eststo clear
 eststo sumstats :estpost sum $outcome childnum eduy married 
 esttab sumstats using sample4sum_county.rtf ,  append  label ///
	cells("count  mean(fmt(3))  min max sd(fmt(3)) ") ///
	noobs title(whole sample summary statistics) 

eststo clear
 eststo sumstats :estpost sum $outcome childnum eduy married covidyr bts teach_cbsa_inhyb teach_cbsa_online  
 esttab sumstats using appx_sample4sum_cbsa.rtf ,  append  label ///
	cells("count  mean(fmt(3))  min max sd ") ///
	noobs title(whole sample summary statistics) 
	
*****ttest--sample mean by binary variables

cap erase "sample4ttest0817.rtf"
foreach h of varlist $heter{
local a: label( `h') 0
local b: label( `h') 1
local c: var label `h'
estpost ttest $outcome ,by(`h')
esttab using sample4ttest0817.rtf , ///
	cells("N_1 mu_1(fmt(3)) N_2 mu_2(fmt(3)) p(star fm(3))") star( * 0.10 ** 0.05 *** 0.01) ///
	noobs compress append label title("T-test of time use by `c', sample1 represents `a', sample2 represents `b'") 
}

***20221011correction***
gl control male childnum eduy  i.occupation_cps married
use "$wkdir\cleaned_data\temp_county_1012.dta",clear
cd "$tablepath"
qui:{
cap erase "Table_county1_base_q1_bts_covid.rtf"
local i=0
eststo clear
foreach y_var in  $outcome {
local a: var label `y_var'
local i=`i'+1
areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year ,a(county) cluster(county)
est store m`i'
}
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 using Table_county1_base_q1_bts_covid.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  ///
	title(\textbf{Baseline Results})  
eststo clear
}

cap gen blwbac=1-colgrad
qui:{
foreach h1 in colgrad blwbac{
foreach h2 in  inhyb online{
cap erase "Table_county1_base_q1_`h1'_`h2'.rtf"
local i=0
eststo clear
foreach y_var in  $outcome {
local a: var label `y_var'
local i=`i'+1
areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if `h1'&teach_county_`h2',a(county) cluster(county)
est store m`i'
}
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 using Table_county1_base_q1_`h1'_`h2'.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  ///
	title(\textbf{Baseline Results})  
eststo clear
}
}
}
cap drop blwbac

cap gen nwfh=1-wfh
qui:{
foreach h1 in nwfh wfh{
foreach h2 in  inhyb online{
cap erase "Table_county1_base_q1_`h1'_`h2'.rtf"
local i=0
eststo clear
foreach y_var in  t_work3 t_work t_work2{
local a: var label `y_var'
local i=`i'+1
areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if `h1'&teach_county_`h2',a(county) cluster(county)
est store m`i'
}
esttab m1 m2 m3  using Table_county1_base_q1_`h1'_`h2'.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  ///
	title(\textbf{Baseline Results})  
eststo clear
}
}
}
cap drop nwfh


cap gen female=1-male
qui:{
foreach h1 in male female{
foreach h2 in  inhyb online{
cap erase "Table_county1_base_q1_`h1'_`h2'.rtf"
local i=0
eststo clear
foreach y_var in  $outcome {
local a: var label `y_var'
local i=`i'+1
areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if `h1'&teach_county_`h2',a(county) cluster(county)
est store m`i'
}
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 using Table_county1_base_q1_`h1'_`h2'.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  ///
	title(\textbf{Baseline Results})  
eststo clear
}
}
}
cap drop female




qui:{
cap erase "Table_county1_base_q1_bts_covid_forhyb.rtf"
local i=0
eststo clear
foreach y_var in  $outcome {
local a: var label `y_var'
local i=`i'+1
areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if teach_county_inhyb,a(county) cluster(county)
est store m`i'
}
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 using Table_county1_base_q1_bts_covid_forhyb.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  ///
	title(\textbf{Baseline Results})  
eststo clear
}

qui:{
cap erase "Table_county1_base_q1_bts_covid_foronline.rtf"
local i=0
eststo clear
foreach y_var in  $outcome {
local a: var label `y_var'
local i=`i'+1
areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if teach_county_online,a(county) cluster(county)
est store m`i'
}
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 using Table_county1_base_q1_bts_covid_foronline.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  ///
	title(\textbf{Baseline Results})  
eststo clear
}

qui{
cap erase "Table_county1_base_q1_bts_covid_formen.rtf"
local i=0
eststo clear
foreach y_var in  $outcome {
local a: var label `y_var'
local i=`i'+1
areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if male,a(county) cluster(county)
est store m`i'
}
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 using Table_county1_base_q1_bts_covid_formen.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  ///
	title(\textbf{Baseline Results})  
eststo clear
}

qui{
cap erase "Table_county1_base_q1_bts_covid_forwomen.rtf"
local i=0
eststo clear
foreach y_var in  $outcome {
local a: var label `y_var'
local i=`i'+1
areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if !male,a(county) cluster(county)
est store m`i'
}
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 using Table_county1_base_q1_bts_covid_forwomen.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  ///
	title(\textbf{Baseline Results})  
eststo clear
}


qui:{
cap erase "Table_county1_base_q3_tripple.rtf"
local i=0
eststo clear
foreach y_var in  $outcome {
local a: var label `y_var'
local i=`i'+1
areg `y_var' i.bts##i.teach_county_online##covidyr  $control i.tumonth c.year ,a(county) cluster(county)
est store m`i'
}
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 using Table_county1_base_q3_tripple.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  ///
	title(\textbf{Baseline Results})  
eststo clear
}

cap gen female=1-male
qui:{
foreach h in male female{
cap erase "Table_county1_base_q3_`h'.rtf"
local i=0
eststo clear
foreach y_var in  $outcome {
local a: var label `y_var'
local i=`i'+1
areg `y_var' i.bts##i.teach_county_online##covidyr  $control i.tumonth c.year if `h' ,a(county) cluster(county)
est store m`i'
}
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 using Table_county1_base_q3_`h'.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  ///
	title(\textbf{Baseline Results})  
eststo clear
}
}
cap drop female

***cbsa
use "$datapath\cbsa_sample.dta",clear
clonevar childpassive=childcare_passive
clonevar work=t_work3
save "$datapath\cbsa_sample.dta", replace
qui:{
cap erase "Table_cbsa1_base_q1_bts_covid.rtf"
local i=0
eststo clear
foreach y_var in  $outcome {
local a: var label `y_var'
local i=`i'+1
areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year ,a(cbsa) cluster(cbsa)
est store m`i'
}
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 using Table_cbsa1_base_q1_bts_covid.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  ///
	title(\textbf{Baseline Results})  
eststo clear
}

cap gen blwbac=1-colgrad
qui:{
foreach h1 in colgrad blwbac{
foreach h2 in  inhyb online{
cap erase "Table_cbsa1_base_q1_`h1'_`h2'.rtf"
local i=0
eststo clear
foreach y_var in  $outcome {
local a: var label `y_var'
local i=`i'+1
areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if `h1'&teach_cbsa_`h2',a(cbsa) cluster(cbsa)
est store m`i'
}
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 using Table_cbsa1_base_q1_`h1'_`h2'.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  ///
	title(\textbf{Baseline Results})  
eststo clear
}
}
}
cap drop blwbac

cap gen nwfh=1-wfh
qui:{
foreach h1 in nwfh wfh{
foreach h2 in  inhyb online{
cap erase "Table_cbsa1_base_q1_`h1'_`h2'.rtf"
local i=0
eststo clear
foreach y_var in  t_work3 t_work t_work2{
local a: var label `y_var'
local i=`i'+1
areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if `h1'&teach_cbsa_`h2',a(cbsa) cluster(cbsa)
est store m`i'
}
esttab m1 m2 m3  using Table_cbsa1_base_q1_`h1'_`h2'.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  ///
	title(\textbf{Baseline Results})  
eststo clear
}
}
}
cap drop nwfh


cap gen female=1-male
qui:{
foreach h1 in male female{
foreach h2 in  inhyb online{
cap erase "Table_cbsa1_base_q1_`h1'_`h2'.rtf"
local i=0
eststo clear
foreach y_var in  $outcome {
local a: var label `y_var'
local i=`i'+1
areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if `h1'&teach_cbsa_`h2',a(cbsa) cluster(cbsa)
est store m`i'
}
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 using Table_cbsa1_base_q1_`h1'_`h2'.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  ///
	title(\textbf{Baseline Results})  
eststo clear
}
}
}
cap drop female



qui:{
cap erase "Table_cbsa1_base_q3_tripple.rtf"
local i=0
eststo clear
foreach y_var in  $outcome {
local a: var label `y_var'
local i=`i'+1
areg `y_var' i.bts##i.teach_cbsa_online##covidyr  $control i.tumonth c.year ,a(cbsa) cluster(cbsa)
est store m`i'
}
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 using Table_cbsa1_base_q3_tripple.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  ///
	title(\textbf{Baseline Results})  
eststo clear
}

***q1:figure***
**overall**

cd "$graphpath"
// drop sports
// clonevar sports= sportsparticipate

set scheme s1color

qui:{
foreach y_var in  $outcome {
gl control male childnum eduy  i.occupation_cps married
areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if teach_county_online,a(county) cluster(county)
scalar b_`y_var'_online_base = _b[1.bts#1.covidyr]
scalar se_`y_var'_online_base = _se[1.bts#1.covidyr]

areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if teach_county_inhyb,a(county) cluster(county)
scalar b_`y_var'_inhyb_base = _b[1.bts#1.covidyr]
scalar se_`y_var'_inhyb_base = _se[1.bts#1.covidyr]

***hetero-gender
gl control childnum eduy  i.occupation_cps married
**hetero-female
areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if teach_county_online&!male,a(county) cluster(county)
scalar b_`y_var'_online_female = _b[1.bts#1.covidyr]
scalar se_`y_var'_online_female = _se[1.bts#1.covidyr]

areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if teach_county_inhyb&!male,a(county) cluster(county)
scalar b_`y_var'_inhyb_female = _b[1.bts#1.covidyr]
scalar se_`y_var'_inhyb_female = _se[1.bts#1.covidyr]
**hetero-male
areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if teach_county_online&male,a(county) cluster(county)
scalar b_`y_var'_online_male = _b[1.bts#1.covidyr]
scalar se_`y_var'_online_male = _se[1.bts#1.covidyr]

areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if teach_county_inhyb&male,a(county) cluster(county)
scalar b_`y_var'_inhyb_male = _b[1.bts#1.covidyr]
scalar se_`y_var'_inhyb_male = _se[1.bts#1.covidyr]

***hetero-edu
gl control childnum male  i.occupation_cps married
**hetero-below bachelor
areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if teach_county_online&!colgrad,a(county) cluster(county)
scalar b_`y_var'_online_blwba = _b[1.bts#1.covidyr]
scalar se_`y_var'_online_blwba = _se[1.bts#1.covidyr]

areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if teach_county_inhyb&!colgrad,a(county) cluster(county)
scalar b_`y_var'_inhyb_blwba = _b[1.bts#1.covidyr]
scalar se_`y_var'_inhyb_blwba = _se[1.bts#1.covidyr]
**hetero-bachelor or above
areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if teach_county_online&colgrad,a(county) cluster(county)
scalar b_`y_var'_online_ba = _b[1.bts#1.covidyr]
scalar se_`y_var'_online_ba = _se[1.bts#1.covidyr]

areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if teach_county_inhyb&colgrad,a(county) cluster(county)
scalar b_`y_var'_inhyb_ba = _b[1.bts#1.covidyr]
scalar se_`y_var'_inhyb_ba = _se[1.bts#1.covidyr]
}
}

***hetero-wfh

gl control childnum male eduy  i.occupation_cps married

qui:{
foreach y_var in  t_work3 t_work t_work2 {
**hetero-not wfh
areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if teach_county_online&!wfh&(telfs==1|telfs==2),a(county) cluster(county)
scalar b_`y_var'_online_nowfh = _b[1.bts#1.covidyr]
scalar se_`y_var'_online_nowfh = _se[1.bts#1.covidyr]

areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if teach_county_inhyb&!wfh&(telfs==1|telfs==2),a(county) cluster(county)
scalar b_`y_var'_inhyb_nowfh = _b[1.bts#1.covidyr]
scalar se_`y_var'_inhyb_nowfh = _se[1.bts#1.covidyr]
**hetero-bachelor or above
areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if teach_county_online&wfh&(telfs==1|telfs==2),a(county) cluster(county)
scalar b_`y_var'_online_wfh = _b[1.bts#1.covidyr]
scalar se_`y_var'_online_wfh = _se[1.bts#1.covidyr]

areg `y_var' i.bts##i.covidyr  $control i.tumonth c.year if teach_county_inhyb&wfh&(telfs==1|telfs==2),a(county) cluster(county)
scalar b_`y_var'_inhyb_wfh = _b[1.bts#1.covidyr]
scalar se_`y_var'_inhyb_wfh = _se[1.bts#1.covidyr]
}
}


use "$wkdir\cleaned_data\temp_county_1012.dta",clear
preserve
gen coef = . 
gen se = . 
gen outcome= ""
gen online=.

local i=2
foreach y_var in childcare childeduc childpassive childmed {
local a: var label `y_var'
replace coef=b_`y_var'_online_base in `i'
replace se=se_`y_var'_online_base in `i'
replace online=1 in `i'
replace outcome="`a'" in `i'

local i=`i'+1
replace coef=b_`y_var'_inhyb_base in `i'
replace se=se_`y_var'_inhyb_base in `i'
replace online=0 in `i'
replace outcome="`a'" in `i'

local i=`i'+2
}

keep coef se outcome online

gen n = _n 
gen up = coef + 1.96* se // ci revised 
gen low = coef - 1.96* se 
keep if n < 14
replace n = - n 

// list in 1/13
// restore

label var n "Parent's Response to Covid-19 during Schooling Reopening Season"


tw (scatter n coef if online==1,ms(O) mc(green) ytit( "Effects of School Reopening on Time Allocation") ylabel(-13(13)0 0 " " -13 " ") mlabel(outcome) mlabp(12) mlabc(black)  xlabel(-90(30)30, grid) xline(0, lp(dash))) ///
(scatter n coef if online==0,ms(T) mc(orange) ylabel(-13(13)0 0 " " -13 " ") ) ///
(rcap up low n if online==1, lc(green) lp(dash) hor ) ///
(rcap up low n if online==0, lc(orange) lp(dash)  xtit("Coef. and 95% CIs in different samples") ///
legend(label(1 "Online Coef.") label(2 "Hybrid Coef.") label(3 "Online 95% CI") label(4 "Hybrid 95% CI") col(1) ring(0) pos(11) size(small))  hori) 


graph export "$graphpath/figure1_overall_1.eps",replace 
graph export "$graphpath/figure1_overall_1.png",replace 
restore

preserve
gen coef = . 
gen se = . 
gen outcome= ""
gen online=.

local i=2
foreach y_var in housework maintenance foodprep{
local a: var label `y_var'
replace coef=b_`y_var'_online_base in `i'
replace se=se_`y_var'_online_base in `i'
replace online=1 in `i'
replace outcome="`a'" in `i'

local i=`i'+1
replace coef=b_`y_var'_inhyb_base in `i'
replace se=se_`y_var'_inhyb_base in `i'
replace online=0 in `i'
replace outcome="`a'" in `i'

local i=`i'+2
}

keep coef se outcome online

gen n = _n 
gen up = coef + 1.96* se // ci revised 
gen low = coef - 1.96* se 
keep if n < 11
replace n = - n 

// list in 1/13
// restore

label var n "Parent's Response to Covid-19 during Schooling Reopening Season"

tw (scatter n coef if online==1,ms(O)  mc(green) ytit( "Effects of School Reopening on Time Allocation") ylabel(-10(10)0 0 " " -10 " ") mlabel(outcome) mlabp(12) mlabc(black) xlabel(-80(20)40, grid) xline(0, lp(dash))) ///
(scatter n coef if online==0,ms(T) mlc(orange)) ///
(rcap up low n if online==1, lc(green) lp(dash) hor ) ///
(rcap up low n if online==0, lc(orange) lp(dash)  xtit("Coef. and 95% CIs in different samples") ///
legend(label(1 "Online Coef.") label(2 "Hybrid Coef.") label(3 "Online 95% CI") label(4 "Hybrid 95% CI") col(1) ring(0) pos(8) size(small))  hori) 

graph export "$graphpath/figure1_overall_2.eps",replace 
graph export "$graphpath/figure1_overall_2.png",replace 
restore



label var sports "Sports"
preserve
gen coef = . 
gen se = . 
gen outcome= ""
gen online=.

local i=2
foreach y_var in leisuret sports work {
local a: var label `y_var'
replace coef=b_`y_var'_online_base in `i'
replace se=se_`y_var'_online_base in `i'
replace online=1 in `i'
replace outcome="`a'" in `i'

local i=`i'+1
replace coef=b_`y_var'_inhyb_base in `i'
replace se=se_`y_var'_inhyb_base in `i'
replace online=0 in `i'
replace outcome="`a'" in `i'

local i=`i'+2
}

keep coef se outcome online

gen n = _n 
gen up = coef + 1.96* se // ci revised 
gen low = coef - 1.96* se 
keep if n < 11
replace n = - n 

// list in 1/13
// restore

label var n "Parent's Response to Covid-19 during Schooling Reopening Season"


tw (scatter n coef if online==1,ms(O)  mc(green) ytit( "Effects of School Reopening on Time Allocation") ylabel(-10(10)0 0 " " -10 " ") mlabel(outcome) mlabp(12) mlabc(black) xlabel(-60(20)100, grid) xline(0, lp(dash))) ///
(scatter n coef if online==0,ms(T) mc(orange)) ///
(rcap up low n if online==1, lc(green) lp(dash) hor ) ///
(rcap up low n if online==0, lc(orange) lp(dash)  xtit("Coef. and 95% CIs in different samples") ///
legend(label(1 "Online Coef.") label(2 "Hybrid Coef.") label(3 "Online 95% CI") label(4 "Hybrid 95% CI") col(1) ring(0) pos(1) size(small))  hori) 


graph export "$graphpath/figure1_overall_3.eps",replace 
graph export "$graphpath/figure1_overall_3.png",replace 
restore







***q2:bts*online***

qui:{
cap erase "Table_county1_base_q2_bts_online.rtf"
local i=0
eststo clear
foreach y_var in  $outcome {
local a: var label `y_var'
local i=`i'+1
areg `y_var' i.bts##i.teach_county_online  $control i.tumonth if tuyear==2020 ,a(county) cluster(county)
est store m`i'
}
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 using Table_county1_base_q2_bts_online.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  ///
	title(\textbf{Baseline Results})  
eststo clear
}

qui:{
cap erase "Table_county1_base_q3_tripple.rtf"
local i=0
eststo clear
foreach y_var in  $outcome {
local a: var label `y_var'
local i=`i'+1
areg `y_var' i.bts##i.teach_county_online##covidyr  $control i.tumonth c.year ,a(county) cluster(county)
est store m`i'
}
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 using Table_county1_base_q3_tripple.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  ///
	title(\textbf{Baseline Results})  
eststo clear
}




gl control childnum eduy  i.occupation_cps married

cap erase "Table_county2_gender_tripple.rtf"
cap erase "Table_county2_gender2_tripple.rtf"
qui:{
	local i=0
eststo clear
foreach y_var in  $outcome {
local i=`i'+1
forvalues j=0/1 {
local c: label(male) `j'
areg `y_var' i.bts##i.teach_county_online##covidyr  $control i.tumonth c.year if male==`j',a(county) cluster(county)
est store m`i'_gender`j'
}
}
esttab m1_gender0 m1_gender1 m2_gender0 m2_gender1 m3_gender0 m3_gender1  m4_gender0 m4_gender1 m5_gender0 m5_gender1 m6_gender0 m6_gender1 m7_gender0 m7_gender1 m8_gender0 m8_gender1 m9_gender0 m9_gender1 m10_gender0 m10_gender1 using Table_county2_gender_tripple.rtf, replace se label star(* 0.1 ** 0.05 *** 0.01)  mtitle( "Female" "Male" "Female" "Male" "Female" "Male" "Female" "Male" "Female" "Male" "Female" "Male" "Female" "Male" "Female" "Male" "Female" "Male" "Female""Male") ///
	title(\textbf{Heterogeneity Results by Gender})  
	
	
esttab m1_gender0 m2_gender0 m3_gender0  m4_gender0 m5_gender0 m6_gender0  m7_gender0 m8_gender0 m9_gender0 m10_gender0  m1_gender1  m2_gender1 m3_gender1 m4_gender1 m5_gender1  m6_gender1  m7_gender1  m8_gender1  m9_gender1 m10_gender1 using Table_county2_gender2_tripple.rtf, replace se label star(* 0.1 ** 0.05 *** 0.01)  mtitle( "Female" "Female" "Female" "Female" "Female" "Female" "Female" "Female" "Female" "Female" "Male" "Male" "Male" "Male" "Male" "Male" "Male" "Male" "Male" "Male")  ///
	title(\textbf{Heterogeneity Results by Gender})  	
	
eststo clear
}




gl control childnum male  i.occupation_cps married
cap erase "Table_county3_edu_tripple.rtf"
cap erase "Table_county3_edu2_tripple.rtf"
qui:{
	local i=0	
eststo clear
foreach y_var in  $outcome {
	local i=`i'+1
forvalues j=0/1 {
local c: label(colgrad) `j'
areg `y_var' i.bts##i.teach_county_online##covidyr  $control i.tumonth c.year if colgrad==`j',a(county) cluster(county)
est store m`i'_hs`j'
}
}
esttab m1_hs0 m1_hs1 m2_hs0 m2_hs1 m3_hs0 m3_hs1  m4_hs0 m4_hs1 m5_hs0 m5_hs1 m6_hs0 m6_hs1 m7_hs0 m7_hs1 m8_hs0 m8_hs1 m9_hs0 m9_hs1 m10_hs0 m10_hs1 using Table_county3_edu_tripple.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  mtitle("Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above") ///
	title(\textbf{Heterogeneity Results by Education})  

esttab m1_hs0 m2_hs0 m3_hs0  m4_hs0 m5_hs0 m6_hs0  m7_hs0 m8_hs0 m9_hs0 m10_hs0  m1_hs1  m2_hs1 m3_hs1 m4_hs1 m5_hs1  m6_hs1  m7_hs1  m8_hs1  m9_hs1 m10_hs1 using Table_county3_edu2_tripple.rtf, replace label star(* 0.1 ** 0.05 *** 0.01)  mtitle("Below bachelor" "Below bachelor" "Below bachelor" "Below bachelor" "Below bachelor" "Below bachelor" "Below bachelor" "Below bachelor""Below bachelor" "Below bachelor" "Bachelor or above" "Bachelor or above"  "Bachelor or above" "Bachelor or above" "Bachelor or above" "Bachelor or above" "Bachelor or above" "Bachelor or above" "Bachelor or above" "Bachelor or above"  ) ///
	title(\textbf{Heterogeneity Results by Education})  
eststo clear
}



gl control childnum male eduy  i.occupation_cps married
cap erase "Table_county4_work_tripple.rtf"
qui:{
local i=0	
eststo clear
foreach y_var in  t_work3 t_work t_work2 {
local i=`i'+1
forvalues j=0/1 {
local c: label(wfh) `j'
areg `y_var' i.bts##i.teach_county_online##covidyr  $control i.tumonth c.year if wfh==`j' &(telfs==1|telfs==2),a(county) cluster(county) 
est store m`i'_wfh`j'
}
}
*peio1ocd prdtocc1 prmjocc1 prmjocgr puiock1
esttab m1_wfh0 m1_wfh1 m2_wfh0 m2_wfh1 m3_wfh0 m3_wfh1    using "Table_county4_work_tripple.rtf", replace  se label star(* 0.1 ** 0.05 *** 0.01)  mtitle("Not WfH Occpation" "WfH Occpation" "Not WfH Occpation" "WfH Occpation" "Not WfH Occpation" "WfH Occpation") ///
	title(\textbf{Heterogeneity Results by Occpation})  
eststo clear
}


gl control childnum male eduy  i.occupation_cps married
cap erase "Table_county4_work2_tripple.rtf"
qui:{
local i=0	
eststo clear
foreach y_var in  t_work3 t_work t_work2 {
local i=`i'+1
forvalues j=0/1 {
local c: label(wfh) `j'
areg `y_var' i.bts##i.teach_county_online##covidyr  $control i.tumonth c.year if wfh==`j' ,a(county) cluster(county) 
est store m`i'_wfh`j'
}
}
*peio1ocd prdtocc1 prmjocc1 prmjocgr puiock1
esttab m1_wfh0 m1_wfh1 m2_wfh0 m2_wfh1 m3_wfh0 m3_wfh1    using "Table_county4_work2_tripple.rtf", replace  se label star(* 0.1 ** 0.05 *** 0.01)  mtitle("Not WfH Occpation" "WfH Occpation" "Not WfH Occpation" "WfH Occpation" "Not WfH Occpation" "WfH Occpation") ///
	title(\textbf{Heterogeneity Results by Occpation})  
eststo clear
}



***hetro***


gl control male childnum eduy  i.occupation_cps married


foreach y_var in  $outcome {
local a: var label `y_var'
areg `y_var' i.bts##i.teach_county_inhyb i.bts##i.teach_county_online  bts covidyr  $control i.tumonth c.year ,a(county) cluster(county)
}
*y =b0 + b1 BTS + b2 COVID + b3 Online + b4 BTSxCOVID +b5 COVIDxOnline + b6 BTSxOnline+ b7 BTSxCOVIDxOnline


gen bts_covid=bts*covid
foreach y_var in $outcome{
areg `y_var' i.bts##teach_county_online i.bts##i.covidyr $control i.tumonth c.year ,a(county) cluster(county)
}

qui:{
cap erase "Table_county_base.rtf"
local i=0
eststo clear
foreach y_var in  $outcome {
local a: var label `y_var'
local i=`i'+1
areg `y_var' bts_county_inhyb bts_county_online bts covidyr  $control i.tumonth c.year ,a(county) cluster(county)
est store m`i'
}
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 using Table_county1_base.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  ///
	title(\textbf{Baseline Results})  
eststo clear
}


gl control childnum eduy  i.occupation_cps married
cap erase "Table_county2_gender.rtf"
cap erase "Table_county2_gender2.rtf"
qui:{
	local i=0
eststo clear
foreach y_var in  $outcome {
local i=`i'+1
forvalues j=0/1 {
local c: label(male) `j'
areg `y_var' bts_county_inhyb bts_county_online bts covidyr  $control i.tumonth c.year if male==`j',a(county) cluster(county)
est store m`i'_gender`j'
}
}
esttab m1_gender0 m1_gender1 m2_gender0 m2_gender1 m3_gender0 m3_gender1  m4_gender0 m4_gender1 m5_gender0 m5_gender1 m6_gender0 m6_gender1 m7_gender0 m7_gender1 m8_gender0 m8_gender1 m9_gender0 m9_gender1 m10_gender0 m10_gender1 using Table_county2_gender.rtf, replace se label star(* 0.1 ** 0.05 *** 0.01)  mtitle( "Female" "Male" "Female" "Male" "Female" "Male" "Female" "Male" "Female" "Male" "Female" "Male" "Female" "Male" "Female" "Male" "Female" "Male" "Female""Male") ///
	title(\textbf{Heterogeneity Results by Gender})  
	
	
esttab m1_gender0 m2_gender0 m3_gender0  m4_gender0 m5_gender0 m6_gender0  m7_gender0 m8_gender0 m9_gender0 m10_gender0  m1_gender1  m2_gender1 m3_gender1 m4_gender1 m5_gender1  m6_gender1  m7_gender1  m8_gender1  m9_gender1 m10_gender1 using Table_county2_gender2.rtf, replace se label star(* 0.1 ** 0.05 *** 0.01)  mtitle( "Female" "Female" "Female" "Female" "Female" "Female" "Female" "Female" "Female" "Female" "Male" "Male" "Male" "Male" "Male" "Male" "Male" "Male" "Male" "Male")  ///
	title(\textbf{Heterogeneity Results by Gender})  	
	
eststo clear
}




gl control childnum male  i.occupation_cps married
cap erase "Table_county3_edu.rtf"
cap erase "Table_county3_edu2.rtf"
qui:{
	local i=0	
eststo clear
foreach y_var in  $outcome {
	local i=`i'+1
forvalues j=0/1 {
local c: label(colgrad) `j'
areg `y_var' bts_county_inhyb bts_county_online bts covidyr  $control i.tumonth c.year if colgrad==`j',a(county) cluster(county)
est store m`i'_hs`j'
}
}
esttab m1_hs0 m1_hs1 m2_hs0 m2_hs1 m3_hs0 m3_hs1  m4_hs0 m4_hs1 m5_hs0 m5_hs1 m6_hs0 m6_hs1 m7_hs0 m7_hs1 m8_hs0 m8_hs1 m9_hs0 m9_hs1 m10_hs0 m10_hs1 using Table_county3_edu.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  mtitle("Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above") ///
	title(\textbf{Heterogeneity Results by Education})  

esttab m1_hs0 m2_hs0 m3_hs0  m4_hs0 m5_hs0 m6_hs0  m7_hs0 m8_hs0 m9_hs0 m10_hs0  m1_hs1  m2_hs1 m3_hs1 m4_hs1 m5_hs1  m6_hs1  m7_hs1  m8_hs1  m9_hs1 m10_hs1 using Table_county3_edu2.rtf, replace label star(* 0.1 ** 0.05 *** 0.01)  mtitle("Below bachelor" "Below bachelor" "Below bachelor" "Below bachelor" "Below bachelor" "Below bachelor" "Below bachelor" "Below bachelor""Below bachelor" "Below bachelor" "Bachelor or above" "Bachelor or above"  "Bachelor or above" "Bachelor or above" "Bachelor or above" "Bachelor or above" "Bachelor or above" "Bachelor or above" "Bachelor or above" "Bachelor or above"  ) ///
	title(\textbf{Heterogeneity Results by Education})  
eststo clear
}



gl control childnum male eduy  i.occupation_cps married
cap erase "Table_county4_work.rtf"
qui:{
local i=0	
eststo clear
foreach y_var in  t_work3 t_work t_work2 {
local i=`i'+1
forvalues j=0/1 {
local c: label(wfh) `j'
areg `y_var' bts_county_inhyb bts_county_online bts covidyr  $control i.tumonth c.year if wfh==`j' &(telfs==1|telfs==2),a(county) cluster(county) 
est store m`i'_wfh`j'
}
}
*peio1ocd prdtocc1 prmjocc1 prmjocgr puiock1
esttab m1_wfh0 m1_wfh1 m2_wfh0 m2_wfh1 m3_wfh0 m3_wfh1    using "Table_county4_work.rtf", replace  se label star(* 0.1 ** 0.05 *** 0.01)  mtitle("Not WfH Occpation" "WfH Occpation" "Not WfH Occpation" "WfH Occpation" "Not WfH Occpation" "WfH Occpation") ///
	title(\textbf{Heterogeneity Results by Occpation})  
eststo clear
}


use sample4_reorganized.dta,clear

label var childeduc "Schooling care" 
label var childcare_passive "Passive care"
label var childcare "Total care"
label var childmed "Medical care"
label var maintenance "Cleaning and maintenance"  
label var  leisuret "Socializing, relaxing and leisure"
label var sports "Sports, exercise and recreation"
label var covidyr "COVID year"
label var bts "back-to-school month"

replace childnum=. if childnum<0
drop if childnum==.
keep if occupation_c!=.
drop if missing(cbsa)
save "$datapath\cbsa_sample.dta",replace


eststo clear
 eststo sumstats :estpost sum $outcome childnum eduy married 
 esttab sumstats using appx_sample4sum_cbsa.rtf ,  append  label ///
	cells("count  mean(fmt(3))  min max sd(fmt(3)) ") ///
	noobs title(whole sample summary statistics) 
	

gl control male childnum eduy  i.occupation_cps married
qui:{
cap erase "Table_cbsa1_base.rtf"
local i=0
eststo clear
foreach y_var in  $outcome {
local a: var label `y_var'
local i=`i'+1
areg `y_var' bts_cbsa_inhyb bts_cbsa_online bts covidyr  $control i.tumonth c.year ,a(cbsa) cluster(cbsa)
est store m`i'
}
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 using Table_cbsa1_base.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  ///
	title(\textbf{Baseline Results})  
eststo clear
}


gl control childnum eduy  i.occupation_cps married

cap erase "Table_cbsa2_gender.rtf"
cap erase "Table_cbsa2_gender2.rtf"
qui:{
	local i=0
eststo clear
foreach y_var in  $outcome {
local i=`i'+1
forvalues j=0/1 {
local c: label(male) `j'
areg `y_var' bts_cbsa_inhyb bts_cbsa_online bts covidyr  $control i.tumonth c.year if male==`j',a(cbsa) cluster(cbsa)
est store m`i'_gender`j'
}
}
esttab m1_gender0 m1_gender1 m2_gender0 m2_gender1 m3_gender0 m3_gender1  m4_gender0 m4_gender1 m5_gender0 m5_gender1 m6_gender0 m6_gender1 m7_gender0 m7_gender1 m8_gender0 m8_gender1 m9_gender0 m9_gender1 m10_gender0 m10_gender1 using Table_cbsa2_gender.rtf, replace se label star(* 0.1 ** 0.05 *** 0.01)  mtitle( "Female" "Male" "Female" "Male" "Female" "Male" "Female" "Male" "Female" "Male" "Female" "Male" "Female" "Male" "Female" "Male" "Female" "Male" "Female""Male") ///
	title(\textbf{Heterogeneity Results by Gender})  
	
	
esttab m1_gender0 m2_gender0 m3_gender0  m4_gender0 m5_gender0 m6_gender0  m7_gender0 m8_gender0 m9_gender0 m10_gender0  m1_gender1  m2_gender1 m3_gender1 m4_gender1 m5_gender1  m6_gender1  m7_gender1  m8_gender1  m9_gender1 m10_gender1 using Table_cbsa2_gender2.rtf, replace se label star(* 0.1 ** 0.05 *** 0.01)  mtitle( "Female" "Female" "Female" "Female" "Female" "Female" "Female" "Female" "Female" "Female" "Male" "Male" "Male" "Male" "Male" "Male" "Male" "Male" "Male" "Male")  ///
	title(\textbf{Heterogeneity Results by Gender})  	
	
eststo clear
}




gl control childnum male  i.occupation_cps married
cap erase "Table_cbsa3_edu.rtf"
cap erase "Table_cbsa3_edu2.rtf"
qui:{
	local i=0	
eststo clear
foreach y_var in  $outcome {
	local i=`i'+1
forvalues j=0/1 {
local c: label(colgrad) `j'
areg `y_var' bts_cbsa_inhyb bts_cbsa_online bts covidyr  $control i.tumonth c.year if colgrad==`j',a(cbsa) cluster(cbsa)
est store m`i'_hs`j'
}
}
esttab m1_hs0 m1_hs1 m2_hs0 m2_hs1 m3_hs0 m3_hs1  m4_hs0 m4_hs1 m5_hs0 m5_hs1 m6_hs0 m6_hs1 m7_hs0 m7_hs1 m8_hs0 m8_hs1 m9_hs0 m9_hs1 m10_hs0 m10_hs1 using Table_cbsa3_edu.rtf, replace  se label star(* 0.1 ** 0.05 *** 0.01)  mtitle("Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above" "Below bachelor" "Bachelor or above") ///
	title(\textbf{Heterogeneity Results by Education})  

esttab m1_hs0 m2_hs0 m3_hs0  m4_hs0 m5_hs0 m6_hs0  m7_hs0 m8_hs0 m9_hs0 m10_hs0  m1_hs1  m2_hs1 m3_hs1 m4_hs1 m5_hs1  m6_hs1  m7_hs1  m8_hs1  m9_hs1 m10_hs1 using Table_cbsa3_edu2.rtf, replace label star(* 0.1 ** 0.05 *** 0.01)  mtitle("Below bachelor" "Below bachelor" "Below bachelor" "Below bachelor" "Below bachelor" "Below bachelor" "Below bachelor" "Below bachelor""Below bachelor" "Below bachelor" "Bachelor or above" "Bachelor or above"  "Bachelor or above" "Bachelor or above" "Bachelor or above" "Bachelor or above" "Bachelor or above" "Bachelor or above" "Bachelor or above" "Bachelor or above"  ) ///
	title(\textbf{Heterogeneity Results by Education})  
eststo clear
}



gl control childnum male eduy  i.occupation_cps married
cap erase "Table_cbsa4_work.rtf"
qui:{
local i=0	
eststo clear
foreach y_var in  t_work3 t_work t_work2 {
local i=`i'+1
forvalues j=0/1 {
local c: label(wfh) `j'
areg `y_var' bts_cbsa_inhyb bts_cbsa_online bts covidyr  $control i.tumonth c.year if wfh==`j' &(telfs==1|telfs==2),a(cbsa) cluster(cbsa) 
est store m`i'_wfh`j'
}
}
*peio1ocd prdtocc1 prmjocc1 prmjocgr puiock1
esttab m1_wfh0 m1_wfh1 m2_wfh0 m2_wfh1 m3_wfh0 m3_wfh1    using "Table_cbsa4_work.rtf", replace  se label star(* 0.1 ** 0.05 *** 0.01)  mtitle("Not WfH Occpation" "WfH Occpation" "Not WfH Occpation" "WfH Occpation" "Not WfH Occpation" "WfH Occpation") ///
	title(\textbf{Heterogeneity Results by Occpation})  
eststo clear
}






























***graphregion(color(white))

cd "$graphpath"
foreach v of varlist $outcome{
preserve 
local a: var label `v'
collapse (mean) `v' year tumonth,by (intvmonth)
line `v' year,by(tumonth ,note("")) xtitle("year",size(*0.9)) ytitle("`a' time use",size(*0.9)) 
restore
graph export "`v'_by_month.png" ,replace
}


gen period=.
replace period=1 if tuyear<2012
replace period=2 if tuyear<2020 & tuyear>2011
replace period=3 if tuyear==2020 & teach_county_inhyb==1
replace period=4 if tuyear==2020 & teach_county_online==1

use "$datapath\county_sample.dta",clear
*overall area
foreach v of varlist $outcome{
bysort tumonth period:egen mean_time=mean(`v')
local a: var label `v'
twoway ///
(connected mean_time tumonth if period==1, sort lpattern(dash) lcolor(lavender) msymbol(sh) mcolor(lavender)) ///
(connected mean_time tumonth if period==2, sort lpattern(longdash) lcolor(sandb ) msymbol(oh) mcolor(sandb )) ///
(connected mean_time tumonth if period==3, sort lpattern(solid) lcolor(cranberry ) msymbol(o) mcolor(cranberry )) ///
(connected mean_time tumonth if period==4, sort  lpattern(dash_dot ) lcolor(black) msymbol(t) mcolor(black)) , ///
xline(9, lp(dash_dot) lc(dkgreen)) title("`a' time changing trend") ytitle("time use/minute") xtitle("month") legend(label(1 "2003-2011") label( 2 "2012-2019")label( 3 "2020 in hybrid counties")  label( 4 "2020 in online counties")) xscale(range (6 12)) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
graph export "overall_`v'.png" ,replace
drop mean_time
*different teaching method areas
}







