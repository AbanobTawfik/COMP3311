#!/bin/sh
source /srvr/$(whoami)/env

pgs start
dropdb a2
createdb a2
psql a2 -f ../a2.db
psql -d a2 -f ../updates.sql
../php_tasks/./acting "james franco" >output.txt
../php_tasks/./acting "james franco"| wc -l >>output.txt
../php_tasks/./acting "john smith"| wc -l >>output.txt

../php_tasks/./title "star war" >>output.txt
../php_tasks/./title "happy" >>output.txt
../php_tasks/./title "mars" >>output.txt

../php_tasks/./toprank "Action&Sci-Fi&Adventure" 10 2005 2005 >>output.txt
../php_tasks/./toprank "Sci-Fi&Adventure&Action" 20 1920 2019 >>output.txt
../php_tasks/./toprank 20 1920 2019 >>output.txt

../php_tasks/./similar "Happy Feet" 30 >>output.txt
../php_tasks/./similar "The Shawshank Redemption" 30 >>output.txt

../php_tasks/./shortest "tom cruise" "Jeremy Renner" >>output.txt
../php_tasks/./shortest "chris evans" "Scarlett Johansson" >>output.txt
../php_tasks/./shortest "tom cruise" "Robert Downey Jr." >>output.txt
../php_tasks/./shortest "brad pitt" "will smith" >>output.txt
../php_tasks/./shortest "chris evans" "bill clinton" |egrep  "(^[0-8]\. )|(^4[5-9]\. )|(^50\. )" >>output.txt
../php_tasks/./shortest "emma stone" "al pacino" |egrep  "(^3[2-5]\. )" >>output.txt
../php_tasks/./shortest "emma stone" "adam garcia" |egrep  "(^[5-8]\. )" >>output.txt
../php_tasks/./shortest "emma stone" "chelsea field" |egrep  "(^2[2-5]\. )" >>output.txt

../php_tasks/./degrees "chris evans" 1 2 |egrep  "(^[0-9]\. )|(^1[0-9]\. )|(^2[0-8]\. )|(^36[8-9]\. )|(^37[0-5]\. )" >>output.txt
../php_tasks/./degrees "chris evans" 2 2 |egrep  "(^[0-6]\. )|(^34[5-9]\. )|(^35[0-1]\. )" >>output.txt
../php_tasks/./degrees "tom cruise" 1 1 |egrep  "(^[0-9]\. )|(^1[0]\. )|(^4[5-9]\. )|(^5[0-3]\. )" >>output.txt
../php_tasks/./degrees "tom cruise" 1 2 |wc -l >>output.txt
../php_tasks/./degrees "chris evans" 4 4 |wc -l >>output.txt
../php_tasks/./degrees "chris evans" 1 6 |wc -l >>output.txt
../php_tasks/./degrees "tom hanks" 1 5 |wc -l >>output.txt
../php_tasks/./degrees "emma stone" 3 6 |wc -l >>output.txt

dropdb a2
pgs stop

diff "output.txt" "sample_result.txt"