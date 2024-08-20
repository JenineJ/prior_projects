/*Creating variables for ARIC-adjudicated incident heart failure (chfdiag A, B, or C) separated by HFpEF and HFrEF (variable adjudhf_bwh)

- Resulting dataset- adjudicatedhf.dta
- Participants with prevalent HF as of the start of adjudication (1/1/2005) are NOT excluded; they can be excluded using prevhf01, c7_inchf17, and phf (physician's heart failure survey)
- Hospitalizations that are adjudicated for both prob/def MI and HF are not considered HF hospitalizations
	- Alternate versions of the variables that do count these hospitalizations as HF hospitalizations are marked with _withmi (dataset- adjudicatedhf_withmi.dta)

Variables: 
- adjudhf_bwh			1: rEF, 2: pEF, 3: unclassified
- adjudhfef				EF (see algorithm below)
- adjudhfdate			hfevtdate of the incident hospitalization
- adjudhfchfdiag		chfdiag of the incident hospitalization
- adjudhfdischdate	ddate (death/discharge date) of the incident hospitalization
- adjudhfpriorlow		indicates the incident pEF cases that had a prior low EF (by lvef_pre_low and lvef_cur_low)


Algorithm for obtaining EF (variable adjudhfef)
1) lvef_cur_low of incident HF hospitalization 
2) most recent of the following: lvef_cur_low of a prior HF hospitalization and lvef_pre_low of incident HF hospitalization. If the result
	is pEF, the prior EF will only be used if:
		- the prior EF is from within the past 6 months
		- there was no intercurrent MI between the prior EF and the incident HF hospitalization

*/

cd `"/Users/`c(username)'/Dropbox (Partners HealthCare)/Amil-Jenine share/Aric- CAD HFpEF/Analysis final files"'
//cd "/Users/brianclaggett/Dropbox/Amil-Jenine share/Aric- CAD HFpEF/Analysis final files"
cls
set autotabgraphs on
use "hfc17occ1.dta", clear		
rename id survid
rename celb02 id

sort id
drop if missing(id)

merge m:1 id using "inc_by17.dta", keepusing (censdat7)
drop if _merge==2
drop _merge

merge m:1 id using "ech.dta", keepusing(ech3 ech10)        	//ech3- date, ech10- EF
drop if _merge==2
drop _merge

drop if hfevtdate > censdat7													//drop adjudicated HF events after censoring date 

gsort id hfevtdate


by id: generate hfepisodenum = _n if (chfdiag == "A" | chfdiag == "B" | chfdiag == "C")	
by id: egen hfepiorder= rank(hfepisodenum)


save "adjudicatedhf.dta", replace

forvalues i=1/4 {
	sleep 1000											//avoids error message by pausing loop to allow time for STATA to save files
	drop if hfepiorder!=1
	save "adjudicatedhf2.dta", replace

	use "c17evt1.dta", clear
	rename id survid
	rename chrt_id id

	drop if (cmidx=="NO-MI" | cmidx=="NO-HOSP" | cmidx=="UNCLASS" | cmidx=="SUSPMI" | missing(cmidx))	

	merge m:1 id using "adjudicatedhf2.dta", keepusing(hfevtdate ddate censdat7)
	drop if _merge==2
	drop _merge

	gsort id cmidate
	drop if cmidate > censdat7

	generate hfandmi = (cmidate>=hfevtdate & ddate>=cmidate & !missing(cmidate) & !missing(ddate))								
	by id: egen hfandmioverall = max(hfandmi)
	by id: drop if _n!=1

	save "c17evt1_intercurrmi.dta", replace
	
	use "adjudicatedhf.dta", clear
	merge m:1 id using "c17evt1_intercurrmi.dta", keepusing(hfandmioverall)
	drop if _merge==2
	drop _merge
	
	bysort id: replace hfepiorder = hfepiorder - 1 if hfandmioverall==1
	drop hfandmioverall 
	save "adjudicatedhf.dta", replace
	}

erase "adjudicatedhf2.dta"

generate adjudhfef = lvef_cur if hfepiorder==1 & lvef_cur_low==1 & lvef_cur < 50		//adjudhfef = EF of earliest A/B/C HF episode; generated only for the incident HF episode; uses LVEF_CUR if concordant with lvef_cur_low, otherwise uses 0 or 101 
replace adjudhfef = lvef_cur if hfepiorder==1 & lvef_cur_low==0 & lvef_cur >= 50 & !missing(lvef_cur)
recode adjudhfef . = 0 if hfepiorder==1 & lvef_cur_low==1
recode adjudhfef . = 101 if hfepiorder==1 & lvef_cur_low==0
generate source = 1 if adjudhfef!=.

generate lvef_filled_dat=.									//date variable that is used when a prior EF value is used to fill in EF
format lvef_filled_dat %tdD_m_Y


//if adjudhfef above is missing, replaces with a previous episode's lvef_cur or lvef_cur_low
forvalues i = 1/10 {								
	by id: replace lvef_filled_dat = lvef_cur_dat[_n-`i'] if hfepiorder==1 & missing(adjudhfef) & !missing(lvef_cur_low[_n-`i'])  
	by id: replace lvef_filled_dat = hfevtdate[_n-`i'] if hfepiorder==1 & missing(adjudhfef) & !missing(lvef_cur_low[_n-`i']) & missing(lvef_cur_dat[_n-`i'])		//uses hfevtdate as date if lvef_cur_low does not have an associated date
	by id: replace adjudhfef = lvef_cur[_n-`i'] if hfepiorder==1 & missing(adjudhfef) & lvef_cur_low[_n-`i']==1 & lvef_cur[_n-`i']<50
	by id: replace adjudhfef = lvef_cur[_n-`i'] if hfepiorder==1 & missing(adjudhfef) & lvef_cur_low[_n-`i']==0 & lvef_cur[_n-`i']>=50 & !missing(lvef_cur)
	by id: replace adjudhfef = 0 if missing(adjudhfef) & hfepiorder==1 & lvef_cur_low[_n-`i']==1
	by id: replace adjudhfef = 101 if missing(adjudhfef) & hfepiorder==1 & lvef_cur_low[_n-`i']==0
	}
recode source . = 2 if adjudhfef!=.
	
generate adjudhfpriorlow= (hfepiorder==1 & lvef_pre_low==1)			//assesses participants with prior low EF (later will be used to find incident HFpEF with prior low EF)
forvalues i= 1/20 {
	by id: replace adjudhfpriorlow = 1 if hfepiorder==1 & lvef_cur_low[_n-`i']==1
	by id: replace adjudhfpriorlow = 1 if hfepiorder==1 & lvef_pre_low[_n-`i']==1
	}


drop if hfepiorder!= 1																			//drops all the episodes aside from the incident A/B/C HF episode


//replaces adjudhfef with lvef_pre if it is still missing, or replaces an older EF obtained from lvef_cur_low of prior hospitalization
replace source=3 if (missing(adjudhfef)|(lvef_filled_dat<mdy(1,1, lvef_pre_year) & !missing(lvef_pre_year))) & !missing(lvef_pre_low) & !missing(lvef_pre_year)
replace lvef_filled_dat = mdy(1, 1, lvef_pre_year) if (missing(adjudhfef)|(lvef_filled_dat<mdy(1,1, lvef_pre_year))) & !missing(lvef_pre_low) & !missing(lvef_pre_year)
replace source=3 if missing(adjudhfef) & !missing(lvef_pre_low) & missing(lvef_pre_year)
replace lvef_filled_dat = 0 if missing(adjudhfef) & !missing(lvef_pre_low) & missing(lvef_pre_year)			//fills in date as Jan 1, 1960 if year of lvef_pre_low is missing
replace adjudhfef= lvef_pre if source==3 & lvef_pre_low==1 & lvef_pre<50
replace adjudhfef= lvef_pre if source==3 & lvef_pre_low==0 & lvef_pre>=50 & !missing(lvef_pre)
replace adjudhfef = 0 if source==3 & lvef_pre_low==1 & lvef_pre>=50
replace adjudhfef = 101 if source==3 & lvef_pre_low==0 & (lvef_pre<50 | missing(lvef_pre))



replace adjudhfef = .  if adjudhfef >=50 & (hfevtdate - lvef_filled_dat) > 180 & !missing(lvef_filled_dat)		//for participants with preserved EF, only keeps prior EF value if it is within 6 months
replace source=. if adjudhfef==.

replace adjudhfef = . if adjudhfef >= 50 & ech10 < 50 & (hfevtdate > ech3) & (ech3 > lvef_filled_dat) & !missing(ech3)		//only keeps prior EF value if it is not refuted by V5 echo
replace adjudhfef = . if adjudhfef <50 & ech10 >=50 & (hfevtdate > ech3) & (ech3 > lvef_filled_dat) & !missing(ech3)
replace source=. if adjudhfef==.

replace adjudhfef = . if adjudhfef >= 50 & lvef_pre < 50 & !missing(lvef_pre_year) & (mdy(1, 1, lvef_pre_year) > lvef_filled_dat)		//only keeps prior EF value if it is not refuted by LVEF_PRE value that is more recent (using Jan 1, lvef_pre_year)
replace adjudhfef = . if adjudhfef <50 & lvef_pre >=50 & !missing(lvef_pre) & !missing(lvef_pre_year) & (mdy(1, 1, lvef_pre_year) > lvef_filled_dat)		


replace lvef_filled_dat = . if missing(adjudhfef)

replace adjudhfef = . if missing(lvef_filled_dat) & missing(lvef_cur) & missing(lvef_cur_low)				//test line- should generate 0 changes
	
generate adjudhf_bwh = 1 if adjudhfef <50								//1: HFrEF, 2: HFpEF, 3: missing
replace adjudhf_bwh = 2 if adjudhfef >=50
replace adjudhf_bwh = 3 if missing(adjudhfef)

replace adjudhfef = . if (adjudhfef==0 | adjudhfef==101)

label var adjudhf_bwh "Adjudicated incident HF (1=rEF, 2=pEF, 3=unclass HF)"
label var adjudhfef "EF of adjudhf_bwh (uses prior EF if missing)"


generate checkformi=1 if adjudhf_bwh==2 & !missing(lvef_filled_dat) 			//marks which participants need to be checked for intercurrent MI

save "adjudicatedhf.dta", replace

																							
use "c17evt1.dta", clear															
rename id survid
rename chrt_id id
drop if missing(id)
																										
drop if (cmidx=="NO-MI" | cmidx=="NO-HOSP" | cmidx=="UNCLASS" | cmidx=="SUSPMI" | cmidx=="")		

merge m:1 id using "adjudicatedhf.dta", keepusing(checkformi hfevtdate lvef_filled_dat)
drop if _merge==2
drop _merge

sort id
recode checkformi 1 = 2 if hfevtdate>cmidate & !missing(hfevtdate) & cmidate>lvef_filled_dat & !missing(cmidate)		//marks episodes where the MI is between the last available EF and the incident HFpEF hospitalization
by id: egen intercurrentmi = max(checkformi)				
by id: drop if _n!=1															//keeps only one episode for each participant, which is marked by intercurrentmi==2 if they have an intercurrent MI
save "c17evt1_intercurrmi.dta", replace

use "adjudicatedhf.dta", clear
merge 1:1 id using "c17evt1_intercurrmi.dta", keepusing(intercurrentmi)
drop if _merge==2
drop _merge

replace adjudhfef=. if intercurrentmi==2						//if intercurrent MI, switch the HFpEF participant to an unclassified participant
replace adjudhf_bwh= 3 if intercurrentmi==2
replace source=. if intercurrentmi==2

																											
generate adjudhfdate = hfevtdate
format adjudhfdate %tdD_m_Y
label var adjudhfdate "Date of adjudhf_bwh (hfevtdate)"

generate adjudhfchfdiag = chfdiag
label var adjudhfchfdiag "Chfdiag for adjudhf_bwh"

generate adjudhfdischdate = ddate
format adjudhfdischdate %tdD_m_Y
label var adjudhfdischdate "Discharge/death date of adjudhf_bwh"


recode adjudhfpriorlow 1 = 0 if adjudhf_bwh!=2					//keeps adjudpriorlow as 1 only if adjudhf==2 (HFpEF)
label var adjudhfpriorlow "HFpEF with prior low EF for adjudhf_bwh"

save "adjudicatedhf.dta", replace




//_withmi version of variables

cd `"/Users/`c(username)'/Dropbox (Partners HealthCare)/Amil-Jenine share/Aric- CAD HFpEF/Analysis final files"'
//cd "/Users/brianclaggett/Dropbox/Amil-Jenine share/Aric- CAD HFpEF/Analysis final files"
cls
set autotabgraphs on
use "hfc17occ1.dta", clear		
rename id survid
rename celb02 id

sort id
drop if missing(id)

merge m:1 id using "inc_by17.dta", keepusing (censdat7)
drop if _merge==2
drop _merge

merge m:1 id using "ech.dta", keepusing(ech3 ech10)        //ech3- date, ech10- EF
drop if _merge==2
drop _merge

drop if hfevtdate > censdat7											//drop adjudicated HF events after censoring date 

gsort id hfevtdate


by id: generate hfepisodenum = _n if (chfdiag == "A" | chfdiag == "B" | chfdiag == "C")	
by id: egen hfepiorder= rank(hfepisodenum)


generate adjudhfef_withmi = lvef_cur if hfepiorder==1 & lvef_cur_low==1 & lvef_cur < 50		//adjudhfef_withmi = EF of earliest A/B/C HF episode; generated only for the incident HF episode; uses LVEF_CUR if concordant with lvef_cur_low, otherwise uses 0 or 101 
replace adjudhfef_withmi = lvef_cur if hfepiorder==1 & lvef_cur_low==0 & lvef_cur >= 50 & !missing(lvef_cur)
recode adjudhfef_withmi . = 0 if hfepiorder==1 & lvef_cur_low==1
recode adjudhfef_withmi . = 101 if hfepiorder==1 & lvef_cur_low==0
generate source = 1 if adjudhfef_withmi!=.

generate lvef_filled_dat=.									//date variable that is used when a prior EF value is used to fill in EF
format lvef_filled_dat %tdD_m_Y


//if adjudhfef_withmi above is missing, replaces with a previous episode's lvef_cur or lvef_cur_low
forvalues i = 1/10 {								
	by id: replace lvef_filled_dat = lvef_cur_dat[_n-`i'] if hfepiorder==1 & missing(adjudhfef_withmi) & !missing(lvef_cur_low[_n-`i'])  
	by id: replace lvef_filled_dat = hfevtdate[_n-`i'] if hfepiorder==1 & missing(adjudhfef_withmi) & !missing(lvef_cur_low[_n-`i']) & missing(lvef_cur_dat[_n-`i'])		//uses hfevtdat as date if lvef_cur_low does not have an associated date
	by id: replace adjudhfef_withmi = lvef_cur[_n-`i'] if hfepiorder==1 & missing(adjudhfef_withmi) & lvef_cur_low[_n-`i']==1 & lvef_cur[_n-`i']<50
	by id: replace adjudhfef_withmi = lvef_cur[_n-`i'] if hfepiorder==1 & missing(adjudhfef_withmi) & lvef_cur_low[_n-`i']==0 & lvef_cur[_n-`i']>=50 & !missing(lvef_cur)
	by id: replace adjudhfef_withmi = 0 if missing(adjudhfef_withmi) & hfepiorder==1 & lvef_cur_low[_n-`i']==1
	by id: replace adjudhfef_withmi = 101 if missing(adjudhfef_withmi) & hfepiorder==1 & lvef_cur_low[_n-`i']==0
	}
recode source . = 2 if adjudhfef_withmi!=.
	
generate adjudhfpriorlow_withmi= (hfepiorder==1 & lvef_pre_low==1)			//assesses participants with prior low EF (later will be used to find incident HFpEF with prior low EF)
forvalues i= 1/20 {
	by id: replace adjudhfpriorlow_withmi = 1 if hfepiorder==1 & lvef_cur_low[_n-`i']==1
	by id: replace adjudhfpriorlow_withmi = 1 if hfepiorder==1 & lvef_pre_low[_n-`i']==1
	}


drop if hfepiorder!= 1																			//drops all the episodes aside from the incident A/B/C HF episode


//replaces adjudhfef_withmi with lvef_pre if it is still missing, or replaces an older EF obtained from lvef_cur_low of prior hospitalization
replace source=3 if (missing(adjudhfef_withmi)|(lvef_filled_dat<mdy(1,1, lvef_pre_year) & !missing(lvef_pre_year))) & !missing(lvef_pre_low) & !missing(lvef_pre_year)
replace lvef_filled_dat = mdy(1, 1, lvef_pre_year) if (missing(adjudhfef_withmi)|(lvef_filled_dat<mdy(1,1, lvef_pre_year))) & !missing(lvef_pre_low) & !missing(lvef_pre_year)
replace source=3 if missing(adjudhfef_withmi) & !missing(lvef_pre_low) & missing(lvef_pre_year)
replace lvef_filled_dat = 0 if missing(adjudhfef_withmi) & !missing(lvef_pre_low) & missing(lvef_pre_year)			//fills in date as Jan 1, 1960 if year of lvef_pre_low is missing
replace adjudhfef_withmi= lvef_pre if source==3 & lvef_pre_low==1 & lvef_pre<50
replace adjudhfef_withmi= lvef_pre if source==3 & lvef_pre_low==0 & lvef_pre>=50 & !missing(lvef_pre)
replace adjudhfef_withmi = 0 if source==3 & lvef_pre_low==1 & lvef_pre>=50
replace adjudhfef_withmi = 101 if source==3 & lvef_pre_low==0 & (lvef_pre<50 | missing(lvef_pre))



replace adjudhfef_withmi = .  if adjudhfef_withmi >=50 & (hfevtdate - lvef_filled_dat) > 180 & !missing(lvef_filled_dat)		//for participants with preserved EF, only keeps prior EF value if it is within 6 months
replace source=. if adjudhfef_withmi==.

replace adjudhfef_withmi = . if adjudhfef_withmi >= 50 & ech10 < 50 & (hfevtdate > ech3) & (ech3 > lvef_filled_dat) & !missing(ech3)		//only keeps prior EF value if it is not refuted by V5 echo
replace adjudhfef_withmi = . if adjudhfef_withmi <50 & ech10 >=50 & (hfevtdate > ech3) & (ech3 > lvef_filled_dat) & !missing(ech3)
replace source=. if adjudhfef_withmi==.

replace adjudhfef_withmi = . if adjudhfef_withmi >= 50 & lvef_pre < 50 & !missing(lvef_pre_year) & (mdy(1, 1, lvef_pre_year) > lvef_filled_dat)		//only keeps prior EF value if it is not refuted by LVEF_PRE value that is more recent (using Jan 1, lvef_pre_year)
replace adjudhfef_withmi = . if adjudhfef_withmi <50 & lvef_pre >=50 & !missing(lvef_pre) & !missing(lvef_pre_year) & (mdy(1, 1, lvef_pre_year) > lvef_filled_dat)		


replace lvef_filled_dat = . if missing(adjudhfef_withmi)

replace adjudhfef_withmi = . if missing(lvef_filled_dat) & missing(lvef_cur) & missing(lvef_cur_low)				//test line- should generate 0 changes
	
generate adjudhf_bwh_withmi = 1 if adjudhfef_withmi <50								//1: HFrEF, 2: HFpEF, 3: missing
replace adjudhf_bwh_withmi = 2 if adjudhfef_withmi >=50
replace adjudhf_bwh_withmi = 3 if missing(adjudhfef_withmi)

replace adjudhfef_withmi = . if (adjudhfef_withmi==0 | adjudhfef_withmi==101)

label var adjudhf_bwh_withmi "Adjudicated inc HF, including MI+HF hosp (1=rEF, 2=pEF, 3=unclass HF)"
label var adjudhfef_withmi "EF of adjudhf_bwh_withmi episode (uses prior EF if missing)"


generate checkformi=1 if adjudhf_bwh_withmi==2 & !missing(lvef_filled_dat) 			//marks which participants need to be checked for intercurrent MI

save "adjudicatedhf_withmi.dta", replace

																							
use "c17evt1.dta", clear															
rename id survid
rename chrt_id id
drop if missing(id)
																										
drop if (cmidx=="NO-MI" | cmidx=="NO-HOSP" | cmidx=="UNCLASS" | cmidx=="SUSPMI" | cmidx=="")		

merge m:1 id using "adjudicatedhf_withmi.dta", keepusing(checkformi hfevtdate lvef_filled_dat)
drop if _merge==2
drop _merge

sort id
recode checkformi 1 = 2 if hfevtdate>cmidate & !missing(hfevtdate) & cmidate>lvef_filled_dat & !missing(cmidate)		//marks episodes where the MI is between the last available EF and the incident HFpEF hospitalization
by id: egen intercurrentmi = max(checkformi)				
by id: drop if _n!=1															//keeps only one episode for each participant, which is marked by intercurrentmi==2 if they have an intercurrent MI
save "c17evt1_intercurrmi.dta", replace

use "adjudicatedhf_withmi.dta", clear
merge 1:1 id using "c17evt1_intercurrmi.dta", keepusing(intercurrentmi)
drop if _merge==2
drop _merge

replace adjudhfef_withmi=. if intercurrentmi==2						//if intercurrent MI, switch the HFpEF participant to an unclassified participant
replace adjudhf_bwh_withmi= 3 if intercurrentmi==2
replace source=. if intercurrentmi==2

																											
generate adjudhfdate_withmi = hfevtdate
format adjudhfdate_withmi %tdD_m_Y
label var adjudhfdate_withmi "Date of adjudhf_bwh_withmi (hfevtdate)"

generate adjudhfchfdiag_withmi = chfdiag
label var adjudhfchfdiag_withmi "Chfdiag for adjudhf_bwh_withmi"

generate adjudhfdischdate_withmi = ddate
format adjudhfdischdate_withmi %tdD_m_Y
label var adjudhfdischdate_withmi "Discharge/death date of adjudhf_bwh_withmi"


recode adjudhfpriorlow_withmi 1 = 0 if adjudhf_bwh_withmi!=2					//keeps adjudpriorlow_withmi as 1 only if adjudhf==2 (HFpEF)
label var adjudhfpriorlow_withmi "HFpEF with prior low EF for adjudhf_bwh_withmi"

save "adjudicatedhf_withmi.dta", replace


use "ARICmaster_011119.dta", clear
drop _merge

merge 1:1 id using "adjudicatedhf.dta", keepusing(adjudhf_bwh adjudhfef adjudhfdate adjudhfchfdiag adjudhfdischdate adjudhfpriorlow)
drop if _merge==2
drop _merge

merge 1:1 id using "adjudicatedhf_withmi.dta", keepusing(adjudhf_bwh_withmi adjudhfef_withmi adjudhfdate_withmi adjudhfchfdiag_withmi adjudhfdischdate_withmi adjudhfpriorlow_withmi)
drop if _merge==2
drop _merge

replace adjudhfdate = CENSDAT7 if missing(adjudhfdate)
replace adjudhfdate_withmi = CENSDAT7 if missing(adjudhfdate_withmi)

keep id adjudhf_bwh adjudhfef adjudhfdate adjudhfchfdiag adjudhfdischdate adjudhfpriorlow adjudhf_bwh_withmi adjudhfef_withmi adjudhfdate_withmi adjudhfchfdiag_withmi adjudhfdischdate_withmi adjudhfpriorlow_withmi

save "adjudicatedhf_variables.dta", replace









