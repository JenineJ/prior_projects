//Creating variables for first reported DM, HTN, AF, stroke, and smoking based on AFU and Visit data

/*
Finds the earliest date of condition using the following:
(self-report refers to the date that participant said they had a history of the condition- does not refer to participant's report of when the condition started)

Variable names:
Example- diabetes
	- everdiab- ever DM by AFU and Visits
	- everdiabdate- date of first report or detected DM
	- everdiabpre (whether DM is missing or "no" before first reported/detected DM- for use in time-varying analyses)
	- everdiabdateno (date participant first reported never having DM; set to missing if it is after first reported/detected DM)
	- everdiab2005- DM reported/detected as of 2005 


Diabetes (diab):
- AFU self-report of history of DM (using AFU data, MCU dataset, and status61 dataset)
- AFU self-report of diabetes medications
- Visit diabts variables that use self-report, meds, and glucose, and have cutoff of 126


Hypertension (htn):
- AFU self-report of history of HTN (using AFU data, MCU dataset, and status61 dataset)
- AFU self-report of HTN medications
- Visit hypert variables that use meds and BP, and have cutoff of 140/90
- See comments to modify file to exclude self-reported HTN


Ever smoking (smoker):
- AFU self-report of current smoking (using AFU data)
- Visit report of current/former/never smoking


Stroke (stroke): 
- Visit 1 self-report of stroke history
- Incident stroke using C7_IN17DPP
(self-reported data from after V1 is not used)


A. fib (af):
- Visit 1 ECG
- Incident a. fib/flutter using afincby11 and aflincby11, which use Visit ECGs, ICD codes, and death certificates, and ends in 1/2012
- Self reported diagnosis of a. fib at recent visits (history of AF was asked in AFU L (2007), then AF since last visit was asked in AFU M and MCU; data not available in AFU composite ending in CY28, so "yes" responses drawn from MCU dataset and status61 dataset)
- All without AF through the above sources are considered to have no history of AF (though data on whether participants said they have no history of AF is not available)
*/


cd `"/Users/`c(username)'/Dropbox (Partners HealthCare)/Amil-Jenine share/Aric- CAD HFpEF/Analysis final files"'
//cd "/Users/brianclaggett/Dropbox/Amil-Jenine share/Aric- CAD HFpEF/Analysis final files"
cls



//Cleans up MCU file
use "uc7503_mcu.dta", clear
rename subjectid id
replace mcu12a = mdy(mcu12am, 01, mcu12ay) if missing(mcu12a) & !missing(mcu12ay)	//sets date to first day of month for 4 a. fib cases with only month and year
save "uc7503_mcu_id and fib cleaned.dta", replace




use "uc605701_compositeafu_cy2_cy23", clear
//last file with questions such as "has a doctor ever told you you have diabetes"; starting 2010 such questions were moved to MCU (medical conditions update) form and dataset, which has data carried forward from prior AFUs
//This file is used to obtain self-reported DM/HTN/smoking from AFUs; this data is also in MCU (medical condition update) dataset and inc* variables of status61 dataset, but some discrepancies so all three are looked at to find earliest date												

//AFU forms- G(1998), M(from 2010 to 2014)
//date of AFU- afucomp1_a
//doc ever diab- afucomp7d_g- form G-L, then new diab since last contact- afucomp15_m for M
//diab meds last 2 weeks- afucomp16c_g- since form G (used in next section of code)

//doc ever htn- afucomp7c_g form G-L, then new htn since last contact- afucomp14_m for M
//htn meds- afucomp16a_g- since G (used in next section)


generate diab=.
generate htn=.
generate smoker=.


foreach var of varlist diab htn smoker {
	generate `var'date =.
	format `var'date %dD_m_Y
	generate `var'dateno = .
	format `var'dateno %dD_m_Y
	}
	

replace diabdate= afucomp1_a if (afucomp7d_g=="Y" | afucomp15_m=="Y" | afucomp16c_g=="Y")		
replace diab=1 if (afucomp7d_g=="Y" | afucomp15_m=="Y" | afucomp16c_g=="Y")
replace diabdateno= afucomp1_a if diab!=1 & (afucomp7d_g=="N" | afucomp16c_g=="N")
replace diab=0 if !missing(diabdateno)

//*remove following section if self-reported HTN data not used
replace htndate= afucomp1_a if (afucomp7c_g=="Y" | afucomp14_m=="Y" | afucomp16a_g=="Y")
replace htn=1 if (afucomp7c_g=="Y" | afucomp14_m=="Y" | afucomp16a_g=="Y")
replace htndateno= afucomp1_a if htn!=1 & (afucomp7c_g=="N" | afucomp16a_g=="N")
replace htn=0 if !missing(htndateno)

replace smokerdate= afucomp1_a if afucomp30_g=="Y"
replace smoker=1 if afucomp30_g=="Y"

//*uncomment if using AFU data on stroke/TIA since last contact
//replace strokedate= afucomp1_a if afucomp29_a=="Y"			
//replace stroke=1 if afucomp29_a=="Y"


gsort id afucomp1_a										//sort by id, then by AFU date


foreach var of varlist diab htn smoker {
	by id: egen ever`var' = max(`var')
	by id: egen ever`var'date = min(`var'date)
	by id: egen ever`var'dateno = min(`var'dateno)		//ever`var'dateno gives earliest date that participant reported not having a history of the condition 
	by id: replace ever`var'dateno = . if ever`var'dateno >= ever`var'date //ever`var'dateno is set to missing if it occurs after participant reports having a history of the condition		
	format ever`var'date %dD_m_Y
	format ever`var'dateno %dD_m_Y
	}


bysort id: keep if _n==1								//keeps only the first AFU for each participant 

save "uc605701_compositeafu_cy2_cy23 with ever variables.dta", replace




use "uc750301_compafu_safu_cy2_cy28.dta", clear	
//most recent available AFU composite; used to get info on AFU-reported meds (med data not used for MCU or inc* variables of status61)

generate afucompdate = date(afucomp1_a, "MDY")
format afucompdate %dD_m_Y

generate diab=.
generate htn=.


foreach var of varlist diab htn {
	generate `var'date =.
	format `var'date %dD_m_Y
	generate `var'dateno = .
	format `var'dateno %dD_m_Y
	}

merge m:1 id using "uc605701_compositeafu_cy2_cy23 with ever variables", keepusing(everdiab everdiabdate everdiabdateno everhtn everhtndate everhtndateno eversmoker eversmokerdate eversmokerdateno)
drop if _merge==2
drop _merge

gsort id afucompdate										//sort by id, then by AFU date

replace diabdate= afucompdate if afucomp16c_g=="Y"
replace diab=1 if afucomp16c_g=="Y"
replace diabdateno= afucompdate if afucomp16c_g=="N"
replace diab=0 if afucomp16c_g=="N"


replace htndate= afucompdate if (afucomp16a_g=="Y")
replace htn=1 if afucomp16a_g=="Y"
replace htndateno= afucompdate if afucomp16a_g=="N"
replace htn=0 if afucomp16a_g=="N"


foreach var of varlist diab htn {
	by id: egen ever`var'28 = max(`var')
	by id: egen ever`var'date28 = min(`var'date)
	by id: egen ever`var'dateno28 = min(`var'dateno)
	format ever`var'date28 %dD_m_Y
	format ever`var'dateno28 %dD_m_Y
	replace ever`var'date = ever`var'date28 if ever`var'date>ever`var'date28
	replace ever`var'=1 if ever`var'28==1
	replace ever`var'dateno = ever`var'dateno28 if ever`var'dateno > ever`var'dateno28
	replace ever`var'dateno = . if ever`var'dateno >= ever`var'date
	}

//browse id diab diabdate diabdateno everdiab everdiabdate everdiabdateno everdiabdate28 everdiabdateno28 htn htndate htndateno everhtn everhtndate everhtndate28 everhtndateno everhtndateno28

bysort id: keep if _n==1	




//Incorporates MCU data
merge 1:1 id using "uc7503_mcu_id and fib cleaned.dta", keepusing(mcu1a mcu2a mcu12a)
drop if _merge==2	
drop _merge


replace everdiabdate = mcu2a if mcu2a < everdiabdate
replace everdiab=1 if !missing(everdiabdate)
replace everdiabdateno = . if everdiabdateno >= everdiabdate

//*remove following section if self-reported HTN data not used
replace everhtndate = mcu1a if mcu1a < everhtndate
replace everhtn=1 if !missing(everhtndate)
replace everhtndateno = . if everhtndateno >= everhtndate

generate everafdate = mcu12a
format everafdate %dD_m_Y
generate everaf = 1 if !missing(mcu12a)




//Incorporates status61 data
merge 1:1 id using "status61_180718.dta", keepusing(incselfrepdm61 incselfrepdm_date61 incselfrephbp61 incselfrephbp_date61 incselfrepaf61 incselfrepaf_date61)
drop if _merge==2
drop _merge

replace everdiabdate = incselfrepdm_date61 if ((incselfrepdm_date61 < everdiabdate) & incselfrepdm61==1) 
replace everdiab = 1 if incselfrepdm61==1

//*remove following section if self-reported HTN data not used
replace everhtndate = incselfrephbp_date61 if ((incselfrephbp_date61 < everhtndate) & incselfrephbp61==1)
replace everhtn = 1 if incselfrephbp61==1

replace everafdate = incselfrepaf_date61 if ((incselfrepaf_date61 < everafdate) & incselfrepaf61==1)
replace everaf = 1 if incselfrepaf61==1

save "uc750301_compafu_safu_cy2_cy28 ever data.dta", replace




//Incorporates Visit data
use "ARICmaster_011119.dta", clear
drop _merge

merge 1:1 id using "uc750301_compafu_safu_cy2_cy28 ever data.dta", keepusing(everdiab everdiabdate everdiabdateno everhtn everhtndate everhtndateno eversmoker eversmokerdate eversmokerdateno everaf everafdate)
drop if _merge==2
drop _merge

merge 1:1 id using "hom", keepusing(hom10a hom10d)			//ever HTN and ever stroke (asked at V1 home visit)
drop if _merge==2
drop _merge

generate v1stroke = 1 if hom10d=="Y"
replace v1stroke = 0 if hom10d=="N"

//*remove following 4 sections if self-reported HTN data not used
generate v1htn = 1 if hom10a=="Y"
replace v1htn = 0 if hom10a=="N"

merge 1:1 id using "hhxb", keepusing(hhxb05a)
drop if _merge==2
drop _merge
generate v2htn = 1 if hhxb05a=="Y"
replace v2htn = 0 if hhxb05a=="N"

merge 1:1 id using "PHXA04", keepusing(PHXA8A)		
drop if _merge==2
drop _merge
generate v3htn = 1 if PHXA8A=="Y"
replace v3htn = 0 if PHXA8A=="N"

merge 1:1 id using "phxb04", keepusing(phxb4)		
drop if _merge==2
drop _merge
generate v4htn = 1 if phxb4=="Y"
replace v4htn = 0 if phxb4=="N"



replace everdiab= 1 if (v1_diabts03==1 | v2_diabts23==1 | v3_diabts34==1 | v4_diabts42==1 | v5_diabts54==1 | diabts64==1)
replace everdiabdate= v1date01 if (everdiabdate>v1date01) & v1_diabts03==1
replace everdiabdateno= v1date01 if (everdiabdateno > v1date01) & (v1_diabts03==0)
replace everdiabdate= v2date21 if (everdiabdate>v2date21) & v2_diabts23==1
replace everdiabdateno= v2date21 if (everdiabdateno > v2date21) & (v2_diabts23==0)
replace everdiabdate= v3date31 if (everdiabdate>v3date31) & v3_diabts34==1
replace everdiabdateno= v3date31 if (everdiabdateno > v3date31) & (v3_diabts34==0)
replace everdiabdate= v4date41 if (everdiabdate>v4date41) & v4_diabts42==1
replace everdiabdateno= v4date41 if (everdiabdateno > v4date41) & (v4_diabts42==0)
replace everdiabdate= v5date51 if (everdiabdate>v5date51) & (v5_diabts54==1)
replace everdiabdateno = v5date51 if (everdiabdateno > v5date51) & (v5_diabts54==0)
replace everdiabdate= v6date61 if (everdiabdate>v6date61) & diabts64==1
replace everdiabdateno= v6date61 if (everdiabdateno > v6date61) & (diabts64==0)

replace everdiabdateno= . if everdiabdateno >= everdiabdate
recode everdiab . = 0 if !missing(everdiabdateno) 
generate everdiab2005= 1 if everdiabdate< date("January 1, 2005", "MDY")
replace everdiab2005= 0 if everdiab2005!=1 & !missing(everdiabdateno)


replace eversmoker= 1 if (v1_cigt01==1 | v1_cigt01==2 | v2_cigt21==1 | v2_cigt21==2| v3_cigt31==1 | v3_cigt31==2 | v4_cigt41==1 | v4_cigt41==2 | v5_cigt52==1 | v5_cigt52==2 | cursmk62==1)
replace eversmokerdate= v1date01 if (eversmokerdate>v1date01) & (v1_cigt01==1 | v1_cigt01==2)
replace eversmokerdateno= v1date01 if (eversmokerdateno> v1date01) & (v1_cigt01==3)
replace eversmokerdate= v2date21 if (eversmokerdate>v2date21) & (v2_cigt21==1 | v2_cigt21==2)
replace eversmokerdateno= v2date21 if (eversmokerdateno> v2date21) & (v2_cigt21==3)
replace eversmokerdate= v3date31 if (eversmokerdate>v3date31) & (v3_cigt31==1 | v3_cigt31==2)
replace eversmokerdateno= v3date31 if (eversmokerdateno> v3date31) & (v3_cigt31==3)
replace eversmokerdate= v4date41 if (eversmokerdate>v4date41) & (v4_cigt41==1 | v4_cigt41==2)
replace eversmokerdateno= v4date41 if (eversmokerdateno> v4date41) & (v4_cigt41==3)
replace eversmokerdate= v5date51 if (eversmokerdate>v5date51) & (v5_cigt52==1 | v5_cigt52==2)
replace eversmokerdateno= v5date51 if (eversmokerdateno> v5date51) & (v5_cigt52==3)
replace eversmokerdate= v6date61 if (eversmokerdate>v6date61) & (cursmk62==1)

replace eversmokerdateno= . if eversmokerdateno >= eversmokerdate
recode eversmoker . = 0 if !missing(eversmokerdateno) 
generate eversmoker2005= 1 if eversmokerdate< date("January 1, 2005", "MDY")
replace eversmoker2005= 0 if eversmoker2005!=1 & !missing(eversmokerdateno)	


//*use below commented out section instead of this section if self-reported HTN data not used
replace everhtn= 1 if (v1htn==1 | v1_hypert05==1 | v2htn==1 | v2_hypert25==1 | v3htn==1 | v3_hypert35==1 | v4htn==1 | v4_hypert45==1 | v5_hypert55==1 | hypert65==1)
replace everhtndate= v1date01 if (everhtndate>v1date01) & (v1htn==1 | v1_hypert05==1)
replace everhtndateno = v1date01 if (everhtndateno>v1date01) & (v1htn!=1 & v1_hypert05!=1) & (v1htn==0 | v1_hypert05==0)
replace everhtndate= v2date21 if (everhtndate>v2date21) & (v2htn==1 | v2_hypert25==1)
replace everhtndateno = v2date21 if (everhtndateno>v2date21) & (v2htn!=1 & v2_hypert25!=1) & (v2htn==0 | v2_hypert25==0)
replace everhtndate= v3date31 if (everhtndate>v3date31) & (v3htn==1 | v3_hypert35==1)
replace everhtndateno = v3date31 if (everhtndateno>v3date31) & (v3htn!=1 & v3_hypert35!=1) & (v3htn==0 | v3_hypert35==0)
replace everhtndate= v4date41 if (everhtndate>v4date41) & (v4htn==1 | v4_hypert45==1)
replace everhtndateno = v4date41 if (everhtndateno>v4date41) & (v4htn!=1 & v4_hypert45!=1) & (v4htn==0 | v4_hypert45==0)

/*
replace everhtn= 1 if (v1_hypert05==1 | v2_hypert25==1 | v3_hypert35==1 | v4_hypert45==1 | v5_hypert55==1 | hypert65==1)
replace everhtndate= v1date01 if (everhtndate>v1date01) & (v1_hypert05==1)
replace everhtndateno = v1date01 if (everhtndateno>v1date01) & (v1_hypert05==0)
replace everhtndate= v2date21 if (everhtndate>v2date21) & (v2_hypert25==1)
replace everhtndateno = v2date21 if (everhtndateno>v2date21) & (v2_hypert25==0)
replace everhtndate= v3date31 if (everhtndate>v3date31) & (v3_hypert35==1)
replace everhtndateno = v3date31 if (everhtndateno>v3date31) & (v3_hypert35==0)
replace everhtndate= v4date41 if (everhtndate>v4date41) & (v4_hypert45==1)
replace everhtndateno = v4date41 if (everhtndateno>v4date41) & (v4_hypert45==0)
*/

replace everhtndate= v5date51 if (everhtndate>v5date51) & (v5_hypert55==1)
replace everhtndateno= v5date51 if (everhtndateno>v5date51) & (v5_hypert55==0)
replace everhtndate= v6date61 if (everhtndate>v6date61) & (hypert65==1)
replace everhtndateno = v6date61 if (everhtndateno>v6date61) & (hypert65==0)

replace everhtndateno= . if everhtndateno > everhtndate
recode everhtn . = 0 if !missing(everhtndateno) 
generate everhtn2005= 1 if everhtndate< date("January 1, 2005", "MDY")	
replace everhtn2005= 0 if everhtn2005!=1 & !missing(everhtndateno)

generate everstroke=1 if v1stroke==1	
replace everstroke=0 if v1stroke==0															
generate everstrokedate= v1date01 if v1stroke==1
format everstrokedate %dD_m_Y
generate everstrokedateno= v1date01 if v1stroke==0
format everstrokedateno %dD_m_Y
replace everstroke=1 if C7_IN17DPP==1
replace everstrokedate= C7_ED17DPP if missing(everstrokedate) & C7_IN17DPP==1
generate everstroke2005= 1 if (everstrokedate< date("January 1, 2005", "MDY"))	
replace everstroke2005= 0 if everstroke2005!=1 & v1stroke==0

replace everaf=1 if afecgv1==1
replace everafdate=v1date01 if afecgv1==1
replace everaf=1 if (afincby11==1 | aflincby11==1)								//incident AF up to early Jan 2012
replace everafdate=dateafinc if (everafdate > dateafinc) & afincby11==1
replace everafdate=dateaflinc if (everafdate > dateaflinc) & aflincby11==1													
recode everaf . = 0 															//all without a. fib information are coded as 0
generate everafpre = 0 if afecgv1 != 1
generate everafdateno = v1date01 if afecgv1 != 1
format everafdateno %dD_m_Y
generate everaf2005= (everafdate< date("January 1, 2005", "MDY"))					


label var everdiab "Ever DM- AFU and Visits"
label var everdiabdate "Date of reported/detected DM"
generate everdiabpre = 0 if everdiab==1 & everdiabdateno < everdiabdate 
label var everdiabpre "Status before reported/detected DM"			//Notes whether DM is . or 0 before first reported/detected DM (for time-varying analyses)
label var everdiabdateno "Date of self-report of never DM"
label var everdiab2005 "Reported/detected DM as of 2005"

label var everhtn "Ever HTN- AFU and Visits"
label var everhtndate "Date of reported/detected HTN"
generate everhtnpre = 0 if everhtn==1 & everhtndateno < everhtndate
label var everhtnpre "Status before reported/detected HTN"
label var everhtndateno "Date of self-report of never HTN"
label var everhtn2005 "Reported/detected HTN as of 2005"

label var eversmoker "Ever smoking- AFU and Visits"
label var eversmokerdate "Date hist of smoking first reported"
generate eversmokerpre = 0 if eversmoker==1 & eversmokerdateno < eversmokerdate
label var eversmokerpre "Status before reported smoking"
label var eversmokerdateno "Date never-smoking first reported"
label var eversmoker2005 "Ever-smoking as of 2005"

label var everstroke "Ever stroke- V1 and adjudicated(C7_IN17DPP)"
label var everstrokedate "Date of reported/adjudicated stroke"
generate everstrokepre = 0 if everstroke==1 & everstrokedateno < everstrokedate
label var everstrokepre "Status before incident stroke"
label var everstrokedateno "Date never-stroke reported (V1 date, if N)"
label var everstroke2005 "Ever stroke as of 2005"

label var everaf "Ever AFib/fl- AFU and surveillance"
label var everafdate "Date fib/fl detected or history reported"
label var everaf2005 "Detected AF as of 2005- V1 and ICD codes"
label var everafpre "Status before AF (0 for all without AF on V1 ECG)"
label var everafdateno "Date of no AF (V1 for all without AF on V1 ECG)"

keep id CENSDAT7 everdiab everdiabdate everdiabpre everdiabdateno everdiab2005 everhtn everhtndate everhtnpre everhtndateno everhtn2005 eversmoker eversmokerdate eversmokerpre eversmokerdateno eversmoker2005 everstroke everstrokedate everstrokepre everstrokedateno everstroke2005 everaf everafdate everafpre everafdateno everaf2005

save "First_DM_HTN_AF_Stroke_Smoking.dta", replace
