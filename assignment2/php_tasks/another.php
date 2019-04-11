#!/usr/bin/php
<?php

////////////////////////////////////////////////////////////////////////////////
//                                TASK E                                      //
////////////////////////////////////////////////////////////////////////////////
//
// The toprank script takes in 3 or 4 commandline arguments:
// ./toprank K StartYear EndYear
// Or:
// ./toprank Genres K StartYear EndYear
// Where Genres is a list of genres separated by '&', K is the top K movies
// Ranked by IMDB score and then by the number of votes
// (both in descending order) between (and including) StartYear and EndYear,
// With 1 <= K <= 1000, 1900 < StartYear <= EndYear < 2020 and your program
// Will not be tested with a list of more than 8 genres. We interpret '&' as
// conjunction, i.e., the selected movies shall contain all the specified
// Genres. When Genres is not provided (when your program takes in 3 arguments),
// Perform the same ranking but on movies with any genres. Do not include any
// Movie titles with empty year.
//

// include the common PHP code file
require("a2.php");

// PROGRAM BODY BEGINS

$usage = "Usage: $argv[0] Start Goal";
$db = dbConnect(DB_CONNECTION);

// Check arguments
if (count($argv) != 3){ 
  exit("$usage\n");
}

$start = $argv[1];
$goal = $argv[2];

$q = "SELECT id from actor where name ILIKE '$start' LIMIT 1;";
$r = dbQuery($db, mkSQL($q, $start));
$t = dbNext($r);
if(empty($t[0])){
	exit("$start is not an actor\n");
}
$start = $t[0];

$q = "SELECT id from actor where name ILIKE '$goal' LIMIT 1;";
$r = dbQuery($db, mkSQL($q, $goal));
$t = dbNext($r);
if(empty($t[0])){
	exit("$goal is not an actor\n");
}
$goal = $t[0];

if($start == $goal){
	return;
}

$found_shortest  = false;
$shortest_paths = array();
// DEGREE 1 check
$q = "SELECT DISTINCT * from graph where graph.actor1_node = $start AND graph.actor2_node = $goal;";
$r = dbQuery($db, mkSQL($q));

while($t = dbNext($r)){
	$found_shortest = true;
	$actor0 = actor_from_id($t[0]);
	$movie_link01 = movie_from_id($t[1]);
	$actor1 = actor_from_id($t[2]);
	
	array_push($shortest_paths, $actor0." was in ".$movie_link01." with ".$actor1."\n");
}

if($found_shortest == true){
	print_shortest_paths($shortest_paths);
	return;
}
// DEGREE 2 check
$q = "SELECT DISTINCT * from graph graph1 JOIN graph graph2 
										       ON graph1.actor2_node = graph2.actor1_node
										       AND graph1.actor1_node = $start
										       AND graph1.actor2_node != graph1.actor1_node
										       AND graph2.movie_edge != graph1.movie_edge
										       AND graph2.actor2_node = $goal;";
$r = dbQuery($db, mkSQL($q));

while($t = dbNext($r)){
	$found_shortest = true;
	$actor0 = actor_from_id($t[0]);
	$movie_link01 = movie_from_id($t[1]);
	$actor1 = actor_from_id($t[2]);
	$movie_link12 = movie_from_id($t[4]);
	$actor2 = actor_from_id($t[5]);
	
	array_push($shortest_paths, $actor0." was in ".$movie_link01." with ".$actor1."; ".$actor1.
										 " was in ".$movie_link12. " with ".$actor2."\n");
}

if($found_shortest == true){
	print_shortest_paths($shortest_paths);
	return;
}

// DEGREE 3 check
$q = "SELECT DISTINCT  graph1.actor1_node,
				       graph1.movie_edge,
				       graph1.actor2_node,
				       graph2.movie_edge,
					   sub1.*
					   FROM graph graph1
					   JOIN graph graph2
					   		ON graph1.actor2_node = graph2.actor1_node
						       AND graph1.actor1_node = '2624'
						       AND graph2.actor2_node != graph1.actor1_node
						       AND graph2.movie_edge != graph1.movie_edge
					   JOIN (SELECT DISTINCT
						       graph1.actor2_node as lastlink,
						       graph1.movie_edge,
						       graph1.actor1_node
					    FROM graph graph1
						        WHERE graph1.actor1_node = '3698') as sub1
						    ON sub1.lastlink = graph2.actor2_node;";
$r = dbQuery($db, mkSQL($q));

while($t = dbNext($r)){
	$found_shortest = true;
	$actor0 = actor_from_id($t[0]);
	$movie_link01 = movie_from_id($t[1]);
	$actor1 = actor_from_id($t[2]);
	$movie_link12 = movie_from_id($t[3]);
	$actor2 = actor_from_id($t[4]);
	$movie_link23 = movie_from_id($t[5]);
	$actor3 = actor_from_id($t[6]);
	
	array_push($shortest_paths, $actor0." was in ".$movie_link01." with ".$actor1."; ".$actor1.
										 " was in ".$movie_link12. " with ".$actor2."; ".$actor2." was in ".
										 $movie_link23." with ".$actor3."\n");
}

if($found_shortest == true){
	print_shortest_paths($shortest_paths);
	return;
}


?>
