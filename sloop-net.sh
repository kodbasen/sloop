#!/bin/bash

sloop::net::start_network(){
  sloop::log::info "Starting network ..."
  if [ "$USE_CNI" = "true" ] && [ "$CNI_PROVIDER" = "weave" ]; then
    sloop::net::start_weave
  else
    sloop::log::info "Starting network using kube-deploy"
    echo "start flannel"
    echo "restart docker"
  fi

  if [ "$USE_CNI" = "true" ]; then
    sloop::log::info "Adding CNI to kubelet service config"
    KUBELET_CNI_ARGS="--network-plugin=cni --network-plugin-dir=/etc/cni/net.d"
  fi
}
