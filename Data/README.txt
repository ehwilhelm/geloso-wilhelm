Data Sources for Merged Database

Goal: Update prior data estimates and append up to 2020-2025 (if available)

Infant Mortality Estimates and Confidence Intervals
United Nations Inter-agency Group for Child Mortality Estimation (UN IGME)

https://data.unicef.org/resources/un-inter-agency-group-for-child-mortality-estimation-unigme/


Economic Freedom of the World
2025 Annual Report

*Likely to have revised historical estimates

	https://www.fraserinstitute.org/studies/economic-freedom-world-2025-annual-report

-------------------------------------------------------------------------------------------------

To be added

Covariates

Go to p. 18 of Callais & Young 2023

Penn World Tables

https://www.rug.nl/ggdc/historicaldevelopment/maddison/releases/maddison-project-database-2023

Polity5

https://ourworldindata.org/grapher/democracy-index-polity

(Remember to cite Our World in Data)
Polity 5 (2020); Population based on various sources (2023) – processed by Our World in Data. “Democracy Index” [dataset]. Polity 5, “Polity5 Project, Political Regime Characteristics and Transitions, 1800–2018 5”; Various sources, “Population” [original data]. Retrieved October 5, 2026 from https://archive.ourworldindata.org/20260909-235947/grapher/democracy-index-polity.html (archived on September 9, 2026).

https://xmarquez.github.io/democracyData/reference/download_polity_annual.html#source

World Bank’s World Development Indicators

https://databank.worldbank.org/source/world-development-indicators

Varieties of Democracy (VDEMS)

	https://www.v-dem.net/data/the-v-dem-dataset/


-------------------------------------------------------------------------------------------------


For periods where overlaps 

World Bank Data on Statistical Capacity (2005-2020)

	https://datacatalog.worldbank.org/search/dataset/0037854/data-on-statistical-capacity

Statistical Performance Indicators (2020?)

	https://www.worldbank.org/en/programs/statistical-performance-indicators/explore-data


-----------------------------------------o-----------------------------------------

1970-2020/2025

Create subfolder under geloso-wilhelm\Data

V-Dems
House large datasets on Box folder
	Share access with Eric

	Pull list of country names from V-Dems
	Write script to merge countries and year with IGME/main database


Scripts and smaller datasets can be stored on GitHub and pushed


Nishant Comments

I couldn't find Hong Kong, Moldova, Taiwan, Tanzania
	Note which databases do not have data for specific countries

South Korea name has been changed to Dem Rep of Korea

I'm confused on which dataset to download for V-Dem Dataset
https://www.v-dem.net/data/the-v-dem-dataset/
All data

Put data on Box folder
Write script that merges country name and year

	Country-Year: V-Dem Full+Others
	All 531 V-Dem indicators and 251 indices + 62 other indicators from other data sources. For R users, we recommend to install our vdem data R package 	which includes the most recent V-Dem dataset and some useful functions to explore the data.



I'm Also not sure on which dataset to download for Statistical Performance Indicators

	SPI is lowest priority
	Data is only available for 2020

	Prioritize Statistical Capacity data for 2005-2020
	https://datacatalog.worldbank.org/search/dataset/0037854/data-on-statistical-capacity



Identify 1-2 examples of different country naming conventions

Clean up name for Turkey in "mergedata.csv"

Rename TÃ¼rkiye as "Türkiye"