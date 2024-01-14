SELECT * FROM PP.dbo.CovidDeaths ORDER BY 3, 4

SELECT * FROM PP.dbo.CovidVaccine ORDER BY 3, 4;

SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM PP.dbo.CovidDeaths
ORDER BY 1, 2;

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, 
	(total_deaths/total_cases) *100 AS death_percentage
FROM PP.dbo.CovidDeaths
WHERE location like '%state%'
ORDER BY 1, 2 DESC;

-- Looking at Total Cases vs Population
-- Shows what % of population got Covid

SELECT location, date, population, total_cases, 
	(total_cases/population) *100 AS case_percentage
FROM PP.dbo.CovidDeaths
WHERE location like '%nigeria%'
ORDER BY 1, 2 DESC;

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS highest_infection_count, 
	MAX((total_cases/population))*100 AS percent_population_infected
FROM PP.dbo.CovidDeaths
--WHERE location like '%nigeria%'
GROUP BY location, population
ORDER BY percent_population_infected DESC;

-- Looking at Countries with Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_count 
FROM PP.dbo.CovidDeaths
--WHERE location like '%nigeria%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;

-- LETS BREAK THINGS DOWN BY CONTINENT

SELECT continent, MAX(CAST(total_deaths AS INT)) AS total_death_count 
FROM PP.dbo.CovidDeaths
--WHERE location like '%nigeria%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;

-- Shows the Continents with the Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_count 
FROM PP.dbo.CovidDeaths
--WHERE location like '%nigeria%'
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC;


-- GLOBAL NUMBERS

SELECT 
	SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS INT)) AS total_deaths, 
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_percentage
FROM PP.dbo.CovidDeaths
-- WHERE location like '%state%'
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1, 2;

-- Join Covid Deaths table on Covid Vaccine table

SELECT * FROM PP.dbo.CovidDeaths dea
JOIN PP.dbo.CovidVaccine vac
	ON dea.location = vac.location
	and dea.date = vac.date


-- Lookings at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS INT)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
			AS rolling_people_vaccinated
FROM PP.dbo.CovidDeaths dea
JOIN PP.dbo.CovidVaccine vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

-- USE CTE

WITH PopVsVac(continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS INT)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
			AS rolling_people_vaccinated
FROM PP.dbo.CovidDeaths dea
JOIN PP.dbo.CovidVaccine vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2, 3
)

SELECT *, (rolling_people_vaccinated/population)*100 FROM PopVsVac

-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated(
	continent nvarChar(255),
	location nvarChar(255),
	date datetime,
	population NUMERIC,
	new_vaccinations NUMERIC,
	rolling_people_vaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS INT)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
			AS rolling_people_vaccinated
FROM PP.dbo.CovidDeaths dea
JOIN PP.dbo.CovidVaccine vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2, 3


SELECT *, (rolling_people_vaccinated/population)*100 FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualisations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS INT)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
			AS rolling_people_vaccinated
FROM PP.dbo.CovidDeaths dea
JOIN PP.dbo.CovidVaccine vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2, 3

SELECT * FROM PercentPopulationVaccinated
