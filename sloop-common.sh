#!/bin/bash

sloop::init(){
  K8S_VERSION=v1.3.0
  WORKDIR=/var/lib/kubelet
  BINDIR=/usr/local/bin
  KUBE_DEPLOY_DIR=$BASEDIR/kube-deploy
  KUBE_DEPLOY_COMMIT=04431672403202d9f535a43f34f0899bc8fff1a7
  KUBELET_SRV_FILE=/run/systemd/system/kubelet.service
  RELEASE_URL="https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/linux/$ARCH"
}

sloop::clone_kube_deploy(){
  if [ ! -d "$KUBE_DEPLOY_DIR" ]; then
    echo "Cloning kube-deploy!"
    git clone https://github.com/kubernetes/kube-deploy.git $KUBE_DEPLOY_DIR
    cd $KUBE_DEPLOY_DIR; git checkout $KUBE_DEPLOY_COMMIT
  fi
  source $KUBE_DEPLOY_DIR/docker-multinode/common.sh
  kube::log::status "sloop - sourced kube-deploy scripts"
}

sloop::main(){
  kube::multinode::main
  kube::multinode::check_params
  kube::multinode::detect_lsb
  kube::log::status "sloop - ready"
}

sloop::install_binaries(){
  sloop::install_hyperkube
  sloop::install_kubectl
}

sloop::install_hyperkube(){
  if [ ! -f "$BINDIR/hyperkube" ]; then
    kube::log::status "sloop - downloading huperkube for native kubelet"
    wget $RELEASE_URL/hyperkube -O $BINDIR/hyperkube
    chmod a+x $BINDIR/hyperkube
  fi
}

sloop::install_kubectl(){
  if [ ! -f "$BINDIR/kubectl" ]; then
    kube::log::status "sloop - downloading kubectl"
    wget $RELEASE_URL/kubectl -O $BINDIR/kubectl
    chmod a+x $BINDIR/kubectl
  fi
}

sloop::install_master(){
  kube::log::status "sloop - installing master"
  API_IP="localhost"
  sloop::install_kubelet_service
  sloop::copy_manifests
}

sloop::install_worker(){
  "sloop - installing worker master ip=$MASTER_IP"
  API_IP=$MASTER_IP
  sloop::install_kubelet_service
}

sloop::install_kubelet_service(){
  if [ ! -f "$KUBELET_SRV_FILE" ]; then
    kube::log::status "sloop - installing kubelet service"
    cat > $KUBELET_SRV_FILE <<- EOF
[Unit]
Description=Kubernetes Kubelet Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=${WORKDIR}
ExecStart=/bin/sh -c "exec ${BINDIR}/hyperkube kubelet \\
  --allow-privileged \\
  --api-servers=http://${API_IP}:8080 \\
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
  kube::log::status "sloop - enabling kubelet service"
  systemctl enable kubelet
}

sloop::copy_manifests() {
  kube::log::status "sloop - copying manifests from hyperkube image"
  CONTAINER_NAME=hyperkube.$RANDOM

  docker run --name $CONTAINER_NAME \
    gcr.io/google_containers/hyperkube-${ARCH}:${K8S_VERSION}

  docker cp $CONTAINER_NAME:/etc/kubernetes/manifests-multi $WORKDIR/manifests
  docker rm $CONTAINER_NAME
}

sloop::start_kubelet(){
  kube::log::status "sloop - starting kubelet service"
  systemctl restart kubelet
}

sloop::turndown(){
  if [ -f "$KUBELET_SRV_FILE" ]; then
    kube::log::status "sloop - stopping kubelet service"
    systemctl stop kubelet
    kube::log::status "sloop - disabling kubelet service"
    systemctl disable kubelet
    kube::log::status "sloop - removing kubelet service"
    rm -f $KUBELET_SRV_FILE
    kube::log::status "sloop - relaoding systemd daemon"
    systemctl daemon-reload
    kube::log::status "sloop - calling kube-deploy turndown"
    kube::multinode::turndown
  fi
}
