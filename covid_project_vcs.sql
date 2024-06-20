-- Original dataset found at 'https://github.com/owid/covid-19-data/tree/master/public/data'

-- Columns were removed and separated into 7 csv files according to subject. Column added with unique 'record_num' for each row in all csv files. 

-- Data cleanup in Python included deletion of rows where location was part of a larger group, including: = "World", "Asia", "Lower middle income", 'Upper middle income", "Africa", "High income", "Europe", "European Union", "Low income", "North America", "South America"
-- Dates after 5/11/2023 deleted from original datast due to U.S Department Health and Human services deeming this date the 'end' of the 'public health emergency.'

-- Tables include: demographics, admissions, cases, deaths, tests, vaccinations. 


------------------------ Table Creation ------------------------


CREATE TABLE demographics (
	record_num	int PRIMARY KEY,
	iso_code	varchar,
	continent	varchar,
	location	varchar,
	date		date,
	population_density	numeric,
	median_age	numeric,
	aged_65_older numeric,
	aged_70_older numeric,
	gdp_per_capita	numeric,
	extreme_poverty	numeric,
	handwashing_facilities	numeric,
	life_expectancy	numeric,
	human_development_index numeric,
	population	bigint,
	stringency_index numeric
);

-- Demographics table: This record_num column will act as our primary key. All following record_num columns in each table refer back (foreign key) to demographics table. 

CREATE TABLE admissions (
	record_num	int,
	icu_patients	int,
	hosp_patients	int,
	weekly_icu_admissions	int,
	weekly_hosp_admissions	int,
		CONSTRAINT fk_admissions
			FOREIGN KEY (record_num)
				REFERENCES demographics(record_num)
				ON DELETE CASCADE
);

CREATE TABLE cases (
	record_num	int,
	total_cases	int,
	new_cases	int,
	new_cases_smoothed	numeric,
	CONSTRAINT fk_admissions
			FOREIGN KEY (record_num)
				REFERENCES demographics(record_num)
				ON DELETE CASCADE
);
	
	
CREATE TABLE deaths (
	record_num	int,
	total_deaths	int,
	new_deaths	int,
	new_deaths_smoothed	numeric,
	CONSTRAINT fk_admissions
			FOREIGN KEY (record_num)
				REFERENCES demographics(record_num)
				ON DELETE CASCADE
);

CREATE TABLE tests (
	record_num	int,
	total_tests	bigint,
	new_tests	int,
	new_tests_smoothed	numeric,
	positive_rate	numeric,
	tests_per_case	numeric,
	CONSTRAINT fk_admissions
			FOREIGN KEY (record_num)
				REFERENCES demographics(record_num)
				ON DELETE CASCADE
);


CREATE TABLE vaccinations (
	record_num	int,
	total_vaccinations	bigint,
	people_vaccinated	bigint,
	people_fully_vaccinated	bigint,
	total_boosters	bigint,
	new_vaccinations	bigint,
	new_vaccinations_smoothed bigint,
	new_people_vaccinated_smoothed	bigint,
	CONSTRAINT fk_admissions
			FOREIGN KEY (record_num)
				REFERENCES demographics(record_num)
				ON DELETE CASCADE
);


------------------------ Data Imports ------------------------


--Import all csv files. 
COPY demographics FROM 'C:\Users\Public\Documents\covid_demographics.csv' DELIMITER ',' CSV HEADER;
COPY admissions FROM 'C:\Users\Public\Documents\covid_admissions.csv' DELIMITER ',' CSV HEADER;
COPY cases FROM 'C:\Users\Public\Documents\covid_cases.csv' DELIMITER ',' CSV HEADER;
COPY comorbities FROM 'C:\Users\Public\Documents\covid_comorbities.csv' DELIMITER ',' CSV HEADER;
COPY deaths FROM 'C:\Users\Public\Documents\covid_deaths.csv' DELIMITER ',' CSV HEADER;
COPY tests FROM 'C:\Users\Public\Documents\covid_tests.csv' DELIMITER ',' CSV HEADER;
COPY vaccinations FROM 'C:\Users\Public\Documents\covid_vaccinations.csv' DELIMITER ',' CSV HEADER;



------------------------ General information about our data ------------------------


SELECT MIN(date) AS start, MAX(date) AS end 
FROM demographics;
-- Double check start and end dates for dataset. 

SELECT continent, COUNT(*) AS entries FROM demographics
GROUP BY continent
ORDER BY entries DESC;
-- 7 Distinct continents including 'null.' Continent with the most entries: Africa. 

SELECT DISTINCT location, iso_code, continent, 
FROM demographics 
GROUP BY location, iso_code, continent 
ORDER BY location ASC;
-- Dataset contains information for 243 locations



------------------------ Top Continent in each Category ------------------------


SELECT continent, SUM(population) FROM demographics
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY continent DESC;
-- South America has the largest population.

SELECT continent, SUM(new_cases) AS cases_per_continent FROM demographics as d
JOIN cases AS c ON d.record_num = c.record_num
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY cases_per_continent DESC;
-- Continent with the most cases: Asia with 296,753,923

SELECT continent, SUM(new_deaths) AS deaths_per_continent FROM demographics as d
JOIN deaths AS de ON d.record_num = de.record_num
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY deaths_per_continent DESC;
-- Europe was the continent with the most deaths at 2,066,082

SELECT continent, SUM(new_tests) AS tests_per_continent FROM demographics as d
JOIN tests AS t ON d.record_num = t.record_num
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY tests_per_continent DESC;
-- Europe had the most tests performed. 

SELECT continent, MAX(total_vaccinations) AS vaccinations_per_continent FROM demographics AS d
JOIN vaccinations as v ON d.record_num = v.record_num
WHERE total_vaccinations IS NOT NULL
GROUP BY continent
ORDER BY vaccinations_per_continent DESC;
-- Asia has the most vaccines given. 


------------------------ Top 5 locations in each Category ------------------------


SELECT location, MAX(population) AS population
FROM demographics 
GROUP BY location 
ORDER BY population DESC
LIMIT 5; 
-- Largest population

SELECT location, SUM(new_cases) AS cases_per_country FROM demographics AS d 
JOIN cases as c ON d.record_num = c.record_num
WHERE new_cases IS NOT NULL
GROUP BY location
ORDER BY cases_per_country DESC
LIMIT 5;
-- Most cases

SELECT location, SUM(new_deaths) AS deaths_per_country FROM demographics AS demo
JOIN deaths as d ON d.record_num = demo.record_num
WHERE new_deaths IS NOT NULL
GROUP BY location
ORDER BY deaths_per_country DESC
LIMIT 5;
-- Most deaths 

SELECT d.location, SUM(new_tests) AS tests_per_country
FROM tests AS t
JOIN demographics AS d
ON t.record_num = d.record_num
WHERE new_tests IS NOT NULL
GROUP BY location
ORDER BY tests_per_country DESC
LIMIT 5;
-- Most Tests  

SELECT location, MAX(total_vaccinations) AS vaccinations_per_continent FROM demographics AS d
JOIN vaccinations as v ON d.record_num = v.record_num
WHERE total_vaccinations IS NOT NULL
GROUP BY location
ORDER BY vaccinations_per_continent DESC
LIMIT 5;
-- Most vaccinations


------------------------ Table Alterations ------------------------

ALTER TABLE demographics ADD COLUMN year integer;
-- Add a year column to begin filtering by year.

UPDATE demographics
SET year = EXTRACT(YEAR FROM date)
-- Extract year from date column, add a column with year only.  

ALTER TABLE demographics ADD column month integer; 
-- Add a month column to filter by month and year.

UPDATE demographics
SET month = EXTRACT(month FROM date)
-- Extract month from date column to be placed in month column created above.


------------------------ Infection Rates ------------------------
SELECT d.location, population, SUM(total_cases) AS max_cases, ROUND(SUM(CAST(new_cases AS numeric)/population)*100,2) AS percent_infected FROM demographics AS d
JOIN cases as c ON d.record_num = c.record_num
WHERE total_cases IS NOT NULL
GROUP BY location, population
ORDER BY percent_infected DESC;
-- Locations with the highest percentages of their population infected with the virus. 

SELECT d.location, population, SUM(new_cases) AS max_cases, ROUND(SUM(CAST(new_cases AS numeric)/population)*100,2) AS percent_infected FROM demographics AS d
JOIN cases as c ON d.record_num = c.record_num
WHERE total_cases IS NOT NULL
GROUP BY location, population
ORDER BY percent_infected DESC;
-- Demonstrates the change in infection rate for each year during the pandemic for each location. 

SELECT d.location, year, population, MAX(total_cases) AS max_cases, ROUND(MAX(CAST(total_cases AS numeric)/population)*100,2) AS percent_infected FROM demographics AS d
JOIN cases as c ON d.record_num = c.record_num
WHERE total_cases IS NOT NULL AND location LIKE 'United States' 
GROUP BY location, year, population
ORDER BY location, year DESC;
-- Infection rate for the United States 2020-2023, by 2023 30.55% of the U.S population had been infected with covid-19. 

 

SELECT DISTINCT year, month, SUM(new_deaths) AS monthly_deaths FROM demographics AS d
JOIN deaths AS de ON D.record_num = de.record_num
GROUP BY year, month
ORDER BY monthly_deaths DESC;
-- Demonstrates the top two combinations of month/year with the most deaths attributed to covid-19, January of 2021 was the worst month during the pandemic with 484,031 deaths worldwide. 


------------------------ United States Analysis ------------------------


-- From this point forward I will focus on exploring trends concerning my home country, the United States.

SELECT year, MAX(total_deaths) AS total_deaths, 
MAX(total_deaths) - LAG(MAX(total_deaths)) OVER (ORDER BY year) AS deaths_this_year,
MAX(total_cases) AS total_cases,
MAX(total_cases) - LAG(MAX(total_cases)) OVER (ORDER BY year) AS cases_this_year, 
ROUND((MAX(CAST(total_deaths AS numeric))/ LAG(MAX(total_cases)) OVER (ORDER BY year))*100,2) AS death_percentage_of_cases
FROM demographics AS d
JOIN deaths AS de ON d.record_num = de.record_num
JOIN cases AS c ON d.record_num = c.record_num
WHERE location LIKE 'United States'
GROUP BY year, population
ORDER BY year;
-- These results demonstrate that the U.S. suffered the most deaths in the year 2021 with 469,667 deaths that year alone, approximately 4.30% of all cases this year ended in death. 
-- In 2022 we see an increase in the number of new cases of covid-19, but a decrease in the number of deaths and percentage of cases resulting in death, dropping from 4.3% to 2.08%. 
-- These values make sense due to the increase in vaccine availability at the end of 2021, meaning more people where vaccinated against the virus by 2022. An increased number of cases
-- in 2022 correlates with the surge of multiple new variants of the virus. Sources: https://www.cdc.gov/museum/timeline/covid19.html, https://www.yalemedicine.org/news/covid-19-variants-of-concern-omicron

SELECT year, MAX(total_vaccinations) AS total_vaccinations, MAX(total_vaccinations) - LAG(MAX(total_vaccinations)) OVER (ORDER BY year) AS difference_vaccinations,
MAX(people_fully_vaccinated) AS people_vaccinated, MAX(people_fully_vaccinated) - LAG(MAX(people_fully_vaccinated)) OVER (ORDER BY year) AS difference_people_vaccinated
FROM demographics as d
JOIN vaccinations as v 
ON d.record_num = v.record_num
WHERE location LIKE 'United States'
GROUP BY year
ORDER BY year ASC;
-- This query shows that the year with the most vaccinations performed, and which had the most people fully vaccinated in the United States, was the year 2021, coorborating the 
-- timeline of decreased deaths in 2022 following vaccinations in 2021. 

SELECT year, MAX(total_cases) AS total_cases, MAX(hosp_patients) AS total_admissions, 
MAX(icu_patients) AS total_icu_admissions, ROUND((MAX(CAST(icu_patients AS numeric)) / MAX(hosp_patients))*100, 2) AS percent_admitted_to_icu, 
ROUND((MAX(CAST(hosp_patients AS numeric))/ MAX(total_cases))*100,2) AS percent_admitted_to_hosp
FROM demographics AS d
JOIN admissions AS a ON d.record_num = a.record_num
JOIN cases AS c ON d.record_num = c.record_num
WHERE location LIKE 'United States'
GROUP BY year, population
ORDER BY year;
-- This query also demonstrates that as the pandemic progressed from 2020-2023, the percentage of cases requiring admission to the hospital (and icu) decreased, with the year 2020
-- when the pandemic first began showing the highest rates of people admitted to the hospital and to the icu. 


