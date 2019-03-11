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
  SELECT person
  FROM executive
         LEFT JOIN category ON category.sector = 'Technology'
  WHERE category.code = executive.code
    AND category.code IS NOT NULL
  ORDER BY executive.person;

create or replace view Q6(Name) as
  SELECT name
  FROM company
         RIGHT JOIN category ON category.sector = 'Services'
  WHERE company.code = category.code
    AND company.zip LIKE '2%'
    AND category.code IS NOT NULL
  ORDER BY company.name;

create or replace view Q7("Date", Code, Volume, PrevPrice, Price, Change, Gain) as
  SELECT result.*
  FROM (
       SELECT "Date",
         code,
         volume,
         LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date"),
         price,
         (price - LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date")),
         ((price - LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date")) /
          LAG(price, 1) OVER (PARTITION BY code ORDER BY "Date") * 100)
       FROM asx
       ) result
  WHERE result."Date" != (SELECT MIN("Date") from asx);
