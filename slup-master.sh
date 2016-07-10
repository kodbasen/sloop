#!/bin/bash

K8S_VERSION=v1.3.0
KUBE_DEPLOY_COMMIT=6b487427136d850f912b25ccf3165ff7bf836a36
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKDIR=$BASEDIR/workdir
KUBE_DEPLOY_DIR=$WORKDIR/kube-deploy
SLUP_KUBELET_MOUNTS="\
  -v /sys:/sys:rw \
  -v /var/run:/var/run:rw \
  -v /var/lib/docker:/var/lib/docker:rw \
  -v /var/lib/kubelet:/var/lib/kubelet:shared \
  -v /var/log/containers:/var/log/containers:rw \
  -v $WORKDIR/etc/kubernetes:/etc/kubernetes:rw"

mkdir -p $WORKDIR

if [ ! -d "$KUBE_DEPLOY_DIR" ]; then
  echo "Cloning kube-deploy!"
  git clone https://github.com/kubernetes/kube-deploy.git $KUBE_DEPLOY_DIR
  cd $KUBE_DEPLOY_DIR; git checkout $KUBE_DEPLOY_COMMIT
fi

cd $BASEDIR

sed -i.bak1 "s;gcr.io/google_containers/etcd;-v \
$WORKDIR/var/etcd/data:/var/etcd/data gcr.io/google_containers/etcd;g" \
$KUBE_DEPLOY_DIR/docker-multinode/common.sh
sed -i.bak2 's/${KUBELET_MOUNTS}/${SLUP_KUBELET_MOUNTS}/g' $KUBE_DEPLOY_DIR/docker-multinode/common.sh

source $KUBE_DEPLOY_DIR/docker-multinode/common.sh

mkdir -p $WORKDIR/etc
docker run --name tempkube gcr.io/google_containers/hyperkube-$ARCH:$K8S_VERSION
docker cp tempkube:/etc/kubernetes $WORKDIR/etc
docker rm tempkube

for i in $WORKDIR/etc/kubernetes/manifests-multi/*; do sed -i -e "s;\"emptyDir\": {};\"hostPath\": { \"path\": \"$WORKDIR/data\" };g" "$i"; done

kube::log::install_errexit

kube::multinode::main

kube::multinode::check_params

kube::multinode::detect_lsb

kube::multinode::turndown

kube::multinode::bootstrap_daemon

kube::multinode::start_etcd

kube::multinode::start_flannel

kube::multinode::restart_docker

kube::multinode::start_k8s_master

kube::log::status "Done. It will take some minutes before apiserver is up though"




#rm -rf /opt/etcd/data/*

#docker run --name tempkube gcr.io/google_containers/hyperkube-$ARCH:$K8S_VERSION
#docker cp tempkube:/etc/kubernetes /etc
#docker rm tempkube

#for i in /etc/kubernetes/manifests-multi/*; do sed -i -e 's/"emptyDir": {}/"hostPath": \{ "path": "\/k8s\/data" }/g' "$i"; done

#exec ./master.sh
