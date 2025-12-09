-------------------------------------------------------------
-- 1. RAW DATA CHECK
-------------------------------------------------------------
SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4;

SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4;


-------------------------------------------------------------
-- 2. BASIC SELECTS
-------------------------------------------------------------
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2;


-------------------------------------------------------------
-- 3. TOTAL CASES VS TOTAL DEATHS
-------------------------------------------------------------
SELECT 
    Location, 
    date, 
    total_cases, 
    total_deaths, 
    (CAST(total_deaths AS float) / NULLIF(total_cases, 0)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE Location LIKE '%states%'
ORDER BY 1,2;


-------------------------------------------------------------
-- 4. TOTAL CASES VS POPULATION
-------------------------------------------------------------
SELECT 
    Location, 
    date, 
    Population, 
    total_cases, 
    (CAST(total_cases AS float) / Population) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2;


-------------------------------------------------------------
-- 5. COUNTRY WITH HIGHEST INFECTION RATE
-------------------------------------------------------------
SELECT 
    Location,
    Population,
    MAX(total_cases) AS HighestInfectionCount,
    MAX(CAST(total_cases AS float) / Population) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;


-------------------------------------------------------------
-- 6. COUNTRIES WITH HIGHEST DEATH COUNT
-------------------------------------------------------------
SELECT 
    Location,
    MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;


-------------------------------------------------------------
-- 7. GLOBAL NUMBERS BY DATE
-------------------------------------------------------------
SELECT
    date,
    SUM(CAST(new_cases AS int)) AS total_cases,
    SUM(CAST(new_deaths AS int)) AS total_deaths,
    (SUM(CAST(new_deaths AS float)) / NULLIF(SUM(CAST(new_cases AS float)), 0)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;


-------------------------------------------------------------
-- 8. GLOBAL TOTAL NUMBERS
-------------------------------------------------------------
SELECT
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS int)) AS total_deaths,
    (SUM(CAST(new_deaths AS float)) / NULLIF(SUM(new_cases), 0)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;


-------------------------------------------------------------
-- 9. POPULATION VS VACCINATION (ROLLING SUM)
-------------------------------------------------------------
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS bigint)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;


-------------------------------------------------------------
-- 10. USING CTE
-------------------------------------------------------------
;WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS bigint)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *,
       (RollingPeopleVaccinated / Population) * 100 AS PercentVaccinated
FROM PopvsVac;


-------------------------------------------------------------
-- 11. TEMP TABLE
-------------------------------------------------------------
DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    SUM(CAST(vac.new_vaccinations AS bigint)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT 
    *,
    (RollingPeopleVaccinated / Population) * 100 AS PercentageVaccinated
FROM #PercentPopulationVaccinated;


-------------------------------------------------------------
-- 12. CREATE VIEW (CLEAN + CORRECT)
-------------------------------------------------------------
USE PortfolioProject;

DROP VIEW IF EXISTS dbo.PercentPopulation;
GO

CREATE VIEW dbo.PercentPopulation AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS bigint)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
GO

select * 
from PercentPopulation