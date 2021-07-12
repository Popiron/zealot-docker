echo "${_group}Configuring Docker volumes ..."

##
## Create docker volumes for zealot
##
create_docker_volumes () {
  echo "${_group}Creating volumes for persistent storage ..."

  echo "Created $(docker volume create --name=zealot-data)."
  echo "Created $(docker volume create --name=zealot-postgres)."
  echo "Created $(docker volume create --name=zealot-redis)."

  cat $TEMPLATE_DOCKER_COMPOSE_PATH/external-volumes.yml >> $DOCKER_COMPOSE_FILE
}

configure_local_docker_volumes() {
  echo "${_group}Configuring docker local volumes ..."
  echo "Which path do you want to storage?"
  printf "ZEALOT_PATH="
  read zealot_path

  if [ -z "$zealot_path" ]; then
    echo "Read PATH failed, Quitting"
    exit 1
  else
    mkdir -p "$zealot_path/redis"
    mkdir -p "$zealot_path/zealot"
    mkdir -p "$zealot_path/postgres"

    echo "You path is: $zealot_path"
    LOCAL_VOLUMES_FILE="$TEMPLATE_DOCKER_COMPOSE_PATH/local-volumes.yml"
    escaped_zealot_path=$(echo $zealot_path | sed 's/\//\\\//g')
    sed -i -e 's/\/tmp\/zealot/'"$escaped_zealot_path"'/g' $LOCAL_VOLUMES_FILE
    clean_sed_temp_file $LOCAL_VOLUMES_FILE

    echo "Local docker volumes configured to $zealot_path"
    cat $TEMPLATE_DOCKER_COMPOSE_PATH/local-volumes.yml >> $DOCKER_COMPOSE_FILE
  fi
}

choose_volumes () {
  printf "Which way do you choose to storage zealot data?\n\
  Use Docker [V]olumes (default)\n\
  Use [L]ocal file system\n"
  read -n 1 action
  echo ""

  local STORAGE=volumes
  case "$action" in
    V | v )
      create_docker_volumes;;
    L | l )
      configure_local_docker_volumes;;
    * )
      ;;
  esac

  if [ -z "$action" ]; then
    create_docker_volumes
  fi

  echo "Written to docker-compose.yml"
}

VOLUMES_EXISTS=$(cat $DOCKER_COMPOSE_FILE | grep -E "^(\s+)zealot\-(\w+):" | wc -l | awk '{print $1}')

if [ "${VOLUMES_EXISTS}" = 3 ]; then
  echo "Volumes already exists, skipped"
else
  choose_volumes
fi

echo "${_endgroup}"
