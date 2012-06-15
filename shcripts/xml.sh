#!/bin/bash
##################################################################################
# P.O.SH
# (c) 2012 Mangled Deutz <dev@webitup.fr>
# Distributed under the terms of the WTF-PL: do wtf you want with that code
##################################################################################

_readnode() {
        local IFS=">";
        read -d \< N C ;
}


_simplenode=
xml_indent=
xml_tab=`echo -ne "\x09"`
xml:serialize(){

  if [[ "$1" == "" ]]; then
      return
  fi
  if [[ ${1:0:1} == "/" ]]; then
      xml_indent="${xml_indent:1}"
      if [[ "$_simplenode" == "true" ]]; then
          _simplenode=
          echo "<$1>"
      else
          echo "$xml_indent<$1>"
      fi
  elif [[ ${1:0:1} == "?" ]]; then
      echo "$xml_indent<$1>"
  elif [[ ${1:0:1} == "!" ]]; then
      echo "$xml_indent<$1>"
  else
      vava=`echo $2 | tr "\n" " " | tr "\r" " " | tr "\t" " "`
      vava=${vava// /}
      if [[ "$vava" != "" ]]; then
          echo -n "$xml_indent<$1>"
          echo -n "$2"
          _simplenode=true
      else
          echo "$xml_indent<$1>"
      fi
      xml_indent="$xml_tab$xml_indent"
  fi
}


xml:readfile(){
  entryfile=$1
  exitfile=$2
  processor=$3
  while _readnode
  do
    $processor "$N" "$C"
  done < "$entryfile" > "$exitfile"
}
