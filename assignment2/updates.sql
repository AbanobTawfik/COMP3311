-- COMP3311 19s1 Assignment 2
--
-- updates.sql
--
-- Written by Abanob Tawfik (z5075490), Apr 2019

--  This script takes a "vanilla" imdb database (a2.db) and
--  make all of the changes necessary to make the database
--  work correctly with your PHP scripts.
--  
--  Such changes might involve adding new views,
--  PLpgSQL functions, triggers, etc. Other changes might
--  involve dropping or redefining existing
--  views and functions (if any and if applicable).
--  You are not allowed to create new tables for this assignment.
--  
--  Make sure that this script does EVERYTHING necessary to
--  upgrade a vanilla database; if we need to chase you up
--  because you forgot to include some of the changes, and
--  your system will not work correctly because of this, you
--  will lose half of your assignment 2 final mark as penalty.
--

--  This is to ensure that there is no trailing spaces in movie titles,
--  as some tasks need to perform full title search.
UPDATE movie SET title = TRIM (title);

CREATE OR REPLACE VIEW ACTORS_MOVIE(actor, movie, director, year, tv_rating,
        rating) as
    SELECT actor_movie_id.actor_name,
           movie_list.title,
           director_list.name,
           movie_list.year,
           movie_list.content_rating,
           rating_list.imdb_score
    FROM (SELECT actor_list.name as actor_name,
                 acting_list.movie_id as movie_id
          FROM actor actor_list
               INNER JOIN acting acting_list
                          ON acting_list.actor_id = actor_list.id) actor_movie_id
         INNER JOIN movie movie_list
                    ON movie_list.id = actor_movie_id.movie_id
         INNER JOIN rating rating_list
                    ON movie_list.id = rating_list.movie_id
         INNER JOIN director director_list
                    ON director_list.id = movie_list.director_id
    ORDER BY actor_movie_id.actor_name, movie_list.year;


--  Add your code below
--
