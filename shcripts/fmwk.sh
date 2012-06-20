#!/bin/bash
##################################################################################
# P.O.SH
# (c) 2012 Mangled Deutz <dev@webitup.fr>
# Distributed under the terms of the WTF-PL: do wtf you want with that code
##################################################################################


fmwk::fixshit(){
  destination="$1"
  fbasepath="$2"
  fname="$3"
  fversion="$4"
  fidbase="$5"
  # Prep-up destination
  if [[ -d "$destination/$fname.framework" ]]; then
    rm -Rf "$destination/$fname.framework"
  fi
  mkdir -p "$destination/$fname.framework/Versions"
  # Get binary for a starter
  binpath=`find "$fbasepath/$fname.framework/Versions" -mindepth 1 -maxdepth 1 -not -name "Current"`
  currentversion=${binpath##*/}
  mkdir "$destination/$fname.framework/Versions/$currentversion"
  ln -s $currentversion "$destination/$fname.framework/Versions/Current"
  cp "$binpath/$fname" "$destination/$fname.framework/Versions/$currentversion"
  if [[ -d  "$binpath/Resources" ]]; then
    cp -R "$binpath/Resources" "$destination/$fname.framework/Versions/$currentversion"
  else
    mkdir "$destination/$fname.framework/Versions/$currentversion/Resources"
  fi
  ln -s Versions/Current/$fname "$destination/$fname.framework/"
  ln -s Versions/Current/Resources "$destination/$fname.framework/"


  if [[ ! -e  "$destination/$fname.framework/Resources/Info.plist" ]]; then
    # Need to produce a valid info.plist for hopeless framework
    sig=`echo $fname | tr '[:lower:]' '[:upper:]'`
    fmwk::generateplist "$fname" "$fidbase.$fname" "$fname" "$fversion" "$fversion" "${sig:0:4}" 
    file::write ＆plist "$destination/$fname.framework/Resources/Info.plist"
  fi
}


fmwk::generateplist(){
  file::read ＆plist "$posh_root/posh.fullplist.tpl"
  plist=${plist/synthetic_executable/$1}
  plist=${plist/synthetic_identifier/$2}
  plist=${plist/synthetic_name/$3}
  plist=${plist/synthetic_short_version/$4}
  plist=${plist/synthetic_version/$5}
  plist=${plist/synthetic_signature/$6}
}
