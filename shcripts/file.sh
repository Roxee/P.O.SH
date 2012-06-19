#!/bin/bash
##################################################################################
# P.O.SH
# (c) 2012 Mangled Deutz <dev@webitup.fr>
# Distributed under the terms of the WTF-PL: do wtf you want with that code
##################################################################################

file::read(){
  ref=${1#＆}
  export $ref="`cat \"$2\"`"
}

file::write(){
  ref=${1#＆}
  echo -n "${!ref}" > "$2"
}
