<?php

// If you want to use the COMP3311 DB Access Library, include the following two lines
//
define("LIB_DIR","/import/adams/1/cs3311/public_html/19s1/assignments/a2");
require_once(LIB_DIR."/db.php");

// Your DB connection parameters, e.g., database name
//
define("DB_CONNECTION","dbname=a2");

//
// Include your other common PHP code below
// E.g., common constants, functions, etc.
//

// this function will be used to print the results from the table
// using correct comma formatting based on flag value
// if the flag is false that means it is the first value that is seen
// and we begin inserting commas before our next value afterwards.
function format_echo($table_value, $first, &$flag){
	if (!$first && !empty($table_value)){
	    if($flag){
	    	echo "$table_value";
	    	$flag = false;
	    }else{  
	      echo ", $table_value";
	  	}
   		return;
    }
	if($first && !empty($table_value)){
		echo "$table_value";
		$flag = false;
		return;
	}
}

function format_echo2($table_value, $first, &$flag){
	if (!$first && !empty($table_value) || $table_value == 0){
	    if($flag){
	    	echo "$table_value";
	    	$flag = false;
	    }else{  
	      echo ", $table_value";
	  	}
   		return;
    }
	if($first && !empty($table_value) || $table_value == 0){
		echo "$table_value";
		$flag = false;
		return;
	}
}

function actor_from_id($id){
	$db = dbConnect(DB_CONNECTION);
	$q = "SELECT name from actor where id = $id LIMIT 1;";
	$r = dbQuery($db, mkSQL($q, $id));
	$t = dbNext($r);
	$name = $t[0];
	return $name;
}

function movie_from_id($id){
	$db = dbConnect(DB_CONNECTION);
	$q = "SELECT title from movie where id = $id LIMIT 1;";
	$r = dbQuery($db, mkSQL($q, $id));
	$t = dbNext($r);
	$year = movie_year_from_id($id);
	$name = $t[0];
	if($year == -1){
		return $name;
	}else{
		return $name." (".$year.")";
	}
	return $name;
}

function movie_year_from_id($id){
	$db = dbConnect(DB_CONNECTION);
	$q = "SELECT year from movie where id = $id LIMIT 1;";
	$r = dbQuery($db, mkSQL($q, $id));
	$t = dbNext($r);
	if(!empty($t[0])){
		$name = $t[0];
		return $name;
	}
	return -1;
}

function print_shortest_paths($array){
	sort($array);
	$i = 1;
	foreach($array as $path){
		echo $i.". ".$path;
		$i++;
	}
}

?>