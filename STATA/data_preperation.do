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



**************************pnas edge geocode file************************
import excel "$datapath\EDGE_GEOCODE_PUBLICLEA_1819.xlsx", sheet("AGN_GEOLOAD_200324") firstrow clear
*keep LEAID STFIP CNTY CBSA
rename LEAID DistrictNCES
rename CNTY fips
rename CBSA cbsa 
destring DistrictNCES,replace
destring fips,replace
replace cbsa="" if cbsa=="N"
destring cbsa,replace
save "pnas_geocode.dta",replace

********************school policy data*********************
import delimited  "$datapath\covid-school-data.csv" ,clear
***teaching method-school district***

encode teachingmethod,gen (teach)
replace teach=. if (teach==4|teach==5|teach==6)

** SportsParticipation OnlineInstructionIncrease and...
label define labelyesno 1 "Yes" 0 "No"

foreach v of varlist sportsparticipation onlineinstructionincrease networkinvestment hardwareinvestment studentillnessreturnpolicy  studentisolationarea parentoptoutclassroomteaching  {
	encode `v' ,gen (`v'0)
replace `v'0=. if (`v'0==2|`v'0==3)
replace `v'0=0 if `v'0==1
replace `v'0=1 if `v'0==4
label values `v'0  labelyesno
}
rename sportsparticipation0 sports
rename onlineinstructionincrease0 online
rename networkinvestment0 network
rename hardwareinvestment0 hardware 
rename studentillnessreturnpolicy0 stuill
rename studentisolationarea0 stuisolation 
rename parentoptoutclassroomteaching0 patentteaching

encode studentmaskpolicy,gen (stumask_temp)
recode stumask_temp (6 2=.)(3 4 5=1)(1=0),gen (stumask)
label values stumask labelyesno
drop stumask_temp


encode staffmaskpolicy,gen (stamask_temp)
recode stamask_temp (2 4=.)(3=1)(1=0),gen (stamask)
label values stamask labelyesno
drop stamask_temp

encode schooltemporaryshutdown ,gen(schlshutdown_temp)
recode schlshutdown_temp (1 2 3=1)(4=0)(5 6=.),gen(schlshutdown)
label values schlshutdown labelyesno
drop schlshutdown_temp

*time variables
drop schoolyear
gen reopendate=date(opendate,"MDY")
rename districtnces DistrictNCES
gen verifieddate=date(lastverifieddate,"MDY")
gen verifiedyear=year(verifieddate)
count if verifiedyear==2020 & teachingmethod=="Pending"

save "covid_school_policy.dta",replace

duplicates tag DistrictNCES,gen (temp)
tab temp
drop temp

***policy variables: county level***
use "covid_school_policy.dta",clear
drop if missing(DistrictNCES) 
duplicates drop DistrictNCES,force
*no duplicates or missing
merge 1:1 DistrictNCES using "pnas_geocode.dta",gen (_mergegeopnas)
keep if _mergegeopnas==3
drop _mergegeopnas
save "covid_school_policy.dta",replace

use "covid_school_policy.dta",clear
tab teach,gen(teach)

replace enrollment=. if teach==.
bys fips: egen totalenroll_county=total (enrollment) 
replace totalenroll_county=. if enrollment==.

gen enrollfrac=enrollment/totalenroll_county
forvalues i=1/3{
	bys fips: egen teach_county_enroll`i'=total(enrollfrac*teach`i')
	replace teach_county_enroll`i'=. if missing(enrollment)
}
gen teach_max=max(teach_county_enroll1, teach_county_enroll2, teach_county_enroll3)
gen teach_county=.
forvalues i=1/3{
	replace teach_county=`i' if teach_county_enroll`i'==teach_max
}
*check whether there will be equal enrollment weight
gen temp= ((teach_county_enroll1==teach_county_enroll2&teach_county_enroll1!=0&teach_county_enroll1!=.)|(teach_county_enroll1==teach_county_enroll3&teach_county_enroll1!=0&teach_county_enroll1!=.)|(teach_county_enroll2==teach_county_enroll3&teach_county_enroll2!=0&teach_county_enroll2!=.))
tab temp
drop temp

// bys fips : egen county_reopendate=sum(enrollfrac*reopendate) if !missing(fips) & !missing(teach) &!missing(enrollfrac) &!missing(reopendate)
bys fips : egen county_reopendate=total(enrollfrac*reopendate) ,missing
replace county_reopendate=. if county_reopendate==0


label var teach_county_enroll1 "enrollment fraction of hybrid teaching method in the county"
label var teach_county_enroll2 "enrollment fraction of in_person teaching method in the county"
label var teach_county_enroll3 "enrollment fraction of online teaching method in the county"
label var totalenroll_county "total enrollment of the county"

label define labelteach 1 "hybrid" 2 "in_person" 3 "online"
label values teach labelteach

collapse (mean) county_reopendate teach_county totalenroll_county teach_county_enroll1 teach_county_enroll2 teach_county_enroll3,by(fips) cw

label var county_reopendate "county reopendate"
label var teach_county "county level policy"

save "county_opendate.dta",replace

***policy variables: cbsa level***

use "covid_school_policy.dta",clear
tab teach,gen(teach)

replace enrollment=. if teach==.
bys cbsa: egen totalenroll_cbsa=total (enrollment) 
replace totalenroll_cbsa=. if enrollment==.

gen enrollfrac=enrollment/totalenroll_cbsa
forvalues i=1/3{
	bys cbsa: egen teach_cbsa_enroll`i'=total(enrollfrac*teach`i')
	replace teach_cbsa_enroll`i'=. if missing(enrollment)
}
gen teach_max=max(teach_cbsa_enroll1, teach_cbsa_enroll2, teach_cbsa_enroll3)
gen teach_cbsa=.
forvalues i=1/3{
	replace teach_cbsa=`i' if teach_cbsa_enroll`i'==teach_max
}
*check whether there will be equal enrollment weight
gen temp= ((teach_cbsa_enroll1==teach_cbsa_enroll2&teach_cbsa_enroll1!=0&teach_cbsa_enroll1!=.)|(teach_cbsa_enroll1==teach_cbsa_enroll3&teach_cbsa_enroll1!=0&teach_cbsa_enroll1!=.)|(teach_cbsa_enroll2==teach_cbsa_enroll3&teach_cbsa_enroll2!=0&teach_cbsa_enroll2!=.))
tab temp
drop temp

// bys cbsa : egen cbsa_reopendate=sum(enrollfrac*reopendate) if !missing(cbsa) & !missing(teach) &!missing(enrollfrac) &!missing(reopendate)
bys cbsa : egen cbsa_reopendate=total(enrollfrac*reopendate) ,missing
replace cbsa_reopendate=. if cbsa_reopendate==0


label var teach_cbsa_enroll1 "enrollment fraction of hybrid teaching method in the cbsa"
label var teach_cbsa_enroll2 "enrollment fraction of in_person teaching method in the cbsa"
label var teach_cbsa_enroll3 "enrollment fraction of online teaching method in the cbsa"
label var totalenroll_cbsa "total enrollment of the cbsa"

label define labelteach 1 "hybrid" 2 "in_person" 3 "online"
label values teach labelteach

collapse (mean) cbsa_reopendate teach_cbsa totalenroll_cbsa teach_cbsa_enroll1 teach_cbsa_enroll2 teach_cbsa_enroll3,by(cbsa) cw

label var cbsa_reopendate "cbsa reopendate"
label var teach_cbsa "cbsa level policy"

save "cbsa_opendate.dta",replace


**merge
*3 pairs of duplicates for nces. some seems to have different policies and even different district name. don't know why.
*754 missing nces
/*districtname:
Vision Charter School Inc
Vision Charter School District
Harlem Village Academies Charter Dist
Harlem Village Academy West Charter Schl
Coastal Preparatory Academy
Cornerstone Charter Academy
*/

//
// *********************covid case data*********************************
// import delimited "$datapath\covid_case_county.csv",clear
// drop v1
// rename variable date
// replace date=subinstr(date,"date","",.)
// replace date=subinstr(date,"_","/",.)
//
// gen coviddate=date(date,"MD20Y")
// format coviddate %td
//
// drop date
// rename value covidcase
//
// tsset uid coviddate
// keep if tin(1jan2020, 31dec2020)
//
// gen tumonth=month(coviddate)
// save "covid_county.dta",replace
//
// collapse (sum) covidcase , by(cbsa tumonth) cw
// rename covidcase county_month_covidcase
// save "covid_county_month.dta",replace
// ***compile to cbsa
// ***crosswalk:fips to cbsa
// *https://www.nber.org/research/data/census-core-based-statistical-area-cbsa-federal-information-processing-series-fips-county-crosswalk
// use "$datapath\cbsa2fipsxw.dta",clear
// codebook fipsstatecode fipscountycode
// destring fipsstatecode fipscountycode,replace
// cap gen fips= fipsstatecode*1000+ fipscountycode
// drop if missing(fips)
//
// save "cbsa2fipsxw.dta",replace
// ***covid: county to cbsa
// use "covid_county.dta",clear
// tab combined_key if fips<1000
// drop if fips<1000
//
// merge n:1 fips using "cbsa2fipsxw.dta",gen(_mergegeo)
//
// keep if _mergegeo==3
// rename cbsacode cbsa
// destring cbsa,replace
// preserve
// collapse (sum) covidcase , by(cbsa coviddate) cw
// rename covidcase cbsa_month_covidcase
// save "covid_cbsa.dta",replace
// restore
//
// cap gen tumonth=month(coviddate)
// collapse (sum) covidcase , by(cbsa tumonth) cw
// rename covidcase cbsa_month_covidcase
// save "covid_cbsa_month.dta",replace
//



log close _all























