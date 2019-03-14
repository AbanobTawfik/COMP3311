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

--------------------------------------------------------------------------------
--                                Question 14                                 --
--------------------------------------------------------------------------------

-- Calculate stock gains based on their prices of the first trading day
-- Dnd last trading day (i.e., the oldest "Date" and the most recent "Date"
-- Of the records stored in the ASX table). Order your result by
-- Gain in descending order and then by Code in ascending order.

-- Similair to above this query requires multiple subqueries and joins
-- In order to achieve the overall change and gain. First we have to
-- Create a subquery to make a view which has the price of the company
-- From day one, next we want to create a subquery which has the price
-- Of the company on the last day. finally we want to join with original table
-- To perform a calculation based on the first and last price
create or replace view Q14(Code, BeginPrice, EndPrice, Change, Gain) as
SELECT resultDayOne.minCode AS Code,
       resultDayOne.firstPrice,
       resultFinalDay.lastPrice,
       resultFinalDay.lastPrice - resultDayOne.firstPrice,
       (resultFinalDay.lastPrice - resultDayOne.firstPrice)
           /resultDayOne.firstPrice * 100 AS Gain
  FROM (SELECT res.*
        -- this subquery will return a view that contains the price
        -- day and code of the company from day one
        FROM(SELECT DISTINCT
               minimal.Code AS minCode,
               MIN(minimal."Date") OVER (PARTITION BY minimal.code) AS firstDay,
               minimal.price AS firstPrice
        FROM asx minimal) res
             -- now we want to join with the original asx table to
             -- get the right values where all match
             INNER JOIN asx original
                        ON original.code = res.minCode
                           AND original."Date" = res.firstDay
                           AND original.price = res.firstPrice) resultDayOne
  -- now we want to join with a subquery which will return a view that
  -- contains the price, day and code of the company from the last day
  -- this is the exact same as above just max not min
  JOIN (SELECT res2.*
        FROM(SELECT DISTINCT
               maximal.Code AS lastCode,
               MAX(maximal."Date") OVER (PARTITION BY maximal.code) AS lastDay,
               maximal.price AS lastPrice
        FROM asx maximal) res2
             INNER JOIN asx original
                        ON original.code = res2.lastCode
                        AND original."Date" = res2.lastDay
                        AND original.price = res2.lastPrice) resultFinalDay
        ON resultFinalDay.lastCode = resultDayOne.minCode
  -- order the results by gain and then code
  ORDER BY Gain DESC, Code ASC;

--------------------------------------------------------------------------------
--                                Question 15                                 --
--------------------------------------------------------------------------------

-- For all the trading records in the ASX table, produce the following
-- Statistics as a database view (where Gain is measured in percentage).
-- AvgDayGain is defined as the summation of all the daily gains (in percentage)
-- Then divided by the number of trading days (as noted above, the total number
-- Of days here should exclude the first trading day).

-- This query is very similair to the query in question 7 and has a
-- Almost exact approach. To make the query not reliant on other views
-- I will be performing the exact same query as i did on q7 in here
-- Then i will simply find the max/min/avg for price and gain
-- For each company grouped by code.
create or replace view Q15(Code, MinPrice, AvgPrice, MaxPrice, MinDayGain, AvgDayGain, MaxDayGain) as
  SELECT result.code,
         MIN(result.price),
         AVG(result.price),
         MAX(result.price),
         MIN(result.gain),
         AVG(result.gain),
         MAX(result.gain)
  -- this is the exact same query as Q7
  FROM (SELECT "Date",
               code,
               volume,
               LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date"),
               price,
               (price - LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date")),
               ((price -
                 LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date")) /
                LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date") * 100) AS gain
        FROM asx) result
  -- exclude the first day of trading (since first day cannot calculate gain
  WHERE result."Date" != (SELECT MIN("Date") FROM asx)
  GROUP by result.code;

--------------------------------------------------------------------------------
--                                Question 16                                 --
--------------------------------------------------------------------------------

-- Create a trigger on the Executive table, to
-- Check and disallow any insert or update of a Person in the Executive table
-- To be an executive of more than one company.

-- First we will make our function with returns a trigger, that will
-- Check how many companies the person we are inserting is executive for.
-- the function will raise an exception if the person is already an Executive
-- For another company. otherwise it will do nothing and return.
-- This will be applied to every row in our executive table
create or replace function executiveCheckTrigger() returns trigger
as $$
-- we are going to declare all variables requires for our check and our
-- error messages
declare
      execName text;
      execCount integer;
      execCode char(3);
BEGIN
    -- first we want to count how many companies a person is executive for
    SELECT COUNT(person) FROM executive WHERE person = new.person INTO execCount;
    -- next we want to get the name and code for the person we are making
    -- executive of another company
    SELECT Code FROM executive WHERE new.person = person INTO execCode;
    SELECT person FROM executive WHERE new.person = person INTO execName;
    -- if the person is an executive for more than 1 company then we
    -- want to raise exception to disallow and also alert user with
    -- error message that "(person) is already executive for (company)"
    IF execCount > 1
    THEN RAISE EXCEPTION '% is already an executive for  %.',execName,execCode;
    END IF;
  return new;
END; $$ language plpgsql;

-- Now we want to create a trigger that applies on any insertion/update On
-- The executive table for each row, it will apply the function above that
-- disallows a person to be a executive for more than 1 company
CREATE TRIGGER Q16
AFTER INSERT OR UPDATE ON executive
FOR EACH ROW EXECUTE PROCEDURE executiveCheckTrigger();

-- quick test
-- INSERT INTO Executive VALUES('AAD', 'Mr. Neil R. Balnaves ssssss');

--------------------------------------------------------------------------------
--                                Question 17                                 --
--------------------------------------------------------------------------------

-- Suppose more stock trading data are incoming into the ASX table.
-- Create a trigger to increase the stock's rating (as Star's) to 5
-- When the stock has made a maximum daily price gain
-- (when compared with the price on the previous trading day)
-- In percentage within its sector. For example, for a given day
-- And a given sector, if Stock A has the maximum price gain in the sector,
-- Its rating should then be updated to 5.
-- If it happens to have more than one stock with the same maximum price gain,
-- Update all these stocks' ratings to 5.
-- Otherwise, decrease the stock's rating to 1 when the stock has performed
-- The worst in the sector in terms of daily percentage price gain.
-- If there are more than one record of rating for a given stock that need to be
-- Updated, update (not insert) all these records.
-- You may assume that there are at least two trading records for each stock
-- In the existing ASX table,
-- And do not worry about the case that when the ASX table is initially empty.

-- This is a much more complicated procedure than the previous trigger.
-- First we need to create a view that has:
-- The date, sector, maximum gain for that sector, minimum gain for that sector
-- For each day in the ASX table.
-- Next we want to make a function for our trigger which will check the
-- Insertion/update to the ASX log to compare it to the maximum and minimum gain
-- For that day and sector. It will then change the rating for that company
-- IF the rating is more than the current max or lower than the current min

-- This query will create a view used for our function which contains
-- The maximum gain/minimum gain, sector and day for each day and sector
create or replace view gainView(Minim, Maxim, gainDay, gainSector) as
SELECT ret.minim AS minim,
       ret.maxim AS maxim,
       ret."Date" AS gainDay,
       ret.sector AS gainSector
  -- To do this we will want to perform a query on our subquery
  -- we want to use the same query on q7 (will just be reusing the code)
  -- to avoid creating multiple dependancies on more views. Then we will
  -- select the max/min for each sector and day from that query as our
  -- final subquery. Finally we want to join this with our category table
  -- to get the sectory of the company and exclude the first day
  FROM (SELECT DISTINCT
                -- we obtain our maximum and minimum over sector and day
                MIN(result.gain) OVER (PARTITION BY cat.sector,result."Date") AS minim,
                MAX(result.gain) OVER (PARTITION BY cat.sector,result."Date") AS maxim,
                result."Date",
                cat.sector
         FROM (SELECT
               "Date",
               code,
               (price - LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date")),
               ((price -
                 LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date")) /
                LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date") * 100) AS gain
        FROM asx) result
  JOIN "category" cat ON cat.code = result.code
  WHERE result."Date" != (SELECT MIN("Date") FROM asx)) ret;

-- This function will be used alongside the gainView view to perform the
-- Functionallity of the trigger required.
create or replace function starUpdateTrigger() returns trigger
as $$
-- Declare the maximum and minimum on the day we are inserting/updating
-- And also the gain/name of the company we are inserting/updating
declare
      highestGain float;
      lowestGain float;
      companyGain float;
      companyName text;
BEGIN
    -- we want to get the minimum gain for the day and sector
    -- using our gainView by matching the company to the sector
    -- then matching the sector to the gainview row which has
    -- the same date
    -- we will insert the minimum into our variable lowest gain
    SELECT Minim
    FROM gainView gains
    JOIN "category" cat
             ON new.code = cat.code
             AND cat.sector = gains.gainSector
             AND gains.gainDay = new."Date" INTO lowestGain;

    -- we want to perform the exact same operation as above
    -- to find the maximum instead in the exact same procedure
    -- and insert that into the highest gain variable
    SELECT Maxim
    FROM gainView gains
    JOIN "category" cat
             ON new.code = cat.code
             AND cat.sector = gains.gainSector
             AND gains.gainDay = new."Date" INTO highestGain;

    -- next we want to check our query from Q7 to see the updated/inserted
    -- gain as a comparison point and insert that into the variable companyGain
    SELECT gain
    FROM Q7 dailyTrades
    WHERE new.code = dailyTrades.Code
    AND new."Date" = dailyTrades."Date" INTO companyGain;

    -- finally we want to insert the company name into the company name variable
    -- for the messages
    SELECT "name"
    FROM company
    WHERE company.code = new.code into companyName;

    -- if the company has gained more than or equal
    -- to the maximum gain for that day
    -- and sector
    IF companyGain >= highestGain
    -- then we want to update that company to 5 star rating
    -- and inform that the company has increased to a 5 star rating
    THEN UPDATE rating
        SET star = 5
        WHERE code = new.code;
        RAISE NOTICE '% has increased to 5 star rating!', companyName;
    END IF;

    -- if the company has gained less than or equal to the lowest gain
    -- for that day and sector
    IF lowestGain >= companyGain
    -- then we want to update that company to 1 star rating
    -- and inform that the company has increased to a 1 star rating
    THEN UPDATE rating
        SET star = 1
        WHERE code = new.code;
        RAISE NOTICE '% has decreased to 1 star rating!', companyName;
    END IF;
    -- otherwise we will notify no changes has occured to the rating
    RAISE NOTICE '% has been added/updated to the asx table', companyName;
  RETURN new;
END; $$ language plpgsql;

-- Now we want to create a trigger that applies on any insertion/update On
-- The asx table for each row, it will apply the function above that
-- will change the ratings if the company has gained more than the maximum
-- gain for that sector on that day, or the lower than the minimum gain for that
-- sector on that day
CREATE TRIGGER Q17
AFTER INSERT OR UPDATE ON asx
FOR EACH ROW EXECUTE PROCEDURE starUpdateTrigger();

--------------------------------------------------------------------------------
--                                Question 18                                 --
--------------------------------------------------------------------------------

-- Stock price and trading volume data are usually incoming data and
-- Seldom involve updating existing data. However, updates are allowed in
-- Order to correct data errors. All such updates (instead of data insertion)
-- Are logged and stored in the ASXLog table.
-- Create a trigger to log any updates on Price and/or Voume in the ASX table
-- And log these updates (only for update, not inserts) into the ASXLog table.
-- Here we assume that Date and Code cannot be corrected and will be the same
-- As their original, old values. Timestamp is the date and time
-- That the correction takes place.
-- Note that it is also possible that a record is corrected more than once,
-- i.e., same Date and Code but different Timestamp.

-- This is a much simpler procedure where we simply create a function that
-- Will insert the timestamp, date, company, volume before update, price before
-- Update, into the asxlog table. this function will return a trigger that
-- Occurs on any update on the asx table
create or replace function updateASXLogTrigger() returns trigger
as $$
-- We want to declare all values whichw ill be used in the columns of the
-- asxlog table based on updated asx row
DECLARE
    timeOfUpdate timestamp;
    dateOfPreviousPrice date;
    companyCode char(3);
    previousVolume integer;
    previousPrice numeric;
BEGIN
    -- now we want to set the timestamp to 
    -- reference for which i found out that now returns timestamp
    -- https://stackoverflow.com/questions/4411311/getting-timestamp-using-mysql
    timeOfUpdate := now();
    -- next we want to get the data from the row before the update occurs
    dateOfPreviousPrice := old."Date";
    companyCode := old.code;
    previousVolume := old.volume;
    previousPrice := old.price;
    -- insert our values into the asxlog table
    INSERT INTO asxlog VALUES(timeOfUpdate,dateOfPreviousPrice,companyCode,
                              previousVolume,previousPrice);
    -- notify the user that changes have been logged
    RAISE NOTICE 'changes to % have been logged', companyCode;
  RETURN new;
END; $$ language plpgsql;

-- Now we want to create a trigger that applies on any update (only update!) On
-- The asx table for each row, it will apply the function above that
-- will log all the changes in price and volume into the asxlog table.
CREATE TRIGGER Q18
AFTER UPDATE ON asx
FOR EACH ROW EXECUTE PROCEDURE updateASXLogTrigger();

-- quick test for q17/q18

-- UPDATE ASX
--     SET price = 1
--     WHERE "Date" = '2012-03-08'
--     AND code = 'WOW'
--     AND volume = '3788100';
--------------------------------------------------------------------------------
--                                FINISHED                                    --
--------------------------------------------------------------------------------
