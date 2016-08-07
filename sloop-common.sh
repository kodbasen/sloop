#!/bin/bash

sloop::init(){
  WORKDIR=/var/lib/kubelet
  BINDIR=/usr/local/bin
  KUBE_DEPLOY_DIR=$BASEDIR/kube-deploy
  KUBE_DEPLOY_COMMIT=969086b076e8f6feb6e9d8c351e620d46bb0b65e
  #KUBE_DEPLOY_COMMIT=master
  KUBELET_SRV_FILE=/run/systemd/system/kubelet.service
}

sloop::kube_deploy(){
  if [ ! -d "$KUBE_DEPLOY_DIR" ]; then
    sloop::clone_kube_deploy
  else
    echo "Sloop - Checking kube-deploy version"
    echo "$(git -C ${KUBE_DEPLOY_DIR} rev-parse HEAD)"
    if [ $KUBE_DEPLOY_COMMIT != "$(git -C ${KUBE_DEPLOY_DIR} rev-parse HEAD)" ]; then
      cd $KUBE_DEPLOY_DIR; git pull; git checkout $KUBE_DEPLOY_COMMIT
    fi
  fi
  source $KUBE_DEPLOY_DIR/docker-multinode/common.sh
  kube::log::status "Sloop - Sourced kube-deploy scripts"
}

sloop::clone_kube_deploy(){
  echo "Sloop - Cloning kube-deploy!"
  git clone https://github.com/kubernetes/kube-deploy.git $KUBE_DEPLOY_DIR
  cd $KUBE_DEPLOY_DIR; git checkout $KUBE_DEPLOY_COMMIT
}

sloop::main(){
  sloop::kube_deploy
  kube::multinode::main
  kube::multinode::log_variables
  kube::multinode::turndown
  kube::log::status "Sloop - Ready"
  sloop::check_version
}

sloop::check_version(){
  if [ ! -f "$WORKDIR/version" ]; then
    kube::log::status "Sloop - Writing kubernetes version"
    mkdir -p $WORKDIR
    echo "$K8S_VERSION" > "$WORKDIR/k8s-version"
  fi

  INSTALLED_K8S_VERSION=$(<${WORKDIR}/k8s-version)

  if [ $INSTALLED_K8S_VERSION != $K8S_VERSION ]; then
    kube::log::status "Sloop - Upgrading Kubernetes to version $K8S_VERSION"
    echo "$K8S_VERSION" > "$WORKDIR/k8s-version"
    rm -f $BINDIR/kubectl $BINDIR/hyperkube
  fi

  kube::log::status "Sloop - Kubernetes $K8S_VERSION"
}

sloop::install_binaries(){
  mkdir -p $BINDIR
  RELEASE_URL="https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/linux/$ARCH"
  sloop::install_hyperkube
  sloop::install_kubectl
}

sloop::install_hyperkube(){
  if [ ! -f "$BINDIR/hyperkube" ]; then
    kube::log::status "Sloop - Downloading hyperkube for native kubelet"
    wget $RELEASE_URL/hyperkube -O $BINDIR/hyperkube
    chmod a+x $BINDIR/hyperkube
  fi
}

sloop::install_kubectl(){
  if [ ! -f "$BINDIR/kubectl" ]; then
    kube::log::status "Sloop - Downloading kubectl"
    wget $RELEASE_URL/kubectl -O $BINDIR/kubectl
    chmod a+x $BINDIR/kubectl
  fi
}

sloop::install_master(){
  kube::log::status "Sloop - Installing master"
  API_IP="localhost"
  sloop::install_kubelet_service
  sloop::copy_manifests
}

sloop::install_worker(){
  kube::log::status "Sloop - Installing worker master ip=$MASTER_IP"
  API_IP=$MASTER_IP
  sloop::install_kubelet_service
}

sloop::install_kubelet_service(){
  if [ ! -f "$KUBELET_SRV_FILE" ]; then
    kube::log::status "Sloop - Installing kubelet service"
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
  kube::log::status "Sloop - Enabling kubelet service"
  systemctl enable kubelet
}

sloop::copy_manifests() {
  kube::log::status "Sloop - Copying manifests from hyperkube image"
  CONTAINER_NAME=hyperkube.$RANDOM

  mkdir -p $WORKDIR

  docker run --name $CONTAINER_NAME \
    gcr.io/google_containers/hyperkube-${ARCH}:${K8S_VERSION}

  docker cp $CONTAINER_NAME:/etc/kubernetes/manifests-multi $WORKDIR/manifests
  docker rm $CONTAINER_NAME
}

sloop::start_kubelet(){
  kube::log::status "Sloop - Starting kubelet service"
  mkdir -p ${WORKDIR}/manifests
  systemctl restart kubelet
}

sloop::turndown(){
  if [ -f "$KUBELET_SRV_FILE" ]; then
    kube::log::status "Sloop - Stopping kubelet service"
    systemctl stop kubelet
    kube::log::status "Sloop - Disabling kubelet service"
    systemctl disable kubelet
    kube::log::status "Sloop - Removing kubelet service"
    rm -f $KUBELET_SRV_FILE
    kube::log::status "Sloop - Relaoding systemd daemon"
    systemctl daemon-reload
    kube::log::status "Sloop - Calling kube-deploy turndown"
    kube::multinode::turndown
  fi
}
