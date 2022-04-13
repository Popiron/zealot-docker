##
## Create docker volumes for zealot
##
create_docker_volumes () {
  # always remove zealot-app volume to make sure use old zealot data
  local HAS_APP_VOLUME=$($d volume ls | grep -v DRIVER | grep zealot-app | wc -l 2> /dev/null)
  if [ -z "$HAS_APP_VOLUME" ]; then
    $d volume rm zealot-app
  fi

  dv="$d volume create --name"
  if [ "$d" != "docker" ]; then
    dv="$d volume create"
  fi

  echo "Created $($dv zealot-uploads)."
  echo "Created $($dv zealot-backup)."
  echo "Created $($dv zealot-postgres)."
  echo "Created $($dv zealot-redis)."

  cat $TEMPLATE_DOCKER_COMPOSE_PATH/external-volumes.yml >> $DOCKER_COMPOSE_FILE
  echo "Exteral volumes write to file: $DOCKER_COMPOSE_FILE"
}

configure_local_docker_volumes() {
  echo "Which path do you want to storage?"
  printf "ZEALOT_STORED_PATH="
  read stored

  if [ -z "$stored" ]; then
    echo "Read ZEALOT_STORED_PATH failed, Quitting"
    exit
  else
    mkdir -p "$stored/zealot/uploads"
    mkdir -p "$stored/zealot/backup"
    mkdir -p "$stored/redis"
    mkdir -p "$stored/postgres"

    local LOCAL_VOLUMES_FILE="$TEMPLATE_DOCKER_COMPOSE_PATH/local-volumes.yml"
    local TEMP_VOLUMES_FILE="/tmp/local-volumes.yml"
    cp $LOCAL_VOLUMES_FILE $TEMP_VOLUMES_FILE

    escaped_zealot_path=$(echo $stored | sed 's/\//\\\//g')
    sed -i -e 's/\/tmp/'"$escaped_zealot_path"'/g' $TEMP_VOLUMES_FILE
    clean_sed_temp_file $TEMP_VOLUMES_FILE

    cat $TEMP_VOLUMES_FILE >> $DOCKER_COMPOSE_FILE
    rm $TEMP_VOLUMES_FILE

    echo "Local volumes '$stored' write to file: $DOCKER_COMPOSE_FILE"
  fi
}

choose_volumes () {
  printf "Which way do you choose to storage zealot data?\n\
  Use Docker/Nerdctl [V]olumes (default)\n\
  Use [L]ocal file system\n"
  read -n 1 action
  echo ""

  local STORAGE=volumes
  case "$action" in
    V|v)
      create_docker_volumes;;
    L|l)
      configure_local_docker_volumes;;
    * )
      ;;
  esac

  if [ -z "$action" ]; then
    create_docker_volumes
  fi
}

##################
# Main
##################
echo "${_group}Configuring Docker volumes ..."

VOLUMES_EXISTS=$(grep -cE "^(\s+)zealot\-(\w+):" $DOCKER_COMPOSE_FILE || echo 0)
if [ "$VOLUMES_EXISTS" -eq 4 ]; then
  echo "Volumes already exists, skipped"
else
  choose_volumes
fi

echo "${_endgroup}"
