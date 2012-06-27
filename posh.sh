#!/bin/bash
##################################################################################
# P.O.SH
# (c) 2012 Mangled Deutz <dev@webitup.fr>
# Distributed under the terms of the WTF-PL: do wtf you want with that code
##################################################################################

# Trix to boot
trix=$(dirname "$0")
cd "$trix"
posh_root=`pwd`
cd - > /dev/null

# Get helpers
# source "$posh_root/shcripts/mosh.sh"
source "$posh_root/shcripts/string.sh"
source "$posh_root/shcripts/ui.sh"
source "$posh_root/shcripts/args.sh" $@
source "$posh_root/shcripts/help.sh"
source "$posh_root/shcripts/bin.sh"
source "$posh_root/shcripts/file.sh"
source "$posh_root/shcripts/http.sh"
source "$posh_root/shcripts/xml.sh"
source "$posh_root/shcripts/crypto.sh"
source "$posh_root/shcripts/dmg.sh"
source "$posh_root/shcripts/fmwk.sh"

ui::header "P.O.SH, a piece of shcript that nicely bundle piles of crode"

case $main_command in
  "help")
    help::short
  ;;
  "source")
    help::source
  ;;
  "version")
    help::version
  ;;
  "author")
    help::author
  ;;
  "license")
    help::license
  ;;
  "mayday")
    help::long
  ;;
  "")
  ;;
  *)
    ui::text "Interactive: posh"
    ui::text "Programmatic: posh key=value key=value"
    ui::text "Commands: version, author, license, source, help, mayday"
    ui::error "What? Albatros?"
  ;;
esac

if [[ "$args_framework" != "" ]]; then
  fmwk::fixshit $args_framework
  exit
fi
# *************************************
# * Check requirements
# *************************************

ui::section "Checking basics"

# Initialize default arguments value for arguments that were not provided already
args::default keys ~/poshkeys
args::default background "$posh_root/posh.png"
args::default autoup NO
args::default autocheck YES
args::default profile NO

# Require binaries
bin::require openssl
bin::require curl
bin::require ruby
bin::require codesign
bin::require hdiutil

ui::info "Everything ok"

# *************************************
# * Application verification
# *************************************

ui::section "Checking your app"

args::fetch app path/to/your/super.app

if [[ ! -d "$args_app" ]]; then
  ui::error "Provided application path doesn't exist, stoopid! :)"
fi
if [[ ! -f "$args_app/Contents/Info.plist" ]]; then
  ui::error "Your app lacks an Info.plist. Please write one buddy."
fi
if [[ ! -d "$args_app/Contents/Resources" ]]; then
  mkdir "$args_app/Contents/Resources"
fi

# Make that absolute
bin::getpath "$args_app"

args_app=$abspath

ui::info "Everything OK"


# *************************************
# * Keys verification
# *************************************

ui::section "Checking keys"

crypto::keyscheck "$args_keys"

ui::info "Everything OK"


# *************************************
# * Prepping files
# *************************************

ui::section "Generating plist and copying key"

args::fetch version X.Y.Z
args::fetch feed http://brainfuck/myappcast.xml

# Copy the public key
cp "${args_keys}/dsa_pub.pem" "${args_app}/Contents/Resources"


# Now, update the thingie plist - do the heavylifting bayby :)
# Start with the template
ind=0
tplized=()
iskey=false
proc(){
  type="$1"
  main="$2"
  shift 2
  if [[ "$type" == "open" ]] && [[ "$main" == "key" ]]; then
    iskey=true
  elif [[ "$type" == "content" ]] && [[ "$iskey" == true ]]; then
    iskey=false
    keyname="$main"
    # Store the pointer
    nn=__synthetic_tpl_$keyname
    export $nn=$ind
    # Store the pointer name in the array
    tplized[$ind]="$main"
    ind=$(expr $ind+1)
  elif [[ "$type" == "content" ]]; then
    # Mustach the shit
    string::mustache ＆main
    # And store the value in the array
    tplized[$ind]="$main"
    ind=$(expr $ind+1)
    # syntheticadd="$syntheticadd$(xml::serialize $type "$main" "$@")"
    # return
  fi
}
xml::parse "proc" "$posh_root/posh.plist.tpl"

# Process the actual plist
iskey=false
procplist(){
  type="$1"
  main="$2"
  shift 2

  if [[ "$type" == "open" ]] && [[ "$main" == "key" ]]; then
    iskey=true
    keyname="$main"
  elif [[ "$type" == "content" ]] && [[ "$iskey" == true ]]; then
    iskey=false
    keyname="$main"
  elif [[ "$type" == "content" ]]; then
    # If we have a defined value for that, replace main with it and unset
    nn=__synthetic_tpl_$keyname
    if [[ "${!nn}" != "" ]]; then
      # Get the pointer
      vn=${!nn}
      # Delete the key
      unset tplized[$vn]
      # Increment to the value
      vn=$(expr $vn+1)
      # Spoof in the value
      main=${tplized[$vn]}
      # Delete the value
      unset tplized[$vn]
      # Delete the pointer
      unset $nn
    fi
  # Append the rest of the tpl if we reached the closing dict - kind of tricky...
  elif [[ "$type" == "close" ]] && [[ "$main" == "dict" ]] && [[ $xml_indent == $xml_tab ]]; then
    n="key"
    for name in ${tplized[@]}; do
      xml::serialize "open" $n
      xml::serialize "content" "$name"
      xml::serialize "close" $n
      if [[ "$n" == "key" ]]; then
        n="string"
      else
        n="key"
      fi
    done
  #   echo "$tpl"
  fi
  xml::serialize $type "$main" "$@"
}

file::read ＆plist "${args_app}/Contents/Info.plist"
echo $plist | xml::parse procplist > Info.plist

# Cleanup - wooot woooot!
# And copy
cp "Info.plist" "${args_app}/Contents/Info.plist"
rm Info.plist

ui::info "Generating plist and copying key: OK"


# *************************************
# * Ready to code sign the shit
# *************************************

# XXX
# Look into easing the import to keychain
# http://www.entropy.ch/blog/Developer/2008/02/11/Mac-OS-X-Application-Code-Signing.html
# XXX
# Look into dependencies signing
# http://stackoverflow.com/questions/7697508/how-do-you-codesign-framework-bundles-for-the-mac-app-store
# XXX
# QT mess-up https://bugreports.qt-project.org/browse/QTBUG-23268

ui::section "Code signing your application"

args::fetch sign "3rd Party Mac Developer Application: Jocelyne la Chaudasse - use 'chuck' to disable codesigning altogether"

if [[ "$args_sign" != "" ]] && [[ "$args_sign" != "chuck" ]]; then
  crypto::codesignapp "$args_sign" "$args_app"
  ui::info "Code signing your application: OK"  
else
  ui::warning "Not signing your code is a mistake, Chuck! But well, you are the boss."
fi

# *************************************
# * Now, pack that baby up
# *************************************

ui::section "Packing the shit up into a nicy dmg"

args::fetch background path/to/super/background

if [[ ! -e "$args_background" ]]; then
    ui::error "Err, your nicy background doesn't exist baby."
fi

aname="${args_app##*/}"

finalShort="${aname%%.*}-install-${args_version}"
dmg::make "${aname%%.*} Install" "$finalShort" "${aname%%.*}" "${args_app%/*}" "${args_background##*/}" "${args_background%/*}"

dmgFinal="$finalShort.dmg"

if [[ -e "${aname%%.*}-install-latest.dmg" ]]; then
  rm "${aname%%.*}-install-latest.dmg"
fi
ln -s "$finalShort.dmg" "${aname%%.*}-install-latest.dmg"

ui::info "Packing the shit up into a nicy dmg: check!"


# *************************************
# * Codesign the dmg
# *************************************

ui::section "Codesign the dmg"

crypto::codesigndmg "$args_sign" "$dmgFinal"

ui::info "Code signing your dmg: OK"  

# *************************************
# * Sparkle sign the dmg, prepare the appcast
# *************************************

ui::section "Sparkle generate sig, prep changelog, pre appcast"

#########
# Log file
#########

args::fetch changelog path/to/changelog/for/$args_version/in/html

logFileName="${finalShort}.html"
file::read ＆loghtml "${posh_root}/posh.log.tpl"

proc(){
  type="$1"
  main="$2"
  shift 2
  if [[ "$type" == "content" ]] && [[ "$main" == "{changelog}" ]]; then
    main="`cat \"$args_changelog\"`"
  fi
  xml::serialize $type "$main" "$@"
}

echo $loghtml | xml::parse proc > "$logFileName"


#########
# Feed
#########

args::fetch feed http://something/cast.xml
# Compute signature
args_synthetic_signature="`/usr/bin/openssl dgst -sha1 -binary < "${dmgFinal}" | /usr/bin/openssl dgst -dss1 -sign "$args_keys/dsa_priv.pem" | /usr/bin/openssl enc -base64`"
args_synthetic_signature=`echo $args_synthetic_signature`
args_synthetic_signature=${args_synthetic_signature/ /}
# Compute size
args_synthetic_size=`ls -l "${dmgFinal}" | awk '{ print $5}'`

# Get remote feed, first, or create one if something goes wrong
if [[ -e feed.remote.xml ]]; then
  rm feed.remote.xml
fi
http::get "${args_feed}" feed.remote.xml
if [[ ! -e feed.remote.xml ]]; then
  ui::warning "Provided feed url does NOT exist. Will use default template for cast instead."
  ui::confirm "Please double check before continuing."

  file::read ＆fullcast "${posh_root}/posh.fullcast.tpl"

  proc(){
    type="$1"
    main="${2}"
    shift 2
    if [[ "$main" == "{synthetic_url}" ]]; then
      main="$args_feed"
    elif [[ "$main" == "{synthetic_title}" ]]; then
      main="${aname%%.*}"
    fi

    xml::serialize $type "$main" "$@"
  }
  echo $fullcast | xml::parse proc > feed.remote.xml
fi

# Now, prep the cast item
feedPath=${args_feed%/*}

args_synthetic_title="${aname%%.*} version $args_version"
args_synthetic_date=`date`

args_synthetic_pack_url="$feedPath/packages/$dmgFinal"
args_synthetic_log_url="$feedPath/packages/$finalShort.html"


# Process the item tpl
file::read ＆castitem "${posh_root}/posh.cast.tpl"

proc(){
  type="$1"
  main="${2}"
  shift 2
  add=
  if [[ "$main" == "{synthetic_log_url}" ]]; then
    main="$args_synthetic_log_url"
  elif [[ "$main" == "{synthetic_title}" ]]; then
    main="$args_synthetic_title"
  elif [[ "$main" == "{synthetic_date}" ]]; then
    main="$args_synthetic_date"
  fi

  for stuff in $@; do
    string::strip ＆stuff
    if [[ "$stuff" != "" ]]; then
      stuff="${stuff/synthetic_pack_url/$args_synthetic_pack_url}"
      stuff="${stuff/synthetic_size/$args_synthetic_size}"
      stuff="${stuff/synthetic_signature/$args_synthetic_signature}"
      stuff="${stuff/synthetic_version/$args_version}"
      add="$add $stuff"
    fi
  done
  if [[ "$type" == "content" ]] && [[ "$main" == "{changelog}" ]]; then
    main="$args_changelog"
  fi
  xml::serialize $type "$main" "$add"
}

echo $castitem | xml::parse proc > "castitem.xml"

file::read ＆castAll "feed.remote.xml"

proc(){
  type="$1"
  main="${2}"
  shift 2
  # XXX BEWARE OF PUBLISHING MULTIPLE IDENTICAL VERSIONS!!!! SHOULD HANDLE THAT
  if [[ "$type" == "close" ]] && [[ "$main" == "channel" ]]; then
    # Some bad variable collision here :((((
    echo `xml::serialize "open" "item"`
    cat "castitem.xml"
    echo `xml::serialize "close" "item"`
    # xml::serialize "close" "channel" "$@"
  # else
  fi
  xml::serialize $type "$main" "$@"
}

echo $castAll | xml::parse proc > "updatedcast.xml"

rm castitem.xml
rm feed.remote.xml



ui::section "Sparkle stuff: OK"


# *************************************
# * Cleanup and upload
# *************************************


ui::section "Cleaning up and preparing for upload"

if [[ ! -d "packages" ]]; then
  mkdir packages
fi
cp *.dmg packages
cp *.html packages
rm *.dmg
rm *.html

feedname=${args_feed##*/}
mv updatedcast.xml "$feedname"


args::fetch remote "myhost:/home/roxee/www/app/webroxer or a local destination"

scp "$feedname" "$args_remote"
scp -r "packages" "$args_remote"

# XXX fix permission on remote server

ui::section "Upload: CHECKED"

ui::section "That's all posh folks!"

exit



