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
  SELECT originalCategory.code, originalCompany.name, originalCompany.address,
         originalCompany.zip, originalCategory.sector
  FROM(
      SELECT category1.sector as companySector,
               company1.country as companyAddress,
               company1.code as invalidCodes,
               COUNT(company1.country) OVER (PARTITION BY sector) as sectorsOutOfAustralia
        FROM company company1 join category category1 on
            company1.code = category1.code
            WHERE company1.country != 'Australia'
      ) comp

   RIGHT OUTER JOIN category originalCategory
       ON originalCategory.sector not in (select companySector from comp)
   JOIN company originalCompany
       ON originalCompany.country = 'Australia'
       AND originalCompany.code = originalCategory.code;

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
