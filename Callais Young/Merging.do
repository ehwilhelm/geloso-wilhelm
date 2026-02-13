*****************************************
clear all

*** Merging


*PWT
clear all
import excel "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\StataReady\PWT.xlsx", sheet("Data") firstrow
egen countrynum = group(country)
tsset countrynum year
gen gdppc = rgdpe/pop
gen gdppc2 = gdppc*gdppc
gen lngdppc = ln(gdppc)
gen gdppc_5growth = lngdppc - L5.lngdppc
replace country = "Bolivia" if country == "Bolivia (Plurinational State of)"
replace country = "Congo, Dem. Rep." if country == "D.R. of the Congo"
replace country = "Congo, Rep." if country == "Congo"
replace country = "Cote d'Ivoire" if country == "Côte d'Ivoire"
replace country = "Curacao" if country == "Curaçao"
replace country = "Hong Kong" if country == "China, Hong Kong SAR"
replace country = "Iran" if country == "Iran (Islamic Republic of)"
replace country = "South Korea" if country == "Republic of Korea"
replace country = "Laos" if country == "Lao People's DR"
replace country = "Macao" if country == "China, Macao SAR"
replace country = "Moldova" if country == "Republic of Moldova"
replace country = "Russia" if country == "Russian Federation"
replace country = "St. Kitts and Nevis" if country == "Saint Kitts and Nevis"
replace country = "St. Lucia" if country == "Saint Lucia"
replace country = "Syria" if country == "Syrian Arab Republic"
replace country = "Tanzania" if country == "U.R. of Tanzania: Mainland"
replace country = "Venezuela" if country == "Venezuela (Bolivarian Republic of)"
replace country = "Vietnam" if country == "Viet Nam"
keep if year == 1970 | year == 1975 | year == 1980 | year == 1985 | year == 1990 | year == 1995 | year == 2000 | year == 2005 | year == 2010 | year == 2015
save "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\PWT.dta" , replace

*EFW
clear all
import excel "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\StataReady\EFW.xlsx", sheet("EFW  Panel Data 2021 Report") firstrow
rename Year year
rename Countries country
order country year
sort country year
drop ISO_Code

replace country = "Egypt" if country == "Egypt, Arab Rep."
replace country = "Bahamas" if country == "Bahamas, The"
replace country = "Gambia" if country == "Gambia, The"
replace country = "Hong Kong" if country == "Hong Kong SAR, China"
replace country = "Iran" if country == "Iran, Islamic Rep."
replace country = "South Korea" if country == "Korea, Rep."
replace country = "Kyrgyzstan" if country == "Kyrgyz Republic"
replace country = "Laos" if country == "Lao PDR"
replace country = "Russia" if country == "Russian Federation"
replace country = "Slovakia" if country == "Slovak Republic"
replace country = "Syria" if country == "Syrian Arab Republic"
replace country = "Venezuela" if country == "Venezuela, RB"
replace country = "Yemen" if country == "Yemen, Rep."

keep if year == 1970 | year == 1975 | year == 1980 | year == 1985 | year == 1990 | year == 1995 | year == 2000 | year == 2005 | year == 2010 | year == 2015


save "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\EFW.dta" , replace


*Fertility
clear all
import excel "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\StataReady\FertilityRate.xls", sheet("Data") firstrow

reshape long y, i(CountryName) j(year)
rename y fertilrate
rename CountryName country
replace country = "Bahamas" if country == "Bahamas, The"
replace country = "Egypt" if country == "Egypt, Arab Rep."
replace country = "Gambia" if country == "Gambia, The"
replace country = "Hong Kong" if country == "Hong Kong SAR, China"
replace country = "Iran" if country == "Iran, Islamic Rep."
replace country = "South Korea" if country == "Korea, Rep."
replace country = "Kyrgyzstan" if country == "Kyrgyz Republic"
replace country = "Macao" if country == "Macao SAR, China"
replace country = "Russia" if country == "Russian Federation"
replace country = "Slovakia" if country == "Slovak Republic"
replace country = "Syria" if country == "Syrian Arab Republic"
replace country = "Venezuela" if country == "Venezuela, RB"
replace country = "Yemen" if country == "Yemen, Rep."
replace country = "Laos" if country == "Lao PDR"
keep if year == 1970 | year == 1975 | year == 1980 | year == 1985 | year == 1990 | year == 1995 | year == 2000 | year == 2005 | year == 2010 | year == 2015

save "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\Fertility.dta" , replace


*Literacy
clear all
import excel "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\StataReady\LiteracyRate.xls", sheet("Data") firstrow

reshape long y, i(CountryName) j(year)
rename y litrate
rename CountryName country
replace country = "Bahamas" if country == "Bahamas, The"
replace country = "Egypt" if country == "Egypt, Arab Rep."
replace country = "Gambia" if country == "Gambia, The"
replace country = "Hong Kong" if country == "Hong Kong SAR, China"
replace country = "Iran" if country == "Iran, Islamic Rep."
replace country = "South Korea" if country == "Korea, Rep."
replace country = "Kyrgyzstan" if country == "Kyrgyz Republic"
replace country = "Macao" if country == "Macao SAR, China"
replace country = "Russia" if country == "Russian Federation"
replace country = "Slovakia" if country == "Slovak Republic"
replace country = "Syria" if country == "Syrian Arab Republic"
replace country = "Venezuela" if country == "Venezuela, RB"
replace country = "Yemen" if country == "Yemen, Rep."
replace country = "Laos" if country == "Lao PDR"
keep if year == 1970 | year == 1975 | year == 1980 | year == 1985 | year == 1990 | year == 1995 | year == 2000 | year == 2005 | year == 2010 | year == 2015

save "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\LitRate.dta" , replace


*Old Age Dependency
clear all
import excel "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\StataReady\OldAgeDependency.xls", sheet("Data") firstrow

reshape long y, i(CountryName) j(year)
rename y oldagedep
rename CountryName country
replace country = "Bahamas" if country == "Bahamas, The"
replace country = "Egypt" if country == "Egypt, Arab Rep."
replace country = "Gambia" if country == "Gambia, The"
replace country = "Hong Kong" if country == "Hong Kong SAR, China"
replace country = "Iran" if country == "Iran, Islamic Rep."
replace country = "South Korea" if country == "Korea, Rep."
replace country = "Kyrgyzstan" if country == "Kyrgyz Republic"
replace country = "Macao" if country == "Macao SAR, China"
replace country = "Russia" if country == "Russian Federation"
replace country = "Slovakia" if country == "Slovak Republic"
replace country = "Syria" if country == "Syrian Arab Republic"
replace country = "Venezuela" if country == "Venezuela, RB"
replace country = "Yemen" if country == "Yemen, Rep."
replace country = "Laos" if country == "Lao PDR"
keep if year == 1970 | year == 1975 | year == 1980 | year == 1985 | year == 1990 | year == 1995 | year == 2000 | year == 2005 | year == 2010 | year == 2015

save "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\OldAgeDepend.dta" , replace


*Polity
clear all
import excel "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\StataReady\Polity.xls", sheet("p5v2018") firstrow

replace country = "Bosnia and Herzegovina" if country == "Bosnia"
replace country = "Cabo Verde" if country == "Cape Verde"
replace country = "Congo, Dem. Rep." if country == "Congo Kinshasa"
replace country = "Congo, Rep." if country == "Congo-Brazzaville"
replace country = "Cote d'Ivoire" if country == "Cote D'Ivoire"
replace country = "Eswatini" if country == "Swaziland"
replace country = "South Korea" if country == "Korea South"
replace country = "Myanmar" if country == "Myanmar (Burma)"
replace country = "North Macedonia" if country == "Macedonia"
replace country = "Slovakia" if country == "Slovak Republic"
replace country = "United Arab Emirates" if country == "UAE"

keep if year == 1970 | year == 1975 | year == 1980 | year == 1985 | year == 1990 | year == 1995 | year == 2000 | year == 2005 | year == 2010 | year == 2015
save "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\polity.dta" , replace

*Urban Share Pop

clear all
import excel "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\StataReady\UrbanPopShare.xls", sheet("Data") firstrow

reshape long y, i(CountryName) j(year)
rename y urbanpop
rename CountryName country
replace country = "Bahamas" if country == "Bahamas, The"
replace country = "Egypt" if country == "Egypt, Arab Rep."
replace country = "Gambia" if country == "Gambia, The"
replace country = "Hong Kong" if country == "Hong Kong SAR, China"
replace country = "Iran" if country == "Iran, Islamic Rep."
replace country = "South Korea" if country == "Korea, Rep."
replace country = "Kyrgyzstan" if country == "Kyrgyz Republic"
replace country = "Macao" if country == "Macao SAR, China"
replace country = "Russia" if country == "Russian Federation"
replace country = "Slovakia" if country == "Slovak Republic"
replace country = "Syria" if country == "Syrian Arab Republic"
replace country = "Venezuela" if country == "Venezuela, RB"
replace country = "Yemen" if country == "Yemen, Rep."
replace country = "Laos" if country == "Lao PDR"
keep if year == 1970 | year == 1975 | year == 1980 | year == 1985 | year == 1990 | year == 1995 | year == 2000 | year == 2005 | year == 2010 | year == 2015

save "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\UrbanPop.dta" , replace


*Decile Shares
clear all
import delimited "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\StataReady\DecileShares.csv"
keep if year == 1970 | year == 1975 | year == 1980 | year == 1985 | year == 1990 | year == 1995 | year == 2000 | year == 2005 | year == 2010 | year == 2015

replace country = "Bahamas" if country == "Bahamas, The"
replace country = "Hong Kong" if country == "Hong Kong SAR, China"
replace country = "South Korea" if country == "Korea, Rep."
replace country = "Kyrgyzstan" if country == "Kyrgyz Republic"
replace country = "Russia" if country == "Russian Federation"
replace country = "Slovakia" if country == "Slovak Republic"
replace country = "Syria" if country == "Syrian Arab Republic"
replace country = "Laos" if country == "Lao"
replace country = "North Macedonia" if country == "Macedonia, FYR"
replace country = "Eswatini" if country == "Swaziland"


save "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\DecileShare.dta" , replace




*SWIID
clear all
import delimited "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\StataReady\SWIID_92.csv"
keep if year == 1970 | year == 1975 | year == 1980 | year == 1985 | year == 1990 | year == 1995 | year == 2000 | year == 2005 | year == 2010 | year == 2015

replace country = "Cabo Verde" if country == "Cape Verde"
replace country = "Congo, Rep." if country == "Congo-Brazzaville"
replace country = "Congo, Dem. Rep." if country == "Congo-Kinshasa"
replace country = "Cote d'Ivoire" if country == "CÃ´te d'Ivoire"
replace country = "South Korea" if country == "Korea"
replace country = "Sao Tome and Principe" if country == "SÃ£o TomÃ© and PrÃ­ncipe"


save "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\SWIID.dta" , replace


*Secondary Gross
clear all

import excel "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\StataReady\SecondaryGross.xls", sheet("Data") firstrow

reshape long y, i(CountryName) j(year)
rename y secondaryed
rename CountryName country
replace country = "Bahamas" if country == "Bahamas, The"
replace country = "Egypt" if country == "Egypt, Arab Rep."
replace country = "Gambia" if country == "Gambia, The"
replace country = "Hong Kong" if country == "Hong Kong SAR, China"
replace country = "Iran" if country == "Iran, Islamic Rep."
replace country = "South Korea" if country == "Korea, Rep."
replace country = "Kyrgyzstan" if country == "Kyrgyz Republic"
replace country = "Macao" if country == "Macao SAR, China"
replace country = "Russia" if country == "Russian Federation"
replace country = "Slovakia" if country == "Slovak Republic"
replace country = "Syria" if country == "Syrian Arab Republic"
replace country = "Venezuela" if country == "Venezuela, RB"
replace country = "Yemen" if country == "Yemen, Rep."
replace country = "Laos" if country == "Lao PDR"
keep if year == 1970 | year == 1975 | year == 1980 | year == 1985 | year == 1990 | year == 1995 | year == 2000 | year == 2005 | year == 2010 | year == 2015

save "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\secondaryed.dta" , replace



*Primary Gross

clear all

import excel "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\StataReady\PrimaryGross.xls", sheet("Data") firstrow

reshape long y, i(CountryName) j(year)
rename y primaryed
rename CountryName country
replace country = "Bahamas" if country == "Bahamas, The"
replace country = "Egypt" if country == "Egypt, Arab Rep."
replace country = "Gambia" if country == "Gambia, The"
replace country = "Hong Kong" if country == "Hong Kong SAR, China"
replace country = "Iran" if country == "Iran, Islamic Rep."
replace country = "South Korea" if country == "Korea, Rep."
replace country = "Kyrgyzstan" if country == "Kyrgyz Republic"
replace country = "Macao" if country == "Macao SAR, China"
replace country = "Russia" if country == "Russian Federation"
replace country = "Slovakia" if country == "Slovak Republic"
replace country = "Syria" if country == "Syrian Arab Republic"
replace country = "Venezuela" if country == "Venezuela, RB"
replace country = "Yemen" if country == "Yemen, Rep."
replace country = "Laos" if country == "Lao PDR"
keep if year == 1970 | year == 1975 | year == 1980 | year == 1985 | year == 1990 | year == 1995 | year == 2000 | year == 2005 | year == 2010 | year == 2015

save "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\primaryed.dta" , replace



*merge
clear all
use "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\PWT.dta" , clear
merge m:m country year using "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\EFW.dta"
drop if _merge == 2
drop _merge

merge m:m country year using "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\Fertility.dta"
drop if _merge == 2
drop _merge

merge m:m country year using "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\LitRate.dta"
drop if _merge == 2
drop _merge

merge m:m country year using "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\OldAgeDepend.dta"
drop if _merge == 2
drop _merge

merge m:m country year using "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\polity.dta"
drop if _merge == 2
drop _merge

merge m:m country year using "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\UrbanPop.dta"
drop if _merge == 2
drop _merge

merge m:m country year using "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\DecileShare.dta"
drop if _merge == 2
drop _merge

merge m:m country year using "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\SWIID.dta"
drop if _merge == 2
drop _merge

merge m:m country year using "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\primaryed.dta"
drop if _merge == 2
drop _merge

merge m:m country year using "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\secondaryed.dta"
drop if _merge == 2
drop _merge

gen totalpop = 1000000*pop
gen totalGDP = rgdpe*1000000

gen inc_10 = (totalGDP*share10)/(0.1*totalpop)
gen inc_9 = (totalGDP*share9)/(0.1*totalpop)
gen inc_8 = (totalGDP*share8)/(0.1*totalpop)
gen inc_7 = (totalGDP*share7)/(0.1*totalpop)
gen inc_6 = (totalGDP*share6)/(0.1*totalpop)
gen inc_5 = (totalGDP*share5)/(0.1*totalpop)
gen inc_4 = (totalGDP*share4)/(0.1*totalpop)
gen inc_3 = (totalGDP*share3)/(0.1*totalpop)
gen inc_2 = (totalGDP*share2)/(0.1*totalpop)
gen inc_1 = (totalGDP*share1)/(0.1*totalpop)

gen inc_top5 = (totalGDP*sharetop5)/(0.05*totalpop)
gen inc_top1 = (totalGDP*sharetop1)/(0.01*totalpop)

sort countrynum year
gen EFWdiff = Summary - L5.Summary
gen EFWjump = 1 if EFWdiff > 1
replace EFWjump = 0 if EFWjump == .
replace EFWjump = . if EFWdiff == .
replace EFWjump = . if L5.EFWjump == 1
replace EFWjump = . if L10.EFWjump == 1
replace EFWjump = . if F5.EFWjump == 1

replace EFWjump = . if country == "Venezuela" & year == 2000
	*not sustained

	
*** Smaller jumps

gen EFW_smallerjump = 1 if EFWdiff > 0.75
replace EFW_smallerjump = 0 if EFW_smallerjump == .
replace EFW_smallerjump = . if EFWdiff == .
replace EFW_smallerjump = . if L5.EFWjump == 1
replace EFW_smallerjump = . if L10.EFWjump == 1
replace EFW_smallerjump = . if F5.EFWjump == 1

replace EFW_smallerjump = . if country == "Venezuela" & year == 2000
	*not sustained
	

*** Bigger Jumps
gen EFW_biggerjump = 1 if EFWdiff > 1.25
replace EFW_biggerjump = 0 if EFW_biggerjump == .
replace EFW_biggerjump = . if EFWdiff == .
replace EFW_biggerjump = . if L5.EFWjump == 1
replace EFW_biggerjump = . if L10.EFWjump == 1
replace EFW_biggerjump = . if F5.EFWjump == 1

replace EFW_biggerjump = . if country == "Venezuela" & year == 2000
	*not sustained
	
	
	
	

drop if Summary == .
drop if inc_10 == . & gini_disp == .

tab EFWjump	
	*54 cases of sustained jumps

gen lngdppc2 = lngdppc^2



gen lagEFW = L5.Summary
gen laghc = L5.hc
gen laglngdppc = L5.lngdppc
gen laggdpc_5growth = L5.gdppc_5growth
gen laglngdppc2 = L5.lngdppc2
gen lagfertilrate = L5.fertilrate
gen lagoldagedep = L5.oldagedep
gen lagpolity2 = L5.polity2
gen lagurbanpop = L5.urbanpop


gen ln_inc_10 = ln(inc_10)
gen ln_inc_9 = ln(inc_9)
gen ln_inc_8 = ln(inc_8)
gen ln_inc_7 = ln(inc_7)
gen ln_inc_6 = ln(inc_6)
gen ln_inc_5 = ln(inc_5)
gen ln_inc_4 = ln(inc_4)
gen ln_inc_3 = ln(inc_3)
gen ln_inc_2 = ln(inc_2)
gen ln_inc_1 = ln(inc_1)
gen ln_inc_top5 = ln(inc_top5)
gen ln_inc_top1 = ln(inc_top1)



gen lag_inc_10 = L5.ln_inc_10
gen lag_inc_9 = L5.ln_inc_9
gen lag_inc_8 = L5.ln_inc_8
gen lag_inc_7 = L5.ln_inc_7
gen lag_inc_6 = L5.ln_inc_6
gen lag_inc_5 = L5.ln_inc_5
gen lag_inc_4 = L5.ln_inc_4
gen lag_inc_3 = L5.ln_inc_3
gen lag_inc_2 = L5.ln_inc_2
gen lag_inc_1 = L5.ln_inc_1
gen lag_inc_top5 = L5.ln_inc_top5
gen lag_inc_top11 = L5.ln_inc_top1


gen lag_share10 = L5.share10
gen lag_share9 = L5.share9
gen lag_share8 = L5.share8
gen lag_share7 = L5.share7
gen lag_share6 = L5.share6
gen lag_share5 = L5.share5
gen lag_share4 = L5.share4
gen lag_share3 = L5.share3
gen lag_share2 = L5.share2
gen lag_share1 = L5.share1
gen lag_sharetop5 = L5.sharetop5
gen lag_sharetop1 = L5.sharetop1


gen changeshare10_5yr = F5.share10 - share10
gen changeshare9_5yr = F5.share9 - share9
gen changeshare8_5yr = F5.share8 - share8
gen changeshare7_5yr = F5.share7 - share7
gen changeshare6_5yr = F5.share6 - share6
gen changeshare5_5yr = F5.share5 - share5
gen changeshare4_5yr = F5.share4 - share4
gen changeshare3_5yr = F5.share3 - share3
gen changeshare2_5yr = F5.share2 - share2
gen changeshare1_5yr = F5.share1 - share1
gen changesharetop5_5yr = F5.sharetop5 - sharetop5
gen changesharetop1_5yr = F5.sharetop1 - sharetop1

gen change_inc_10_5yr = F5.ln_inc_10 - ln_inc_10
gen change_inc_9_5yr = F5.ln_inc_9 - ln_inc_9
gen change_inc_8_5yr = F5.ln_inc_8 - ln_inc_8
gen change_inc_7_5yr = F5.ln_inc_7 - ln_inc_7
gen change_inc_6_5yr = F5.ln_inc_6 - ln_inc_6
gen change_inc_5_5yr = F5.ln_inc_5 - ln_inc_5
gen change_inc_4_5yr = F5.ln_inc_4 - ln_inc_4
gen change_inc_3_5yr = F5.ln_inc_3 - ln_inc_3
gen change_inc_2_5yr = F5.ln_inc_2 - ln_inc_2
gen change_inc_1_5yr = F5.ln_inc_1 - ln_inc_1
gen change_inc_top5_5yr = F5.ln_inc_top5 - ln_inc_top5
gen change_inc_top1_5yr = F5.ln_inc_top1 - ln_inc_top1


gen change_gini_disp_5yr = F5.gini_disp - gini_disp
gen change_gini_mkt_5yr = F5.gini_mkt - gini_mkt

gen lag_gini_disp = L5.gini_disp
gen lag_gini_mkt = L5.gini_mkt


gen oecd = 1 if country == "Australia"
replace oecd = 1 if country == "Austria"
replace oecd = 1 if country == "Belgium"
replace oecd = 1 if country == "Canada"
replace oecd = 1 if country == "Chile"
replace oecd = 1 if country == "Colombia"
replace oecd = 1 if country == "Costa Rica"
replace oecd = 1 if country == "Czech Republic"
replace oecd = 1 if country == "Denmark"
replace oecd = 1 if country == "Estonia"
replace oecd = 1 if country == "Finland"
replace oecd = 1 if country == "France"
replace oecd = 1 if country == "Germany"
replace oecd = 1 if country == "Greece"
replace oecd = 1 if country == "Hungary"
replace oecd = 1 if country == "Iceland"
replace oecd = 1 if country == "Ireland"
replace oecd = 1 if country == "Israel"
replace oecd = 1 if country == "Italy"
replace oecd = 1 if country == "Japan"
replace oecd = 1 if country == "South Korea"
replace oecd = 1 if country == "Latvia"
replace oecd = 1 if country == "Lithuania"
replace oecd = 1 if country == "Luxembourg"
replace oecd = 1 if country == "Mexico"
replace oecd = 1 if country == "Netherlands"
replace oecd = 1 if country == "New Zealand"
replace oecd = 1 if country == "Norway"
replace oecd = 1 if country == "Poland"
replace oecd = 1 if country == "Portugal"
replace oecd = 1 if country == "Slovakia"
replace oecd = 1 if country == "Slovenia"
replace oecd = 1 if country == "Spain"
replace oecd = 1 if country == "Sweden"
replace oecd = 1 if country == "Switzerland"
replace oecd = 1 if country == "Turkey"
replace oecd = 1 if country == "United Kingdom"
replace oecd = 1 if country == "United States"









save "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\ALLDATA.dta" , replace

use "C:\Users\jcallais\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\ALLDATA.dta" , clear


*UE--> Diff
clear all

import excel "C:\Users\C00535185\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\StataReady\Unemployment_Different.xls", sheet("Data") firstrow


reshape long y, i(CountryName) j(year)
rename y unemployment_different
rename CountryName country
replace country = "Bahamas" if country == "Bahamas, The"
replace country = "Egypt" if country == "Egypt, Arab Rep."
replace country = "Gambia" if country == "Gambia, The"
replace country = "Hong Kong" if country == "Hong Kong SAR, China"
replace country = "Iran" if country == "Iran, Islamic Rep."
replace country = "South Korea" if country == "Korea, Rep."
replace country = "Kyrgyzstan" if country == "Kyrgyz Republic"
replace country = "Macao" if country == "Macao SAR, China"
replace country = "Russia" if country == "Russian Federation"
replace country = "Slovakia" if country == "Slovak Republic"
replace country = "Syria" if country == "Syrian Arab Republic"
replace country = "Venezuela" if country == "Venezuela, RB"
replace country = "Yemen" if country == "Yemen, Rep."
replace country = "Laos" if country == "Lao PDR"

egen countrynum = group(country)
tsset countrynum year

gen ue_5avg_diff = (unemployment_different + L.unemployment_different + LL.unemployment_different + LLL.unemployment_different + LLLL.unemployment_different)/5
replace ue_5avg_diff = (unemployment_different + LL.unemployment_different + LLL.unemployment_different + LLLL.unemployment_different)/4 if L.unemployment_different == .
replace ue_5avg_diff = (unemployment_different + L.unemployment_different + LLL.unemployment_different + LLLL.unemployment_different)/4 if LL.unemployment_different == .
replace ue_5avg_diff = (unemployment_different + L.unemployment_different + LL.unemployment_different + LLLL.unemployment_different)/4 if LLL.unemployment_different == .
replace ue_5avg_diff = (unemployment_different + L.unemployment_different + LLL.unemployment_different + LLL.unemployment_different)/4 if LLLL.unemployment_different == .

replace ue_5avg_diff = (unemployment_different + LLL.unemployment_different + LLLL.unemployment_different)/3 if L.unemployment_different == . & LL.unemployment_different == .
replace ue_5avg_diff = (unemployment_different + LL.unemployment_different + LLLL.unemployment_different)/3 if L.unemployment_different == . & LLL.unemployment_different == .
replace ue_5avg_diff = (unemployment_different + LL.unemployment_different + LLL.unemployment_different)/3 if L.unemployment_different == . & LLLL.unemployment_different == .

replace ue_5avg_diff = (unemployment_different + L.unemployment_different + LL.unemployment_different)/3 if LLL.unemployment_different == . & LLLL.unemployment_different == .
replace ue_5avg_diff = (unemployment_different + L.unemployment_different + LLL.unemployment_different)/3 if LL.unemployment_different == . & LLLL.unemployment_different == .
replace ue_5avg_diff = (unemployment_different + L.unemployment_different + LLLL.unemployment_different)/3 if LL.unemployment_different == . & LLL.unemployment_different == .

replace ue_5avg_diff = (unemployment_different + L.unemployment_different)/2 if LL.unemployment_different == . & LLL.unemployment_different == . & LLLL.unemployment_different == .
replace ue_5avg_diff = (unemployment_different + LL.unemployment_different)/2 if L.unemployment_different == . & LLL.unemployment_different == . & LLLL.unemployment_different == .
replace ue_5avg_diff = (unemployment_different + LLL.unemployment_different)/2 if LL.unemployment_different == . & L.unemployment_different == . & LLLL.unemployment_different == .
replace ue_5avg_diff = (unemployment_different + LLLL.unemployment_different)/2 if LL.unemployment_different == . & LLL.unemployment_different == . & L.unemployment_different == .

replace ue_5avg_diff = (unemployment_different + LL.unemployment_different)/2 if L.unemployment_different == . & LLL.unemployment_different == . & LLLL.unemployment_different == .
replace ue_5avg_diff = (unemployment_different + LLL.unemployment_different)/2 if LL.unemployment_different == . & L.unemployment_different == . & LLLL.unemployment_different == .
replace ue_5avg_diff = (unemployment_different + LLLL.unemployment_different)/2 if LL.unemployment_different == . & LLL.unemployment_different == . & L.unemployment_different == .

replace ue_5avg_diff = unemployment_different if L.unemployment_different == . & LL.unemployment_different == . & LLL.unemployment_different == . & LLLL.unemployment_different == .


keep if year == 1970 | year == 1975 | year == 1980 | year == 1985 | year == 1990 | year == 1995 | year == 2000 | year == 2005 | year == 2010 | year == 2015

drop countrynum

save "C:\Users\C00535185\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\Unemployment_Different.dta" , replace



*UE--> ILO
clear all

import excel "C:\Users\C00535185\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\StataReady\Unemployment_ILOEstimate.xls", sheet("Data") firstrow

reshape long y, i(CountryName) j(year)
rename y unemployment_ILO
rename CountryName country
replace country = "Bahamas" if country == "Bahamas, The"
replace country = "Egypt" if country == "Egypt, Arab Rep."
replace country = "Gambia" if country == "Gambia, The"
replace country = "Hong Kong" if country == "Hong Kong SAR, China"
replace country = "Iran" if country == "Iran, Islamic Rep."
replace country = "South Korea" if country == "Korea, Rep."
replace country = "Kyrgyzstan" if country == "Kyrgyz Republic"
replace country = "Macao" if country == "Macao SAR, China"
replace country = "Russia" if country == "Russian Federation"
replace country = "Slovakia" if country == "Slovak Republic"
replace country = "Syria" if country == "Syrian Arab Republic"
replace country = "Venezuela" if country == "Venezuela, RB"
replace country = "Yemen" if country == "Yemen, Rep."
replace country = "Laos" if country == "Lao PDR"



egen countrynum = group(country)
tsset countrynum year

gen ue_5avg_ILO = (unemployment_ILO + L.unemployment_ILO + LL.unemployment_ILO + LLL.unemployment_ILO + LLLL.unemployment_ILO)/5

keep if year == 1970 | year == 1975 | year == 1980 | year == 1985 | year == 1990 | year == 1995 | year == 2000 | year == 2005 | year == 2010 | year == 2015


drop countrynum

save "C:\Users\C00535185\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\Unemployment_ILO.dta" , replace



*individualism
clear all


import excel "C:\Users\C00535185\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\Trust_Individualism.xlsx", sheet("Sheet1") firstrow

drop trust

replace country = "Trinidad and Tobago" if country == "Trinidad"

replace country = "Burkina Faso" if country == "Burkina"

save "C:\Users\C00535185\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\Individualism.dta" , replace


*corruption
clear all
use "C:\Users\C00535185\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\StataReady\Corruption.dta" , clear


keep if year == 1970 | year == 1975 | year == 1980 | year == 1985 | year == 1990 | year == 1995 | year == 2000 | year == 2005 | year == 2010 | year == 2015


replace country = "Trinidad and Tobago" if country == "Trinidad & Tobago"



save "C:\Users\C00535185\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\Corruption.dta" , replace




*trust
clear all

import excel "C:\Users\C00535185\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\Trust\TRUST_Collected.xlsx", sheet("Sheet1") firstrow

rename Country country

replace country = "Kyrgyzstan" if country == "Kyrgystan"

save "C:\Users\C00535185\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\Trust.dta" , replace





use "C:\Users\C00535185\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\ALLDATA.dta" , clear
merge m:m country year using "C:\Users\C00535185\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\Trust.dta"
drop if _merge == 2
drop _merge

merge m:m country year using "C:\Users\C00535185\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\Corruption.dta"
drop if _merge == 2
drop _merge

merge m:1 country using "C:\Users\C00535185\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\Individualism.dta"
drop if _merge == 2
drop _merge

merge m:m country using "C:\Users\C00535185\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\Unemployment_ILO.dta"
drop if _merge == 2
drop _merge


merge m:m country using "C:\Users\C00535185\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\Unemployment_Different.dta"
drop if _merge == 2
drop _merge

sort countrynum year

gen lague_diff = L5.ue_5avg_diff
gen lague_ilo = L5.ue_5avg_ILO
gen lagcorruption = L5.corruption
gen lagindividualism = L5.individualism
gen lagtrust = L5.trust


save "C:\Users\C00535185\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\ALLDATA_NewVariables.dta" , replace




drop if laghc ==.
drop if laglngdppc == .
drop if laggdpc_5growth == .
drop if laglngdppc2 == .
drop if lagfertilrate == .
drop if lagoldagedep == .
drop if  lagpolity2 == .
drop if  lagurbanpop == .

drop if lagcorruption == .
drop if lagindividualism == .
drop if lagtrust == .



summ Summary share10 share9 share8 share7 share6 share5 share4 share3 share2 share1 sharetop5 sharetop1 
summ inc_10 inc_9 inc_8 inc_7 inc_6 inc_5 inc_4 inc_3 inc_2 inc_1 inc_top5 inc_top1 gini_disp gini_mkt
summ  hc lngdppc gdppc_5growth lngdppc2 fertilrate oldagedep polity2 urbanpop

summ changeshare10_5yr changeshare9_5yr changeshare8_5yr  changeshare7_5yr  changeshare6_5yr  changeshare5_5yr  changeshare4_5yr  changeshare3_5yr  changeshare2_5yr ///
changeshare1_5yr changesharetop5_5yr changesharetop1_5yr 

summ change_inc_10_5yr change_inc_9_5yr  change_inc_8_5yr  change_inc_7_5yr  change_inc_6_5yr  change_inc_5_5yr  change_inc_4_5yr  change_inc_3_5yr  change_inc_2_5yr ///
change_inc_1_5yr change_inc_top5_5yr change_inc_top1_5yr

summ change_gini_disp_5yr change_gini_mkt_5yr



summ Summary inc_10 ue_5avg_diff ue_5avg_ILO corruption individualism trust


*Figure 1
graph twoway (lfit share10 Summary) (scatter share10 Summary)	

graph twoway (lfit share1 Summary) (scatter share1 Summary)	

*Figure 2
graph twoway (lfit ln_inc_10 Summary) (scatter ln_inc_10 Summary)	

graph twoway (lfit ln_inc_1 Summary) (scatter ln_inc_1 Summary)	


*Figure 3
graph twoway (lfit gini_disp Summary) (scatter gini_disp Summary)	

graph twoway (lfit gini_mkt Summary) (scatter gini_mkt Summary)	
