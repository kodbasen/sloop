#!/bin/bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ -z ${MASTER_IP} ]]; then
  MASTER_IP=$(hostname -I | awk '{print $1}')
fi

source $BASEDIR/sloop-common.sh

sloop::init

sloop::clone_kube_deploy

sloop::main

sloop::turndown

sloop::install_binaries

sloop::install_master

kube::multinode::bootstrap_daemon

kube::multinode::start_etcd

kube::multinode::start_flannel

kube::multinode::restart_docker

sloop::start_kubelet

kube::log::status "Sloop - Done starting master node."
