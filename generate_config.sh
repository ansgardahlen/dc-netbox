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

#IMAGE_BRANCH=$IMAGE_BRANCH
NETBOX_BRANCH=v2.4.7

#AUTH_LDAP_SERVER_URI=ldaps://<FQDN_1> ldaps://<FQDN_2> ldaps://<FQDN_2>
#AUTH_LDAP_BIND_DN=<LDAP_CN_BIND_USER>
#AUTH_LDAP_BIND_PASSWORD=<LDAP_BIND_PASS>
#LDAP_IGNORE_CERT_ERRORS=True
#AUTH_LDAP_USER_SEARCH_BASEDN=<SEARCH_BASE_DN>
#AUTH_LDAP_GROUP_SEARCH_BASEDN=<SEARCH_GROUP_DN>
#AUTH_LDAP_REQUIRE_GROUP_DN=<LDAP_NETBOX_USER_GROUP_CN>
#AUTH_LDAP_IS_ADMIN_DN=<LDAP_NETBOX_ADMIN_GROUP_CN>
#AUTH_LDAP_IS_SUPERUSER_DN=<LDAP_NETBOX_SUPERUSER_GROUP_CN>
#AUTH_LDAP_CACHE_GROUPS=<CACHETIME_3600>
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
#BANNER_TOP=LDAP TEST
#BANNER_BOTTOM=BANNER BOTTOM
#BANNER_LOGIN=LDAP LOGIN TEST
#NAPALM_USERNAME=
#NAPALM_PASSWORD=
#NAPALM_TIMEOUT=10
MAX_PAGE_SIZE=0
DEBUG=TRUE
#MAINTENANCE_MODE=TRUE
#REDIS_PASSWORD=
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

cat << EOF > ./data/netbox/nginx-config/nginx.conf
worker_processes 1;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    tcp_nopush     on;
    keepalive_timeout  65;
    gzip  on;
    server_tokens off;

    server {
        listen 80;

        server_name localhost;

        access_log off;

        location /static/ {
            alias /opt/netbox/netbox/static/;
        }

        location / {
            proxy_pass http://netbox:8001;
            proxy_set_header X-Forwarded-Host \$http_host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-Proto \$scheme;
            add_header P3P 'CP="ALL DSP COR PSAa PSDa OUR NOR ONL UNI COM NAV"';
        }
    }
}
EOF
