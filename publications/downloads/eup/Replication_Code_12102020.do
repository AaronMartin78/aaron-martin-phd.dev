
	clear all
	log using replication_log.log, replace  	
	
	***December 10, 2020

	**Replication Code
	
	**Please load two .dta files into your working directory.
	**The first one is called "McElroy_replication_data.dta". You will only need this to run Appendix B, the McElroy replication models.
	**Everything else builds off of "EUP_replication_dataset_12092020.dta"
	**If both of these are saved to your working directory, then the code should run without an issue.

		***Figure 1. Theoretical Relationships Between Strategic Switching, Weak Institutionalization and Group Collapse
		**Not replicable

		***Table 1. Group Collapse
			* There is no table or list function that will allow anyone to call up all of the numbers in this table simultaneously. 
			* Because some MEPs affiliate with multiple groups during the course of a single session, it is necessary to calculate all variable by each group-session.
			* Lines 40 to 1937 replicate all of the steps to create the group-level variables, such as seat share & effective number of parties
			* There are lines of code to sort and list the appropriate variables which will allow you to see how I made this table. It involved, in many cases, simply counting occurrences of events.
			* For example, if you sort by switch_date, you can see how many MEPs switched before a group collapse occurred (pre-collapse switches).
			* I built this table, row by row, and as far as I know, there is no way to do it differently because the numbers change when MEPs switch groups. 
			* This is why the numbers are based on ALL members or delegations who affiliated during the course of a term, and not simply those who started the term in the group.

		***Table 2. Comparison of Means between Collapsing and Non-Collapsing Groups
			**~Lines 2279 to 2363

		***Table 3. Dependent Variables
			***~Lines 2082-2087

		***Figure 2. DW-Nominate Scores	
			***~Lines 2363-2395
			
		***Table 4. Pooled Logistic Regression with a Penalized Maximum-Likelihood Estimator
			***~Lines 2395-2582
			
		***To replicate, users must first download several Stata programs including:
			*ssc install firthlogit
			*ssc install firthfit
			*ssc install bigtab
***************************************************************************************************************************************
	
*** Begin Replication Here
	
	use EUP_replication_dataset_12092020, clear		
		
		gen enp = 0
		gen enp3 = 0
		gen term_share= 0
		replace term_share = tenure_raw2 if tenure_raw2 >=1		
		gen npd_percent = 0
		
		***TABLE 1		
		**Concentration	& ENP		
					
				***CDI
					sort EP ms bloc_id
					
					gen cdi_check = 0
					replace cdi_check = 1 if start_group_ses =="CDI" | start_group == "CDI"  | group1_ses =="CDI"   | group2_ses =="CDI" | group3_ses =="CDI"
										
					bysort EP cdi_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if cdi_check==1
					bysort EP cdi_check bloc_id: gen yy = _N
					bysort EP cdi_check tag: gen yy2 = _N if tag==1				
					bysort EP cdi_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3
										
					bysort EP cdi_check: gen zz = [(yy/xx)*100]^2
					bysort EP cdi_check: egen cc =sum(zz) if tag==1 
					bysort EP cdi_check: egen cc2 = max(cc) 
					replace concentration = cc2 if EP==1 & cdi_check==1		
					
					bysort EP cdi_check: gen cc3 = (1/cc)*10000
					bysort EP cdi_check: egen cc4 = max(cc3) 
					replace enp = cc4 if cdi_check==1							
					
					bysort EP cdi_check: gen p = (yy/xx) if tag==1
					bysort EP cdi_check: gen p2 = p*p if tag==1
					bysort EP cdi_check: egen sump2 = sum(p2) if tag==1
					bysort EP cdi_check: gen q = 1/sump2 
					bysort EP cdi_check: egen enp2 = max(q) 
					bysort EP: replace enp3 = enp2 if cdi_check==1	
					
					gen seatshare_check = xx/session_total_members if cdi_check==1 & EP==1
					replace epg_perc = seatshare_check if cdi_check==1 & EP==1
					replace npd_per_epg = yy2 if cdi_check==1 & EP==1
					bysort EP cdi_check: replace npd_percent = (yy/xx) if cdi_check==1
					
						sort bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days xx tag yy yy2 zz cc cc2 cc3 cc4 seatshare_check enp enp2 enp3 npd_percent ///
						if cdi_check==1, compress
						
						sort EP bloc_id2
						list EP start_group epg_perc npd_per_epg term_share enp epg_tag ///
						if cdi_check==1, compress
						
				***Lagged FTR Variables for T-TEsts
					
					***EPG Days
					gen ld = 0
					replace ld = epg_days if cdi_check==1 & EP==1
					egen max_ld = max(ld) if cdi_check==1
					gen ftr_epg_days = max_ld if cdi_check==1
					
					***EPG Term Share
					gen lts = 0
					replace lts = tenure_raw2 if cdi_check==1 & EP==1
					egen max_lts = max(lts) if cdi_check==1
					gen ftr_epg_ts = max_lts if cdi_check==1					
					
					**Seat Share
					gen ls = 0
					replace ls = epg_perc if cdi_check==1 & EP==1
					egen max_ls = max(ls) if cdi_check==1
					gen ftr_epg_perc = max_ls if cdi_check==1
					
					**NPDs per EPG_leader
					gen ln = 0
					replace ln =  npd_per_epg if cdi_check==1 & EP==1
					egen max_ln  = max(ln) if cdi_check==1							
					gen ftr_npds = max_ln if cdi_check==1
					
					**Concentration
					gen lc = 0
					replace lc = concentration if cdi_check==1 & EP==1
					egen max_lc = max(lc) if cdi_check==1
					gen ftr_concent = max_lc if cdi_check==1
					
					** Lagged ENP
					gen lenp = 0
					replace lenp = enp if cdi_check==1 & EP==1
					egen max_lenp = max(lenp) if cdi_check==1
					gen ftr_enp = max_lenp if cdi_check==1
					
					list EP start_group start_group_num bloc_id cdi_check epg_members epg_perc npd_per_epg term_share tenure_raw2 lts ftr_epg_ts ls ftr_epg_perc ln ftr_npds lenp ftr_enp ftr ///
					if cdi_check==1, compress		
				
					list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"
					sort hoy_id EP start_group end_group bloc_id	
*********************************************************************************************
								
				***DEP
					drop xx-cc4 p-enp2 ld max_ld lts max_lts ls max_ls ln max_ln lc max_lc lenp max_lenp seatshare_check			
					
					gen dep_check = 0
					replace dep_check = 1 if start_group_ses =="DEP" | start_group == "DEP"  | group1_ses =="DEP"   | group2_ses =="DEP" | group3_ses =="DEP"	
					
					bysort EP dep_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if dep_check==1
					bysort EP dep_check bloc_id: gen yy = _N
					bysort EP dep_check tag: gen yy2 = _N if tag==1				
					bysort EP dep_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3								
										
					bysort EP dep_check: gen zz = [(yy/xx)*100]^2
					bysort EP dep_check: egen cc =sum(zz) if tag==1 
					bysort EP dep_check: egen cc2 = max(cc) 
					replace concentration = cc2 if EP==1 & dep_check==1		
					
					bysort EP dep_check: gen cc3 = (1/cc)*10000
					bysort EP dep_check: egen cc4 = max(cc3) 
					replace enp = cc4 if dep_check==1							
					
					bysort EP dep_check: gen p = (yy/xx) if tag==1
					bysort EP dep_check: gen p2 = p*p if tag==1
					bysort EP dep_check: egen sump2 = sum(p2) if tag==1
					bysort EP dep_check: gen q = 1/sump2 
					bysort EP dep_check: egen enp2 = max(q) 
					bysort EP: replace enp3 = enp2 if dep_check==1	
					
					gen seatshare_check = xx/session_total_members if dep_check==1 & EP==1
					replace epg_perc = seatshare_check if dep_check==1 & EP==1
					replace npd_per_epg = 5 if dep_check==1 & EP==1
					bysort EP dep_check: replace npd_percent = (yy/xx) if dep_check==1
				
						sort EP tag bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days xx tag yy yy2 zz cc cc2 cc3 cc4 seatshare_check enp enp2 enp3 npd_percent ///
						if dep_check==1, compress
						
				***Lagged FTR Variables for T-Tests
					
					***EPG Days
					gen ld = 0
					replace ld = epg_days if dep_check==1 & EP==1
					egen max_ld = max(ld) if dep_check==1
					replace ftr_epg_days = max_ld if dep_check==1
					
					***EPG Term Share
					gen lts = 0
					replace lts = tenure_raw2 if dep_check==1 & EP==1
					egen max_lts = max(lts) if dep_check==1
					replace ftr_epg_ts = max_lts if dep_check==1					
					
					**Seat Share
					gen ls = 0
					replace ls = epg_perc if dep_check==1 & EP==1
					egen max_ls = max(ls) if dep_check==1
					replace ftr_epg_perc = max_ls if dep_check==1
					
					**NPDs per EPG_leader
					gen ln = 0
					replace ln =  npd_per_epg if dep_check==1 & EP==1
					egen max_ln  = max(ln) if dep_check==1							
					replace ftr_npds = max_ln if dep_check==1
					
					**Concentration
					gen lc = 0
					replace lc = concentration if dep_check==1 & EP==1
					egen max_lc = max(lc) if dep_check==1
					replace ftr_concent = max_lc if dep_check==1
					
					** Lagged ENP
					gen lenp = 0
					replace lenp = enp if dep_check==1 & EP==1
					egen max_lenp = max(lenp) if dep_check==1
					replace ftr_enp = max_lenp if dep_check==1
					
					list EP start_group start_group_num bloc_id dep_check epg_members epg_perc npd_per_epg term_share tenure_raw2 lts ftr_epg_ts ls ftr_epg_perc ln ftr_npds lenp ftr_enp ftr ///
					if dep_check==1, compress
					
						sort EP bloc_id2
						list EP start_group epg_perc npd_per_epg yy2 term_share enp tag nationalparty epg_tag  ///
						if dep_check==1, compress
					
					list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"
					sort hoy_id EP start_group end_group bloc_id	
*********************************************************************************************
				***TCDI
					drop xx-cc4 p-enp2 ld max_ld lts max_lts ls max_ls ln max_ln lc max_lc lenp max_lenp seatshare_check							
					drop tcdi_check
					gen tcdi_check = 0
					replace tcdi_check = 1 if start_group_ses =="TCDI" | start_group == "TCDI"  | group1_ses =="TCDI"   | group2_ses =="TCDI" | group3_ses =="TCDI"		
					
					replace term_share = (tcdi_days/max_EP2_days) if tcdi_check==1
					
					bysort EP tcdi_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if tcdi_check==1
					bysort EP tcdi_check bloc_id: gen yy = _N
					bysort EP tcdi_check tag: gen yy2 = _N if tag==1				
					bysort EP tcdi_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3								
										
					bysort EP tcdi_check: gen zz = [(yy/xx)*100]^2
					bysort EP tcdi_check: egen cc =sum(zz) if tag==1 
					bysort EP tcdi_check: egen cc2 = max(cc) 
					replace concentration = cc2 if tcdi_check==1		
					
					bysort EP tcdi_check: gen cc3 = (1/cc)*10000
					bysort EP tcdi_check: egen cc4 = max(cc3) 
					replace enp = cc4 if tcdi_check==1							
					
					bysort EP tcdi_check: gen p = (yy/xx) if tag==1
					bysort EP tcdi_check: gen p2 = p*p if tag==1
					bysort EP tcdi_check: egen sump2 = sum(p2) if tag==1
					bysort EP tcdi_check: gen q = 1/sump2 
					bysort EP tcdi_check: egen enp2 = max(q) 
					bysort EP: replace enp3 = enp2 if tcdi_check==1	
					
					gen seatshare_check = xx/session_total_members if tcdi_check==1 & EP==2
					replace epg_perc = seatshare_check if tcdi_check==1 & EP==2
					replace npd_per_epg = 6 if tcdi_check==1 & EP==2
					bysort EP tcdi_check: replace npd_percent = (yy/xx) if tcdi_check==1
					
						sort EP tag bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days xx tag yy yy2 zz cc cc2 cc3 cc4 seatshare_check enp enp2 enp3 tag npd_percent ///
						if tcdi_check==1, compress															
						
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg epg_days term_share tag ///
						if tcdi_check==1, compress
						
						list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"
						sort hoy_id EP start_group end_group bloc_id	
*********************************************************************************************				
									
				***COM
					drop xx-cc4 p-enp2 seatshare_check						
					gen com_check = 0
					replace com_check = 1 if start_group_ses =="COM" | start_group == "COM"  | group1_ses =="COM"   | group2_ses =="COM" | group3_ses =="COM"		
					replace nationalparty = "Socialistisk folkeparti" if EP==3 & hoy_id==1277
					
					bysort EP com_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if com_check==1
					bysort EP com_check bloc_id: gen yy = _N
					bysort EP com_check tag: gen yy2 = _N if tag==1				
					bysort EP com_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3					
										
					bysort EP com_check: gen zz = [(yy/xx)*100]^2
					bysort EP com_check: egen cc =sum(zz) if tag==1 
					bysort EP com_check: egen cc2 = max(cc) 
					replace concentration = cc2 if com_check==1		
					
					bysort EP com_check: gen cc3 = (1/cc)*10000
					bysort EP com_check: egen cc4 = max(cc3) 
					replace enp = cc4 if com_check==1							
					
					bysort EP com_check: gen p = (yy/xx) if tag==1
					bysort EP com_check: gen p2 = p*p if tag==1
					bysort EP com_check: egen sump2 = sum(p2) if tag==1
					bysort EP com_check: gen q = 1/sump2 
					bysort EP com_check: egen enp2 = max(q) 
					bysort EP: replace enp3 = enp2 if com_check==1	
					
					gen seatshare_check = xx/session_total_members if com_check==1 
					replace epg_perc = seatshare_check if com_check==1 
					replace epg_members = xx if com_check ==1
					replace npd_per_epg = yy2 if com_check==1 
					bysort EP com_check: replace npd_percent = (yy/xx) if com_check==1
					
						sort EP tag bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days concentration xx tag yy yy2 zz cc cc2 cc3 cc4 seatshare_check enp npd_percent term_share ///
						if com_check==1, compress	
						
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg epg_days tag ///
						if com_check==1, compress	
						
					***Lagged FTR Variables for T-TEsts
					
					***EPG Days
					gen ld = 0
					replace ld = epg_days if com_check==1 & EP==2
					egen max_ld = max(ld) if com_check==1
					replace ftr_epg_days = max_ld if com_check==1
					
					***EPG Term Share
					gen lts = 0
					replace lts = tenure_raw2 if com_check==1 & EP==2
					egen max_lts = max(lts) if com_check==1
					replace ftr_epg_ts = max_lts if com_check==1					
					
					**Seat Share
					gen ls = 0
					replace ls = epg_perc if com_check==1 & EP==2
					egen max_ls = max(ls) if com_check==1
					replace ftr_epg_perc = max_ls if com_check==1
					
					**NPDs per EPG_leader
					gen ln = 0
					replace ln =  npd_per_epg if com_check==1 & EP==2
					egen max_ln  = max(ln) if com_check==1							
					replace ftr_npds = max_ln if com_check==1
					
					**Concentration
					gen lc = 0
					replace lc = concentration if com_check==1 & EP==2
					egen max_lc = max(lc) if com_check==1
					replace ftr_concent = max_lc if com_check==1
					
					** Lagged ENP
					gen lenp = 0
					replace lenp = enp if com_check==1 & EP==2
					egen max_lenp = max(lenp) if com_check==1
					replace ftr_enp = max_lenp if com_check==1
					
					list EP start_group start_group_num bloc_id com_check epg_members epg_perc npd_per_epg term_share tenure_raw2 lts ftr_epg_ts ls ftr_epg_perc ln ftr_npds lenp ftr_enp ftr ///
					if com_check==1, compress
					
						sort EP bloc_id2
						list EP start_group epg_perc npd_per_epg yy2 term_share enp tag nationalparty epg_tag  ///
						if com_check==1, compress
						
						list EP epg_perc npd_per_epg term_share enp if com_check==1 & epg_tag==1
					
					list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"					
					sort hoy_id EP start_group end_group bloc_id
*********************************************************************************************										
				***ED
					drop xx-cc4 p-enp2 seatshare_check	
					drop ld max_ld lts max_lts ls max_ls ln max_ln lc max_lc lenp max_lenp 	
					
					drop ed_check
					gen ed_check = 0
					replace ed_check = 1 if start_group_ses =="ED" | start_group == "ED"  | group1_ses =="ED"   | group2_ses =="ED" | group3_ses =="ED"	
					replace bloc_id = 240 if bloc_id==253 & EP==3 & ed_check==1
					
					gen ed_days = 0
					replace ed_days = switch_date1 - start_date_ses if ed_check==1
					replace term_share = 2 + (ed_days/max_EP3_days) if ed_check==1 & EP==3					
				
					replace epg_tag = 1 if EP==1 & start_group == "ED" & hoy_id==765
					replace epg_tag = 0 if EP==2 & ed_check==1 & hoy_id ==1651 & epg_tag==1
					
					bysort EP ed_check: gen xx = _N 
					replace xx =34 if EP==3 & ed_check==1
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if ed_check==1
					replace tag = 0 if bloc_id==240 & EP==3 & ed_check==1
					bysort EP ed_check bloc_id: gen yy = _N
					bysort EP ed_check tag: gen yy2 = _N if tag==1				
					bysort EP ed_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3						
					replace yy2 = 2 if EP==3 & ed_check==1					
					
					bysort EP ed_check: gen zz = [(yy/xx)*100]^2
					bysort EP ed_check: egen cc =sum(zz) if tag==1 
					bysort EP ed_check: egen cc2 = max(cc) 
					replace concentration = cc2 if ed_check==1		
					
					bysort EP ed_check: gen cc3 = (1/cc)*10000
					bysort EP ed_check: egen cc4 = max(cc3) 
					replace enp = cc4 if ed_check==1							
					
					bysort EP ed_check: gen p = (yy/xx) if tag==1
					bysort EP ed_check: gen p2 = p*p if tag==1
					bysort EP ed_check: egen sump2 = sum(p2) if tag==1
					bysort EP ed_check: gen q = 1/sump2 
					bysort EP ed_check: egen enp2 = max(q) 
					bysort EP: replace enp3 = enp2 if ed_check==1	
					
					gen seatshare_check = xx/session_total_members if ed_check==1 
					replace epg_perc = seatshare_check if ed_check==1 
					replace epg_members = xx if ed_check ==1
					replace npd_per_epg = yy2 if ed_check==1 
					replace term_share = 2.5558 if ed_check==1 & EP==3 & epg_tag==1
					bysort EP ed_check: replace npd_percent = (yy/xx) if ed_check==1
					
						sort bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days concentration xx tag yy yy2 zz cc cc2 cc3 cc4 ///
						seatshare_check enp enp2 enp3 term_share tag epg_tag ///
						if ed_check==1, compress	
						
						sort bloc_id
						list EP start_group epg_members epg_perc npd_per_epg epg_days bloc_id nationalparty tag switch_date1-switch_date2 xx tag yy yy2 zz cc cc2 cc3 cc4 ///
						seatshare_check enp  ///
						if ed_check==1, compress	
						
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg epg_days tag ///
						if ed_check==1, compress			
						
						list EP epg_perc npd_per_epg term_share enp if ed_check==1 & epg_tag==1						
					
						list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"			
						sort hoy_id EP start_group end_group bloc_id
*********************************************************************************************																
				***GUE		
					drop xx-cc4 p-enp2 seatshare_check	
					drop gue_check
					gen gue_check = 0
					replace gue_check = 1 if start_group_ses =="GUE" | start_group == "GUE"  | group1_ses =="GUE"   | group2_ses =="GUE" | group3_ses =="GUE"		
					replace epg_tag = 1 if gue_check==1 & EP==3 & hoy_id==947				
					
					bysort EP gue_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if gue_check==1
					bysort EP gue_check bloc_id: gen yy = _N
					bysort EP gue_check tag: gen yy2 = _N if tag==1				
					bysort EP gue_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3								
										
					bysort EP gue_check: gen zz = [(yy/xx)*100]^2
					bysort EP gue_check: egen cc =sum(zz) if tag==1 
					bysort EP gue_check: egen cc2 = max(cc) 
					replace concentration = cc2 if gue_check==1		
					
					bysort EP gue_check: gen cc3 = (1/cc)*10000
					bysort EP gue_check: egen cc4 = max(cc3) 
					replace enp = cc4 if gue_check==1							
					
					bysort EP gue_check: gen p = (yy/xx) if tag==1
					bysort EP gue_check: gen p2 = p*p if tag==1
					bysort EP gue_check: egen sump2 = sum(p2) if tag==1
					bysort EP gue_check: gen q = 1/sump2 
					bysort EP gue_check: egen enp2 = max(q) 
					bysort EP: replace enp3 = enp2 if gue_check==1	
					
					gen seatshare_check = xx/session_total_members if gue_check==1 
					replace epg_perc = seatshare_check if gue_check==1 
					replace epg_members = xx if gue_check ==1
					replace npd_per_epg = yy2 if gue_check==1 
					bysort EP gue_check: replace npd_percent = (yy/xx) if gue_check==1
						
						sort bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days concentration xx tag yy yy2 zz cc cc2 cc3 cc4 seatshare_check enp enp2 enp3 term_share ///
						if gue_check==1, compress	
						
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg epg_days tag ///
						if gue_check==1, compress	
						
							***Days in office for mid-session collapse
							sort EP start_date_ses
							list EP start_group start_group_num bloc_id ms start_date_ses end_date_ses switch_date1-switch_date4 ///
							if start_group_ses =="GUE" | start_group == "GUE" | group1_ses =="GUE"  | group2_ses =="GUE"  | group3_ses =="GUE", compress		
							
							gen marker = 1 if gue_check==1 & switch_date2 != .
							gen mm = switch_date2 - start_date_ses if marker ==1
							egen mmm = max(mm) if gue_check==1 & EP==3
							replace epg_days = mmm if gue_check==1 & EP==3
							drop marker-mmm		
							
							gen gue_days = 0
							replace gue_days = switch_date2 - start_date_ses if gue_check==1
							replace term_share = (epg_days/max_EP3_days) if gue_check==1 & EP==3
							
							list EP start_group start_group_num bloc_id parlgov switch_date1-switch_date2 npd_per_epg concentration epg_days gue_days tenure_raw2 term_share  ///
							if gue_check==1, compress		
							
							sort EP  bloc_id
							list EP start_group_ses-end_group_ses start_date_ses  switch_date1-switch_date4  end_date_ses bloc_id tag nationalparty ///
							if start_group_ses =="GUE" | start_group == "GUE" | group1_ses =="GUE"  | group2_ses =="GUE"  | group3_ses =="GUE", compress		
										
							list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg enp term_share tag ///
							if gue_check==1, compress	
							
							sort EP
							list EP epg_perc npd_per_epg term_share enp if gue_check==1 & epg_tag==1						
											
							list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"		
							sort hoy_id EP start_group end_group bloc_id
*********************************************************************************************	
											
				***CG
					drop xx-cc4 p-enp2 seatshare_check	
					gen cg_check = 0
					replace cg_check = 1 if start_group_ses =="CG" | start_group == "CG"  | group1_ses =="CG"   | group2_ses =="CG" | group3_ses =="CG"		
					
					bysort EP cg_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if cg_check==1
					bysort EP cg_check bloc_id: gen yy = _N
					bysort EP cg_check tag: gen yy2 = _N if tag==1				
					bysort EP cg_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3									
										
					bysort EP cg_check: gen zz = [(yy/xx)*100]^2
					bysort EP cg_check: egen cc =sum(zz) if tag==1 
					bysort EP cg_check: egen cc2 = max(cc) 
					replace concentration = cc2 if cg_check==1		
					
					bysort EP cg_check: gen cc3 = (1/cc)*10000
					bysort EP cg_check: egen cc4 = max(cc3) 
					replace enp = cc4 if cg_check==1							
					
					bysort EP cg_check: gen p = (yy/xx) if tag==1
					bysort EP cg_check: gen p2 = p*p if tag==1
					bysort EP cg_check: egen sump2 = sum(p2) if tag==1
					bysort EP cg_check: gen q = 1/sump2 
					bysort EP cg_check: egen enp2 = max(q) 
					bysort EP: replace enp3 = enp2 if cg_check==1	
					
					gen seatshare_check = xx/session_total_members if cg_check==1 
					replace epg_perc = seatshare_check if cg_check==1 
					replace epg_members = xx if cg_check ==1
					replace npd_per_epg = yy2 if cg_check==1 
					bysort EP cg_check: replace npd_percent = (yy/xx) if cg_check==1
					
						sort bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days concentration xx tag yy yy2 zz cc cc2 cc3 cc4 seatshare_check enp enp2 enp3 term_share ///
						if cg_check==1, compress	
						
						sort EP end_date_ses bloc_id
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg enp term_share bloc_id tag  switch_date1-switch_date4  start_date_ses end_date_ses ///
						if cg_check==1, compress	
						
					***Lagged FTR Variables for T-TEsts
					
					***EPG Days
					gen ld = 0
					replace ld = epg_days if cg_check==1 & EP==3
					egen max_ld = max(ld) if cg_check==1
					replace ftr_epg_days = max_ld if cg_check==1
					
					***EPG Term Share
					gen lts = 0
					replace lts = tenure_raw2 if cg_check==1 & EP==3
					egen max_lts = max(lts) if cg_check==1
					replace ftr_epg_ts = max_lts if cg_check==1					
					
					**Seat Share
					gen ls = 0
					replace ls = epg_perc if cg_check==1 & EP==3
					egen max_ls = max(ls) if cg_check==1
					replace ftr_epg_perc = max_ls if cg_check==1
					
					**NPDs per EPG_leader
					gen ln = 0
					replace ln =  npd_per_epg if cg_check==1 & EP==3
					egen max_ln  = max(ln) if cg_check==1							
					replace ftr_npds = max_ln if cg_check==1
					
					**Concentration
					gen lc = 0
					replace lc = concentration if cg_check==1 & EP==3
					egen max_lc = max(lc) if cg_check==1
					replace ftr_concent = max_lc if cg_check==1
					
					** Lagged ENP
					gen lenp = 0
					replace lenp = enp if cg_check==1 & EP==3
					egen max_lenp = max(lenp) if cg_check==1
					replace ftr_enp = max_lenp if cg_check==1
					
					list EP start_group start_group_num bloc_id cg_check epg_members epg_perc npd_per_epg term_share tenure_raw2 lts ftr_epg_ts ls ftr_epg_perc ln ftr_npds lenp ftr_enp ftr ///
					if cg_check==1, compress			
					
					sort EP
					list EP epg_perc npd_per_epg term_share enp if cg_check==1 & epg_tag==1		
					
					list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"
					sort hoy_id EP start_group end_group bloc_id		
*************************************************************									
				***DR
					drop xx-cc4 p-enp2 seatshare_check	
					drop ld max_ld lts max_lts ls max_ls ln max_ln lc max_lc lenp max_lenp 					
					gen dr_check = 0
					replace dr_check = 1 if start_group_ses =="DR" | start_group == "DR"  | group1_ses =="DR"   | group2_ses =="DR" | group3_ses =="DR"		
					
					bysort EP dr_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if dr_check==1
					bysort EP dr_check bloc_id: gen yy = _N
					bysort EP dr_check tag: gen yy2 = _N if tag==1				
					bysort EP dr_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3										
										
					bysort EP dr_check: gen zz = [(yy/xx)*100]^2
					bysort EP dr_check: egen cc =sum(zz) if tag==1 
					bysort EP dr_check: egen cc2 = max(cc) 
					replace concentration = cc2 if dr_check==1		
					
					bysort EP dr_check: gen cc3 = (1/cc)*10000
					bysort EP dr_check: egen cc4 = max(cc3) 
					replace enp = cc4 if dr_check==1							
					
					bysort EP dr_check: gen p = (yy/xx) if tag==1
					bysort EP dr_check: gen p2 = p*p if tag==1
					bysort EP dr_check: egen sump2 = sum(p2) if tag==1
					bysort EP dr_check: gen q = 1/sump2 
					bysort EP dr_check: egen enp2 = max(q) 
					bysort EP: replace enp3 = enp2 if dr_check==1	
					
					gen seatshare_check = xx/session_total_members if dr_check==1 
					replace epg_perc = seatshare_check if dr_check==1 
					replace epg_members = xx if dr_check ==1
					replace npd_per_epg = yy2 if dr_check==1 
					bysort EP dr_check: replace npd_percent = (yy/xx) if dr_check==1
					
						sort bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days concentration xx tag yy yy2 zz cc cc2 cc3 cc4 seatshare_check enp enp2 enp3 term_share ///
						if dr_check==1, compress	
						
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg epg_days enp tag epg_tag ///
						if dr_check==1, compress	
						
					***Lagged FTR Variables for T-TEsts
					
					***EPG Days
					gen ld = 0
					replace ld = epg_days if dr_check==1 & EP==3
					egen max_ld = max(ld) if dr_check==1
					replace ftr_epg_days = max_ld if dr_check==1
					
					***EPG Term Share
					gen lts = 0
					replace lts = tenure_raw2 if dr_check==1 & EP==3
					egen max_lts = max(lts) if dr_check==1
					replace ftr_epg_ts = max_lts if dr_check==1					
					
					**Seat Share
					gen ls = 0
					replace ls = epg_perc if dr_check==1 & EP==3
					egen max_ls = max(ls) if dr_check==1
					replace ftr_epg_perc = max_ls if dr_check==1
					
					**NPDs per EPG_leader
					gen ln = 0
					replace ln =  npd_per_epg if dr_check==1 & EP==3
					egen max_ln  = max(ln) if dr_check==1							
					replace ftr_npds = max_ln if dr_check==1
					
					**Concentration
					gen lc = 0
					replace lc = concentration if dr_check==1 & EP==3
					egen max_lc = max(lc) if dr_check==1
					replace ftr_concent = max_lc if dr_check==1
					
					** Lagged ENP
					gen lenp = 0
					replace lenp = enp if dr_check==1 & EP==3
					egen max_lenp = max(lenp) if dr_check==1
					replace ftr_enp = max_lenp if dr_check==1
					
					list EP start_group start_group_num bloc_id dr_check epg_members epg_perc npd_per_epg term_share tenure_raw2 lts ftr_epg_ts ls ftr_epg_perc ln ftr_npds lenp ftr_enp ftr ///
					if dr_check==1, compress		
					
					sort EP end_date_ses bloc_id
					list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg enp term_share bloc_id tag  switch_date1-switch_date4  start_date_ses end_date_ses ///
					if dr_check==1, compress	
					
					list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"	
					sort hoy_id EP start_group end_group bloc_id
*********************************************************************************************	
				***FE
					drop xx-cc4 p-enp2 seatshare_check	
					drop ld max_ld lts max_lts ls max_ls ln max_ln lc max_lc lenp max_lenp 
					drop fe_check
					gen fe_check = 0
					replace fe_check = 1 if start_group_ses =="FE" | start_group == "FE"  | group1_ses =="FE"   | group2_ses =="FE" | group3_ses =="FE"		
					replace bloc_id = 373 if bloc_id == 372 & EP==4 & ms=="IT" & end_group_ses== "EPP"
					replace bloc_id = 373 if bloc_id == 395 & EP==4 & ms=="IT" & end_group_ses== "EPP"
					
						gen fe_days = 0
						replace fe_days = switch_date1 - start_date_ses if fe_check==1 & start_group_ses== "FE"
						replace term_share = (fe_days/max_EP4_days) if fe_check==1 & EP==4
						replace term_share = 0.1922234 if fe_check== 1 & EP==4 & term_share==0
						
						list EP start_group start_group_num bloc_id parlgov switch_date1-switch_date2 npd_per_epg concentration epg_days fe_days tenure_raw2 term_share  ///
						if fe_check==1, compress	
						
					bysort EP fe_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if fe_check==1
					bysort EP fe_check bloc_id: gen yy = _N
					bysort EP fe_check tag: gen yy2 = _N if tag==1				
					bysort EP fe_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3										
										
					bysort EP fe_check: gen zz = [(yy/xx)*100]^2
					bysort EP fe_check: egen cc =sum(zz) if tag==1 
					bysort EP fe_check: egen cc2 = max(cc) 
					replace concentration = cc2 if fe_check==1		
					
					bysort EP fe_check: gen cc3 = (1/cc)*10000
					bysort EP fe_check: egen cc4 = max(cc3) 
					replace enp = cc4 if fe_check==1							
					
					bysort EP fe_check: gen p = (yy/xx) if tag==1
					bysort EP fe_check: gen p2 = p*p if tag==1
					bysort EP fe_check: egen sump2 = sum(p2) if tag==1
					bysort EP fe_check: gen q = 1/sump2 
					bysort EP fe_check: egen enp2 = max(q) 
					bysort EP: replace enp3 = enp2 if fe_check==1	
					
					gen seatshare_check = xx/session_total_members if fe_check==1 
					replace epg_perc = seatshare_check if fe_check==1 
					replace epg_members = xx if fe_check ==1
					replace npd_per_epg = yy2 if fe_check==1 
					bysort EP fe_check: replace npd_percent = (yy/xx) if fe_check==1
					
						sort bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days concentration xx tag yy yy2 zz cc cc2 cc3 cc4 seatshare_check enp enp2 enp3 term_share ///
						if fe_check==1, compress	
						
						sort bloc_id
						list EP start_group epg_members epg_perc npd_per_epg epg_days bloc_id nationalparty tag switch_date1-switch_date2 xx tag yy yy2 zz cc cc2 cc3 cc4 ///
						seatshare_check enp  ///
						if fe_check==1, compress	
						
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg epg_days enp tag epg_tag ///
						if fe_check==1, compress	
						
						sort EP end_date_ses bloc_id
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg enp term_share bloc_id tag  switch_date1-switch_date4  start_date_ses end_date_ses ///
						if fe_check==1, compress	
						
						list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"	
						sort hoy_id EP start_group end_group bloc_id
*********************************************************************************************		
				***RBW
					drop xx-cc4 p-enp2 seatshare_check	
					
					*drop rbw_check
					gen rbw_check = 0
					replace rbw_check = 1 if start_group_ses =="RBW" | start_group == "RBW"  | group1_ses =="RBW"   | group2_ses =="RBW" | group3_ses =="RBW"		
					replace rbw_check = 0 if rbw_check==1 & EP==3 & group1_ses =="V" & group2_ses =="."
					
					bysort EP rbw_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if rbw_check==1
					bysort EP rbw_check bloc_id: gen yy = _N
					bysort EP rbw_check tag: gen yy2 = _N if tag==1				
					bysort EP rbw_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3									
										
					bysort EP rbw_check: gen zz = [(yy/xx)*100]^2
					bysort EP rbw_check: egen cc =sum(zz) if tag==1 
					bysort EP rbw_check: egen cc2 = max(cc) 
					replace concentration = cc2 if rbw_check==1		
					
					bysort EP rbw_check: gen cc3 = (1/cc)*10000
					bysort EP rbw_check: egen cc4 = max(cc3) 
					replace enp = cc4 if rbw_check==1							
					
					bysort EP rbw_check: gen p = (yy/xx) if tag==1
					bysort EP rbw_check: gen p2 = p*p if tag==1
					bysort EP rbw_check: egen sump2 = sum(p2) if tag==1
					bysort EP rbw_check: gen q = 1/sump2 
					bysort EP rbw_check: egen enp2 = max(q) 
					bysort EP: replace enp3 = enp2 if rbw_check==1	
					
					gen seatshare_check = xx/session_total_members if rbw_check==1 
					replace epg_perc = seatshare_check if rbw_check==1 
					replace epg_members = xx if rbw_check ==1
					replace npd_per_epg = yy2 if rbw_check==1 
					bysort EP rbw_check: replace npd_percent = (yy/xx) if rbw_check==1
						
						sort bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days concentration xx tag yy yy2 zz cc cc2 cc3 cc4 seatshare_check enp enp2 enp3 term_share ///
						if rbw_check==1, compress	
						
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg epg_days enp term_share tag epg_tag ///
						if rbw_check==1, compress	
						
					***Lagged FTR Variables for T-TEsts
					
					***EPG Days
					gen ld = 0
					replace ld = epg_days if rbw_check==1 & EP==3
					egen max_ld = max(ld) if rbw_check==1
					replace ftr_epg_days = max_ld if rbw_check==1
					
					***EPG Term Share
					gen lts = 0
					replace lts = tenure_raw2 if rbw_check==1 & EP==3
					egen max_lts = max(lts) if rbw_check==1
					replace ftr_epg_ts = max_lts if rbw_check==1					
					
					**Seat Share
					gen ls = 0
					replace ls = epg_perc if rbw_check==1 & EP==3
					egen max_ls = max(ls) if rbw_check==1
					replace ftr_epg_perc = max_ls if rbw_check==1
					
					**NPDs per EPG_leader
					gen ln = 0
					replace ln =  npd_per_epg if rbw_check==1 & EP==3
					egen max_ln  = max(ln) if rbw_check==1							
					replace ftr_npds = max_ln if rbw_check==1
					
					**Concentration
					gen lc = 0
					replace lc = concentration if rbw_check==1 & EP==3
					egen max_lc = max(lc) if rbw_check==1
					replace ftr_concent = max_lc if rbw_check==1
					
					** Lagged ENP
					gen lenp = 0
					replace lenp = enp if rbw_check==1 & EP==3
					egen max_lenp = max(lenp) if rbw_check==1
					replace ftr_enp = max_lenp if rbw_check==1
					
					list EP start_group start_group_num bloc_id rbw_check epg_members epg_perc npd_per_epg term_share tenure_raw2 lts ftr_epg_ts ls ftr_epg_perc ln ftr_npds lenp ftr_enp ftr ///
					if rbw_check==1, compress	
					
						sort EP end_date_ses bloc_id
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg enp term_share bloc_id tag  switch_date1-switch_date4  start_date_ses end_date_ses ///
						if rbw_check==1, compress
						
						sort EP switch_date1 bloc_id
						list EP nationalparty bloc_id start_group_ses-end_group_ses epg_perc npd_per_epg enp term_share bloc_id tag switch_date1-switch_date4 end_date_ses ///
						if rbw_check==1 & EP==3, compress
					
					list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"			
					sort hoy_id EP start_group end_group bloc_id
*********************************************************************************************	
				***UPE
					drop xx-cc4 p-enp2 seatshare_check	
					drop ld max_ld lts max_lts ls max_ls ln max_ln lc max_lc lenp max_lenp 
					
					gen upe_check = 0
					replace upe_check = 1 if start_group_ses =="UPE" | start_group == "UPE"  | group1_ses =="UPE"   | group2_ses =="UPE" | group3_ses =="UPE"	
					replace bloc_id = 372 if bloc_id==395 & EP==4 & nationalparty =="Centro cristiano democratico"
					replace bloc_id = 375 if bloc_id==379 & EP==4 & parlgov==658
					replace bloc_id = 377 if bloc_id==380 & EP==4 & parlgov==251
									
						***Days in office for mid-session collapse
							gen marker = 1 if upe_check==1 & group2_ses =="."  & end_group_ses == "UPE"
							gen mm = end_date_ses - switch_date1 if upe_check ==1
							*egen mmm = max(mm) if upe_check==1 & EP==4
							replace epg_days = mm if upe_check==1 & EP==4 & end_group_ses == "UPE"
							
							sort EP start_date_ses end_group_ses
							list EP start_group start_group_ses-end_group_ses start_group_num bloc_id ms start_date_ses switch_date1-switch_date4 end_date_ses  epg_days marker mm ///
							if start_group_ses =="UPE" | start_group == "UPE" | group1_ses =="UPE"  | group2_ses =="UPE"  | group3_ses =="UPE", compress		
							
									gen upe_days2 = 0
									replace term_share = 0 if upe_check==1
									replace upe_days2 = switch_date2 - switch_date1 if upe_check==1 & EP==4
									replace upe_days2 = end_date_ses- switch_date1 if upe_check==1 & EP==4 & switch_date2==.
									replace term_share = (upe_days2/max_EP4_days) if upe_check==1 & EP==4 & term_share==0		
									replace term_share = 0.8077766 if upe_check==1
									
									sort EP bloc_id tag
									list EP start_group_ses-end_group_ses start_group_num bloc_id tag switch_date1-switch_date2 npd_per_epg concentration epg_days upe_days2 tenure_raw2 term_share  ///
									if upe_check==1, compress		
									
					bysort EP upe_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if upe_check==1
					bysort EP upe_check bloc_id: gen yy = _N
					bysort EP upe_check tag: gen yy2 = _N if tag==1				
					bysort EP upe_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3									
										
					bysort EP upe_check: gen zz = [(yy/xx)*100]^2
					bysort EP upe_check: egen cc =sum(zz) if tag==1 
					bysort EP upe_check: egen cc2 = max(cc) 
					replace concentration = cc2 if upe_check==1		
					
					bysort EP upe_check: gen cc3 = (1/cc)*10000
					bysort EP upe_check: egen cc4 = max(cc3) 
					replace enp = cc4 if upe_check==1							
					
					bysort EP upe_check: gen p = (yy/xx) if tag==1
					bysort EP upe_check: gen p2 = p*p if tag==1
					bysort EP upe_check: egen sump2 = sum(p2) if tag==1
					bysort EP upe_check: gen q = 1/sump2 
					bysort EP upe_check: egen enp2 = max(q) 
					bysort EP: replace enp3 = enp2 if upe_check==1	
					
					gen seatshare_check = xx/session_total_members if upe_check==1 
					replace epg_perc = seatshare_check if upe_check==1 
					replace epg_members = xx if upe_check ==1
					replace npd_per_epg = yy2 if upe_check==1 
					bysort EP upe_check: replace npd_percent = (yy/xx) if upe_check==1
					
						sort bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days concentration xx tag yy yy2 zz cc cc2 cc3 cc4 seatshare_check enp enp2 enp3 term_share ///
						if upe_check==1, compress	
						
						list EP start_group start_group_num start_group_ses-end_group_ses  bloc_id epg_members epg_perc npd_per_epg epg_days enp term_share tag epg_tag bloc_id  ///
						if upe_check==1, compress	
						
					***Lagged FTR Variables for T-TEsts
					
					***EPG Days
					gen ld = 0
					replace ld = epg_days if upe_check==1 & EP==4
					egen max_ld = max(ld) if upe_check==1
					replace ftr_epg_days = max_ld if upe_check==1
					
					***EPG Term Share
					gen lts = 0
					replace lts = tenure_raw2 if upe_check==1 & EP==4
					egen max_lts = max(lts) if upe_check==1
					replace ftr_epg_ts = max_lts if upe_check==1					
					
					**Seat Share
					gen ls = 0
					replace ls = epg_perc if upe_check==1 & EP==4
					egen max_ls = max(ls) if upe_check==1
					replace ftr_epg_perc = max_ls if upe_check==1
					
					**NPDs per EPG_leader
					gen ln = 0
					replace ln =  npd_per_epg if upe_check==1 & EP==4
					egen max_ln  = max(ln) if upe_check==1							
					replace ftr_npds = max_ln if upe_check==1
					
					**Concentration
					gen lc = 0
					replace lc = concentration if upe_check==1 & EP==4
					egen max_lc = max(lc) if upe_check==1
					replace ftr_concent = max_lc if upe_check==1
					
					** Lagged ENP
					gen lenp = 0
					replace lenp = enp if upe_check==1 & EP==4
					egen max_lenp = max(lenp) if upe_check==1
					replace ftr_enp = max_lenp if upe_check==1
					
					list EP start_group start_group_num bloc_id upe_check epg_members epg_perc npd_per_epg term_share tenure_raw2 lts ftr_epg_ts ls ftr_epg_perc ln ftr_npds lenp ftr_enp ftr ///
					if upe_check==1, compress	
					
						sort EP end_date_ses bloc_id
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg enp term_share bloc_id tag  switch_date1-switch_date4  start_date_ses end_date_ses ///
						if upe_check==1, compress
				
					list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"		
					sort hoy_id EP start_group end_group bloc_id
*********************************************************************************************				
				
				***RDE
					drop xx-cc4 p-enp2 seatshare_check	
					drop ld max_ld lts max_lts ls max_ls ln max_ln lc max_lc lenp max_lenp 
					drop rde_check
					gen rde_check = 0
					replace rde_check = 1 if start_group_ses =="RDE" | start_group == "RDE"  | group1_ses =="RDE"   | group2_ses =="RDE" | group3_ses =="RDE"	
					
							gen rde_days2 = 0
							replace rde_days2 = switch_date1 - start_date_ses if rde_check==1 & EP==4
							replace term_share = 2 + (rde_days2/max_EP4_days) if rde_check==1 & EP==4
											
							list EP start_group start_group_num bloc_id parlgov switch_date1-switch_date2 npd_per_epg concentration epg_days rde_days2 tenure_raw2 term_share  ///
							if rde_check==1, compress	
					
					bysort EP rde_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if rde_check==1
					bysort EP rde_check bloc_id: gen yy = _N
					bysort EP rde_check tag: gen yy2 = _N if tag==1				
					bysort EP rde_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3										
										
					bysort EP rde_check: gen zz = [(yy/xx)*100]^2
					bysort EP rde_check: egen cc =sum(zz) if tag==1 
					bysort EP rde_check: egen cc2 = max(cc) 
					replace concentration = cc2 if rde_check==1		
					
					bysort EP rde_check: gen cc3 = (1/cc)*10000
					bysort EP rde_check: egen cc4 = max(cc3) 
					replace enp = cc4 if rde_check==1							
					
					bysort EP rde_check: gen p = (yy/xx) if tag==1
					bysort EP rde_check: gen p2 = p*p if tag==1
					bysort EP rde_check: egen sump2 = sum(p2) if tag==1
					bysort EP rde_check: gen q = 1/sump2 
					bysort EP rde_check: egen enp2 = max(q) 
					bysort EP: replace enp3 = enp2 if rde_check==1	
					
					gen seatshare_check = xx/session_total_members if rde_check==1 
					replace epg_perc = seatshare_check if rde_check==1 
					replace epg_members = xx if rde_check ==1
					replace npd_per_epg = yy2 if rde_check==1 
					bysort EP rde_check: replace npd_percent = (yy/xx) if rde_check==1
					
						sort bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days concentration xx tag yy yy2 zz cc cc2 cc3 cc4 seatshare_check enp enp2 enp3 term_share ///
						if rde_check==1, compress	
						
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg epg_days enp term_share tag epg_tag ///
						if rde_check==1, compress
						
						sort bloc_id
						list EP start_group epg_members epg_perc npd_per_epg epg_days bloc_id nationalparty tag switch_date1-switch_date2 xx tag yy yy2 zz cc cc2 cc3 cc4 ///
						seatshare_check enp  ///
						if rde_check==1, compress	
						
								replace term_share =  0.8077766 if start_group == "UPE" & EP==4 & epg_tag==1
								replace npd_per_epg = 11 if  start_group == "UPE" & EP==4 & epg_tag==1
								replace epg_perc = 0.0864198 if  start_group == "UPE" & EP==4 & epg_tag==1
								replace enp = 3.864654 if start_group == "UPE" & EP==4 & epg_tag==1
								sort EP start_group
								list EP start_group enp term_share npd_per_epg epg_perc epg_tag hoy_id if epg_tag==1 & start_group != "NI"		
								
						sort EP end_date_ses bloc_id
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg enp term_share bloc_id tag  switch_date1-switch_date4  start_date_ses end_date_ses ///
						if rde_check==1, compress
					
						list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"	
						sort hoy_id EP start_group end_group bloc_id
*********************************************************************************************	
			
				**EDN
					drop xx-cc4 p-enp2 seatshare_check					
					drop edn_check
					gen edn_check = 0
					replace edn_check = 1 if start_group_ses =="UEN-CG" | start_group == "UEN-CG"  | group1_ses =="UEN-CG"   | group2_ses =="UEN-CG" | group3_ses =="UEN-CG"
							
							gen edn_days = 0
							replace edn_days = switch_date1 - start_date_ses if edn_check==1 & EP==4 & start_group_ses=="UEN-CG"
							replace term_share = (edn_days/max_EP4_days) if edn_check==1 & EP==4
							replace term_share = 0.4633078 if edn_check==1 & term_share != 0.4633078
							
							list EP start_group_ses-end_group_ses start_group_num bloc_id parlgov switch_date1-switch_date2 npd_per_epg concentration epg_days edn_days tenure_raw2 term_share  ///
							if edn_check==1, compress		
					
					bysort EP edn_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if edn_check==1
					bysort EP edn_check bloc_id: gen yy = _N
					bysort EP edn_check tag: gen yy2 = _N if tag==1				
					bysort EP edn_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3									
										
					bysort EP edn_check: gen zz = [(yy/xx)*100]^2
					bysort EP edn_check: egen cc =sum(zz) if tag==1 
					bysort EP edn_check: egen cc2 = max(cc) 
					replace concentration = cc2 if edn_check==1		
					
					bysort EP edn_check: gen cc3 = (1/cc)*10000
					bysort EP edn_check: egen cc4 = max(cc3) 
					replace enp = cc4 if edn_check==1							
					
					bysort EP edn_check: gen p = (yy/xx) if tag==1
					bysort EP edn_check: gen p2 = p*p if tag==1
					bysort EP edn_check: egen sump2 = sum(p2) if tag==1
					bysort EP edn_check: gen q = 1/sump2 
					bysort EP edn_check: egen enp2 = max(q) 
					bysort EP: replace enp3 = enp2 if edn_check==1	
					
					gen seatshare_check = xx/session_total_members if edn_check==1 
					replace epg_perc = seatshare_check if edn_check==1 
					replace epg_members = xx if edn_check ==1
					replace npd_per_epg = yy2 if edn_check==1 
					bysort EP edn_check: replace npd_percent = (yy/xx) if edn_check==1
					
						sort bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days concentration xx tag yy yy2 zz cc cc2 cc3 cc4 seatshare_check enp enp2 enp3 term_share ///
						if edn_check==1, compress	
						
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg epg_days enp term_share tag epg_tag ///
						if edn_check==1, compress								
									
						sort EP start_group_ses 
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg enp term_share bloc_id tag  switch_date1-switch_date4  start_date_ses end_date_ses ///
						if edn_check==1, compress
						
							list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"	
							sort hoy_id EP start_group end_group bloc_id
*********************************************************************************************	
					
			**I-EDN
					drop xx-cc4 p-enp2 seatshare_check				
					
					*drop iedn_check
					gen iedn_check = 0
					replace iedn_check = 1 if start_group_ses =="I-EDN" | start_group == "I-EDN"  | group1_ses =="I-EDN"   | group2_ses =="I-EDN" | group3_ses =="I-EDN"		
				
							gen iedn_days2 = 0
							replace iedn_days2 = end_date_ses - switch_date2 if iedn_check==1 & EP==4 & group2_ses=="I-EDN"
							replace term_share = (iedn_days2/max_EP4_days) if iedn_check==1 & EP==4
							replace term_share = 0.5031906 if term_share != 0.5031906 & EP==4 & iedn_check ==1
														
							list EP start_group_ses-end_group_ses start_group_num bloc_id parlgov switch_date1-switch_date2 npd_per_epg concentration epg_days iedn_days2 tenure_raw2 term_share  ///
							if iedn_check==1, compress		
					
					bysort EP iedn_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if iedn_check==1
					bysort EP iedn_check bloc_id: gen yy = _N
					bysort EP iedn_check tag: gen yy2 = _N if tag==1				
					bysort EP iedn_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3										
										
					bysort EP iedn_check: gen zz = [(yy/xx)*100]^2
					bysort EP iedn_check: egen cc =sum(zz) if tag==1 
					bysort EP iedn_check: egen cc2 = max(cc) 
					replace concentration = cc2 if iedn_check==1		
					
					bysort EP iedn_check: gen cc3 = (1/cc)*10000
					bysort EP iedn_check: egen cc4 = max(cc3) 
					replace enp = cc4 if iedn_check==1							
					
					bysort EP iedn_check: gen p = (yy/xx) if tag==1
					bysort EP iedn_check: gen p2 = p*p if tag==1
					bysort EP iedn_check: egen sump2 = sum(p2) if tag==1
					bysort EP iedn_check: gen q = 1/sump2 
					bysort EP iedn_check: egen enp2 = max(q) 
					bysort EP: replace enp3 = enp2 if iedn_check==1	
					
					gen seatshare_check = xx/session_total_members if iedn_check==1 
					replace epg_perc = seatshare_check if iedn_check==1 
					replace epg_members = xx if iedn_check ==1
					replace npd_per_epg = yy2 if iedn_check==1 
					bysort EP iedn_check: replace npd_percent = (yy/xx) if iedn_check==1
						
						sort bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days concentration xx tag yy yy2 zz cc cc2 cc3 cc4 seatshare_check enp enp2 enp3 term_share ///
						if iedn_check==1, compress	
						
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg epg_days enp term_share tag epg_tag ///
						if iedn_check==1, compress	
						
					***Lagged FTR Variables for T-TEsts
					
					***EPG Days
					gen ld = 0
					replace ld = epg_days if iedn_check==1 & EP==4
					egen max_ld = max(ld) if iedn_check==1
					replace ftr_epg_days = max_ld if iedn_check==1
					
					***EPG Term Share
					gen lts = 0
					replace lts = tenure_raw2 if iedn_check==1 & EP==4
					egen max_lts = max(lts) if iedn_check==1
					replace ftr_epg_ts = max_lts if iedn_check==1					
					
					**Seat Share
					gen ls = 0
					replace ls = epg_perc if iedn_check==1 & EP==4
					egen max_ls = max(ls) if iedn_check==1
					replace ftr_epg_perc = max_ls if iedn_check==1
					
					**NPDs per EPG_leader
					gen ln = 0
					replace ln =  npd_per_epg if iedn_check==1 & EP==4
					egen max_ln  = max(ln) if iedn_check==1							
					replace ftr_npds = max_ln if iedn_check==1
					
					**Concentration
					gen lc = 0
					replace lc = concentration if iedn_check==1 & EP==4
					egen max_lc = max(lc) if iedn_check==1
					replace ftr_concent = max_lc if iedn_check==1
					
					** Lagged ENP
					gen lenp = 0
					replace lenp = enp if iedn_check==1 & EP==4
					egen max_lenp = max(lenp) if iedn_check==1
					replace ftr_enp = max_lenp if iedn_check==1
					
					list EP start_group start_group_num bloc_id iedn_check epg_members epg_perc npd_per_epg term_share tenure_raw2 lts ftr_epg_ts ls ftr_epg_perc ln ftr_npds lenp ftr_enp ftr ///
					if iedn_check==1, compress	
					
						sort EP start_group_ses 
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg enp term_share bloc_id tag  switch_date1-switch_date4  start_date_ses end_date_ses ///
						if iedn_check==1, compress
				
					list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"		
					sort hoy_id EP start_group end_group bloc_id
								
*********************************************************************************************			
				**ARE
					drop xx-cc4 p-enp2 seatshare_check	
					drop ld max_ld lts max_lts ls max_ls ln max_ln lc max_lc lenp max_lenp 					
					*drop are_check
					gen are_check = 0
					replace are_check = 1 if start_group_ses =="ARE" | start_group == "ARE"  | group1_ses =="ARE"   | group2_ses =="ARE" | group3_ses =="ARE"
					replace bloc_id = 440 if bloc_id==433 & EP==5 & are_check==1
						
					bysort EP are_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if are_check==1
					bysort EP are_check bloc_id: gen yy = _N
					bysort EP are_check tag: gen yy2 = _N if tag==1				
					bysort EP are_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3						
										
					bysort EP are_check: gen zz = [(yy/xx)*100]^2
					bysort EP are_check: egen cc =sum(zz) if tag==1 
					bysort EP are_check: egen cc2 = max(cc) 
					replace concentration = cc2 if are_check==1		
					
					bysort EP are_check: gen cc3 = (1/cc)*10000
					bysort EP are_check: egen cc4 = max(cc3) 
					replace enp = cc4 if are_check==1							
					
					bysort EP are_check: gen p = (yy/xx) if tag==1
					bysort EP are_check: gen p2 = p*p if tag==1
					bysort EP are_check: egen sump2 = sum(p2) if tag==1
					bysort EP are_check: gen q = 1/sump2 
					bysort EP are_check: egen enp2 = max(q) 
					bysort EP: replace enp3 = enp2 if are_check==1	
					
					gen seatshare_check = xx/session_total_members if are_check==1 
					replace epg_perc = seatshare_check if are_check==1 
					replace epg_members = xx if are_check ==1
					replace npd_per_epg = yy2 if are_check==1 
					bysort EP are_check: replace npd_percent = (yy/xx) if are_check==1
					
						sort EP tag bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days concentration xx tag yy yy2 zz cc cc2 cc3 cc4 seatshare_check enp term_share npd_percent bloc_id ///
						if are_check==1, compress	
						
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg epg_days enp term_share tag epg_tag ///
						if are_check==1, compress	
						
					***Lagged FTR Variables for T-TEsts
					
					***EPG Days
					gen ld = 0
					replace ld = epg_days if are_check==1 & EP==4
					egen max_ld = max(ld) if are_check==1
					replace ftr_epg_days = max_ld if are_check==1
					
					***EPG Term Share
					gen lts = 0
					replace lts = tenure_raw2 if are_check==1 & EP==4
					egen max_lts = max(lts) if are_check==1
					replace ftr_epg_ts = max_lts if are_check==1					
					
					**Seat Share
					gen ls = 0
					replace ls = epg_perc if are_check==1 & EP==4
					egen max_ls = max(ls) if are_check==1
					replace ftr_epg_perc = max_ls if are_check==1
					
					**NPDs per EPG_leader
					gen ln = 0
					replace ln =  npd_per_epg if are_check==1 & EP==4
					egen max_ln  = max(ln) if are_check==1							
					replace ftr_npds = max_ln if are_check==1
					
					**Concentration
					gen lc = 0
					replace lc = concentration if are_check==1 & EP==4
					egen max_lc = max(lc) if are_check==1
					replace ftr_concent = max_lc if are_check==1
					
					** Lagged ENP
					gen lenp = 0
					replace lenp = enp if are_check==1 & EP==4
					egen max_lenp = max(lenp) if are_check==1
					replace ftr_enp = max_lenp if are_check==1
					
					list EP start_group start_group_num bloc_id are_check epg_members epg_perc npd_per_epg term_share tenure_raw2 lts ftr_epg_ts ls ftr_epg_perc ln ftr_npds lenp ftr_enp ftr ///
					if are_check==1, compress	
					
						sort EP bloc_id
						list EP start_group start_group_num bloc_id  epg_members epg_perc npd_per_epg enp term_share bloc_id tag  switch_date1-switch_date4  national ///
						if are_check==1, compress
						*start_group_ses-end_group_ses
				
					list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"		
					sort hoy_id EP start_group end_group bloc_id
								
*********************************************************************************************	
				
				**TDI
					drop xx-cc4 p-enp2 seatshare_check	
					drop ld max_ld lts max_lts ls max_ls ln max_ln lc max_lc lenp max_lenp 								
					drop tdi_check
					gen tdi_check = 0
					replace tdi_check = 1 if start_group_ses =="TDI" | start_group == "TDI"  | group1_ses =="TDI"   | group2_ses =="TDI" | group3_ses =="TDI"
					
							gen tdi_days2 = 0
							replace tdi_days2 = switch_date2 - switch_date1 if tdi_check==1 & EP==5 
							replace term_share = (tdi_days2/max_EP5_days) if tdi_check==1 & EP==5
							replace term_share = 0.441402 if tdi_check==1 & EP==5
					
					bysort EP tdi_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if tdi_check==1
					bysort EP tdi_check bloc_id: gen yy = _N
					bysort EP tdi_check tag: gen yy2 = _N if tag==1				
					bysort EP tdi_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3									
										
					bysort EP tdi_check: gen zz = [(yy/xx)*100]^2
					bysort EP tdi_check: egen cc =sum(zz) if tag==1 
					bysort EP tdi_check: egen cc2 = max(cc) 
					replace concentration = cc2 if tdi_check==1		
					
					bysort EP tdi_check: gen cc3 = (1/cc)*10000
					bysort EP tdi_check: egen cc4 = max(cc3) 
					replace enp = cc4 if tdi_check==1							
					
					bysort EP tdi_check: gen p = (yy/xx) if tag==1
					bysort EP tdi_check: gen p2 = p*p if tag==1
					bysort EP tdi_check: egen sump2 = sum(p2) if tag==1
					bysort EP tdi_check: gen q = 1/sump2 
					bysort EP tdi_check: egen enp2 = max(q) 
					bysort EP: replace enp3 = enp2 if tdi_check==1	
					
					gen seatshare_check = xx/session_total_members if tdi_check==1 
					replace epg_perc = seatshare_check if tdi_check==1 
					replace epg_members = xx if tdi_check ==1
					replace npd_per_epg = yy2 if tdi_check==1 
					bysort EP tdi_check: replace npd_percent = (yy/xx) if tdi_check==1
					
						sort bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days concentration xx tag yy yy2 zz cc cc2 cc3 cc4 seatshare_check enp enp2 enp3 term_share ///
						if tdi_check==1, compress	
						
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg epg_days enp term_share tag epg_tag ///
						if tdi_check==1, compress	
						
						sort EP bloc_id
						list EP start_group start_group_num bloc_id  epg_members epg_perc npd_per_epg enp term_share bloc_id tag  switch_date1-switch_date4  national ///
						if tdi_check==1, compress
						*start_group_ses-end_group_ses
						
						list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"		
						sort hoy_id EP start_group end_group bloc_id								
															
*************************************************************************************************
						
				***EDD
					drop xx-cc4 p-enp2 seatshare_check					
					*drop edd_check
					gen edd_check = 0
					replace edd_check = 1 if start_group_ses =="EDD" | start_group == "EDD"  | group1_ses =="EDD"   | group2_ses =="EDD" | group3_ses =="EDD"										
											
					bysort EP edd_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if edd_check==1
					bysort EP edd_check bloc_id: gen yy = _N
					bysort EP edd_check tag: gen yy2 = _N if tag==1				
					bysort EP edd_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3								
										
					bysort EP edd_check: gen zz = [(yy/xx)*100]^2
					bysort EP edd_check: egen cc =sum(zz) if tag==1 
					bysort EP edd_check: egen cc2 = max(cc) 
					replace concentration = cc2 if edd_check==1		
					
					bysort EP edd_check: gen cc3 = (1/cc)*10000
					bysort EP edd_check: egen cc4 = max(cc3) 
					replace enp = cc4 if edd_check==1							
					
					bysort EP edd_check: gen p = (yy/xx) if tag==1
					bysort EP edd_check: gen p2 = p*p if tag==1
					bysort EP edd_check: egen sump2 = sum(p2) if tag==1
					bysort EP edd_check: gen q = 1/sump2 
					bysort EP edd_check: egen enp2 = max(q) 
					bysort EP: replace enp3 = enp2 if edd_check==1	
					
					gen seatshare_check = xx/session_total_members if edd_check==1 
					replace epg_perc = seatshare_check if edd_check==1 
					replace epg_members = xx if edd_check ==1
					replace npd_per_epg = yy2 if edd_check==1 
					bysort EP edd_check: replace npd_percent = (yy/xx) if edd_check==1
					
						sort bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days concentration xx tag yy yy2 zz cc cc2 cc3 cc4 seatshare_check enp enp2 enp3 term_share ///
						if edd_check==1, compress	
						
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg epg_days enp term_share tag epg_tag ///
						if edd_check==1, compress	
						replace npd_per_epg = 5 if epg_tag==1 & edd_check==1 & EP==5
						
					***Lagged FTR Variables for T-TEsts
					
					***EPG Days
					gen ld = 0
					replace ld = epg_days if edd_check==1 & EP==5
					egen max_ld = max(ld) if edd_check==1
					replace ftr_epg_days = max_ld if edd_check==1
					
					***EPG Term Share
					gen lts = 0
					replace lts = tenure_raw2 if edd_check==1 & EP==5
					egen max_lts = max(lts) if edd_check==1
					replace ftr_epg_ts = max_lts if edd_check==1					
					
					**Seat Share
					gen ls = 0
					replace ls = epg_perc if edd_check==1 & EP==5
					egen max_ls = max(ls) if edd_check==1
					replace ftr_epg_perc = max_ls if edd_check==1
					
					**NPDs per EPG_leader
					gen ln = 0
					replace ln =  npd_per_epg if edd_check==1 & EP==5 & epg_tag==1
					egen max_ln  = max(ln) if edd_check==1							
					replace ftr_npds = max_ln if edd_check==1
					
					**Concentration
					gen lc = 0
					replace lc = concentration if edd_check==1 & EP==5
					egen max_lc = max(lc) if edd_check==1
					replace ftr_concent = max_lc if edd_check==1
					
					** Lagged ENP
					gen lenp = 0
					replace lenp = enp if edd_check==1 & EP==5
					egen max_lenp = max(lenp) if edd_check==1
					replace ftr_enp = max_lenp if edd_check==1
					
					list EP start_group start_group_num bloc_id edd_check epg_members epg_perc npd_per_epg term_share tenure_raw2 lts ftr_epg_ts ls ftr_epg_perc ln ftr_npds lenp ftr_enp ftr ///
					if edd_check==1, compress	
					
						sort EP bloc_id
						list EP start_group start_group_num bloc_id  epg_members epg_perc npd_per_epg enp term_share bloc_id tag  switch_date1-switch_date4  start_group_ses-end_group_ses ///
						if edd_check==1, compress
						*start_group_ses-end_group_ses
				
					list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"		
					sort hoy_id EP start_group end_group bloc_id
					
*********************************************************************************************		
						
				***ITS
					drop xx-cc4 p-enp2 seatshare_check	
					drop ld max_ld lts max_lts ls max_ls ln max_ln lc max_lc lenp max_lenp 		
					drop its_check
					gen its_check = 0
					replace its_check = 1 if start_group_ses =="ITS" | start_group == "ITS"  | group1_ses =="ITS"   | group2_ses =="ITS" | group3_ses =="ITS"	
					replace bloc_id = 746 if bloc_id==762 & EP==6 & its_check==1
				
							gen its_days2 = 0
							replace its_days2 = switch_date2 - switch_date1 if its_check==1 & EP==6
							replace term_share = (its_days2/max_EP6_days) if its_check==1 & EP==6		
							replace term_share = 0.166575  if its_check==1 & EP==6
					
					bysort EP its_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if its_check==1
					bysort EP its_check bloc_id: gen yy = _N
					bysort EP its_check tag: gen yy2 = _N if tag==1				
					bysort EP its_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3
					
					bysort EP its_check: gen zz = [(yy/xx)*100]^2
					bysort EP its_check: egen cc =sum(zz) if tag==1 
					bysort EP its_check: egen cc2 = max(cc) 
					replace concentration = cc2 if its_check==1		
					
					bysort EP its_check: gen cc3 = (1/cc)*10000
					bysort EP its_check: egen cc4 = max(cc3) 
					replace enp = cc4 if its_check==1							
					
					bysort EP its_check: gen p = (yy/xx) if tag==1
					bysort EP its_check: gen p2 = p*p if tag==1
					bysort EP its_check: egen sump2 = sum(p2) if tag==1
					bysort EP its_check: gen q = 1/sump2 
					bysort EP its_check: egen enp2 = max(q) 
					bysort EP: replace enp3 = enp2 if its_check==1	
					
					gen seatshare_check = xx/session_total_members if its_check==1 
					replace epg_perc = seatshare_check if its_check==1 
					replace epg_members = xx if its_check ==1
					replace npd_per_epg = yy2 if its_check==1 
					bysort EP its_check: replace npd_percent = (yy/xx) if its_check==1
					
						sort bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days concentration xx tag yy yy2 zz cc cc2 cc3 cc4 seatshare_check enp enp2 enp3 term_share tag epg_tag ///
						if its_check==1, compress	
						
						list EP start_group start_group_ses-end_group_ses bloc_id nationalparty epg_members epg_perc npd_per_epg epg_days enp term_share tag epg_tag switch_date1-switch_date2 ///
						if its_check==1 , compress	
						
						sort EP bloc_id
						list EP start_group start_group_num bloc_id  epg_members epg_perc npd_per_epg enp term_share bloc_id tag  switch_date1-switch_date4 nationalparty ///
						if its_check==1, compress
						*start_group_ses-end_group_ses
					
						list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"		
						sort hoy_id EP start_group end_group bloc_id
					
*********************************************************************************************		

				***UEN
					drop xx-cc4 p-enp2 seatshare_check	
					gen uen_check = 0
					replace uen_check = 1 if start_group_ses =="UEN" | start_group == "UEN"  | group1_ses =="UEN"   | group2_ses =="UEN" | group3_ses =="UEN"	
					replace bloc_id =742 if bloc_id==765 & EP==6 & uen_check==1
					replace bloc_id =732 if bloc_id==766 & EP==6 & uen_check==1
					replace bloc_id =712 if bloc_id==768 & EP==6 & uen_check==1
					
					bysort EP uen_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if uen_check==1
					bysort EP uen_check bloc_id: gen yy = _N
					bysort EP uen_check tag: gen yy2 = _N if tag==1				
					bysort EP uen_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3
					
					bysort EP uen_check: gen zz = [(yy/xx)*100]^2
					bysort EP uen_check: egen cc =sum(zz) if tag==1 
					bysort EP uen_check: egen cc2 = max(cc) 
					replace concentration = cc2 if uen_check==1		
					
					bysort EP uen_check: gen cc3 = (1/cc)*10000
					bysort EP uen_check: egen cc4 = max(cc3) 
					replace enp = cc4 if uen_check==1							
					
					bysort EP uen_check: gen p = (yy/xx) if tag==1
					bysort EP uen_check: gen p2 = p*p if tag==1
					bysort EP uen_check: egen sump2 = sum(p2) if tag==1
					bysort EP uen_check: gen q = 1/sump2 
					bysort EP uen_check: egen enp2 = max(q) 
					bysort EP: replace enp3 = enp2 if uen_check==1	
					
					gen seatshare_check = xx/session_total_members if uen_check==1 
					replace epg_perc = seatshare_check if uen_check==1 
					replace epg_members = xx if uen_check ==1
					replace npd_per_epg = 8 if uen_check==1 & EP==5
					replace npd_per_epg = 19 if uen_check==1 & EP==6
					bysort EP uen_check: replace npd_percent = (yy/xx) if uen_check==1
					
						sort bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days concentration xx tag yy yy2 zz cc cc2 cc3 cc4 seatshare_check enp enp2 enp3 term_share npd_per_epg tag epg_tag ///
						if uen_check==1, compress	
						
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg epg_days enp term_share tag epg_tag ///
						if uen_check==1, compress	
						replace npd_per_epg = 5 if epg_tag==1 & uen_check==1 & EP==5						
						
						list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"		
						sort hoy_id EP start_group end_group bloc_id
					
*********************************************************************************************		
	
				***InDem
					drop xx-cc4 p-enp2 seatshare_check	
					gen indem_check = 0
					replace indem_check = 1 if start_group_ses =="InDem" | start_group == "InDem"  | group1_ses =="InDem"   | group2_ses =="InDem" | group3_ses =="InDem"		
									
					bysort EP indem_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if indem_check==1
					bysort EP indem_check bloc_id: gen yy = _N
					bysort EP indem_check tag: gen yy2 = _N if tag==1				
					bysort EP indem_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3	
					
					bysort EP indem_check: gen zz = [(yy/xx)*100]^2
					bysort EP indem_check: egen cc =sum(zz) if tag==1 
					bysort EP indem_check: egen cc2 = max(cc) 
					replace concentration = cc2 if indem_check==1		
					
					bysort EP indem_check: gen cc3 = (1/cc)*10000
					bysort EP indem_check: egen cc4 = max(cc3) 
					replace enp = cc4 if indem_check==1							
					
					bysort EP indem_check: gen p = (yy/xx) if tag==1
					bysort EP indem_check: gen p2 = p*p if tag==1
					bysort EP indem_check: egen sump2 = sum(p2) if tag==1
					bysort EP indem_check: gen q = 1/sump2 
					bysort EP indem_check: egen enp2 = max(q) 
					bysort EP: replace enp3 = enp2 if indem_check==1	
					
					gen seatshare_check = xx/session_total_members if indem_check==1 
					replace epg_perc = seatshare_check if indem_check==1 
					replace epg_members = xx if indem_check ==1
					replace npd_per_epg = yy2 if indem_check==1 				
					bysort EP indem_check: replace npd_percent = (yy/xx) if indem_check==1
						
						sort bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days concentration xx tag yy yy2 zz cc cc2 cc3 cc4 seatshare_check enp enp2 enp3 term_share npd_per_epg tag epg_tag ///
						if indem_check==1, compress	
						
						list EP start_group start_group_num bloc_id start_group_ses-end_group_ses epg_members epg_perc npd_per_epg epg_days enp term_share tag epg_tag ///
						if indem_check==1, compress	
						replace npd_per_epg = 5 if epg_tag==1 & indem_check==1 & EP==5						
						
						list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"		
						sort hoy_id EP start_group end_group bloc_id
						
*********************************************************************************************
			**NI
					drop xx-cc4 p-enp2 seatshare_check	
					gen ni_check = 0
					replace ni_check = 1 if start_group_ses =="NI" & end_group_ses=="NI"
									
					bysort EP ni_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP bloc_id) if ni_check==1
					bysort EP ni_check bloc_id: gen yy = _N
					bysort EP ni_check tag: gen yy2 = _N if tag==1				
					bysort EP ni_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3	
					
					gen seatshare_check = xx/session_total_members if ni_check==1 
					replace epg_perc = seatshare_check if ni_check==1 
					replace epg_members = xx if ni_check ==1
					replace npd_per_epg = yy2 if ni_check==1 				
					bysort EP ni_check: replace npd_percent = (yy/xx) if ni_check==1
											
						sort EP tag bloc_id
						list EP start_group start_group_num  epg_members epg_perc npd_per_epg epg_days concentration xx tag yy yy2 seatshare_check term_share npd_per_epg npd_percent tag epg_tag ///
						if ni_check==1, compress		
*********************************************************************************************
*********************************************************************************************
							
		***Check Institutionalized groups
						
				***GUE/NGL 
					drop xx-yy2 seatshare_check	
					gen guengl_check = 0
					replace guengl_check = 1 if start_group_ses =="GUE/NGL" | start_group == "GUE/NGL"  | group1_ses =="GUE/NGL"   | group2_ses =="GUE/NGL" | group3_ses =="GUE/NGL"	
					replace bloc_id = 275 if bloc_id==273 & guengl_check==1 & EP==4
					replace bloc_id = 433 if bloc_id==440 & guengl_check==1 & EP==5
					replace bloc_id = 544 if bloc_id==543 & guengl_check==1 & EP==6
							
					bysort EP guengl_check: gen xx = _N 
					sort hoy_id EP start_group end_group bloc_id
					egen tag = tag(EP  bloc_id) if guengl_check==1
					bysort EP guengl_check bloc_id: gen yy = _N
					bysort EP guengl_check tag: gen yy2 = _N if tag==1
					bysort EP guengl_check: egen yy3=max(yy2)
					replace yy2 = yy3
					drop yy3
				
					bysort EP guengl_check: gen zz = [(yy/xx)*100]^2
					bysort EP guengl_check: egen cc =sum(zz) if tag==1 
					bysort EP guengl_check: egen cc2 = max(cc) 
					replace concentration = cc2 if guengl_check==1						
						
					bysort EP guengl_check: gen cc3 = (1/cc)*10000
					bysort EP guengl_check: egen cc4 = max(cc3) 
					replace enp = cc4 if guengl_check==1							
						
					bysort EP: gen seatshare_check = xx/session_total_members if guengl_check==1 
					replace epg_perc = seatshare_check if guengl_check==1 
					replace epg_members = xx if guengl_check ==1
					replace npd_per_epg = yy2 if guengl_check==1 
					bysort EP guengl_check: replace npd_percent = (yy/xx) if guengl_check==1
				
					sort EP start_group_ses group1_ses switch_date1 bloc_id
					list EP ms bloc_id start_group_ses-end_group_ses switch_date1-switch_date4 epg_members epg_perc npd_per_epg concentration epg_days xx tag yy yy2 zz cc cc2 seatshare_check  ///
					if guengl_check==1, compress
				
					sort epg_tag EP
					list EP ms bloc_id start_group_ses-end_group_ses switch_date1-switch_date4 epg_members epg_days epg_perc npd_per_epg concentration ///
					if guengl_check==1, compress 
					
					sort epg_tag EP
					list EP ms bloc_id start_group_ses-end_group_ses switch_date1-switch_date4 epg_members epg_days epg_perc npd_per_epg concentration epg_tag ///
					if guengl_check==1, compress 				
					
					list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"		
					sort hoy_id EP start_group end_group bloc_id
					
					sort EP ms bloc_id
					list EP ms nationalparty bloc_id parlgov tag start_group_ses-end_group_ses switch_date1-switch_date4  if guengl_check==1, compress 
					
					sort hoy_id EP start_group end_group bloc_id
*********************************************************************************************		
			
			***Greens
				drop xx-cc4 seatshare_check	
				gen v_check = 0
				replace v_check = 1 if start_group_num_ses == 6 | start_group_num == 6 | group1_num_ses == 6 | group2_num_ses == 6 | group3_num_ses == 6		
			
				bysort EP v_check: gen xx = _N 
				sort hoy_id EP start_group end_group bloc_id
				egen tag = tag(EP  bloc_id) if v_check ==1
				bysort EP v_check bloc_id: gen yy = _N
				bysort EP v_check tag: gen yy2 = _N if tag==1
				bysort EP v_check: egen yy3=max(yy2)
				replace yy2 = yy3
				drop yy3
			
				bysort EP v_check: gen zz = [(yy/xx)*100]^2
				bysort EP v_check: egen cc =sum(zz) if tag==1 
				bysort EP v_check: egen cc2 = max(cc) 
				replace concentration = cc2 if v_check==1					
					
				bysort EP v_check: gen cc3 = (1/cc)*10000
				bysort EP v_check: egen cc4 = max(cc3) 
				replace enp = cc4 if v_check==1							
					
				bysort EP: gen seatshare_check = xx/session_total_members if v_check==1 
				replace epg_perc = seatshare_check if v_check==1 
				replace epg_members = xx if v_check ==1
				replace npd_per_epg = yy2 if v_check==1 
				bysort EP v_check: replace npd_percent = (yy/xx) if v_check==1
			
			
				sort EP start_group_ses group1_ses switch_date1 bloc_id
				list EP ms bloc_id start_group_ses-end_group_ses switch_date1-switch_date4 epg_members epg_perc npd_per_epg concentration epg_days xx tag yy yy2 zz cc cc2 seatshare_check  ///
				if v_check==1, compress
				
				sort EP start_group_ses group1_ses switch_date1 bloc_id
				list EP ms bloc_id start_group_ses-end_group_ses switch_date1-switch_date4 epg_members epg_days epg_perc npd_per_epg concentration   ///
				if v_check==1, compress
						
				sort epg_tag EP
				list EP ms bloc_id start_group_ses-end_group_ses switch_date1-switch_date4 epg_members epg_days epg_perc npd_per_epg concentration epg_tag ///
				if v_check==1, compress 
				
				sort EP ms bloc_id
				list EP ms nationalparty bloc_id parlgov tag start_group_ses-end_group_ses switch_date1-switch_date4  if v_check==1, compress 
				
				list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"		
				sort hoy_id EP start_group end_group bloc_id
*********************************************************************************************		
				
			***SOC
				drop xx-cc4 seatshare_check	
				gen soc_check = 0
				replace soc_check = 1 if start_group_num_ses == 8 | start_group_num == 8 | group1_num_ses == 8 | group2_num_ses == 8 | group3_num_ses == 8	
				replace bloc_id = 9 if bloc_id==8 & EP==1 & soc_check==1
				replace bloc_id = 88 if bloc_id==154 & EP==2 & soc_check==1
				replace bloc_id = 91 if bloc_id==159 & EP==2 & soc_check==1
				replace bloc_id = 171 if bloc_id==207 & EP==3 & soc_check==1
				replace bloc_id = 440 if bloc_id==433 & EP==5 & soc_check==1
				replace bloc_id = 594 if bloc_id==628 & EP==6 & soc_check==1
				replace bloc_id = 586 if bloc_id==755 & EP==6 & soc_check==1
				replace bloc_id = 600 if bloc_id==599 & EP==6 & soc_check==1
			
				bysort EP soc_check: gen xx = _N 
				sort hoy_id EP start_group end_group bloc_id
				egen tag = tag(EP  bloc_id) if soc_check ==1
				bysort EP soc_check bloc_id: gen yy = _N
				bysort EP soc_check tag: gen yy2 = _N if tag==1
				bysort EP soc_check: egen yy3=max(yy2)
				replace yy2 = yy3
				drop yy3
			
				bysort EP soc_check: gen zz = [(yy/xx)*100]^2
				bysort EP soc_check: egen cc =sum(zz) if tag==1 
				bysort EP soc_check: egen cc2 = max(cc) 
				replace concentration = cc2 if soc_check==1	
					
				bysort EP soc_check: gen cc3 = (1/cc)*10000
				bysort EP soc_check: egen cc4 = max(cc3) 
				replace enp = cc4 if soc_check==1							
					
				bysort EP: gen seatshare_check = xx/session_total_members if soc_check==1 
				replace epg_perc = seatshare_check if soc_check==1 
				replace epg_members = xx if soc_check ==1
				replace npd_per_epg = yy2 if soc_check==1 
				bysort EP soc_check: replace npd_percent = (yy/xx) if soc_check==1
			
				sort EP start_group_ses group1_ses switch_date1 bloc_id
				list EP ms bloc_id start_group_ses-end_group_ses switch_date1-switch_date4 epg_members epg_perc npd_per_epg concentration epg_days xx tag yy yy2 zz cc cc2 seatshare_check  ///
				if soc_check==1, compress
				
				sort EP start_group_ses group1_ses switch_date1 bloc_id
				list EP ms bloc_id start_group_ses-end_group_ses switch_date1-switch_date4 epg_members epg_days epg_perc npd_per_epg concentration   ///
				if soc_check==1 & EP < 4, compress
				
				sort EP start_group_ses group1_ses switch_date1 bloc_id
				list EP ms bloc_id start_group_ses-end_group_ses switch_date1-switch_date4 epg_members epg_days epg_perc npd_per_epg concentration   ///
				if soc_check==1 & EP > 3, compress
						
				sort epg_tag EP
				list EP hoy_id ms bloc_id start_group_ses-end_group_ses switch_date1-switch_date4 epg_members epg_days epg_perc npd_per_epg concentration epg_tag ///
				if soc_check==1 & epg_tag==1, compress 
				
				replace epg_tag = 0 if EP==3 & soc_check==1 & hoy_id ==907 & epg_tag==1
				
					sort EP ms bloc_id
					list EP  nationalparty ms bloc_id parlgov tag start_group_ses-end_group_ses switch_date1-switch_date4 if soc_check==1 & EP==6, compress 
				
				list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"		
				sort hoy_id EP start_group end_group bloc_id
*********************************************************************************************		
					
			***Liberals
				drop xx-cc4 seatshare_check	
				gen l_check = 0
				replace l_check = 1 if start_group_num_ses == 9 | start_group_num == 9 | group1_num_ses == 9 | group2_num_ses == 9 | group3_num_ses == 9	
				replace bloc_id = 29 if bloc_id==30 & EP==1 & l_check==1
				replace bloc_id = 112 if bloc_id==113 & EP==2 & l_check==1
				replace bloc_id = 221 if bloc_id==263 & EP==3 & l_check==1
				replace bloc_id = 328 if bloc_id==354 & EP==4 & l_check==1
				replace bloc_id = 330 if bloc_id==396 & EP==4 & l_check==1
				replace bloc_id = 463 if bloc_id==464 & EP==5 & l_check==1
				replace bloc_id = 617 if bloc_id==754 & EP==6 & l_check==1
				replace bloc_id = 657 if bloc_id==656 & EP==6 & l_check==1
			
				bysort EP l_check: gen xx = _N 
				sort hoy_id EP start_group end_group bloc_id
				egen tag = tag(EP  bloc_id) if l_check==1
				bysort EP l_check bloc_id: gen yy = _N
				bysort EP l_check tag: gen yy2 = _N if tag==1
				bysort EP l_check: egen yy3=max(yy2)
				replace yy2 = yy3
				drop yy3
			
				bysort EP l_check: gen zz = [(yy/xx)*100]^2
				bysort EP l_check: egen cc =sum(zz) if tag==1 
				bysort EP l_check: egen cc2 = max(cc) 
				replace concentration = cc2 if l_check==1	
					
				bysort EP l_check: gen cc3 = (1/cc)*10000
				bysort EP l_check: egen cc4 = max(cc3) 
				replace enp = cc4 if l_check==1							
					
				bysort EP: gen seatshare_check = xx/session_total_members if l_check==1 
				replace epg_perc = seatshare_check if l_check==1 
				replace epg_members = xx if l_check ==1
				replace npd_per_epg = yy2 if l_check==1 
				bysort EP l_check: replace npd_percent = (yy/xx) if l_check==1
			
				sort EP start_group_ses group1_ses switch_date1 bloc_id
				list EP ms bloc_id start_group_ses-end_group_ses switch_date1-switch_date4 epg_members epg_perc npd_per_epg concentration epg_days xx tag yy yy2 zz cc cc2 seatshare_check  ///
				if l_check==1, compress
				
				sort EP start_group_ses group1_ses switch_date1 bloc_id
				list EP ms bloc_id start_group_ses-end_group_ses switch_date1-switch_date4 epg_members epg_days epg_perc npd_per_epg concentration   ///
				if l_check==1, compress				
						
				sort epg_tag EP
				list EP hoy_id ms bloc_id start_group_ses-end_group_ses switch_date1-switch_date4 epg_members epg_days epg_perc npd_per_epg concentration epg_tag ///
				if l_check==1 & epg_tag==1, compress 
				
					sort EP ms bloc_id
					list EP  nationalparty ms bloc_id parlgov tag if l_check==1, compress 
				
				list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"		
				sort hoy_id EP start_group end_group bloc_id
*********************************************************************************************					
			***EPP
				drop xx-cc4 seatshare_check	
				gen epp_check = 0
				replace epp_check = 1 if start_group_num_ses == 10 | start_group_num == 10 | group1_num_ses == 10 | group2_num_ses == 10 | group3_num_ses == 10		
				replace epg_tag = 0 if EP==3 & epp_check==1 & hoy_id ==1393 & epg_tag==1
				replace epg_tag = 1 if EP==2 & epp_check==1 & hoy_id==1471 & epg_tag==0
				replace bloc_id = 36 if bloc_id ==41 & EP==1 & epp_check==1
				replace bloc_id = 40 if bloc_id ==28 & EP==1 & epp_check==1
				replace bloc_id = 242 if bloc_id == 243 & EP==3 & epp_check==1
				replace bloc_id = 328 if bloc_id == 354 & EP==4 & epp_check==1
				replace bloc_id = 486 if bloc_id == 513 & EP==5 & epp_check==1
				replace bloc_id = 682 if bloc_id == 737 & EP==6 & epp_check==1
			
				bysort EP epp_check: gen xx = _N 
				sort hoy_id EP start_group end_group bloc_id
				egen tag = tag(EP  bloc_id) if epp_check ==1
				bysort EP epp_check bloc_id: gen yy = _N
				bysort EP epp_check tag: gen yy2 = _N if tag==1
				bysort EP epp_check: egen yy3=max(yy2)
				replace yy2 = yy3
				drop yy3
				replace tag = 0 if EP==2 & epp_check==1 & bloc_id==151 & tag==1
			
				bysort EP epp_check: gen zz = [(yy/xx)*100]^2
				bysort EP epp_check: egen cc =sum(zz) if tag==1 
				bysort EP epp_check: egen cc2 = max(cc) 
				replace concentration = cc2 if epp_check==1					
					
				bysort EP epp_check: gen cc3 = (1/cc)*10000
				bysort EP epp_check: egen cc4 = max(cc3) 
				replace enp = cc4 if epp_check==1							
					
				bysort EP: gen seatshare_check = xx/session_total_members if epp_check==1 
				replace epg_perc = seatshare_check if epp_check==1 
				replace epg_members = xx if epp_check ==1
				replace npd_per_epg = yy2 if epp_check==1 
				bysort EP epp_check: replace npd_percent = (yy/xx) if epp_check==1
				
				sort EP ms bloc_id
				list EP  nationalparty ms bloc_id parlgov tag if epp_check==1 & EP==6, compress 				
			
				list EP start_group enp term_share npd_per_epg epg_perc if epg_tag==1 & start_group != "NI"		

				drop xx-cc4 seatshare_check	
				
				sort hoy_id EP start_group end_group bloc_id					
				
				save EUP_replication_dataset_12092020_A, replace
				
				*save check1, replace
				*cf _all using EUP_replication_dataset_12092020_A, verbose
				*ALL GOOD
				*sort EP start_group

**************************************************************************************************************************************
**************************************************************************************************************************************		
				
***Check distances
	use EUP_replication_dataset_12092020_A, clear
		
	sort EP start_group_num
	
	count if switch_date1 == start_date_ses & late_start==1 & collapse==1 & start_ses_switch==1
	replace start_ses_switch = 0 if switch_date1 == start_date_ses & late_start==1 & collapse==1 & start_ses_switch==1
	replace start_ses_switch = 1 if start_ses_switch==0 & ftr==1
	replace late_start = 0 if hoy_id==23745 & EP==6
	replace start_ses_switch = 0 if hoy_id==23747 & EP==6
	replace start_ses_switch = 0 if hoy_id==24088 & EP==6
	replace start_ses_switch = 0 if hoy_id==24089 & EP==6
	replace start_ses_switch = 0 if hoy_id==23745 & EP==6
		
	**EPG MEDIANS				
		bysort EP start_group_num: egen epg_median_d1 = median(dw_nomd1)
		bysort EP start_group_num: egen epg_median_d2 = median(dw_nomd2)
	
	***NPD MEDIANS	
		bysort EP bloc_id: egen npd_median_d1 = median(dw_nomd1)
		bysort EP bloc_id: egen npd_median_d2 = median(dw_nomd2)

	***MEP to EPG Distance
		gen a1_raw = abs(dw_nomd1 - epg_median_d1)
		gen a2_raw = abs(dw_nomd2 - epg_median_d2)
					
	***NPD to EPG Distance	
		gen c1_raw = abs(npd_median_d1 - epg_median_d1) 
		gen c2_raw = abs(npd_median_d2 - epg_median_d2)						
	
	****Lag Distances
		*drop lag_mep_to_epg* lag_mep_to_npd_d1*
		
		sort hoy_id EP 
		bysort hoy_id: gen lag_ref_a1 = a1_raw[_n-1] 
		bysort hoy_id: gen lag_ref_a2 = a2_raw[_n-1]  
		bysort hoy_id: gen lag_ref_c1 = c1_raw[_n-1]
		bysort hoy_id: gen lag_ref_c2 = c2_raw[_n-1]			
		
	***MEP to EPG Lagged
		gen a1_lagged = 0
		replace a1_lagged = lag_ref_a1 if start_ses_switch ==1 & ftr ==0	
		replace a1_lagged = a1_raw if start_ses_switch ==1 & ftr ==1	
		replace a1_lagged = a1_raw if start_ses_switch ==0 
		replace a1_lagged = a1_raw if a1_lagged ==. 
		
		gen a2_lagged = 0
		replace a2_lagged = lag_ref_a2 if start_ses_switch ==1 & ftr ==0
		replace a2_lagged = a2_raw if start_ses_switch ==1 & ftr ==1	
		replace a2_lagged = a2_raw if start_ses_switch ==0 
		replace a2_lagged = a2_raw if a2_lagged ==. 
		
	***MEP to NPD
		gen c1_lagged = 0
		replace c1_lagged = lag_ref_c1 if start_ses_switch ==1 & ftr ==0
		replace c1_lagged = c1_raw if start_ses_switch ==1 & ftr ==1	
		replace c1_lagged = c1_raw if start_ses_switch ==0 
		replace c1_lagged = c1_raw if c1_lagged ==. 
		
		gen c2_lagged = 0
		replace c2_lagged = lag_ref_c1 if start_ses_switch ==1 & ftr ==0
		replace c2_lagged = c2_raw if start_ses_switch ==1 & ftr ==1	
		replace c2_lagged = c2_raw if start_ses_switch ==0 
		replace c2_lagged = c2_raw if c2_lagged ==.
	
	***Standardized	Lagged Distances
		egen a1_std2 = std(a1_lagged)
		egen a2_std2 = std(a2_lagged)
		egen c1_std2 = std(c1_lagged)
		egen c2_std2 = std(c2_lagged)
		
	***lagged EPG.Percentage
		sort hoy_id EP 
		bysort hoy_id: gen lag_ref_epgperc = epg_perc[_n-1] 
		gen epg_perc_lag = 0
		replace epg_perc_lag = lag_ref_epgperc if start_ses_switch ==1 & ftr ==0
		replace epg_perc_lag = epg_perc if start_ses_switch ==1 & ftr ==1	
		replace epg_perc_lag = epg_perc if start_ses_switch ==0
		replace epg_perc_lag = epg_perc if epg_perc_lag ==.
	
	***lagged NPD.Percentage
		sort hoy_id EP 
		bysort hoy_id: gen lag_ref_npdperc = npd_percent[_n-1] 
		gen npd_perc_lag = 0
		replace npd_perc_lag = lag_ref_npdperc if start_ses_switch ==1 & ftr ==0
		replace npd_perc_lag = npd_percent if start_ses_switch ==1 & ftr ==1	
		replace npd_perc_lag = npd_percent if start_ses_switch ==0
		replace npd_perc_lag = npd_percent if npd_perc_lag ==.
		tab lag_ref_npdperc
	***age 
		replace age_martin = 51.50 if hoy_id==4553 & EP==5
		replace age_martin = 51.42 if hoy_id==4323 & EP==5
		replace age_martin = 34.08 if hoy_id==4519 & EP==5
		replace age_martin = 39.08 if hoy_id==4519 & EP==6
		replace age_martin = 49.00 if hoy_id==28217 & EP==6
		
	***lagged Age
		sort hoy_id EP 
		bysort hoy_id: gen lag_ref_age = age_martin[_n-1] 
		gen age_lag = 0
		replace age_lag = lag_ref_age if start_ses_switch ==1 & ftr ==0
		replace age_lag = age_martin if start_ses_switch ==1 & ftr ==1	
		replace age_lag = age_martin if start_ses_switch ==0
		replace age_lag = age_martin if age_lag ==.
		
	***lagged Tenure
		sort hoy_id EP 
		bysort hoy_id: gen lag_ref_tenure = mep_tenure[_n-1] 
		gen tenure_lag = 0
		replace tenure_lag = lag_ref_tenure if start_ses_switch ==1 & ftr ==0
		replace tenure_lag = mep_tenure if start_ses_switch ==1 & ftr ==1	
		replace tenure_lag = mep_tenure if start_ses_switch ==0
		replace tenure_lag = mep_tenure if tenure_lag ==.
		
	***Lagged Govt
		sort hoy_id EP 
		bysort hoy_id: gen lag_ref_govt = govt2[_n-1] 
		gen govt_lag = 0
		replace govt_lag = lag_ref_govt if start_ses_switch ==1 & ftr ==0
		replace govt_lag = govt2 if start_ses_switch ==1 & ftr ==1	
		replace govt_lag = govt2 if start_ses_switch ==0
		replace govt_lag = govt2 if govt_lag ==.
		tab lag_ref_govt
	 
	***Lagged Commissioner
		sort hoy_id EP 
		bysort hoy_id: gen lag_ref_com = np_com[_n-1] 
		gen np_com_lag = 0
		replace np_com_lag = lag_ref_govt if start_ses_switch ==1 & ftr ==0
		replace np_com_lag = np_com if start_ses_switch ==1 & ftr ==1	
		replace np_com_lag = np_com if start_ses_switch ==0
		replace np_com_lag = np_com if np_com_lag ==.		

		*sort hoy_id EP 
		*list EP start_group_ses-end_group_ses dw* epg_median_d1 a1_raw a1_lagged start_ses_switch multisession if a1_lagged==.		
		
		*list EP start_group_ses-end_group_ses dw* epg_median_d1 a1_raw a1_lagged start_ses_switch multisession if npd_perc_lag ==.		
	
		*list EP hoy_id hoy_name start_group_ses-end_group_ses switch_date1-switch_date2 session_switch indiv_switch_restrict1 bloc_switch_restrict1 ///
		*collapse ftr  if start_ses_switch ==1 & ftr ==0 & collapse==0, compress

	***TABLE 3: Summary of DVS
		tab2 EP session_switch
		tab2 EP collapse
		tab2 EP indiv_switch_restrict1
		tab2 EP bloc_switch_restrict1
		tab2 indiv_switch_restrict1 bloc_switch_restrict1				
					
			*list EP hoy_id hoy_name  start_group_ses-end_group_ses bloc_id switch_date* collapse ftr merger dissolve if EP==1 & session_switch==1
			
			sort collapse bloc_switch_restrict1 ftr dissolve merger bloc_id    
			list EP hoy_id hoy_name  start_group_ses-end_group_ses bloc_id switch_date* collapse ftr merger dissolve ///
			indiv_switch_restrict1 bloc_switch_restrict1 if EP==4 & session_switch==1, compress
	
		sort hoy_id EP start_group end_group bloc_id					
		
		save EUP_replication_dataset_12092020_B, replace
		
			*save check2, replace
			*cf _all using EUP_replication_dataset_12092020_B, verbose
			*ALL GOOD
			*sort EP start_group
		
******Introduce Lags for the Ttests

	use EUP_replication_dataset_12092020_B, clear
	
	bigtab EP start_group term_share if epg_tag==1
	
	***Lagging variables for FTR
		
		***Term Share
			gen term_share2 = term_share
			replace term_share2 = ftr_epg_ts if ftr==1 
		
		**Seat Share
			gen epg_perc2 = epg_perc
			replace epg_perc2 = ftr_epg_perc if ftr==1
			
		**NPDs per EPG_leader
			gen npd_per_epg2 = npd_per_epg
			replace npd_per_epg2 = ftr_npds if ftr==1
				
		***ENP
			gen enp2 = enp
			replace enp2 = ftr_enp if ftr==1 	
			
		**Concentration
			gen concent2 = concentration
			replace concent2 = ftr_concent if ftr==1 

***Reduce Dataset for group-level analysis

			keep if epg_tag==1
			keep EP start_group start_group_num  collapse ftr merger dissolve term_share term_share2  epg_perc epg_perc2  npd_per_epg npd_per_epg2  enp enp2 concentration concent2
			sort EP start_group
			list 
		
			sort EP start_group
			list EP start_group  term_share2  epg_perc2  npd_per_epg2  enp2 collapse merger ftr dissolve 
					
			replace ftr= 1 if EP==1 & start_group== "CDI"
			replace ftr = 1 if EP==1 & start_group== "DEP"
			set obs `=_N+1'
				replace EP = 2 if EP==. 
				replace start_group = "TCDI" if start_group==""
				replace merger = 0 if merger == .
				replace dissolve = 1 if dissolve == .
				replace ftr = 0 if ftr == .
				replace collapse = 1 if collapse == .
				replace term_share2 = 0.033954 if term_share2 == .
				replace epg_perc2 = 0.016 if epg_perc2 == .
				replace npd_per_epg2 = 6 if npd_per_epg2 == .
				replace concent2 = 1837 if concent2 == .
				replace start_group_num = 30 if start_group_num==.
				replace enp2 = 4.545454 if enp2 ==.
				
			replace ftr = 1 if EP==2 & start_group== "COM"
			replace ftr = 1 if EP==3 & start_group== "CG"
			replace ftr = 1 if EP==3 & start_group== "DR"
			
			set obs `=_N+1'
				replace EP = 4 if EP == .
				replace start_group = "FE" if start_group == ""
				replace merger = 1 if merger == .
				replace dissolve = 0 if dissolve == .
				replace ftr = 0 if ftr == .
				replace collapse = 1 if collapse == .
				replace term_share2 = 0.192234 if term_share2  == .
				replace epg_perc2 = 0.038 if epg_perc2 == .
				replace npd_per_epg2 = 2 if npd_per_epg2 == .
				replace concent2 = 9311 if concent2 == .
				replace start_group_num = 31 if start_group_num==.
				replace enp2 = 1.073973 if enp2 ==.
			
			replace ftr = 1 if EP==3 & start_group== "RBW"
			
			replace term_share2 = 2.192234 if EP==4 & start_group=="RDE"
			replace npd_per_epg2 = 5 if EP==4 & start_group=="RDE"
			replace concent2 = 3673 if EP==4 & start_group=="RDE"
			replace enp2 = 2.7222 if EP==4 & start_group=="RDE"
		
		set obs `=_N+1'			
				replace EP = 4 if EP == .
				replace start_group = "EDN" if start_group == ""
				replace merger = 0 if merger == .
				replace dissolve = 1 if dissolve == .
				replace ftr = 0 if ftr == .
				replace collapse = 1 if collapse == .
				replace term_share2 = 0.4633078 if term_share2 == .
				replace epg_perc2 = 0.026 if epg_perc2 == .
				replace npd_per_epg2 = 6 if npd_per_epg2 == .
				replace concent2 = 3241 if concent2 == .
				replace start_group_num = 32 if start_group_num==.
				replace enp2 = 3.08547 if enp2 ==.			
							
			set obs `=_N+1'			
				replace EP = 4 if EP == .
				replace start_group = "I-EDN" if start_group == ""
				replace merger = 0 if merger == .
				replace dissolve = 0 if dissolve == .
				replace ftr = 1 if ftr == .
				replace collapse = 1 if collapse == .
				replace term_share2 = 0.5031906 if term_share2 == .
				replace epg_perc2 = 0.030 if epg_perc2 == .
				replace npd_per_epg2 = 10 if npd_per_epg2 == .
				replace concent2 = 2107 if concent2 == .
				replace start_group_num = 33 if start_group_num==.
				replace enp2 = 4.745098 if enp2 ==.
				
			replace ftr = 1 if EP==4 & start_group== "ARE"
			
			set obs `=_N+1'
				replace EP = 6 if EP == .
				replace start_group = "ITS" if start_group == ""
				replace merger = 0 if merger == .
				replace dissolve = 1 if dissolve == .
				replace ftr = 0 if ftr == .
				replace collapse = 1 if collapse == .
				replace epg_perc2 =  0.019  if epg_perc2 == .
				replace npd_per_epg2 = 10 if npd_per_epg2 == .
				replace concent2 = 1235 if concent2 == .
				replace term_share2 = 0.166575 if term_share2 == .
				replace start_group_num = 34 if start_group_num==.
				replace enp2 = 7.714286 if enp2 ==.
				
			set obs `=_N+1'
				replace EP = 3 if EP == .
				replace start_group = "ED" if start_group == ""
				replace merger = 1 if merger == .
				replace dissolve = 0 if dissolve == .
				replace ftr = 0 if ftr == .
				replace collapse = 1 if collapse == .
				replace epg_perc2 =  0.0561983  if epg_perc2 == .
				replace npd_per_epg2 = 2 if npd_per_epg2 == .
				replace concent2 = 5575 if concent2 == .
				replace term_share2 = 2.5558 if term_share2 == .	
				replace start_group_num = 11 if start_group_num==.
				replace enp2 = 1.124514 if enp2 ==.
				
			replace ftr = 1 if start_group == "EDD"
			replace dissolve = 0 if start_group == "NI" & EP==2
			replace collapse = 0 if start_group == "NI" & EP==2
			replace merger = 0 if start_group == "UPE" & EP==4
			replace ftr = 1 if start_group == "UPE" & EP==4
			replace dissolve = 0 if start_group == "NI" & EP==6
			replace collapse = 0 if start_group == "NI" & EP==6
			replace ftr = 1 if start_group == "UEN" & EP==6
			replace ftr = 1 if start_group == "InDem" & EP== 6
			replace ftr = 0 if start_group == "UEN" & EP==5
			replace collapse = 0 if start_group == "UEN" & EP==5
			
			replace ftr= 0 if start_group =="GUE" & EP==3
			
			replace collapse = 1 if ftr==1
			replace collapse = 1 if dissolve==1
			replace collapse = 1 if merger==1	
			
			drop if start_group == "NI"
						
			sort EP start_group
			
			sort EP collapse ftr diss merger  start_group
			
			sort  collapse ftr diss merger EP 
			
			
			list EP start_group collapse ftr dissolve merger term_share2 epg_perc2 npd_per_epg2 enp2
			
				sort  EP start_group collapse term_share enp2							
				save EUP_replication_dataset_12092020_C, replace
			
				*save check4, replace
				*cf _all using EUP_replication_dataset_12092020_C, verbose
				*ALL GOOD	
		
************************************************************************************************************		
		***Table 2 & Appendix C
		***Results from these tests are combined in Table 2
		***The full battery of preliminary tests for equality & the t-tests which are included in App. C are here
			
			**Test for equality of variance with Levene's Test
			use EUP_replication_dataset_12092020_C, replace
			
			***Collapse
				*sdtest term_share2, by(collapse)
				robvar term_share2, by(collapse)
				ttest term_share2, by(collapse) unequal
				
				robvar epg_perc2, by(collapse)
				ttest epg_perc2, by(collapse) unequal
				
				robvar npd_per_epg2, by(collapse)		
				ttest npd_per_epg2, by(collapse) unequal	
				
				robvar enp2, by(collapse)
				ttest enp2, by(collapse) unequal
									
			**FTR
				robvar term_share2, by(ftr)
				ttest term_share2, by(ftr) unequal
				
				robvar epg_perc2, by(ftr)
				ttest epg_perc2, by(ftr) unequal
				
				robvar npd_per_epg2, by(ftr)		
				ttest npd_per_epg2, by(ftr)	unequal	
				
				robvar enp2, by(ftr)
				sdtest  enp2, by(ftr)
				ttest enp2, by(ftr) unequal
			
			**Dissolve
				robvar term_share2, by(dissolve)
				sdtest term_share2, by(dissolve)
				ttest term_share2, by(dissolve)
				ttest term_share2, by(dissolve) unequal
				
				robvar epg_perc2, by(dissolve)	
				sdtest epg_perc2, by(dissolve)	
				ttest epg_perc2, by(dissolve)
				ttest epg_perc2, by(dissolve) unequal
				
				robvar npd_per_epg2, by(dissolve)
				sdtest npd_per_epg2, by(dissolve)
				ttest npd_per_epg2, by(dissolve)
				ttest npd_per_epg2, by(dissolve) unequal
				
				robvar enp2, by(dissolve)
				sdtest enp2, by(dissolve)
				ttest enp2, by(dissolve)				
				ttest enp2, by(dissolve) unequal
			
			***Mergers N=3
				sdtest term_share2, by(merger)
				robvar term_share2, by(merger)
				ttest term_share2, by(merger)				
				
				robvar epg_perc2, by(merger)
				sdtest epg_perc2, by(merger)
				ttest epg_perc2, by(merger) unequal
				
				robvar npd_per_epg2, by(merger)	
				sdtest npd_per_epg2, by(merger)
				ttest npd_per_epg2, by(merger)
				ttest npd_per_epg2, by(merger) unequal
				
				robvar enp2, by(merger)
				sdtest enp2, by(merger)				
				ttest enp2, by(merger) 
				ttest enp2, by(merger) unequal
				
				ttest enp2, by(merger) welch
							
				sort  EP start_group collapse term_share enp2		
				save EUP_replication_dataset_12092020_D, replace
				
				*save check6, replace
				*cf _all using dataset_for_RR2_ttests_11172020, verbose
				*ALL GOOD

************************************************************************************************
	
	***Figure 2. DW Nominate Scores	
		use EUP_replication_dataset_12092020_B, clear
	
			scatter dw_nomd2 dw_nomd1 if  dw_nomd1 <= 1, by(EP) ||			
			twoway scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==10, mc(blue) by(EP) msize(vsmall) || ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==11, mc(navy) by(EP) msize(vsmall)	|| ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==9, mc(yellow) by(EP) msize(vsmall) || ///				
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==1, mc(pink) by(EP) msize(vsmall) || ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & dw_nomd2 <= 0.5 & start_group_num==8, mc(red) by(EP) msize(vsmall) || ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==6, mc(green) by(EP) msize(vsmall) || ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==2, mc(pink) by(EP) msize(vsmall)  ||  ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==3, mc(pink) by(EP) msize(vsmall) || ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==4, mc(pink) by(EP) msize(vsmall) || ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==5, mc(lime) by(EP) msize(vsmall) || ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==7, mc(orange) by(EP) msize(vsmall) || ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==12, mc(bluishgray) by(EP) msize(vsmall) || /// 
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==13, mc(dknavy) by(EP) msize(vsmall) || ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==14, mc(dknavy) by(EP) msize(vsmall) || ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==15, mc(dknavy) by(EP) msize(vsmall) || ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==16, mc(dkorange) by(EP) msize(vsmall) || ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==17, mc(orange) by(EP) msize(vsmall) || ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==19, mc(orange) by(EP) msize(vsmall) || ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==20, mc(orange) by(EP) msize(vsmall) || ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==21, mc(orange) by(EP) msize(vsmall) || ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==23, mc(maroon) by(EP) msize(vsmall) || ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==25, mc(maroon) by(EP) msize(vsmall) || ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==26, mc(maroon) by(EP) msize(vsmall) || ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==27, mc(black) by(EP) msize(vsmall) || ///
			scatter dw_nomd2 dw_nomd1 if dw_nomd1 <= 1 & start_group_num==28, mc(gray) msize(vsmall) by(EP, legend(off)) 
				
********************************************************************************				
	***Analysis of Strategic Switching
		
		use EUP_replication_dataset_12092020_B, clear
						
	***Models		
		
		***All Switches, Main Models
				
				*Full Model
				firthlogit session_switch ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///	
				collapse ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag
					est store all_switch_full3
					est save all_switch_full3, replace
					firthfit
					
					generate sample_all3 = 1 if e(sample) ==1	
					*list EP hoy_id start_group  if age_lag==.
					
					*sort EP start_group
					*list EP  session_switch ///
					*npd_percent c_epg_perc2 ///
					*a1_std a2_std c1_std c2_std ///	
					*collapse ///
					*tenure_lag i.female age_lag i.govt_lag np_com_lag hoy_name if sample_all3 !=1
				
					est restore all_switch_full3
					constraint 1 npd_perc_lag = 0					
					constraint 2 epg_perc_lag = 0
					constraint 3 a1_std2 = 0					
					constraint 4 a2_std2 = 0
					constraint 5 c1_std2 = 0			
					constraint 6 c2_std2 = 0
					constraint 7 collapse = 0					
				
						*sum a1_std a2_std 
						*est restore all_switch_full3_or
						*margins, predict() at(a1_std2==(-0.5(0.5)8) ) vsquish atmeans post 
						*marginsplot
						
						*est restore all_switch_full3
						*margins, predict() at(a2_std2==(-0.5(0.5)5) ) vsquish atmeans post 
						*marginsplot					
				
						*est restore all_switch_full3_or
						*margins, predict() at(npd_percent==(0(0.1)1) collapse==(0)) vsquish atmeans post 
						*marginsplot	
						
						*est restore all_switch_full3_or
						*margins, predict() at( epg_perc==(0.05(0.1)0.35)) vsquish  post 
						*marginsplot	
						
						*est restore all_switch_full3_or
						*margins, predict() at( npd_percent==(0.05(0.1)0.85)) vsquish  post 
						*marginsplot	
						
						*est restore all_switch_full3
						*margins, predict() at(epg_perc==(0(0.03)0.3) ) vsquish atmeans post 
						*marginsplot							
						
						*est restore all_switch_full3
						*margins, predict() at(a2_std2==(-1(1)8) ) vsquish atmeans post 
						*marginsplot
						
						*est restore all_switch_full3
						*margins, dydx() at(c2_std2=(-1(1)8)) vsquish atmeans post 
						*marginsplot
						*test _b[1._at] = _b[2._at] 
						*test _b[1._at] = _b[3._at] 
						*test _b[1._at] = _b[4._at] 
						*te*st _b[1._at] = _b[5._at] 
						*test _b[1._at] = _b[6._at] 
						*test _b[1._at] = _b[7._at] 
						*test _b[1._at] = _b[8._at] 
						*test _b[1._at] = _b[9._at] 
											
				*Power
				firthlogit session_switch ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///	
				collapse ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag  if sample_all3==1, constraint(3 4 5 6 7)
					est store all_power3
					est save all_power3, replace
					firthfit
				
				*Add Collapse
				firthlogit session_switch ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///	
				collapse ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag  if sample_all3==1, constraint(3 4 5 6 )
					est store all_power_col3
					est save all_power_col3, replace
					firthfit			
					
					est use all_power3
					outreg2 using all_switches3,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use all_power_col3
					outreg2 using all_switches3,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
					est use all_switch_full3
					outreg2 using all_switches3,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	

			***Individual Switches, Main Models	
			clear all
			use EUP_replication_dataset_12092020_B, clear
					
				*Indiv Full Model
					firthlogit indiv_switch_restrict1 ///
					npd_perc_lag epg_perc_lag ///
					a1_std2 a2_std2 ///	
					tenure_lag i.female age_lag i.govt_lag np_com_lag 
						est store indiv_switch_full3
						est save indiv_switch_full3, replace
						firthfit
						
						generate sample_all4 = 1 if e(sample) ==1	
						list EP hoy_id start_group  if age_lag==.
					
						est restore indiv_switch_full3
						constraint 1 npd_perc_lag = 0					
						constraint 2 epg_perc_lag = 0
						constraint 3 a1_std2 = 0					
						constraint 4 a2_std2 = 0			
						
				**Indiv Power
					firthlogit indiv_switch_restrict1 ///
					npd_perc_lag epg_perc_lag ///
					a1_std2 a2_std2 ///	
					tenure_lag i.female age_lag i.govt_lag np_com_lag  if sample_all4==1, constraint(3 4)
						est store indiv_power3
						est save indiv_power3, replace
						firthfit
						
								
			***Bloc Switches; Main Models
				*Bloc Full Model
					firthlogit bloc_switch_restrict1 ///
					npd_perc_lag epg_perc_lag ///
					c1_std2 c2_std2 ///	
					tenure_lag i.female age_lag i.govt_lag np_com_lag 
						est store bloc_switch_full3
						est save bloc_switch_full3, replace
						firthfit
						
						generate sample_all5 = 1 if e(sample) ==1	
					
						est restore bloc_switch_full3
						constraint 5 c1_std2 = 0					
						constraint 6 c2_std2 = 0				
				
				*Bloc Power
					firthlogit bloc_switch_restrict1 ///
					npd_perc_lag epg_perc_lag ///
					c1_std2 c2_std2 ///	
					tenure_lag i.female age_lag i.govt_lag np_com_lag  if sample_all5==1, constraint(5 6)
						est store bloc_power3
						est save bloc_power3, replace
						firthfit
						
				
					est use indiv_power3
					outreg2 using indiv_bloc3,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use indiv_switch_full3
					outreg2 using indiv_bloc3,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use bloc_power3
					outreg2 using indiv_bloc3,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use bloc_switch_full3
					outreg2 using indiv_bloc3,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					
					***Alltogether
					est use all_power3
					outreg2 using Final_Table4,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use all_power_col3
					outreg2 using Final_Table4,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
					est use all_switch_full3
					outreg2 using Final_Table4,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
					est use indiv_power3
					outreg2 using Final_Table4,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use indiv_switch_full3
					outreg2 using Final_Table4,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use bloc_power3
					outreg2 using Final_Table4,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use bloc_switch_full3
					outreg2 using Final_Table4,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word

	
***************************************************************************************************************************************

	***Appendix A. Descriptive Statistics
	
		use EUP_replication_dataset_12092020_B, clear
		
		sum session_switch indiv_switch_restrict1  bloc_switch_restrict1 npd_percent  epg_perc   ///
		a1_std2 a2_std2 c1_std2 c2_std2 collapse dissolve ftr merger female age_martin govt2 np_com
		
		use EUP_replication_dataset_12092020_D, clear
		sum term_share epg_perc npd_per_epg enp collapse dissolve ftr merger

	***Appendix B. McElroy Replication Models
	
			use McElroy_replication_data, clear
			
			***Logit Models
				logit session_switch mep_tenure a1_std  major i.key_com##i.com_leader EPG_leader  ed_dummy
				est store mc_logit1b
				est save mc_logit1b, replace									
							
			**Firth Models
				firthlogit session_switch mep_tenure a1_std  major i.key_com##i.com_leader EPG_leader  ed_dummy
				est store mc_firth1b
				est save mc_firth1b, replace
				firthfit
					
					est use mc_logit1b
						outreg2 using ep3_comp2b,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use mc_firth1b
						outreg2 using ep3_comp2b,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word			
				
	***Appendix C. Levene's Tests and T-Tests
		***Lines 2279 to 2363

	***Appendix D. Robustness Checks and Coding Decisions
		
		use EUP_replication_dataset_12092020_B, clear
					
		***All Switches, EP Fixed Effects FIRTH Models				
				
				*Full Model
				firthlogit session_switch ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///	
				collapse ///
				i.EP ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag  
					est store all_switch_fe
					est save all_switch_fe, replace
					firthfit
					
					generate sample_fe = 1 if e(sample) ==1	
					*list EP hoy_id start_group  if age_lag==.
				
					est restore all_switch_fe
					constraint 1 npd_perc_lag = 0					
					constraint 2 epg_perc_lag = 0
					constraint 3 a1_std2 = 0					
					constraint 4 a2_std2 = 0
					constraint 5 c1_std2 = 0			
					constraint 6 c2_std2 = 0
					constraint 7 collapse = 0	
					constraint 8 EP = 0			
					
				*Baseline
				firthlogit session_switch ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///	
				collapse ///
				i.EP ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag  if sample_fe==1, constraint(1 2 3 4 5 6 7)
					est store all_base_fe
					est save all_base_fe, replace
					firthfit
					
				*Power
				firthlogit session_switch ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///	
				collapse ///
				i.EP ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag  if sample_fe==1, constraint(3 4 5 6 7)
					est store all_power_fe
					est save all_power_fe, replace
					firthfit
				
				*Add Collapse
				firthlogit session_switch ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///	
				collapse ///
				i.EP ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag  if sample_fe==1, constraint(3 4 5 6 )
					est store all_power_col_fe
					est save all_power_col_fe, replace
					firthfit
					
				***Everything just no collapse
				firthlogit session_switch ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///	
				collapse ///
				i.EP ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag  if sample_fe==1, constraint(7)
					est store all_no_col_fe
					est save all_no_col_fe, replace
					firthfit					
					
				***Distance Only
				firthlogit session_switch ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///	
				collapse ///
				i.EP ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag  if sample_fe==1, constraint(1 2 7)
					est store all_only_dist_col_fe
					est save all_only_dist_col_fe, replace
					firthfit
			
				***Indiv Full Model
				firthlogit indiv_switch_restrict1 ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 ///	
				i.EP ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag  
					est store fe_indiv_full
					est save fe_indiv_full, replace
					firthfit								
			
				***Bloc Full Model
				firthlogit bloc_switch_restrict1 ///
				npd_perc_lag epg_perc_lag ///
				c1_std2 c2_std2 ///	
				i.EP ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag  
					est store fe_bloc_full
					est save fe_bloc_full, replace
					firthfit
					
					est use all_base_fe
					outreg2 using app_fe,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
					est use all_only_dist_col_fe
					outreg2 using app_fe,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
					est use all_power_fe
					outreg2 using app_fe,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use all_no_col_fe
					outreg2 using app_fe,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use all_power_col_fe
					outreg2 using app_fe,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use all_switch_fe
					outreg2 using app_fe,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use fe_indiv_full
					outreg2 using app_fe,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
					est use fe_bloc_full
					outreg2 using app_fe,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
		
					
			****FIRTH MODELS WITH Disaggregated Collapse Variables
				*Full Model
				firthlogit session_switch ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///	
				dissolve ftr merger ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag  
					est store all_switch_disag
					est save all_switch_disag, replace
					firthfit
					
					generate sample_disag = 1 if e(sample) ==1	
					*list EP hoy_id start_group  if age_lag==.
				
					est restore all_switch_disag
					constraint 1 npd_perc_lag = 0					
					constraint 2 epg_perc_lag = 0
					constraint 3 a1_std2 = 0					
					constraint 4 a2_std2 = 0
					constraint 5 c1_std2 = 0			
					constraint 6 c2_std2 = 0
					constraint 7 dissolve = 0	
					constraint 8 ftr = 0
					constraint 9 merger = 0				
				
				*Baseline
				firthlogit session_switch ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///	
				dissolve ftr merger ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag  if sample_disag==1, constraint(1 2 3 4 5 6 7 8 9)
					est store all_base_disag
					est save all_base_disag, replace
					firthfit
					
				*Power
				firthlogit session_switch ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///	
				dissolve ftr merger ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag  if sample_disag==1, constraint(3 4 5 6 7 8 9)
					est store all_power_disag
					est save all_power_disag, replace
					firthfit
				
				*Add Collapse
				firthlogit session_switch ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///	
				dissolve ftr merger ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag  if sample_disag==1, constraint(3 4 5 6 )
					est store all_power_col_disag
					est save all_power_col_disag, replace
					firthfit
					
				***Everything just no collapse
				firthlogit session_switch ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///	
				dissolve ftr merger ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag  if sample_disag==1, constraint(7 8 9)
					est store all_no_col_disag
					est save all_no_col_disag, replace
					firthfit					
					
				***Distance Only
				firthlogit session_switch ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///	
				dissolve ftr merger ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag  if sample_disag==1, constraint(1 2 7 8 9)
					est store all_only_dist_col_disag
					est save all_only_dist_col_disag, replace
					firthfit
				
					est use all_base_disag
					outreg2 using app_disag,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
					est use all_power_disag
					outreg2 using app_disag,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
					est use all_only_dist_col_disag
					outreg2 using app_disag,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word							
					est use all_no_col_disag
					outreg2 using app_disag,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word						
					est use all_power_col_disag
					outreg2 using app_disag,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
					est use all_switch_disag
					outreg2 using app_disag,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
		
			***All Switches, Logit Models, clustered errors on MEPs
			
				*Full Model
				logit session_switch ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///	
				collapse ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag, vce(cluster hoy_id) 
					est store all_switch_logit
					est save all_switch_logit, replace
					generate sample_logit = 1 if e(sample) ==1									
					
				*Baseline
				logit session_switch ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag  if sample_logit==1, vce(cluster hoy_id)
					est store all_base_logit
					est save all_base_logit, replace
									
				*Power
				logit session_switch ///
				npd_perc_lag epg_perc_lag ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag  if sample_logit==1, vce(cluster hoy_id)
					est store all_base_logit
					est store all_power_logit
					est save all_power_logit, replace
								
				*Add Collapse
				logit session_switch ///
				npd_perc_lag epg_perc_lag ///
				collapse ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag  if sample_logit==1, vce(cluster hoy_id)
					est store all_base_logit
					est store all_power_col_logit
					est save all_power_col_logit, replace
										
				***Everything just no collapse
				logit session_switch ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///	
				tenure_lag i.female age_lag i.govt_lag np_com_lag  if sample_logit==1, vce(cluster hoy_id)
					est store all_no_col_logit
					est save all_no_col_logit, replace									
					
				***Distance Only
				logit session_switch ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///				
				tenure_lag i.female age_lag i.govt_lag np_com_lag  if sample_logit==1, vce(cluster hoy_id)
					est store all_only_dist_col_logit
					est save all_only_dist_col_logit, replace					
					
					est use all_base_logit
					outreg2 using app_logit,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
					est use all_power_logit
					outreg2 using app_logit,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
					est use all_only_dist_col_logit
					outreg2 using app_logit,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use all_no_col_logit
					outreg2 using app_logit,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word					
					est use all_power_col_logit
					outreg2 using app_logit,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					est use all_switch_logit
					outreg2 using app_logit,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
					
			
	****Options A, B, and CD
		use EUP_replication_dataset_12092020_B, clear
		
		*Option A
		*All IVs using Lag Replacements for "Beginning of Session" Switchers
				firthlogit session_switch ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///	
				collapse ///
				tenure_lag i.female age_lag i.govt_lag np_com_lag
				est save option_a_full, replace
				est store option_a_full
				firthfit
				
				firthlogit indiv_switch_restrict1 ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 ///	
				tenure_lag i.female age_lag i.govt_lag np_com_lag
				est save option_a_ind, replace
				est store option_a_ind
				firthfit
				
				firthlogit bloc_switch_restrict1 ///
				npd_perc_lag epg_perc_lag ///
				c1_std2 c2_std2 ///	
				tenure_lag i.female age_lag i.govt_lag np_com_lag
				est save option_a_bloc, replace
				est store option_a_bloc
				firthfit
		
		*Option B
		*Only using Lag Replacements for Distance & Power Variables
				firthlogit session_switch ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///	
				collapse ///
				mep_tenure i.female age_martin i.govt2 np_com  	
				est save option_b_full, replace
				est store option_b_full
				firthfit
				
				firthlogit indiv_switch_restrict1 ///
				npd_perc_lag epg_perc_lag ///
				a1_std2 a2_std2 ///	
				mep_tenure i.female age_martin i.govt2 np_com  	
				est save option_b_ind, replace
				est store option_b_ind
				firthfit
				
				firthlogit bloc_switch_restrict1 ///
				npd_perc_lag epg_perc_lag ///
				c1_std2 c2_std2 ///	
				mep_tenure i.female age_martin i.govt2 np_com  	
				est save option_b_bloc, replace
				est store option_b_bloc
				firthfit
		
		*Option C
		*Only using Lag Replacement for Distance Variabels
				firthlogit session_switch ///
				npd_percent epg_perc ///
				a1_std2 a2_std2 c1_std2 c2_std2 ///	
				collapse ///
				mep_tenure i.female age_martin i.govt2 np_com  	
				est save option_c_full, replace
				est store option_c_full
				firthfit
				
				firthlogit indiv_switch_restrict1 ///
				npd_percent epg_perc ///
				a1_std2 a2_std2 ///	
				mep_tenure i.female age_martin i.govt2 np_com  	
				est save option_c_ind, replace
				est store option_c_ind
				firthfit
				
				firthlogit bloc_switch_restrict1 ///
				npd_percent epg_perc ///
				c1_std2 c2_std2 ///	
				mep_tenure i.female age_martin i.govt2 np_com  	
				est save option_c_bloc, replace
				est store option_c_bloc
				firthfit
				
			est use option_a_full
			outreg2 using coding_comp,  replace ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
			est use option_b_full
			outreg2 using coding_comp,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
			est use option_c_full
			outreg2 using coding_comp,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
			
			est use option_a_ind
			outreg2 using coding_comp,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
			est use option_b_ind
			outreg2 using coding_comp,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
			est use option_c_ind
			outreg2 using coding_comp,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
			
			est use option_a_bloc
			outreg2 using coding_comp,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
			est use option_b_bloc
			outreg2 using coding_comp,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word
			est use option_c_bloc
			outreg2 using coding_comp,  append ctitle(Log Odds)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word	
			
			
	***Odds Ratios for full Models
	
			use EUP_replication_dataset_12092020_B, clear
	
		***Model 3				
			*Full Model
			firthlogit session_switch ///
			npd_perc_lag epg_perc_lag ///
			a1_std2 a2_std2 c1_std2 c2_std2 ///	
			collapse ///
			tenure_lag i.female age_lag i.govt_lag np_com_lag, or
				est store model3_or
				est save model3_or, replace
				firthfit
				
		***Model 5
			***Individual Switches, Main Models				
				*Indiv Full Model
					firthlogit indiv_switch_restrict1 ///
					npd_perc_lag epg_perc_lag ///
					a1_std2 a2_std2 ///	
					tenure_lag i.female age_lag i.govt_lag np_com_lag, or 
						est store model5_or
						est save model5_or, replace
						firthfit
		***Model 7								
			***Bloc Switches; Main Models
				*Bloc Full Model
					firthlogit bloc_switch_restrict1 ///
					npd_perc_lag epg_perc_lag ///
					c1_std2 c2_std2 ///	
					tenure_lag i.female age_lag i.govt_lag np_com_lag, or 
						est store model7_or
						est save model7_or, replace
						firthfit
			
			est use model3_or
			outreg2 using or_models,  replace ctitle(Log Ratios)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word eform
			est use model5_or
			outreg2 using or_models,  append ctitle(Log Ratios)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word eform
			est use model7_or
			outreg2 using or_models,  append ctitle(Log Ratios)  alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) word eform
			
	
			log close
			
	
