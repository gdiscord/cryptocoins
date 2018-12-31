#!/bin/sh

if $1="update"; then
cd
su xlibmn -c "liberty-cli stop"
wget https://s3.amazonaws.com/liberty-builds/5.0.72.0/linux-x64.tar.gz
tar xvzf linux-x64.tar.gz
rm linux-x64.tar.gz
mv linux* /usr/local/bin
sleep 10
echo "few seconds remaining. please wait ..."
su xlibmn -c "libertyd -deamon"
su xlibmn -c "liberty-cli "
echo "masternode is successfully updated and running the newest wallet release version"
echo "you must re-activate the node from your desktop wallet now."

else
CONF_FILE="/home/xlibmn/.liberty/liberty.conf"
DEFAULT_RPC_PORT=10416
PORT=10417
MASTERNODE_GEN_KEY=$1
WANIP=$(wget -qO- ipinfo.io/ip)

if [ -z "$MASTERNODE_GEN_KEY" ] 
then
	echo "|||!!!!!!                                 !!!!!!!|||"
	echo "|||!!!!!!   STOP on MISSING INFORMATION   !!!!!!!|||"
	echo "                                                    "
	echo "        ---------------------------------           "
	echo "                                                    " 
	echo "       Masternode private key is missing.           "   
	echo "                                                    "   
	echo "  1. Open debug console on your desktop wallet.     " 
	echo "                                                    " 
	echo "          2. type: createmasternodekey.             "   
	echo "                                                    " 
	echo "   Then use that to start the script as below:      "    
	echo "                                                    "
	echo "           $0 <masternode_gen_key>                  "    
	echo "                                                    "
	echo "======  ------------------------------------- ======"   
	echo "===================================================="
	echo "===================================================="
	exit 
fi


apt install make
apt install aptitude -y
apt-get update -y
apt-get upgrade -y

apt-get install fail2ban -y
cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

apt install tzdata

fallocate -l 3000M /mnt/3000MB.swap
dd if=/dev/zero of=/mnt/3000MB.swap bs=1024 count=3072000
mkswap /mnt/3000MB.swap
swapon /mnt/3000MB.swap
chmod 600 /mnt/3000MB.swap
echo '/mnt/3000MB.swap  none  swap  sw 0  0' >> /etc/fstab

useradd -m -s /bin/bash xlibmn

wget https://s3.amazonaws.com/liberty-builds/5.0.72.0/linux-x64.tar.gz
sudo tar xvzf linux-x64.tar.gz -C /usr/local/bin/
su xlibmn -c "libertyd -daemon"

if ! apt-get -qq install pwgen; 
    then
		sudo apt-get install pwgen
fi
if ! apt-get -qq install dnsutils; 
	then 
		sudo apt-get install dnsutils
fi
RPC_USER=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
PASSWORD=$(pwgen -s 64 1)

echo "creating conf file"
su xlibmn -c "liberty-cli stop" && sleep 5

cat <<EOF > "$CONF_FILE"
rpcuser=$RPC_USER
rpcpassword=$PASSWORD
rpcallowip=127.0.0.1
rpcport=$DEFAULT_RPC_PORT
port=$PORT
listen=1
server=1
daemon=1
maxconnections=256
masternode=1
masternodeadd=$WANIP
masternodeprivkey=$MASTERNODE_GEN_KEY
EOF
cat "$CONF_FILE"



su xlibmn -c libertyd
echo "please wait... just seconds to go!"
sleep 15
su xlibmn -c "liberty-cli getblockcount"


echo "|||!!!!!!!!!!!!!!!!!!!!!                            !!!!!!!!!!!!!!!!!!!!"
echo "|||!!!!!!!!!!!!!!!!!!!!!   !!!CONGRATULATIONS!!!    !!!!!!!!!!!!!!!!!!!!"
echo "                                                                       "
echo "              --------------------------------                         "
echo "                                                                       " 
echo "       Your Liberty wallet is deployed and running on VPS.             "
echo "                                                                       " 
echo "         The public ip address of your Masternode is $WANIP.           "  
echo "                                                                       "   
echo "               Use this ip to setup your desktop wallet.               "    
echo "                                                                       "   
echo "                                                                       " 
echo "    Remember to use the same masternodeprivkey in your desktop wallet  "        
echo "                                                                       "
echo "                                                                       " 
echo "=========   --------------------------------------------   ============"   
echo "======================================================================="
echo "======================================================================="
fi

#clean up
rm $0
