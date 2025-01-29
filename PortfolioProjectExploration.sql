select * from CovidDeaths
WHERE continent <> '' AND continent IS NOT NULL
order by 3, 4

--select * from CovidVaccinations
--order by 3, 4

-- Select data that we are going to be usinbg

Select 
	location,
	date, 
	total_cases, 
	new_cases, 
	total_deaths,
	new_deaths,
	population 
from CovidDeaths
WHERE continent <> '' AND continent IS NOT NULL
order by 1, 2



-- looking at total cases vs total deaths
-- shows likelihood of dying if you contract covid,,, But is some cases like Kenya.


SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths,
    (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
FROM CovidDeaths
--Where location like '%kenya%'
WHERE continent <> '' AND continent IS NOT NULL
ORDER BY location, date;




-- looking at total cases vs population
-- this shows what % of population got covid

SELECT 
    location, 
    date, 
    total_cases, 
    population,
    (CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) * 100 AS Populationpercentage
FROM CovidDeaths
--Where location like '%kenya%'
WHERE continent <> '' AND continent IS NOT NULL
ORDER BY location, date;




-- Looking at countries with highest infection rates compared to population grouped by location and population
SELECT 
    location,
    Population, 
    MAX(CONVERT(FLOAT, total_cases)) AS HighestInfectionCount,
    MAX(CONVERT(FLOAT, total_cases) / NULLIF(CONVERT(FLOAT, Population), 0)) * 100 AS PercentOfPopulation
FROM CovidDeaths
-- WHERE location LIKE '%kenya%'
WHERE continent <> '' AND continent IS NOT NULL
GROUP BY location, Population
ORDER BY PercentOfPopulation DESC;





-- Showing countries with highest deathcount per population

SELECT 
    location, 
    MAX(CONVERT(FLOAT, total_deaths)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent <> '' AND continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;



-- Breaking deathcount by continent per population


SELECT 
  CAST(continent AS nvarchar) AS continent, 
    MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent <> '' AND continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;








-- GLOBAL NUMBERS


SELECT 
    SUM(CONVERT(INT, new_cases)) AS Total_Cases,
    SUM(CONVERT(INT, new_deaths)) AS Total_Deaths,
    (SUM(CONVERT(INT, new_deaths)) * 100.0 / SUM(NULLIF(CONVERT(INT, new_cases), 0))) AS Death_Percentage
FROM CovidDeaths
WHERE continent <> '' AND continent IS NOT NULL
ORDER BY Total_Cases, Total_Deaths;



--Joining Vaccination and deaths table

Select * 
from CovidDeaths dea
join
CovidVaccinations vac
on dea.location = vac.location
and 
dea.date = vac.date

--looking at total population vs vaccination

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations , SUM(convert(int, vac.new_vaccinations)) OVER (partition by  dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
	from CovidDeaths dea
	join
	CovidVaccinations vac
	on dea.location = vac.location
	and 
	dea.date = vac.date
WHERE dea.continent <> '' AND dea.continent IS NOT NULL
order by 1,2,3



-- USE CTE 

WITH popvsVac (continent, location, Date, Population, New_vaccinations, RollingPeopleVaccinated)  
AS  
(  
    SELECT  
        dea.continent,  
        dea.location,  
        dea.date,  
        dea.population, 
        TRY_CONVERT(int, vac.new_vaccinations) AS New_vaccinations,  
        SUM(COALESCE(TRY_CONVERT(int, NULLIF(vac.new_vaccinations, '')), 0)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated  
    FROM CovidDeaths dea  
    JOIN CovidVaccinations vac  
        ON dea.location = vac.location  
        AND dea.date = vac.date  
    WHERE dea.continent <> ''  
        AND dea.continent IS NOT NULL  
        AND ISNUMERIC(vac.new_vaccinations) = 1  -- Ensure only numeric values  
)  
SELECT *, (RollingPeopleVaccinated * 100.0 / Population) AS VaccinationPercentage
FROM popvsVac;


--TEMP TABLE

DROP table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric,

)
Insert into #PercentPopulationVaccinated

SELECT  
        dea.continent,  
        dea.location,  
        dea.date,  
        dea.population, 
        TRY_CONVERT(int, vac.new_vaccinations) AS New_vaccinations,  
        SUM(COALESCE(TRY_CONVERT(int, NULLIF(vac.new_vaccinations, '')), 0)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated  
    FROM CovidDeaths dea  
    JOIN CovidVaccinations vac  
        ON dea.location = vac.location  
        AND dea.date = vac.date  
    WHERE dea.continent <> ''  
        AND dea.continent IS NOT NULL  
        AND ISNUMERIC(vac.new_vaccinations) = 1  -- Ensure only numeric values  
	
SELECT *, (RollingPeopleVaccinated * 100.0 / Population) AS VaccinationPercentage
FROM #PercentPopulationVaccinated;


-- Creating view to store data for later visualization

create view PercentPopulationVaccinated As

SELECT  
        dea.continent,  
        dea.location,  
        dea.date,  
        dea.population, 
        TRY_CONVERT(int, vac.new_vaccinations) AS New_vaccinations,  
        SUM(COALESCE(TRY_CONVERT(int, NULLIF(vac.new_vaccinations, '')), 0)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated  
    FROM CovidDeaths dea  
    JOIN CovidVaccinations vac  
        ON dea.location = vac.location  
        AND dea.date = vac.date  
    WHERE dea.continent <> ''  
        AND dea.continent IS NOT NULL  
        AND ISNUMERIC(vac.new_vaccinations) = 1  -- Ensure only numeric values
		
		
		
		
		select * 
		from PercentPopulationVaccinated