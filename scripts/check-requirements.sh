MIN_DOCKER_VERSION='19.03.6'
MIN_COMPOSE_VERSION='1.24.1'

CURRENT_OS=$(current_os)
DOCKER_VERSION=$(docker version --format '{{.Server.Version}}')
COMPOSE_VERSION=$($dc --version | sed 's/docker-compose version \(.\{1,\}\),.*/\1/')

# Compare dot-separated strings - function below is inspired by https://stackoverflow.com/a/37939589/808368
function ver () { echo "$@" | awk -F. '{ printf("%d%03d%03d", $1,$2,$3); }'; }

##
## Check and install docker
##
check_and_install_docker () {
  docker_path=`which docker.io || which docker 2> /dev/null`
  if [ -z $docker_path ]; then
    if [ "$CURRENT_OS" == "Darwin" ]; then
      echo "Docker not installed. Click https://docs.docker.com/docker-for-mac/install/ manually, "
      echo "after then hit enter to continue or Ctrl+C to exit"
      read
    else
      read -p "Docker not installed. Enter to install from https://get.docker.com/ or Ctrl+C to exit"
      curl https://get.docker.com/ | sh
    fi
  fi

  docker_path=`which docker.io || which docker 2> /dev/null`
  if [ -z $docker_path ]; then
    echo "Docker install failed. Quitting."
    exit
  fi
}

##
## Check and install docker-compose
##
check_and_install_docker_compose () {
  docker_compose_path=`which docker-compose`
  if [ -z $docker_compose_path ]; then
    read -p "Docker Compose not installed. Enter to install from https://docs.docker.com/compose/install/ or Ctrl+C to exit"
    curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    export PATH="/usr/local/bin/docker-compose:$PATH"
  fi

  docker_compose_path=`which docker-compose`
  if [ -z $docker_compose_path ]; then
    echo "Docker Compose install failed. Quitting."
    exit
  fi
}

echo "${_group}Checking requirements ..."

check_and_install_docker
check_and_install_docker_compose

if [[ "$(ver $DOCKER_VERSION)" -lt "$(ver $MIN_DOCKER_VERSION)" ]]; then
  echo "FAIL: Expected minimum Docker version to be $MIN_DOCKER_VERSION but found $DOCKER_VERSION"
  exit 1
fi

if [[ "$(ver $COMPOSE_VERSION)" -lt "$(ver $MIN_COMPOSE_VERSION)" ]]; then
  echo "FAIL: Expected minimum docker-compose version to be $MIN_COMPOSE_VERSION but found $COMPOSE_VERSION"
  exit 1
fi

echo "Current OS: `uname -sm`"
echo "Docker version: ${DOCKER_VERSION}"
echo "Docker Compose version: ${COMPOSE_VERSION}"

echo "${_endgroup}"
