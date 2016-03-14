#!/bin/bash

[[ ${fixCrypto+x} ]] || fixCrypto='fix' ;

thisD=`dirname "$0"` ;
[[ "" == "$thisD" ]] && thisD='.' ;
[[ -z $DEBUG ]] && DEBUG='1' ;

consts() {
  [[ -z $HOME ]] && export HOME=`bash -c "cd && pwd"` ;

  encryptedSuffix='encrypted' ;
  decryptKey=~/.ssh/id_rsa.pem ;
  encryptCert=~/.ssh/id_rsa.cert ;
  encrypt='openssl smime -encrypt -binary -aes256 -outform DER' ;
  decrypt='openssl smime -decrypt -binary -inform DER' ;
  [[ $mkcertSubj ]] || mkcertSubj='/C=US/ST=State/L=Location/O=Org/CN=aVeryCommonName' ;
  
  privKey=~/".ssh/id_rsa.${encryptedSuffix}" ;
  if [[ -e ~/.ssh/id_rsa.pem ]] ; then
    privKey=~/.ssh/id_rsa.pem ;
  fi ;
  if [[ ! -e $privKey ]] ; then
    privKey=~/.ssh/id_rsa ;
  fi ;
  decryptKey=$privKey ;
  mkcert="openssl req -new -key $privKey -nodes -x509 -days 3650 -subj \"$mkcertSubj\" -out" ;
  encryptprivkey="openssl rsa -des3 -in $privKey -out" ;
  # decryptprivkey="openssl rsa -in ~/.ssh/id_rsa.priv -out" ;
  decryptprivkey="openssl rsa -in ~/.ssh/id_rsa.$encryptedSuffix -out" ;
  genPubKey="openssl rsa -pubout -in " ;
  genSshPubKey="ssh-keygen -y -f " ;
  
}
initCrypto() {
  consts ;
  
  d="$HOME/.ssh" ;
  if [[ ! -e "$d/id_rsa" ]] ; then
    if [[ ! -e "$d/id_rsa.pem" ]] ; then
      # if [[ ! -e "$d/id_rsa.priv" ]] ; then
      if [[ ! -e "$d/id_rsa.$encryptedSuffix" ]] ; then
        echo "ERROR: Failed to find .ssh/id_rsa .  We could generate one via ssh-keygen -t rsa but it is rare not to have one at all.  Before running ssh-keygen, reconsider your situation and why your user account lacks fundamental SSH credentials (perhaps it was provisioned via 'useradd' instead of 'adduser'?)." 1>&2 ;
        exit 1 ;
      else
        if [[ "fix" == "$fixCrypto" ]] ; then
          echo "Prepare to be prompted for private key password:" ;
          eval "$decryptprivkey $d/id_rsa.pem " || rm $d/id_rsa.pem ;
        fi ;
        echo "# decrypt private key $d/id_rsa.pem: $decryptprivkey $d/id_rsa.pem" 1>&2 ;
        cexecute ln -s "id_rsa.pem" "$d/id_rsa" ;
        _cexecute ls "$d/id_rsa.pem" ;
      fi ;
    else
      cexecute ln -s "id_rsa.pem" "$d/id_rsa" ;
    fi ;
  fi ;
  if [[ ! -e "$d/id_rsa.pem" ]] ; then
      cexecute ln -s "id_rsa" "$d/id_rsa.pem" ;
  fi ;
  
  f='id_rsa.cert' ;
  if [[ ! -e $d/$f ]] ; then
    if [[ "fix" == "$fixCrypto" ]] ; then
      # echo "Prepare to be prompted for private key password:" ;
      echo "You aren't prompted for private key password, are you?" ;
      (cd $d && eval "$mkcert $f" ; 
      ) ;
    # else
    fi ;
      echo "# make cert $d/$f" 1>&2 ;
  fi ;
  
  d="$HOME/.ssh" ;
  f="id_rsa.${encryptedSuffix}" ;
  if [[ ! -e $d/$f ]] ; then
    if [[ "fix" == "$fixCrypto" ]] ; then
      echo "Prepare to be prompted for private key password:" ;
      eval "$encryptprivkey $d/$f" || rm $d/$f ;
      echo "# encrypt private key $d/$f: $encryptprivkey $f" 1>&2 ;
    else
      echo "# encrypt private key $d/$f" 1>&2 ;
    fi ;
  fi ;
  if [[ ! -e $d/$f ]] ; then
    echo "ERROR: Failed to encrypt private key into $f .  It is best to have an encrypted private key for the sake of backing up your SSH credentials without vulnerability." \
    1>&2 ;
  fi ;
  
  find ~/.ssh -type f -name '*.pem' > tmp.cryptic.txt ;
  while read f ; do
    local x=`ls -ld "$f" | egrep -v '^.r..[\-][\-][\-][\-][\-][\-]' ` ;
    [[ -z $x ]] || cexecute chmod go-rwx "$f" ;
  done < tmp.cryptic.txt ;
  rm -f tmp.cryptic.txt ;

  local cfgd="$HOME/.ssh/pairConfigs" ;
  for cfg in `ls "$cfgd/" ` ; do
    local d=`head -1 "$cfgd/$cfg" ` ;
    local f=`head -2 "$cfgd/$cfg" | tail -1 ` ;
    [[ $f ]] || continue ;
    [[ -e $d/$f.$encryptedSuffix ]] || execute encryptFileFromTo $d/$f   $d/$f.$encryptedSuffix ;
    [[ -e $d/$f ]]                  || execute decryptFileFromTo $d/$f.$encryptedSuffix   $d/$f ;
  done ;
  
  # # # XXX TODO: Search for *.pem and *.secret and .priv it.
  # # # XXX TODO: Search for *.pem and .pub.ssh it.
  if [[ '' ]] ; then
  for f in $privateKeys \
  ; do
    local subd=`dirname "$d/$f"` ;
    local basef=`basename "$d/$f"` ;
    # local noExt=`echo "$f" | perl -ne 's/[.][^.]*$// ; print $_' ` ;
    local noExt=`echo "$basef" | perl -ne 's/[.][^.]*$// ; print $_' ` ;
    [[ -e "$d/$f.pub" ]]         || execute getPubKeyFromTo "$d/$f" "$d/$f.pub" ;
    # local cmd1="cd $d && chmod u+w . && ln -s \"$noExt.pub.ssh\" \"$noExt.pub\"" ;
    local cmd1="cd $subd && chmod u+w . && ln -s \"$noExt.pub.ssh\" \"$noExt.pub\"" ;
    cmd1="$cmd1 && chmod a-w ." ;
    [[ -e "$d/$noExt.pub" ]]     || execute bash -c "$cmd1" ;
    local priv="$d/$f" ;
    # local pub="$d/$noExt.pub.ssh" ;
    local pub="$subd/$noExt.pub.ssh" ;
    # [[ -e "$d/$noExt.pub.ssh" ]] || execute getSshPubKeyFromTo "$d/$f" "$d/$noExt.pub.ssh" ;
    [[ -e "$pub" ]] || execute getSshPubKeyFromTo "$priv" "$pub" ;
  done ;
  fi ;
  
}
csanitizeForEval() { # Usage: trustworthyVar=$(sanitizeForEval "$riskyVar")
  local inString=$1 ;
  local outString=$(echo "$inString" | tr -d '"' | tr -d "'" | tr -d '\n' | tr -d '\r' ) ;
  echo "$outString" ;
}
cexecute() {
  cmdX="$@" ;
    echo "$cmdX" ;
  if [[ "fix" == "$fixCrypto" ]] ; then
    _cexecute "$@" ;
  else
    error=`echo -e "$error\n$cmdX" ` ;
  fi ;
}
_cexecute() {
  cmdX="$@" ;
  [[ $DEBUG ]] && echo "$cmdX" 1>&2 ;
  "$@" ;
  error=$? ;
  if [[ -z $error || "$error" == "" || "$error" == "0" ]] ; then
    true ;
  else
    echo "ERROR: From command $cmdX: '$error'." 1>&2 ;
    exit $error ;
  fi ;
}
encryptFileFromTo() {
  infile=$1 ;
  outfile=$2 ;
  # cmd="$encrypt -in $infile -out $outfile $encryptCert" ;
  outfile=`echo "$outfile" | perl -ne "s{[~]}{$HOME} ; print \$_" ` ;
  infile=`echo "$infile" | perl -ne "s{[~]}{$HOME} ; print \$_" ` ;
  infile=`readlink -f "$infile" 2>/dev/null || greadlink -f "$infile"` ;
  # infile=`readlink -f $infile 2>/dev/null || greadlink -f $infile ` ;
  d=`dirname $outfile` ;
  of=`basename $outfile` ;
  cmd="$encrypt -in $infile -out $of $encryptCert" ;
  # doChmod=`ls -lartd "$d"/ | egrep -v '^..w'` ;
  doChmod=`ls -lartd "$d"/ | egrep -v '^..w'` ;
  if [[ -d $d && -e $infile && ! -e $outfile ]] ; then
    if [[ "fix" == "$fixCrypto" ]] ; then
      if [[ $doChmod ]] ; then
        _cexecute chmod u+w "$d" ;
      fi ;
      (cd $d && eval "$cmd" ; 
      ) ;
      echo "# encrypt : $cmd" ;
      _cexecute chmod a-w "$d" ;
    else
      echo "# encrypt $infile to $outfile: $cmd" ;
    fi ;
    _cexecute chmod a-w "$outfile" ;
  fi ;
}
decryptFileFromTo() {
  infile=$1 ;
  outfile=$2 ;
  # cmd="$decrypt -in $infile -out $outfile -inkey $decryptKey" ;
  outfile=`echo "$outfile" | perl -ne "s{[~]}{$HOME} ; print \$_" ` ;
  infile=`echo "$infile" | perl -ne "s{[~]}{$HOME} ; print \$_" ` ;
  infile=`readlink -f "$infile" 2>/dev/null || greadlink -f "$infile"` ;
  # infile=`readlink -f $infile 2>/dev/null || greadlink -f $infile ` ;
  d=`dirname $outfile` ;
  of=`basename $outfile` ;
  cmd="$decrypt -in $infile -out $of -inkey $decryptKey" ; 
  if [[ -d $d && -e $infile && ! -e $outfile ]] ; then
    if [[ "fix" == "$fixCrypto" ]] ; then
      if [[ $doChmod ]] ; then
        _cexecute chmod u+w "$d" ;
      fi ;
      (cd $d && eval "$cmd" ; # QQQ XXX Typo/logic error: If outfile has a non-blank dirname this has to break the command (cmd) because it uses outfile, not its basename.
      ) ;
      echo "# decrypt $infile into $outfile: $cmd" ;
      _cexecute chmod a-w "$d" ;
    else
      echo "# decrypt $infile into $outfile: $cmd" ;
    fi ;
    _cexecute chmod a-w "$outfile" ;
    _cexecute chmod go-rx "$outfile" ;
  fi ;
}
getSshPubKeyFromTo() {
  _getPubKeyFromTo "$1" "$2" "$genSshPubKey" ;
}
getPubKeyFromTo() {
  _getPubKeyFromTo "$1" "$2" "$genPubKey" ;
}
_getPubKeyFromTo() {
  local infile=$(csanitizeForEval "$1") ;
  local outfile=$(csanitizeForEval "$2") ;
  local absInfile=`readlink -f "$infile" 2> /dev/null || greadlink -f "$infile" ` ;
  local d=`dirname "$outfile" ` ;
  local b=`basename "$outfile" ` ;
  local cmd="$3 \"$absInfile\"" ;
  doChmod=`ls -lartd "$d"/ | egrep -v '^..w'` ;
  if [[ -d $d && -e $infile && ! -e $outfile ]] ; then
    if [[ "fix" == "$fixCrypto" ]] ; then
      if [[ $doChmod ]] ; then
        _cexecute chmod u+w "$d" ;
      fi ;
      (cd $d && eval "$cmd" > "$b" ; 
      ) ;
      echo "# Public key from private key $infile into $outfile: $cmd" ;
      if [[ $doChmod ]] ; then
        _cexecute chmod a-w "$d" ;
      fi ;
    else
      echo "# Public key from private key $infile into $outfile: $cmd" ;
    fi ;
  fi ;
}

#
