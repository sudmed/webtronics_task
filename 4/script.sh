#!/bin/bash

# remove empty lines in file
sed -i '/^$/d' file.txt

# parse file line by line
cat file.txt | while read line
do
   # if there is a trailing slash, it is a directory. Make dir only
   [[ "${line}" == */ ]] && mkdir -p "${line}"

   # if there is no trailing slash, it is a file. Touch file and make dir (if necessary)
   [[ "${line}" != */ ]] && mkdir -p "$(dirname "$line")/" && touch "${line}"
done
