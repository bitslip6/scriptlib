#!/usr/bin/env zsh

. "$(dirname "$0")/libs.sh"

# get directory listing from $1
data1=$(remote_ls $1)
# convert the string to an array on new lines (data2 is an output var 
string_to_lines data2 "$data1"
file=$(picker_select $data2)

scp $1/$file $file
