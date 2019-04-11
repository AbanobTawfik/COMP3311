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
-- Note this Query was used as a skeleton for acting.php because
-- parameters were passed into the php query to increase efficiency, however
-- This is an overall view of all actors and movies they acted in.

-- This query will be used to return all the movies actors have acted in and
-- All the details of the movies associated. This query will be used to solve
-- Task A by associating the actor with all the movies they have worked in
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
               LEFT JOIN acting acting_list
                          ON acting_list.actor_id = actor_list.id) actor_movie_id
         -- Join the subquery with the movie table with matching movie id's
         LEFT JOIN movie movie_list
                    ON movie_list.id = actor_movie_id.movie_id
         -- Join aswell on the rating table with matching movie id
         LEFT JOIN rating rating_list
                    ON movie_list.id = rating_list.movie_id
         -- Join aswell on the director table with the matching director id
         LEFT JOIN director director_list
                    ON director_list.id = movie_list.director_id
    -- order chronologically by the name, and then year
    ORDER BY actor_movie_id.actor_name, movie_list.year;

--------------------------------------------------------------------------------
--                                TASK B                                      --
--------------------------------------------------------------------------------
-- First we will make our function which returns all matches genres for a
-- movie id in a combined string, where each genre is seperated with the ","
-- character
create or replace function all_genres2(input_movie_id int) returns text
as $$
-- we are going to declare all variables required for return value
--
declare
      final_return_genre text;
      entry record;
BEGIN
    final_return_genre = '';
    -- scan through each entry in genre table, and if we have entry with
    -- same movie id we will conjoin them together with the , character
    FOR entry IN SELECT * FROM genre WHERE genre.movie_id = input_movie_id
        ORDER BY genre.genre ASC
    LOOP
        final_return_genre := final_return_genre||entry.genre||',';
    END LOOP;
    -- remove final , to sanitize list
    final_return_genre := RTRIM(final_return_genre, ',');
    return final_return_genre;
END; $$ language plpgsql;

-- This query will be used to return the list of all movies, with all rating
-- details attached to the table, and all genres the movie is associated with
-- we can place restrictions to receive only certain entries from this table
-- within the php script
CREATE OR REPLACE VIEW movie_list(movie, year, tv_rating, score, genres) as
    SELECT movie_list.title,
           movie_list.year,
           movie_list.content_rating,
           rating_list.imdb_score,
           all_genres2(movie_list.id)
    FROM movie movie_list
         LEFT JOIN rating rating_list
                   ON rating_list.movie_id = movie_list.id;
--------------------------------------------------------------------------------
--                                TASK C                                      --
--------------------------------------------------------------------------------

-- First we will make our function which returns all matches genres for a
-- movie id in a combined string, where each genre is seperated with the "&"
-- character
create or replace function all_genres(input_movie_id int) returns text
as $$
-- we are going to declare all variables required for return value
--
declare
      final_return_genre text;
      entry record;
BEGIN
    final_return_genre = '';
    -- scan through each entry in genre table, and if we have entry with
    -- same movie id we will conjoin to our genre list the extra genre and &
    -- character
    FOR entry IN SELECT * FROM genre WHERE genre.movie_id = input_movie_id
    LOOP
        final_return_genre := final_return_genre||entry.genre||'&';
    END LOOP;
    -- remove the final & at end of genre list to sanitize list
    final_return_genre := RTRIM(final_return_genre, '&');
    return final_return_genre;
END; $$ language plpgsql;

-- This query will be used to return all the movies and all the details of the
-- Movies associated. This query will be used to solve Task B by ordering the
-- Result by rating and including all genres with the movie
-- We can then filter our results based on that result

-- To deal with multiple genres we can use a PgPsql function to combine all
-- genres to one column entry "all genres" in our view.
CREATE OR REPLACE VIEW rankings(id, movie, year, content_rating, language,
        score, number_of_reviews,all_genres_list) as
SELECT movie_list.id as id,
       movie_list.title as title,
       movie_list.year as year,
       movie_list.content_rating as content_rating,
       movie_list.lang as lang,
       rating_list.imdb_score as imdb_score,
       rating_list.num_voted_users as num_voted_users,
       all_genres(movie_list.id)
FROM movie movie_list
   LEFT JOIN rating rating_list
              ON movie_list.id = rating_list.movie_id
ORDER BY rating_list.imdb_score, rating_list.num_voted_users DESC;

--------------------------------------------------------------------------------
--                                TASK D                                      --
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW similar_movies(id, movie, year, matching_genres,
        matching_keywords, score, number_of_reviews) as
 SELECT big_query.id,
        big_query.title,
        big_query.year,
        coalesce(big_query.genre_count, 0) as genre_count,
        coalesce(big_query.keyword_count, 0) as keyword_count,
        big_query.imdb_score,
        big_query.num_voted_users
 FROM  (SELECT movie_list.id as id,
       movie_list.title as title,
       movie_list.year as year,
       join_query_genre.amount as genre_count,
       join_query_keyword.amount as keyword_count,
       rating_list.imdb_score as imdb_score,
       rating_list.num_voted_users as num_voted_users
FROM movie movie_list
     LEFT JOIN rating rating_list
               ON movie_list.id = rating_list.movie_id
LEFT JOIN(SELECT count(genre_list.genre) as amount,
            movie_list.id as id
     FROM genre genre_list
          JOIN movie movie_list
               ON movie_list.id = genre_list.movie_id
     JOIN(SELECT genre_list.genre,
                 movie_list.id
                 FROM genre genre_list
                      JOIN movie movie_list
                           ON genre_list.movie_id = movie_list.id
                      WHERE movie_list.title ILIKE 'Happy FeeT'
                 ) AS genre_join
                      ON genre_join.genre = genre_list.genre
     GROUP BY movie_list.id, genre_join.id
              HAVING genre_join.id != movie_list.id) as join_query_genre
          ON join_query_genre.id = movie_list.id
LEFT JOIN(SELECT count(keyword_list.keyword) as amount,
            movie_list.id as id
     FROM keyword keyword_list
          JOIN movie movie_list
               ON movie_list.id = keyword_list.movie_id
     JOIN(SELECT keyword_list.keyword,
                 movie_list.id
                 FROM keyword keyword_list
                      JOIN movie movie_list
                           ON keyword_list.movie_id = movie_list.id
                      WHERE movie_list.title ILIKE 'Happy FeeT'
                 ) AS keyword_join
                      ON keyword_join.keyword = keyword_list.keyword
     GROUP BY movie_list.id, keyword_join.id
              HAVING keyword_join.id != movie_list.id) as join_query_keyword
          ON join_query_keyword.id = movie_list.id)big_query
ORDER BY genre_count DESC, keyword_count DESC,
         imdb_score DESC, num_voted_users DESC;

--------------------------------------------------------------------------------
--                                TASK E && F                                 --
--------------------------------------------------------------------------------

create or replace view graph(actor1_node, movie_edge, actor2_node) as
SELECT acting_list1.actor_id,
       acting_list1.movie_id,
       acting_list2.actor_id
FROM acting acting_list1
     JOIN acting acting_list2
          ON acting_list1.movie_id = acting_list2.movie_id
             AND acting_list1.actor_id != acting_list2.actor_id;

create or replace view test_bill_clinton_chris_evans(degree0, link01, degree1, link12
                                                      degree2, link23, degree3,
                                                      link34, degree4, link45, degree5) as
SELECT DISTINCT graph1.actor1_node,
       graph1.movie_edge,
       graph1.actor2_node,
       graph2.movie_edge,
       graph2.actor2_node,
       graph3.movie_edge,
       --graph3.actor2_node,
       sub1.*
FROM graph graph1
JOIN graph graph2
    ON graph1.actor2_node = graph2.actor1_node
        AND graph1.actor1_node = '301'
        AND graph2.actor2_node != graph1.actor1_node
        AND graph2.movie_edge != graph1.movie_edge
JOIN graph graph3
    ON graph2.actor2_node = graph3.actor1_node
       AND graph3.actor2_node != graph2.actor1_node
       AND graph3.movie_edge != graph2.movie_edge
       AND graph3.movie_edge != graph2.movie_edge
       AND graph3.movie_edge != graph1.movie_edge
JOIN graph graph4
    ON graph3.actor2_node = graph4.actor1_node
       AND graph4.actor2_node != graph3.actor1_node
        AND graph4.movie_edge != graph3.movie_edge
        AND graph4.movie_edge != graph2.movie_edge
        AND graph4.movie_edge != graph1.movie_edge

join (SELECT DISTINCT graph3.actor2_node as lastlink,
       graph3.movie_edge,
       graph2.actor2_node,
       graph2.movie_edge,
       graph1.actor2_node,
       graph1.movie_edge,
       graph1.actor1_node
FROM graph graph1
JOIN graph graph2
    ON graph1.actor2_node = graph2.actor1_node
        AND graph1.actor1_node = '3003'
        AND graph2.actor2_node != graph1.actor1_node
        AND graph2.movie_edge != graph1.movie_edge
JOIN graph graph3
    ON graph2.actor2_node = graph3.actor1_node
       AND graph3.actor2_node != graph2.actor1_node
       AND graph3.movie_edge != graph2.movie_edge
       AND graph3.movie_edge != graph1.movie_edge
JOIN graph graph4
    ON graph3.actor2_node = graph4.actor1_node
       AND graph4.actor2_node != graph3.actor1_node
        AND graph4.movie_edge != graph3.movie_edge
        AND graph4.movie_edge != graph2.movie_edge
        AND graph4.movie_edge != graph1.movie_edge) as sub1
    ON sub1.lastlink = graph3.actor2_node;
