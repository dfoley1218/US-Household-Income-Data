-- Let's take a look at our US household income data and see what insights we can find.
-- First, let's start with data cleaning.


SELECT * 
FROM us_project.us_household_income
;


SELECT * 
FROM us_project.us_household_income_statistics
;


-- Looks like this ID column didn't import properly. Let's fix that.

ALTER TABLE 
us_project.us_household_income_statistics
RENAME COLUMN `ï»¿id` TO `ID`
;

-- Let's start to check for duplicates

SELECT ID, COUNT(ID)
FROM us_project.us_household_income
GROUP BY ID
HAVING COUNT(ID) > 1
;

-- Looks like we have 6 duplicates. Let's remove those

SELECT row_id,
id,
ROW_NUMBER() OVER( PARTITION BY id ORDER BY id)
FROM us_household_income
;


SELECT *
FROM
(
SELECT row_id,
id,
ROW_NUMBER() OVER( PARTITION BY id ORDER BY id) as row_num
FROM us_household_income
) as Duplicates
WHERE row_num  > 1
;

-- great, we've found the row IDs with duplicates. Let's delete them.


DELETE FROM us_household_income
WHERE row_id IN (
		SELECT row_id
		FROM
		(
			SELECT row_id,
			id,
			ROW_NUMBER() OVER( PARTITION BY id ORDER BY id) as row_num
			FROM us_household_income
			) as Duplicates
WHERE row_num  > 1
)
;


-- Great! Now let's do the exact same thing for the other table. 


SELECT ID, COUNT(ID)
FROM us_household_income_statistics
GROUP BY ID
HAVING COUNT(ID) > 1
;

-- No duplicates were found.
-- We did notice in our first look at the data that some of the state names were wrong. Let's fix those now.

SELECT State_name, COUNT(State_name)
FROM us_project.us_household_income
GROUP BY State_name
;

SELECT DISTINCT(State_name)
FROM us_project.us_household_income
GROUP BY State_name
;

-- Let's fix those incorrect state names

UPDATE us_project.us_household_income
SET State_Name = 'Georgia'
WHERE State_name = 'georia'
;

UPDATE us_project.us_household_income
SET State_Name = 'Alabama'
WHERE State_name = 'alabama'
;

-- Now let's do the same thing for state abbreviations

SELECT DISTINCT(State_ab)
FROM us_project.us_household_income
GROUP BY State_ab
;

-- These look good. Now, we found a "place" that was not filled in. Let's fix that, too.

SELECT *
FROM us_project.us_household_income
Where Place = ''
;

SELECT *
FROM us_project.us_household_income
Where County = 'Autauga County'
ORDER BY 1
;

UPDATE us_household_income
SET Place = 'Autaugaville'
WHERE County = 'Autauga County'
AND City = 'Vinemont'
;

-- Now let's check the "type" column to check for duplicates or errors

SELECT Type, COUNT(type)
FROM us_household_income
GROUP BY type
;

-- Looks like "Boroughs" needs to be in "Borough"

UPDATE us_household_income
SET Type = 'Borough'
WHERE Type = 'Boroughs'
;

-- The Aland and Awater columns need to be checked for null values now.


SELECT ALand, AWater
FROM us_household_income
WHERE AWater = 0 OR AWater = '' or AWater IS NULL
;

SELECT ALand, AWater
FROM us_household_income
WHERE ALand = 0 OR ALand = '' or ALand IS NULL
;

SELECT ALand, AWater
FROM us_household_income
WHERE (AWater = 0 OR AWater = '' or AWater IS NULL)
AND (ALand = 0 OR ALand = '' or ALand IS NULL)
;

-- With the last query we've confirmed that there are not mistakes here, as some county areas are just land or just water, but there are no columns where both sets are null or 0

-- Now let's do some EDA!
-- Let's see a sum of area and land for each state

Select State_Name, Aland, Awater
FROM us_household_income
;

-- This shows us the states with the most land

Select State_Name, SUM(Aland), SUM(Awater)
FROM us_household_income
GROUP BY State_Name
ORDER BY 2 DESC
;

-- And this shows us the states with the most water

Select State_Name, SUM(Aland), SUM(Awater)
FROM us_household_income
GROUP BY State_Name
ORDER BY 3 DESC
;

-- Now let's show the top ten largest states by land, and by water

Select State_Name, SUM(Aland), SUM(Awater)
FROM us_household_income
GROUP BY State_Name
ORDER BY 2 DESC
LIMIT 10
;

Select State_Name, SUM(Aland), SUM(Awater)
FROM us_household_income
GROUP BY State_Name
ORDER BY 3 DESC
LIMIT 10
;


-- Now, let's start working with the income data. Let's join these two tables.

SELECT *
FROM us_household_income as u
	JOIN us_household_income_statistics as us
		ON u.id = us.id
        ;
    
-- Because we had less values come in from the non statistics table, let's perform a right join to make sure we can see which values we are missing
-- We can also find the ids that are null

SELECT *
FROM us_household_income as u
	RIGHT JOIN us_household_income_statistics as us
		ON u.id = us.id
WHERE u.id IS NULL
        ;

-- in order to not utilize these data, let's perform an inner join

SELECT *
FROM us_household_income as u
	INNER JOIN us_household_income_statistics as us
		ON u.id = us.id
        ;

-- Looks like we have statistics data that are 0's. Let's filter those non-null values out so it doesn't skew our future equations

SELECT *
FROM us_household_income as u
	INNER JOIN us_household_income_statistics as us
		ON u.id = us.id
WHERE Mean <> 0
        ;


-- Let's take a look at the mean and median incomes as it relates to the "type" and "track" columns.
-- First, let's query all of these columns

SELECT u.State_Name, county, `type`, `primary`, mean, median
FROM us_household_income as u
	INNER JOIN us_household_income_statistics as us
		ON u.id = us.id
WHERE Mean <> 0
        ;

-- Now let's look at the average mean and median incomes per state, sorted by lowest 5 


SELECT u.State_Name, ROUND(AVG(mean),1) as Avg_Mean, ROUND(AVG(median),1) As Avg_Median
FROM us_household_income as u
	INNER JOIN us_household_income_statistics as us
		ON u.id = us.id
        WHERE Mean <> 0
        GROUP BY u.State_Name
        ORDER BY 2 ASC
        LIMIT 5
        ;
        
-- Now let's see the top 5 richest states

SELECT u.State_Name, ROUND(AVG(mean),1) as Avg_Mean, ROUND(AVG(median),1) As Avg_Median
FROM us_household_income as u
	INNER JOIN us_household_income_statistics as us
		ON u.id = us.id
        WHERE Mean <> 0
        GROUP BY u.State_Name
        ORDER BY 2 DESC
        LIMIT 5
        ;


-- Now let's look at these same medians and means compared to the "type" and "primary" fields

SELECT `Type`, COUNT(Type), ROUND(AVG(mean),1) as Avg_Mean, ROUND(AVG(median),1) As Avg_Median
FROM us_household_income as u
	INNER JOIN us_household_income_statistics as us
		ON u.id = us.id
        WHERE Mean <> 0
        GROUP BY `Type`
        ORDER BY 2 Desc
        ;


-- Now let's filter by types that are non outliers with their numbers.


SELECT `Type`, COUNT(Type), ROUND(AVG(mean),1) as Avg_Mean, ROUND(AVG(median),1) As Avg_Median
FROM us_household_income as u
	INNER JOIN us_household_income_statistics as us
		ON u.id = us.id
        WHERE Mean <> 0
        GROUP BY `Type`
        HAVING COUNT(Type) > 100
        ORDER BY 2 Desc
        ;

-- Now let's take a larger look at our average mean income per household for larger cities

SELECT u.state_name, city, ROUND(AVG(Mean),1)
FROM us_household_income as u
	JOIN us_household_income_statistics as us
		ON u.id = us.id
	GROUP BY u.state_name, city
    ORDER BY ROUND(AVG(Mean),1) DESC
        ;

-- These are the highest earning cities in America. Nice!

-- SUMMARY: We found a lot here. We figured out the areas of land and water per state, found dirty data via a join, found state level highest and lowest averages and medians, and we looked at the different types of cities, and finally found the highest earning cities in America. 










