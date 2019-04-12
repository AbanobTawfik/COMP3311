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

-- To deal with multiple genres we can use a PlPgsql function to combine all
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
-- Note this Query was used as a skeleton for similair.php because
-- parameters were passed into the php query to increase efficiency, however
-- This is query will show the case for happy feet linking to its most similair
-- movies

-- This query uses multiple joins and subqueries to return the genre count
-- and keyword count for each movie in comparison to our input movies, in this
-- case happy feet. First we create a query to return all movies with their
-- ratings and details by joining the movie list and the rating list. Next
-- we will perform a join on a subquery to get the count for matching genre
-- between all our movies and happy feet. in the join we will join the
-- genres of our movie and happy feet and get a count of how many rows there
-- are. The same procedure is used to get the count for number of keywords
-- between each movie. Finally we sort the rows by genre count, keyword count,
-- score and finally number of reviews. All this is done in a subquery to
-- allow us to coalesce to change null rows from 0 matches, to the value 0. This
-- is particularly important because null values place higher.
CREATE OR REPLACE VIEW similar_movies(id, movie, year, matching_genres,
        matching_keywords, score, number_of_reviews) as
 SELECT big_query.id,
        big_query.title,
        big_query.year,
        coalesce(big_query.genre_count, 0) as genre_count,
        coalesce(big_query.keyword_count, 0) as keyword_count,
        big_query.imdb_score,
        big_query.num_voted_users
 -- subquery to get all movies and ratings for movies. we use a subquery
 -- to allow us to use the results of the subquery to join all movies for
 -- genre count and keyword count.
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
-- Now we want to join our subquery with the subquery that calculates the number
-- of same genres between all movies passed in and the movie we are comparing to
-- in this case happy feet.
LEFT JOIN(SELECT count(genre_list.genre) as amount,
            movie_list.id as id
     FROM genre genre_list
          JOIN movie movie_list
               ON movie_list.id = genre_list.movie_id
     -- now we want to make a query of all movies and their similar genre count
     -- to the target movie, we will use the id as identifier and then join the
     -- previous subquery on matching id and the id doesnt match our target
     -- (we dont want to say happy feet is similar to happy feet)
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
-- now we will do the exact same thing to get the count of similair keywords
-- between our target movie and our movie id.
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
-- next the query is sorted by the specification specific sort
ORDER BY genre_count DESC, keyword_count DESC,
         imdb_score DESC, num_voted_users DESC;

--------------------------------------------------------------------------------
--                                TASK E                                      --
--------------------------------------------------------------------------------
-- This question was mostly done in sql for efficiency, multiple attempts were
-- made in php but it was in magnitutes slower to querying our states.

-- i used a graph to create all first degree connections for ALL actors and
-- all movies that link these actors, so you would have duplicate nodes connect
-- on a different edge (example 2 actors act together before on multiple movie)
-- this was done simply by joining the acting table with itself on the same
-- movie id, but different actor id (every actor is obviously linked to himself)
-- this would be the basis of all degree connections. This is degree 1 and each
-- degree is built off of this in a similar way.
-- A bidirectional search was implemented in PHP since it
CREATE OR REPLACE VIEW graph(actor1_node, movie_edge, actor2_node) AS
SELECT acting_list1.actor_id,
       acting_list1.movie_id,
       acting_list2.actor_id
FROM acting acting_list1
     JOIN acting acting_list2
          ON acting_list1.movie_id = acting_list2.movie_id
             AND acting_list1.actor_id != acting_list2.actor_id;

-- The degree 1 connection function is used to filter out node1 results we dont
-- need. These functions were made to be called from php. this allows the
-- queries to be performed at a much faster rate as we are filtering early
CREATE OR REPLACE FUNCTION degree1_actors(actor_id int) RETURNS SETOF RECORD
AS $$
BEGIN
    -- return the graph entries which have the same node 1 id as
    -- our input requests
    RETURN QUERY SELECT * FROM graph WHERE graph.actor1_node = actor_id;
END; $$ language plpgsql;

-- The degree 2 connection function is used to filter out node1 results that
-- are not at degree 2 from our starting actor, we essentially want to find all
-- actors on another graph that are joined to the actor 2 on our initial degree 1
-- to get our degree 2 actors. we make sure we don't rejoin paths that have already
-- been seen (to avoid cycles we don't rejoin on the same movie/nodes)
CREATE OR REPLACE FUNCTION degree2_actors(actor_id int) RETURNS SETOF RECORD
AS $$
BEGIN
    -- We want to join the graph on another instance of the graph to get the
    -- second degree paths and make sure we dont go back to any actor on degree 1
    -- and we don't go back on any edge in degree 1.
    RETURN QUERY SELECT DISTINCT graph1.actor1_node,
                                 graph1.movie_edge,
                                 graph1.actor2_node,
                                 graph2.movie_edge,
                                 graph2.actor2_node
                 from graph graph1 JOIN graph graph2
                                   ON graph1.actor2_node = graph2.actor1_node
                                   AND graph1.actor1_node = actor_id
                                   AND graph1.actor2_node != graph1.actor1_node
                                   AND graph2.movie_edge != graph1.movie_edge
                                   AND graph2.actor2_node != graph1.actor1_node;
END; $$ language plpgsql;

-- The degree 3 connection function is used to filter out node1 results that
-- are not at degree 3 from our starting actor, we essentially want to find all
-- actors on another graph that are joined to the actor 3 on our initial degree 1
-- to get our degree 3 actors. we make sure we don't rejoin paths that have already
-- been seen (to avoid cycles we don't rejoin on the same movie/nodes)
CREATE OR REPLACE FUNCTION degree3_actors(actor_id int) RETURNS SETOF RECORD
AS $$
BEGIN
    -- This is the exact same query above except joining on 1 more graph
    -- to get next depth
    RETURN QUERY SELECT DISTINCT graph1.actor1_node,
                                 graph1.movie_edge,
                                 graph1.actor2_node,
                                 graph2.movie_edge,
                                 graph2.actor2_node,
                                 graph3.movie_edge,
                                 graph3.actor2_node
                 from graph graph1 JOIN graph graph2
                                   ON graph1.actor2_node = graph2.actor1_node
                                   AND graph1.actor1_node = actor_id
                                   AND graph1.actor2_node != graph1.actor1_node
                                   AND graph2.actor2_node != graph1.actor1_node
                                   AND graph2.movie_edge != graph1.movie_edge
                                   JOIN graph graph3
                                   ON graph2.actor2_node = graph3.actor1_node
                                   AND graph3.actor2_node != graph2.actor1_node
                                   AND graph3.actor2_node != graph1.actor1_node
                                   AND graph3.movie_edge != graph2.movie_edge
                                   AND graph3.movie_edge != graph1.movie_edge;
END; $$ language plpgsql;