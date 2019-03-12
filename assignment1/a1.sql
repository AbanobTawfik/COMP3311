create or replace view Q1(Name, Country) as
  SELECT Name, Country
  FROM company
  WHERE Country != 'Australia';

create or replace view Q2(Code) as
  SELECT code
  FROM executive
  GROUP BY code
  HAVING COUNT(code) > 5;

create or replace view Q3(Name) as
  SELECT name
  FROM category
         RIGHT JOIN company on category.sector = 'Technology'
  WHERE company.code = category.code
    AND category.sector IS NOT NULL
  ORDER BY company.name;

create or replace view Q4(Sector, Number) as
  SELECT sector, count(sector)
  FROM category
  GROUP BY sector;

create or replace view Q5(Name) as
  SELECT DISTINCT person
  FROM executive
         LEFT JOIN category ON category.sector = 'Technology'
  WHERE category.code = executive.code
  ORDER BY executive.person;

create or replace view Q6(Name) as
  SELECT DISTINCT name
  FROM company
         JOIN category ON category.sector = 'Services'
  WHERE company.code = category.code
    AND company.zip LIKE '2%'
    AND category.code IS NOT NULL
  ORDER BY company.name;

create or replace view Q7("Date", Code, Volume, PrevPrice, Price, Change, Gain) as
  SELECT result.*
  FROM (SELECT "Date",
               code,
               volume,
               LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date"),
               price,
               (price - LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date")),
               ((price -
                 LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date")) /
                LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date") * 100)
        FROM asx) result
  WHERE result."Date" != (SELECT MIN("Date") from asx);


create or replace view Q8("Date", Code, Volume) as
  SELECT result.*
  FROM (SELECT "Date",
               Code,
               MAX(Volume) OVER (PARTITION BY "Date" ORDER BY "Date") as volume
        FROM asx) result
         INNER JOIN asx original ON original.Code = result.code
                                      AND original.volume = result.volume
                                      AND original."Date" = result."Date"
  ORDER BY "Date", Code;

create or replace view Q9(Sector, Industry, Number) as
  SELECT Sector, Industry, Count(Industry)
  FROM category
  GROUP BY Industry, Sector
  order by Sector, Industry;

create or replace view Q10(Code, Industry) as
  SELECT original.code, result.Industry
  FROM (SELECT Industry, COUNT(Industry) OVER (PARTITION BY Industry) as counter
        FROM category) result
         INNER JOIN category original ON original.industry = result.industry
                                           AND result.counter = 1;

create or replace view Q11(Sector, AvgRating) as
  SELECT result.Sector, AVG(
                          result.rating) --OVER (PARTITION BY result1.Sector)
  FROM (SELECT c.code as code, c.Sector as sector, r.star as rating
        from rating r
               INNER JOIN category c ON c.code = r.code) result
  GROUP BY result.sector;

create or replace view Q12(Name) as
  SELECT result.name
  FROM (SELECT DISTINCT person                                   as name,
                        count(person) OVER (PARTITION BY person) as amount
        FROM executive) result
  WHERE result.amount > 1
  ORDER BY result.name;

create or replace view Q13(Code, Name, Address, Zip, Sector) as
  SELECT originalCategory.code, originalCompany.Name, originalCompany.address,
         originalCompany.zip, originalCategory.sector
  FROM category originalCategory
  JOIN company originalCompany
      on originalCategory.code = originalCompany.code
      AND originalCompany.country = 'Australia'
  LEFT JOIN (
      SELECT category1.sector as companySector,
               company1.country as companyAddress,
               company1.code as invalidCodes,
               COUNT(company1.country) OVER (PARTITION BY sector) as sectorsOutOfAustralia
        FROM company company1 join category category1 on
            company1.code = category1.code
            WHERE company1.country != 'Australia'
      )AS comp
  ON originalCategory.sector = comp.companySector
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
       (resultFinalDay.lastPrice - resultDayOne.firstPrice)/resultDayOne.firstPrice * 100 as Gain
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


-- create or replace view test(Sector, country, code, OutsideAustralia) as
--   SELECT comp.*
--   FROM(
--         SELECT category1.sector as companySector,
--                company1.country as companyAddress,
--                company1.code as invalidCodes,
--                COUNT(company1.country) OVER (PARTITION BY sector) as sectorsOutOfAustralia
--         FROM company company1 join category category1 on
--             company1.code = category1.code
--             WHERE company1.country != 'Australia'
--       ) comp
