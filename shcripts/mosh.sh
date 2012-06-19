#!/bin/bash
##################################################################################
# P.O.SH
# (c) 2012 Mangled Deutz <dev@webitup.fr>
# Distributed under the terms of the WTF-PL: do wtf you want with that code
##################################################################################

shopt -s extglob

# ★ ＆
# Helper that parses the right member of an assignation
__posh__::parseassign(){
  # memo="$1"

  name="${1%%=*}"
  if [[ "$name" == "$1" ]]; then
    shift 1
    memo="$1"
  else
    memo=${1:${#name}}
  fi
  if [[ "$memo" == "=" ]]; then
    shift 1
    memo="$1"
  else
    memo=${1#*=}
  fi
  shift 1

  # Is memo a function?
  if [[ "${memo%%::*}" != "$memo"  ]]; then
    $memo "$@"
    value=$poshout
    if [[ "$?" != "0" ]]; then
      echo "Fatal error in function call '${memo}' with args '$@': ${posherr}"
      exit 1
    fi
  # Or a pointer to something?
  elif [[ "${memo:0:1}" == "＆" ]]; then
    if [[ "${#memo}" == "1" ]]; then
      refname=$1
    else
      refname="${memo:1}"
    fi
    value="${refname}"
  # Or a literal?
  else
    value="$memo $@"
  fi
}

# Helper that handles actual assignation (delegates heavyweight job to the previous)
posh::assign(){
  # $1 -> type
  # $2 -> assignation blob
  typage=$1
  shift 1
  name=$1
  shift 1
  if [[ "${name:0:1}" == "★" ]]; then
    pointedtypage=$typage
    typage="pointer"
    if [[ "${#name}" == "1" ]]; then
      name=$1
      shift 1
    else
      name=${name:1}
    fi
  fi

  __posh__::parseassign $name "$@"

  # echo "Parse returned: $name and $value"

  # if [[ "$typage" == "pointer" ]]; then
  #   value="__posh_${pointedtypage}_${value}"
  # fi
  varname=__posh_ref_${name/:/＆/}
  export ${varname}=$typage
  varname=__posh_${!varname}_${name/:/＆/}
  export ${varname}="$value"
}

delete(){
  typage=__posh_ref_${1/:/＆/}
  varname=__posh_${!typage}_${1/:/＆/}
  unset ${typage}
  unset ${varname}
}

string(){
  posh::assign string "$@"
}

bool(){
  posh::assign boolean "$@"
}

int(){
  posh::assign int "$@"
}

# Functions helper
# posh::parsearg(){
#   # Is it a pointer?
#   if [[ "${1:0:1}" == "＆" ]]; then
#     # if [[ "$#1" == "1" ]]; then
#     #   shift 1
#     #   __posh_name=$1
#     # else
#     __posh_name=${1:1}
#     # fi
#     typage=__posh_ref_${__posh_name/:/＆/}
#     __posh_type=${!typage}
#     innername=__posh_${!typage}_${__posh_name/:/＆/}
#     __posh_value="${!innername}"
#   # Or a literal
#   else
#     __posh_name=
#     __posh_type=literal
#     __posh_value="$1"
#     poshout="$1"
#   fi
# }

dump(){
  typage=__posh_ref_${1/:/＆/}
  if [[ $typage == "pointer" ]]; then
    varname=__posh_${!typage}_${1/:/＆/}
    dump ${varname}
    return
  else
    varname=__posh_${!typage}_${1/:/＆/}
  fi
  echo -e "${!varname}"
}

★(){
  name=__posh_pointer_$1
  shift 1
  posh::assign string ${!name} "$@"
}

# 
# string bar = "oldbar"
# string ★ foo = ＆bar
# ★ foo = "newbar"

