* Appendix replication file for: 
* Daniels B, Dolinger A, Bedoya G, Rogo K, Goicoechea A, Coarasa J, Wafula F, Mwaura N, Kimeu R, Das J. 
* Use of standardised patients to assess quality of healthcare in Nairobi, Kenya: 
* A pilot, cross-sectional study with international comparisons. 
* BMJ Global Health. 2017 Jun 1;2(2):e000333.

version 13
cd "/Users/bbdaniels/GitHub/bmjgh2017/"

	qui do "adofiles/betterbar.ado"
	qui do "adofiles/chartable.ado"
	qui do "adofiles/reftab.ado"
	qui do "adofiles/tabstatout.ado"
	qui do "adofiles/weightab.ado"

* Table A1. Essential history question items

	use "data/sp_kenya.dta" , clear

	label var cp_h27 "Taking Other Medications"

	tabstatout ///
		as_h1 as_h12 as_h22 as_h20 as_h21 as_h15 as_h16 as_h19 as_h23 as_h6 as_h7 as_h8 ///
		cp_h1 cp_h26 cp_h3 cp_h9 cp_h5 cp_h6 cp_h10 cp_h13 cp_h22 cp_h27 ///
		ch_h1 ch_h17 ch_h10 ch_h9 ch_h18 ch_h14 ch_h16 ch_h6 ///
		tb_h1 tb_h2 tb_h3 tb_h4 tb_h5 tb_h6 tb_h7 tb_h8 tb_h9 ///
		using "outputs/Table_A1.xls" ///
		, replace by(case_code ) dec(2 2 2 2 ) ///
			lines(COL_NAMES 3 LAST_ROW 3) 
			
* Table A2. Primary Outcomes for Standardized Patients Cases Among Private Facilities
	
	use "data/sp_kenya.dta" , clear
	
	recode facility_type (2 = 0 "Private")(3/5 = 1 "FBO/NGO")(* =.) , gen(fbongo)

	reftab ??_correct waiting duration checklist_essential price_kenya refer med_any med med_class_any_6 med_class_any_16 ///
		using "outputs/Table_A2.xls" ///
		, by(fbongo) controls(i.case_code) ref(0) ///
			se n replace sheet("Table 5") dec(2 2 2 2 `theDec') lines(COL_NAMES 3 LAST_ROW 3) 

* Table A3. Validation Regressions with Standardized Patient Characteristics

	use "data/sp_kenya.dta" , clear

	qui foreach var of varlist correct waiting duration checklist_essential price_kenya refer med_any med med_class_any_6 med_class_any_16 {
		reg `var' sp_roster_age sp_roster_bmi sp_roster_bp_sys sp_roster_male i.case_code, cluster(facilitycode)
		est sto `var'
		
		local theLabel : var label `var'
		local theLabels `"`theLabels' "`theLabel'""'
		
		qui sum `var' if e(sample)
		local mean = `r(mean)'
		estadd scalar mean = `mean'
		
		}
		
	xml_tab correct waiting duration checklist_essential price_kenya refer med_any med med_class_any_6 med_class_any_16 ///
		using "outputs/Table_A3.xls" ///
		, replace below keep(sp_roster_age sp_roster_bmi sp_roster_bp_sys sp_roster_male) cnames(`theLabels') stats(mean N) ///
		 lines(COL_NAMES 3 LAST_ROW 3) 

* Table A4. Diagnoses Given, by Standardized Patient Case

	use "data/sp_kenya.dta" , clear
	
	replace diagnosis  = "NO DIAGNOSIS" if diagnosis == ""

	tabout diagnosis case ///
		using "outputs/Table_A4.xls" , replace
		
* Table A5: Cross-country results
	
	use "data/sp_comparison.dta", clear
		
	recode study_code (2 = 1 "Kenya") (3/4 = 2 "India") (5 = 3 "China") (* = .), gen(studytemp)
	
	drop if studytemp == .
	
	recode study_code (2 = 1 "Nairobi, Kenya") (5 = 2 "Rural China") (3 = 3 "Rural India") (4 = 4 "Urban India") , gen(studygraph)
	
	label var refer "Referred"
	label var correct "Correct"
	
	label def check 1 "Asthma" 2 "Chest Pain" 3 "Diarrhoea" 4 "Tuberculosis"
		label val case_code check
	
	gen kenya = (study == "Kenya")
		expand 2 if kenya == 1, gen(false)
		replace study = "India" if studytemp == 2
		replace case = "All" if false == 1
		
		label var checklist "Common Checklist %"
		label var med "Number of Medications"
	
	egen check = group(case study), lname(checktemp)
	gen weight = 1
	
	weightab  correct waiting duration checklist price refer med_any med med_class_any_6 med_class_any_16   ///
		using	"outputs/Table_A5.xls" ///
				[pweight = weight] ///
				, replace ///
				over(check) stats(b ll ul) n dec(2 2 2 2 2 2 2 2 2 2)  lines(COL_NAMES 3 LAST_ROW 3) 

* Figure A1. Sampling Map

	* Not included in this dataset due to identifying information.
	
* Figure A2. Three-Sector Comparison of Quality Outcomes

	use "data/sp_kenya.dta" , clear
		
	label var as_correct "Asthma: Inhaler/Bronchodilator"
	label var ch_correct "Child Diarrhoea: ORS"
	label var cp_correct "Chest Pain: Referral/Aspirin/ECG"
	label var tb_correct "Tuberculosis: AFB Smear"

	 recode facility_type (3/5 = 3)
	 
	 label def facility_type 1 "Public" 2 "Private For-Profit" 3 "Private FBO/SFO", modify
		label val facility_type facility_type
	 
	 betterbar ///
		??_correct  checklist  refer med_any  med_class_any_6 med_class_any_16 ///
		, $graph_opts over(facility_type) xlab(${pct}) barlab(mean) legend(r(1) symxsize(small) symysize(small))
		
		graph export "outputs/Figure_A2.png" , replace width(2000)
		
* Figure A3. Comparison of marginal effects from linear and logistic specifications

	use "data/sp_kenya.dta" , clear
		
	label var as_correct "Asthma: Inhaler/Bronchdilator"
	label var ch_correct "Child Diarrhea: ORS"
	label var cp_correct "Chest Pain: Referral/Aspirin/ECG"
	label var tb_correct "Tuberculosis: AFB Smear"
	
	cap mat drop theResults
	local theLabels ""
	local x = 15.5

	qui foreach var of varlist ??_correct refer med_any med_class_any_6 med_class_any_16 {

		local theLabel : var label `var'
		local theLabels `"`theLabels' `x' "`theLabel'""'
		local x = `x' - 2
	
		reg `var' facility_private i.case_code 
		
		mat a = r(table)
			local b = a[1,1]
			local ll = a[5,1]
			local ul = a[6,1]
			mat a = [`b',`ll',`ul',1]
			
			mat rownames a = "`var'"
		
		logit `var' facility_private i.case_code 
			margins , dydx(facility_private)
		
		mat b = r(table)
			local b = b[1,1]
			local ll = b[5,1]
			local ul = b[6,1]
			mat b = [`b',`ll',`ul',2]
			
			mat rownames b = "`var'"
			
		mat theResults = nullmat(theResults) \ a \ b 
		
		}
		
	mat colnames theResults = "b" "ll" "ul" "type"
	matlist theResults

	clear
	svmat theResults , names(col)
	
	gen n = _n
	replace n = 17-n
	tw ///
		(rcap ll ul n if type == 1 , hor lc(navy)) ///
		(scatter n b if type == 1 , mc(black)) ///
		(rcap ll ul n if type == 2 , hor lc(maroon)) ///
		(scatter n b if type == 2 , mc(black)) ///
		, $graph_opts ylab(`theLabels') ytit(" ") xlab(-1 "-100p.p." -.5 `""-50p.p." "{&larr} Favors Public""' 0 "No Effect" .5 `""+50p.p." "Favors Private {&rarr}""' 1 "+100p.p.") ///
			xline(0 , lc(gs12) lp(dash)) legend(order(2 "Marginal Effect" 1 "Linear Model" 3 "Logistic Model") r(1))

		graph export "outputs/Figure_A3.png" , replace width(2000)

* Have a lovely day!
