#!/bin/bash
##################################################################################
# P.O.SH
# (c) 2012 Mangled Deutz <dev@webitup.fr>
# Distributed under the terms of the WTF-PL: do wtf you want with that code
##################################################################################

#################################################
# Pony nasty helpers - god forbids shell script!
#################################################

# Get a curl header "name" from a curl response stream, or the status if name is not provided
http::getnoerror(){
  read line
  result="${line#* }"
  result="${result% *}"
  if [[ "$result" != "200" ]]; then
    exit -1
  fi

  # Get rid of headers
  while read line; do
    string::strip ＆line
    if [[ "$line" == "" ]]; then
      break
    fi
  done
  while read line; do
    echo "$line" >> "$1"
  done

    # curr=${line%%:*}
    # if [[ $curr = $name ]]; then
    #   ext=${line#*:}
    #   ext=`echo $ext | tr "\r" ' ' | tr "\n" ' '`
    #   result="$result$ext; "
    #   echo "----------------"
    #   echo $result
    #   echo "----------------"
    # fi
}



http::get(){
  bitch="$(curl -i \"$1\")"
  echo "$bitch" | http::getnoerror "$2"
}
