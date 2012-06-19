#!/bin/bash
##################################################################################
# P.O.SH
# (c) 2012 Mangled Deutz <dev@webitup.fr>
# Distributed under the terms of the WTF-PL: do wtf you want with that code
##################################################################################

# Set the default value ($2) for variable name ($1)
args::default(){
  _name=$1
  _n=args_$_name
  if [[ "${!_n}" == "" ]]; then
    export args_$_name="$2"
  fi
}

# If variable $1 is not initialized (either default or command line), ask the user to answer, with exemple value $2
args::fetch(){
  _name=$1
  _ex=$2
  inner=args_$_name
  if [[ "${!inner}" == "" ]]; then
    ui::ask "Please provide a '$_name' (eg: $_ex), or break now and specify $_name=VALUE on the script invocation: " args_$_name
  fi
}

args::get(){
  nn=args_$1
  echo ${!nn}
}

_init(){
  key=$1
  value="$2"
  if [[ "$value" != "" ]]; then
    export args_$key="$value"
  else
    export main_command=$key
  fi
}

string::getparams _init $@
