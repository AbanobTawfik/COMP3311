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
$q = "SELECT * FROM degree1_actors($start) d1(a1 int, m1 int, a2 int)
                    WHERE d1.a2 = $goal;";
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
$q = "SELECT *
	  FROM degree1_actors($start) d1(a1 int, m1 int, a2 int)
	  JOIN degree1_actors($goal) d11(a1 int, m1 int, a2 int)
	     ON d11.a2 = d1.a2;";
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
$q = "SELECT d2.a1, d2.m1, d2.a2, d2.m2, d2.a3, d1.m1, d1.a1
	  FROM degree2_actors($start) d2(a1 int, m1 int, a2 int, m2 int, a3 int)
	  JOIN degree1_actors($goal) d1(a1 int, m1 int, a2 int)
		 	ON d1.a2 = d2.a3;";
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

// DEGREE 4 check
$q = "SELECT d2.a1, d2.m1, d2.a2, d2.m2, d2.a3, d22.m2, d22.a2, d22.m1, d22.a1
	  FROM degree2_actors($start) d2(a1 int, m1 int, a2 int, m2 int, a3 int)
	  JOIN degree2_actors($goal) d22(a1 int, m1 int, a2 int, m2 int, a3 int)
		   ON d2.a3 = d22.a3;";
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
	$movie_link34 = movie_from_id($t[7]);
	$actor4 = actor_from_id($t[8]);
	
	array_push($shortest_paths, $actor0." was in ".$movie_link01." with ".$actor1."; ".$actor1.
										 " was in ".$movie_link12. " with ".$actor2."; ".$actor2." was in ".
										 $movie_link23." with ".$actor3."; ".$actor3." was in ".$movie_link34." with ".
										 $actor4 
										 ."\n");
}

if($found_shortest == true){
	print_shortest_paths($shortest_paths);
	return;
}

// DEGREE 2 check
$q = "SELECT *
	  FROM degree1_actors($start) d1(a1 int, m1 int, a2 int)
	  JOIN degree1_actors($goal) d11(a1 int, m1 int, a2 int)
	     ON d11.a2 = d1.a2;";
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
$q = "SELECT d2.a1, d2.m1, d2.a2, d2.m2, d2.a3, d1.m1, d1.a1
	  FROM degree2_actors($start) d2(a1 int, m1 int, a2 int, m2 int, a3 int)
	  JOIN degree1_actors($goal) d1(a1 int, m1 int, a2 int)
		 	ON d1.a2 = d2.a3;";
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

// DEGREE 5 check
$q = "SELECT d3.a1, d3.m1, d3.a2, d3.m2, d3.a3, d3.m3, d3.a4, d2.m2, d2.a2, d2.m1, d2.a1
	  FROM degree3_actors($start) d3(a1 int, m1 int, a2 int, m2 int, a3 int, m3 int, a4 int)
      JOIN degree2_actors($goal) d2(a1 int, m1 int, a2 int, m2 int, a3 int)
           ON d3.a4 = d2.a3;";
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
	$movie_link34 = movie_from_id($t[7]);
	$actor4 = actor_from_id($t[8]);
	$movie_link45 = movie_from_id($t[9]);
	$actor5 = actor_from_id($t[10]);
	
	array_push($shortest_paths, $actor0." was in ".$movie_link01." with ".$actor1."; ".$actor1.
										 " was in ".$movie_link12. " with ".$actor2."; ".$actor2." was in ".
										 $movie_link23." with ".$actor3."; ".$actor3." was in ".$movie_link34." with ".
										 $actor4."; ".$actor4." was in ".$movie_link45." with ".$actor5."\n");
}

if($found_shortest == true){
	print_shortest_paths($shortest_paths);
	return;
}

// DEGREE 6 check
$q = "SELECT d3.a1, d3.m1, d3.a2, d3.m2, d3.a3, d3.m3, d3.a4, d33.m3, d33.a3, d33.m2, d33.a2, d33.m1, d33.a1
	  FROM degree3_actors($start) d3(a1 int, m1 int, a2 int, m2 int, a3 int, m3 int, a4 int)
	  JOIN degree3_actors($goal) d33(a1 int, m1 int, a2 int, m2 int, a3 int, m3 int, a4 int)
		    ON d3.a4 = d33.a4;";
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
	$movie_link34 = movie_from_id($t[7]);
	$actor4 = actor_from_id($t[8]);
	$movie_link45 = movie_from_id($t[9]);
	$actor5 = actor_from_id($t[10]);
	$movie_link56 = movie_from_id($t[11]);
	$actor6 = actor_from_id($t[12]);
	array_push($shortest_paths, $actor0." was in ".$movie_link01." with ".$actor1."; ".$actor1.
										 " was in ".$movie_link12. " with ".$actor2."; ".$actor2." was in ".
										 $movie_link23." with ".$actor3."; ".$actor3." was in ".$movie_link34." with ".
										 $actor4."; ".$actor4." was in ".$movie_link45." with ".$actor5."; ".$actor5." was in ".
										 $movie_link56." with ".$actor6 ."\n");
}

if($found_shortest == true){
	print_shortest_paths($shortest_paths);
	return;
}
?>