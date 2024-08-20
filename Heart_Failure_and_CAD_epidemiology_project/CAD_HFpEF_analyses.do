//CAD and HFpEF Analyses in ARIC Cohort

//***ANALYSIS 1
//Cox regression for incident HF/HFpEF/HFrEF among participants free of HF as of 1/1/2005, with incident CHD and other variables as time-varying covariates

//***ANALYSIS 2*** 
//Impact of prevalent CAD as of Visit 5 on echo parameters and troponin at Visit 5 among HF-free participants with normal ejection fraction

//***ANALYSIS 3***
//Extent to which CAD-associated echocardiographic and biomarker measures account for the relationship between CAD and incident HF, HFpEF, and HFrEF



cd `"/Users/`c(username)'/Dropbox (Partners HealthCare)/Amil-Jenine share/Aric- CAD HFpEF/Analysis final files"'
cls
set autotabgraphs on 


use "ARICmaster_013019.dta", clear	

//Variable set-up
rename ech3	e3date		//date of Visit 5 echo
rename ech3y e3year		//year of echo
rename ech4 e4lvid		//LVID
rename ech6 e6septum	//IV septum thickness
rename ech7 e7pwt		//posterior wall thickness
generate e10ef = ech10  //EF 
replace e10ef = eco9 if !missing(eco9)		//(no overlap between ech10 and eco9)
rename ech12 e12lvmi	//LVMI
rename ech17 e17lavi	//LAVI
rename ech26 e26septale	//septal e'
rename ech20 e20E		//E
rename ech28 e28EAratio	//E/A
rename ech47 e47strain	//average peak longitudinal strain
generate Eeprime = e20E / e26septale

tabulate v1_center, generate(g)			//creates dummy variables for center
rename g1 centerF
rename g2 centerJ
rename g3 centerM
rename g4 centerW


replace v1_center = "1" if v1_center == "F"
replace v1_center = "2" if v1_center == "J"
replace v1_center = "3" if v1_center == "M"
replace v1_center = "4" if v1_center == "W"
destring v1_center, replace

generate race = 1 if black==1
replace race = 2 if white==1
replace race = 3 if asian==1
replace race = 4 if native_amer==1



save "ARICmaster_013019- CAD HFpEF.dta", replace




//***ANALYSIS 1
//Cox regression for incident HF/HFpEF/HFrEF among participants free of HF as of 1/1/2005, with incident CHD and other variables as time-varying covariates

use "ARICmaster_013019- CAD HFpEF.dta", clear

//used for Table 1- baseline characteristics in 2005
global tbl1cont "adjage mostrecentgfr mostrecentbmi mostrecentldl mostrecenthdl mostrecentchol mostrecenthb"
global tbl1skew mostrecenttg
global tbl1cat "female black everdiab2005 eversmoker2005 everhtn2005 everstroke2005 everaf2005 centerF centerJ centerM centerW"

//used as covariates in analysis
//global catcovariates "diab smoker htn stroke af"   [REMOVE?]


merge 1:1 id using "First_DM_HTN_AF_Stroke_Smoking.dta"            		//created using First_DM_HTN_AF_Stroke_Smoking creation.do
drop if _merge==2
drop _merge

merge 1:1 id using "phfa1104_singleentry.dta", keepusing(PHFA1 PHFA2A PHFA2B PHFA2B1 PHFA2Cdate)		//Physician heart failure survey data- generated using "phfa1104- Physician Heart Failure survey.do"
drop if _merge==2
drop _merge


drop if CENSDAT7 < date("January 1, 2005", "MDY")


drop if v1_prevhf01==1												
drop if C7_DATE_INCHF17 < date("January 1, 2005", "MDY")
drop if PHFA1=="Y" & PHFA2Cdate<date("January 1, 2005", "MDY")			//drop if HF before 1/1/2005 per Physician heart failure survey


count if missing(v4date41)												//1,730 with missing V4
count if missing(v4date41) & missing(v3date31) & missing(v2date21) 		//897 missing both V3 and V4; 371 missing V2, V3, and V4
						


generate adjage = (date("January 1, 2005", "MDY") - BIRTHDAT51)/365.25	//age as of 1/1/2005

generate diab=.
generate htn=.
generate smoker=.
generate stroke=.
generate af=.



//Earliest date of incident CHD
drop if missing(v1_prvchd05)

//740 had both MI and revasc; of these, 159 had first revasc before first MI, 577 had first revasc after first MI (148 within 3 days after MI, 319 within a week), and 4 had them on same day

generate incmi=1 if C7_DATEMI <= C7_DATEPROC & C7_MI17==1 & C7_DATEMI <= CENSDAT7
generate increvasc = 1 if (missing(incmi) | ((C7_DATEPROC < C7_DATEMI) & incmi==1)) & C7_CARDPROC==1 & C7_DATEPROC <= CENSDAT7 

generate lowestdate = C7_DATEMI if incmi==1 
replace lowestdate = C7_DATEPROC if increvasc==1
format lowestdate %dD_m_Y	

//replace lowestdate = C7_SMIDATE if C7_SMIDATE < lowestdate & C7_SMI_BY17==1   	//adds silent MI ****

replace lowestdate = v1date01 if v1_prvchd05==1         //sets lowest date as V1 date if patient has V1 prev CHD- later these patients are dropped b/c had CHD before 1/1/2005

count if v5_prvchd51==1 & missing(lowestdate)			//(22; all had silent MI except Subject F101162- developed CHD sometime before V5? did not have HF)
replace lowestdate=v5date51 if id=="F101162"			

drop if lowestdate < date("January 1, 2005", "MDY")		//drops those with prevalent CHD as of 1/1/2005


generate mostrecentbmi = v4_bmi41
replace mostrecentbmi = v3_bmi32 if missing(mostrecentbmi)
replace mostrecentbmi = v2_bmi21 if missing(mostrecentbmi)
replace mostrecentbmi = v1_bmi01 if missing(mostrecentbmi)

generate mostrecentgfr = v4_ckdepi_egfr
replace mostrecentgfr = v2_ckdepi_egfr if missing(mostrecentgfr)
replace mostrecentgfr = v1_ckdepi_egfr if missing(mostrecentgfr)

generate mostrecentldl = LDL_V4
replace mostrecentldl = LDL_V3 if missing(mostrecentldl)
replace mostrecentldl = LDL_V2 if missing(mostrecentldl)
replace mostrecentldl = LDL_V1 if missing(mostrecentldl)

generate mostrecenthdl = HDL_V4
replace mostrecenthdl = HDL_V3 if missing(mostrecenthdl)
replace mostrecenthdl = HDL_V2 if missing(mostrecenthdl)
replace mostrecenthdl = HDL_V1 if missing(mostrecenthdl)

generate mostrecentchol = TOTCHOL_V4
replace mostrecentchol = TOTCHOL_V3 if missing(mostrecentchol)
replace mostrecentchol = TOTCHOL_V2 if missing(mostrecentchol)
replace mostrecentchol = TOTCHOL_V1 if missing(mostrecentchol)

generate mostrecenttg = v4_lipd2a 
replace mostrecenttg = v3_LIPC2A if missing(mostrecenttg)
replace mostrecenttg = v2_lipb02a if missing(mostrecenttg)
replace mostrecenttg = v1_lipa02 if missing(mostrecenttg)

generate mostrecenthb = v4_hmtd4
replace mostrecenthb = v3_hmtc4 if missing(mostrecenthb)
replace mostrecenthb = v2_hmtb02 if missing(mostrecenthb)
replace mostrecenthb = v1_hmta02 if missing(mostrecenthb)


//generate histograms	
/*													
foreach var of varlist $tbl1cont $tbl1skew {
	histogram `var', frequency normal name(`var'_nl, replace)
	}
*/

save "ARICmaster_013019- CAD HFpEF2.dta", replace






use "ARICmaster_013019- CAD HFpEF2.dta", clear


//table1 $tbl1cont $tbl1cat, nonpar($tbl1skew)

//TABLE 1
display "variable" _column(20) "N" _column(40) "Mean" _column(60) "SD"					//would need median for skewed variable (TG), but TG not used for manuscript
foreach var of varlist $tbl1cont {
	quietly summarize `var'
	display `"`var'"' _column(20) r(N) _column(40) %9.1f r(mean) _column(60) %9.2f r(sd)
}


display "variable" _column(20) "Total N" _column(40) "Frequency" _column(55) "Percentage"
foreach var of varlist $tbl1cat {
	quietly tab `var', matcell(x)								
	display `"`var'"' _column(20) r(N) _column(40) x[2,1] _column(50) %9.1f (x[2,1]*100/r(N)) "%"
}





//checking if there is an intervening MI between initial CHD event and subsequent incident HF
use "c17evt1.dta", clear
rename id survid
rename chrt_id id
keep if (cmidx == "PROBMI" | cmidx == "DEFMI")

merge m:1 id using "ARICmaster_013019- CAD HFpEF2.dta", keepusing(lowestdate adjudhfdate CENSDAT7)
drop if _merge==2
drop _merge

gsort id cmidate
drop if cmidate > CENSDAT7

generate intervenmi = (cmidate> lowestdate & !missing(cmidate)) & ((cmidate < adjudhfdate) & !missing(adjudhfdate))
drop if intervenmi != 1
by id: egen intervenmidate = min(cmidate)
by id: drop if _n!=1

save "c17evt1 intervenmi.dta", replace







//Cox regression for CAD and HF	

cls
use "ARICmaster_013019- CAD HFpEF2.dta", clear

global catcovariates "diab smoker htn stroke af"

generate risktime=(adjudhfdate - date("January 1, 2005", "MDY"))

generate v5datesp = (v5date51 - date("January 1, 2005", "MDY")) 

foreach var of varlist $catcovariates {
	generate ever`var'datesp = (ever`var'date - date("January 1, 2005", "MDY"))
	replace ever`var'datesp = 0 if ((ever`var'date < date("January 1, 2005", "MDY")))
}

generate inchf = 0	


save "ARICmaster_013019- CAD HFpEF2.dta", replace



//The portions that are different between the analyses below are denoted by lines of asterisks





//----------------------------------------------------------------------------

//Results for the primary analysis; gives all HF, followed by HFpEF, then HFrEF
cls
use "ARICmaster_013019- CAD HFpEF2.dta", clear


//*************************************************************************
//For sex and race sensitivity analyses, uncomment the appropriate line below:
//keep if female==0
//keep if female==1
//keep if black==1
//keep if white==1


//CHD defined as both MI and revasc:
generate chdtime = C7_DATEMI - date("January 1, 2005", "MDY") if incmi==1
replace chdtime = C7_DATEPROC - date("January 1, 2005", "MDY") if increvasc==1
generate chdpresent = (increvasc==1 | incmi==1)
//*************************************************************************

forvalues i=1/3 {
	//*************************************************************************
	//To assess HF:
	replace inchf = (adjudhf_bwh==1 | adjudhf_bwh==2 | adjudhf_bwh==3) if `i'==1		//ref, pef, and unclassified
	replace inchf = (adjudhf_bwh==2) if `i'==2			//pef
	replace inchf = (adjudhf_bwh==1) if `i'==3			//ref
	//*************************************************************************

	stset risktime, failure(inchf==1) id(id)

	stsplit timeafterchd if chdpresent==1, at(0 90 365) after(chdtime) 
	replace timeafterchd = timeafterchd + 1 if chdpresent==1
	recode timeafterchd . = 0

	foreach var of varlist $catcovariates {
		stsplit ever`var'split, at(0) after(ever`var'datesp) 
		replace ever`var'split = ever`var'split + 1 if ever`var'==1	
		recode ever`var'split . = 0
		replace ever`var'split = ever`var'pre if ever`var'split==0 & !missing(ever`var'datesp)
	}
	
	stsplit bmisplit if !missing(v5_bmi51), at(0) after(v5datesp)
	replace bmisplit = bmisplit + 1 if !missing(v5_bmi51)
	replace bmisplit = mostrecentbmi if (bmisplit==0 | missing(bmisplit))
	replace bmisplit = v5_bmi51 if bmisplit==1

	stsplit gfrsplit if !missing(v5_ckdepi_egfr), at(0) after(v5datesp)
	replace gfrsplit = gfrsplit + 1 if !missing(v5_ckdepi_egfr)
	replace gfrsplit = mostrecentgfr if (gfrsplit==0 | missing(gfrsplit))
	replace gfrsplit = v5_ckdepi_egfr if gfrsplit==1

	
	generate gfrsq = gfrsplit * gfrsplit

	generate bmisq = bmisplit * bmisplit


	egen racesex = group(black female)


	stcox i.timeafterchd adjage i.racesex i.everhtnsplit i.everafsplit i.everstrokesplit gfrsplit gfrsq bmisplit bmisq, strata(everdiabsplit eversmokersplit v1_center)

	//estat ic 
	//sts graph, failure
	//sts graph, by(timeafterchd) name(timeafterchd, replace)

	estat phtest, detail

	generate in_mod = e(sample)
	strate timeafterchd if in_mod==1, per(36525)

	//stphplot, by(timeafterchd) name(timeafterchd_PropHazTest, replace)

	egen strata = group(v1_center everdiabsplit eversmokersplit)

	generate exptime = (_t - _t0)/36525
	
	quietly: poisson _d i.timeafterchd adjage i.racesex i.everhtnsplit i.everafsplit i.everstrokesplit gfrsplit gfrsq bmisplit bmisq i.strata, exp(exptime)

	replace exptime=1
	margins timeafterchd, predict(xb) 

	
	matrix Output = r(table)
	matlist Output

	matrix Values = J(4,3,.)
	forvalues k=1/4 {
		matrix Values[`k',1] = Output[1,`k']
		matrix Values[`k',2] = Output[5,`k']
		matrix Values[`k',3] = Output[6,`k']
	}

	matlist Values

	mata: st_matrix("ValuesExp", exp(st_matrix("Values")))
	matrix colnames ValuesExp = "Margin" "Lower CI" "Upper CI"
	matrix rownames ValuesExp = "time0" "time1" "time91" "time366"
	matlist ValuesExp

	drop timeafterchd gfrsplit bmisplit gfrsq bmisq racesex in_mod 
	capture drop strata exptime 

	foreach var of varlist $catcovariates {
		drop ever`var'split
	}
		
	stjoin
}






//------------------------------------------------------------------------------
//Checking for effect modification by sex
//Results for the primary analysis; gives all HF, followed by HFpEF, then HFrEF
cls
use "ARICmaster_013019- CAD HFpEF2.dta", clear


//*************************************************************************
//For sex and race sensitivity analyses, uncomment the appropriate line below:
//keep if female==0
//keep if female==1
//keep if black==1
//keep if white==1


//CHD defined as both MI and revasc:
generate chdtime = C7_DATEMI - date("January 1, 2005", "MDY") if incmi==1
replace chdtime = C7_DATEPROC - date("January 1, 2005", "MDY") if increvasc==1
generate chdpresent = (increvasc==1 | incmi==1)
//*************************************************************************

forvalues i=1/3 {
	//*************************************************************************
	//To assess HF:
	replace inchf = (adjudhf_bwh==1 | adjudhf_bwh==2 | adjudhf_bwh==3) if `i'==1		//ref, pef, and unclassified
	replace inchf = (adjudhf_bwh==2) if `i'==2			//pef
	replace inchf = (adjudhf_bwh==1) if `i'==3			//ref
	//*************************************************************************

	stset risktime, failure(inchf==1) id(id)

	stsplit timeafterchd if chdpresent==1, at(0 90 365) after(chdtime) 
	replace timeafterchd = timeafterchd + 1 if chdpresent==1
	recode timeafterchd . = 0

	foreach var of varlist $catcovariates {
		stsplit ever`var'split, at(0) after(ever`var'datesp) 
		replace ever`var'split = ever`var'split + 1 if ever`var'==1	
		recode ever`var'split . = 0
		replace ever`var'split = ever`var'pre if ever`var'split==0 & !missing(ever`var'datesp)
	}
	
	stsplit bmisplit if !missing(v5_bmi51), at(0) after(v5datesp)
	replace bmisplit = bmisplit + 1 if !missing(v5_bmi51)
	replace bmisplit = mostrecentbmi if (bmisplit==0 | missing(bmisplit))
	replace bmisplit = v5_bmi51 if bmisplit==1

	stsplit gfrsplit if !missing(v5_ckdepi_egfr), at(0) after(v5datesp)
	replace gfrsplit = gfrsplit + 1 if !missing(v5_ckdepi_egfr)
	replace gfrsplit = mostrecentgfr if (gfrsplit==0 | missing(gfrsplit))
	replace gfrsplit = v5_ckdepi_egfr if gfrsplit==1

	
	generate gfrsq = gfrsplit * gfrsplit

	generate bmisq = bmisplit * bmisplit


	egen racesex = group(black female)

	//***************************************************************************
	stcox i.timeafterchd adjage i.racesex i.everhtnsplit i.everafsplit i.everstrokesplit gfrsplit gfrsq bmisplit bmisq i.timeafterchd##i.female, strata(everdiabsplit eversmokersplit v1_center)

	testparm i.timeafterchd#i.female
	//***************************************************************************
	
	drop timeafterchd gfrsplit bmisplit gfrsq bmisq racesex 
	capture drop in_mod 
	capture drop strata exptime 

	foreach var of varlist $catcovariates {
		capture drop ever`var'split
	}
		
	stjoin
}




//------------------------------------------------------------------------------
//Checking for effect modification by race
//Results for the primary analysis; gives all HF, followed by HFpEF, then HFrEF
cls
use "ARICmaster_013019- CAD HFpEF2.dta", clear


//*************************************************************************
//For sex and race sensitivity analyses, uncomment the appropriate line below:
//keep if female==0
//keep if female==1
//keep if black==1
//keep if white==1


//CHD defined as both MI and revasc:
generate chdtime = C7_DATEMI - date("January 1, 2005", "MDY") if incmi==1
replace chdtime = C7_DATEPROC - date("January 1, 2005", "MDY") if increvasc==1
generate chdpresent = (increvasc==1 | incmi==1)
//*************************************************************************


//****************************************************
preserve
keep if (black==1 | white==1)

forvalues i=1/3 {
	//*************************************************************************
	//To assess HF:
	replace inchf = (adjudhf_bwh==1 | adjudhf_bwh==2 | adjudhf_bwh==3) if `i'==1		//ref, pef, and unclassified
	replace inchf = (adjudhf_bwh==2) if `i'==2			//pef
	replace inchf = (adjudhf_bwh==1) if `i'==3			//ref
	//*************************************************************************

	stset risktime, failure(inchf==1) id(id)

	stsplit timeafterchd if chdpresent==1, at(0 90 365) after(chdtime) 
	replace timeafterchd = timeafterchd + 1 if chdpresent==1
	recode timeafterchd . = 0

	foreach var of varlist $catcovariates {
		stsplit ever`var'split, at(0) after(ever`var'datesp) 
		replace ever`var'split = ever`var'split + 1 if ever`var'==1	
		recode ever`var'split . = 0
		replace ever`var'split = ever`var'pre if ever`var'split==0 & !missing(ever`var'datesp)
	}
	
	stsplit bmisplit if !missing(v5_bmi51), at(0) after(v5datesp)
	replace bmisplit = bmisplit + 1 if !missing(v5_bmi51)
	replace bmisplit = mostrecentbmi if (bmisplit==0 | missing(bmisplit))
	replace bmisplit = v5_bmi51 if bmisplit==1

	stsplit gfrsplit if !missing(v5_ckdepi_egfr), at(0) after(v5datesp)
	replace gfrsplit = gfrsplit + 1 if !missing(v5_ckdepi_egfr)
	replace gfrsplit = mostrecentgfr if (gfrsplit==0 | missing(gfrsplit))
	replace gfrsplit = v5_ckdepi_egfr if gfrsplit==1

	
	generate gfrsq = gfrsplit * gfrsplit

	generate bmisq = bmisplit * bmisplit


	egen racesex = group(black female)

	//***************************************************************************
	stcox i.timeafterchd adjage i.racesex i.everhtnsplit i.everafsplit i.everstrokesplit gfrsplit gfrsq bmisplit bmisq i.timeafterchd##i.black, strata(everdiabsplit eversmokersplit v1_center)

	testparm i.timeafterchd#i.black
	//***************************************************************************
	
	drop timeafterchd gfrsplit bmisplit gfrsq bmisq racesex 
	capture drop in_mod 
	capture drop strata exptime 

	foreach var of varlist $catcovariates {
		capture drop ever`var'split
	}
		
	stjoin
}
//********************************************
restore
//********************************************






//------------------------------------------------------------------------------

//Results for CAD defined as MI only (revasc censored)
cls
use "ARICmaster_013019- CAD HFpEF2.dta", clear

//*************************************************************************
//For CHD defined as MI only (revasc censored):
generate chdtime = C7_DATEMI - date("January 1, 2005", "MDY") if incmi==1
generate chdpresent = (incmi==1)

replace adjudhf_bwh=. if increvasc==1 & C7_DATEPROC < adjudhfdate
replace adjudhfdate = C7_DATEPROC if increvasc==1 & C7_DATEPROC < adjudhfdate
//*************************************************************************


forvalues i=1/3 {
	//*************************************************************************
	//To assess HF:
	replace inchf = (adjudhf_bwh==1 | adjudhf_bwh==2 | adjudhf_bwh==3) if `i'==1		//ref, pef, and unclassified
	replace inchf = (adjudhf_bwh==2) if `i'==2			//pef
	replace inchf = (adjudhf_bwh==1) if `i'==3			//ref
	//*************************************************************************


	stset risktime, failure(inchf==1) id(id)

	stsplit timeafterchd if chdpresent==1, at(0 90 365) after(chdtime) 
	replace timeafterchd = timeafterchd + 1 if chdpresent==1
	recode timeafterchd . = 0

	foreach var of varlist $catcovariates {
		stsplit ever`var'split, at(0) after(ever`var'datesp) 
		replace ever`var'split = ever`var'split + 1 if ever`var'==1	
		recode ever`var'split . = 0
		replace ever`var'split = ever`var'pre if ever`var'split==0 & !missing(ever`var'datesp)
	}
	
	stsplit bmisplit if !missing(v5_bmi51), at(0) after(v5datesp)
	replace bmisplit = bmisplit + 1 if !missing(v5_bmi51)
	replace bmisplit = mostrecentbmi if (bmisplit==0 | missing(bmisplit))
	replace bmisplit = v5_bmi51 if bmisplit==1

	stsplit gfrsplit if !missing(v5_ckdepi_egfr), at(0) after(v5datesp)
	replace gfrsplit = gfrsplit + 1 if !missing(v5_ckdepi_egfr)
	replace gfrsplit = mostrecentgfr if (gfrsplit==0 | missing(gfrsplit))
	replace gfrsplit = v5_ckdepi_egfr if gfrsplit==1

	
	generate gfrsq = gfrsplit * gfrsplit

	generate bmisq = bmisplit * bmisplit

	egen racesex = group(black female)


	stcox i.timeafterchd adjage i.racesex i.everhtnsplit i.everafsplit i.everstrokesplit gfrsplit gfrsq bmisplit bmisq, strata(everdiabsplit eversmokersplit v1_center)
	
	estat phtest, detail

	generate in_mod = e(sample)
	strate timeafterchd if in_mod==1, per(36525)


	egen strata = group(v1_center everdiabsplit eversmokersplit)


	generate exptime = (_t - _t0)/36525
	
	quietly: poisson _d i.timeafterchd adjage i.racesex i.everhtnsplit i.everafsplit i.everstrokesplit gfrsplit gfrsq bmisplit bmisq i.strata, exp(exptime)

	replace exptime=1
	margins timeafterchd, predict(xb) 

	
	matrix Output = r(table)
	matlist Output

	matrix Values = J(4,3,.)
	forvalues k=1/4 {
		matrix Values[`k',1] = Output[1,`k']
		matrix Values[`k',2] = Output[5,`k']
		matrix Values[`k',3] = Output[6,`k']
	}

	matlist Values

	mata: st_matrix("ValuesExp", exp(st_matrix("Values")))
	matrix colnames ValuesExp = "Margin" "Lower CI" "Upper CI"
	matrix rownames ValuesExp = "time0" "time1" "time91" "time366"
	matlist ValuesExp

	drop timeafterchd gfrsplit bmisplit gfrsq bmisq racesex in_mod 
	capture drop strata exptime 

	foreach var of varlist $catcovariates {
		drop ever`var'split
	}
		
	stjoin
}





//------------------------------------------------------------------------------

//Results for CAD defined as revasc only (MI censored)
cls
use "ARICmaster_013019- CAD HFpEF2.dta", clear

	
//*************************************************************************
//For CHD defined as revasc only (MI censored):
generate chdtime = C7_DATEPROC - date("January 1, 2005", "MDY") if increvasc==1
generate chdpresent = (increvasc==1)

replace adjudhf_bwh=. if incmi==1 & C7_DATEMI < adjudhfdate
replace adjudhfdate = C7_DATEMI if incmi==1 & C7_DATEMI < adjudhfdate
//*************************************************************************


forvalues i=1/3 {
	//*************************************************************************
	//To assess HF:
	replace inchf = (adjudhf_bwh==1 | adjudhf_bwh==2 | adjudhf_bwh==3) if `i'==1		//ref, pef, and unclassified
	replace inchf = (adjudhf_bwh==2) if `i'==2			//pef
	replace inchf = (adjudhf_bwh==1) if `i'==3			//ref
	//*************************************************************************

	stset risktime, failure(inchf==1) id(id)

	stsplit timeafterchd if chdpresent==1, at(0 90 365) after(chdtime) 
	replace timeafterchd = timeafterchd + 1 if chdpresent==1
	recode timeafterchd . = 0

	foreach var of varlist $catcovariates {
		stsplit ever`var'split, at(0) after(ever`var'datesp) 
		replace ever`var'split = ever`var'split + 1 if ever`var'==1	
		recode ever`var'split . = 0
		replace ever`var'split = ever`var'pre if ever`var'split==0 & !missing(ever`var'datesp)
	}
	
	stsplit bmisplit if !missing(v5_bmi51), at(0) after(v5datesp)
	replace bmisplit = bmisplit + 1 if !missing(v5_bmi51)
	replace bmisplit = mostrecentbmi if (bmisplit==0 | missing(bmisplit))
	replace bmisplit = v5_bmi51 if bmisplit==1

	stsplit gfrsplit if !missing(v5_ckdepi_egfr), at(0) after(v5datesp)
	replace gfrsplit = gfrsplit + 1 if !missing(v5_ckdepi_egfr)
	replace gfrsplit = mostrecentgfr if (gfrsplit==0 | missing(gfrsplit))
	replace gfrsplit = v5_ckdepi_egfr if gfrsplit==1

	
	generate gfrsq = gfrsplit * gfrsplit

	generate bmisq = bmisplit * bmisplit


	egen racesex = group(black female)


	stcox i.timeafterchd adjage i.racesex i.everhtnsplit i.everafsplit i.everstrokesplit gfrsplit gfrsq bmisplit bmisq, strata(everdiabsplit eversmokersplit v1_center)


	estat phtest, detail

	generate in_mod = e(sample)
	strate timeafterchd if in_mod==1, per(36525)


	egen strata = group(v1_center everdiabsplit eversmokersplit)


	generate exptime = (_t - _t0)/36525
	
	quietly: poisson _d i.timeafterchd adjage i.racesex i.everhtnsplit i.everafsplit i.everstrokesplit gfrsplit gfrsq bmisplit bmisq i.strata, exp(exptime)

	replace exptime=1
	margins timeafterchd, predict(xb) 

	
	matrix Output = r(table)
	matlist Output

	matrix Values = J(4,3,.)
	forvalues k=1/4 {
		matrix Values[`k',1] = Output[1,`k']
		matrix Values[`k',2] = Output[5,`k']
		matrix Values[`k',3] = Output[6,`k']
	}

	matlist Values

	mata: st_matrix("ValuesExp", exp(st_matrix("Values")))
	matrix colnames ValuesExp = "Margin" "Lower CI" "Upper CI"
	matrix rownames ValuesExp = "time0" "time1" "time91" "time366"
	matlist ValuesExp

	drop timeafterchd gfrsplit bmisplit gfrsq bmisq racesex in_mod 
	capture drop strata exptime 

	foreach var of varlist $catcovariates {
		drop ever`var'split
	}
		
	stjoin
}





//------------------------------------------------------------------------------
//Results for unclassified HF cases added to HFpEF category, then to HFrEF category (loop changed to 2 iterations)
cls
use "ARICmaster_013019- CAD HFpEF2.dta", clear

//*************************************************************************
//CHD defined as both MI and revasc:
generate chdtime = C7_DATEMI - date("January 1, 2005", "MDY") if incmi==1
replace chdtime = C7_DATEPROC - date("January 1, 2005", "MDY") if increvasc==1
generate chdpresent = (increvasc==1 | incmi==1)
//*************************************************************************


forvalues i=1/2 {
	//*************************************************************************
	//To move all unclassified to either pEF or rEF groups:
	replace inchf = (adjudhf_bwh==2 | adjudhf_bwh==3) if `i'==1			//pef + unclassified
	replace inchf = (adjudhf_bwh==1 | adjudhf_bwh==3) if `i'==2			//ref + unclassified
	//*************************************************************************

	stset risktime, failure(inchf==1) id(id)

	stsplit timeafterchd if chdpresent==1, at(0 90 365) after(chdtime) 
	replace timeafterchd = timeafterchd + 1 if chdpresent==1
	recode timeafterchd . = 0

	foreach var of varlist $catcovariates {
		stsplit ever`var'split, at(0) after(ever`var'datesp) 
		replace ever`var'split = ever`var'split + 1 if ever`var'==1	
		recode ever`var'split . = 0
		replace ever`var'split = ever`var'pre if ever`var'split==0 & !missing(ever`var'datesp)
	}
	
	stsplit bmisplit if !missing(v5_bmi51), at(0) after(v5datesp)
	replace bmisplit = bmisplit + 1 if !missing(v5_bmi51)
	replace bmisplit = mostrecentbmi if (bmisplit==0 | missing(bmisplit))
	replace bmisplit = v5_bmi51 if bmisplit==1

	stsplit gfrsplit if !missing(v5_ckdepi_egfr), at(0) after(v5datesp)
	replace gfrsplit = gfrsplit + 1 if !missing(v5_ckdepi_egfr)
	replace gfrsplit = mostrecentgfr if (gfrsplit==0 | missing(gfrsplit))
	replace gfrsplit = v5_ckdepi_egfr if gfrsplit==1

	
	generate gfrsq = gfrsplit * gfrsplit

	generate bmisq = bmisplit * bmisplit


	egen racesex = group(black female)


	stcox i.timeafterchd adjage i.racesex i.everhtnsplit i.everafsplit i.everstrokesplit gfrsplit gfrsq bmisplit bmisq, strata(everdiabsplit eversmokersplit v1_center)

	estat phtest, detail

	generate in_mod = e(sample)
	strate timeafterchd if in_mod==1, per(36525)


	egen strata = group(v1_center everdiabsplit eversmokersplit)


	generate exptime = (_t - _t0)/36525
	
	quietly: poisson _d i.timeafterchd adjage i.racesex i.everhtnsplit i.everafsplit i.everstrokesplit gfrsplit gfrsq bmisplit bmisq i.strata, exp(exptime)

	replace exptime=1
	margins timeafterchd, predict(xb) 

	
	matrix Output = r(table)
	matlist Output

	matrix Values = J(4,3,.)
	forvalues k=1/4 {
		matrix Values[`k',1] = Output[1,`k']
		matrix Values[`k',2] = Output[5,`k']
		matrix Values[`k',3] = Output[6,`k']
	}

	matlist Values

	mata: st_matrix("ValuesExp", exp(st_matrix("Values")))
	matrix colnames ValuesExp = "Margin" "Lower CI" "Upper CI"
	matrix rownames ValuesExp = "time0" "time1" "time91" "time366"
	matlist ValuesExp

	drop timeafterchd gfrsplit bmisplit gfrsq bmisq racesex in_mod 
	capture drop strata exptime 

	foreach var of varlist $catcovariates {
		drop ever`var'split
	}
		
	stjoin
}





//------------------------------------------------------------------------------

//Results for censoring of participants who develop an MI after the incident CAD event
cls
use "ARICmaster_013019- CAD HFpEF2.dta", clear

//*************************************************************************
//CHD defined as both MI and revasc:
generate chdtime = C7_DATEMI - date("January 1, 2005", "MDY") if incmi==1
replace chdtime = C7_DATEPROC - date("January 1, 2005", "MDY") if increvasc==1
generate chdpresent = (increvasc==1 | incmi==1)


//To censor intervening MI:
merge 1:1 id using "c17evt1 intervenmi.dta", keepusing(intervenmi intervenmidate)
drop if _merge==2
drop _merge

replace adjudhf_bwh =. if intervenmi==1 
replace adjudhfdate = intervenmidate if intervenmi==1 & intervenmidate < adjudhfdate
//*************************************************************************


forvalues i=1/3 {
	//*************************************************************************
	//To assess HF:
	replace inchf = (adjudhf_bwh==1 | adjudhf_bwh==2 | adjudhf_bwh==3) if `i'==1		//ref, pef, and unclassified
	replace inchf = (adjudhf_bwh==2) if `i'==2			//pef
	replace inchf = (adjudhf_bwh==1) if `i'==3			//ref
	//*************************************************************************

	stset risktime, failure(inchf==1) id(id)

	stsplit timeafterchd if chdpresent==1, at(0 90 365) after(chdtime) 
	replace timeafterchd = timeafterchd + 1 if chdpresent==1
	recode timeafterchd . = 0

	foreach var of varlist $catcovariates {
		stsplit ever`var'split, at(0) after(ever`var'datesp) 
		replace ever`var'split = ever`var'split + 1 if ever`var'==1	
		recode ever`var'split . = 0
		replace ever`var'split = ever`var'pre if ever`var'split==0 & !missing(ever`var'datesp)
	}
	
	stsplit bmisplit if !missing(v5_bmi51), at(0) after(v5datesp)
	replace bmisplit = bmisplit + 1 if !missing(v5_bmi51)
	replace bmisplit = mostrecentbmi if (bmisplit==0 | missing(bmisplit))
	replace bmisplit = v5_bmi51 if bmisplit==1

	stsplit gfrsplit if !missing(v5_ckdepi_egfr), at(0) after(v5datesp)
	replace gfrsplit = gfrsplit + 1 if !missing(v5_ckdepi_egfr)
	replace gfrsplit = mostrecentgfr if (gfrsplit==0 | missing(gfrsplit))
	replace gfrsplit = v5_ckdepi_egfr if gfrsplit==1

	
	generate gfrsq = gfrsplit * gfrsplit

	generate bmisq = bmisplit * bmisplit


	egen racesex = group(black female)

	stcox i.timeafterchd adjage i.racesex i.everhtnsplit i.everafsplit i.everstrokesplit gfrsplit gfrsq bmisplit bmisq, strata(everdiabsplit eversmokersplit v1_center)


	estat phtest, detail

	generate in_mod = e(sample)
	strate timeafterchd if in_mod==1, per(36525)


	egen strata = group(v1_center everdiabsplit eversmokersplit)


	generate exptime = (_t - _t0)/36525
	
	quietly: poisson _d i.timeafterchd adjage i.racesex i.everhtnsplit i.everafsplit i.everstrokesplit gfrsplit gfrsq bmisplit bmisq i.strata, exp(exptime)


	replace exptime=1
	margins timeafterchd, predict(xb) 

	
	matrix Output = r(table)
	matlist Output

	matrix Values = J(4,3,.)
	forvalues k=1/4 {
		matrix Values[`k',1] = Output[1,`k']
		matrix Values[`k',2] = Output[5,`k']
		matrix Values[`k',3] = Output[6,`k']
	}

	matlist Values

	mata: st_matrix("ValuesExp", exp(st_matrix("Values")))
	matrix colnames ValuesExp = "Margin" "Lower CI" "Upper CI"
	matrix rownames ValuesExp = "time0" "time1" "time91" "time366"
	matlist ValuesExp

	drop timeafterchd gfrsplit bmisplit gfrsq bmisq racesex in_mod 
	capture drop strata exptime 

	foreach var of varlist $catcovariates {
		drop ever`var'split
	}
		
	stjoin
}







//------------------------------------------------------------------------------

//Results for censoring pf participants for whom the hospitalization for initial CAD was also adjudicated as a HF hospitalization
cls
use "ARICmaster_013019- CAD HFpEF2.dta", clear

//*************************************************************************
//CHD defined as both MI and revasc:
generate chdtime = C7_DATEMI - date("January 1, 2005", "MDY") if incmi==1
replace chdtime = C7_DATEPROC - date("January 1, 2005", "MDY") if increvasc==1
generate chdpresent = (increvasc==1 | incmi==1)

//To censor at hospitalization for MI + HF:
//file below created with "adjudhf without mi with hf.do"- patients with first HF occurring during an MI hospitalization are labeled as adjudhf_bwh2=4 and the date of that hospitalization is adjudhfdate2
merge 1:1 id using "adjudicatedhf without mi with hf.dta", keepusing(adjudhf_bwh2 adjudhfef2 adjudhfdate2 adjudhfchfdiag2)  
drop if _merge==2
drop _merge
replace adjudhfdate2 = CENSDAT7 if missing(adjudhfdate2)
replace risktime = (adjudhfdate2 - date("January 1, 2005", "MDY"))
//*************************************************************************


forvalues i=1/3 {
	//*************************************************************************
	//To censor at hospitalization for MI + HF:
	replace inchf = (adjudhf_bwh2==1 | adjudhf_bwh2==2 | adjudhf_bwh2==3) if `i'==1		//ref, pef, and unclassified
	replace inchf = (adjudhf_bwh2==2) if `i'==2			//pef
	replace inchf = (adjudhf_bwh2==1) if `i'==3	
	//*************************************************************************

	stset risktime, failure(inchf==1) id(id)

	stsplit timeafterchd if chdpresent==1, at(0 90 365) after(chdtime) 
	replace timeafterchd = timeafterchd + 1 if chdpresent==1
	recode timeafterchd . = 0

	foreach var of varlist $catcovariates {
		stsplit ever`var'split, at(0) after(ever`var'datesp) 
		replace ever`var'split = ever`var'split + 1 if ever`var'==1	
		recode ever`var'split . = 0
		replace ever`var'split = ever`var'pre if ever`var'split==0 & !missing(ever`var'datesp)
	}
	
	stsplit bmisplit if !missing(v5_bmi51), at(0) after(v5datesp)
	replace bmisplit = bmisplit + 1 if !missing(v5_bmi51)
	replace bmisplit = mostrecentbmi if (bmisplit==0 | missing(bmisplit))
	replace bmisplit = v5_bmi51 if bmisplit==1

	stsplit gfrsplit if !missing(v5_ckdepi_egfr), at(0) after(v5datesp)
	replace gfrsplit = gfrsplit + 1 if !missing(v5_ckdepi_egfr)
	replace gfrsplit = mostrecentgfr if (gfrsplit==0 | missing(gfrsplit))
	replace gfrsplit = v5_ckdepi_egfr if gfrsplit==1

	
	generate gfrsq = gfrsplit * gfrsplit

	generate bmisq = bmisplit * bmisplit

	egen racesex = group(black female)

	stcox i.timeafterchd adjage i.racesex i.everhtnsplit i.everafsplit i.everstrokesplit gfrsplit gfrsq bmisplit bmisq, strata(everdiabsplit eversmokersplit v1_center)


	estat phtest, detail

	generate in_mod = e(sample)
	strate timeafterchd if in_mod==1, per(36525)


	egen strata = group(v1_center everdiabsplit eversmokersplit)


	generate exptime = (_t - _t0)/36525
	
	quietly: poisson _d i.timeafterchd adjage i.racesex i.everhtnsplit i.everafsplit i.everstrokesplit gfrsplit gfrsq bmisplit bmisq i.strata, exp(exptime)

	replace exptime=1
	margins timeafterchd, predict(xb) 

	
	matrix Output = r(table)
	matlist Output

	matrix Values = J(4,3,.)
	forvalues k=1/4 {
		matrix Values[`k',1] = Output[1,`k']
		matrix Values[`k',2] = Output[5,`k']
		matrix Values[`k',3] = Output[6,`k']
	}

	matlist Values

	mata: st_matrix("ValuesExp", exp(st_matrix("Values")))
	matrix colnames ValuesExp = "Margin" "Lower CI" "Upper CI"
	matrix rownames ValuesExp = "time0" "time1" "time91" "time366"
	matlist ValuesExp

	drop timeafterchd gfrsplit bmisplit gfrsq bmisq racesex in_mod 
	drop strata exptime 

	foreach var of varlist $catcovariates {
		drop ever`var'split
	}
		
	stjoin
}





//------------------------------------------------------------------------------

//Results for composite outcome of incident HF and death (not separating because same deaths would be added to HFpEF group and HFrEF group)
//loop not needed so eliminated
cls
use "ARICmaster_013019- CAD HFpEF2.dta", clear

//*************************************************************************
//CHD defined as both MI and revasc:
generate chdtime = C7_DATEMI - date("January 1, 2005", "MDY") if incmi==1
replace chdtime = C7_DATEPROC - date("January 1, 2005", "MDY") if increvasc==1
generate chdpresent = (increvasc==1 | incmi==1)

//For composite outcome of death and HF:
egen adjudhfdate3 = rowmin(adjudhfdate DATED17)
format adjudhfdate3 %dD_m_Y	
//*************************************************************************


	//*************************************************************************
	//****To assess composite endpoint of HF and death:
	replace inchf = (adjudhf_bwh==1 | adjudhf_bwh==2 | adjudhf_bwh==3 | (!missing(DATED17) & DATED17<=adjudhfdate))
	replace risktime=(adjudhfdate3 - date("January 1, 2005", "MDY")) 
	//*************************************************************************


	stset risktime, failure(inchf==1) id(id)

	stsplit timeafterchd if chdpresent==1, at(0 90 365) after(chdtime) 
	replace timeafterchd = timeafterchd + 1 if chdpresent==1
	recode timeafterchd . = 0

	foreach var of varlist $catcovariates {
		stsplit ever`var'split, at(0) after(ever`var'datesp) 
		replace ever`var'split = ever`var'split + 1 if ever`var'==1	
		recode ever`var'split . = 0
		replace ever`var'split = ever`var'pre if ever`var'split==0 & !missing(ever`var'datesp)
	}
	
	stsplit bmisplit if !missing(v5_bmi51), at(0) after(v5datesp)
	replace bmisplit = bmisplit + 1 if !missing(v5_bmi51)
	replace bmisplit = mostrecentbmi if (bmisplit==0 | missing(bmisplit))
	replace bmisplit = v5_bmi51 if bmisplit==1

	stsplit gfrsplit if !missing(v5_ckdepi_egfr), at(0) after(v5datesp)
	replace gfrsplit = gfrsplit + 1 if !missing(v5_ckdepi_egfr)
	replace gfrsplit = mostrecentgfr if (gfrsplit==0 | missing(gfrsplit))
	replace gfrsplit = v5_ckdepi_egfr if gfrsplit==1

	
	generate gfrsq = gfrsplit * gfrsplit

	generate bmisq = bmisplit * bmisplit


	egen racesex = group(black female)


	stcox i.timeafterchd adjage i.racesex i.everhtnsplit i.everafsplit i.everstrokesplit gfrsplit gfrsq bmisplit bmisq, strata(everdiabsplit eversmokersplit v1_center)


	estat phtest, detail

	generate in_mod = e(sample)
	strate timeafterchd if in_mod==1, per(36525)


	egen strata = group(v1_center everdiabsplit eversmokersplit)

	generate exptime = (_t - _t0)/36525
	
	quietly: poisson _d i.timeafterchd adjage i.racesex i.everhtnsplit i.everafsplit i.everstrokesplit gfrsplit gfrsq bmisplit bmisq i.strata, exp(exptime)
	

	replace exptime=1
	margins timeafterchd, predict(xb) 

	
	matrix Output = r(table)
	matlist Output

	matrix Values = J(4,3,.)
	forvalues k=1/4 {
		matrix Values[`k',1] = Output[1,`k']
		matrix Values[`k',2] = Output[5,`k']
		matrix Values[`k',3] = Output[6,`k']
	}

	matlist Values

	mata: st_matrix("ValuesExp", exp(st_matrix("Values")))
	matrix colnames ValuesExp = "Margin" "Lower CI" "Upper CI"
	matrix rownames ValuesExp = "time0" "time1" "time91" "time366"
	matlist ValuesExp

	drop timeafterchd gfrsplit bmisplit gfrsq bmisq racesex in_mod 
	drop strata exptime 

	foreach var of varlist $catcovariates {
		drop ever`var'split
	}
		
	stjoin


//------------------------------------------------------------------------------

//ADDITIONAL SENSITIVY ANALYSIS ADDED FEB 26 2020
//Results if adjudhf _withmi variables are used, which count HF hospitalizations where MI is also diagnosed as a HF hospitalization (instead of excluding it)
//Cox regression for CAD and HF	

cls
use "ARICmaster_013019- CAD HFpEF2.dta", clear

global catcovariates "diab smoker htn stroke af"


***************************
//Additional lines for this sensitivity analysis
//also, "_withmi" is added to the end of adjudhf variables 
merge 1:1 id using "adjudicatedhf_withmi.dta", keepusing(adjudhf_bwh_withmi adjudhfef_withmi adjudhfdate_withmi adjudhfchfdiag_withmi adjudhfdischdate_withmi adjudhfpriorlow_withmi)
drop if _merge==2
drop _merge
replace adjudhfdate_withmi = CENSDAT7 if missing(adjudhfdate_withmi)


capture drop risktime
capture drop v5datesp
foreach var of varlist $catcovariates {
	capture drop  ever`var'datesp 
}
capture drop inchf
****************************

generate risktime=(adjudhfdate_withmi - date("January 1, 2005", "MDY"))

generate v5datesp = (v5date51 - date("January 1, 2005", "MDY")) 

foreach var of varlist $catcovariates {
	generate ever`var'datesp = (ever`var'date - date("January 1, 2005", "MDY"))
	replace ever`var'datesp = 0 if ((ever`var'date < date("January 1, 2005", "MDY")))
}

generate inchf = 0	


save "ARICmaster_013019- CAD HFpEF2_withmi.dta", replace



//----------------------------------------------------------------------------

//Results for the primary analysis; gives all HF, followed by HFpEF, then HFrEF
cls
use "ARICmaster_013019- CAD HFpEF2_withmi.dta", clear


//*************************************************************************
//For sex and race sensitivity analyses, uncomment the appropriate line below:
//keep if female==0
//keep if female==1
//keep if black==1
//keep if white==1


//CHD defined as both MI and revasc:
generate chdtime = C7_DATEMI - date("January 1, 2005", "MDY") if incmi==1
replace chdtime = C7_DATEPROC - date("January 1, 2005", "MDY") if increvasc==1
generate chdpresent = (increvasc==1 | incmi==1)
//*************************************************************************

forvalues i=1/3 {
	//*************************************************************************
	//To assess HF:
	replace inchf = (adjudhf_bwh_withmi==1 | adjudhf_bwh_withmi==2 | adjudhf_bwh_withmi==3) if `i'==1		//ref, pef, and unclassified
	replace inchf = (adjudhf_bwh_withmi==2) if `i'==2			//pef
	replace inchf = (adjudhf_bwh_withmi==1) if `i'==3			//ref
	//*************************************************************************

	stset risktime, failure(inchf==1) id(id)

	stsplit timeafterchd if chdpresent==1, at(0 90 365) after(chdtime) 
	replace timeafterchd = timeafterchd + 1 if chdpresent==1
	recode timeafterchd . = 0

	foreach var of varlist $catcovariates {
		stsplit ever`var'split, at(0) after(ever`var'datesp) 
		replace ever`var'split = ever`var'split + 1 if ever`var'==1	
		recode ever`var'split . = 0
		replace ever`var'split = ever`var'pre if ever`var'split==0 & !missing(ever`var'datesp)
	}
	
	stsplit bmisplit if !missing(v5_bmi51), at(0) after(v5datesp)
	replace bmisplit = bmisplit + 1 if !missing(v5_bmi51)
	replace bmisplit = mostrecentbmi if (bmisplit==0 | missing(bmisplit))
	replace bmisplit = v5_bmi51 if bmisplit==1

	stsplit gfrsplit if !missing(v5_ckdepi_egfr), at(0) after(v5datesp)
	replace gfrsplit = gfrsplit + 1 if !missing(v5_ckdepi_egfr)
	replace gfrsplit = mostrecentgfr if (gfrsplit==0 | missing(gfrsplit))
	replace gfrsplit = v5_ckdepi_egfr if gfrsplit==1

	
	generate gfrsq = gfrsplit * gfrsplit

	generate bmisq = bmisplit * bmisplit


	egen racesex = group(black female)


	stcox i.timeafterchd adjage i.racesex i.everhtnsplit i.everafsplit i.everstrokesplit gfrsplit gfrsq bmisplit bmisq, strata(everdiabsplit eversmokersplit v1_center)

	//estat ic 
	//sts graph, failure
	//sts graph, by(timeafterchd) name(timeafterchd, replace)

	estat phtest, detail

	generate in_mod = e(sample)
	strate timeafterchd if in_mod==1, per(36525)

	//stphplot, by(timeafterchd) name(timeafterchd_PropHazTest, replace)

	egen strata = group(v1_center everdiabsplit eversmokersplit)

	generate exptime = (_t - _t0)/36525
	
	quietly: poisson _d i.timeafterchd adjage i.racesex i.everhtnsplit i.everafsplit i.everstrokesplit gfrsplit gfrsq bmisplit bmisq i.strata, exp(exptime)

	replace exptime=1
	margins timeafterchd, predict(xb) 

	
	matrix Output = r(table)
	matlist Output

	matrix Values = J(4,3,.)
	forvalues k=1/4 {
		matrix Values[`k',1] = Output[1,`k']
		matrix Values[`k',2] = Output[5,`k']
		matrix Values[`k',3] = Output[6,`k']
	}

	matlist Values

	mata: st_matrix("ValuesExp", exp(st_matrix("Values")))
	matrix colnames ValuesExp = "Margin" "Lower CI" "Upper CI"
	matrix rownames ValuesExp = "time0" "time1" "time91" "time366"
	matlist ValuesExp

	drop timeafterchd gfrsplit bmisplit gfrsq bmisq racesex in_mod 
	capture drop strata exptime 

	foreach var of varlist $catcovariates {
		drop ever`var'split
	}
		
	stjoin
}




//Creation of failure curves for HFpEF and HFrEF
cls
use "ARICmaster_013019- CAD HFpEF2.dta", clear

generate chdpresent = (lowestdate!=.)

drop if chdpresent == 0
drop if adjudhfdate <= lowestdate

generate postchdhf = (adjudhf_bwh==1 | adjudhf_bwh==2 | adjudhf_bwh==3)

generate timefromchd = (adjudhfdate - lowestdate)/365.25



rename timefromchd followuptime
generate outcome1 = (adjudhf_bwh==1)
generate outcome2 = (adjudhf_bwh==2)


//full failure curves
stset followuptime, failure(outcome1==1) exit(time 9.5) id(id) 
//sts graph, failure yscale(range(0 1)) ylabel(0(0.25)1) xscale(range(0 10)) xlabel(0(2)10) risktable(0(2)12) 
sts gen s1 = s

stset followuptime, failure(outcome2==1) exit(time 9.5) id(id) 
//sts graph, failure yscale(range(0 1)) ylabel(0(0.25)1) xscale(range(0 2)) xlabel(0(2)10) risktable(0(2)12)  
sts gen s2 = s


generate HFrEF = 1-s1
generate HFpEF = 1-s2
twoway line HFrEF HFpEF _t, sort connect(step step) ytitle("Proportion developing HF") yscale(range(0 1)) ylabel(0(0.25)1) xtitle("Time after CAD diagnosis (years)") xscale(range(0 10)) xlabel(0(2)10)

//new version added 4/8/2020 with smaller y-axis
graph twoway line HFrEF HFpEF _t, sort connect(step step) ytitle("Proportion developing HF") yscale(range(0 0.25)) ylabel(0(0.05)0.25) xtitle("Time after CAD diagnosis (years)") xscale(range(0 10)) xlabel(0(2)10)
graph export cuminc2.tif, width(8000)


//failure curve inset (shorter x axis)
stset followuptime, failure(outcome1==1) exit(time 2) id(id) 
sts gen sinset1 = s

stset followuptime, failure(outcome2==1) exit(time 2) id(id) 
sts gen sinset2 = s

generate finset1 = 1-sinset1
generate finset2 = 1-sinset2
twoway line finset1 finset2 _t, sort connect(step step) yscale(range(0 0.1)) ylabel(0 (0.02) 0.1) xscale(range(0 2)) xlabel(0 0.25 1 2)















//***ANALYSIS 2*** 
//Impact of prevalent CAD as of Visit 5 on echo parameters and troponin at Visit 5 among HF-free participants with normal ejection fraction
//***Of note, skewed variables not included in manuscript

use "ARICmaster_013019- CAD HFpEF.dta", clear
cls

merge 1:1 id using cbc_final.dta, keepusing(cbc3) 				//merges in WBC data
drop if _merge==2
drop _merge


merge 1:1 id using ech.dta, keepusing(ech32)					//merges in AV peak velocity
drop if _merge==2
drop _merge
	

drop if missing(e3date)						//9674 without Visit 5 echo dropped (all remaining have !missing(v5date51))
drop if v5_prevhf52==1						//775 with prior HF dropped
drop if v5_prevdefposshf51==1				//197 with possible prior HF dropped
drop if adjudhfdate < v5date51 				//drops another 6 (drops another 24 if only v5_prevhf52 is used)
//drop if prevhf01==1						//91 additional participants with prevalent HF as of visit 1- keep bc unlikely real HF- no subsequent events 
drop if missing(v5_prvchd51)				//90 with missing CHD history dropped **


drop if v5date51==CENSDAT7 					//drops if not followed past V5


generate prvchdwithsmi = v5_prvchd51 			//v5_prvchd51 and v5_prvchd53 do not include silent MIs detected at V5 (assigned C7_SMIDATE 2004-2005)
replace prvchdwithsmi = 1 if C7_SMI_BY17==1 & (C7_SMIDATE < v5date51)	//adds 40 prvCHD

tab prvchdwithsmi, m 		//4524 no CHD, 526 with CHD 

/* To exclude silent MI
generate prvchd = (v1_prvchd05==1 | (C7_MI17==1 & C7_DATEMI <= v5date51) | (C7_CARDPROC==1 & C7_DATEPROC <= v5date51))
tab prvchd, m 				//4580 no CHD, 470 CHD
*/





drop if e10ef < 50							//76 with depressed EF dropped **
count										//4,974 remaining



drop if ech56=="Y" | ech57=="Y"				//ech56- mod or greater AI (16); ech57- mod or greater MS (0 participants)
drop if ech19>20							//MR- ech19- MR jet area to LA area (%)
drop if ech32>300							//AV peak velocity

generate bnp = v5_lip43
replace bnp = 2.5 if ND_PRO_BNP_V5==1

generate meanwall = (e6septum + e7pwt)/2 if !missing(e6septum) & !missing(e7pwt)
replace meanwall = e6septum if missing(e7pwt) & !missing(e6septum)
replace meanwall = e7pwt if missing(e6septum) & !missing(e7pwt)




global tbl1cont "v5age52 v5_ckdepi_egfr v5_bmi51 v5_ldl51 v5_hdl v5_chol v5_chm15 v5_cbc5"
//global tbl1skew "TGS_V5 CRP_V5"
global tbl1cat "female v5firstdiab v5firsthtn v5firststroke v5firstaf v5firstsmoker v5formersmoker v5_cursmk52"	
global tbl1race "black white asian native_amer"
global tbl1center "centerF centerJ centerM centerW"
global vlistechoparam "e4lvid e6septum e7pwt e10ef e12lvmi e17lavi e26septale e20E e28EAratio e47strain Eeprime meanwall"


/*
foreach var of varlist $tbl1skew {
	generate lg`var'=log(`var')
	}
*/

merge 1:1 id using "First_DM_HTN_AF_Stroke_Smoking.dta"
drop if _merge==2
drop _merge


generate diab=.
generate smoker=.
generate htn=.
generate stroke=.
generate af=.

foreach var of varlist diab smoker htn stroke af {
	generate v5first`var' = 1 if ever`var'==1 & ever`var'date<=v5date51
	recode v5first`var' . = 0 if ever`var'==0 | ever`var'pre==0 
}

generate v5formersmoker = (v5firstsmoker==1 & v5_cursmk52!=1)

tab v5firstdiab v5_ever_dm, m 						//comparing variables from "First" file to ARIC V5 variables
tab v5firstsmoker v5_ever_smoker, m 
tab v5firsthtn v5_ever_htn, m 
tab v5firststroke v5_prvstr51, m 
tab v5firstaf v5_prvaf51, m 

save "ARICmaster_013019- CAD HFpEF4.dta", replace




use "ARICmaster_013019- CAD HFpEF4.dta", clear	

/*
//This commented-out section checks the below tables:
table1 $tbl1cont $tbl1cat black, by(prvchdwithsmi) gmean($tbl1skew)


//Continuous variables:
regress v5age52 prvchdwithsmi female white asian native_amer centerF centerJ centerM

foreach var of varlist v5_ckdepi_egfr v5_bmi51 v5_ldl51 v5_hdl v5_chol v5_chm15 v5_cbc5 {
	regress `var' prvchdwithsmi v5age52 female white asian native_amer centerF centerJ centerM
}


//Skewed variables:
ttest lgTGS_V5, by(prvchdwithsmi)			//p-value 0.919; per ADO, p-value 0.75 (use gmean in Table1)
ttest lgCRP_V5, by(prvchdwithsmi)			//p-value 0.0018; per ADO, p-value <0.001


regress lgTGS_V5 prvchdwithsmi v5age52 female white asian native_amer centerF centerJ centerM, eform(ratio)	
regress lgCRP_V5 prvchdwithsmi v5age52 female white asian native_amer centerF centerJ centerM, eform(ratio)	


//Categorical variables:
foreach var of varlist $tbl1cat {
	tab `var' prvchdwithsmi, exact matcell(freq)		//p-value for stroke- 0.012 here, and 0.006 by ADO; p-value for cursmk- 0.83 here, and 0.76 by ADO (Fisher's exact instead of chi square)
}
logistic female prvchdwithsmi v5age52 white asian native_amer centerF centerJ centerM
logistic black prvchdwithsmi v5age52 female centerF centerJ centerM

foreach var of varlist v5firstdiab v5firsthtn v5firststroke v5firstaf v5firstsmoker v5formersmoker v5_cursmk52 {
	logistic `var' prvchdwithsmi v5age52 female white asian native_amer centerF centerJ centerM	
}


//Centers
tab v5center prvchdwithsmi, exact matcell(freq)


//Echo parameters
//Unadjusted
table1 $vlistechoparam, by(prvchdwithsmi) gmean(v5_lip38)

//adjusted
foreach var of varlist $vlistechoparam {
	regress `var' prvchdwithsmi v5age52 female white asian native_amer centerF centerJ centerM
}

//fully adjusted
foreach var of varlist $vlistechoparam {
	regress `var' prvchdwithsmi v5age52 female white asian native_amer v5_bmi51 v5_ckdepi_egfr v5_chm15 v5_cbc5 v5firstdiab v5firsthtn v5firstaf v5firststroke v5firstsmoker centerF centerJ centerM
}

//Adjusted means
table1adjust e4lvid 2 e6septum 2 e7pwt 2 e10ef 2 e12lvmi 2 e17lavi 2 e26septale 2 e20E 2 e28EAratio 2 e47strain 2 Eeprime 2 meanwall 2, by(prvchdwithsmi) adjust(v5age52 female white asian native_amer centerF centerJ centerM)

*/



//Several histograms to assess normality of variables (*separate by HF vs no HF?)
/*
swilk $vlistechoparam
foreach var of varlist $vlistechoparam {
	histogram `var', frequency normal name(`var'_nl, replace)
	}
*/

//TABLE 1


/*
foreach var of varlist e4lvid meanwall e12lvmi e10ef e20E Eeprime v5_lip38 {		//e17lavi
generate `var'present = (!missing(`var')) 

disp "."
disp "."
disp "."
disp "."

disp `var'
tab `var'present


local predictor `var'present
*/

count


local predictor "prvchdwithsmi"
local covar "v5age52 female white asian native_amer centerF centerJ centerM"
sort `predictor'

//Normal continuous variables
local rowcount = `:word count $tbl1cont'
local rowspecp = (`rowcount' + 2)*"&"
matrix P = J(`rowcount',10,.)
matrix colnames P = TotN "NoCHD N" "NC Mean" "NC SD" "CHD N" "CHD Mean" "CHD SD" P-value AdjBeta "AdjP"
matrix rownames P = $tbl1cont
local i=1
foreach var of varlist $tbl1cont {	
	quietly: ttest `var', by(`predictor')
	matrix P[`i',1] = r(N_1)+r(N_2)
	matrix P[`i',2] = r(N_1)
	matrix P[`i',3] = r(mu_1)
	matrix P[`i',4] = r(sd_1)
	matrix P[`i',5] = r(N_2)
	matrix P[`i',6] = r(mu_2)
	matrix P[`i',7] = r(sd_2)
	matrix P[`i',8] = r(p)
	quietly: regress `var' `predictor' `: list covar - var'
	matrix P[`i',9] = (_b[`predictor'])
	matrix P[`i',10] = 2*ttail(e(df_r),abs(_b[`predictor']/_se[`predictor']))
	local ++i
	}

/*
//Skewed Continuous variables
local rowcount = `:word count $tbl1skew'
local rowspecq = (`rowcount' + 2)*"&"
matrix Q = J(`rowcount',16,.)
matrix colnames Q = TotN "NoCHD N" "NC Mdn" "NC 25%" "NC 75%" "NC Gmean" "CHD N" "CHD Mdn" "CHD 25%" "CHD 75%" "CHD Gmean" P-value Ratio "RatCI L" "RatCI U" AdjP
matrix rownames Q = $tbl1skew
local i=1				
foreach var of varlist $tbl1skew {
	quietly: summarize `var' if `predictor'==0, detail
	matrix Q[`i',2] = r(N)
	matrix Q[`i',3] = r(p50)
	matrix Q[`i',4] = r(p25)
	matrix Q[`i',5] = r(p75)
	quietly: ameans `var' if `predictor'==0
	matrix Q[`i',6] = r(mean_g)
	quietly: summarize `var' if `predictor'==1, detail
	matrix Q[`i',7] = r(N)
	matrix Q[`i',8] = r(p50)
	matrix Q[`i',9] = r(p25)
	matrix Q[`i',10] = r(p75)
	matrix Q[`i',1] = Q[`i',2] + Q[`i',6]
	quietly: ameans `var' if `predictor'==1	
	matrix Q[`i',11] = r(mean_g)
	quietly: ttest lg`var', by(`predictor')
	matrix Q[`i',12] = r(p)
	//histogram lg`var', frequency normal name(log`var'_nl, replace) 
	quietly: regress lg`var' `predictor' `: list covar - var', eform(ratio)			//gives ratio of betas for outcome of geometric means- exponentiates beta coefficient*** call ratio (of geometric means) or "" from tables and results of Paramount study
	matrix Q[`i',13] = exp((_b[`predictor']))
	matrix Q[`i',14] = exp(_b[`predictor'] - invttail(e(df_r),0.025)*_se[`predictor'])
	matrix Q[`i',15] = exp(_b[`predictor'] + invttail(e(df_r),0.025)*_se[`predictor'])
	matrix Q[`i',16] = 2*ttail(e(df_r),abs(_b[`predictor']/_se[`predictor']))
	local ++i
	}
*/

//Categorical variables																	//**race no longer sig after adjusting for site- valid? small number of blacks at non-Jackson sites?
local rowcount = `:word count $tbl1cat'
local rowspecs = (`rowcount' + 2)*"&"
matrix S = J(`rowcount',8,.)
matrix colnames S = TotN "NoCHD N" "NC Prop" "CHD N" "CHD Prop" P-value "Adj OR" "Adj P"
matrix rownames S = $tbl1cat
local i=1				
foreach var of varlist $tbl1cat {
	quietly: tab `var' `predictor', exact matcell(freq)	
	matrix S[`i',1] = (freq[1,1]+freq[1,2]+freq[2,1]+freq[2,2])
	matrix S[`i',2] = freq[2,1]
	matrix S[`i',3] = (freq[2,1]/(freq[1,1]+freq[2,1]))
	matrix S[`i',4] = freq[2,2]
	matrix S[`i',5] = (freq[2,2]/(freq[1,2]+freq[2,2]))
	matrix S[`i',6] = r(p_exact)
	quietly: logistic `var' `predictor' `: list covar - var' 							//gives odds ratio
	matrix S[`i',7] = exp(_b[`predictor'])
	quietly: test `predictor'
	matrix S[`i',8] = r(p)
	local ++i
	}

//Center																														
local rowcount = `:word count $tbl1center'
local rowspect = (`rowcount' + 2)*"&"
matrix T = J(`rowcount',4,.)
matrix colnames T = "NoCHD N" "NC Prop" "CHD N" "CHD Prop" 
matrix rownames T = $tbl1center
quietly: tab v5center `predictor', exact matcell(freq)
local center0n = freq[1,1]+freq[2,1]+freq[3,1]+freq[4,1]
local center1n = freq[1,2]+freq[2,2]+freq[3,2]+freq[4,2]
local centerp = r(p_exact)
local i=1				
foreach var of varlist $tbl1center {	
	matrix T[`i',1] = freq[`i',1]
	matrix T[`i',2] = freq[`i',1]/`center0n'
	matrix T[`i',3] = freq[`i',2]
	matrix T[`i',4] = freq[`i',2]/`center1n'
	local ++i
}

//Race																														
local rowcount = `:word count $tbl1race'
local rowspect = (`rowcount' + 2)*"&"
matrix U = J(`rowcount',4,.)
matrix colnames U = "NoCHD N" "NC Prop" "CHD N" "CHD Prop" 
matrix rownames U = $tbl1race
tab race `predictor', exact matcell(freq)
local race0n = freq[1,1]+freq[2,1]+freq[3,1]+freq[4,1]
local race1n = freq[1,2]+freq[2,2]+freq[3,2]+freq[4,2]
local racep = r(p_exact)
local i=1				
foreach var of varlist $tbl1race {	
	matrix U[`i',1] = freq[`i',1]
	matrix U[`i',2] = freq[`i',1]/`race0n'
	matrix U[`i',3] = freq[`i',2]
	matrix U[`i',4] = freq[`i',2]/`race1n'
	local ++i
}


//Normal continuous variables
matlist P, cspec(& %14s o2 |  %5.0f  | %7.0f & o2 %9.2f & %9.2f o3 | %7.0f & o2 %9.2f & %9.2f o3 | %9.3f| %9.1f & %9.3f |) rspec(`rowspecp')
//Skewed continuous variables
//matlist Q, cspec(& %14s |  %5.0f  | %7.0f & %7.2f & %7.2f & %7.2f & %7.2f | %7.0f & %7.2f & %7.2f & %7.2f & %7.2f | %7.3f | %7.2f & %7.2f & %7.2f | %7.2f |) rspec(`rowspecq')
//Categorical variables
matlist S, cspec(& %14s o2 |  %5.0f  | %7.0f & o2 %9.3f o3 | %7.0f & o2 %9.3f o3 | %9.3f| %9.3f & o3 %9.3f |) rspec(`rowspecs')
//Center variables
display "No CHD n: " `center0n' "  CHD n: " `center1n' "  Center p: " `centerp'
matlist T, cspec(& %14s o2 | %7.0f & %7.3f | %7.0f & %7.3f|) rspec(`rowspect')
//Race variables
display "No CHD n: " `race0n' "  CHD n: " `race1n' "  Race p: " `racep'
matlist U, cspec(& %14s o2 | %7.0f & %7.3f | %7.0f & %7.3f|) rspec(`rowspect')


logistic black
logistic black prvchdwithsmi v5age52 female centerF centerJ centerM


local exclude white asian native_amer
quietly: tab black `predictor', exact matcell(freq)
display "Black- P-value: "	r(p_exact) 
quietly: logistic black `predictor' `: list covar - exclude' 						//gives odds ratio
display "Adj OR: "	exp(_b[`predictor'])
quietly: test `predictor'
display "Adj P: " r(p)


**ANALYSIS
//Echo parameters table 1
local predictor "prvchdwithsmi"
local covar "v5age52 female white asian native_amer centerF centerJ centerM"
sort `predictor'
local rowcount = `:word count $vlistechoparam'
local rowspecp = (`rowcount' + 2)*"&"
matrix P = J(`rowcount',10,.)
matrix colnames P = TotN "NoCHD N" "NoC Mean" "NoC SD" "CHD N" "CHD Mean" "CHD SD" P-value AdjBeta AdjP
matrix rownames P = $vlistechoparam
local i=1
foreach var of varlist $vlistechoparam {	
	quietly: ttest `var', by(`predictor')
	matrix P[`i',1] = r(N_1)+r(N_2)
	matrix P[`i',2] = r(N_1)
	matrix P[`i',3] = r(mu_1)
	matrix P[`i',4] = r(sd_1)
	matrix P[`i',5] = r(N_2)
	matrix P[`i',6] = r(mu_2)
	matrix P[`i',7] = r(sd_2)
	matrix P[`i',8] = r(p)
	quietly: regress `var' `predictor' `: list covar - var' 
	matrix P[`i',9] = (_b[`predictor'])
	matrix P[`i',10] = 2*ttail(e(df_r),abs(_b[`predictor']/_se[`predictor']))
	local ++i
	}

//Fully adjusted Echo parameters
local predictor "prvchdwithsmi"
local covar "v5age52 female white asian native_amer v5_bmi51 v5_ckdepi_egfr v5_chm15 v5_cbc5 v5firstdiab v5firsthtn v5firstaf v5firststroke v5firstsmoker centerF centerJ centerM"
sort `predictor'
local rowcount = `:word count $vlistechoparam'
local rowspecs = (`rowcount' + 2)*"&"
matrix S = J(`rowcount',10,.)
matrix colnames S = TotN "NoCHD N" "NoC Mean" "NoC SD" "CHD N" "CHD Mean" "CHD SD" P-value Beta "LinReg P"
matrix rownames S = $vlistechoparam
local i=1
foreach var of varlist $vlistechoparam {	
	quietly: ttest `var', by(`predictor')
	matrix S[`i',1] = r(N_1)+r(N_2)
	matrix S[`i',2] = r(N_1)
	matrix S[`i',3] = r(mu_1)
	matrix S[`i',4] = r(sd_1)
	matrix S[`i',5] = r(N_2)
	matrix S[`i',6] = r(mu_2)
	matrix S[`i',7] = r(sd_2)
	matrix S[`i',8] = r(p)
	quietly: regress `var' `predictor' `: list covar - var' 
	matrix S[`i',9] = (_b[`predictor'])
	matrix S[`i',10] = 2*ttail(e(df_r),abs(_b[`predictor']/_se[`predictor']))
	local ++i
	}

//Echo parameters table 1
matlist P, cspec(& %14s o2 |  %5.0f  | %7.0f & o2 %9.2f & %9.2f o3 | %7.0f & o2 %9.2f & %9.2f o3 | %9.3f | %9.3f & %9.3f |) rspec(`rowspecp')

//Echo parameters fully adjusted	
matlist S, cspec(& %14s o2 |  %5.0f  | %7.0f & o2 %9.2f & %9.2f o3 | %7.0f & o2 %9.2f & %9.2f o3 | %9.3f | %9.3f & %9.3f |) rspec(`rowspecs')




/* Troponin not used in manuscript
//Troponin table 1			//"test"?- v5_lip38 	
//local predictor "prvchdwithsmi"
local covar "v5age52 female white asian native_amer centerF centerJ centerM"
generate lgv5_lip38 = log(v5_lip38)
//sort `predictor'
local rowcount = 1
local rowspecq = (`rowcount' + 2)*"&"
matrix Q = J(`rowcount',16,.)
matrix colnames Q = TotN "NoCHD N" "NC Mdn" "NC 25%" "NC 75%" "NC Gmean" "CHD N" "CHD Mdn" "CHD 25%" "CHD 75%" "CHD Gmean" P-value Ratio "RatCI L" "RatCI U" AdjP
matrix rownames Q = v5_lip38
local i=1				
foreach var of varlist v5_lip38 {
	quietly: summarize `var' if `predictor'==0, detail
	matrix Q[`i',2] = r(N)
	matrix Q[`i',3] = r(p50)
	matrix Q[`i',4] = r(p25)
	matrix Q[`i',5] = r(p75)
	quietly: ameans `var' if `predictor'==0
	matrix Q[`i',6] = r(mean_g)
	quietly: summarize `var' if `predictor'==1, detail
	matrix Q[`i',7] = r(N)
	matrix Q[`i',8] = r(p50)
	matrix Q[`i',9] = r(p25)
	matrix Q[`i',10] = r(p75)
	matrix Q[`i',1] = Q[`i',2] + Q[`i',6]
	quietly: ameans `var' if `predictor'==1	
	matrix Q[`i',11] = r(mean_g)
	quietly: ttest lg`var', by(`predictor')
	matrix Q[`i',12] = r(p)
	//histogram lg`var', frequency normal name(log`var'_nl, replace) 
	quietly: regress lg`var' `predictor' `: list covar - var', eform(ratio)			//gives ratio of betas for outcome of geometric means- exponentiates beta coefficient*** call ratio (of geometric means) or "" from tables and results of Paramount study
	matrix Q[`i',13] = exp((_b[`predictor']))
	matrix Q[`i',14] = exp(_b[`predictor'] - invttail(e(df_r),0.025)*_se[`predictor'])
	matrix Q[`i',15] = exp(_b[`predictor'] + invttail(e(df_r),0.025)*_se[`predictor'])
	matrix Q[`i',16] = 2*ttail(e(df_r),abs(_b[`predictor']/_se[`predictor']))
	local ++i
	}
	
//Fully adjusted Troponin
//local predictor "prvchdwithsmi"
local covar "v5age52 female white asian native_amer v5_bmi51 v5_ckdepi_egfr v5_chm15 v5_cbc5 v5firstdiab v5firsthtn v5firstaf v5firststroke v5firstsmoker centerF centerJ centerM"
//sort `predictor'
local rowcount = 1
local rowspecs = (`rowcount' + 2)*"&"
matrix S = J(`rowcount',16,.)
matrix colnames S = TotN "NoCHD N" "NC Mdn" "NC 25%" "NC 75%" "NC Gmean" "CHD N" "CHD Mdn" "CHD 25%" "CHD 75%" "CHD Gmean" P-value Ratio "RatCI L" "RatCI U" AdjP
matrix rownames S = v5_lip38
local i=1				
foreach var of varlist v5_lip38 {
	quietly: summarize `var' if `predictor'==0, detail
	matrix S[`i',2] = r(N)
	matrix S[`i',3] = r(p50)
	matrix S[`i',4] = r(p25)
	matrix S[`i',5] = r(p75)
	quietly: ameans `var' if `predictor'==0
	matrix S[`i',6] = r(mean_g)
	quietly: summarize `var' if `predictor'==1, detail
	matrix S[`i',7] = r(N)
	matrix S[`i',8] = r(p50)
	matrix S[`i',9] = r(p25)
	matrix S[`i',10] = r(p75)
	matrix S[`i',1] = Q[`i',2] + Q[`i',6]
	quietly: ameans `var' if `predictor'==1	
	matrix S[`i',11] = r(mean_g)
	generate lg2`var' = log(`var')
	ttest lg2`var', by(`predictor')
	matrix S[`i',12] = r(p)
	//histogram lg`var', frequency normal name(log`var'_nl, replace) 
	quietly: regress lg2`var' `predictor' `: list covar - var', eform(ratio)			//gives ratio of betas for outcome of geometric means- exponentiates beta coefficient*** call ratio (of geometric means) or "" from tables and results of Paramount study
	matrix S[`i',13] = exp((_b[`predictor']))
	matrix S[`i',14] = exp(_b[`predictor'] - invttail(e(df_r),0.025)*_se[`predictor'])
	matrix S[`i',15] = exp(_b[`predictor'] + invttail(e(df_r),0.025)*_se[`predictor'])
	matrix S[`i',16] = 2*ttail(e(df_r),abs(_b[`predictor']/_se[`predictor']))
	local ++i
	}

//Troponin and BNP table 1
matlist Q, cspec(& %14s |  %5.0f  | %7.0f & %7.3f & %7.3f & %7.3f & %7.3f | %7.0f & %7.3f & %7.3f & %7.3f & %7.3f | %7.3f | %7.3f & %7.3f & %7.3f & %7.3f |) rspec(`rowspecq')
//Troponin and BNP fully adjusted	
matlist S, cspec(& %14s |  %5.0f  | %7.0f & %7.3f & %7.3f & %7.3f & %7.3f | %7.0f & %7.3f & %7.3f & %7.3f & %7.3f | %7.3f | %7.3f & %7.3f & %7.3f & %7.3f |) rspec(`rowspecs')

/*
drop lgv5_lip38 lg2v5_lip38

}
*/

*/














//==================================================================================================================
//***ANALYSIS 3***
//Extent to which CAD-associated echocardiographic and biomarker measures account for the relationship between CAD and incident HF, HFpEF, and HFrEF
//stptime, by(chd) to get event rates


//Censor when participant develops post-V5 MI (can no longer use V5 echo as predictor for HF)
use "c17evt1.dta", clear
rename id survid
rename chrt_id id
keep if (cmidx == "PROBMI" | cmidx == "DEFMI")	

merge m:1 id using "ARICmaster_013019.dta", keepusing(v5date51 CENSDAT7)
drop if _merge==2
drop _merge

sort id
generate pv5mi= (cmidate>v5date51 & !missing(cmidate) & CENSDAT7>=cmidate & !missing(CENSDAT7))
generate pv5midate= cmidate if pv5mi==1
by id: egen postv5mi= max(pv5mi)
by id: egen postv5midate= min(pv5midate)

by id: drop if _n!=1

save "c17evt1intercurrmi.dta", replace







use "ARICmaster_013019- CAD HFpEF4.dta", clear

global vlistechoparam "e4lvid e6septum e7pwt e10ef e12lvmi e17lavi e20E e28EAratio Eeprime meanwall e26septale"

count if v5date51 > e3date						//4- 3 with echo immediately before visit 5; 1 with echo almost 6 months prior, but no CHD/HF
count if v5date51 < e3date						//72
count if v5date51==e3date						//4710

count if e3date > C7_DATEMI & C7_DATEMI > v5date51 & !missing(C7_DATEMI)		//0- no participants with MI/ISP/SMI between V5 date and echo
count if e3date > C7_DATEISP & C7_DATEISP > v5date51 & !missing(C7_DATEISP)	//0
count if e3date > C7_SMIDATE & C7_SMIDATE > v5date51 & !missing(C7_SMIDATE)	//0
count if e3date > C7_DATE_INCHF17 & C7_DATE_INCHF17 > v5date51 & !missing(C7_DATE_INCHF17)	//0- no participants with HF between V5 date and echo

merge 1:1 id using "c17evt1intercurrmi.dta", keepusing(postv5mi postv5midate) 
drop if _merge==2
drop _merge


count


generate adjudhfdate2= adjudhfdate
replace adjudhfdate2= postv5midate if (postv5midate < adjudhfdate2) & postv5mi==1		//142 had Post V5 MI before censoring for HF/end of follow-up (4 more at same time)


generate risktime=(adjudhfdate2 - v5date51)

generate postv5newhf = .

local predictor2 "prvchdwithsmi"

replace postv5newhf = ((adjudhf_bwh==2) & (adjudhfdate>=v5date51))                      //looks at HFpEF
//replace postv5newhf = ((adjudhf_bwh==1 | adjudhf_bwh==2 | adjudhf_bwh==3) & (adjudhfdate >= v5date51)) //all HF
//replace postv5newhf = ((adjudhf_bwh==1) & (adjudhfdate>=v5date51))                    //HFrEF

replace postv5newhf = 0 if (postv5midate==adjudhfdate2) & postv5mi==1		//29 had Post V5 MI before HF

//Baseline model (not presented in manuscript)	
stset adjudhfdate2, failure(postv5newhf==1) id(id) origin(v5date51)
stcox prvchdwithsmi v5age52, strata(female race v1_center) 

estat phtest, detail
strate `predictor2', per(36525)
	
stphplot, by(`predictor2') name(`predictor2'_PropHazTest, replace)
	
//--
//Structure
//Model with patient with missing structure data excluded
stcox prvchdwithsmi v5age52 if !missing(e4lvid) & !missing(meanwall) & !missing(e12lvmi), strata(female race v1_center)
//Model with structure variables included
stcox prvchdwithsmi v5age52 e4lvid meanwall e12lvmi, strata(female race v1_center)
	
//Systolic function
stcox prvchdwithsmi v5age52 if !missing(e10ef) & !missing(e47strain), strata(female race v1_center)
stcox prvchdwithsmi v5age52 e10ef e47strain, strata(female race v1_center)

//Diastolic function 
stcox prvchdwithsmi v5age52 if !missing(e17lavi) & !missing(e20E) & !missing(Eeprime) & !missing(e26septale), strata(female race v1_center)
stcox prvchdwithsmi v5age52 e17lavi e20E Eeprime e26septale, strata(female race v1_center)

/*   
//bootstrapping- not used for manuscript
	capture program drop boot 
	program boot, rclass
	stcox prvchdwithsmi v5age52 if !missing(e17lavi) & !missing(e20E) & !missing(Eeprime), strata(female race v1_center)
	mat beta = e(b)
	stcox prvchdwithsmi v5age52 e17lavi e20E Eeprime, strata(female race v1_center)
	
	mat beta2 = e(b)
	return scalar total  = el(beta,1,1)
	return scalar pct_dir  = el(beta2,1,1)/el(beta,1,1)*100
	return scalar pct_med  = (el(beta,1,1)-el(beta2,1,1))/el(beta,1,1)*100
	end

	set seed 1125
	bootstrap  r(total) r(pct_med) r(pct_dir), reps(200): boot
	estat bootstrap, percentile
*/


