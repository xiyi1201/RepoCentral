
cd "C:\Users\09453022\OneDrive - Pepsico\Epidemiology - Documents\Data\NHANES"

use dr1iff_b.dta, clear /* 2001 */
append using dr1iff_c	/* 2003 */
append using dr1iff_d	/* 2005 */
append using dr1iff_e	/* 2007 */
append using dr1iff_f	/* 2009 */
append using dr1iff_g	/* 2011 */
append using dr1iff_h	/* 2013 */
append using dr1iff_i	/* 2015 */
append using p_dr1iff	/* 2017-20 */
append using dr1iff_j	/* 2021-23 */

* Food code harmonization
replace dr1ifdcd = drdifdcd if dr1ifdcd==.
tostring dr1ifdcd, g(foodcode_str)

* Cleaning up a few variables
replace dr1drstz=drddrstz if dr1drstz==.
ta dr1drstz, m 

lookfor wt
replace wtdrd1=wtdrd1pp if wtdrd1==.
summ wtdrd1

* Collapse statement for creating person-level data file
collapse (sum) dr1ikcal dr1iprot dr1itfat dr1isfat dr1ipfat dr1imfat dr1icarb dr1isugr dr1ifibe dr1ichol dr1ivc (max) dr1drstz wtdrd1, by(seqn)
save "C:\Users\09453022\OneDrive - Pepsico\Epidemiology - Documents\Projects\Master_Trends\intermediate.dta", replace

* BRING IN DEMOGRAPHIC DATA
use demo_b, clear
append using demo_c demo_d demo_e demo_f demo_g demo_h demo_i p_demo demo_j
merge 1:1 seqn using "C:\Users\09453022\OneDrive - Pepsico\Epidemiology - Documents\Projects\Master_Trends\intermediate.dta"

* GENERAGE AGE GROUPINGS
ta ridageyr sdd if dr1drstz==1 
recode ridageyr (min/5=1) (5/9=2) (10/14=3) (15/19=4) (20/29=5) (30/39=6) (40/49=7) (50/64=8) (65/max=9), g(agecat)

* GENERATE FILTER VARIABLE
g filter=1 if dr1drstz==1

* SVYSET THE DATA
svyset [pweight=wtdrd1], strata(sdmvstra) psu(sdmvpsu)

* Zero out variables 
foreach var in dr1ikcal dr1iprot dr1itfat dr1isfat dr1ipfat dr1imfat dr1icarb dr1isugr dr1ifibe dr1ichol dr1ivc { 
	replace `var'=. if dr1drstz!=1
}

* RECODE YEAR VARIABLES
recode sdd (10=11) (66=10), g(year)
mean dr1ikcal, over(year)

gen countvar=1

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
gen medium_income=1 if ridageyr<1.3 & indfmpir<2.5
gen higher_income=1 if indfmpir>=2.5

* CREATE NEW VARIABLES FOR INTERPRETABILITY: % of total energy
gen PCTdr1iprot = ((dr1iprot * 4)/dr1ikcal)*100 /*protein (4 kcal per gram)*/
gen PCTdr1icarb = ((dr1icarb * 4)/dr1ikcal)*100 /*carbohydrate (4 kcal per gram)*/
gen PCTdr1isugr = ((dr1isugr * 4)/dr1ikcal)*100 /*total sugar (4 kcal per gram)*/
gen PCTdr1itfat = ((dr1itfat * 9)/dr1ikcal)*100 /*total fat (9 kcal per gram)*/
gen PCTdr1isfat = ((dr1isfat * 9)/dr1ikcal)*100 /*saturated fat (9 kcal per gram)*/

/* CALORIES */
putexcel set "C:\Users\09453022\OneDrive - Pepsico\Epidemiology - Documents\Projects\Master_Trends\tester3.xlsx", modify sheet(Calories)

local k=1
* EXCEL LABELS
	quietly: putexcel a`k'=("VARIABLE") b`k'=("POPULATION") c`k'=("Parameter") d`k'=("2001-2") e`k'=("2003-4") f`k'=("2005-6") g`k'=("2007-8") h`k'=("2009-10") i`k'=("2011-12") j`k'=("2013-14") k`k'=("2015-16") l`k'=("2017-20") m`k'=("2021-23") n`k'=("p-trend") o`k'=("%_change") p`k'=("PAIRWISE_TEST_LAST_2_CYCLES")

* LOOP OVER ALL VARIABLES
foreach var of varlist dr1ikcal dr1iprot dr1itfat dr1isfat dr1ipfat dr1imfat dr1icarb dr1isugr dr1ifibe dr1ichol dr1ivc PCTdr1iprot PCTdr1icarb PCTdr1isugr PCTdr1itfat PCTdr1isfat {
	
	* NESTED LOOP: POPULATION SUBGROUP
	foreach subgroup in total female male child adolescents age_0_5 age_6_10 age_11_14 age_15_19 age_20_34 age_35_49 age_50_69 age_70 female_19 male_19 female_20_49 male_20_49 female_50 male_50 NHW NHB Mexican_American below_HS HS some_college college_above lower_income medium_income higher_income {
		
	local k=`k'+1
	* OVERALL TREND 
	* survey-weighted mean over years
	svy, subpop(if filter==1 & `subgroup'==1): mean `var', over(year)
	matrix A = r(table)
	* rounding for different variables 
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
putexcel set "C:\Users\09453022\OneDrive - Pepsico\Epidemiology - Documents\Projects\Master_Trends\tester3.xlsx", modify sheet(SampleSizes)

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
	local n = r(N)
	*quietly: putexcel b`j'=(`n') c`j'=(`n') d`j'=(`n') e`j'=(`n') f`j'=(`n') g`j'=(`n') h`j'=(`n') i`j'=(`n') j`j'=(`n') k`j'=(`n')
	local letter = char(64 + `col')
    quietly putexcel `letter'`j' = (`n')
	local col = `col' + 1
	}
}
	
	