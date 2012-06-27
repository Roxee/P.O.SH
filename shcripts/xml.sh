#!/bin/bash
##################################################################################
# P.O.SH
# (c) 2012 Mangled Deutz <dev@webitup.fr>
# Distributed under the terms of the WTF-PL: do wtf you want with that code
##################################################################################

# ★ ＆


# XXXXXXX will choke if comment contains < or >
xml::parser::core(){
  processor=$1
  N="$2"
  C="$3"
  # OIFS="$4"
  local IFS="$4"
  string::strip ＆C
  # echo
  # echo "***********"
  # echo "Entering with: $N"
  # echo "And Entering with: $C"
  # echo "***********"
  if [[ "$C" != "" ]]; then
    $processor "content" "$C"
  fi
  # Closing tag?
  string::startswith "$N" "/"
  if [[ $poshout == true ]]; then
    string::stripbeforefirst ＆N "/"
    $processor "close" $N
    continue
  fi
  # PI
  string::startswith "$N" "?"
  if [[ $poshout == true ]]; then
    # XXX parse attrs as well
    string::stripbeforefirst ＆N "?"
    string::stripafterlast ＆N "?"
    $processor "pi" $N
    continue
  fi
  # Comment
  string::startswith "$N" "!--"
  if [[ $poshout == true ]]; then
    string::stripbeforefirst ＆N "!--"
    string::stripafterlast ＆N "--"
    $processor "comment" "$N"
    continue
  fi
  # Doc
  string::startswith "$N" "!"
  if [[ $poshout == true ]]; then
    string::stripbeforefirst ＆N "!"
    # string::stripafterlast ＆N "--"
    $processor "doctype" "$N"
    continue
  fi
  # Autoclosing
  string::endswith "$N" "/"
  if [[ $poshout == true ]]; then
    string::stripafterlast ＆N "/"
    $processor "autoclose" $N
    continue
  fi

  # else
  $processor "open" "$N"
}

xml::parse(){
  # entryfile=$1
  # exitfile=$2
  processor=${1#＆}
  filename="$2"
  # echo "$filename"
  OIFS="$IFS"
  local IFS="<"
  if [[ "$filename" != "" ]]; then
    while read -d \> C N
    do
      # local IFS="$OIFS"
      xml::parser::core $processor "$N" "$C" "$OIFS"
      # local IFS="<"
    done < "$filename"
  else
    while read -d \> C N
    do
      xml::parser::core $processor "$N" "$C" "$OIFS"
    done
  fi
}

xml_indent=
xml_tab=`echo -ne "\x09"`

xml::output::indent(){
  xml_indent="$xml_tab$xml_indent"
}

xml::output::unindent(){
  xml_indent="${xml_indent:1}"
}

xml::output::return(){
  echo ""
}

xml::output::print(){
  indent=$2
  data="$1"
  if [[ "$indent" == true ]]; then
    data="${xml_indent}$data"
  fi
  echo -ne "$data"
}

xml::reset(){
  xml_indent=
  nolf=false
}

nolf=false
xml::serialize(){
  # echo "Has type: $1"
  # echo "Has main: $2"
  type=$1
  main=$2
  shift 2
  case $type in
    "open")
      nolf=false
      xml::output::return
      xml::output::print "<$main" true
      while [[ $# != 0 ]] ; do
        xml::output::print " $1"
        shift 1
      done
      xml::output::print ">"
      xml::output::indent
    ;;
    "close")
      xml::output::unindent
      string::strip ＆main
      if [[ $nolf == false ]]; then
        xml::output::return
        xml::output::print "</$main>" true
      else
        xml::output::print "</$main>"
      fi
      nolf=false
    ;;
    "autoclose")
      xml::output::return
      string::strip ＆main
      xml::output::print "<$main" true
      while [[ $# != 0 ]] ; do
        xml::output::print " $1"
        shift 1
      done
      xml::output::print " />"
    ;;
    "pi")
      if [[ "$main" != "xml" ]]; then
        xml::output::return
      fi
      xml::output::print "<?$main" true
      while [[ $# != 0 ]] ; do
        xml::output::print " $1"
        shift 1
      done
      xml::output::print "?>"
    ;;
    "comment")
      xml::output::return
      xml::output::print "<!--" true
      # xml::output::return
      xml::output::print "$main"
      # xml::output::return
      xml::output::print "-->"
    ;;
    "doctype")
      xml::output::return
      string::strip ＆main
      # nolf=true
      xml::output::print "<!$main>" true
    ;;
    "content")
      # XXX may honor whitespace pre
      string::strip ＆main
      nolf=true
      xml::output::print "$main"
    ;;
    *)
      # xml::output::print "$main"
    ;;
  esac
}



# # A simple helper 
# _simplenode=
# xml_indent=
# xml_tab=`echo -ne "\x09"`
# # Serialize for a nodeName $1, with textContent $2, and attributes $3
# xml::serialize(){
#   _serializeOTN_name=$1
#   shift 1
#   _serializeOTN_value="$1"
#   shift 1

#   # Shit in the pipe
#   if [[ "$_serializeOTN_name" == "" ]]; then
#     return
#   fi

#   # Closing tags
#   string::startswith "$_serializeOTN_name" "/"
#   if [[ $poshout == true ]]; then
#     if [[ "$_simplenode" == "true" ]]; then
#       _simplenode=
#       echo "<$_serializeOTN_name>"
#     else
#       xml_indent="${xml_indent:1}"
#       echo "$xml_indent<$_serializeOTN_name>"
#     fi
#     return
#   fi

#   if [[ "$_simplenode" == "true" ]]; then
#     _simplenode=
#     xml_indent="$xml_tab$xml_indent"
#     echo ""
#   fi

#   # Comments
#   string::startswith $_serializeOTN_name "!--"
#   if [[ $poshout == true ]]; then
#   # if [[ "$_serializeOTN_name" == "!--" ]]; then
#     echo "${xml_indent}<$_serializeOTN_name $@>"
#     return
#   fi

#   # Short autoclosing tags
#   string::endswith $_serializeOTN_name "/"
#   if [[ $poshout == true ]]; then
#     string::strip _serializeOTN_name "/"
#     echo "<$_serializeOTN_name />"
#     # xml_indent="${xml_indent:1}"
#     return
#   fi

#   # Open, no LF
#   echo -n "$xml_indent<$_serializeOTN_name"

#   while [[ "$#" != "0" ]]; do
#     string::endswith "$1" "/"
#     if [[ $poshout == true ]]; then
#       sss="/"
#     fi
#     string::endswith "$1" "?"
#     if [[ $poshout == true ]]; then
#       sss="?"
#     fi
#     # string::endswith "$1" "--"
#     # if [[ $poshout == true ]]; then
#     #   sss="--"
#     # fi

#     if [[ "$sss" != "" ]]; then
#       a=$1
#       string::strip ＆a $sss
#       if [[ "$a" != "" ]]; then
#         echo -n " $a"
#       fi
#       echo " $sss>"
#       sss=
#       return
#     fi
#     echo ""
#     echo -n "$xml_indent$xml_tab$1"
#     shift 1
#   done

#   # Close, but don't LF - it depends if what follows is actual content then closing, or a hierarchy
#   echo -n ">"


#   # Cleanup values - a bit aggressive but well...
#   # vava=`echo $_serializeOTN_value | tr "\n" " " | tr "\r" " " | tr "\t" " "`
#   # vava=${vava// /}
#   # if [[ "$vava" != "" ]]; then
#   if [[ "$_serializeOTN_value" != "" ]]; then
#       _simplenode=true
#       echo -n $_serializeOTN_value
#   else
#     # XXX this is ugly on regular tags that contain nothingness...
#     _simplenode=true
#     # echo ""
#     # xml_indent="$xml_tab$xml_indent"
#   fi
# }

# trail=false
# xml::tpler(){
#   if [[ "$type" == "open"]] && [[ "$name" == "key"]]; then
#     trail=true
#   elif [[ "$" ]]
#   fi
#   type=$1
#   main=$2
#   shift 2
#   xml::serialize $type $main "$@"
# }

# file::read ＆tplist "$posh_root/posh.plist.tpl"
# $(echo "$tplist" | xml::parse proc)



# exit


# _tpl_helper(){
#   N=$1
#   C=$2
#   name=`echo $N | cut -d" " -f 1`
#   if [[ $name == "key" ]]; then
#     realname=$C
#     xml::serialize "$N" "$C"
#   elif [[ $name == "string" ]]; then
#     value=${C#\{}
#     value=${value%\}}
#     if [[ "$value" != "$C" ]]; then
#         export nn=args_$value
#         value=${!nn}
#     fi
#     tplvar=tpl_${realname}
#     export $tplvar=$value
#     xml::serialize "$N" "$value"
#   else
#     xml::serialize "$N" ""
#   fi
# }

# xml::processTpl(){
#   tpl=$1
#   output=$2
#   closure=$3
#   xml::pipe "$tpl" "$output" _tpl_helper
#   # And close
#   echo "</$closure>" >> "$output"
# }



# # A xml processor that will replace literals {stuff} by corresponding args_stuff value if it exists
# # be it in contents or in attributes
# _shallow(){
#   _shallow_name=$1
#   _shallow_value=$2
#   shift 2
#   _shallow_attr=$@

#   string::mustache _shallow_value
#   xml::serialize "$_shallow_name" "$_shallow_value" $_shallow_attr

#   # string::strip _shallow_value }{
#   # # string::strip _shallow_value "{"

#   # if [[ "$_shallow_value" == "" ]]; then
#   #   xml::serialize "$_shallow_name" "" $_shallow_attr
#   #   return
#   # fi
#   # if [[ "$_shallow_value" != "$C" ]]; then
#   #   # echo "****** $_shallow_value"
#   #   # echo -e $_shallow_value | hexdump
#   #   # exit

#   #   nn=args_$_shallow_value
#   #   replace_value=${!nn}
#   #   xml::serialize "$_shallow_name" "$replace_value" $_shallow_attr
#   # else
#   #   xml::serialize "$_shallow_name" "$C" $_shallow_attr
#   # fi
# }

# xml::shallowTpl(){
#   tpl=$1
#   output=$2
#   closure=$3
#   xml::pipe "$tpl" "$output" _shallow
#   # And close
#   echo "</$closure>" >> "$output"
# }



# xml::shallowTpl "$posh_root/posh.cast.tpl" "castItem.xml" "description"

# exit
