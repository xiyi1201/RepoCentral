
use dr1iff_b.dta, clear /* 2001 */
append using dr1iff_c	/* 2003 */
append using dr1iff_d	/* 2005 */
append using dr1iff_e	/* 2007 */
append using dr1iff_f	/* 2009 */
append using dr1iff_g	/* 2011 */
append using dr1iff_h	/* 2013 */
append using dr1iff_i	/* 2015 */
append using p_dr1iff	/* 2017-20 */
append using dr1iff_l	/* 2021-23 */
duplicates report seqn dr1iline

* Food code harmonization
replace dr1ifdcd = drdifdcd if dr1ifdcd==.
tostring dr1ifdcd, g(foodcode_str)

/* BRING IN FPED DATA */
merge 1:1 seqn dr1iline using "SCRATCH\fped_combined_june2025.dta" 

* Cleaning up a few variables
replace dr1drstz=drddrstz if dr1drstz==.
ta dr1drstz, m 

lookfor wt
replace wtdrd1=wtdrd1pp if wtdrd1==.
summ wtdrd1

* Collapse statement for creating person-level data file
collapse (sum) dr1igrms- dr1imois dr1isodi dr1ichl dr1ivd dr1i_f_citmlb- dr1i_a_drinks (max) dr1drstz wtdrd1, by(seqn)
save "intermediate.dta", replace

* BRING IN DEMOGRAPHIC DATA
use demo_b, clear
append using demo_c demo_d demo_e demo_f demo_g demo_h demo_i p_demo demo_l
merge 1:1 seqn using "intermediate.dta"

* GENERAGE AGE GROUPINGS
ta ridageyr sdd if dr1drstz==1 
recode ridageyr (min/5=1) (5/9=2) (10/14=3) (15/19=4) (20/29=5) (30/39=6) (40/49=7) (50/64=8) (65/max=9), g(agecat)

* GENERATE FILTER VARIABLE
g filter=1 if dr1drstz==1

* SVYSET THE DATA
svyset [pweight=wtdrd1], strata(sdmvstra) psu(sdmvpsu)

* Zero out variables 
foreach var in dr1ikcal dr1iprot dr1icarb dr1isugr dr1ifibe dr1itfat dr1isfat dr1imfat dr1ipfat dr1ichol dr1iatoc dr1iret dr1ivara dr1iacar dr1ibcar dr1icryp dr1ilyco dr1ilz dr1ivb1 dr1ivb2 dr1iniac dr1ivb6 dr1ifola dr1ifa dr1iff dr1ifdfe dr1ichl dr1ivb12 dr1ivc dr1ivk dr1icalc dr1iphos dr1imagn dr1iiron dr1izinc dr1icopp dr1isodi dr1ipota dr1isele dr1icaff dr1itheo dr1ialco dr1imois { 
	replace `var'=. if dr1drstz!=1
}

* RECODE YEAR VARIABLES
recode sdd (66=10), g(year)
mean dr1ikcal, over(year)

* GENERATE SELF DEFINED SUBGROUP VARIABLES
/*
Link : https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2021/DataFiles/DEMO_L.htm#RIDRETH3
*/
gen total=1 if filter==1
gen female=1 if riagendr==2
gen male=1 if riagendr==1
gen child=1 if ridageyr<=19
gen adolescents=1 if ridageyr>=20
gen age_0_5=1 if ridageyr<=5
gen age_6_10=1 if ridageyr>=6 & ridageyr<=10
gen age_11_14=1 if ridageyr>=11 & ridageyr<=14
gen age_15_19=1 if ridageyr>=15 & ridageyr<=19
gen age_20_34=1 if ridageyr>=20 & ridageyr<=34
gen age_35_49=1 if ridageyr>=35 & ridageyr<=49
gen age_50_69=1 if ridageyr>=50 & ridageyr<=69
gen age_70=1 if ridageyr>=70
gen female_19=1 if ridageyr<=19 & riagendr==2
gen male_19=1 if ridageyr<=19 & riagendr==1
gen female_20_49=1 if ridageyr>=20 & ridageyr<=49 & riagendr==2
gen male_20_49=1 if ridageyr>=20 & ridageyr<=49 & riagendr==1
gen female_50=1 if ridageyr>=50 & riagendr==2
gen male_50=1 if ridageyr>=50 & riagendr==1
gen NHW=1 if ridreth1==3
gen NHB=1 if ridreth1==4
gen Mexican_American=1 if ridreth1==1
*gen Hispanic=1 if ridreth1==2 /*2007-8 onwards*/
*gen NHA=1 if ridreth1==6 /*2011-12 onwards*/
gen below_HS=1 if dmdeduc2==2 | dmdeduc2==1
gen HS=1 if  dmdeduc2==3
gen some_college=1 if dmdeduc2==4
gen college_above=1 if dmdeduc2==5
*INCOME RATIO THRESHOLD: TO BE DISCUSSED
gen lower_income=1 if indfmpir<=1.3
gen medium_income=1 if ridageyr<1.3 & indfmpir<=2.99
gen higher_income=1 if indfmpir>=3

* CREATE NEW VARIABLES FOR INTERPRETABILITY: % of total energy
gen PCTdr1iprot = ((dr1iprot * 4)/dr1ikcal)*100 /*protein (4 kcal per gram)*/
gen PCTdr1icarb = ((dr1icarb * 4)/dr1ikcal)*100 /*carbohydrate (4 kcal per gram)*/
gen PCTdr1isugr = ((dr1isugr * 4)/dr1ikcal)*100 /*total sugar (4 kcal per gram)*/
gen PCTdr1itfat = ((dr1itfat * 9)/dr1ikcal)*100 /*total fat (9 kcal per gram)*/
gen PCTdr1isfat = ((dr1isfat * 9)/dr1ikcal)*100 /*saturated fat (9 kcal per gram)*/

* Calculate energy adjusted values for each of the nutrient variables 
foreach var of varlist dr1iprot dr1icarb dr1isugr dr1ifibe dr1itfat dr1isfat dr1imfat dr1ipfat dr1ichol dr1iatoc dr1iret dr1ivara dr1iacar dr1ibcar dr1icryp dr1ilyco dr1ilz dr1ivb1 dr1ivb2 dr1iniac dr1ivb6 dr1ifola dr1ifa dr1iff dr1ifdfe dr1ichl dr1ivb12 dr1ivc dr1ivk dr1icalc dr1iphos dr1imagn dr1iiron dr1izinc dr1icopp dr1isodi dr1ipota dr1isele dr1icaff dr1itheo dr1ialco dr1imois {
   g `var'_ea = (`var'/dr1ikcal)*2000 if filter==1
}

/* CALORIES */
putexcel set "tester3.xlsx", modify sheet(Calories)

local k=1
* EXCEL LABELS
	quietly: putexcel a`k'=("VARIABLE") b`k'=("POPULATION") c`k'=("Parameter") d`k'=("2001-2") e`k'=("2003-4") f`k'=("2005-6") g`k'=("2007-8") h`k'=("2009-10") i`k'=("2011-12") j`k'=("2013-14") k`k'=("2015-16") l`k'=("2017-20") m`k'=("2021-23") n`k'=("p-trend") o`k'=("%_change") p`k'=("PAIRWISE_TEST_LAST_2_CYCLES")

* LOOP OVER ALL VARIABLES (except individual fatty acids & dr1ivd)
* NUTRIENTS NOT FOUND: dr1iatoa dr1ib12a dr1is040 dr1is060 dr1is080 dr1is100 dr1is120 dr1is140 dr1is160 dr1is180 dr1im161 dr1im181 dr1im201 dr1im221 dr1ip182 dr1ip183 dr1ip184 dr1ip204 dr1ip205 dr1ip225 dr1ip226 
* MAY NEED TO EXCLUDE DUE TO CERTAIN YEARS DATA ARE MISSING: dr1ichl dr1isodi
foreach var of varlist dr1ikcal dr1iprot dr1icarb dr1isugr dr1ifibe dr1itfat dr1isfat dr1imfat dr1ipfat dr1ichol dr1iatoc dr1iret dr1ivara dr1iacar dr1ibcar dr1icryp dr1ilyco dr1ilz dr1ivb1 dr1ivb2 dr1iniac dr1ivb6 dr1ifola dr1ifa dr1iff dr1ifdfe dr1ichl dr1ivb12 dr1ivc dr1ivk dr1icalc dr1iphos dr1imagn dr1iiron dr1izinc dr1icopp dr1isodi dr1ipota dr1isele dr1icaff dr1itheo dr1ialco dr1imois PCTdr1iprot PCTdr1icarb PCTdr1isugr PCTdr1itfat PCTdr1isfat dr1iprot_ea dr1icarb_ea dr1isugr_ea dr1ifibe_ea dr1itfat_ea dr1isfat_ea dr1imfat_ea dr1ipfat_ea dr1ichol_ea dr1iatoc_ea dr1iret_ea dr1ivara_ea dr1iacar_ea dr1ibcar_ea dr1icryp_ea dr1ilyco_ea dr1ilz_ea dr1ivb1_ea dr1ivb2_ea dr1iniac_ea dr1ivb6_ea dr1ifola_ea dr1ifa_ea dr1iff_ea dr1ifdfe_ea dr1ichl_ea dr1ivb12_ea dr1ivc_ea dr1ivk_ea dr1icalc_ea dr1iphos_ea dr1imagn_ea dr1iiron_ea dr1izinc_ea dr1icopp_ea dr1isodi_ea dr1ipota_ea dr1isele_ea dr1icaff_ea dr1itheo_ea dr1ialco_ea dr1imois_ea {
	
	* NESTED LOOP: POPULATION SUBGROUP
	foreach subgroup in total female male child adolescents age_0_5 age_6_10 age_11_14 age_15_19 age_20_34 age_35_49 age_50_69 age_70 female_19 male_19 female_20_49 male_20_49 female_50 male_50 NHW NHB Mexican_American below_HS HS some_college college_above lower_income medium_income higher_income {
		
	local k=`k'+1
	* OVERALL TREND 
	* survey-weighted mean over years
	svy, subpop(if filter==1 & `subgroup'==1): mean `var', over(year)
	matrix A = r(table)
	* rounding for different variables: note for calories need one more step to round up to integer in excel 
	quietly: putexcel a`k'=(e(varlist)) b`k'=("`subgroup'") c`k'=("average") d`k'=(round(A[1,1], 0.1)) e`k'=(round(A[1,2], 0.1)) f`k'=(round(A[1,3], 0.1)) g`k'=(round(A[1,4], 0.1)) h`k'=(round(A[1,5], 0.1)) i`k'=(round(A[1,6], 0.1)) j`k'=(round(A[1,7], 0.1)) k`k'=(round(A[1,8], 0.1)) l`k'=(round(A[1,9], 0.1)) m`k'=(round(A[1,10], 0.1))
	* survey-weighted p-trend
	svy, subpop(if filter==1 & `subgroup'==1): regress `var' c.year
	matrix A = r(table)
	quietly: putexcel  n`k'=(A[4,1])
	* survey-weighted pair wise p-value
	svy, subpop(if filter==1 & `subgroup'==1): regress `var' ib10.year
	matrix A = r(table)
	quietly: putexcel p`k'=(A[4,10])

	}
}

/* SAMPLE SIZE PER STRATA/YEAR */
putexcel set "tester3.xlsx", modify sheet(SampleSizes)

levelsof year if filter == 1, local(years) /*unique years*/

local j=1  
quietly: putexcel a`j'=("POPULATION") b`j'=("2001-2") c`j'=("2003-4") d`j'=("2005-6") e`j'=("2007-8") f`j'=("2009-10") g`j'=("2011-12") h`j'=("2013-14") i`j'=("2015-16") j`j'=("2017-20") k`j'=("2021-23") 

* LOOP OVER ALL POPULATION
foreach subgroup in total female male child adolescents age_0_5 age_6_10 age_11_14 age_15_19 age_20_34 age_35_49 age_50_69 age_70 female_19 male_19 	 female_20_49 male_20_49 female_50 male_50 NHW NHB Mexican_American below_HS HS some_college college_above lower_income medium_income higher_income {
	local j=`j'+1
	quietly putexcel A`j' = ("`subgroup'")
	local col = 2 // Column B = 2
	foreach yr of local years {
	* unweighted sample sizes across years
	count if filter == 1 & `subgroup' == 1 & year == `yr'
	local n = r(N) /*record number of observations*/
	local letter = char(64 + `col')
    quietly putexcel `letter'`j' = (`n')
	local col = `col' + 1
	}
}

	