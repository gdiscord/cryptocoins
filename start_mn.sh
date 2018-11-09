#!/bin/bash

COIN=digiwage
MN_NAME=$1
HOST_COIN_HOME=/root/.$1
CONF_FILE=$HOST_COIN_HOME/$COIN.conf
COIN_DATADIR=/home/.$COIN
COIN_ADMIN_TEMP=/root/.$COIN
COIN_CONF=$MN_NAME:/$COIN_DATADIR/$COIN.conf
DEFAULT_RPC_PORT=46002
PORT=46003
DOCKER_REPO=gccdocker/$COIN
MASTERNODE_GEN_KEY="$2"

DKR=docker-ce
PTNR=portainer
TEMP=$HOST_COIN_HOME/.rootconf

sudo apt-get update

WANIP=$(wget -qO- ipinfo.io/ip)


if ! apt-get -qq install $DKR; 
	then
	#install docker
	sudo apt-get remove docker docker-engine docker.io

	sudo apt-get update

	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

	sudo add-apt-repository \
	   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
	   $(lsb_release -cs) \
	   stable"

	sudo apt-get update

	sudo apt-get -y install docker-ce

	#install portainer
	sudo docker volume create portainer_data
	sudo docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer
fi


if [ -z "$MN_NAME" ] 
	then
	  echo "Masternode name missing. Please start the script correctly"
	  echo "Usage is: $0 <mn_name> <masternod_gen_key>"
	  exit 1
fi

if [ -z "$MASTERNODE_GEN_KEY" ] 
	then
	  echo "!!!!! <<<<< STOP on INCORRECT or MISSING INFORMATION >>>>> !!!!!!"
	  echo "Masternode private key missing. Please start script correctly"
	  echo "Usage is: $0 <mn_name> <masternod_gen_key>"
	  exit 1
fi


function create_conf {
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

	if [ ! -f "$HOST_COIN_HOME" ];
	then
		mkdir "$HOST_COIN_HOME"
		mkdir "$TEMP"
	fi
echo "creating conf file"
cat <<EOF > "$CONF_FILE"
rpcuser=$RPC_USER
rpcpassword=$PASSWORD
rpcallowip=0.0.0.0
rpcbind=0.0.0.0
rpcport=$DEFAULT_RPC_PORT
port=$PORT
listen=1
server=1
daemon=0
maxconnections=64
masternode=1
externalip=$WANIP
masternodeprivkey=$MASTERNODE_GEN_KEY
EOF
cat "$CONF_FILE"
cp "$CONF_FILE" "$TEMP"
}

function install_mn {
	check_container_status
	display_result
}

function check_container_status {
	if ! grep -q "$MASTERNODE_GEN_KEY" "$CONF_FILE"
		then
			create_conf
	fi
	if [ ! -f "$CONF_FILE" ]
		then
		    create_conf
	fi

	if [ ! "$(docker ps -q -f name="$MN_NAME")" ]; then
    	if [ "$(docker ps -aq -f status=exited -f name="$MN_NAME")" ]; then
        # cleanup
         clean_up
    	fi
	fi
	run_image
}

#clean up
function clean_up { 
	docker rm "$MN_NAME" ;
	echo "function clean_up"
}

function deploy_mn {
	run_image
}

#start image
function run_image { 
	docker run -d \
	-p "$PORT":"$PORT" -p "$DEFAULT_RPC_PORT":"$DEFAULT_RPC_PORT" \
	-v "$HOST_COIN_HOME":"$COIN_DATADIR" \
	-v "$HOST_COIN_HOME":"$COIN_ADMIN_TEMP" \
	--name "$MN_NAME" "$DOCKER_REPO" /bin/bash
}

#utility - copy conf file from host to container
function copy_conf { 
	#what is the content of the conf file in docker image before container creation?
	docker cp "$COIN_CONF" "$HOST_COIN_HOME/temp/$COIN.conf"
	echo "initial conf file of $MN_NAME is: "
	cat $HOST_COIN_HOME/temp/$COIN.conf

	#deploy the running conf file from host.
	docker cp  "$CONF_FILE" "$COIN_CONF" ;
	echo "copied local conf file $CONF_FILE to masternode: $MN_NAME location $COIN_DATADIR"

	#What is now the content of the conf file after container deployment?
	docker cp "$COIN_CONF" "$HOST_COIN_HOME/temp/$COIN.conf"
	echo "new conf file of $MN_NAME is: "
	cat "$HOST_COIN_HOME/temp/$COIN.conf"
}

#restart the container
function restart_container { 
	docker container restart "$MN_NAME";
	echo "restart_container"
}

function display_result {
	#WANIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
	myipaddresses=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
	result=$(docker ps -q -f name="$MN_NAME")
	echo "result is $result"
	if [ -z "$result" ];then
		echo "Your $COIN Masternode installation for $MN_NAME was NOT successful due to errors"
		echo "Please try again after correcting errors."

    else
		echo "!!!!!! <<<<< CONGRATULATIONS >>>>> !!!!!!"
		echo "Your $COIN Masternode $MN_NAME is now running"
		echo "Now, point your browser to $WANIP:9000 to manage your masternode."
		echo "Below are the ip addresses detected on your vps:"
		echo "$myipaddresses"
	fi

}

install_mn