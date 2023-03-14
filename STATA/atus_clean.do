clear all
***setup environment***
cd "D:\Documents\Dropbox\Dropbox\ATUS 2020 project\working_yb\reorganization"
global wkdir `c(pwd)' 

cap mkdir output
cap mkdir cleaned_data
cd "$wkdir\cleaned_data"

log close _all
log using "reorganization $S_DATE",replace

gl datapath = "$wkdir\raw_data" 
gl outpath="$wkdir\output"


****cps-fips
// use "$datapath\atuscps_2020.dta",clear
//
// keep tucaseid tulineno gestfips gtcbsa gtco gtmetsta
// keep if tulineno==1
// clonevar statefips= gestfips
// save "temp_atusfips.dta", replace 


use "$datapath\atuscps_2020.dta",clear
keep if tulineno==1
merge 1:1 tucaseid using "$datapath\atussum_2020.dta",nogen keep(match)
merge 1:1 tucaseid tulineno using "$datapath\atusrost_2020.dta",nogen keep(match)

drop if trchildnum==0 ///see trohhchild:Presence of own household children < 18


foreach var in prmjind1 prmjocgr pemaritl pelkfto puwk hefaminc tesex pesex{
	replace `var'=. if `var'<0
}

tab1 trchildnum tesex  telfs tespempnot ptdtrace 
sum teage, d  //why do respondents younger than 18 have household children <18
recode tudiaryday (2 3 4 5 6 =1) (1 7=0), gen(weekday)  
gen white =  ptdtrace==1
replace white=. if ptdtrace==.

compare tesex pesex if tesex!=.
gen male = pesex==1
replace male=. if pesex==.
clonevar age= teage
gen age2= age^2
*edu
recode peeduca (31 32 33 34 35 36 37 38  =0) (39 40 41 42 43 44 45 46=1) (-1=.), gen(hsgrad)
recode peeduca (31 32 33 34 35 36 37 38 39  =0) (40 41 42 43 44 45 46=1) (-1=.), gen(somecol)
recode peeduca (31 32 33 34 35 36 37 38 39 40 41 42  =0) (43 44 45 46=1) (-1=.), gen(colgrad)

gen urban =gtmetsta == 1
replace urban =. if gtmetsta ==-1
replace urban =. if gtmetsta ==3

gen childcare = t030101+t030102+ t030103+ t030104+ t030105+ t030106+ t030108+ t030109 +t030110+ t030111+ t030112 
gen childcarei = childcare>0
replace childcarei =. if childcare==. 

gen childcare_ext =t030101+t030102+ t030103+ t030104+ t030105+ t030106+ t030108+ t030109 +t030110+ t030111+ t030112+ t030199
gen childcare_exti = childcare_ext >0
replace childcare_exti =. if childcare_ext == .
label var childcare_ext "Caring For & Helping HH Children"

gen childeduc = t030201+ t030202+ t030203+ t030204+ t030299
gen childeduci = childeduc >0
replace childeduci =. if childeduc==.
label var childeduc "Activities Related to HH Children's Education"

gen childmed = t030301+ t030302+ t030303+ t030399
gen childmedi = childmed >0
replace childmedi=. if childmed==.
label var childmed "Activities Related to HH Children's Health"

save "clean.dta",replace


use "$datapath\atusresp_2020.dta",clear

clonevar childcare_passive = trtohhchild
merge 1:1 tucaseid using "clean.dta", nogen keep(match)
gen childcare_passivei = childcare_passive >0
replace childcare_passivei=. if childcare_passive ==.
label var childcare_passive "passive childcare for chld age<=18"
*actually this is with own household children---Total nonwork-related time respondent spent with own household children < 18 (in minutes)
save "clean.dta",replace


clear all 
use "$datapath\atuact_2020.dta", clear 
clonevar childcare_passive13 = trtcctot_ln
replace childcare_passive13 =. if childcare_passive13 <0
collapse (sum) childcare_passive , by(tucaseid)
keep tucaseid childcare_passive13 
*while this is with all children---Total time spent during activity providing secondary childcare for all children < 13 (in minutes)
*TRTCCTOT_LN is the maximum for the activity of the following variables: TRTOHH_LN, TRTNOHH_LN, TRTONHH_LN, and TRTCOC_LN

merge 1:1 tucaseid using "clean.dta", nogen keep(match)
gen childcare_passive13i = childcare_passive >0
replace childcare_passive13i=. if childcare_passive ==.
label var childcare_passive13 "passive childcare for chld age<=13"

save "clean.dta", replace 

clonevar intyear = tuyear 
label var childcare  "Childcare"
label var childcarei "Childcare"
label var childcare_passive  "Passive childcare"
label var childcare_passivei "Passive childcare"

clonevar physicalcare = t030101
clonevar readingto = t030102
clonevar playingwith = t030103
clonevar artscrafts = t030104
clonevar sportswith = t030105
clonevar planningfor = t030108
clonevar lookingafter = t030109


foreach var in physicalcare readingto playingwith artscrafts sportswith planningfor lookingafter  {
gen `var'i = `var'>0
replace `var'i=. if `var'==.
}
label var physicalcarei     "Physical care for hh children"
label var readingtoi        "Reading to/with hh children"
label var playingwithi      "Playing with hh children, not sports"
label var artscraftsi       "Arts and crafts with hh children"
label var sportswithi       "Playing sports with hh children"
label var planningfori      "Organization & planning for hh children"
label var lookingafteri     "Looking after hh children (as a primary activity)"

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

clonevar fulltime=trdpftpt
replace fulltime=. if fulltime<0
replace fulltime=0 if fulltime==2

clonevar occupation=trmjocgr
replace occupation=. if occupation<0
clonevar occupation_cps=prmjocgr

label var male "gender,=1 if male"
****
*family structure.1:married(spouse present or absent) 2:widowed divorced or seperated 3: never married

recode pemaritl (1 2=1)(3 4 5=2)(6=3),gen (famstructure)
label var famstructure "family structure"
label define labelfamstruc 1 "married" 2 "widowed divorced or seperated" 3 "never married"
label values famstructure labelfamstruc

*teio1ocd Edited: occupation code (main job)--too many unique values
*trdtocc1 Detailed occupation recode (main job)
*trmjocc1 Major occupation recode (main job)
*trmjocgr Major occupation category (main job)	1-6

*TEHRUSL1 Edited: how many hours per week do you usually work at your main job?
*TEHRUSLT Edited: total hours usually worked per week (sum of TEHRUSL1 and TEHRUSL2)

*telfs:Edited: labor force status
*TRDPFTPT:Full time or part time employment status of respondent--Respondent File, Activity Summary File
*PRWKSTAT Full time or part time work status ATUS-CPS File

recode telfs (1 2 =1)(3 4 5=0)(-1 -2 -3=.),gen (laboutstatus)
label var laboutstatus "labor force status"

// label define labelfulltime 0 "part time employment status" 1 "full time employment status"
label define labelmale 1 "male" 0 "female"
label define labelhsgrad 1 "with high school diploma or above" 0 "without high school diploma"
label define labelsomecol 1 "some college or above" 0 "below college"
label define labelcolgrad 1 "bachelor's degree or above" 0 "below bachelor's degree"
label define labellabour 0 "part time work status" 1 "full time work status"
label values  male labelmale
label values  hsgrad labelhsgrad
label values  somecol labelsomecol
label values  colgrad labelcolgrad
label values fulltime labelfulltime
rename laboutstatus labourstatus
label values labourstatus labellabour

label var male "gender"
label var hsgrad "education attainment of high school"
label var somecol "education attainment of some college"
label var colgrad "education attainment of college graduating"
label define labelsuspension 0 "interviewed before suspension" 1 "interviewed after suspension" 


gen month1_3=(tumonth<=3)
label values month1_3 labelsuspension
label var  month1_3 "interviewed before suspension"

gen t_work=t050101+ t050102+ t050103+ t050104+ t050199 ///
			+t050201+ t050203+ t050299 ///
			+t050301+ t050302+ t050303+ t050304+ t050305+ t050399 ///
			+t050401+t050403+ t050404+ t050499

gen commute=t180501+ t180502+ t180503+ t180504
gen t_work2=t_work + t180501+ t180502+ t180503+ t180504		
gen t_work3=t050101+ t050102+ t050103+ t050104+ t050199

label var t_work "Work & Work Related Activities"
label var t_work3 "Working"
label var t_work2 "Work & Work Related Activities & Commuting"
label var commute "Commuting"


***self care
clonevar asleep=t010101 
clonevar sleepless=t010102 
gen sleep= t010101+ t010102
gen grooming=t010201+ t010299
gen hlthselfcare=t010301 + t010399
gen personalactivity=t010401 + t010499
gen personalcare=t010101 +t010102 +t010201+ t010299+ t010301 +t010399+ t010401+ t010499

label var sleep "Sleeping & Sleeplessness"
label var grooming "Grooming"
label var hlthselfcare "Health-related Self Care"
label var personalactivity "Personal Activities"
label var personalcare "Personal Care"


gen leisure=t120301+ t120302+ t120303+ t120304 +t120305+ t120306 +t120307 +t120308+ t120309 +t120310+ t120311+ t120312+ t120313+ t120399
gen social=t120101+t120199
gen leisuret=t120101+ t120199+ t120201+ t120202 +t120299 +t120301 +t120302 +t120303+ t120304 +t120305+ t120306+ t120307+ t120308 +t120309+ t120310+ t120311 +t120312+ t120313+ t120399+ t120401 +t120402 +t120403+ t120404 +t120499 +t120501 +t120502+ t120503+ t120504+ t129999
label var leisure "Relaxing and Leisure"
label var social "Socializing and Communicating"
label var leisuret "Socializing, Relaxing, and Leisure"
**
gen sports=t130101+ t130102+ t130103+ t130104+ t130105 +t130106 +t130107 +t130108 +t130109+ t130110+ t130112 +t130113+ t130114 +t130116+ t130117 +t130118+ t130119+ t130120 +t130122+ t130124+ t130125 +t130126+t130127+ t130128+ t130129+ t130130 +t130131+ t130132 +t130133+ t130134+ t130136 +t130199 +t130202+ t130203+ t130210 +t130211 +t130212+ t130213 +t130216+ t130220 +t130224+ t130227 +t130229 +t130299 +t130301 +t130302 +t139999
gen sportsparticipate=t130101+ t130102+ t130103+ t130104+ t130105 +t130106 +t130107 +t130108 +t130109+ t130110+ t130112 +t130113+ t130114 +t130116+ t130117 +t130118+ t130119+ t130120 +t130122+ t130124+ t130125 +t130126+t130127+ t130128+ t130129+ t130130 +t130131+ t130132 +t130133+ t130134+ t130136 +t130199 
label var sports "Sports, Exercise, and Recreation"
label var sportsparticipate "Participating in Sports, Exercise, or Recreation"

**domestic labour
egen housework= rowtotal(t020101 t020102 t020103 t020104 t020199 t020201 t020202 t020203 t020299 t020301 t020302 t020303 t020399 t020401 t020402 t020499 t020501 t020502 t020599 t020601 t020602 t020699 t020701 t020799 t020801 t020899 t020901 t020902 t020903 t020904 t020905 t020999 t029999)

egen maintenance= rowtotal(t020101 t020102 t020103 t020104 t020199)
egen foodprep = rowtotal(t020201 t020202 t020203 t020299 )
egen householdmanagement = rowtotal(t020901 t020902 t020903 t020904 t020905 t020999 t029999)
label var housework  "All housework"
label var maintenance "Cleaning, maintenance"
label var foodprep "Food preparation"
label var householdmanagement "Household management"


replace gtco=. if gtco<=0
gen fips=gestfips*1000+ gtco
replace fips=. if gtco==0
clonevar cbsa=gtcbsa 
replace cbsa=. if cbsa<=0

save "clean.dta", replace 


//
//
// foreach h of varlist $hetero{
// foreach v of varlist $parenting $parentingdt $work {
//  byhist `v', by(`h')
// graph export `h'_`v'byhist.png ,replace
// }    
// }
//
// foreach h of varlist $hetero{
// estpost ttest $parenting $parentingdt $work ,by(`h')
// esttab using 0507ttest.rtf , ///
// 	cells("N_1 mu_1(fmt(3)) N_2 mu_2(fmt(3)) t(star fm(3))") star( * 0.10 ** 0.05 *** 0.01) ///
// 	noobs compress append title(T-test by `h', sample1 means `h'==0, sample2 means `h'==1) 
// 	*notes ("sample 1 means `h'==0; sample 2 means `h'==1. Reported in the last column is t-statistic")
//
// }
// eststo clear
// forvalues i=1/6{
// 	eststo sumstats`i' :estpost sum $parenting $parentingdt $work if occupation==`i'
// 	esttab sumstats`i' using "0508sum_occu.rtf" ,  append  ///
// 	cells("count  mean(fmt(3))  min max sd ") ///
// 	noobs title(occupation=`i') 
// }



/*1 Management, professional, and related occupations
           2 Service occupations
           3 Sales and office occupations
           4 Farming, fishing, and forestry occupations
           5 Construction and maintenance occupations
           6 Production, transportation, and material moving occupations
*/













log close
clear










