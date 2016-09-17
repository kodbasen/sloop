#!/bin/bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

MASTER_IP=localhost

source $BASEDIR/sloop-common.sh
source $BASEDIR/sloop-net.sh

sloop::init

sloop::main

sloop::check_running

sloop::install_binaries

sloop::install_master

kube::bootstrap::bootstrap_daemon

kube::multinode::start_etcd

sloop::net::start_network
#kube::multinode::start_flannel

#kube::bootstrap::restart_docker

sloop::start_kubelet

kube::log::status "Sloop - Done starting master node."
