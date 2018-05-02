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
SUPERUSER_EMAIL=${SUPERUSER_EMAIL}
SUPERUSER_PASSWORD=$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)
SUPERUSER_API_TOKEN=$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)
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
HTTP_PORT=80
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
MEDIA_ROOT=/opt/netbox/netbox/media
#BANNER_TOP=
#BANNER_BOTTOM=
#BANNER_LOGIN=
NAPALM_USERNAME=
NAPALM_PASSWORD=
NAPALM_TIMEOUT=10
MAX_PAGE_SIZE=0
#DEBUG=TRUE
#MAINTENANCE_MODE=TRUE

#####################
# LDAP
#####################
AUTH_LDAP_SERVER_URI=ldap://darz.local
AUTH_LDAP_BIND_DN=
AUTH_LDAP_BIND_PASSWORD=
LDAP_IGNORE_CERT_ERRORS=
AUTH_LDAP_USER_SEARCH_BASEDN=
AUTH_LDAP_GROUP_SEARCH_BASEDN=
AUTH_LDAP_REQUIRE_GROUP_DN=
AUTH_LDAP_IS_ADMIN_DN=
AUTH_LDAP_IS_SUPERUSER_DN=
##AUTH_LDAP_FIND_GROUP_PERMS=
AUTH_LDAP_CACHE_GROUPS=
##AUTH_LDAP_ATTR_FIRSTNAME=
##AUTH_LDAP_ATTR_LASTNAME=
##AUTH_LDAP_ATTR_MAIL=

EOF

mkdir -p ./data/netbox/nginx-config

if [[ -f ./data/netbox/nginx-config/nginx.conf ]]; then
  read -r -p "config file nginx.conf exists and will be overwritten, are you sure you want to contine? [y/N] " response
  case $response in
    [yY][eE][sS]|[yY])
      mv ./data/netbox/nginx-config/nginx.conf ./data/netbox/nginx-config/nginx.conf_backup
      ;;
    *)
      exit 1
    ;;
  esac
fi
cp ./data/Dockerfiles/netbox/docker/nginx.conf ./data/netbox/nginx-config/nginx.conf
