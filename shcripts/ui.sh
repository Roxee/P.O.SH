#!/bin/bash

ui:header(){
  tput setaf 2
  echo "********************************************************************************************"
  echo "* $@"
  echo "********************************************************************************************"
  echo ""
  tput op
}

ui:section(){
  tput setaf 2
  echo ""
  echo "____________________________________________________________________________________________"
  echo "| $@"
  echo "____________________________________________________________________________________________"
  echo ""
  tput op
}

ui:text(){
  echo "$@"
}

ui:error(){
  tput setaf 1
  echo " * ERROR: $@"
  echo " Try --help or --mayday, optionally followed by a topic name for more info"
  tput op
  exit 1
}

ui:info(){
  tput setaf 2
  echo " * INFO: $@"
  tput op
}

ui:warning(){
  tput setaf 3
  echo " * WARNING: $@"
  tput op
}

ui:confirm(){
  echo "$@. Press enter now."
  read
}

ui:ask(){
  read -p "$1" $2
}
