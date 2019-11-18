/*
Objective
---------
By analyzing the data on median estimated values of single family homes by zip codes from 
the past two decades (https://drive.google.com/file/d/1rydAepWim_Pi0Krh1-RoJjJjDKwc4Gpv/view)
help a company make more informed decisions on real estate investments. 
*/

/*
The examined database contains 4.204.924 rows thereby 175.096 housing prices are missing
affecting 47 of 51 states. ND is the most severe case with no data between 1996 and 2005.
*/ 
SELECT state, COUNT(*)
FROM realestate
WHERE value IS NULL;
-- 
SELECT state, COUNT(*)
FROM realestate
WHERE value IS NULL
GROUP BY state;

-- There are 15,452 distinct zip-codes 
SELECT COUNT(DISTINCT zip_code)
FROM realestate;

-- distributed between 51 states
SELECT state, COUNT(DISTINCT zip_code) as N_zip_codes
FROM realestate
GROUP BY 1
ORDER BY 2 DESC;
-- CA has 1.230 zip-codes; DA only 18

--The historical data is available for 23 years: from 1996 to 2018
SELECT DISTINCT substr(date, 1, 4)
FROM realestate;

-- For the most recent month of the data available (2018-11) 
-- a) what is the range of estimated home values across the nation? 
SELECT date, MAX(value) as Max_Price, MIN(value) as Min_Price, MAX(value)-MIN(value) as Range
FROM realestate
GROUP BY 1
HAVING date = '2018-11';
-- date: 2018-11	price_range: 17.736.200

-- b) the largest price in 2018-11 was in New York City (17.757.800)
SELECT date, state, city, MAX(value)
FROM realestate
GROUP BY 1
HAVING date = '2018-11';

-- c) the smallest price in 2018-11 was in Milan, MO (21.600)
SELECT date, state, city, MIN(value)
FROM realestate
GROUP BY 1
HAVING date = '2018-11';

-- d) which states in 2018-11 had the highest average home values? How about the lowest?
SELECT date, state, ROUND(AVG(value),2) as Mean_Price
FROM realestate
GROUP BY 1, 2
HAVING date = '2018-11'
ORDER BY 3 DESC;
-- 3 states with the highest values: DC($826.6K), CA($751.0K), HI($711.1K)
-- 3 states with the lowest values: OK($121.5K), MS($123.1K), WV($124.0K)
-- see figure 'MeanPrice_vs_State_2018_11.png' for the whole distribution

-- How the highest average home values changed over years? 
-- What were the respective states? 
WITH tmp 
AS	(
	SELECT substr(date, 1, 4) AS Year, state, ROUND(AVG(value),2) as Average
	FROM realestate
	GROUP BY 1, 2
	)
SELECT Year, state, MAX(Average) as Highest_Mean_Price
FROM tmp
GROUP BY Year;
/* 
The highest averaged price increased from 1996 to 2006. Then there was a drop between 2006 and 2011.
The prices started increasing again from 2011 (see figure 'HighestMeanPrice_vs_Year_1.png').
Among the leaders are HI(1996,1997,2007), CA(1998-2006) and DC(2008-2018).
*/
 
-- How the lowest average home values changed over years? 
-- What were the respective states? 
WITH tmp 
AS	(
	SELECT substr(date, 1, 4) AS Year, state, ROUND(AVG(value),2) as Average
	FROM realestate
	GROUP BY 1, 2
	)
SELECT Year, state, MIN(Average) as Lowest_Mean_Price
FROM tmp
GROUP BY Year;
/* 
Figure 'LowestMeanPrice_vs_Year_1.png' shows how the lowest average price varied over years.
For the whole time period Oklahoma had the lowest average prices ('LowestMeanPrice_vs_Year_1.png') 
*/

-- The following query will be used to study percent changes (PC) 
WITH tmp 
AS	(
	SELECT substr(date, 1, 4) AS Year, state, ROUND(AVG(value),2) as MeanPrc
	FROM realestate
	GROUP BY 1, 2
	)
SELECT A.Year, A.state, A.MeanPrc as MeanCurr, B.MeanPrc as MeanPrev, Round((A.MeanPrc-B.MeanPrc)/B.MeanPrc*100.0, 2) as Percent_Change
FROM tmp A, tmp B
WHERE CAST(A.Year as INTEGER) = CAST(B.Year+1 as INTEGER) AND A.state = B.state
ORDER by 2,1;

-- How much have the mean home prices increased (in %) by state for the whole period? 
WITH tmp 
AS	(
	SELECT substr(date, 1, 4) AS Year, state, ROUND(AVG(value),2) as MeanPrc
	FROM realestate
	GROUP BY 1, 2
	),
tmp1 
AS	(
	SELECT A.Year, A.state, (A.MeanPrc-B.MeanPrc)/B.MeanPrc*100.0 as Percent_Change
	FROM tmp A, tmp B
	WHERE CAST(A.Year as INTEGER) = CAST(B.Year+1 as INTEGER) AND A.state = B.state
	)
SELECT tmp1.state, SUM(tmp1.Percent_Change) as 'Mean_Price_Growth_1996-2018(%)'
FROM tmp1
GROUP BY 1
HAVING tmp1.state != 'ND'
ORDER BY 2 DESC;
-- In 13 states the mean home prices have grown by more than 100%: in DC by 156%, followed by CA(144%) and SD(135%) 
-- see figure 'Price_growth_vs_State_allyears.png'

-- What were the smallest percent changes in all states?
WITH tmp 
AS	(
	SELECT substr(date, 1, 4) AS Year, state, ROUND(AVG(value),2) as MeanPrc
	FROM realestate
	GROUP BY 1, 2
	),
tmp1 
AS	(
	SELECT A.Year, A.state, (A.MeanPrc-B.MeanPrc)/B.MeanPrc*100.0 as Percent_Change
	FROM tmp A, tmp B
	WHERE CAST(A.Year as INTEGER) = CAST(B.Year+1 as INTEGER) AND A.state = B.state
	)
SELECT tmp1.state, tmp1.Year, MIN(tmp1.Percent_Change) as Smallest_Percent_Changes
FROM tmp1
GROUP BY 1
HAVING tmp1.state != 'ND'
ORDER BY 3 ;
-- except for AK they are all negative: in NV the housing prices once droped by 22% (in 2009)
-- see figure 'Smallest_percent_changes_vs_State.png' for more detail

-- When states experienced their smallest percent changes?
WITH tmp 
AS	(
	SELECT substr(date, 1, 4) AS Year, state, ROUND(AVG(value),2) as MeanPrc
	FROM realestate
	GROUP BY 1, 2
	),
tmp1 
AS	(
	SELECT A.Year, A.state, (A.MeanPrc-B.MeanPrc)/B.MeanPrc*100.0 as Percent_Change
	FROM tmp A, tmp B
	WHERE CAST(A.Year as INTEGER) = CAST(B.Year+1 as INTEGER) AND A.state = B.state
	),
tmp2
AS	(
	SELECT tmp1.state, tmp1.Year, MIN(tmp1.Percent_Change) as Smst_Percent_Change
	FROM tmp1
	GROUP BY 1
	HAVING tmp1.state != 'ND'
	)
SELECT tmp2.Year, COUNT(*) as 'States_with_smallest_PC'
FROM tmp2
GROUP BY 1;
--  4 states had their minimal percent changes in 2008
-- 24 states in 2009
--  7 states in 2010
-- 14 states in 2011. These are 49 states
 
-- What were the largest percent changes in all states?
WITH tmp 
AS	(
	SELECT substr(date, 1, 4) AS Year, state, ROUND(AVG(value),2) as MeanPrc
	FROM realestate
	GROUP BY 1, 2
	),
tmp1 
AS	(
	SELECT A.Year, A.state, (A.MeanPrc-B.MeanPrc)/B.MeanPrc*100.0 as Percent_Change
	FROM tmp A, tmp B
	WHERE CAST(A.Year as INTEGER) = CAST(B.Year+1 as INTEGER) AND A.state = B.state
	)
SELECT tmp1.state, tmp1.Year, MAX(tmp1.Percent_Change) as Largest_Percent_Changes
FROM tmp1
GROUP BY 1
HAVING tmp1.state != 'ND'
ORDER BY 3 DESC ;
-- most states had their largest percent changes between 1998 and 2006
-- in 2005 the mean hausing prices have grown in AZ by 33% !!!, NV in 2004 by 30.3%, 
-- HI in 2004 by 30% (see 'Largest_percent_changes_vs_State.png' for more detail) 
-- 6 states had their largest PC between 2016 and 2018 (TX, OH, OK, MO, KY, IN: 6-9%)

-- During the last 5 years (2014-2018) the mean housing prices increased everywhere ...
-- see figure 'Price_growth_vs_State_last5years.png'
WITH tmp 
AS	(
	SELECT substr(date, 1, 4) AS Year, state, ROUND(AVG(value),2) as MeanPrc
	FROM realestate
	GROUP BY 1, 2
	),
tmp1 
AS	(
	SELECT A.Year, A.state, (A.MeanPrc-B.MeanPrc)/B.MeanPrc*100.0 as Percent_Change
	FROM tmp A, tmp B
	WHERE CAST(A.Year as INTEGER) = CAST(B.Year+1 as INTEGER) AND A.state = B.state
	)
SELECT tmp1.state, SUM(tmp1.Percent_Change) as 'Growth_Mean_Price_2014-2018(%)'
FROM tmp1
WHERE CAST(tmp1.Year as INTEGER) > 2013
GROUP BY 1
HAVING tmp1.state != 'ND'
ORDER BY 2 DESC;
-- the best states for making real estate investments are NV (49.7%), WA(49%) and FL(45.6%)

/*
By joining the real estate prices with the census data 
https://docs.google.com/spreadsheets/d/1NAgjKKhdGrvwwlc0aoH4JvjrScsytst0g_cVCsdX0Jk/edit#gid=1774413306
one can find correlation between mean income and mean housing prices. 
The scatter plot represented in figure 'Income_vs_Price_2018.png' also reveals three outliers (DC, CA, HI) 
with clearly overpriced housing prices
*/
SELECT substr(realestate.date, 1, 4) AS Year, realestate.state as state, ROUND(AVG(realestate.value),2) as Mean_Price, ROUND(AVG(census_data.median_household_income),2) as Mean_Income
FROM realestate
JOIN census_data ON  realestate.zip_code=census_data.zip_code
GROUP BY 1,2
HAVING CAST(Year as INTEGER) = 2018;

/*
In contrast, no correlation exists between population and housing prices
as seen from figure 'Pop_vs_Price_2018.png'
*/
SELECT substr(realestate.date, 1, 4) AS Year, realestate.state as state, ROUND(AVG(realestate.value),2) as Mean_Price, ROUND(SUM(census_data.pop_total),2) as Pop_Total
FROM realestate
JOIN census_data ON  realestate.zip_code=census_data.zip_code
GROUP BY 1,2
HAVING CAST(Year as INTEGER) = 2018;