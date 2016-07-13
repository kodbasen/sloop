#!/bin/bash

slup::init(){
  K8S_VERSION=v1.3.0
  ARCH=arm64
  WORKDIR=/var/lib/kubelet
  BINDIR=/usr/local/bin
  KUBE_DEPLOY_DIR=$BASEDIR/kube-deploy
  KUBE_DEPLOY_COMMIT=master
  SYSTEMDDIR=/lib/systemd/system
  KUBELET_SRV_FILE=$SYSTEMDDIR/kubelet.service
  RELEASE_URL="https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/linux/$ARCH"
}

slup::clone_kube_deploy(){
  if [ ! -d "$KUBE_DEPLOY_DIR" ]; then
    echo "Cloning kube-deploy!"
    git clone https://github.com/kubernetes/kube-deploy.git $KUBE_DEPLOY_DIR
    cd $KUBE_DEPLOY_DIR; git checkout $KUBE_DEPLOY_COMMIT
  fi
  source $KUBE_DEPLOY_DIR/docker-multinode/common.sh
  kube::log::status "Slup - sourced kube-deploy scripts"
}

slup::main(){
  kube::log::status "Slup - ready to start deploy kube using Slup!"
  kube::multinode::main
  kube::multinode::check_params
  kube::multinode::detect_lsb
  kube::log::status "Slup - calling kube-deploy turndown"
  kube::multinode::turndown
  mkdir -p $WORKDIR/bin
}

slup::install_binaries(){
  slup::install_hyperkube
  slup::install_kubectl
}

slup::install_hyperkube(){
  if [ ! -f "$WORKDIR/bin/hyperkube" ]; then
    kube::log::status "Slup - downloading huperkube for native kubelet"
    wget $RELEASE_URL/hyperkube -O $WORKDIR/bin/hyperkube
    chmod a+x $WORKDIR/bin/hyperkube
  fi
}

slup::install_kubectl(){
  if [ ! -f "$BINDIR/kubectl" ]; then
    kube::log::status "Slup - downloading kubectl"
    wget $RELEASE_URL/kubectl -O $BINDIR/kubectl
    chmod a+x $BINDIR/kubectl
  fi
}

slup::install_kubelet_service(){
  if [ ! -f "$KUBELET_SRV_FILE" ]; then
    kube::log::status "Slup - installing kubelet service"
    cat > $KUBELET_SRV_FILE <<- EOF
[Unit]
Description=Kubernetes Kubelet Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=${WORKDIR}
ExecStart=/bin/sh -c "exec ${WORKDIR}/bin/hyperkube kubelet \\
  --allow-privileged \\
  --api-servers=http://${MASTER_IP}:8080 \\
  --cluster-dns=10.0.0.10 \\
  --cluster-domain=cluster.local \\
  --v=2 \\
  --hostname-override=\$(ip -o -4 addr list ${NET_INTERFACE} | awk '{print \$4}' | cut -d/ -f1) \\
  --config=${WORKDIR}/manifests"
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  fi
  kube::log::status "Slup - enabling kubelet service"
  systemctl enable kubelet
}

slup::copy_manifests() {
  kube::log::status "Slup - copying manifests from hyperkube image"
  CONTAINER_NAME=hyperkube.$RANDOM

  docker run --name $CONTAINER_NAME \
    gcr.io/google_containers/hyperkube-${ARCH}:${K8S_VERSION}

  docker cp $CONTAINER_NAME:/etc/kubernetes/manifests-multi $WORKDIR/manifests
  docker rm $CONTAINER_NAME
}

slup::start_k8s_master(){
  kube::log::status "Slup - starting kubelet service"
  systemctl restart kubelet
}
