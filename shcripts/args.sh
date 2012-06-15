#!/bin/bash

# *************************************
# * Handling arg stack
# *************************************

# Set the default value ($2) for variable name ($1)
args:default(){
  _name=$1
  _n=args_$_name
  if [[ "${!_n}" == "" ]]; then
    export args_$_name="$2"
  fi
}

# If variable $1 is not initialized (either default or command line), ask the user to answer, with exemple value $2
args:fetch(){
  _name=$1
  _ex=$2
  inner=args_$_name
  if [[ "${!inner}" == "" ]]; then
    ui:ask "Please provide a '$_name' (eg: $_ex), or break now and specify $_name=VALUE on the script invocation: " args_$_name
  fi
}

_init(){
  for _i in "$@"; do
    _value=${_i#*=}
    _name=${_i%%=**}
    if [[ "$_name" == "$_i" ]]; then
      if [[ "$_previous" == "" ]]; then
        main_command=${_name##*-}
      fi
      _nn=args_${_previous}
      export $_nn="${!_nn} $_name"
    else
      case $_name in
      *)
        export _previous=$_name
        export args_${_name}=$_value
      ;;
      esac
    fi
  done
}

_init $@
