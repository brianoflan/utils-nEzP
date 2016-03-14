#!/bin/bash

# Only arg = 'fix' to fix what's wrong.
fix=$1 ;

consts(){
  thisDir=$(dirname $0) ;
  pwdX=$(pwd) ;
  # abs=`dirname $0 | sed -e 's/^\(.\).*$/\1/'` ;
  # if [[ -z $thisDir || "$thisDir" == "." ]] ; then
  #   thisDir="$pwdX" ;
  # else
  #   if [[ "$abs" != "/" ]] ; then
  #     thisDir="$pwdX/$thisDir" ;
  #   fi ;
  # fi ;
  cd $thisDir ;
  abs=`pwd` ;
  thisDir=$abs ;
  scriptBase=$(basename $0) ;
  # cd $thisDir ;

  [[ -z $DEBUG ]] && DEBUG='1' ;
  [[ -z $HOME ]] && export HOME=`bash -c "cd && pwd"` ;

  [[ ! -e $0.consts ]] || source $0.consts ;
  fixCrypto="$fix" ;
  source "$thisDir/cryptic.sh" ;
}

main(){
  consts ;
  local error='' ;

  initCrypto ;
  
  if [[ "fix" != "$fix" && $error ]] ; then
    echo "ERROR: I checked and found problems:" ;
    echo "$error" | perl -ne 'print "  $_" ' ;
    echo ;
    echo "  Re-run $0 with one argument 'fix' to repair." ;
    echo ;
  fi ;
  
}






idemGemInstall(){
  local pkg=$1 ;
  local pkgBase=`basename "$pkg"` ;
  local x=`gem list | perl -ne "m{^\\Q$pkgBase\\E(\\s|\$)} && print \$_" ` ;
  if [[ -z $x ]] ; then
    execute gem install "$pkg" ;
  fi ;
}
idemRbenvInstall(){
  local pkg=$1 ;
  local pkgBase=`basename "$pkg"` ;
  local x=`rbenv versions | perl -ne "m{\\Q$pkgBase\\E\$} && print \$_" ` ;
  if [[ -z $x ]] ; then
    execute rbenv install "$pkg" ;
  fi ;
}
idemBrewInstall() {
  # pwd 1>&2 ;
  local pkg=$1 ;
  local pkgBase=`basename "$pkg"` ;
  local x=`brew list | perl -ne "m{\\Q$pkgBase\\E\$} && print \$_" ` ;
  if [[ -z $x ]] ; then
    local x=`brew cask list | perl -ne "m{\\Q$pkgBase\\E\$} && print \$_" ` ;
    if [[ -z $x ]] ; then
      execute brew install "$pkg" ;
    else
      [[ $DEBUG -gt 2 ]] && echo "DEBUG: Package $pkg already installed." 1>&2 ;
    fi ;
  else
    [[ $DEBUG -gt 2 ]] && echo "DEBUG: Package $pkg already installed." 1>&2 ;
  fi ;
  # pwd 1>&2 ;
}












execute() {
  local cmdX="$@" ;
  # echo "$cmdX" ;
  if [[ "fix" == "$fix" ]] ; then
    _execute "$@" ;
  else
    # echo "Not yet executing $cmdX (fix=$fix)." 1>&2 ;
    error=`echo -e "$error\n$cmdX" ` ;
  fi ;
}
_execute() {
  local cmdX="$@" ;
  echo "$cmdX" ;
  "$@" ;
  local err=$? ;
  if [[ -z $err || "$err" == "" || "$err" == "0" ]] ; then
    true ;
  else
    echo "ERROR: From command $cmdX: '$err'." 1>&2 ;
    exit $err ;
  fi ;
}

main ;

#

