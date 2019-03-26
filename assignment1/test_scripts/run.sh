#!/bin/sh

ssh grieg
read -s "zid: (include the z)" zid
source /srvr/$zid/env

pgs start
dropdb a1-check > output.txt
createdb a1-check >> output.txt
psql a1-check -f asx-schema.sql
psql a1-check -f asx-insert.sql
psql a1-check -f a1.sql
psql -d a1-check -f input.txt >> output.txt
cat output.txt
dropdb a1-check > output.txt
pgs stop
