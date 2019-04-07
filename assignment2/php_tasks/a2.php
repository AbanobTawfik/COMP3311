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

function create_graph(&$graph, &$r, $t){
	
}


?>