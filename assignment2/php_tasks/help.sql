--
--
-- SELECT actor_list.id as degree0actor,
--        acting_list.movie_id as degree01link,
--        actor_list2.id as degree1actor
-- FROM actor actor_list
--      JOIN acting acting_list
--           ON acting_list.actor_id = actor_list.id
--              AND actor_list.name ILIKE 'Tom Cruise'
--      JOIN movie movie_list
--           ON movie_list.id = acting_list.movie_id
--      JOIN acting acting_list2
--           ON acting_list2.movie_id = acting_list.movie_id
--      JOIN actor actor_list2
--           ON actor_list2.id = acting_list2.actor_id
--              AND acting_list2.actor_id != acting_list.actor_id
--      JOIN(SELECT actor
--
--           ON actor_list3.id != actor_list.id) as degree2;
--
--
-- SELECT acting_list1.actor_id as degree0,
--        acting_list1.movie_id,
--        acting_list2.actor_id as degree1,
--        degree2.movie_id,
--        degree2.actor2 as degree2
-- FROM acting acting_list1
--      JOIN acting acting_list2
--           ON acting_list1.movie_id = acting_list2.movie_id
--              AND acting_list1.actor_id = 301
--              AND acting_list1.actor_id != acting_list2.actor_id
-- JOIN (SELECT degree2_acting_list1.actor_id as actor1,
--              degree2_acting_list1.movie_id,
--              degree2_acting_list2.actor_id as actor2
--       FROM acting degree2_acting_list1
--             JOIN acting degree2_acting_list2
--                  ON degree2_acting_list1.movie_id = degree2_acting_list2.movie_id
--                  AND degree2_acting_list1.actor_id != degree2_acting_list2.actor_id) as degree2
--       ON degree2.actor1 = acting_list2.actor_id
--          AND degree2.actor2 != acting_list1.actor_id
-- JOIN ;

--
-- SELECT acting_list1.actor_id,
--        acting_list1.movie_id,
--        acting_list2.actor_id,
--        degree2.movie_id,
--        degree2.actor2,
--        degree3.movie_id,
--        degree3.actor2
-- FROM acting acting_list1
--      JOIN acting acting_list2
--           ON acting_list1.movie_id = acting_list2.movie_id
--              AND acting_list1.actor_id = 301
--              AND acting_list1.actor_id != acting_list2.actor_id
-- JOIN (SELECT degree1_acting_list1.actor_id as actor1,
--              degree1_acting_list1.movie_id,
--              degree2_acting_list2.actor_id as actor2
--       FROM acting degree1_acting_list1
--             JOIN acting degree2_acting_list2
--                  ON degree1_acting_list1.movie_id = degree2_acting_list2.movie_id
--                  AND degree1_acting_list1.actor_id != degree2_acting_list2.actor_id) as degree2
--       ON degree2.actor1 = acting_list2.actor_id
--          AND degree2.actor2 != acting_list1.actor_id
-- JOIN (SELECT degree3_acting_list1.actor_id as actor1,
--              degree3_acting_list1.movie_id,
--              degree3_acting_list2.actor_id as actor2
--       FROM acting degree3_acting_list1
--             JOIN acting degree3_acting_list2
--                  ON degree3_acting_list1.movie_id = degree3_acting_list2.movie_id
--                  AND degree3_acting_list1.actor_id != degree3_acting_list2.actor_id) as degree3
--       ON degree3.actor1 = degree2.actor1
--          AND degree3.actor2 != acting_list1.actor_id
--          AND degree3.actor2 != degree2.actor2;
--
-- SELECT acting_list1.actor_id,
--        acting_list1.movie_id,
--        acting_list2.actor_id,
--        degree2.movie_id,
--        degree2.actor2,
--        degree3.movie_id,
--        degree3.actor2 as degree3actor
-- FROM acting acting_list1
--      JOIN acting acting_list2
--           ON acting_list1.movie_id = acting_list2.movie_id
--              AND acting_list1.actor_id = 3001
--              AND acting_list1.actor_id != acting_list2.actor_id
-- JOIN (SELECT degree1_acting_list1.actor_id as actor1,
--              degree1_acting_list1.movie_id,
--              degree2_acting_list2.actor_id as actor2
--       FROM acting degree1_acting_list1
--             JOIN acting degree2_acting_list2
--                  ON degree1_acting_list1.movie_id = degree2_acting_list2.movie_id
--                  AND degree1_acting_list1.actor_id != degree2_acting_list2.actor_id) as degree2
--       ON degree2.actor1 = acting_list2.actor_id
--          AND degree2.actor2 != acting_list1.actor_id
-- JOIN (SELECT degree3_acting_list1.actor_id as actor1,
--              degree3_acting_list1.movie_id,
--              degree3_acting_list2.actor_id as actor2
--       FROM acting degree3_acting_list1
--             JOIN acting degree3_acting_list2
--                  ON degree3_acting_list1.movie_id = degree3_acting_list2.movie_id
--                  AND degree3_acting_list1.actor_id != degree3_acting_list2.actor_id) as degree3
--       ON degree3.actor1 = degree2.actor1
--          AND degree3.actor2 != acting_list1.actor_id
--          AND degree3.actor2 != degree2.actor2;

--
--
-- SELECT DISTINCT graph3.actor2_node as lastlink,
--        graph3.movie_edge,
--        graph2.actor2_node,
--        graph2.movie_edge,
--        graph1.actor2_node,
--        graph1.movie_edge,
--        graph1.actor1_node
-- FROM graph graph1
-- JOIN graph graph2
--     ON graph1.actor2_node = graph2.actor1_node
--         AND graph1.actor1_node = '3001'
--         AND graph2.actor2_node != graph1.actor1_node
--         AND graph2.movie_edge != graph1.movie_edge
-- JOIN graph graph3
--     ON graph2.actor2_node = graph3.actor1_node
--        AND graph3.actor2_node != graph2.actor1_node
--        AND graph3.movie_edge != graph2.movie_edge
--        AND graph3.movie_edge != graph1.movie_edge
-- JOIN graph graph4
--     ON graph3.actor2_node = graph4.actor1_node
--        AND graph4.actor2_node != graph3.actor1_node
--         AND graph4.movie_edge != graph3.movie_edge
--         AND graph4.movie_edge != graph2.movie_edge
--         AND graph4.movie_edge != graph1.movie_edge

create or replace view graph(actor1_node, movie_edge, actor2_node) as
SELECT acting_list1.actor_id,
       acting_list1.movie_id,
       acting_list2.actor_id
FROM acting acting_list1
     JOIN acting acting_list2
          ON acting_list1.movie_id = acting_list2.movie_id
             AND acting_list1.actor_id != acting_list2.actor_id;

create type path as
(
    INPUT = input_function,
    OUTPUT = output_function,
    paths text
);

create or replace function shortest(input_movie_id int, input_movie_id2 int)
    returns setof path
as $$
-- we are going to declare all variables required for return value
--
declare
      single_path path;
      --single_path.paths text;
      counter int := 0;
      entry record;
BEGIN


    FOR entry IN SELECT DISTINCT * FROM graph WHERE graph.actor1_node = 301
    LOOP
        single_path := (entry.actor1_node::text || ' in ' || entry.movie_edge::text
                             ||' with ' || entry.actor2_node::text);
        return next entry;
        --final_return_genre := final_return_genre||entry.genre||'&';
    END LOOP;
    -- remove the final & at end of genre list to sanitize list
--    final_return_genre := RTRIM(final_return_genre, '&');

    -- remove final , to sanitize list
    -- final_return_genre := RTRIM(final_return_genre, ',');
END; $$ language plpgsql;

select * from shortest(301,301);

SELECT DISTINCT graph1.actor1_node,
                graph1.movie_edge,
                graph1.actor2_node
FROM graph graph1
WHERE graph1.actor1_node = 301;



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
