#!/bin/bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

MASTER_IP=localhost

source $BASEDIR/sloop-common.sh

sloop::init

sloop::main

sloop::turndown

sloop::install_binaries

sloop::install_master

kube::bootstrap::bootstrap_daemon

kube::multinode::start_etcd

kube::multinode::start_flannel

kube::bootstrap::restart_docker

sloop::start_kubelet

kube::log::status "Sloop - Done starting master node."
