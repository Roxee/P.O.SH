#!/bin/bash

trix=$(dirname "$0")
cd "$trix"
posh_root=`pwd`
cd - > /dev/null

source "$posh_root/shcripts/ui.sh"
source "$posh_root/shcripts/args.sh" $@
source "$posh_root/shcripts/help.sh"
source "$posh_root/shcripts/bin.sh"
source "$posh_root/shcripts/xml.sh"
source "$posh_root/shcripts/crypto.sh"
source "$posh_root/shcripts/dmg.sh"

ui:header "P.O.SH, a piece of shcript that nicely bundle piles of crode"

case $main_command in
  "help")
    help:short
  ;;
  "source")
    help:source
  ;;
  "version")
    help:version
  ;;
  "author")
    help:author
  ;;
  "license")
    help:license
  ;;
  "mayday")
    help:long
  ;;
  "")
  ;;
  *)
    ui:text "Interactive: posh"
    ui:text "Commands: version, author, license, source, help, mayday"
    ui:text "Programmatic: posh key=value key=value"
    ui:error "What? Albatros?"
  ;;
esac

# *************************************
# * Check requirements
# *************************************

ui:section "Checking basics"

# Initialize default arguments value for arguments that were not provided already
args:default keys ~/poshkeys
args:default background "$posh_root/posh.png"
args:default autoup NO
args:default autocheck YES
args:default profile NO

# Require binaries
bin:require openssl
bin:require curl
bin:require ruby
bin:require codesign
bin:require hdiutil

ui:info "Everything ok"

# *************************************
# * Application verification
# *************************************

ui:section "Checking your app"

args:fetch app path/to/your/super.app

if [[ ! -d "$args_app" ]]; then
  ui:error "Provided application path doesn't exist, stoopid! :)"
fi
if [[ ! -f "$args_app/Contents/Info.plist" ]]; then
  ui:error "Your app lacks an Info.plist. Please write one buddy."
fi
if [[ ! -d "$args_app/Contents/Resources" ]]; then
  mkdir "$args_app/Contents/Resources"
fi

# Make that absolute
bin:getpath "$args_app"

args_app=$abspath

ui:info "Everything OK"

# *************************************
# * Keys verification
# *************************************

ui:section "Checking keys"

crypto:keyscheck "$args_keys"

ui:info "Everything OK"


# *************************************
# * Prepping files
# *************************************

ui:section "Generating plist and copying key"

args:fetch version X.Y.Z
args:fetch feed http://brainfuck/myappcast.xml

# Copy the public key
cp "${args_keys}/dsa_pub.pem" "${args_app}/Contents/Resources"


# Now, update the thingie plist - do the heavylifting bayby :)

# Read the template, extract all the tpl_* variables and dump a copy using any {X} for args_X
preparator(){
  N=$1
  C=$2
  name=`echo $N | cut -d" " -f 1`
  if [[ $name == "key" ]]; then
    realname=$C
    xml:serialize "$N" "$C"
  elif [[ $name == "string" ]]; then
    value=${C#\{}
    value=${value%\}}
    if [[ "$value" != "$C" ]]; then
        export nn=args_$value
        value=${!nn}
    fi
    tplvar=tpl_${realname}
    export $tplvar=$value
    xml:serialize "$N" "$value"
  else
    xml:serialize "$N" ""
  fi
}

xml_indent="$xml_tab$xml_tab"
xml:readfile "$posh_root/posh.plist.tpl" "${args_app}/Contents/Info.plist.processed" "preparator"
# And close
echo "</string>" >> "${args_app}/Contents/Info.plist.processed"



# Now, read the info.plist, and proceed with the nasty dance
passup=0
ok=
congrulator(){
  name=`echo $N | cut -d" " -f 1`
  # If we were ordered to passup, let's do
  if [[ $passup -gt 0 ]]; then
      # Ignore comments when gobbling up stuff
      if [[ "${name:0:1}" != "!" ]]; then
          passup=`expr $passup - 1`
      fi
  elif [[ $name == "key" ]]; then
      realname=$C
      tplvar=tpl_${realname}
      # No tpl value means we don't handle that one - copy as is
      if [[ "${!tplvar}" == "" ]]; then
          xml:serialize "$N" "$C"
      else
          # Going to ignore the closing tag and the string tag that follows it
          passup=3
      fi
  elif [[ "$name" == "dict" ]] && [[ "$ok" == "" ]]; then
      # This is the start of the stream - append whatever the (processed) defined shit be
      xml:serialize "$N" "$C"
      ok=true
      cat "${args_app}/Contents/Info.plist.processed"
  else
      # Anything else has to pass through
      xml:serialize "$N" "$C"
  fi
}

xml_indent=""
xml:readfile "${args_app}/Contents/Info.plist" "${args_app}/Contents/Info.plist.filtered" "congrulator"
# And close
echo "</plist>" >> "${args_app}/Contents/Info.plist.filtered"


# Cleanup - wooot woooot!
cp "${args_app}/Contents/Info.plist.filtered" "${args_app}/Contents/Info.plist"
rm "${args_app}/Contents/Info.plist.filtered"
rm "${args_app}/Contents/Info.plist.processed"


ui:info "Generating plist and copying key: OK"


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
ui:section "Code signing your application"

args:fetch sign "3rd Party Mac Developer Application: Jocelyne la Chaudasse - use 'chuck' to disable codesigning altogether"

if [[ "$args_sign" != "" ]] && [[ "$args_sign" != "chuck" ]]; then
  crypto:codesignapp "$args_sign" "$args_app"
  ui:info "Code signing your application: OK"  
else
  ui:warning "Not signing your code is a mistake, Chuck! But well, you are the boss."
fi


# *************************************
# * Now, pack that baby up
# *************************************

ui:section "Packing the shit up into a nicy dmg"

args:fetch background path/to/super/background
if [[ ! -e $args_background ]]; then
    ui:error "Err, your nicy background doesn't exist baby."
fi

aname="${args_app##*/}"
dmg:make "${aname%%.*} Install" "${aname%%.*}-install-${args_version}" "${aname%%.*}" "${args_app%/*}" "${args_background##*/}" "${args_background%/*}"

dmgFinal="${args_app%/*}/${aname%%.*}-install-${args_version}.dmg"

ui:info "Packing the shit up into a nicy dmg: check!"


# *************************************
# * Codesign the dmg
# *************************************

ui:section "Codesign the dmg"

# echo $dmgFinal

crypto:codesigndmg "$args_sign" "$dmgFinal"

# *************************************
# * Sparkle sign the dmg, prepare the appcast
# *************************************

exit


ui:section "Sparkle prepare sign the dmg"

## Compute signature
#signature=`openssl dgst -sha1 -binary < "${appBasePath}/${dmgFileName}.dmg" | openssl dgst -dss1 -sign "$crypto_private_key" | openssl enc -base64`
## Compute size
#sizi=`ls -l sign_update.rb | awk '{ print $5}'`
##
#curl -o feed.remote.xml "${args_feed}"



#logFileName=${dmgFileName}.html
#cp "${args_changelog}" "logFileName"
#logContent=
#sed s/{changelog}/$1/ posh.log.tpl < $args_logfile > "$logFileName"


#posh.cast.tpl
#<title>{synthetic_title}</title>
#<pubDate>{synthetic_date</pubDate>
#<enclosure url="{synthetic_pack_url}" sparkle:version="{version}" type="application/octet-stream" length="{synthetic_size}" sparkle:dsaSignature="{synthetic_signature}" />
#<description>{synthetic_log_url}</description>



#echo " *******"
#echo " *******"
#echo -n $signature
#echo " *******"
#echo " *******"
#echo -n $sizi
#echo " *******"
#echo " *******"
ui:info "Sparkle sign the dmg: OK"


#  length = os.path.getsize(packpath)

#  encloseurl = fs.dirname(casturl) + '/packages/' + fs.basename(packpath)

#  # Finally generate the appcast file

#  # Otherwise, puke returns the cached version :(
#  sh('puke -c')
#  # Get the previous file at url X
#  try:
#    stuff = FileList(casturl)
#    deepcopy(stuff, Yak.TMP_ROOT)
#    local = fs.readfile(fs.join(Yak.TMP_ROOT, fs.basename(casturl)))
#  except:
#    local = fs.readfile('appcasttpl.xml')
#    local = local.replace("{CAST-URL}", casturl)

#  from email.utils import formatdate
#  reladate = formatdate(timeval=None, localtime=True, usegmt=True)


#  newversion = """
#    <item>
#          <title>%s version %s</title>
#          <pubDate>%s</pubDate>
#          <enclosure url="%s" sparkle:version="%s" type="application/octet-stream" length="%s" sparkle:dsaSignature="%s" />
#      </item>
#  </channel>
#  """ % (name, version, reladate, encloseurl, version, length, signature)

#  local = local.replace('</channel>', newversion)

#  pubcast = Yak.PACK_ROOT + "/" + fs.basename(casturl)
#  fs.writefile(pubcast, local)

## THIS IS XXX ABOMINABLE
## user-jenkins-box-Linux:
##     ROOT: '/opt/puke/jenkins-roxee'
##     DEPLOY_ROOT: '/var/www/deploy/static/lib'
##     DOC_ROOT: '/var/www/deploy/static/doc/roxeecore'

#  sh('scp %s %s' % (pubcast, 'app.roxee.net:/home/roxee/www/app/webroxer/'))
#  sh('scp %s %s' % (packpath, 'app.roxee.net:/home/roxee/www/app/webroxer/packages'))

#  client = SSH()
#  client.load_system_host_keys()
#  client.connect('app.roxee.net', username="dmp")
#  sh('chmod a+r %s; chmod -R a+r %s' % ('/home/roxee/www/app/webroxer/appcast.xml', '/home/roxee/www/app/webroxer/packages'), ssh=client)
