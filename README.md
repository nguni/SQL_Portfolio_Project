# SQL Portfolio: Analyzing COVID-19 Data Using SQL Queries
In this project, I used SQL to explore COVID-19 data and gain insights into the impact of the pandemic globally. 
The dataset consists of two primary tables: CovidDeaths and CovidVaccinations, which provide information on cases, deaths, and vaccinations across different locations and dates.

The following sections explain the SQL queries used in the analysis, including their purpose and the insights they provide.

**1. Exploring the Dataset**

Retrieving Data from COVID-19 Tables

```
SELECT * FROM CovidDeaths
WHERE continent <> '' AND continent IS NOT NULL
ORDER BY 3, 4;
```

```
SELECT * FROM CovidVaccinations
ORDER BY 3, 4;
```
**Purpose**

These queries fetch all records from the CovidDeaths and CovidVaccinations tables. The condition continent ``` <> '' AND continent IS NOT NULL ``` ensures that we only include meaningful records, excluding aggregate data that might appear in the dataset.

**2. Selecting Key Data for Analysis**

```
SELECT 
    location,
    date, 
    total_cases, 
    new_cases, 
    total_deaths,
    new_deaths,
    population 
FROM CovidDeaths
WHERE continent <> '' AND continent IS NOT NULL
ORDER BY 1, 2;

```
**Purpose**

This query selects key columns needed for analysis, such as total cases, new cases, total deaths, new deaths, and population. This data helps track the progression of the pandemic in different regions.


**3. Calculating Death Rate (Likelihood of Dying from COVID-19)**

```
SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths,
    (CONVERT(FLOAT, total_deaths) / NULLIF(CONVERT(FLOAT, total_cases), 0)) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent <> '' AND continent IS NOT NULL
ORDER BY location, date;

```
**Purpose**

This query calculates the percentage of deaths among confirmed cases, indicating the likelihood of dying if one contracts COVID-19. The ``` NULLIF ``` function ensures division by zero is avoided.


**4. Percentage of Population Infected**
   
```
SELECT 
    location, 
    date, 
    total_cases, 
    population,
    (CONVERT(FLOAT, total_cases) / NULLIF(CONVERT(FLOAT, population), 0)) * 100 AS PopulationPercentage
FROM CovidDeaths
WHERE continent <> '' AND continent IS NOT NULL
ORDER BY location, date;

```

**Purpose**

This query calculates the percentage of a country’s population that has been infected. It helps assess the extent of COVID-19 spread in different locations.

**6. Countries with the Highest Infection Rate**

```

SELECT 
    location,
    Population, 
    MAX(CONVERT(FLOAT, total_cases)) AS HighestInfectionCount,
    MAX(CONVERT(FLOAT, total_cases) / NULLIF(CONVERT(FLOAT, Population), 0)) * 100 AS PercentOfPopulation
FROM CovidDeaths
WHERE continent <> '' AND continent IS NOT NULL
GROUP BY location, Population
ORDER BY PercentOfPopulation DESC;
```
**Purpose**

This query identifies countries with the highest infection rates relative to their population, using the MAX() function to find the peak number of infections.


**7. Countries with the Highest Death Count**

```
SELECT 
    location, 
    MAX(CONVERT(FLOAT, total_deaths)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent <> '' AND continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;
```
**Purpose**

This query ranks countries based on total COVID-19 deaths, providing a clear view of the most affected regions.


**8. Death Count by Continent**
```
SELECT 
    CAST(continent AS NVARCHAR) AS continent, 
    MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent <> '' AND continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;
```

**Purpose**

This query aggregates death counts at the continent level to analyze regional impact.

**9. Global COVID-19 Statistics**
```
SELECT 
    SUM(CONVERT(INT, new_cases)) AS Total_Cases,
    SUM(CONVERT(INT, new_deaths)) AS Total_Deaths,
    (SUM(CONVERT(INT, new_deaths)) * 100.0 / SUM(NULLIF(CONVERT(INT, new_cases), 0))) AS Death_Percentage
FROM CovidDeaths
WHERE continent <> '' AND continent IS NOT NULL;

```

**Purpose**

This query provides a global summary of total cases, deaths, and the overall death percentage.

**10. Joining COVID-19 Deaths and Vaccinations Data**

```
SELECT * 
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date;

```

**Purpose**

This query joins the two tables based on location and date, allowing analysis of deaths alongside vaccination rates.

**11. Tracking Vaccination Progress**

```
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,  
    SUM(CONVERT(INT, vac.new_vaccinations)) 
        OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent <> '' AND dea.continent IS NOT NULL
ORDER BY 1, 2, 3;

```

**Purpose**

This query calculates the cumulative number of people vaccinated using a SUM() window function.

**12. Using CTE to Analyze Vaccination Percentage**
```
WITH popvsVac (continent, location, Date, Population, New_vaccinations, RollingPeopleVaccinated)  
AS  
(  
    SELECT  
        dea.continent,  
        dea.location,  
        dea.date,  
        dea.population, 
        TRY_CONVERT(INT, vac.new_vaccinations) AS New_vaccinations,  
        SUM(COALESCE(TRY_CONVERT(INT, NULLIF(vac.new_vaccinations, '')), 0)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated  
    FROM CovidDeaths dea  
    JOIN CovidVaccinations vac  
        ON dea.location = vac.location  
        AND dea.date = vac.date  
    WHERE dea.continent <> ''  
        AND dea.continent IS NOT NULL  
        AND ISNUMERIC(vac.new_vaccinations) = 1  
)  
SELECT *, (RollingPeopleVaccinated * 100.0 / Population) AS VaccinationPercentage
FROM popvsVac;
```

**Purpose**

This query uses a Common Table Expression (CTE) to calculate the rolling number of vaccinated people and the percentage of the population vaccinated.

**13. Creating a Temporary Table for Vaccination Analysis**

```
DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated (
    continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_Vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT * FROM popvsVac;

SELECT *, (RollingPeopleVaccinated * 100.0 / Population) AS VaccinationPercentage
FROM #PercentPopulationVaccinated;
```

**Purpose**

This query creates a temporary table to store and analyze vaccination data.

**13. Creating a View for Future Analysis**
```
CREATE VIEW PercentPopulationVaccinated AS
SELECT * FROM popvsVac;
```
**Purpose**

This view stores vaccination data for easy retrieval and visualization.

**Conclusion**

This SQL project provided valuable insights into the COVID-19 pandemic using data analysis techniques. 
The queries explored infection rates, death percentages, and vaccination trends globally and by region. Using SQL joins, CTEs, temporary tables, and views enhanced the efficiency and clarity of the analysis.
