#!/bin/bash
##################################################################################
# P.O.SH
# (c) 2012 Mangled Deutz <dev@webitup.fr>
# Distributed under the terms of the WTF-PL: do wtf you want with that code
##################################################################################

bin:getpath(){
  cd "$1"
  abspath=`pwd`
  cd - > /dev/null
}

bin:require(){
  _shortname=${1%%.*}
  _argname=args_bin_$_shortname
  _binary=
  if which $1 > /dev/null; then
    _binary=`which $1`
  elif [[ -e "$posh_root/bin/$1" ]]; then
    _binary="$posh_root/bin/$1"
  elif [[ ${!_argname} != "" ]] && ls ${!_argname}/$1 > /dev/null; then
    bin:getpath "${!_argname}"
    _binary="$abspath/$1"
  fi
  if [[ "$_binary" != "" ]]; then
    export $_argname=$_binary
  else
    ui:error "Couldn't find required binary '$1'. Please add it to your PATH, or pass its parent directory explicitely on the command line using bin_$_shortname=containing/dir"
  fi
}

bin:exec(){
  ui:error Not implemented
  # XXX todo
}