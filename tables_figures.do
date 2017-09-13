* Replication file for: 
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

	global graph_opts title(, justification(left) color(black) span pos(11)) graphregion(color(white)) ylab(,angle(0) nogrid) xtit(,placement(left) justification(left)) yscale(noline) xscale(noline) legend(region(lc(none) fc(none)))
	global graph_opts_1 title(, justification(left) color(black) span pos(11)) graphregion(color(white)) ylab(,angle(0) nogrid) yscale(noline) xsize(7) legend(region(lc(none) fc(none)))
	global comb_opts graphregion(color(white)) xsize(7) legend(region(lc(none) fc(none)))
	global hist_opts ylab(, angle(0) axis(2)) yscale(noline alt axis(2)) ytit(, axis(2)) ytit(, axis(1)) yscale(off axis(2)) yscale(alt)
	global note_opts justification(left) color(black) span pos(7)
	global pct `" 0 "0%" .25 "25%" .5 "50%" .75 "75%" 1 "100%" "'
		
* Table 2. Facility summary statistics

	use "data/facilities.dta", clear
	recode facility_type (1=1 "Public")(2=2 "Private")(3/max = 3 "FBO/SFO") , gen(typetemp)
	
	label var kenya_fac_nstaff "Average Staff Size"
	label var kenya_fac_pharm "Has Pharmacy" 
	label var kenya_fac_lab "Has Laboratory" 
	label var kenya_fac_qual_code_1 "Main Provider CO" 
	label var kenya_fac_qual_code_2 "Main Provider Nurse" 
	label var kenya_fac_qual_code_3 "Main Provider MO" 
	
	tabstatout 	///
			(mean) kenya_fac_nstaff kenya_fac_avgpats ///
			(sum)  kenya_fac_level_1 kenya_fac_level_2 kenya_fac_pharm kenya_fac_lab kenya_fac_qual_code_1 kenya_fac_qual_code_2 kenya_fac_qual_code_3 ///
		using 	"outputs/Table_1.xls" ///
			, 	n t by(typetemp) replace ///
				dec(1 0 0 0 0 0 0 0)  ///
				lines(COL_NAMES 3 LAST_ROW 3) 
		
* Table 3. Primary outcomes for standardised patient (SP) cases

	use "data/sp_kenya.dta" , clear
	
	expand 2, gen(false)
		replace case_code = 9 if false == 1
		label def case 9 "Total", modify
		
	gen weight = 1

	label var as_correct "Inhaler or Bronchodilator"
	label var ch_correct "ORS"
	label var cp_correct "Referral, ECG, or Aspirin"
	label var tb_correct "Sputum Test"

	weightab correct waiting duration checklist_essential price_kenya refer med_any med med_class_any_6 med_class_any_16 ///
		using "outputs/Table_2.xls" ///
		[pweight = weight] ///
		, over(case_code) n sd total replace stats(b ll ul) ///
			lines(COL_NAMES 3 LAST_ROW 3) 
			
* Table 4. Primary outcomes for standardised patient cases by sector

	use "data/sp_kenya.dta" , clear

	reftab ??_correct waiting duration checklist_essential price_kenya refer med_any med med_class_any_6 med_class_any_16 ///
		using "outputs/Table_3_1.xls" ///
		, by(facility_private) controls(i.case_code) ref(0) ///
			se n replace lines(COL_NAMES 3 LAST_ROW 3) 
			
	reftab ??_correct refer med_any med_class_any_6 med_class_any_16 ///
		using "outputs/Table_3_2.xls" ///
		, by(facility_private) controls(i.case_code) ref(0) ///
			logit se n replace lines(COL_NAMES 3 LAST_ROW 3) 

* Figure 1. Effect of sector on primary standardised patient outcomes

	use "data/sp_kenya.dta" , clear
	
	label var as_correct "Asthma: Inhaler/Bronchodilator"
	label var ch_correct "Child Diarrhoea: ORS"
	label var cp_correct "Chest Pain: Referral/Aspirin/ECG"
	label var tb_correct "Tuberculosis: AFB Smear"

	chartable ??_correct refer med_any med_class_any_6 med_class_any_16 ///
		, xsize(8) rhs(facility_private i.case_code) command(logit) or p case0(Public) case1(Private)
		
		graph export "outputs/Figure_1.png" , replace width(2000)
		
* Figure 2. Primary outcomes for standardised patient cases by setting

	use "data/sp_comparison.dta", clear
		
	recode study_code (2 = 1 "Kenya") (3/4 = 2 "India") (5 = 3 "China") (* = .), gen(studytemp)
	
	drop if studytemp == .
	
	recode study_code (2 = 1 "Nairobi, Kenya") (5 = 2 "Rural China") (3 = 3 "Rural India") (4 = 4 "Urban India") , gen(studygraph)
	
	label var refer "Referred"
	label var correct "Correct"
	
	label def check 1 "Asthma" 2 "Chest Pain" 3 "Diarrhoea" 4 "Tuberculosis"
		label val case_code check
	
	betterbar ///
		correct refer ch_child med_class_any_6 ///
		, over(studygraph) by(case_code) ///
			nobycolor se dropzero xlab(${pct}) ///
			legend(symxsize(small) symysize(small) pos(6) ring(1) r(2) ) ///
			barlook(1 lc(white) lw(thin) fi(100)) ysize(6)
			
		graph export "outputs/Figure_2.png" , replace width(2000)
				
* Have a lovely day!
