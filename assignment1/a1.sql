--------------------------------------------------------------------------------
--                             Abanob Tawfik                                  --
--                                z5075490                                    --
--                          COMP3311 Assignment 1                             --
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                                Question 1                                  --
--------------------------------------------------------------------------------
-- List all the company names (and countries)
-- That are incorporated outside Australia.

-- The query is self explanatory for this question
create or replace view Q1(Name, Country) as
  SELECT company_list.Name,
         company_list.Country
  FROM company company_list
  WHERE company_list.Country != 'Australia';

--------------------------------------------------------------------------------
--                                Question 2                                  --
--------------------------------------------------------------------------------

-- List all the company codes that have more
-- Than five executive members on record (i.e., at least six).

-- The query is self explanatory for this question
create or replace view Q2(Code) as
  SELECT executive_list.code
  FROM executive executive_list
  GROUP BY executive_list.code
  HAVING COUNT(executive_list.code) > 5;

--------------------------------------------------------------------------------
--                                Question 3                                  --
--------------------------------------------------------------------------------

-- List all the company names that are in the sector of "Technology"

-- This query requires a join between the company table and the category table
-- Since the company table doesn't not contain the sector information however
-- The category table does, so we join the two table where the company
-- Codes match
create or replace view Q3(Name) as
  SELECT company_list.name
  FROM category category_list
        -- join the category table and company table
        -- to access sector information for a company
       JOIN company company_list
            -- only join the rows from the category table
            -- that are in the technology sector
            ON category_list.sector = 'Technology'
  -- and the rows with matching codes from the company table and category table
  WHERE company_list.code = category_list.code;

--------------------------------------------------------------------------------
--                                Question 4                                  --
--------------------------------------------------------------------------------

-- Find the number of Industries in each Sector

-- The code for this Query is self explanatory
-- We chose distinct industry count since there are
-- Multiple companies that work in the same industry
-- And we don't want to double count them
create or replace view Q4(Sector, Number) as
  SELECT category_list.sector,
         count(DISTINCT category_list.industry)
  FROM category category_list
  GROUP BY category_list.sector;

--------------------------------------------------------------------------------
--                                Question 5                                  --
--------------------------------------------------------------------------------

-- Find all the executives (i.e., their names) that are affiliated with
-- Companies in the sector of "Technology". If an executive is affiliated
-- With more than one company, he/she is counted if one of these companies
-- Is in the sector of "Technology".

-- This query requires a join since the executive table does not contain
-- The sector, so we perform a join on the condition that the code
-- For the company the executive is for, and the code for the company in the
-- Sector table are equal. this allows us to see which sector the executive
-- Is in.

-- As an interesting notes due to the trigger we place on Question 16, the
-- Second statement cannot be true unless run without the trigger
create or replace view Q5(Name) as
  SELECT DISTINCT executive_list.person
  FROM executive executive_list
       -- we perform a join on our executive table and our category table
       -- to link the person to a sector by matching the rows
       -- which have the same company code
       JOIN category category_list
            ON category_list.sector = 'Technology'
  WHERE category_list.code = executive_list.code;

--------------------------------------------------------------------------------
--                                Question 6                                  --
--------------------------------------------------------------------------------

-- List all the company names in the sector of "Services" that are
-- Located in Australia with the first digit of their zip code being 2.

-- This query is slightly more complicated than the previous joins
-- In the condition that the companys it matches must have a zip that
-- Begins with '2'
-- To do this we will add another condition to our join
create or replace view Q6(Name) as
  SELECT DISTINCT company_list.name
  FROM company company_list
       -- similair to previous question, join the companies who's sector
       -- is services
       JOIN category category_list
            ON category_list.sector = 'Services'
  WHERE company_list.code = category_list.code
    -- set the condition that the company code from the category table
    -- matches the company code from the company table
    -- and the company zip begins in 2 followed by other values
    AND company_list.zip LIKE '2%';

--------------------------------------------------------------------------------
--                                Question 7                                  --
--------------------------------------------------------------------------------

-- Create a database view of the ASX table that contains previous Price,
-- Price change (in amount, can be negative) and Price gain
-- (in percentage, can be negative). (Note that the first trading day should be
-- Excluded in your result.)
-- For example, if the PrevPrice is 1.00, Price is 0.85;
-- Then Change is -0.15 and Gain is -15.00 (in percentage
-- But you do not need to print out the percentage sign).

-- This query simply requires calculations performed on the asx table
-- With the same asx table shifted by 1 (using results of previous day)
-- Excluding the first day. To do this we use LAG
-- Which will take the previous row value over a partition
create or replace view Q7("Date", Code, Volume, PrevPrice, Price, Change, Gain) as
  SELECT result.*
  FROM (SELECT "Date",
               code,
               volume,
               -- We will take the previous row result for our previous price
               -- By grouping the rows by the company code, and taking the order
               -- From date, this allows us to pick the previous price
               LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date"),
               price,
               -- This calculation takes the change by the following
               -- Change = current price - old price
               (price - LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date")),
               -- This calculation takes the gain by the following
               -- Gain = (current price - old price) / old price * 100
               ((price -
                 LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date")) /
                LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date") * 100)
        FROM asx) result
  -- We exclude the first day of trading since we cannot workout previous
  -- Data from the very first day
  WHERE result."Date" != (SELECT MIN("Date") FROM asx);

--------------------------------------------------------------------------------
--                                Question 8                                  --
--------------------------------------------------------------------------------

-- Find the most active trading stock (the one with the maximum trading volume;
-- If more than one, output all of them) on every trading day. Order your
-- Output by "Date" and then by Code.

-- This query will find the row with the highest volume of stock
-- Traded for each date. This is done by finding the rows with the maximum
-- Volume, grouped by the date (this effectively finds the day with the
-- Maximum volume). This is joined with the original table with the condition
-- that all field values are the same, this is to remove the case where
-- all companies are shown with maximum traded volume (i.e. correct value
-- For maximum, but all rows display this).
create or replace view Q8("Date", Code, Volume) as
  SELECT result.*
  FROM (SELECT "Date",
               Code,
               MAX(Volume) OVER (PARTITION BY "Date" ORDER BY "Date") AS volume
        FROM asx) result
                  -- we join the results from our first subquery that
                  -- returns the rows with maximum volume, however
                  -- every company on every date shows trading at max volume
                  -- so we join on the condition that all attributes match
                  -- on the original company to filter our results
                  INNER JOIN asx original
                             ON original.Code = result.code
                             AND original.volume = result.volume
                             AND original."Date" = result."Date"
  -- first we order our output by date, then by code
  ORDER BY "Date",
           Code;

--------------------------------------------------------------------------------
--                                Question 9                                  --
--------------------------------------------------------------------------------

-- Find the number of companies per Industry.
-- Order your result by Sector and then by Industry.

-- This is a simple Query that explains itself.
-- We do not use distinct under the assumption that company names are unique.
-- To do this we group our Sector and Industry
-- and perform a count()
create or replace view Q9(Sector, Industry, Number) as
  SELECT category_list.Sector,
         category_list.Industry,
         Count(category_list.Industry)
  FROM category category_list
  GROUP BY category_list.Industry,
           category_list.Sector
  -- first we order our output by sector, then by industry
  ORDER BY category_list.Sector,
           category_list.Industry;

--------------------------------------------------------------------------------
--                                Question 10                                 --
--------------------------------------------------------------------------------

-- List all the companies (by their Code)
-- that are the only one in their Industry (i.e., no competitors).

-- This query is very simple, we will find the rows in category where,
-- The count of the industry column returns 1, this will be done by
-- First performing a subquery to output industry, and the number of companies
-- In that industry
-- Then we join that query with the original table
-- Where the row industry  matches
-- And the count is 1
create or replace view Q10(Code, Industry) as
  SELECT original.code,
         result.Industry
  -- first we will perform a query to count how many companies
  -- are in the industry by performing a count
  FROM (SELECT Industry,
               -- count the number of rows grouped by industry
               COUNT(Industry) OVER (PARTITION BY Industry) AS counter
        FROM category) result
             -- now we want to join our previous
             -- Subquery with the original table where
             -- the industry matches and the count = 1
             INNER JOIN category original
                        ON original.industry = result.industry
                           AND result.counter = 1;

--------------------------------------------------------------------------------
--                                Question 11                                 --
--------------------------------------------------------------------------------

-- List all sectors ranked by their average ratings in descending order.
-- AvgRating is calculated by finding the average AvgCompanyRating for each
-- Sector (where AvgCompanyRating is the average rating of a company).

-- This query requires us to first combine columns from the category table
-- And the rating table, to provide a rating to each row in the category table
-- This will be done by a simple join in a subquery. Then we will
-- Need to take the average for each sector by grouping the sector then ordering
-- In descending order.
create or replace view Q11(Sector, AvgRating) as
  SELECT result.Sector,
         AVG(result.rating) as AvgRating
  -- first we want to make a query that contains
  -- the company code, sector and rating
  -- by joining our rating table and category table
  -- this will allow us to take the average rating for sectors
  FROM (SELECT category_list.code AS code,
               category_list.Sector AS sector,
               rating_list.star AS rating
        FROM rating rating_list
             -- join with the rating table to add a rating to our
             -- sector, we will join on the condition rows
             -- have matching company codes
             INNER JOIN category category_list
                        ON category_list.code = rating_list.code) result
  -- group the results by sectors
  GROUP BY result.sector
  -- order by rating in descending order
  ORDER BY AvgRating DESC;

--------------------------------------------------------------------------------
--                                Question 12                                 --
--------------------------------------------------------------------------------

-- Output the person names of the executives that are
-- Affiliated with more than one company.

-- This a very simple query, First we want to perform a subquery
-- To create a table of DISTINCT (incase executive for more than one company)
-- People, and the amount of companies they are an executive for
-- Then we will perform our main query to select the ones who have
-- count greater than 1
create or replace view Q12(Name) as
  SELECT result.name
  FROM (SELECT DISTINCT person as name,
                        -- we perform our count grouped by the person name
                        count(person) OVER (PARTITION BY person) as amount
        FROM executive) result
  WHERE result.amount > 1;

--------------------------------------------------------------------------------
--                                Question 13                                 --
--------------------------------------------------------------------------------

-- Find all the companies with a registered address in Australia,
-- In a Sector where there are no overseas companies in the same Sector.
-- I.e., they are in a Sector that all companies there
-- have local Australia address.

-- This is a very complicated query as there are many steps to it
-- First we want to join the tables category and company under the conditions
-- 1. company code is = category code
-- 2. company is located in australia
-- Creating our first query to retrieve company code, name,
-- Address, zip and sector located in Australia
-- Next we want to join this with another Query
-- The query for our join will be to gather all the sectors with companies
-- Outside of Australia as an exclusion list. This can allow us to
-- Exclude all companies in the sector that are in the exclusion list
-- We join on this query under the condition that the company sector and
-- Exclusion sector are equal, only when value is null
-- This will exclude any row from our first query in the exclusion list
create or replace view Q13(Code, Name, Address, Zip, Sector) as
  SELECT category_list.code,
         company_list.Name,
         company_list.address,
         company_list.zip,
         category_list.sector
  FROM category category_list
           -- join our category and sector table under the condition that
           -- the codes are equivalent and the company is located in Australia
           JOIN company company_list
            ON category_list.code = company_list.code
            AND company_list.country = 'Australia'
  -- Now that we have our table of ALL companies that are in Australia
  -- with all the columns required in the view, we need to remove the
  -- rows which are in a sector that have other companies out of Australia
  -- in the same sector
  LEFT JOIN (
      -- This subquery will select the companies that are out of australia
      -- and list the sector that they are in, as this sector will now be
      -- apart of the exclusion list
      -- only rows in the exclusion list sector will be returned
  
      SELECT category1.sector AS companySector,
             company1.country AS companyAddress,
             company1.code AS invalidCodes
        FROM company company1
             -- Join the company table with the category table
             -- under the condition that the company is out of Australia
             -- and the category code and company code are equivalent
             JOIN category category1
                  ON company1.code = category1.code
                  WHERE company1.country != 'Australia'
      )AS comp
  -- Now we will do an exclusion join by matching our first query of
  -- all companies in Australia with the condition that
  -- the sector from the exclusion list is equivalent and that the sector 
  -- is null, which will exclude the row that contains sector from exclusion
  -- list
  ON category_list.sector = comp.companySector
     WHERE Comp.companySector IS NULL;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
create or replace view Q14(Code, BeginPrice, EndPrice, Change, Gain) as
SELECT resultDayOne.minCode as Code,
       resultDayOne.firstPrice,
       resultFinalDay.lastPrice,
       resultFinalDay.lastPrice - resultDayOne.firstPrice,
       (resultFinalDay.lastPrice - resultDayOne.firstPrice)
           /resultDayOne.firstPrice * 100 as Gain
  FROM (SELECT res.*
        FROM(SELECT DISTINCT
               minimal.Code as minCode,
               MIN(minimal."Date") OVER (PARTITION BY minimal.code) as firstDay,
               minimal.price as firstPrice
        FROM asx minimal) res
      INNER JOIN asx original
          ON original.code = res.minCode
          AND original."Date" = res.firstDay
          AND original.price = res.firstPrice) resultDayOne
  JOIN (SELECT res2.*
        FROM(SELECT DISTINCT
               maximal.Code as lastCode,
               MAX(maximal."Date") OVER (PARTITION BY maximal.code) as lastDay,
               maximal.price as lastPrice
        FROM asx maximal) res2
      INNER JOIN asx original
          ON original.code = res2.lastCode
          AND original."Date" = res2.lastDay
          AND original.price = res2.lastPrice) resultFinalDay
  ON resultFinalDay.lastCode = resultDayOne.minCode
  ORDER BY Gain desc, Code asc;

create or replace view Q15(Code, MinPrice, AvgPrice, MaxPrice, MinDayGain, AvgDayGain, MaxDayGain) as
  SELECT result.code,
         MIN(result.price),
         AVG(result.price),
         MAX(result.price),
         MIN(result.gain),
         AVG(result.gain),
         MAX(result.gain)
  FROM (SELECT "Date",
               code,
               volume,
               LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date"),
               price,
               (price - LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date")),
               ((price -
                 LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date")) /
                LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date") * 100) as gain
        FROM asx) result
  WHERE result."Date" != (SELECT MIN("Date") from asx)
  GROUP by result.code;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
create or replace function executiveCheckTrigger() returns trigger
as $$
declare
      execName text;
      execCount integer;
      execCode char(3);
BEGIN
    select COUNT(person) from executive WHERE person = new.person INTO execCount;
    select Code from executive WHERE new.person = person INTO execCode;
    select person from executive where new.person = person INTO execName;
    if execCount > 1
    then raise exception '% is already an executive for  %.',execName,execCode;
    end if;
  return new;
END; $$ language plpgsql;


CREATE TRIGGER Q16
AFTER insert OR UPDATE ON executive
FOR EACH ROW EXECUTE PROCEDURE executiveCheckTrigger();
INSERT INTO Executive VALUES('AAD', 'Mr. Neil R. Balnaves ssssss');
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
create or replace view gainView(Minim, Maxim, gainDay, gainSector) as
SELECT ret.minim as minim,
       ret.maxim as maxim,
       ret."Date" as gainDay,
       ret.sector as gainSector
  FROM ( SELECT DISTINCT MIN(result.gain) OVER (PARTITION BY cat.sector,result."Date") as minim,
                MAX(result.gain) OVER (PARTITION BY cat.sector,result."Date") as maxim,
                result."Date",
                cat.sector
         FROM (SELECT "Date",
               code,
               (price - LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date")),
               ((price -
                 LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date")) /
                LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date") * 100) as gain
        FROM asx) result
  JOIN "category" cat ON cat.code = result.code
  WHERE result."Date" != (SELECT MIN("Date") from asx)) ret;

create or replace function starUpdateTrigger() returns trigger
as $$
declare
      highestGain float;
      lowestGain float;
      companyGain float;
      companyName text;
BEGIN

    SELECT Minim
    from gainView gains
    JOIN "category" cat
             on new.code = cat.code
             and cat.sector = gains.gainSector into highestGain;

    SELECT Maxim
    from gainView gains
    JOIN "category" cat
             on new.code = cat.code
             and cat.sector = gains.gainSector into lowestGain;

    SELECT gain
    from Q7 dailyTrades
    Where new.code = dailyTrades.Code
    AND new."Date" = dailyTrades."Date" INTO companyGain;

    SELECT "name"
    from company
    WHERE company.code = new.code into companyName;

    if companyGain >= highestGain
    THEN UPDATE rating
        SET star = 5
        WHERE code = new.code;
        raise notice '% has increased to 5 star rating!', companyName;
    END IF;
    if lowestGain >= companyGain
    THEN UPDATE rating
        SET star = 1
        WHERE code = new.code;
        raise notice '% has decreased to 1 star rating!', companyName;
    END IF;
    raise notice '% has been added to the asx table', companyName;
  return new;
END; $$ language plpgsql;

CREATE TRIGGER Q17
AFTER insert OR UPDATE ON asx
FOR EACH ROW EXECUTE PROCEDURE starUpdateTrigger();
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
create or replace function updateASXLogTrigger() returns trigger
as $$
DECLARE
    timeOfUpdate timestamp;
    dateOfPreviousPrice date;
    companyCode char(3);
    previousVolume integer;
    previousPrice numeric;
BEGIN
    timeOfUpdate := now();
    dateOfPreviousPrice := old."Date";
    companyCode := old.code;
    previousVolume := old.volume;
    previousPrice := old.price;
    INSERT into asxlog values(timeOfUpdate,dateOfPreviousPrice,companyCode,
                              previousVolume,previousPrice);
    raise notice 'changes to % have been logged', companyCode;
  return new;
END; $$ language plpgsql;

CREATE TRIGGER Q18
AFTER UPDATE ON asx
FOR EACH ROW EXECUTE PROCEDURE updateASXLogTrigger();


-- UPDATE ASX
--     SET price = 1
--     WHERE "Date" = '2012-03-08'
--     AND code = 'WOW'
--     AND volume = '3788100';
