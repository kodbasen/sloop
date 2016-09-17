#!/bin/bash

WEAVE_IMG_ARM="weaveworks/weaveexec:latest"
WEAVE_IMG_AMD64="kodbasen/weaveexec:latest"

sloop::net::start_weave(){

  # Weave nodes
  if [ -z ${WEAVE_NODES+x} ]; then
    sloop::log::fatal "WEAVE_NODES is unset";
  else
    sloop::log::info "WEAVE_NODES is set to '$WEAVE_NODES'";
  fi

  # Weave password for encryption
  if [ -f "${WEAVE_PWD_FILE}" ]; then
    sloop::log::info "WEAVE_PWD_FILE is set to '$WEAVE_PWD_FILE'";
    WEAVE_PASSWORD=$(cat ${WEAVE_PWD_FILE})
  else
    sloop::log::info "WEAVE_PWD_FILE is not set";
  fi

  sloop::net::install_weave

  if [ sloop::check_container_running "weave" 2>/dev/null ]; then
    sloop::log::info "Weave is allready running"
    return 0
  fi

  sloop::log::info "Starting weave network ..."
  if [ -z ${WEAVE_GW+x} ]; then
    sloop::log::info "WEAVE_GW is unset";
    weave launch $WEAVE_NODES
    weave expose
  else
    sloop::log::info "WEAVE_GW is set to '$WEAVE_GW'";
    route add $WEAVE_GW gw $(ip route show | grep default | awk '{ print $3}') 2> /dev/null
    ip route del 0/0
    weave launch $WEAVE_NODES
    weave expose
    route add default gw 10.32.0.1 weave
  fi
}

sloop::net::install_weave(){
  if [ -f "/usr/local/bin/weave" ]; then
    sloop::log::info "Weave installed"
    return 0
  fi

  if [ $ARCH == "amd64" ]; then
    WEAVE_IMG=$WEAVE_IMG_AMD64
  else
    WEAVE_IMG=$WEAVE_IMG_ARM
  fi

  CONTAINER_NAME=weaveexec.$RANDOM
  docker run --name=$CONTAINER_NAME weaveworks/weaveexec:1.6.1 > /dev/null 2>&1
  docker cp $CONTAINER_NAME:/home/weave/weave /usr/local/bin
  docker rm $CONTAINER_NAME

  sloop::log::info "Installing weave"
  curl -L git.io/weave -o /usr/local/bin/weave
  chmod a+x /usr/local/bin/weave
  return 0
}
