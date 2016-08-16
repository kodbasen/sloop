#!/bin/bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $BASEDIR/sloop-common.sh

sloop::init

sloop::main

sloop::check_running

sloop::install_binaries

sloop::install_worker

kube::bootstrap::bootstrap_daemon

kube::multinode::start_flannel

kube::bootstrap::restart_docker

sloop::start_kubelet

kube::multinode::start_k8s_worker_proxy

kube::log::status "Sloop - Done starting worker node."
