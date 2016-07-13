#!/bin/bash

slup::init(){
  K8S_VERSION=v1.3.0
  ARCH=arm64
  WORKDIR=/var/lib/kubelet
  BINDIR=/usr/local/bin
  KUBE_DEPLOY_DIR=$WORKDIR/kube-deploy
  KUBE_DEPLOY_COMMIT=master
  SYSTEMDDIR=/lib/systemd/system
  KUBELET_SRV_FILE=$SYSTEMDDIR/kubelet.service
  RELEASE_URL="https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/linux/$ARCH"

  mkdir -p $WORKDIR/bin
}

slup::clone_kube_deploy(){
  if [ ! -d "$KUBE_DEPLOY_DIR" ]; then
    echo "Cloning kube-deploy!"
    git clone https://github.com/kubernetes/kube-deploy.git $KUBE_DEPLOY_DIR
    cd $KUBE_DEPLOY_DIR; git checkout $KUBE_DEPLOY_COMMIT
  fi
  source $KUBE_DEPLOY_DIR/docker-multinode/common.sh
}

slup::install_binaries(){
  slup::install_hyperkube
  slup::install_kubectl
}

slup::install_hyperkube(){
  if [ ! -f "$BINDIR/hyperkube" ]; then
    wget $RELEASE_URL/hyperkube -O $WORKDIR/bin/hyperkube
    chmod a+x $WORKDIR/bin/hyperkube
  fi
}

slup::install_kubectl(){
  if [ ! -f "$BINDIR/kubectl" ]; then
    wget $RELEASE_URL/kubectl -O $BINDIR/kubectl
    chmod a+x $BINDIR/kubectl
  fi
}

slup::install_kubelet_service(){
  if [ ! -f "$KUBELET_SRV_FILE" ]; then
    cat > $KUBELET_SRV_FILE <<- EOF
[Unit]
Description=Kubernetes Kubelet Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=${WORKDIR}
ExecStart=/bin/sh -c "exec /var/lib/kubelet/bin/hyperkube kubelet
  --allow-privileged \\
  --pod_infra_container_image=kubernetesonarm/pause \\
  --api-servers=http://${MASTER_IP}:8080 \\
  --cluster-dns=10.0.0.10 \\
  --cluster-domain=cluster.local \\
  --v=2 \\
  --address=0.0.0.0 \\
  --enable-server \\
  --hostname-override=\$(ip -o -4 addr list ${NET_INTERFACE} | awk '{print \$4}' | cut -d/ -f1) \\
  --config=${WORKDIR}/manifests"
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  fi

  systemctl enable kubelet
}

slup::copy_manifests() {
  CONTAINER_NAME=hyperkube.$RANDOM

  docker run --name $CONTAINER_NAME \
    gcr.io/google_containers/hyperkube-${ARCH}:${K8S_VERSION}

  docker cp $CONTAINER_NAME:/etc/kubernetes/manifests-multi $WORKDIR/manifests
  docker rm $CONTAINER_NAME
}

slup::start_k8s_master(){
  systemctl restart kubelet
}
