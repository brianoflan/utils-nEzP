#!/bin/bash

# # # Use on a Ubuntu instance like so:
# # #   f=runAwsEc2Vnc.sh ; curl -sL https://raw.githubusercontent.com/brianoflan/utils-nEzP/master/$f > ./$f && sudo bash ./$f

sudo bash -c "apt-get -y update && apt-get -y install --no-install-recommends lubuntu-desktop && apt-get -y install tightvncserver expect autocutsel" ;

# echo "pw$(date -u +'%Y%m%d')\npw$(date -u +'%Y%m%d')\nn\n\n" | vncpasswd ;

prog=/usr/bin/vncpasswd
mypass="pw$(date -u +'%Y%m%d')"

/usr/bin/expect <<EOF
spawn "$prog"
expect "Password:"
send "$mypass\r"
expect "Verify:"
send "$mypass\r"
expect "y/n"
send "n\r"
expect eof
exit
EOF

# vncserver ;
# export DISPLAY=:1 ;
# nohup startlxde &> ~/startlxde.log & echo "started lxde" ;

vncserver :1 ;
vncserver -kill :1 ;

cat > ~/.vnc/xstartup <<'EOF2'
#!/bin/sh

xsetroot -solid grey -cursor_name left_ptr
autocutsel -fork
/usr/bin/lxsession -s Lubuntu -e LXDE
EOF2

vncserver :1 -geometry 1024x768 ;

#
