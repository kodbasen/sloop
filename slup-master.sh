#!/bin/bash

export ARCH=arm64
export K8S_VERSION=v1.3.0

#rm -rf /opt/etcd/data/*

docker run --name tempkube gcr.io/google_containers/hyperkube-$ARCH:$K8S_VERSION
docker cp tempkube:/etc/kubernetes /etc
docker rm tempkube

for i in /etc/kubernetes/manifests-multi/*; do sed -i -e 's/"emptyDir": {}/"hostPath": \{ "path": "\/k8s\/data" }/g' "$i"; done

exec ./master.sh
