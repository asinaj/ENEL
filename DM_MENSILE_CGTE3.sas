OPTIONS VALIDVARNAME=any;
libname datafile "C:\Users\asinaj\Desktop\ENEL\LAST DATA";
libname output "C:\Users\asinaj\Desktop\ENEL\OUTPUT";

/*
proc sql;
select distinct '4ZECOGEOSAS01_ENTITA'n
from datafile.zecogeosas01;
quit;*/
data ZECOGEOSAS02;
	set datafile.zecogeosas01;
	length ENTITA_FARINELLO $150. KDAG_A KDAG_B 8.;
	format KDAG_A KDAG_B 19.2;

	if '4ZECOGEOSAS01_ENTITA'n in( "Farinello A" "Farinello B") then
		ENTITA_FARINELLO="Farinello";
	else ENTITA_FARINELLO='4ZECOGEOSAS01_ENTITA'n;

	if '4ZECOGEOSAS01_ENTITA'n = "Farinello A" then
		KDAG_A='4ZECOGEOSAS01_KDAG_NUMERAT'n;
	else KDAG_A=.;

	if '4ZECOGEOSAS01_ENTITA'n = "Farinello B" then
		KDAG_B='4ZECOGEOSAS01_KDAG_NUMERAT'n;
	else  KDAG_B=.;
run;

data zecogeosas03;
	set zecogeosas02;
	length  ore_disp_kdag 8. ore_disp_kdag_A 8. ore_disp_kdag_B 8.;
	format  ore_disp_kdag 19.2 ore_disp_kdag_A 19.2 ore_disp_kdag_B 19.2;

	/*if '4ZECOGEOSAS01_ENTITA'n in( "Farinello A" "Farinello B");*/
	ore_disp_kdag = '4ZECOGEOSAS01_ORE_MESE'n - '4ZECOGEOSAS01_KDAG_NUMERAT'n;

	if '4ZECOGEOSAS01_ENTITA'n = "Farinello A" then
		ore_disp_kdag_A = '4ZECOGEOSAS01_ORE_MESE'n - KDAG_A;
	else ore_disp_kdag_A=.;

	if '4ZECOGEOSAS01_ENTITA'n = "Farinello B" then
		ore_disp_kdag_B = '4ZECOGEOSAS01_ORE_MESE'n - KDAG_B;
	else  ore_disp_kdag_B=.;
run;

/*ore_disp_kdag=sum(ore_disp_kdag_A, ore_disp_kdag_B)*/
Proc sql;
	create table tot_farinello as
		Select '0CALMONTH2'n, '0CALYEAR'n, '4ZECOGEOSAS01_ORE_MESE'n, '4ZECOGEOSAS01_KDAG_NUMERAT'n, '4ZECOGEOSAS01_ENTITA'n,
			ore_disp_kdag_A, ore_disp_kdag_B, ore_disp_kdag
		From zecogeosas03
			where '4ZECOGEOSAS01_ENTITA'n in( "Farinello A" "Farinello B")
	;
quit;

Proc sql;
	create table tot_farinello2 as
		Select '0CALMONTH2'n, '0CALYEAR'n, '4ZECOGEOSAS01_ORE_MESE'n,'4ZECOGEOSAS01_ENTITA'n,
			ore_disp_kdag_A, ore_disp_kdag_B,ore_disp_kdag,
			sum (ore_disp_kdag) as ore_disp_kdag_TOT,
			sum (ore_disp_kdag_A) as ore_disp_kdag_ATOT,
			sum (ore_disp_kdag_B) as ore_disp_kdag_BTOT
		From tot_farinello
			group by 1,2
	;
quit;

proc sql;
	create table finale as
		select a.*,b. ore_disp_kdag, b.'4ZECOGEOSAS01_ENTITA'n, b.ore_disp_kdag_A, b.ore_disp_kdag_B
			from ZECOGEOSAS02 as a left join tot_farinello2 as b
				on a.'0CALMONTH2'n=b.'0CALMONTH2'n and a.'0CALYEAR'n=b.'0CALYEAR'n and 
				a.'4ZECOGEOSAS01_ENTITA'n=b.'4ZECOGEOSAS01_ENTITA'n
	;
quit;

proc sql;
	create table finale2 as 
		select a.*, b.'4ZECOGEOKG_CONSUMO_SODA'n,b.'4ZECOGEOKG_PLANT'n
			from finale as a left join datafile.zecogeokg as b 
				on upcase(a.ENTITA_FARINELLO)=tranwrd(trim(compbl(b.'4ZECOGEOKG_PLANT'n))," ","_")
	;
quit;

data finale3;
	set finale2;
	length SODA_A SODA_B 8.;
	format SODA_A 23.2 SODA_B 23.2;
if '4ZECOGEOKG_CONSUMO_SODA'n=. then delete;
	if '4ZECOGEOSAS01_ENTITA'n in ("Farinello A" "Farinello B") then
		do;
			SODA_A=(('4ZECOGEOKG_CONSUMO_SODA'n*ore_disp_kdag_A)/ ore_disp_kdag);
			SODA_B =(('4ZECOGEOKG_CONSUMO_SODA'n*ore_disp_kdag_B)/ ore_disp_kdag);
		end;
run;

data DM_MENSILE_CGTE (keep=
	anno_mese
	entita
	anno
	mese
	primo_gg_mese
	ore_mese
	ore_indisp_gruppo
	ore_dispon_gruppo
	ore_indisp_centrale
	ore_dispon_centrale
	ore_indisp_amis
	ore_disp_amis
	ore_indisp_amis_gruppo
	ore_dispo_amis_gruppo
	ore_indisp_cause_esterne
	num_blocchi_amis
	kdag_numeratore
	kg_consumo_soda
	num_fs_gruppo
	num_fs_amis
	SODA_A
	SODA_B
	ENTITA_FARINELLO
	);
	set finale3;
	length 
		anno_mese $11. 
		entita $150.;
	format 
		anno_mese $7. 
		entita $100.
		anno 11.
		mese 4.  
		primo_gg_mese DATE10.
		ore_mese 6. 
		ore_indisp_gruppo 12.2
		ore_dispon_gruppo 12.2
		ore_indisp_centrale 12.2 
		ore_dispon_centrale 12.2 
		ore_indisp_amis 12.2 
		ore_disp_amis 12.2
		ore_indisp_amis_gruppo 12.2 
		ore_dispo_amis_gruppo 12.2
		ore_indisp_cause_esterne 12.2
		num_blocchi_amis 20.
		num_fs_gruppo 20. 
		num_fs_amis 20.
		kdag_numeratore 19.2
	    kg_consumo_soda 23.2
		ENTITA_FARINELLO $150.
	;
	label 
		anno_mese = anoo_mese
		entita = entita
		anno = anno
		mese = mese
		primo_gg_mese = primo_gg_mese
		ore_mese = ore_mese
		ore_indisp_gruppo = ore_indisp_gruppo
		ore_dispon_gruppo = ore_dispon_gruppo
		ore_indisp_centrale = ore_indisp_centrale
		ore_dispon_centrale = ore_dispon_centrale
		ore_indisp_amis = ore_indisp_amis
		ore_disp_amis = ore_disp_amis
		ore_indisp_amis_gruppo = ore_indisp_amis_gruppo
		ore_dispo_amis_gruppo = ore_dispo_amis_gruppo
		ore_indisp_cause_esterne = ore_indisp_cause_esterne
		num_blocchi_amis = num_blocchi_amis
		kdag_numeratore = kdag_numeratore
		kg_consumo_soda = kg_consumo_soda
		num_fs_gruppo = num_fs_gruppo
		num_fs_amis = num_fs_amis
	;
	anno_mese =cats('0CALYEAR'n,'-','0CALMONTH2'n);
	entita =left('4ZECOGEOSAS01_ENTITA'n);

	/*'4ZECOGEOSAS01_ENTITA'=upcase('4ZECOGEOSAS01_IMPIANTO');
	'4ZECOGEOSAS01_ENTITA'=upcase('2FZEOPGEOPLANT');*/
	anno =input('0CALYEAR'n, $12.);
	mese =input('0CALMONTH2'n, $6.);
	primo_gg_mese =input('0CALDAY'n, yymmdd8.);
	ore_mese = '4ZECOGEOSAS01_ORE_MESE'n;
	ore_indisp_gruppo ='4ZECOGEOSAS01_ORE_IND_GR'n;
	ore_dispon_gruppo ='4ZECOGEOSAS01_ORE_DISP_GR'n;
	ore_indisp_centrale ='4ZECOGEOSAS01_ORE_IND_CEN'n;
	ore_dispon_centrale ='4ZECOGEOSAS01_ORE_DISP_CEN'n;
	ore_indisp_amis ='4ZECOGEOSAS01_ORE_IND_AMIS'n;
	ore_disp_amis ='4ZECOGEOSAS01_ORE_DISP_AMI'n;
	ore_indisp_amis_gruppo ='4ZECOGEOSAS01_ORE_DISP_AMI'n;
	ore_dispo_amis_gruppo ='4ZECOGEOSAS01_ORE_DISP_A_0'n;
	ore_indisp_cause_esterne = '4ZECOGEOSAS01_ORE_IND_EXT'n;
	num_blocchi_amis = '4ZECOGEOSAS01_NUM_BL_AMIS'n;
	kdag_numeratore = '4ZECOGEOSAS01_KDAG_NUMERAT'n;
	num_fs_gruppo ='4ZECOGEOSAS01_NUM_FS_GRU'n;
	num_fs_amis ='4ZECOGEOSAS01_NUM_FS_GR_AM'n;
	kg_consumo_soda='4ZECOGEOKG_CONSUMO_SODA'n;
run;

/*NOTE:
Regarding the following varibles we haven't found a match 
with the ones of datasets (ZECOGEOKG, ZECOGEOSAS01)
ore_sfioro
fluido_sfiorato
ore_fs_maggiori_1ora
potenza_nominale_mw
potenza_media_mensile_lorda_mw
netta_metering_gwh
ore_di_funzionamento
ore_fuoriservizio_centrale
ore_sfioro_0001
t_fluido_sfiorato
tot_fluido_geo_ingresso_t
temp_media_ingresso_reattore
delta_t_media_del_reattore
varianza_delta_t
temp_max_bypass_amis_scar_emer */

/