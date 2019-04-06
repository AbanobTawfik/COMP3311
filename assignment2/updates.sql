-- COMP3311 19s1 Assignment 2
--
-- updates.sql
--
-- Written by Abanob Tawfik (z5075490), Apr 2019

-- This script takes a "vanilla" imdb database (a2.db) and
-- make all of the changes necessary to make the database
-- work correctly with the PHP scripts.


-- This is to ensure that there is no trailing spaces in movie titles,
-- As some tasks need to perform full title search.
UPDATE movie SET title = TRIM (title);

--------------------------------------------------------------------------------
--                                TASK A                                      --
--------------------------------------------------------------------------------
-- This query will be used to return all the movies actors have acted in and
-- All the details of the movies associated. This query will be used to solve
-- Task A by assosciating the actor with all the movies they have worked in
-- And all details of the movie.

-- This query uses multiple joins to link data between multiple tables. We want
-- To try link all the movies to the actors and all the details of that movie
-- Including the director name from the director table, and rating from the
-- Rating table
CREATE OR REPLACE VIEW ACTORS_MOVIE(actor, movie, director, year, tv_rating,
        rating) as
    SELECT actor_movie_id.actor_name,
           movie_list.title,
           director_list.name,
           movie_list.year,
           movie_list.content_rating,
           rating_list.imdb_score
    -- First we want to create a subquery to return the movie ids an actor has
    -- Acted in, we want to join first the actor name and movie id from the
    -- Actor table and acting table.
    FROM (SELECT actor_list.name as actor_name,
                 acting_list.movie_id as movie_id
          FROM actor actor_list
               INNER JOIN acting acting_list
                          ON acting_list.actor_id = actor_list.id) actor_movie_id
         -- Join the subquery with the movie table with matching movie id's
         INNER JOIN movie movie_list
                    ON movie_list.id = actor_movie_id.movie_id
         -- Join aswell on the rating table with matching movie id
         INNER JOIN rating rating_list
                    ON movie_list.id = rating_list.movie_id
         -- Join aswell on the director table with the matching director id
         INNER JOIN director director_list
                    ON director_list.id = movie_list.director_id
    -- order chronologically by the name, and then year
    ORDER BY actor_movie_id.actor_name, movie_list.year;

