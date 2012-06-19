#!/bin/bash
##################################################################################
# P.O.SH
# (c) 2012 Mangled Deutz <dev@webitup.fr>
# Distributed under the terms of the WTF-PL: do wtf you want with that code
##################################################################################

_author="Author: Mangled Deutz (dev@webitup.fr)"
_version="Version: 0.42"
_license="License: WTF license + just give me credit for it if it works - don't if it doesn't"
_giturl="https://github.com/webitup/P.O.SH"

help::version(){
  ui::section Version
  ui::text $_version
  exit
}

help::author(){
  ui::section Author
  ui::text $_author
  exit
}

help::license(){
  ui::section License
  ui::text $_license
  exit
}

help::source(){
  ui::section Source
  ui::text $_giturl
  exit
}


help::short(){
  ui::section Basic help
  ui::text "P.O.SH take a builded MacOSX application, prepare it for update (Sparkle), codesign it, upgrade the appcast\
  build a glorified dmg, sparkle-sign the dmg, and upload the shit."
  ui::text "It also use a powerful templating system to make this process easily customizable."
  ui::text 
  ui::text "Basic/interactive use: ./posh.sh"
  ui::text "... and answer the questions"
  ui::text 
  ui::text "Using parameters to avoid interactive: ./posh.sh app=path version=1.2.3 sign=Josette Développe feed=http://stuff/myappcast.xml"
  ui::text "... will prep your app located at path using the provided parameters"
  ui::text 
  ui::text "For a fully detailed help, try ./posh.sh mayday"
  ui::text 
  ui::text "Other simple commands that P.O.SH recognize: version, author, license, source"
  exit
}

help::long(){
  ui::section Advanced help
  ui::section "Generalities"

  ui::text "P.O.SH is a helper script collection meant to take your nice OSX application (that uses Sparkle, \
and Breakpad, because you are a classy cunt), and dramatically ease the process of 'publishing' it."
  ui::text "Technically, it manages Info.plist, codesigning, appcast updating, Sparkle signing, dmg generation and \
upload processes easy to insert into your build environment of choice."
  ui::text
  ui::text "P.O.SH is pure bash, and depends exclusively on either OSX readily available tools (namely curl and openssl) \
or tools provided by XCode (codesign)"
  ui::text
  ui::text "P.O.SH started as a helper for RoxeeMegaUp, a piece of crode meant to make it trivial to embark \
Sparkle/WinSparkle in a QT app and enjoy OSX/WIN auto updating. Check it out at https://github.com/webitup/qt-roxeemegaup."

  ui::text "What P.O.SH does specifically?"
  ui::text " - your Info.plist, if existing (and it should), will be updated properly with any Sparkle-relevant information"
  ui::text " - your app will be codesigned, using your apple developer key (Frameworks will be signed as well)"
  ui::text " - a nice dmg package will be generated"
  ui::text " - a signature for the dmg will be computed using your Sparkle keys so that your updates are secured (a key pair will be generated if \
you don't have one already)"
  ui::text " - the dmg will be uploaded over ssh, along with the updated appcast and changelog file"
  ui::text ""
  ui::text "Note that this is divided in tasks, that can be selectively disabled."
  ui::text "Also note that template files supporting a flexible syntax are used extensively, allowing you to customize the shit."

  ui::section "Basic usage"

  ui::text "P.O.SH can be used interactively simply by calling posh.sh."
  ui::text "You will then be prompted regularly for parameters and path to provide"
  ui::text 
  ui::text "But you can also can it purely programmatic, passing it key/values parameters like this: ./posh.sh key=value key=value"
  ui::text "where key/value pairs correspond to any of the following:"
  ui::text " - app=path -> the mother of parameters, that points to your app directory (eg: app=~/SuperApp.app)"
  ui::text " - keys=path -> allows you to point to a directory where your Sparkle keys reside (defaults to ~/poshkeys)"
  ui::text " - sign=Josette Gaudiche -> allows you to specify your apple developper identity to be used by the signing process"
  ui::text " - version=X.Y.Z -> what will be the new version of your app?"
  ui::text " - feed=http://super/cast.xml -> the url of your appcast feed - if it exists, it will be fetched and used as a base, if not, a \
new one will be generated from the template"
  ui::text
  ui::text "Note that a value may contain unescaped space or any other kinky character (but the equal sign)"
  ui::text
  ui::text "If you fail to provide any 'required' argument, you will be prompted interactively to provide them."
  ui::text "If you fail to provide any 'optional' argument, a default value will be used."

  ui::section "Not doing some tasks"

  ui::text "Say, if you don't use sparkle, but still want a signed app and a dmg, you can do so by 'chucking' tasks:"
  ui::text " - sign=chuck: will disable the code signing part"
  ui::text " - sparkle=chuck: will disable any Sparkle related operation (implies upload=chuck)"
  ui::text " - upload=chuck: skip the uploading part. You will be left with a prepped-up dmg and possibly updated appcast file"

  ui::section "Advanced arguments"

  ui::text "Here are the (optional) arguments used by the templates that you can access (see posh.plist.tpl):"
  ui::text " - autocheck=YES/NO -> whether Sparkle will automatically verify updates (defaults to YES)"
  ui::text " - autoup=YES/NO -> whether Sparkle will automatically download new updates (defaults to NO)"
  ui::text " - profile=YES/NO -> whether Sparkle will send you anonymous platform informations (defaults to NO)"

  ui::section "Codesigning"

  ui::text "What you need to now:"
  ui::text " - you SHOULD edit the file posh.codesign.tpl in order to fine-tune what is going to be signed in your bundle"
  ui::text " - Frameworks in your app are going to be signed as well - if their info.plist is borked, you will be warned but the build won't stop!!!"
  ui::text " - the dmg is signed as well"
  ui::text " - Qt* are especially borked frameworks - you need to fix the Info.plist contents and locations manually"

  ui::section "Templating system"

  ui::text "You understood that posh uses the content of the posh.plist.tpl file to decide what values \
should be exfiltered from your info plist, and appropriately replaced by parameters you specify."
  ui::text "It's very simple to extend on that to support new command line parameters and plist values. Technically:"
  ui::text " - edit the posh.plist.tpl, and add exactly <key>DSObscureAppleName</key><string>{poshrox}</string>"
  ui::text " - now, call posh using an extra parameter: poshrox=somevalue"
  ui::text " - look at the generated info.plist file, and witness the power of posh"
  ui::text "Right now, only key/string pairs support this mechanism though."

  ui::section "Final words"

  ui::text "All this might or might not work for you. This shcript has been croded for the sole reason I was tired of \
doing all that manually for the Roxee project."
  ui::text ""
  ui::text "P.O.SH is a friend of PUKE, the versatile python build system."
  ui::text "    .-'\"'-."
  ui::text "   / \`. ,' \\ "
  ui::text "  |  ,' \`.  |"
  ui::text "  |   ___   |"
  ui::text "   \ ( . ) /"
  ui::text "    '-.:.-'"
  ui::text "      .:."
  ui::text "      ::: "
  ui::text "      :::"
  ui::text "      ::."
  ui::text "      '::"
  ui::text "       '"
  exit
}