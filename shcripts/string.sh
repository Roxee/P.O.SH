#!/bin/bash
##################################################################################
# P.O.SH
# (c) 2012 Mangled Deutz <dev@webitup.fr>
# Distributed under the terms of the WTF-PL: do wtf you want with that code
##################################################################################

# Some utf8 stuff that doesn't work http://mywiki.wooledge.org/BashFAQ/071
# Suggest using LC_CTYPE, or LC_ALL (to C.UTF-8) which printf doesn't give a crap about

# ★ ＆
# Use ext glob bitch!
shopt -s extglob


string::length(){
  poshout=${#1}
}

string::charAt(){
  poshout=${1:$2:1}
}

string::charCodeAt(){
  ch=${1:$2:1}
  ch=`echo -ne "$ch" | hexdump`
  ch=${ch:8}
  ch=${ch%%[0-9][0-9][0-9]*}
  poshout=${ch// /}
}

string::concat(){
  poshout="$1"
  shift 1
  while [[ "$#" != "" ]]; do
    poshout="${poshout}$1"
    shift 1
  done
}

string::indexOf(){
  ch=${1%%$2*}
  poshout=${#ch}
}

string::lastIndexOf(){
  ch=${1%$2*}
  poshout=${#ch}
}

string::substr(){
  poshout="${1:$2:$3}"
}


# console.debug(){
#   echo -e $@
# }

# console.log(){
#   echo -e $@
# }

# console.warn(){
#   echo -e $@
# }

# console.error(){
#   echo -e $@
#   exit 1
# }

string_TAB=`echo -e "\x09"`
string_CR=`echo -e "\x0d"`
string_SP=`echo -e "\x20"`
string_LF=`echo -e "\x0a"`


# Check wether a given string begins with any of the given needles
# @function string::startswith
# @param $1 string to test
# @param $2 needle to compare
# [@param $n] additional needle to compare
# @returns 0 if none of the needle where found, 1 if at least one needle was found
string::startswith(){
  str="$1"
  # ret=0
  shift 1
  while [[ "$#" != "0" ]]; do
    needle="$1"
    m=${#needle}
    if [[ "${str:0:$m}" == "$needle" ]]; then
      poshout=true
      return
    fi
    shift 1
  done
  poshout=false
}

# Check wether a given string ends with any of the given needles
# @function string::endswith
# @param $1 string to test
# @param $2 needle to compare
# [@param $n] additional needle to compare
# @returns 0 if none of the needle where found, 1 if at least one needle was found
string::endswith(){
  str="$1"
  # ret=0
  shift 1
  l=${#str}
  while [[ "$#" != "0" ]]; do
    needle="$1"
    m=${#needle}
    d=`expr $l - $m`
    if [[ "${str:$d:$m}" == "$needle" ]]; then
      poshout=true
      return
    fi
    shift 1
  done
  poshout=false
}

# Modify a parameter so that the suffix part after last occurence of a word is removed
# @function string::stripafterlast
# @param &$1 string to test
# @param $2 needle to compare
string::stripafterlast(){
  varname="${1#＆}"
  word="$2"
  export $varname="${!varname%$word*}"
}

# Modify a parameter so that the suffix part after first occurence of a word is removed
string::stripafterfirst(){
  varname="${1#＆}"
  word="$2"
  export $varname="${!varname%%$word*}"
}


# Modify a parameter so that the prefix part before first occurence of a word is removed
string::stripbeforefirst(){
  varname="${1#＆}"
  word="$2"
  export $varname="${!varname#*$word}"
}

# Modify a parameter so that the suffix part before last occurence of a word is removed
string::stripbeforelast(){
  varname="${1#＆}"
  word="$2"
  export $varname="${!varname##*$word}"
}

# Modify a parameter referenced by $1 so that any leading or trailing space(s) is removed
# Also does clean-up any additional leading or trailing character class
string::strip(){
  # Remove LF first
  varname="${1#＆}"
  export $varname="`echo -n ${!varname}`"
  shift 1
  export $varname="${!varname%%*([${string_LF}${string_SP}${string_TAB}${string_CR}${@:- }])}"
  export $varname="${!varname##*([${string_LF}${string_SP}${string_TAB}${string_CR}${@:- }])}"
}

# IN REPLACE: ${VAR/search/replace}
# SMART SUBTRING: echo ${str:$((-3)):2}
string::getkv(){
  kname="${1#＆}"
  vname="${2#＆}"
  export $kname="$3"
  export $vname="$3"
  string::stripafterfirst $1 "="
  string::stripbeforefirst $2 "="
  string::strip $2 '"' "'"
}

string::getparams(){
  callback=$1
  shift 1
  while [[ "$#" != "0" ]]; do
    string::getkv ＆_string_key ＆_string_value "$1"
    # Lonesome value,aggregate
    if [[ "$_string_key" == "$1" ]]; then
      if [[ "$_pkey" != "" ]]; then
        _pvalue="$_pvalue $_string_value"
      else
        _pkey=$_string_key
      fi
    else
      # Anything previously in the buffer? Notify
      if [[ "$_pkey" != "" ]]; then
        $callback $_pkey "$_pvalue"
      fi
      _pkey=$_string_key
      _pvalue="$_string_value"
    fi
    shift 1
  done
  if [[ "$_pkey" != "" ]]; then
    $callback $_pkey "$_pvalue"
  fi
}

# fun(){
#   echo "$1: $2"
# }

# string::getparams fun "$@"

# Simple helper that replace a possibly templated value (eg: {toto}) by its corresponding variable value ($args_toto)
string::mustache(){
  name=${1#＆}
  value=${!name}
  string::strip ＆value "}" "{"
  if [[ "$value" != "${!name}" ]];then
    ni=args_$value
    export ${name}=${!ni}
  fi
}



# stringdef="     some string parameter     "
# stringnull=

# echo " * Get a variable, fallback to default if null or not defined:"
# echo ${stringdef:-this is default}
# echo ${stringnull:-this is default}
# echo ${stringundef:-this is default}

# echo " * Get a variable, fallback to default if not defined:"
# echo ${stringdef-this is default}
# echo ${stringnull-this is default}
# echo ${stringundef-this is default}

# echo " * Get a variable, fallback to default if null or not defined, assign:"
# echo ${stringdef:=this is default}
# echo ${stringnull:=this is default}
# echo ${stringundef:=this is default}
# echo ${stringdef}
# echo ${stringnull}
# echo ${stringundef}

# unset stringundef
# stringnull=

# echo " * Get a variable, fallback to default if not defined, assign:"
# echo ${stringdef=this is default}
# echo ${stringnull=this is default}
# echo ${stringundef=this is default}
# echo ${stringdef}
# echo ${stringnull}
# echo ${stringundef}

# unset stringundef
# stringnull=

# echo " * Get a variable, exit on error if null or not defined:"
# echo ${stringdef:?Defined string is ok}
# # echo ${stringnull:?Null string is NOT ok}
# # echo ${stringundef:?Undefined string is NOT ok}

# echo " * Get a variable, exit on error if not defined:"
# echo ${stringdef?Defined string is ok}
# echo ${stringnull?Null string is ok}
# # echo ${stringundef?Undefined string is NOT ok}

# echo " * Substitue value unless null or not defined:"
# echo ${stringdef:+this is default}
# echo ${stringnull:+this is default}
# echo ${stringundef:+this is default}

# echo " * Substitue value unless not defined:"
# echo ${stringdef+this is default}
# echo ${stringnull+this is default}
# echo ${stringundef+this is default}

# echo " * Param length"
# echo ${#stringdef}
# echo ${#stringnull}
# echo ${#stringundef}

# echo " * Remove smallest suffix matching"
# echo "/////${stringdef% }/////"

# echo " * Remove biggest suffix matching"
# echo "/////${stringdef%% }/////"

# echo " * Remove smallest prefix matching"
# echo "/////${stringdef# }/////"

# echo " * Remove biggest prefix matching"
# echo "/////${stringdef## }/////"
