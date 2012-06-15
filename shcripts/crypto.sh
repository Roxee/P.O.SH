#!/bin/bash


generatekeys(){
  ui:warning "Different versions of openssl are known to break havoc here.\
If your signed updates don't validate in Sparkle in a cryptic way, \
double check what openssl version you have been using (which openssl) \
read https://answers.launchpad.net/sparkle/+question/37960 \
and/or try a different openssl version (possibly using brew)"
  if [[ ! -d "$1" ]]; then
      mkdir "$1"
  fi
  cd "$1"
  openssl dsaparam 2048 < /dev/urandom > dsaparam.pem
  openssl gendsa dsaparam.pem -out dsa_priv.pem
  openssl dsa -in dsa_priv.pem -pubout -out dsa_pub.pem
  rm dsaparam.pem
  ui:info "Keys generated into $1"
  ui:confirm "You NEED to understand that the private key is PRECIOUS - and you should back it up, and you MUST NOT loose it."
  cd -
}

crypto:keyscheck(){
  if [[ ! -f "$1/dsa_pub.pem" ]]; then
      ui:warning "No public key found in $1."
      ui:confirm "If you already have pem keys, break now and start this script again passing an explicit keys=path argument.\
      Otherwise, a new pair will be generated and put into $1."
      generatekeys "$1"
  fi
}

crypto:codesigndmg(){
  identity="$1"
  app_path="$2"
  if codesign -f -s "$identity" "$app_path" > /dev/null; then
      ui:info "..."
  else
      ui:error "Failed signing bitch! Probably your identity didn't check out. Are you who you pretend you are? :)))"
  fi
}


crypto:codesignapp(){
  identity="$1"
  app_path="$2"
  if codesign --resource-rules "$posh_root/posh.codesign.tpl" -f -s "$identity" "$app_path" > /dev/null; then
      ui:info "..."
  else
      ui:error "Failed signing bitch! Probably your identity didn't check out. Are you who you pretend you are? :)))"
  fi
  if [[ -d "$app_path/Contents/Frameworks" ]]; then
    if find "$app_path/Contents/Frameworks" -iname "Current" -exec codesign -f -s "$identity" "{}" \; > /dev/null; then
      ui:info "Signed frameworks succesfully"
    else
      ui:warning "Failed signing some framework!!!!!!!"
      # ui:confirm "Continue anyhow?"
      # candidates=`find "$app_path/Contents/Frameworks" -iname "Current"`
      # for i in $candidates; do
      #     echo "$i"
      #     if codesign -f -s "$identity" "$i" > /dev/null; then
      #         ui:info "Signed $i"
      #     else
      #         ui:warning "Failed signing framework $i"
      #     fi
      # done
    fi
  fi
}