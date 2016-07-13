#!/bin/bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $BASEDIR/slup-common.sh

slup::init

slup::clone_kube_deploy

slup::main

slup::turndown

slup::install_binaries

slup::install_master

kube::multinode::bootstrap_daemon

kube::multinode::start_etcd

kube::multinode::start_flannel

kube::multinode::restart_docker

slup::start_kubelet
