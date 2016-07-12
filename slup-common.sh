#!/bin/bash

slup::init(){
  K8S_VERSION=v1.3.0
  ARCH=arm64
  WORKDIR=$BASEDIR/workdir
  BINDIR=$WORKDIR/usr/bin
  KUBE_DEPLOY_DIR=$WORKDIR/kube-deploy
  KUBE_DEPLOY_COMMIT=6b487427136d850f912b25ccf3165ff7bf836a36
  SYSTEMDDIR=$WORKDIR/serviced
  KUBELET_SRV_FILE=$SYSTEMDDIR/kubelet.service
  RELEASE_URL="https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/linux/$ARCH"

  mkdir -p $SYSTEMDDIR
  mkdir -p $BINDIR
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
  slup::install_kubelet
  slup::install_kubectl
}

slup::install_kubelet(){
  if [ ! -f "$BINDIR/kubelet" ]; then
    wget $RELEASE_URL/kubelet -O $BINDIR/kubelet
    chmod a+x $BINDIR/kubelet
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
WorkingDirectory=/var/lib/kubelet
EnvironmentFile=/etc/kubernetes/k8s.conf
ExecStartPre=mkdir -p /etc/kubernetes/manifests
ExecStart=/bin/sh -c "exec /etc/kubernetes/binaries/hyperkube kubelet
  --allow-privileged \\
  --pod_infra_container_image=kubernetesonarm/pause \\
  --api-servers=http://${MASTER_IP}:8080 \\
  --cluster-dns=10.0.0.10 \\
  --cluster-domain=cluster.local \\
  --v=2 \\
  --address=0.0.0.0 \\
  --enable-server \\
  --hostname-override=\$(ip -o -4 addr list ${NET_INTERFACE} | awk '{print \$4}' | cut -d/ -f1) \\
  --config=/etc/kubernetes/manifests"
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  fi

  #systemctl enable kubelet
}

slup::start_k8s_master(){
  systemctl restart kubelet
}
