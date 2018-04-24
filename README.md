# free-ssl
This script will help you to generate a trusted SSL certificate issued by [Let's Encrypt](letsencrypt.org) using [certbot](https://github.com/certbot/certbot) for your Shift node.<br>

## Prerequisites
In order to complete this script, you will need:
* Have a working [Shift](https://shiftproject.com) instance
* Your own domain. Your domain will look something like this --> `subdomain.domain.tk`
* An [A Record](https://my.freenom.com/knowledgebase.php?action=displayarticle&id=4) that points your domain to the public IP address of your server
* To know your network interface
	* Run `ifconfig` and write it down (normally it is eth0, eth1, eth2, ens1, ens2, ens3...) <br>

## Install Let's Encrypt certificate
First of all you'll need to clone this repository:
```
cd ~
git clone https://github.com/terrabellus/free-ssl.git
cd free-ssl
```
To generate and install the trusted SSL certificate, run: `bash installssl.sh`<br>
The script will guide you through the installation process.<br>

## Renew Let's Encrypt certificate
`renewssl.sh` checks the expiry date of your certificate and renews it if the expiration date is less than 30 days. However, you will need to add a cronjob with `crontab -e` to automatically execute the script.<br>

Make sure to replace **$SSLUSER** with the username you ran the script on!<br><br>

**Example:*** 12 * * WED bash /home/**$SSLUSER**/free-ssl/start_renew.sh >> /home/**$SSLUSER**/free-ssl/logs/cron.log<br>
This cronjob checks and renews your SSL certificate every Wednesday at 12pm.<br><br>

You can also use [Crontab Generator](https://crontab-generator.org/) to generate a custom cronjob.<br>

## Links
Documentation: https://certbot.eff.org/docs <br>
Software project: https://github.com/certbot/certbot <br>
Notes for developers: https://certbot.eff.org/docs/contributing.html <br>
Main Website: https://certbot.eff.org <br>
Let's Encrypt Website: https://letsencrypt.org <br>
Community: https://community.letsencrypt.org <br>
ACME spec: http://ietf-wg-acme.github.io/acme/ <br>
ACME working area in github: https://github.com/ietf-wg-acme/acme <br><br>

Original script: https://github.com/mrgrshift/free-ssl.git <br>
