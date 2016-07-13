#!/bin/bash
#!/bin/bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $BASEDIR/slup-common.sh

slup::init

slup::clone_kube_deploy

slup::main

slup::turndown

slup::install_hyperkube

slup::install_worker

kube::multinode::bootstrap_daemon

kube::multinode::start_flannel

kube::multinode::restart_docker

slup::start_kubelet
