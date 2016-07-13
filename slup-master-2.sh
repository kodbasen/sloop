#!/bin/bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $BASEDIR/slup-common.sh

slup::init

slup::clone_kube_deploy

kube::multinode::turndown

slup::main

kube::multinode::check_params

slup::install_binaries

slup::install_kubelet_service

slup::copy_manifests

kube::multinode::bootstrap_daemon

kube::multinode::start_etcd

kube::multinode::start_flannel

kube::multinode::restart_docker

slup::start_k8s_master
