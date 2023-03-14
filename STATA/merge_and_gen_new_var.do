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



*******merge atus and covid cases*******
use "clean.dta",clear
gen year=2020
gen tudate= mod(tudiarydate,100)
gen intvdate=mdy(tumonth,tudate,tuyear)
// merge n:1 fips tumonth using "covid_county_month.dta",gen(_mergecountycovid)
// drop if _mergecountycovid==2
// merge n:1 cbsa tumonth using "covid_cbsa_month.dta",gen(_mergecountycbsa)
// drop if _mergecountycbsa==2

append using atus2003_2019.dta
replace intvdate=mdy(tumonth,1,tuyear) if intvdate==.

merge n:1 fips using  county_opendate.dta,gen (_mergecounty)
drop if _mergecounty==2 

merge n:1 cbsa using  cbsa_opendate.dta,gen (_mergecbsa)
drop if _mergecbsa==2
save sample4_reorganized.dta,replace



*******generate variables*******
use "sample4_reorganized.dta",clear

gen county_openmonth=month(county_reopendate)
gen cbsa_openmonth=month(cbsa_reopendate)

gen county_openi=intvdate>=county_reopendate
replace county_openi=. if county_reopendate==.
gen cbsa_openi=intvdate>=cbsa_reopendate
replace cbsa_openi=. if cbsa_reopendate==.

label var intvdate "date of ATUS interview"

label var county_openi "=1 if the interview date is later than the county reopendate"
label var cbsa_openi "=1 if the interview date is later than the cbsa reopendate"
label var county_openmonth "county level school reopening date"
label var cbsa_openmonth "cbsa level school reopening date"

gen county_distance= tumonth-county_openmonth
replace county_distance=. if missing(county_openmonth)
gen cbsa_distance= tumonth-cbsa_openmonth
replace cbsa_distance=. if missing(cbsa_openmonth)

label var county_distance "time distance (month) of the interviewed month to the county-level school reopening date"
label var cbsa_distance "time distance (month) of the interviewed month to the cbsa-level school reopening date"

// replace teach_county=0 if year<2020
// replace teach_cbsa=0 if year<2020

label define labelteach 0 "before covid year 2020"  1 "hybrid" 2 "in_person" 3 "online"
// rename teach_fips teach_county
label values teach_county labelteach
label values teach_cbsa labelteach
label var teach_county "county-level teaching method"
label var teach_cbsa "csba-level teaching method"

label define labelschoolopen 0 "school not reopened when interviewed" 1 "school reopened when interviewed"
label values county_openi labelschoolopen
label values cbsa_openi labelschoolopen




// rename month_county_covidcase county_month_covidcase
// label var county_month_covidcase "monthly confirmed covid cases at county level"
// label var cbsa_month_covidcase "monthly confirmed covid cases at cbsa level"
// replace county_month_covidcase=county_month_covidcase/100000
// replace cbsa_month_covidcase=cbsa_month_covidcase/100000


recode peeduca (-3 -2 -1=.)(31=0)(32=2)(33=5)(34=7)(35=9)(36=10)(37=11)(38 39=12)(40 41 42=15)(43=16)(44 45=18)(46=21),gen (eduy)
label var eduy "education year"
*occupation 2021 albanesi kim covid 19 us labor market occupation family gender jep
/*Flexible : Education, Training, and Library 
Management, Business, Computer and Mathematical, Architecture and Engineering
Life, Physical, and Social Science
Community and Social Services
Legal 
Arts, Design, Entertainment, Sports,and Media
Sales and Related
Office and Administrative

Inflexible: Healthcare Practitioners and Technical, Healthcare Support,Food Preparation and Serving, Personal Care and Service
Protective Service, Building and Grounds Cleaning and Maintenance, Farming, Fishing, and Forestry, Construction Trades, Extraction
Installation, Maintenance, and Repair
 Production, Transportation and Material Moving
*/
gen post= intvdate> date("9/1/2020","MDY" ) 
// recode prmjocgr (-3 -2 -1=.)(1 3 =1)(2 4 5 6 7=0),gen(wfh)
recode prmjocc1 (-3 -2 -1=.)(1 2 4 5 =1)(3 6 7 8 9 10 11=0),gen(wfh)
label var wfh "work from home occupation"


gen covidyr=year==2020
gen bts=(tumonth>=9)

gen reopen=bts*covid
label var reopen "school opening period for 2020"



gen teach_county_inhyb=(teach_county==1|teach_county==2)
gen teach_county_online=(teach_county==3)
gen teach_cbsa_inhyb=(teach_cbsa==1|teach_cbsa==2)
gen teach_cbsa_online=(teach_cbsa==3)
label var teach_county_inhyb "in-person or hybrid as county-level teaching method"
label var teach_county_online "online as county-level teaching method"
label var teach_cbsa_inhyb "in-person or hybrid as cbsa-level teaching method"
label var teach_cbsa_online "online as cbsa-level teaching method"


/*trchildnum Number of household children < 18
trnumhou Number of people living in respondent's household
hrnumhou Total number of persons in the household (household members)
huprscnt Number of actual and attempted personal contacts*/
clonevar atus_childnum=trchildnum
clonevar atus_hhmembernum=trnumhou
clonevar childnum=prnmchld
clonevar hhmembernum=hrnumhou
gen hhadultnum=hrnumhou-childnum
label var hhadultnum "Number of adults in the household"

*gender indicator, number of children, years of schooling, age, occupation indicators, family structure indicator.
gen bts_county_inhyb= bts*teach_county_inhyb
label var bts_county_inhyb "bts*teach_county_inhyb"
gen bts_county_online=bts*teach_county_online
label var bts_county_online "bts*teach_county_online"
gen bts_cbsa_inhyb= bts*teach_cbsa_inhyb
label var bts_cbsa_inhyb "bts*teach_cbsa_inhyb"
gen bts_cbsa_online=bts*teach_cbsa_online
label var bts_cbsa_online "bts*teach_cbsa_online"

format intvdate %td
gen intvmonth=mofd(intvdate)
label var intvmonth "montly date of ATUS interview"







// foreach d in county cbsa{
// forvalues i=1/3{
// 	local a: label(teach_`d') `i'
// 	local b: var label teach_`d'
// 	gen teach_`d'_`a'=teach_`d'==`i'
// 	label var  teach_`d'_`a' "`a' is the `b'"
// 	gen `d'openi_`a'=`d'_openi * teach_`d'_`a'
// 	label var `d'openi_`a' " `d'_openi*teach_`d'_`a'"
// 	gen `d'_dis_`a'=`d'_distance*teach_`d'_`a'
// 	label var `d'_dis_`a' "`d'_distance*teach_`d'_`a'"
// 	gen post_`d'_`a'=post* teach_`d'_`a'
// 	label var post_`d'_`a' " post*teach_`d'_`a'"
// 	gen post_`d'_enroll`i'=post*teach_`d'_enroll`i'
// 	label var post_`d'_enroll`i' "post*enroll_`d'_`a'"
//	
// }	
// }


// rename housework maintenance
// rename householdmaint housework

drop married
recode pemaritl  (1=1)(2 3 4 5 6=0),gen(married)
label define labelmarried 0 "not married or spouse absent" 1 "married and spouse present"
label values married labelmarried
label var married "marriage status"

clonevar county=fips
save sample4_reorganized_whole.dta,replace
keep if tumonth>5
save sample4_reorganized.dta,replace

log close _all





















