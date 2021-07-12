echo "${_group}Configuring cert file(s) ..."

##
## Check or generate Caddyfile
##
check_or_generate_caddyfile () {
  if [ -f "$CADDY_FILE" ]; then
    echo "${CADDY_FILE} file already exists, skipped."
  else
    echo "Creating $CADDY_FILE file"
    mkdir -p $ROOTFS_ETC_PATH
    cp -n "$CADDY_TEMPLATE_FILE" "$CADDY_FILE"
  fi
}

##
## Check or configure Let's Encrypt SSL
##
check_or_configure_letsencrypt_ssl () {
  echo "${_group}Configuring Let's Encrypt SSL/TLS ..."
  echo "What is you email for let's encrypt?"
  printf "ZEALOT_CERT_EMAIL="
  read email

  if [ -z "$email" ]; then
    echo "Read ZEALOT_CERT_EMAIL failed, Quitting"
    exit
  else
    sed -i -e 's/^.*ZEALOT_CERT_EMAIL=.*$/ZEALOT_CERT_EMAIL='"$email"'/' $ENV_FILE
    clean_sed_temp_file $ENV_FILE
    echo "Let's Encrypt email written to .env"

    check_or_generate_caddyfile
    sed -i -e 's/^.*tls .*$/  tls {$ZEALOT_CERT_EMAIL}/' $CADDY_FILE
    clean_sed_temp_file $CADDY_FILE
    echo "Let's Encrypt email written to $CADDY_FILE"
  fi

  ZEALOT_USE_SSL="letsencrypt"
}

##
## Check or Generate self signed SSL
##
check_or_generate_selfsigned_ssl () {
  echo "${_group}Configuring self signed SSL/TLS cert ..."

  DOMAIN_NAME=$(grep 'ZEALOT_DOMAIN' $ENV_FILE | awk '{split($0,a,"="); print a[2]}')
  echo "Generating self-signed cert for ${DOMAIN_NAME}"

  CERT_NAME="${DOMAIN_NAME}.pem"
  KEY_NAME="${DOMAIN_NAME}-key.pem"
  CERT_FILE="${CERTS_PATH}/${CERT_NAME}"
  KEY_FILE="${CERTS_PATH}/${KEY_NAME}"

  mkdir -p "$(pwd)/$CERTS_PATH"
  docker run --rm --name zealot-mkcert -v $(pwd)/$CERTS_PATH:/root/.local/share/mkcert \
    icyleafcn/mkcert /bin/ash -c "mkcert -install && mkcert ${DOMAIN_NAME}" &> /dev/null

  while true; do
    if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ];then
      sed -i -e 's/^.*ZEALOT_CERT=.*$/ZEALOT_CERT='"$CERT_NAME"'/' $ENV_FILE
      sed -i -e 's/^.*ZEALOT_CERT_KEY=.*$/ZEALOT_CERT_KEY='"$KEY_NAME"'/' $ENV_FILE
      clean_sed_temp_file $ENV_FILE
      echo "Generated cert and key to $CERTS_PATH"

      check_or_generate_caddyfile
      local CADDY_CERTS_PATH=$(echo $DOCKER_CADDY_CERT_PATH | sed 's/\//\\\//g')
      sed -i -e 's/^  tls .*$/  tls '"$CADDY_CERTS_PATH"'\/{$ZEALOT_CERT} '"$CADDY_CERTS_PATH"'\/{$ZEALOT_CERT_KEY}/' $CADDY_FILE
      clean_sed_temp_file $CADDY_FILE
      echo "Self-signed cert and key written to $CADDY_FILE"

      break
    fi
    sleep 1
  done

  ZEALOT_USE_SSL="selfsigned"
}

##
## Enable rails serve static files
##
enable_rails_serve_static_files () {
  echo "${_group}Enable Rails serve static files ..."

  SSL_NAME=false
  sed -i -e 's/^# RAILS_SERVE_STATIC_FILES=.*$/RAILS_SERVE_STATIC_FILES=true/' $ENV_FILE
  clean_sed_temp_file $ENV_FILE
  echo "Written RAILS_SERVE_STATIC_FILES=true written to .env"
}

##
## Start deploy flow
##
choose_deploy () {
  printf "How do you deploy?\n\
  Use [L]et's Encryt SSL (default)\n\
  Use [S]elf-signed SSL\n\
  Do [n]ot use SSL? \n"
  read -n 1 action
  echo ""

  local SSL_NAME=letsencrypt
  case "$action" in
    L | l )
      check_or_configure_letsencrypt_ssl;;
    S | s )
      check_or_generate_selfsigned_ssl;;
    N | n )
      enable_rails_serve_static_files;;
    * )
      ;;
  esac

  if [ -z "$action" ]; then
    check_or_configure_letsencrypt_ssl
  fi

  echo "${_endgroup}"
}

if [ -f "$DOCKER_COMPOSE_FILE" ]; then
  if [ -n "cat $DOCKER_COMPOSE_FILE | grep '# USE SSL:'" ]; then
    HAS_DOCKERDOCKER_COMPOSE_FILE="true"
    echo "Cert already configured, skipped"
  else
    echo "Detected docker-compose file AND its not writon by zealot, at your own risk!!!"
  fi
fi

if [ "$HAS_DOCKERDOCKER_COMPOSE_FILE" == "false" ]; then
  choose_deploy
else
  echo "${_endgroup}"
fi
