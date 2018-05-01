#!/bin/bash

if [[ -f netbox.conf ]]; then
  read -r -p "config file netbox.conf exists and will be overwritten, are you sure you want to contine? [y/N] " response
  case $response in
    [yY][eE][sS]|[yY])
      mv netbox.conf netbox.conf_backup
      ;;
    *)
      exit 1
    ;;
  esac
fi

if [ -z "$PUBLIC_FQDN" ]; then
  read -p "Hostname (FQDN): " -ei "netbox.example.org" PUBLIC_FQDN
fi

if [ -z "$ADMIN_MAIL" ]; then
  read -p "Netbox admin Mail address: " -ei "mail@example.com" ADMIN_MAIL
fi

[[ -f /etc/timezone ]] && TZ=$(cat /etc/timezone)
if [ -z "$TZ" ]; then
  read -p "Timezone: " -ei "Europe/Berlin" TZ
fi

cat << EOF > netbox.conf
# ------------------------------
# netbox web ui configuration
# ------------------------------
# example.org is _not_ a valid hostname, use a fqdn here.
PUBLIC_FQDN=${PUBLIC_FQDN}

# ------------------------------
# NETBOX admin user
# ------------------------------
SUPERUSER_NAME=netboxadmin
SUPERUSER_EMAIL=${ADMIN_MAIL}
SUPERUSER_PASSWORD=$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)
NETBOX_USERNAME=netboxguest
NETBOX_PASSWORD=$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)

# ------------------------------
# SQL database configuration
# ------------------------------
DB_NAME=netbox
DB_USER=netbox

# Please use long, random alphanumeric strings (A-Za-z0-9)
DB_HOST=postgres
DB_PASSWORD=$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)
DBROOT=$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)

# ------------------------------
# Bindings
# ------------------------------

# You should use HTTPS, but in case of SSL offloaded reverse proxies:
HTTP_PORT=8080
HTTP_BIND=0.0.0.0

# Your timezone
TZ=${TZ}

# Fixed project name
#COMPOSE_PROJECT_NAME=netbox

BRANCH-master=master
ALLOWED_HOSTS=*
SECRET_KEY=$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)
EMAIL_SERVER=localhost
EMAIL_PORT=25
EMAIL_USERNAME=foo
EMAIL_PASSWORD=bar
EMAIL_TIMEOUT=10
EMAIL_FROM=netbox@bar.com
LOGIN_REQUIRED=True
EOF


