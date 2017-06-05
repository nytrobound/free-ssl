#!/bin/bash
# This script will help you to generate a trusted SSL certificate issued by Let's Encrypt using certbot.

SSLUSER=$USER
LOCAL_HOME=$(pwd)
CONF=$(pwd)/config.sh
LOG=$(pwd)/logs/installssl.log
CYAN='\033[1;36m'
OFF='\033[0m'
mkdir -p logs
echo "++++++++++++++++++++" >> $LOG
echo "Installation start.." >> $LOG
echo

if [ -f "config.sh" ]; then
	echo "A previous installation was detected." | tee -a $LOG
	echo "This script is meant to be executed only once." | tee -a $LOG
	echo "Exiting..." | tee -a $LOG
	exit 0
fi

echo "This script will help you to generate a trusted SSL certificate issued by Let's Encrypt using certbot."
echo
echo -n "Enter your domain name: "
	read DOMAIN_NAME
echo -n "Enter your email: "
        read EMAIL
echo -n "Enter the port you will use for HTTPS: "
        read HTTPS_PORT
echo
echo -e "Before proceeding, please check your ufw configuration. To do this, execute ${CYAN}sudo ufw status${OFF} in a new terminal on your server."
echo "You'll need to have your own ports enable, especially your SSH port and your SHIFT client port."
echo -e "Execute ${CYAN}ifconfig${OFF} in the other terminal and look for the network interface of your server (normally is eth0, eth1, eth2, ens1, ens2, ens3...)."
echo -n "What is your network interface?: "
        read NETWORK_INTERFACE
echo
echo "Your domain name is: $DOMAIN_NAME" >> $LOG
echo "Your email is: $EMAIL" >> $LOG
echo "Your https port is: $HTTPS_PORT" >> $LOG
echo "Your network interface is: $NETWORK_INTERFACE" >> $LOG

echo
echo -n "Enabling port 443/tcp.. " | tee -a $LOG
sudo ufw allow 443/tcp &>> $LOG || { echo "Could not enable port 443. Please read your logs/installssl.log file. Exiting."  | tee -a $LOG && exit 1; }
echo "Done."
echo
echo -n "Backing up firewall.." | tee -a $LOG
sudo cp /etc/ufw/before.rules before.rules.backup
echo "Done." | tee -a $LOG

echo
echo -n "Installing certbot.. " | tee -a $LOG
sudo apt-get install software-properties-common
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update
sudo apt-get install certbot
echo "Done." | tee -a $LOG
export LC_ALL="en_US.UTF-8" >> $LOG
export LC_CTYPE="en_US.UTF-8" >> $LOG

echo
echo -n "Generating new SSL certificate.. this could take some minutes.." | tee -a $LOG
certbot certonly --standalone -d $DOMAIN_NAME --email $EMAIL --agree-tos --non-interactive &>> $LOG || { echo "Could not generate SSL certificate. Please read your logs/installssl.log file. Exiting." | tee -a $LOG && exit 1; }
echo "Done." | tee -a $LOG
sudo chmod 755 /etc/letsencrypt/archive/
sudo chmod 755 /etc/letsencrypt/live/

echo
echo -n "Installing redirection on port 443 to port $HTTPS_PORT.. " | tee -a $LOG
sudo sh -c "echo >> /etc/ufw/before.rules" >> $LOG
sudo sh -c "echo \"# free-ssl -- Auto-Redirect \" >> /etc/ufw/before.rules" >> $LOG
sudo sh -c "echo \"*nat\" >> /etc/ufw/before.rules" >> $LOG
sudo sh -c "echo \":PREROUTING ACCEPT [0:0]\" >> /etc/ufw/before.rules" >> $LOG
sudo sh -c "echo \"-A PREROUTING -i $NETWORK_INTERFACE -p tcp --dport 443 -j REDIRECT --to-port $HTTPS_PORT\" >> /etc/ufw/before.rules" >> $LOG
sudo sh -c "echo \"COMMIT\" >> /etc/ufw/before.rules" >> $LOG
echo "done" | tee -a $LOG

cd $LOCAL_HOME
echo "SSLUSER=\"$SSLUSER\"" > $CONF
echo "DOMAIN=\"$DOMAIN_NAME\"" >> $CONF
echo "EMAIL=\"$EMAIL\"" >> $CONF
echo "HTTPS_PORT=\"$HTTPS_PORT\"" >> $CONF
echo "NETWORK_INTERFACE=\"$NETWORK_INTERFACE\"" >> $CONF

echo
echo "Please do the following"
echo -e "Run: ${CYAN}sudo nano /etc/ufw/before.rules${OFF}"
echo "Go to the bottom of the file and check your last 4 lines, that should look like this:"
echo "    *nat"
echo "    :PREROUTING ACCEPT [0:0]"
echo "    -A PREROUTING -i $NETWORK_INTERFACE -p tcp --dport 443 -j REDIRECT --to-port $HTTPS_PORT"
echo "    COMMIT"
echo
echo "* If everything is correct, confirm with y and the script will reload your firewall."
echo "* If there is something else or wrong, confirm with n and the script will restore a backup."
echo "* Be aware that if the /etc/ufw/before.rules file contains other type of lines at the end of the file, your firewall might not work properly."

	read -p "Do you want to continue (y/n)?: " -n 1 -r
	if [[  $REPLY =~ ^[Yy]$ ]]
	   then
		echo " " | tee -a $LOG
		echo "Installing the renew script.." | tee -a $LOG
		echo "#!/bin/sh" >  start_renew.sh
		echo "cd /home/$SSLUSER/free-ssl/" >> start_renew.sh
		echo "source config.sh" >> start_renew.sh
		echo "bash renewssl.sh \$1" >> start_renew.sh

		echo "Deleting allow 443/tcp rule.." >> $LOG
		sudo ufw delete allow 443/tcp &>> $LOG || { echo "Could not remove allow 443/tcp rule. Please read your logs/installssl.log file. Exiting." | tee -a $LOG && exit 1; }
		echo "Allowing your https port $HTTPS_PORT/tcp.." >> $LOG
		sudo ufw allow $HTTPS_PORT/tcp &>> $LOG || { echo "Could not allow $HTTPS_PORT/tcp rule. Please read your logs/installssl.log file. Exiting." | tee -a $LOG && exit 1; }
		echo "ufw reload.." >> $LOG
		sudo ufw reload &>> $LOG || { echo "Could not reload ufw. Please read your logs/installssl.log file. Exiting." | tee -a $LOG && exit 1; }
	else
		echo -n "Restoring ufw/before.rules.." | tee -a $LOG
		sudo rm /etc/ufw/before.rules >> $LOG
		sudo cp before.rules.backup /etc/ufw/before.rules >> $LOG
		echo "done" | tee -a $LOG
		echo
		echo "You have decided not to continue. Please add the lines described above for /etc/ufw/before.rules and reload your firewall manually." | tee -a $LOG
		exit 0
	fi

echo
echo
echo " Your SSL Certificate has been created successfully, now you need to perform the following manual task: " | tee -a $LOG
echo "########################################################################################################" | tee -a $LOG
echo
echo "Go to your Shift config.json file and edit the ssl section like the following:" | tee -a $LOG
echo "    \"ssl\": {" | tee -a $LOG
echo -e "        \"enabled\": ${CYAN}true${OFF},"
echo "        \"enabled\": true," >> $LOG
echo "        \"options\": {" | tee -a $LOG
echo -e "            \"port\": ${CYAN}$HTTPS_PORT${OFF},"
echo "            \"port\": $HTTPS_PORT," >> $LOG
echo "            \"address\"\: \"0.0.0.0\"," | tee -a $LOG
echo -e "            \"key\": \"${CYAN}/etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem${OFF}\","
echo "            \"key\": \"/etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem\"," >> $LOG
echo -e "            \"cert\": \"${CYAN}/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem${OFF}\""
echo "            \"cert\": \"/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem\"" >> $LOG
echo "        }" | tee -a $LOG
echo "    }," | tee -a $LOG

echo
echo "Please save your config.json file and reload Shift with ./shift_manager.bash reload" 
echo
echo "****************************************************"
echo "* ${CYAN}Installation Successfully Completed${OFF} *" | tee -a $LOG
echo "****************************************************"
echo
echo "You can now visit your address https://$DOMAIN_NAME and confirm the result." | tee -a $LOG
echo " "  | tee -a $LOG
echo "Now you'll need to add a cronjob to renew your certificate regularly." | tee -a $LOG
echo "It is recommended to use https://www.crontab-generator.org/ to help you with your cronjob." | tee -a $LOG
echo "Example: To check and renew your SSL certificate every Wednesday at 12pm you need to run sudo crontab -e and add at the end:" | tee -a $LOG
echo "* 12 * * WED bash /home/$SSLUSER/free-ssl/start_renew.sh >> /home/$SSLUSER/free-ssl/logs/cron.log" | tee -a $LOG
echo " " | tee -a $LOG

