# Start various things to make iSH more useful
echo
/usr/local/bin/rbg
if [ -e /run/openrc/softlevel ]
then
  echo "OpenRC Present"
else
  touch /run/openrc/softlevel
fi

#openrc-init
echo
echo "-----------------------------------------------"
echo  "Switching to non root ish account"
echo
echo "Use [31msudo[0m to run commands as root"
echo
su - ish
