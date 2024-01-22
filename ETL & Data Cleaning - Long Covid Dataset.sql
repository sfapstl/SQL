-- In this project, I will perform ETL procedures on a Long Covid dataset from the U.S. Census Bureau in MySQL Workbench
-- Long COVID is broadly defined as signs, symptoms, and conditions that continue or develop after acute COVID-19 infection and can last weeks, months, or years

-- The Tableau dashboard associated with this dataset can be found on my Tableau Public profile: https://public.tableau.com/app/profile/seanapostol/viz/LongCovidPrevalence/LongCovid

-- Data source: https://www.cdc.gov/nchs/covid19/pulse/long-covid.htm


-- Creating a table in a local database into which raw data from the downloaded .CSV file will be inserted
CREATE TABLE `sys`.`post_covid_conditions` (
  `indicator` VARCHAR(150) NULL,
  `group` VARCHAR(100) NULL,
  `state` VARCHAR(100) NULL,
  `subgroup` VARCHAR(50) NULL,
  `phase` DECIMAL(10) NULL,
  `time_period` INT(10) NULL,
  `time_period_label` VARCHAR(100) NULL, 
  `time_period_start` VARCHAR(50) NULL, -- NOTE: These are supposed to be DATE values but are not formatted to the MySQL date format in the .CSV file, to be transformed later
  `time_period_end` VARCHAR(50) NULL, -- NOTE: These are supposed to be DATE values but are not formatted to the MySQL date format in the .CSV file, to be transformed later
  `value` DECIMAL(10) NULL,
  `ci_low` DECIMAL(10) NULL,
  `ci_high` DECIMAL(10) NULL,
  `ci_interval` VARCHAR(50) NULL,
  `quartile_range` VARCHAR(50) NULL,
  `quartile_number` INT(10) NULL,
  `suppression_flag` INT(10) NULL);

-- Inserting the raw data into the table from the .CSV file
LOAD DATA LOCAL INFILE 'C:\\Users\\---\\Documents\\---\\SQL\\Post-COVID_Conditions_new.csv' 
INTO TABLE post_covid_conditions
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Inspecting the newly created table
SELECT * FROM post_covid_conditions;

SAMPLE RESULT:

indicator	group			state		subgroup	phase	time_period	time_period_label	time_period_start	time_period_end		value	ci_low	ci_high	ci_interval	quartile_range	quartile_number	suppression_flag
Ever had COVID	National Estimate	United States	United States	4	47		Jun 29 - Jul 11, 2022	06/29/2022		07/11/2022		43	42	44	42.4 - 44.2			0		0

-- Note that time_period_start and time_period_end are not in the standard MySQL date format (YYYY-MM-DD)

-- Transforming the data type for the date columns from the VARCHAR to DATE data type and standardizing the date format:
UPDATE post_covid_conditions
SET time_period_start = STR_TO_DATE(time_period_start, '%m/%d/%Y');

UPDATE post_covid_conditions
SET time_period_end = STR_TO_DATE(time_period_end, '%m/%d/%Y');

-- Inspecting the updated table
SELECT * FROM post_covid_conditions;

SAMPLE RESULT:

indicator	group			state		subgroup	phase	time_period	time_period_label	time_period_start	time_period_end		value	ci_low	ci_high	ci_interval	quartile_range	quartile_number	suppression_flag
Ever had COVID	National Estimate	United States	United States	4	46		Jun 1 - Jun 13, 2022	2022-06-01		2022-06-13		40	40	41	39.5 - 41.1			0		0		

-- Date columns are now formatted in the standard MySQL date format (YYYY-MM-DD)

-- Viewing the data in the 'subgroup' column
SELECT DISTINCT
    	subgroup
FROM 
	post_covid_conditions
WHERE 
	post_covid_conditions.group <> 'By State'; -- interested only in national long covid rates per demographic, not by state

RESULT:
	- - - - - - - - -	
	subgroup
	- - - - - - - - -
	18 - 29 years
	30 - 39 years
	40 - 49 years
	50 - 59 years
	60 - 69 years
	70 - 79 years
	80 years and above
	Bachelor's degree or higher
	Bisexual
	Cis-gender female
	Cis-gender male
	Female
	Gay or lesbian
	High school diploma or GED
	Hispanic or Latino
	Less than a high school diploma
	Male
	Non-Hispanic Asian, single race
	Non-Hispanic Black, single race
	Non-Hispanic White, single race
	Non-Hispanic, other races and multiple races
	Some college/Associate's degree
	Straight
	Transgender
	United States
	With disability
	Without disability */
	- - - - - - - - -

-- The `subgroup` column contains all the demographic information needed for analysis vis-a-vis Long Covid rates in the `value` column
-- However, the current formatting of the data in the table makes it difficult to read
-- I want to see Long Covid rates for each demographic in a straight line or one row per indicator

-- Creating a temporary table to transform the `subgroup` column into discrete categories of age, sex, gender identity, sexuality, race, education level, and disability status using CASE statements with corresponding values of Long Covid rates
CREATE TEMPORARY TABLE long_covid_groups
SELECT
    	time_period_start,
    	indicator,
	
    	CASE subgroup
		WHEN 'United States' THEN 'national' -- national estimate of Long Covid prevalence for the entire population, inserted in age_group instead of another CASE for efficiency but unrelated to age group
		WHEN '18 - 29 years' THEN '18 - 29'
		WHEN '30 - 39 years' THEN '30 - 39'
		WHEN '40 - 49 years' THEN '40 - 49'
		WHEN '50 - 59 years' THEN '50 - 59'
       		WHEN '60 - 69 years' THEN '60 - 69'
       		WHEN '70 - 79 years' THEN '70 - 79'
        	WHEN '80 years and above' THEN '80+'
	END AS age_group,
	
    	CASE subgroup
		WHEN 'Male' THEN 'male'
        	WHEN 'Female' THEN 'female'
	END AS sex,
	
    	CASE
		WHEN subgroup IN ('Cis-gender male', 'Cis-gender female') THEN 'cisgender'
        	WHEN subgroup = 'Transgender' THEN 'transgender'
	END AS gender_identity,
	
    	CASE
		WHEN subgroup = 'Straight' THEN 'heterosexual'
        	WHEN subgroup IN ('Gay or lesbian', 'Bisexual') THEN 'non-heterosexual'
	END AS sexuality,
	
	CASE
		WHEN subgroup = 'Hispanic or Latino' THEN 'hispanic'
        	WHEN subgroup = 'Non-Hispanic White, single race' THEN 'white'
        	WHEN subgroup = 'Non-Hispanic Black, single race' THEN 'black'
        	WHEN subgroup = 'Non-Hispanic Asian, single race' THEN 'asian'
        	WHEN subgroup = 'Non-Hispanic, other races and multiple races' THEN 'other/mixed'
	END AS race,
	
    	CASE
		WHEN subgroup IN ('Less than a high school diploma', 'High school diploma or GED', "Some college/Associate's degree") THEN 'no_college'
        	WHEN subgroup = "Bachelor's degree or higher" THEN 'college_grad'
	END AS educ_level, -- using education level as a proxy for socioeconomic status
	
    	CASE subgroup
		WHEN 'With disability' THEN 'disabled'
        	WHEN 'Without disability' THEN 'not_disabled'
	END AS disability_status,
	
    	AVG(value) AS percentage
FROM 
	post_covid_conditions
GROUP BY 
	1, 2, 3, 4, 5, 6, 7, 8, 9;
-- end of temp table

-- Create a temporary table from the previous table showing Long Covid rates for all demographics per Long Covid indicator, grouped by survey start date
CREATE TEMPORARY TABLE lc_indicator_level
SELECT
    	time_period_start AS survey_start_date,
    	indicator,
	
    	ROUND(MAX(CASE WHEN age_group = 'national' THEN percentage END), 2) AS national_avg,
	
    	ROUND(MAX(CASE WHEN age_group = '18 - 29' THEN percentage END), 2) AS "18-29",
    	ROUND(MAX(CASE WHEN age_group = '30 - 39' THEN percentage END), 2) AS "30-29",
    	ROUND(MAX(CASE WHEN age_group = '40 - 49' THEN percentage END), 2) AS "40-49",
    	ROUND(MAX(CASE WHEN age_group = '50 - 59' THEN percentage END), 2) AS "50-59",
    	ROUND(MAX(CASE WHEN age_group = '60 - 69' THEN percentage END), 2) AS "60-69",
    	ROUND(MAX(CASE WHEN age_group = '70 - 79' THEN percentage END), 2) AS "70-79",
    	ROUND(MAX(CASE WHEN age_group = '80+' THEN percentage END), 2) AS "80+",
	
    	ROUND(MAX(CASE WHEN sex = 'male' THEN percentage END), 2) AS male,
    	ROUND(MAX(CASE WHEN sex = 'female' THEN percentage END), 2) AS female,
	
    	ROUND(MAX(CASE WHEN gender_identity = 'cisgender' THEN percentage END), 2) AS cisgender,
    	ROUND(MAX(CASE WHEN gender_identity = 'transgender' THEN percentage END), 2) AS transgender,
	
    	ROUND(MAX(CASE WHEN sexuality = 'heterosexual' THEN percentage END), 2) AS hetero,
    	ROUND(MAX(CASE WHEN sexuality = 'non-heterosexual' THEN percentage END), 2) AS non_hetero,
	
    	ROUND(MAX(CASE WHEN race = 'hispanic' THEN percentage END), 2) AS hispanic,
    	ROUND(MAX(CASE WHEN race = 'white' THEN percentage END), 2) AS white,
    	ROUND(MAX(CASE WHEN race = 'black' THEN percentage END), 2) AS black,
    	ROUND(MAX(CASE WHEN race = 'asian' THEN percentage END), 2) AS asian,
    	ROUND(MAX(CASE WHEN race = 'other/mixed' THEN percentage END), 2) AS other_race,
	
    	ROUND(MAX(CASE WHEN educ_level = 'no_college' THEN percentage END), 2) AS non_college,
    	ROUND(MAX(CASE WHEN educ_level = 'college_grad' THEN percentage END), 2) AS college_grad,
	
    	ROUND(MAX(CASE WHEN disability_status = 'disabled' THEN percentage END), 2) AS disabled,
    	ROUND(MAX(CASE WHEN disability_status = 'not_disabled' THEN percentage END), 2) AS not_disabled
FROM 
	long_covid_groups
GROUP BY 
	1, 2
ORDER BY 
	survey_start_date;
-- end of temp table

-- Inspecting the temporary table to check the data
SELECT * 
FROM 
	indicator_level 
WHERE 
	survey_start_date = '2022-09-14' -- arbitrary value
	AND indicator IN ('Currently experiencing long COVID, as a percentage of adults who ever had COVID', 
			  'Currently experiencing long COVID, as a percentage of all adults'); -- arbitrary value

RESULT:

survey_start_date	indicator				national_avg	18-29	30-29	40-49	50-59	60-69	70-79	80+	male	female	cisgender	transgender	hetero	non_hetero	hispanic	white	black	asian	other_race	non_college	college_grad	disabled	not_disabled
2022-09-14	Currently experiencing long COVID, 
		as a percentage of adults who ever had COVID	15.00		11.00	14.00	16.00	18.00	17.00	16.00	15.00	12.00	18.00	15.00		30.00		15.00	16.50		15.00		15.00	14.00	9.00	19.00		18.00		12.00		30.00		13.00
2022-09-14	Currently experiencing long COVID, 
		as a percentage of all adults			7.00		6.00	8.00	9.00	9.00	7.00	5.00	5.00	6.00	9.00	7.00		17.00		7.00	8.50		8.00		7.00	6.00	4.00	10.00		8.33		6.00		14.00		6.00

-- Now, percentage values of Long Covid prevalence per demographic are grouped by indicator and survey start date for better readability, mimicking pivot table views in Excel

-- Finally, create a new table in the database with the cleaned and transformed data for further analysis
CREATE TABLE indicator_level
SELECT * 
FROM lc_indicator_level;


/* NOTE FOR ANALYSIS:

The data manipulation possibilities for this dataset are limited since the values for Long Covid rates in the data source have already been pre-aggregated from individual survey responses.
As such, it is not possible to manipulate the data to show, for example, the Long Covid prevalence for white males who are 18-29 years old. 
In other words, the values for Long Covid rates are for each discrete category only.

However, other analyses are still possible such as trend analysis, comparisons between the national rate and specific demographics across indicators, etc.
*/
