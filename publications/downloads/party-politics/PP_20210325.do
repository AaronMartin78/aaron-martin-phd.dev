***January 1, 2021

clear all
cd "C:\Users\admin\Desktop\Dissertation\Articles_Final_Submission_All_4_Papers\stata_analysis_ambitious_switch\Analysis for Party Politics Submission\"

***run lines 1-2612 in RR2_models_12072020_EUP do file and then save as dataset_12222020

use dataset_12222020, clear
	
	***Check EPG codes		
		bysort EP: tab2 start_group c_epg_perc
			
			**EP2
			list hoy_id start_group EP ms start_group_ses-group4_ses c_epg_perc if EP==2 & start_group=="RDE"
			replace c_epg_perc = -.1457988 if start_group=="RDE" & EP==2 & c_epg_perc < 0.20
			
			**EP3
			sort c_epg_perc
			list hoy_id start_group EP ms start_group_ses-group4_ses c_epg_perc if EP==3 & start_group=="EPP"	
			egen max= max(c_epg_perc) if  start_group=="EPP" & EP==3
			replace c_epg_perc = max if start_group=="EPP" & EP==3 & c_epg_perc < 0
			drop max
			
			list hoy_id start_group EP ms start_group_ses-group4_ses c_epg_perc if EP==3 & start_group=="GUE"	
			egen min= min(c_epg_perc) if  start_group=="GUE" & EP==3
			replace c_epg_perc = min if start_group=="GUE" & EP==3 & c_epg_perc > 0
			drop min
			
			list hoy_id start_group EP ms start_group_ses-group4_ses c_epg_perc if EP==3 & start_group=="LDR"
			egen max= max(c_epg_perc) if  start_group=="LDR" & EP==3
			replace c_epg_perc = max if start_group=="LDR" & EP==3 & c_epg_perc < -.11276
			drop max
			
			*EP4
			egen max= max(c_epg_perc) if  start_group=="ARE" & EP==4
			replace c_epg_perc = max if start_group=="ARE" & EP==4 & c_epg_perc < -.17
			drop max
			
			egen max= max(c_epg_perc) if  start_group=="ELDR" & EP==4
			replace c_epg_perc = max if start_group=="ELDR" & EP==4 & c_epg_perc < -.128
			drop max
			
			egen max= max(c_epg_perc) if  start_group=="EPP" & EP==4
			replace c_epg_perc = max if start_group=="EPP" & EP==4 & c_epg_perc < 0
			drop max
			
			egen max= max(c_epg_perc) if  start_group=="GUE/NGL" & EP==4
			replace c_epg_perc = max if start_group=="GUE/NGL" & EP==4 & c_epg_perc < -.1590
			drop max
			
			egen min= min(c_epg_perc) if  start_group=="UPE" & EP==4
			replace c_epg_perc = min if start_group=="UPE" & EP==4 & c_epg_perc > -.207
			drop min
			
			*EP5
			egen max= max(c_epg_perc) if  start_group=="EPP-ED" & EP==5
			replace c_epg_perc = max if start_group=="EPP-ED" & EP==5 & c_epg_perc < 0
			drop max
			
			egen max= max(c_epg_perc) if  start_group=="PES" & EP==5
			replace c_epg_perc = max if start_group=="PES" & EP==5 & c_epg_perc < 0
			drop max
			
			*EP6
			egen max= max(c_epg_perc) if  start_group=="ALDE" & EP==6
			replace c_epg_perc = max if start_group=="ALDE" & EP==6 & c_epg_perc < -0.07
			drop max
						
	***Center npd_perc
			sum npd_percent
			gen c_npd_perc = npd_percent - r(mean)
			

	***Code from dissertation article
		sort EP start_group_ses-group4_ses parlgov inst_switch
		replace ftr = 1 if start_group == "CDI" & EP>1
		replace dissolve = 0 if hoy_id==1289 & EP==3
		replace inst_switch = 0 if hoy_id==1289 & EP==3
		replace casc_cat = 0 if hoy_id==1289 & EP==3
		replace casc_cat2 = 0 if hoy_id==1289 & EP==3

	***DVs
		drop amb_switch
		
		gen amb_switch = 0
		replace amb_switch = 1 if indiv_switch_restrict1==1 & switch_count_ses ==1
		replace amb_switch = 1 if bloc_switch_restrict1==1 & switch_count_ses ==1
		
		gen amb_switch_indiv = 0
		replace amb_switch_indiv = 1 if indiv_switch_restrict1==1 & switch_count_ses ==1
		
		gen amb_switch_bloc = 0	
		replace amb_switch_bloc = 1 if bloc_switch_restrict1==1 & switch_count_ses ==1
		
		gen multiswitch=0
		replace multiswitch = 1 if switch_count_ses > 1
		
		tab session_switch multiswitch
		tab session_switch amb_switch
		tab multiswitch amb_switch
		tab collapse amb_switch
		tab collapse amb_switch_indiv
		tab collapse amb_switch_bloc
		
		list EP start_group_ses-group4_ses switch_count_ses amb_switch multiswitch collapse ftr merger dissolve ///
		if session_switch==1 & amb_switch==0 & multiswitch==0		
		
		sort EP switch_date1
		list EP start_group_ses-group4_ses switch_date1 switch_count_ses amb_switch multiswitch collapse ftr merger dissolve multiswitch a1_raw a1_std2 ///
		if start_ses_switch==1 & amb_switch==1 
	
	***Total Switches per session_switch
	
		**All checked out, the original variable is correct
	
		*egen switch_count_ses2 = rownonmiss(start_group_num_ses group1_num_ses group2_num_ses group3_num_ses group4_num_ses) if session_switch ==1
		*replace switch_count_ses2 = 0 if switch_count_ses2==.
		*gen switch_count_ses3 = 0
		*replace switch_count_ses3 = switch_count_ses2-1 if session_switch ==1		
		*list hoy_name EP start_group_ses-group4_ses switch_date1-switch_date3 switch_count_ses2 switch_count_ses3 switch_count_ses if switch_count_ses!= switch_count_ses3
			
	
	***Total Switches per Career
		drop switch_count_total
		
		bysort hoy_id: egen switch_count_total = sum(switch_count_ses)
		tab switch_count_total
		
		sort hoy_id EP
		list hoy_name EP start_group_ses-group4_ses switch_count_ses switch_count_total if switch_count_total >3
		
		list hoy_name EP start_group_ses-group4_ses switch_count_ses switch_count_total collapse ftr merger dissolve if switch_count_ses ==4
		list hoy_name EP start_group_ses-group4_ses switch_count_ses switch_count_total switch_date1-switch_date4 if switch_count_ses ==4
		
		list hoy_name EP start_group_ses-group4_ses switch_count_ses switch_count_total switch_date1-switch_date4 nationalparty ftr dissolve merger ///
		if switch_count_ses ==3 & collapse ==0
			**Three members of the Liga Nord Speroni, Bossi, Borghezi: Indem --> NI -->UEN
		
		sort EP bloc_id
		list hoy_name EP start_group_ses-group4_ses switch_count_ses switch_count_total switch_date1-switch_date4 bloc_id ftr dissolve merger ///
		if switch_count_ses ==2 & collapse ==0

	**Fix Intensity
		
		gen intensity2 = 0
		replace intensity2 = sqrt(((dw_nomd1 - 0)^2)+((dw_nomd2-0)^2))
		tab intensity2
			
		sum intensity2
		egen z_intense2 = std(intensity2)
		
	***Fix NPD ID codes
	***Bloc_id3 is basically just parlgov, and I created IDs for hthos that were missing	
	
		bysort ms nationalparty: egen max_bloc_id= max(bloc_id) if parlgov==.
		replace max_bloc_id = max_bloc_id + 10000
		
		list bloc_id max_bloc_id EP ms  nationalparty  if parlgov==. 
		
		gen bloc_id3 = parlgov
		replace bloc_id3 = max_bloc_id if bloc_id3==.
		replace bloc_id3 = 10000 if bloc_id==.
		drop max_bloc_id		
		
	***New Bloc Tag
		sort hoy_id EP start_group ms bloc_id3
		egen bloc_tag3 = tag(EP bloc_id3)
		tab bloc_tag3
		
		sort bloc_id3 EP 
		*list EP start_group ms bloc_id3 nationalparty if EP<3 & bloc_tag3==1
		
		run save_do
	
		sort hoy_id EP start_group end_group bloc_id3		
		save PP_dataset, replace
			
			*save check3, replace
			*cf _all using PP_dataset
			*ALL GOOD
*********************************************************************************
		
	***Models#
	
	**January 5, 2021

		*cd "C:\Users\admin\Desktop\Dissertation\Articles_Final_Submission_All_4_Papers\stata_analysis_ambitious_switch\Analysis for Party Politics Submission\Old\Jan4_2021\"
	
			*est use as_2L_full
			*use PP_dataset, clear
			*est esample: 
			*est esample			
			
			*margins, predict() at(a2_std2 =(-1(1)7) a1_std2==(-1 7)) vsquish atmeans post 
			*marginsplot
		xtset hoy_id EP
		log using 01052021, text
	
		***2 level Models, Delegation
			xtmelogit amb_switch || bloc_id3:
			estat icc
			estat ic
			est store as_base_npd
			est save as_base_npd, replace
			
			xtmelogit amb_switch || start_group_num: 
			estat icc
			estat ic
			est store as_base_epg
			est save as_base_epg, replace			
			
			
			**NPD Nested
				xtmelogit amb_switch ///
				c.a1_std2##c.a2_std2 ///
				c.a1_std2#c.a1_std2 ///
				c.a2_std2#c.a2_std2 ///
				c_npd_perc c_epg_perc govt2 ///
				mep_tenure age_martin i.female ///
				|| bloc_id3:
				
					generate sample_amb = e(sample)
					est store as_2L_npd_full
					est save as_2L_npd_full, replace
					estat icc
					estat ic
				
					est restore as_2L_npd_full
					margins, predict() at(a2_std2 =(-1(1)7) a1_std2==(-1 7)) vsquish atmeans post 
					marginsplot
				
					test _b[1._at] = _b[4._at]
					test _b[1._at] = _b[5._at]
					test _b[1._at] = _b[10._at]
					test _b[9._at] = _b[18._at]
					test _b[10._at] = _b[18._at]
					test _b[8._at] = _b[17._at]
			
			***EPG Tested
				xtmelogit amb_switch ///
				c.a1_std2##c.a2_std2 ///
				c.a1_std2#c.a1_std2 ///
				c.a2_std2#c.a2_std2 ///
				c_npd_perc c_epg_perc govt2 ///
				mep_tenure age_martin i.female ///
				|| start_group_num: if sample_amb==1
					
					est store as_2L_epg_full
					est save as_2L_epg_full, replace
					estat icc
					estat ic
				
					est restore as_2L_epg_full
					margins, predict() at(a2_std2 =(-1(1)7) a1_std2==(-1 7)) vsquish atmeans post 
					marginsplot
				
***********************************************************************************
			
			***3 Level Models
				xtmelogit amb_switch || start_group_num: || bloc_id3: 
				estat icc
				estat ic
				est store as_base_3L
				est save as_base_3L, replace			
			
			
			***Intensity	
				*Initial starting points
					logit amb_switch ///
					z_intense2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female
					matrix as3 = e(b) 
				
					xtmelogit amb_switch ///
					z_intense2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female ///
					|| start_group_num: || bloc_id3: if sample_amb==1, refineopts(iterate(0)) from(as3, skip) difficult
					
						est store as_3L_intensity
						est save as_3L_intensity, replace
						estat icc
						estat ic
				
			***Quadratic
				*Initial starting points
					logit amb_switch ///
					c.a1_std2 c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female
					matrix as4 = e(b) 
				
					xtmelogit amb_switch ///
					c.a1_std2 c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female ///
					|| start_group_num: || bloc_id3: if sample_amb==1 , refineopts(iterate(0)) from(as4, skip) difficult				
					
						est store as_3L_quad
						est save as_3L_quad, replace
						estat icc
						estat ic
						
			***Distances
				*Initial starting points
					logit amb_switch ///
					c.a1_std2 c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female
					matrix as5 = e(b) 				
				
					xtmelogit amb_switch ///
					c.a1_std2 c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female ///
					|| start_group_num: || bloc_id3: if sample_amb==1 , refineopts(iterate(0)) from(as5, skip) difficult
				
					est store as_3L_dist
					est save as_3L_dist, replace
					estat icc
					estat ic				
					
			***Full Models
				*Initial starting points
					logit amb_switch ///
					c.a1_std2##c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female
					matrix as4 = e(b) 
				
					xtmelogit amb_switch ///
					c.a1_std2##c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female ///
					|| start_group_num: || bloc_id3: if sample_amb==1 , refineopts(iterate(0)) from(as4, skip) difficult				
					
						est store as_3L_full
						est save as_3L_full, replace
						estat icc
						estat ic
						
				***Table Just 3 Level Models
					
					est use as_base_3L
					outreg2 using amb_switch1,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					
					est use as_3L_intensity
					outreg2 using amb_switch1,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					
					est use as_3L_dist
					outreg2 using amb_switch1,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
				
					est use as_3L_quad
					outreg2 using amb_switch1,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
					
					est use as_3L_full
					outreg2 using amb_switch1,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
					
****************************************************************************************************************************************	
	***2 Level Models--Delegations
				xtmelogit amb_switch || bloc_id3: 
				estat icc
				estat ic
				est store as_base_2L
				est save as_base_2L, replace			
			
			
			***Intensity	
				*Initial starting points
					logit amb_switch ///
					z_intense2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female
					matrix as5 = e(b) 
				
					xtmelogit amb_switch ///
					z_intense2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female ///
					 || bloc_id3: if sample_amb==1, refineopts(iterate(0)) from(as5, skip) difficult
					
						est store as_2L_intensity
						est save as_2L_intensity, replace
						estat icc
						estat ic
				
			***Quadratic
				*Initial starting points
					logit amb_switch ///
					c.a1_std2 c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female
					matrix as6 = e(b) 
				
					xtmelogit amb_switch ///
					c.a1_std2 c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female ///
					 || bloc_id3: if sample_amb==1 , refineopts(iterate(0)) from(as6, skip) difficult				
					
						est store as_2L_quad
						est save as_2L_quad, replace
						estat icc
						estat ic
						
			***Distances
				*Initial starting points
					logit amb_switch ///
					c.a1_std2 c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female
					matrix as7 = e(b) 				
				
					xtmelogit amb_switch ///
					c.a1_std2 c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female ///
					 || bloc_id3: if sample_amb==1 , refineopts(iterate(0)) from(as7, skip) difficult
				
					est store as_2L_dist
					est save as_2L_dist, replace
					estat icc
					estat ic				
					
			***Full Models
				*Initial starting points
					logit amb_switch ///
					c.a1_std2##c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female
					matrix as8 = e(b) 
				
					xtmelogit amb_switch ///
					c.a1_std2##c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female ///
					 || bloc_id3: if sample_amb==1 , refineopts(iterate(0)) from(as8, skip) difficult				
					
						est store as_2L_full
						est save as_2L_full, replace
						estat icc
						estat ic
						
				***Table Just 2 Level Models
					
					est use as_base_2L
					outreg2 using amb_switch2,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					
					est use as_2L_intensity
					outreg2 using amb_switch2,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					
					est use as_2L_dist
					outreg2 using amb_switch2,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
				
					est use as_2L_quad
					outreg2 using amb_switch2,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
					
					est use as_2L_full
					outreg2 using amb_switch2,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
					
	
				lrtest as_3L_full as_2L_full
				
				lrtest as_3L_quad as_2L_quad
				
				lrtest as_3L_dist as_2L_dist
				
				lrtest as_3L_intensity as_2L_intensity
				
				
****************************************************************************************************************************************	
	***2 Level Models--EPGS
				xtmelogit amb_switch || start_group_num:
				estat icc
				estat ic
				est store as_base_2LB
				est save as_base_2LB, replace			
			
			
			***Intensity	
				*Initial starting points
					logit amb_switch ///
					z_intense2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female
					matrix as9 = e(b) 
				
					xtmelogit amb_switch ///
					z_intense2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female ///
					 || start_group_num: if sample_amb==1, refineopts(iterate(0)) from(as9, skip) difficult
					
						est store as_2LB_intensity
						est save as_2LB_intensity, replace
						estat icc
						estat ic
				
			***Quadratic
				*Initial starting points
					logit amb_switch ///
					c.a1_std2 c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female
					matrix as10 = e(b) 
				
					xtmelogit amb_switch ///
					c.a1_std2 c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female ///
					 || start_group_num: if sample_amb==1 , refineopts(iterate(0)) from(as10, skip) difficult				
					
						est store as_2LB_quad
						est save as_2LB_quad, replace
						estat icc
						estat ic
						
			***Distances
				*Initial starting points
					logit amb_switch ///
					c.a1_std2 c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female
					matrix a11 = e(b) 				
				
					xtmelogit amb_switch ///
					c.a1_std2 c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female ///
					 || start_group_num: if sample_amb==1 , refineopts(iterate(0)) from(a11, skip) difficult
				
					est store as_2LB_dist
					est save as_2LB_dist, replace
					estat icc
					estat ic				
					
			***Full Models
				*Initial starting points
					logit amb_switch ///
					c.a1_std2##c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female
					matrix as12 = e(b) 
				
					xtmelogit amb_switch ///
					c.a1_std2##c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female ///
					 || start_group_num: if sample_amb==1 , refineopts(iterate(0)) from(as12, skip) difficult				
					
						est store as_2LB_full
						est save as_2LB_full, replace
						estat icc
						estat ic
						
				***Table Just 2 Level Models
					
					est use as_base_2LB
					outreg2 using amb_switch2B,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					
					est use as_2LB_intensity
					outreg2 using amb_switch2B,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					
					est use as_2LB_dist
					outreg2 using amb_switch2B,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
				
					est use as_2LB_quad
					outreg2 using amb_switch2B,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
					
					est use as_2LB_full
					outreg2 using amb_switch2B,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
					
						lrtest as_3L_full as_2LB_full
					
						lrtest as_3L_quad as_2LB_quad
						
						lrtest as_3L_dist as_2LB_dist
						
						lrtest as_3L_intensity as_2LB_intensity
						
							
***Robustness Checks

	*Logistic Regression
			
			***Intensity	
					logit amb_switch ///
					z_intense2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female, vce(cluster hoy_id)
					est store as_log_intense
					est save as_log_intense, replace
					
					logit amb_switch ///
					z_intense2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female, vce(cluster bloc_id3)
					est store as_log_intense2
					est save as_log_intense2, replace
					
					logit amb_switch ///
					z_intense2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female, vce(cluster start_group_num)
					est store as_log_intense3
					est save as_log_intense3, replace
					
			***Distances
				*Initial starting points
					logit amb_switch ///
					c.a1_std2 c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female, vce(cluster hoy_id)				
					est store as_log_dist
					est save as_log_dist, replace
					
					logit amb_switch ///
					c.a1_std2 c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female, vce(cluster bloc_id3)				
					est store as_log_dist2
					est save as_log_dist2, replace
					
					logit amb_switch ///
					c.a1_std2 c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female, vce(cluster start_group_num)				
					est store as_log_dist3
					est save as_log_dist3, replace
					
			***Quadratic
				*Initial starting points
					logit amb_switch ///
					c.a1_std2 c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female, vce(cluster hoy_id)
					est store as_log_quad
					est save as_log_quad, replace
					
					logit amb_switch ///
					c.a1_std2 c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female, vce(cluster bloc_id3)
					est store as_log_quad2
					est save as_log_quad2, replace
					
					logit amb_switch ///
					c.a1_std2 c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female, vce(cluster start_group_num)
					est store as_log_quad3
					est save as_log_quad3, replace								
					
			***Full Models
				*Initial starting points
					logit amb_switch ///
					c.a1_std2##c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female, vce(cluster hoy_id)	
					est store as_log_full
					est save as_log_full, replace
					
					logit amb_switch ///
					c.a1_std2##c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female, vce(cluster bloc_id3)	
					est store as_log_full2
					est save as_log_full2, replace
					
					logit amb_switch ///
					c.a1_std2##c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female, vce(cluster start_group_num)	
					est store as_log_full3
					est save as_log_full3, replace
	
***FirthLogit with collapse
					
					firthlogit session_switch ///
					collapse ///
					z_intense2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female
					est store as_firth_intense
					est save as_firth_intense, replace	
					firthfit
					
					firthlogit session_switch ///
					ftr dissolve merger ///
					z_intense2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female
					est store as_firth_intense
					est save as_firth_intense2, replace		
					firthfit
					
			***Distances		
					firthlogit session_switch ///
					collapse ///
					c.a1_std2 c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female			
					est store as_firth_dist
					est save as_firth_dist, replace
					firthfit
					
					firthlogit session_switch ///
					ftr dissolve merger ///
					c.a1_std2 c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female			
					est store as_firth_dist2
					est save as_firth_dist2, replace
					firthfit
					
			***Quadratic				
					firthlogit session_switch ///
					collapse ///
					c.a1_std2 c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female
					est store as_firth_quad
					est save as_firth_quad, replace								
					firthfit
					
					firthlogit session_switch ///
					ftr dissolve merger ///
					c.a1_std2 c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female
					est store as_firth_quad2
					est save as_firth_quad2, replace								
					firthfit
					
			***Full Models				
					firthlogit session_switch ///
					collapse ///
					c.a1_std2##c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female
					est store as_firth_full
					est save as_firth_full, replace
					firthfit
					
					firthlogit session_switch ///
					ftr dissolve merger ///
					c.a1_std2##c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female
					est store as_firth_full2
					est save as_firth_full2, replace
					firthfit
					
					margins, predict() at(a2_std2 =(-1(1)7) a1_std2==(-1 7)) vsquish atmeans post 
					marginsplot
	
	
	*********************************************************************************
	***The Multi-switching Models are good.
	***Need to re-avaluate the distance variables for the models on ambitious switching
	
	***January 4, 2021
	
	**Switch Count Models
		*log using pp_01042020, text
		use PP_dataset, clear
		xtset hoy_id EP
	
		**Switches per session per MEP
			log using 01072021_A, text
			
			***Negative Binomial Regression
		
				***With Exposure
					xtnbreg  switch_count_ses collapse c_npd_perc c_epg_perc mep_tenure age_martin i.female,  ///
					exposure(daysinoffice) i(start_group_num) difficult  
					est store ses_count_collapse_nb
					est save ses_count_collapse_nb, replace	
					estat ic
					*gen sample = e(sample)
					
					xtnbreg  switch_count_ses ftr dissolve merger c_npd_perc c_epg_perc mep_tenure age_martin i.female,  ///
					exposure(daysinoffice) i(start_group_num) difficult  
					est store ses_count_collapse_nb2
					est save ses_count_collapse_nb2, replace	
					estat ic
					
					xtnbreg  switch_count_ses c_npd_perc c_epg_perc mep_tenure age_martin i.female, exposure(daysinoffice) difficult i(start_group_num) 
					est store ses_count_no_collapse_nb 
					est save ses_count_no_collapse_nb, replace	
					estat ic	
										
					lrtest ses_count_collapse_nb ses_count_no_collapse_nb
				
				***Without Exposure
					xtnbreg  switch_count_ses collapse c_npd_perc c_epg_perc mep_tenure age_martin i.female,  ///
					i(start_group_num) difficult  
					est store ses_count_col_noexp_nb
					est save ses_count_col_noexp_nb, replace	
					estat ic
					*gen sample = e(sample)
					
					xtnbreg  switch_count_ses ftr dissolve merger c_npd_perc c_epg_perc mep_tenure age_martin i.female,  ///
					i(start_group_num) difficult  
					est store ses_count_col_noexp_nb2
					est save ses_count_col_noexp_nb2, replace	
					estat ic
					
					xtnbreg  switch_count_ses c_npd_perc c_epg_perc mep_tenure age_martin i.female, difficult i(start_group_num) 
					est store ses_count_no_collapse_nb2 
					est save ses_count_no_collapse_nb2, replace	
					estat ic			
							
				***Table Switch Count with NO Exposure
					est use ses_count_no_collapse_nb
					outreg2 using nbreg_no_exp,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use ses_count_collapse_nb
					outreg2 using nbreg_no_exp,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
					est use ses_count_collapse_nb2
					outreg2 using nbreg_no_exp,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
				
				***Table Switch Count with OUT Exposure Variable
					est use ses_count_col_noexp_nb
					outreg2 using nbreg_with_exp,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use ses_count_col_noexp_nb2
					outreg2 using nbreg_with_exp,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
					est use ses_count_no_collapse_nb2
					outreg2 using nbreg_with_exp,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word

				
			***Mixed Effects Poisson		
					mepoisson  switch_count_ses c_npd_perc c_epg_perc mep_tenure age_martin i.female ///
					|| start_group_num: || bloc_id3: ,  difficult vce(robust)
					est store ses_count_no_collpse_mep
					est save ses_count_no_collapse_mep, replace			
					estat ic
					
					mepoisson  switch_count_ses collapse c_npd_perc c_epg_perc mep_tenure age_martin i.female  ///
					|| start_group_num: || bloc_id3: ,  difficult 
					est store mepois_collapse
					est save mepois_collapse, replace
					
					est store ses_count_collapse_mep
					est save ses_count_collapse_mep, replace
					estat ic
					
						xtmepoisson  switch_count_ses collapse c_npd_perc c_epg_perc mep_tenure age_martin i.female  ///
						|| start_group_num: || bloc_id3: ,   difficult 
						est store extmepois_collapse
						est save extmepois_collapse
						
							lrtest extmepois_collapse mepois_collapse
							
					
					
					mepoisson  switch_count_ses ftr dissolve merger c_npd_perc c_epg_perc mep_tenure age_martin i.female  ///
					|| start_group_num: || bloc_id3: ,  difficult vce(robust)
					est store ses_count_collapse_mep2
					est save ses_count_collapse_mep2, replace
					estat ic
			
				***Table for ME Poisson Models						
					est use ses_count_no_collapse_mep
					outreg2 using mep,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
					est use ses_count_collapse_mep
					outreg2 using mep,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use ses_count_collapse_mep2
					outreg2 using mep,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
		
			***Firthlogit, Dichotomous Outcome, pooled
		
					firthlogit multiswitch c_npd_perc c_epg_perc mep_tenure age_martin i.female
					firthfit
					est store firth_multi1
					est save firth_multi1, replace
					
					firthlogit multiswitch collapse c_npd_perc c_epg_perc mep_tenure age_martin i.female
					firthfit
					est store firth_multi2
					est save firth_multi2, replace
					
					firthlogit multiswitch ftr dissolve merger c_npd_perc c_epg_perc mep_tenure age_martin i.female
					firthfit
					est store firth_multi3
					est save firth_multi3, replace
				
				***Table Firth	
					est use firth_multi1
					outreg2 using multi_firth,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use firth_multi2
					outreg2 using multi_firth,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use firth_multi3
					outreg2 using multi_firth,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
		
			***Mixed effects Logit
									
					xtmelogit multiswitch c_npd_perc c_epg_perc mep_tenure age_martin i.female || start_group_num:
					estat icc
					estat ic
					est store xtmelogit_multi1
					est save xtmelogit_multi1, replace
					
					xtmelogit multiswitch collapse c_npd_perc c_epg_perc mep_tenure age_martin i.female || start_group_num: 
					estat icc
					estat ic
					est store xtmelogit_multi2
					est save xtmelogit_multi2, replace
					
					xtmelogit multiswitch ftr dissolve merger c_npd_perc c_epg_perc mep_tenure age_martin i.female || start_group_num: 
					estat icc
					estat ic
					est store xtmelogit_multi3
					est save xtmelogit_multi3, replace
				
				***Table xtmelogit
					est use xtmelogit_multi1
					outreg2 using multi_xtmelogit,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use xtmelogit_multi2
					outreg2 using multi_xtmelogit,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use xtmelogit_multi3
					outreg2 using multi_xtmelogit,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
				
				***Combined	
					est use firth_multi1
					outreg2 using multi_combo,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use xtmelogit_multi1
					outreg2 using multi_combo,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use firth_multi2
					outreg2 using multi_combo,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word		
					est use xtmelogit_multi2
					outreg2 using multi_combo,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
					est use firth_multi3
					outreg2 using multi_combo,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
					est use xtmelogit_multi3
					outreg2 using multi_combo,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
				
				***Combined2				
					est use firth_multi1
					outreg2 using combo2,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use firth_multi2
					outreg2 using combo2,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
					est use xtmelogit_multi1
					outreg2 using combo2,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use xtmelogit_multi2
					outreg2 using combo2,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
	
			***Ordered Logit
					ologit  switch_count_ses c_npd_perc c_epg_perc mep_tenure age_martin i.female, vce(cluster hoy_id)	 
					est store ologit1
					est save ologit1, replace
					estat ic
					
					ologit  switch_count_ses collapse c_npd_perc c_epg_perc mep_tenure age_martin i.female, vce(cluster hoy_id)	 
					est store ologit2
					est save ologit2, replace
					estat ic
					
					ologit  switch_count_ses ftr dissolve merger c_npd_perc c_epg_perc mep_tenure age_martin i.female, vce(cluster hoy_id)	 
					est store ologit3
					est save ologit3, replace
					estat ic
				
				***Table Ologit
					est use ologit1
					outreg2 using ologit,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use ologit2
					outreg2 using ologit,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
					est use ologit3
					outreg2 using ologit,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
					
					log close

************************************************************************************************************+
					
****Models of Ambitious Switching
log using pp_01042020, text
xtset hoy_id EP
		
		***2 level Models, bloc_id3 == Parlgov + my substitutes for missing
			xtmelogit amb_switch || bloc_id3:
			estat icc
			estat ic
			est store as_base2
			est save as_base2, replace
			
			xtmelogit amb_switch || start_group_num: || bloc_id3:
			estat icc
			estat ic
			est store as_base3
			est save as_base3, replace			
			
			xtmelogit amb_switch ///
			c.a1_std2##c.a2_std2 ///
			c.a1_std2#c.a1_std2 ///
			c.a2_std2#c.a2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| bloc_id3:
			
				generate sample_amb = e(sample)
				est store as_2L_full
				est save as_2L_full, replace
				estat icc
				estat ic
			
				margins, predict() at(a2_std2 =(-1(1)7) a1_std2==(-1 7)) vsquish atmeans post 
				marginsplot
			
				test _b[1._at] = _b[4._at]
				test _b[1._at] = _b[5._at]
				test _b[1._at] = _b[10._at]
				test _b[9._at] = _b[18._at]
				test _b[10._at] = _b[18._at]
				test _b[8._at] = _b[17._at]
			
		
			xtmelogit amb_switch ///
			c.a1_std2 c.a2_std2 ///
			c.a1_std2#c.a1_std2 ///
			c.a2_std2#c.a2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| bloc_id3: if sample_amb==1
			
				est store as_2L_quad
				est save as_2L_quad, replace
				estat icc
				estat ic
				
			xtmelogit amb_switch ///
			c.a1_std2 c.a2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| bloc_id3: if sample_amb==1
			
				est store as_2L_dist
				est save as_2L_dist, replace
				estat icc
				estat ic		
		
			***Table Just 2 Level Models
				est use as_2L_dist
				outreg2 using amb_switch1,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
				est use as_2L_quad
				outreg2 using amb_switch1,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
				est use as_2L_full
				outreg2 using amb_switch1,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
		
			
		**3 level models, Delegations nested in groups
				**Generate Starting Points
				logit amb_switch ///
				c.a1_std2##c.a2_std2 ///
				c.a1_std2#c.a1_std2 ///
				c.a2_std2#c.a2_std2 ///
				c_npd_perc c_epg_perc govt2 ///
				mep_tenure age_martin i.female 
				matrix as = e(b)
					
					xtmelogit amb_switch ///
					c.a1_std2##c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female ///
					|| start_group_num: || bloc_id3: if sample_amb==1, refineopts(iterate(0)) from(as, skip) difficult
			
						est store as_3L_full
						est save as_3L_full, replace
						estat icc
						estat ic
						
					xtmelogit amb_switch ///
					c.a1_std2 c.a2_std2 ///
					c.a1_std2#c.a1_std2 ///
					c.a2_std2#c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female ///
					|| start_group_num: || bloc_id3: if sample_amb==1, refineopts(iterate(0)) from(as, skip) difficult
			
						est store as_3L_quad
						est save as_3L_quad, replace
						estat icc
						estat ic
						
					xtmelogit amb_switch ///
					c.a1_std2 c.a2_std2 ///
					c_npd_perc c_epg_perc govt2 ///
					mep_tenure age_martin i.female ///
					|| start_group_num: || bloc_id3: if sample_amb==1, refineopts(iterate(0)) from(as, skip) difficult
			
						est store as_3L_dist
						est save as_3L_dist, replace
						estat icc
						estat ic				
					
					***Table Just 3 level Models
						est use as_3L_dist
						outreg2 using amb_switch2,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word							
						est use as_3L_quad
						outreg2 using amb_switch2,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word		
						est use as_3L_full
						outreg2 using amb_switch2,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
						
					***Table Combo 2 & 3 Level Models
						est use as_2L_dist
						outreg2 using amb_switch3,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
						est use as_3L_dist
						outreg2 using amb_switch3,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word							
						est use as_2L_quad
						outreg2 using amb_switch3,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
						est use as_3L_quad
						outreg2 using amb_switch3,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word						
						est use as_2L_full
						outreg2 using amb_switch3,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
						est use as_3L_full
						outreg2 using amb_switch3,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
						
						
						
		**3 level models--slopes
				xtmelogit amb_switch ///
				c.a1_std2##c.a2_std2 ///
				c.a1_std2#c.a1_std2 ///
				c.a2_std2#c.a2_std2 ///
				c_npd_perc c_epg_perc govt2 ///
				mep_tenure age_martin i.female ///
				|| start_group_num: c_epg_perc || bloc_id3: if sample_amb==1, cov(unstruct) refineopts(iterate(0)) from(as, skip) difficult
		
					est store as_3L_full_slope
					est save as_3L_full_slope, replace
					estat icc
					estat ic
					
				xtmelogit amb_switch ///
				c.a1_std2 c.a2_std2 ///
				c.a1_std2#c.a1_std2 ///
				c.a2_std2#c.a2_std2 ///
				c_npd_perc c_epg_perc govt2 ///
				mep_tenure age_martin i.female ///
				|| start_group_num: c_epg_perc || bloc_id3: if sample_amb==1, cov(unstruct) refineopts(iterate(0)) from(as, skip) difficult
		
					est store as_3L_quad_slope
					est save as_3L_quad_slope, replace
					estat icc
					estat ic
					
				xtmelogit amb_switch ///
				c.a1_std2 c.a2_std2 ///
				c_npd_perc c_epg_perc govt2 ///
				mep_tenure age_martin i.female ///
				|| start_group_num: c_epg_perc || bloc_id3: if sample_amb==1, cov(unstruct) refineopts(iterate(0)) from(as, skip) difficult
		
					est store as_3L_dist_slope
					est save as_3L_dist_slope, replace
					estat icc
					estat ic	
					
					***Table Just 3 level Models
						est use as_3L_dist_slope
						outreg2 using amb_switch4,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word							
						est use as_3L_quad_slope
						outreg2 using amb_switch4,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word		
						est use as_3L_full_slope
						outreg2 using amb_switch4,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	

					***Table Combo 2 & 3 Level Models
						est use as_2L_dist
						outreg2 using amb_switch5,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
						est use as_3L_dist
						outreg2 using amb_switch5,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
						est use as_3L_dist_slope
						outreg2 using amb_switch5,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
						
						est use as_2L_quad
						outreg2 using amb_switch5,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
						est use as_3L_quad
						outreg2 using amb_switch5,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
						est use as_3L_quad_slope
						outreg2 using amb_switch5,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word						
											
						est use as_2L_full
						outreg2 using amb_switch5,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
						est use as_3L_full
						outreg2 using amb_switch5,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
						est use as_3L_full_slope
						outreg2 using amb_switch5,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word

						est restore as_3L_full_slope
						margins, predict(mu fixed) at(a2_std2 =(-1(1)7) a1_std2==(-1 7)) vsquish atmeans post 
						marginsplot
						
						est restore as_3L_full
						margins, predict(mu fixed) at(a2_std2 =(-1(1)7) a1_std2==(-1 7)) vsquish atmeans post 
						marginsplot
						
						est restore as_2L_full
						margins, predict(mu fixed) at(a2_raw =(-1(1)7) a1_raw==(-1 7)) vsquish atmeans post 
						marginsplot


						xtmelogit amb_switch ///
						c.a1_raw c.a2_raw ///
						L1.a1_raw L1.a2_raw ///
						c_npd_perc c_epg_perc govt2 ///
						mep_tenure age_martin i.female ///
						|| bloc_id3: if sample_amb==1,  refineopts(iterate(0)) from(as, skip) difficult
						
						margins, predict(mu fixed) at(a2_raw =(0(0.2)1) a1_raw==(0 0.5 1)) vsquish atmeans post 
						marginsplot
						
						xtmelogit amb_switch ///
						c.a1_raw c.a2_raw ///						
						c.a1_raw#c.a1_raw ///
						c.a2_raw#c.a2_raw ///
						L1.a1_raw L1.a2_raw ///
						c_npd_perc c_epg_perc govt2 ///
						mep_tenure age_martin i.female ///
						|| bloc_id3: if sample_amb==1,  refineopts(iterate(0)) from(as, skip) difficult
						est store as_quad_lags_2L
						est save as_quad_lags_2L, replace
						
						gen a1_sq = a1_raw*a1_raw
					
					
					xtmelogit amb_switch ///
						c.a1_raw##c.a2_raw ///						
						c.a1_raw#c.a1_raw ///
						c.a2_raw#c.a2_raw ///
						L1.a1_raw L1.a2_raw ///
						c_npd_perc c_epg_perc govt2 ///
						mep_tenure age_martin i.female ///
						|| bloc_id3: if sample_amb==1,  refineopts(iterate(0)) from(as, skip) difficult

*****************************************************************************************************************					
	***Combined Ambitious Switchers, Indiv + Bloc
		***January 1, fix the start_group_num
	
		log using pp_01012020, text
		
		xtset hoy_id EP
		
		***2 level Models, bloc_id3 == Parlgov + my substitutes for missing
			xtmelogit amb_switch || bloc_id3:
			estat icc
			estat ic
			est store as_base2
			est save as_base2, replace
			
			xtmelogit amb_switch || start_group_num: || bloc_id3:
			estat icc
			estat ic
			est store as_base2
			est save as_base2, replace			
			
			xtmelogit amb_switch ///
			c.a1_std2##c.a2_std2 ///
			c.a1_std2#c.a1_std2 ///
			c.a2_std2#c.a2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| bloc_id3:
			
				generate sample_amb = e(sample)
				est store as_b3_full
				est save as_b3_full, replace
				estat icc
				estat ic
			
				margins, predict() at(a2_std2 =(-1(1)7) a1_std2==(-1 7)) vsquish atmeans post 
				marginsplot
			
				test _b[1._at] = _b[4._at]
				test _b[1._at] = _b[5._at]
				test _b[1._at] = _b[10._at]
				test _b[9._at] = _b[18._at]
				test _b[10._at] = _b[18._at]
				test _b[8._at] = _b[17._at]
			
		
			xtmelogit amb_switch ///
			c.a1_std2 c.a2_std2 ///
			c.a1_std2#c.a1_std2 ///
			c.a2_std2#c.a2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| bloc_id3: if sample_amb==1
			
				est store as_b3_quad
				est save as_b3_quad, replace
				estat icc
				estat ic
				
			xtmelogit amb_switch ///
			c.a1_std2 c.a2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| bloc_id3: if sample_amb==1
			
				est store as_b3_dist
				est save as_b3_dist, replace
				estat icc
				estat ic		
		
				est use as_b3_dist
				outreg2 using amb_switch1,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
				est use as_b3_quad
				outreg2 using amb_switch1,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
				est use as_b3_full
				outreg2 using amb_switch1,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
		
			
		**3 level models, Delegations nested in groups
				logit amb_switch ///
				c.a1_std2##c.a2_std2 ///
				c.a1_std2#c.a1_std2 ///
				c.a2_std2#c.a2_std2 ///
				c_npd_perc c_epg_perc govt2 ///
				mep_tenure age_martin i.female 
				matrix as = e(b)
				
				xtmelogit amb_switch ///
				c.a1_std2##c.a2_std2 ///
				c.a1_std2#c.a1_std2 ///
				c.a2_std2#c.a2_std2 ///
				c_npd_perc c_epg_perc govt2 ///
				mep_tenure age_martin i.female ///
				|| start_group_num: || bloc_id3: if sample_amb==1, refineopts(iterate(0)) from(as, skip) difficult
		
					est store as_b3_3lvl_full
					est save as_b3_3lvl_full, replace
					estat icc
					estat ic
					
				xtmelogit amb_switch ///
				c.a1_std2 c.a2_std2 ///
				c.a1_std2#c.a1_std2 ///
				c.a2_std2#c.a2_std2 ///
				c_npd_perc c_epg_perc govt2 ///
				mep_tenure age_martin i.female ///
				|| start_group_num: || bloc_id3: if sample_amb==1, refineopts(iterate(0)) from(as, skip) difficult
		
					est store as_b3_3lvl_quad
					est save as_b3_3lvl_quad, replace
					estat icc
					estat ic
					
				xtmelogit amb_switch ///
				c.a1_std2 c.a2_std2 ///
				c_npd_perc c_epg_perc govt2 ///
				mep_tenure age_martin i.female ///
				|| start_group_num: || bloc_id3: if sample_amb==1, refineopts(iterate(0)) from(as, skip) difficult
		
					est store as_b3_3lvl_dist
					est save as_b3_3lvl_dist, replace
					estat icc
					estat ic				
				
					est use as_b3_dist
					outreg2 using amb_switch3,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word				
					est use as_b3_3lvl_dist
					outreg2 using amb_switch3,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					
					est use as_b3_quad				
					outreg2 using amb_switch3,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word			
					est use as_b3_3lvl_quad
					outreg2 using amb_switch3,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word		
					
					est use as_b3_full
					outreg2 using amb_switch3,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word								
					est use as_b3_3lvl_full
					outreg2 using amb_switch3,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
					
					
		**3 level models--slopes
				xtmelogit amb_switch ///
				c.a1_std2##c.a2_std2 ///
				c.a1_std2#c.a1_std2 ///
				c.a2_std2#c.a2_std2 ///
				c_npd_perc c_epg_perc govt2 ///
				mep_tenure age_martin i.female ///
				|| start_group_num: c_epg_perc || bloc_id3: if sample_amb==1, refineopts(iterate(0)) from(as, skip) difficult
		
					est store as_b3_3lvl_full2
					est save as_b3_3lvl_full2, replace
					estat icc
					estat ic
					
				xtmelogit amb_switch ///
				c.a1_std2 c.a2_std2 ///
				c.a1_std2#c.a1_std2 ///
				c.a2_std2#c.a2_std2 ///
				c_npd_perc c_epg_perc govt2 ///
				mep_tenure age_martin i.female ///
				|| start_group_num: c_epg_perc || bloc_id3: if sample_amb==1, refineopts(iterate(0)) from(as, skip) difficult
		
					est store as_b3_3lvl_quad2
					est save as_b3_3lvl_quad2, replace
					estat icc
					estat ic
					
				xtmelogit amb_switch ///
				c.a1_std2 c.a2_std2 ///
				c_npd_perc c_epg_perc govt2 ///
				mep_tenure age_martin i.female ///
				|| start_group_num: c_epg_perc || bloc_id3: if sample_amb==1, refineopts(iterate(0)) from(as, skip) difficult
		
					est store as_b3_3lvl_dist2
					est save as_b3_3lvl_dist2, replace
					estat icc
					estat ic	

*********************************************************************************
	***Individual Ambitious switchers
	
		xtset hoy_id EP
		
		xtmelogit amb_switch_indiv || bloc_id3:
		estat icc
		estat ic
		est store asi_base2
		est save asi_base2, replace
		
		xtmelogit amb_switch_indiv || start_group_num: || bloc_id3:
		estat icc
		estat ic
		est store asi_base3
		est save asi_base3, replace

			xtmelogit amb_switch_indiv ///
			c.a1_std2##c.a2_std2 ///
			c.a1_std2#c.a1_std2 ///
			c.a2_std2#c.a2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| bloc_id3:
			
				generate sample_amb_indiv = e(sample)
				est store asi_b3_full
				est save asi_b3_full, replace
				estat icc
				estat ic
			
				margins, predict() at(a2_std2 =(-1(1)7) a1_std2==(-1 7)) vsquish atmeans post 
				marginsplot
			
				test _b[1._at] = _b[4._at]
				test _b[1._at] = _b[5._at]
				test _b[1._at] = _b[10._at]
				test _b[9._at] = _b[18._at]
				test _b[10._at] = _b[18._at]
				test _b[8._at] = _b[17._at]
			
		
			xtmelogit amb_switch_indiv ///
			c.a1_std2 c.a2_std2 ///
			c.a1_std2#c.a1_std2 ///
			c.a2_std2#c.a2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| bloc_id3: if sample_amb_indiv==1
			
				est store asi_b3_quad
				est save asi_b3_quad, replace
				estat icc
				estat ic
				
			xtmelogit amb_switch_indiv ///
			c.a1_std2 c.a2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| bloc_id3: if sample_amb_indiv==1
			
				est store asi_b3_dist
				est save asi_b3_dist, replace
				estat icc
				estat ic		
		
				est use asi_b3_dist
				outreg2 using amb_switch_indiv1,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
				est use asi_b3_quad
				outreg2 using amb_switch_indiv1,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
				est use asi_b3_full
				outreg2 using amb_switch_indiv1,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
		
		
	**3 level models
		*Preliminary Logit model to generate starting points
		logit amb_switch_indiv ///
		c.a1_std2##c.a2_std2 ///
		c.a1_std2#c.a1_std2 ///
		c.a2_std2#c.a2_std2 ///
		c_npd_perc c_epg_perc govt2 ///
		mep_tenure age_martin i.female
		matrix asi = e(b)	
	
			xtmelogit amb_switch_indiv ///
			c.a1_std2##c.a2_std2 ///
			c.a1_std2#c.a1_std2 ///
			c.a2_std2#c.a2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| start_group_num: || bloc_id3: if sample_amb_indiv==1, refineopts(iterate(0)) from(asi, skip) difficult
	
				est store asi_b3_3lvl_full
				est save asi_b3_3lvl_full, replace
				estat icc
				estat ic
				
			xtmelogit amb_switch_indiv ///
			c.a1_std2 c.a2_std2 ///
			c.a1_std2#c.a1_std2 ///
			c.a2_std2#c.a2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| start_group_num: || bloc_id3: if sample_amb_indiv==1, refineopts(iterate(0)) from(asi, skip) difficult
	
				est store asi_b3_3lvl_quad
				est save asi_b3_3lvl_quad, replace
				estat icc
				estat ic
				
			xtmelogit amb_switch_indiv ///
			c.a1_std2 c.a2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| start_group_num: || bloc_id3: if sample_amb_indiv==1, refineopts(iterate(0)) from(asi, skip) difficult
	
				est store asi_b3_3lvl_dist
				est save asi_b3_3lvl_dist, replace
				estat icc
				estat ic				
			
				est use asi_b3_dist
				outreg2 using amb_switch_indiv2,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word				
				est use asi_b3_3lvl_dist
				outreg2 using amb_switch_indiv2,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
				
				est use asi_b3_quad				
				outreg2 using amb_switch_indiv2,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word			
				est use asi_b3_3lvl_quad
				outreg2 using amb_switch_indiv2,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word		
				
				est use asi_b3_full
				outreg2 using amb_switch_indiv2,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word								
				est use asi_b3_3lvl_full
				outreg2 using amb_switch_indiv2,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
				
				
	**3 level models--slopes
		**Main Models
			xtmelogit amb_switch_indiv ///
			c.a1_std2##c.a2_std2 ///
			c.a1_std2#c.a1_std2 ///
			c.a2_std2#c.a2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| start_group_num: c_epg_perc || bloc_id3: if sample_amb_indiv==1, refineopts(iterate(0)) from(asi, skip) difficult
	
				est store asi_b3_3lvl_full2
				est save asi_b3_3lvl_full2, replace
				estat icc
				estat ic
				est restore asi_b3_3lvl_full2				
					
			xtmelogit amb_switch_indiv ///
			c.a1_std2 c.a2_std2 ///
			c.a1_std2#c.a1_std2 ///
			c.a2_std2#c.a2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| start_group_num: c_epg_perc || bloc_id3: if sample_amb_indiv==1, refineopts(iterate(0)) from(asi, skip) difficult
	
				est store asi_b3_3lvl_quad2
				est save asi_b3_3lvl_quad2, replace
				estat icc
				estat ic
				
			xtmelogit amb_switch_indiv ///
			c.a1_std2 c.a2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| start_group_num: c_epg_perc || bloc_id3: if sample_amb_indiv==1, refineopts(iterate(0)) from(asi, skip) difficult
	
				est store asi_b3_3lvl_dist2
				est save asi_b3_3lvl_dist2, replace
				estat icc
				estat ic	
					
********************************************************************************
	***Amnitious Bloc Switchers			
	
		xtmelogit amb_switch_bloc || start_group_num:
		estat icc
		estat ic
		est store asb_base2
		est save asb_base2, replace			
		
			xtmelogit amb_switch_bloc ///
			c.c1_std2##c.c2_std2 ///
			c.c1_std2#c.c1_std2 ///
			c.c2_std2#c.c2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| start_group_num:
			
				generate sample_amb_bloc = e(sample)
				est store asb_b3_full
				est save asb_b3_full, replace
				estat icc
				estat ic
			
				margins, predict() at(c2_std2 =(-1(1)7) c1_std2==(-1 7)) vsquish atmeans post 
				marginsplot
			
				test _b[1._at] = _b[4._at]
				test _b[1._at] = _b[5._at]
				test _b[1._at] = _b[10._at]
				test _b[9._at] = _b[18._at]
				test _b[10._at] = _b[18._at]
				test _b[8._at] = _b[17._at]
			
		
			xtmelogit amb_switch_bloc ///
			c.c1_std2 c.c2_std2 ///
			c.c1_std2#c.c1_std2 ///
			c.c2_std2#c.c2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| start_group_num: if sample_amb_bloc==1
			
				est store asb_b3_quad
				est save asb_b3_quad, replace
				estat icc
				estat ic
				
			xtmelogit amb_switch_bloc ///
			c.c1_std2 c.c2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| start_group_num: if sample_amb_bloc==1
			
				est store asb_b3_dist
				est save asb_b3_dist, replace
				estat icc
				estat ic		
		
				est use asb_b3_dist
				outreg2 using amb_switch_bloc1,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
				est use asb_b3_quad
				outreg2 using amb_switch_bloc1,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
				est use asb_b3_full
				outreg2 using amb_switch_bloc1,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
		
				
	**2 level models--slopes
			logit amb_switch_bloc ///
			c.c1_std2 c.c2_std2 ///
			c.c1_std2#c.c1_std2 ///
			c.c2_std2#c.c2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female
			matrix xx = e(b)
						
			xtmelogit amb_switch_bloc ///
			c.c1_std2##c.c2_std2 ///
			c.c1_std2#c.c1_std2 ///
			c.c2_std2#c.c2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| start_group_num: c_epg_perc  if sample_amb_bloc==1, refineopts(iterate(0)) from(xx, skip) difficult 
	
				est store asb_b3_3lvl_full2
				est save asb_b3_3lvl_full2, replace
				estat icc
				estat ic
				est restore asb_b3_3lvl_full2
			
			xtmelogit amb_switch_bloc ///
			c.c1_std2 c.c2_std2 ///
			c.c1_std2#c.c1_std2 ///
			c.c2_std2#c.c2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| start_group_num: c_epg_perc  if sample_amb_bloc==1, refineopts(iterate(0)) from(xx, skip) difficult 
	
				est store asb_b3_3lvl_quad2
				est save asb_b3_3lvl_quad2, replace
				estat icc
				estat ic
				
			xtmelogit amb_switch_bloc ///
			c.c1_std2 c.c2_std2 ///
			c_npd_perc c_epg_perc govt2 ///
			mep_tenure age_martin i.female ///
			|| start_group_num: c_epg_perc  if sample_amb_bloc==1, refineopts(iterate(0)) from(xx, skip) difficult 
	
				est store asb_b3_2lvl_dist2
				est save asb_b3_2lvl_dist2, replace
				estat icc
				estat ic
				
				est restore asb_b3_2lvl_dist2
				outreg2 using asb_b3_2lvl_dist3,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
				est restore asb_b3_3lvl_quad2
				outreg2 using asb_b3_2lvl_dist3,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
				est restore asb_b3_3lvl_full2
				outreg2 using asb_b3_2lvl_dist3,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word		
			
			log close		
			
			
	*********ordered logit
	
	xtset hoy_id EP
	
	**Switches per session per MEP
	ologit  switch_count_ses mep_tenure age_martin i.female i.EP, vce(cluster hoy_id)	 
	est store ses_count_base
	est save ses_count_base, replace	
	estat ic
	
	ologit  switch_count_ses  c_npd_perc c_epg_perc mep_tenure age_martin i.female i.EP, vce(cluster hoy_id)	 
	est store ses_count_no_collapse
	est save ses_count_no_collapse, replace	
	estat ic
	
	ologit  switch_count_ses c.a1_std2 c.a2_std2  c_npd_perc c_epg_perc mep_tenure age_martin i.female i.EP, vce(cluster hoy_id)	 
	est store ses_count_distance
	est save ses_count_distance, replace	
	estat ic
	
	ologit  switch_count_ses collapse c.a1_std2 c.a2_std2 c_npd_perc c_epg_perc mep_tenure age_martin i.female i.EP, vce(cluster hoy_id)	 
	est store ses_count_full
	est save ses_count_full, replace
	estat ic

				est use ses_count_base
				outreg2 using switch_count_ses,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
				est use ses_count_no_collapse
				outreg2 using switch_count_ses,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
				est use ses_count_distance
				outreg2 using switch_count_ses,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word				
				est use ses_count_full
				outreg2 using switch_count_ses,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
	
	***Pooled Career Switches
		ologit  switch_count_total	mep_tenure age_martin i.female i.EP, vce(cluster hoy_id)	 
		est store tot_count_base
		est save tot_count_base, replace	
		estat ic
		
		ologit  switch_count_total	c_npd_perc c_epg_perc mep_tenure age_martin i.female i.EP, vce(cluster hoy_id)	 
		est store tot_count_no_collapse
		est save tot_count_no_collapse, replace	
		estat ic
		
		ologit  switch_count_total	c.a1_std2 c.a2_std2   c_npd_perc c_epg_perc mep_tenure age_martin i.female i.EP, vce(cluster hoy_id)	 
		est store tot_count_distance
		est save tot_count_distance, replace	
		estat ic
		
		ologit  switch_count_total	collapse c.a1_std2 c.a2_std2  c_npd_perc c_epg_perc mep_tenure age_martin i.female i.EP, vce(cluster hoy_id)	 
		est store tot_count_full
		est save tot_count_full, replace
		estat ic

		
					est use tot_count_base
					outreg2 using switch_count_total,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use tot_count_no_collapse
					outreg2 using switch_count_total,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
					est use tot_count_distance
					outreg2 using switch_count_total,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
					est use tot_count_full
					outreg2 using switch_count_total,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
		
		
	
	
	ologit  switch_count_total collapse c_npd_perc c_epg_perc mep_tenure age_martin i.female i.EP, vce(cluster hoy_id)
	 
	reg  switch_count_ses collapse c_npd_perc c_epg_perc mep_tenure age_martin i.female i.EP, vce(cluster hoy_id)
	reg  switch_count_total collapse c_npd_perc c_epg_perc mep_tenure age_martin i.female i.EP, vce(cluster hoy_id)
	 
	 xtologit  switch_count_ses collapse c_npd_perc c_epg_perc mep_tenure age_martin i.female i.EP
	 
	 
 ***Negative Binomial
	 
	 xtset hoy_id EP
	
	**Switches per session per MEP
	xtnbreg  switch_count_ses mep_tenure age_martin i.female i.EP,  exposure(daysinoffice) difficult 
	est store ses_count_base_nb
	est save ses_count_base_nb, replace	
	estat ic
	
	xtnbreg  switch_count_ses  c_npd_perc c_epg_perc mep_tenure age_martin i.female i.EP, exposure(daysinoffice) difficult 
	est store ses_count_no_collapse_nb
	est save ses_count_no_collapse_nb, replace	
	estat ic
	
	xtnbreg  switch_count_ses c.a1_std2 c.a2_std2  c_npd_perc c_epg_perc mep_tenure age_martin i.female i.EP,  exposure(daysinoffice) difficult 
	est store ses_count_distance_nb
	est save ses_count_distance_nb, replace	
	estat ic
	
	
		nbreg switch_count_ses collapse  c_npd_perc c_epg_perc mep_tenure age_martin i.female daysinoffice
		matrix nbreg = e(b)
		
		menbreg switch_count_ses collapse c_npd_perc c_epg_perc mep_tenure age_martin i.female  ///
		|| start_group_num: , difficult
		matrix menbreg = e(b)
		
		xtnbreg  switch_count_ses collapse c.a1_std2 c.a2_std2 c_npd_perc c_epg_perc mep_tenure age_martin i.female i.EP,  ///
		exposure(daysinoffice) from(menbreg, skip) difficult 
		est store ses_count_full_nb
		est save ses_count_full_nb, replace
		estat ic

					
			
	***Mixed Effects Poisson
		xtset hoy_id EP
		*hist switch_count_ses
		
		mepoisson  switch_count_ses mep_tenure age_martin i.female ///
		|| start_group_num: || bloc_id3: ,  difficult vce(robust)
		est store ses_count_base_mep
		est save ses_count_base_mep, replace			
		estat ic
		
		mepoisson  switch_count_ses c_npd_perc c_epg_perc mep_tenure age_martin i.female ///
		|| start_group_num: || bloc_id3: ,  difficult vce(robust)
		est store ses_count_no_collpse_mep
		est save ses_count_no_collapse_mep, replace			
		estat ic
		
		 mepoisson  switch_count_ses  c.a1_std2 c.a2_std2 c_npd_perc c_epg_perc mep_tenure age_martin i.female ///
		|| start_group_num: || bloc_id3: ,  difficult vce(robust)
		est store ses_count_distance_mep
		est save ses_count_distance_mep, replace	
		estat ic
		
		mepoisson  switch_count_ses collapse c_npd_perc c_epg_perc mep_tenure age_martin i.female  ///
		|| start_group_num: || bloc_id3: ,  difficult vce(robust)
		est store ses_count_co_no_dist_mep
		est save ses_count_co_no_dist_mep, replace
		estat ic
				
		mepoisson  switch_count_ses collapse c.a1_std2 c.a2_std2 c_npd_perc c_epg_perc mep_tenure age_martin i.female  ///
		|| start_group_num: || bloc_id3: ,  difficult vce(robust)
		est store ses_count_full_mep
		est save ses_count_full_mep, replace
		estat ic
		
					est use ses_count_base_mep
					outreg2 using switch_count_ses_mep,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use ses_count_no_collapse_mep
					outreg2 using switch_count_ses_mep,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
					est use ses_count_distance_mep
					outreg2 using switch_count_ses_mep,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word						
					est use ses_count_co_no_dist_mep
					outreg2 using switch_count_ses_mep,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
					est use ses_count_full_mep
					outreg2 using switch_count_ses_mep,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					
			
	
		***Examine positive sign on epg power var
		
		sort EP start_group collapse 
		list hoy_id EP ms start_group_ses-group4_ses switch_date1-switch_date3 c_epg_perc switch_count_ses collapse ftr dissolve merger if multiswitch==1 & c_epg_perc > 0.1
		
		
		
		
		
		