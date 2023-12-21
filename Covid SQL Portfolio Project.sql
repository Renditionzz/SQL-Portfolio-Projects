select *
from PortfolioProject..CovidDeaths$
where continent is not null
order by 3,4

--select *
--from PortfolioProject..CovidVaccinations$
--order by 3,4

-- Select the data we're going to use.

--select Location, date, total_cases,new_cases,total_deaths,population
--from PortfolioProject..CovidDeaths$
--order by 1,2

-- Looking at the total cases vs total deaths

-- Shows the likelihood of deathrates of covid by country
select Location, date, total_cases,total_deaths, 
(convert(float,total_deaths) / nullif(convert(float,total_cases),0)) * 100 as Deathpercentage
from PortfolioProject..CovidDeaths$
where location like '%states%'
order by 1,2

-- looking at total cases vs population
select Location, date,population,total_cases, 
(convert(float,total_cases) / population) * 100 as Infectionpercentage
from PortfolioProject..CovidDeaths$
where location = 'United States'
order by 1,2

-- Looking at Countires with Highest Infection Rate compared to Population
select Location,population,MAX(total_cases) as HighestInfectionCount, 
Max((convert(float,total_cases) / population) * 100) as PercentPopulationInfected
from PortfolioProject..CovidDeaths$
group by location,population
order by PercentPopulationInfected DESC

-- Showing Countries with highest death count per population
select Location, Max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths$
where continent is not null
group by location
order by TotalDeathCount DESC


-- By Continent


-- Showing continents with the highest death count per population
select continent, Max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths$
where continent is not null
group by continent
order by TotalDeathCount DESC

-- Global numbers

select sum(new_cases) as TotalCases, sum(new_deaths) as TotalDeaths, (sum(new_deaths) / nullif(sum(new_cases),0) * 100) as Deathpercentage
from PortfolioProject..CovidDeaths$
where continent is not null
-- group by date
order by 1,2

-- Covid Vaccinations
select *
from PortfolioProject..CovidVaccinations$

--Join Covid deaths and vaccinations
select *
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date

-- Look at total population vs vaccination
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as bigint)) over (partition by  dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3


--Using a CTE

with PopvsVac (Continent,Location,Date,Population, New_Vaccinations, RollingPeopleVaccinated)
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as bigint)) over (partition by  dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
)
select *, (RollingPeopleVaccinated / Population) * 100 as PercentVaccinated
from PopvsVac


-- temp table

drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(bigint,vac.new_vaccinations)) over (partition by  dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null

select *, (RollingPeopleVaccinated / Population) *100
from #PercentPopulationVaccinated

-- Creating View to store data for later visualizations
create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(bigint,vac.new_vaccinations)) over (partition by  dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null


--
Select *
From PercentPopulationVaccinated