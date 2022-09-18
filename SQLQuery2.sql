/*

Video Games Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


-- Gives us all the columns in the database ordered by column Rank in ascending order 
-- From our database, the highest ranked video game was made in 2006

select * 
from vgcategories
where Platform is not null
order by Rank


-- Select Data that we are going to be starting with

select name, year, Genre
from vgcategories

-- Let's find out how many genres we have from vgcategories database
-- We have 12 genres in total with Action having the highest overall count

select distinct(Genre), count(*) as Genre_overall
from vgcategories
group by Genre
order by Genre_overall desc

-- Let's find out how many genre were released after 2014
-- Action video games are still the made more that the rest of the genres

select distinct(Genre), count(*) as Genre_overall
from vgcategories
where year > 2014
group by Genre
order by Genre_overall desc

-- Using CTE to create 'GenreCount'

With GenreCount (Genre, Genre_overall)
as
(
select distinct(Genre), count(*) as Genre_overall
from vgcategories
group by Genre
)

select *
from GenreCount
group by Genre, Genre_overall
order by Genre_overall


-- Using Subquery in CTE to perform the percentage of each and every genre
-- Puzzle genre has the lowest percentage 

With GenreCount (Genre, Genre_overall)
as
(
select distinct(Genre), count(*) as Genre_overall
from vgcategories
group by Genre
)

select *,Round((Cast(Genre_overall as float)/
-- This subquery calculates the total number of entries in the 'Genre_overall' column
(
select sum(Cast(Genre_overall as float)) 
from GenreCount
)
					)* 100, 0) as Percentage

from GenreCount
group by Genre, Genre_overall
order by Percentage desc


-- Time to view the video game sales database

Select *
from vgsales

-- Let's JOIN the two tables to have a broader understanding of the sales in every video game.

Select vgc.name, vgs.year, NA_sales, EU_sales, JP_sales, Other_sales, Global_Sales
from vgcategories vgc
Join vgsales vgs
	on vgc.Rank = vgs.Rank
	and vgc.Year = vgs.Year
Order by vgc.Year desc

-- Using Temp Table to perform further calculations

DROP TABLE if exists #CateVsSales
CREATE Table #CateVsSales
(Name nvarchar(255),
Genre nvarchar(255),
year numeric, 
NA_sales numeric, 
EU_sales numeric, 
JP_sales numeric, 
Other_sales numeric, 
Global_Sales numeric
)

Insert into #CateVsSales
Select vgc.name,vgc.Genre, vgs.year, NA_sales, EU_sales, JP_sales, Other_sales, Global_Sales
from vgcategories vgc
Join vgsales vgs
	on vgc.Rank = vgs.Rank
	and vgc.Year = vgs.Year
Order by vgc.Year desc

-- Using our new Temp Table, let's find the total sales in distinct genre

Select distinct(Genre), Sum(NA_sales) NA, Sum(EU_sales) EU, Sum(JP_sales) JP, Sum(Other_sales) OS, Sum(Global_Sales) GS
from #CateVsSales
group by Genre
order by GS desc

-- Let's see how these genres have performed over the years on globle sales

select distinct(Genre), year, Sum(Global_Sales) GS 
from #CateVsSales
group by Genre, year
order by year desc, GS desc

-- Let's create a new column Using CTE
with Cumfunc (Genre, year, GS)
as
(
select distinct(Genre), year, Sum(Global_Sales) GS 
from #CateVsSales
group by Genre, year
)

-- Finding the cumulative sum per year in each genre
Select *, Sum(GS) over (partition by year order by year, GS) as CumSum
From CumFunc
order by year


-- Creating View to store data for later visualizations


CREATE VIEW CateVsSales as
Select vgc.name,vgc.Genre, vgs.year, NA_sales, EU_sales, JP_sales, Other_sales, Global_Sales
from vgcategories vgc
Join vgsales vgs
	on vgc.Rank = vgs.Rank
	and vgc.Year = vgs.Year

-- Time to categorize the global sales using CASES 

SELECT name, genre, year, 
Case when Global_sales < PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Global_sales) OVER (PARTITION BY Genre) then 'Small sales'
	 when Global_sales > PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Global_sales) OVER (PARTITION BY Genre) then 'Big sales'
	 Else 'Medium sales' End as Categorized_sales

From CateVsSales
order by year desc