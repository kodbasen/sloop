#!/bin/bash

WEAVE_IMG_ARM="weaveworks/weaveexec:latest"
WEAVE_IMG_AMD64="kodbasen/weaveexec:latest"

sloop::net::start_weave(){
  if [ -z ${WEAVE_NODES+x} ]; then
    sloop::log::fatal "WEAVE_NODES is unset";
  else
    sloop::log::info "WEAVE_NODES is set to '$WEAVE_NODES'";
  fi
  sloop::log::info "Starting weave network ..."
  sloop::net::install_weave
  sloop::net::start_weave
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
}
