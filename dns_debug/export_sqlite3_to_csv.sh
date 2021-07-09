#!/bin/bash

QUERY_FILES=$(ls sql | grep export | xargs)
OUT_DIR="sqlite3_out"

if [[ ! -d "$OUT_DIR" ]]; then 
    mkdir $OUT_DIR
fi

cd $OUT_DIR

for file in $QUERY_FILES; do
    sqlite3 ../out/db < ../sql/$file
done

ls