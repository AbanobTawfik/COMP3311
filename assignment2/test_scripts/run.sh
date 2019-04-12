#!/bin/sh
source /srvr/$(whoami)/env

pgs start
dropdb a2
createdb a2
psql a2 -f a2.db
psql -d a2 -f updates.sql
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



cat output.txt

dropdb a2
pgs stop