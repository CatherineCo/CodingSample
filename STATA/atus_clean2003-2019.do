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
******
use "$datapath\sample3_2003-2019.dta",clear
sum trchildnum //all obs with children


clonevar fulltime=trdpftpt
replace fulltime=. if fulltime<0
replace fulltime=0 if fulltime==2


// clonevar occupation=trmjocgr
// replace occupation=. if occupation<0
**# Bookmark #1 
clonevar occupation_cps=prmjocgr


label var male "gender,=1 if male"

*family structure.1:married(spouse present or absent) 2:widowed divorced or seperated 3: never married
recode pemaritl (1 2=1)(3 4 5=2)(6=3),gen (famstructure)
label var famstructure "family structure"
label define labelfamstruc 1 "married" 2 "widowed divorced or seperated" 3 "never married"
label values famstructure labelfamstruc


recode telfs (1 2 =1)(3 4 5=0)(-1 -2 -3=.),gen (laboutstatus)
label var laboutstatus "labor force status"


clonevar tumonth=hrmonth 
gen month1_3=(tumonth<=3)

gen commute=t180501+ t180502+ t180589

gen t_work3=t050101+ t050102+ t050103+ t050189

clonevar asleep=t010101 
clonevar sleepless=t010102 
gen sleep= t010101+ t010102 + t010199 
gen grooming=t010201+ t010299
gen hlthselfcare=t010301 + t010399
gen personalactivity=t010401 + t010499
gen personalcare=t010101 +t010102 +t010199 +t010201 +t010299 +t010301 +t010399 +t010401 +t010499 +t010501 +t010599 +t019999


gen leisure=t120301+ t120302+ t120303+ t120304 +t120305+ t120306 +t120307 +t120308+ t120309 +t120310+ t120311+ t120312+ t120313+ t120399
gen social=t120101+t120199
gen leisuret=t120101+ t120199+ t120201+ t120202 +t120299 +t120301 +t120302 +t120303+ t120304 +t120305+ t120306+ t120307+ t120308 +t120309+ t120310+ t120311 +t120312+ t120313+ t120399+ t120401 +t120402 +t120403+ t120404 +t120499 +t120501 +t120502+ t120503+ t120504+ t120599+t129999
gen sports=t130101+ t130102+ t130103+ t130104+ t130105 +t130106 +t130107 +t130108 +t130109+ t130110+ t130112 +t130113+ t130114 +t130116+ t130117 +t130118+ t130119+ t130120 +t130122+ t130124+ t130125 +t130126+t130127+ t130128+ t130129+ t130130 +t130131+ t130132 +t130133+ t130134+ t130136 +t130199 +t130201+t130202+ t130203+t130204+ t130205 +t130206 +t130207+ t130208+ t130209+ t130210 +t130211 +t130212+ t130213 +t130214 +t130215+t130216+t130217 +t130218 +t130219+ t130220 +t130221 +t130222 +t130223+t130224+t130225+t130226+ t130227+t130228 +t130229+t130230+ t130231 +t130232 +t130299 +t130301 +t130302 +t139999+t130401+ t130402 +t130499 +t139999

gen sportsparticipate=t130101+ t130102+ t130103+ t130104+ t130105 +t130106 +t130107 +t130108 +t130109+ t130110+ t130112 +t130113+ t130114 +t130116+ t130117 +t130118+ t130119+ t130120 +t130122+ t130124+ t130125 +t130126+t130127+ t130128+ t130129+ t130130 +t130131+ t130132 +t130133+ t130134+ t130136 +t130199

egen housework= rowtotal(t020101 t020102 t020103 t020104 t020199 t020201 t020202 t020203 t020299 t020301 t020302 t020303 t020399 t020401 t020402 t020499 t020501 t020502 t020599 t020681 t020699 t020701 t020799 t020801 t020899 t020901 t020902 t020903 t020904 t020905 t020999 t029999)
egen maintenance  = rowtotal(t020101 t020102 t020103 t020104 t020199)
egen foodprep = rowtotal(t020201 t020202 t020203 t020299 )
egen householdmanagement = rowtotal(t020901 t020902 t020903 t020904 t020905 t020999 t029999)


replace gtco=. if gtco<=0
gen fips=gestfips*1000+ gtco
replace fips=. if gtco==0
clonevar cbsa=gtcbsa 
replace cbsa=. if cbsa<=0





save "atus2003_2019.dta",replace






log close
clear























