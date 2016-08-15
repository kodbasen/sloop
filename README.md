# Sloop
![sloop](https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Slup.png/250px-Slup.png "Sloop")

Sloop lets you run a Kubernetes cluster using a hybrid solution between native and Docker. Sloop uses kube-deploy and [docker-multinode](https://github.com/kubernetes/kube-deploy/tree/master/docker-multinode) except for the `kubelet` component that is run directly in your os. All you need to get started using Sloop is `bash`, `git`, `curl` and `docker`.

The reason for running your `kubelet`:s native is the full support of [Persistent Volumes](http://kubernetes.io/docs/user-guide/persistent-volumes/).

Sloop uses the best of two world. Docker for bootstrapping your cluster and native `kubelet` for full Kubernetes functionality.

Sloop is currently using the latest stable Kubernetes version (`v1.3.4`).

## Starting your master

On your master node:
```
$ git clone https://github.com/kodbasen/sloop.git
$ cd sloop
$ ./sloop-master.sh
$ # To watch your master start:
$ watch kubectl --all-namespaces=true get pods -o wide
$ # To watch your workers becoming available:
$ watch kubectl get nodes
```

## Starting your workers

On your worker nodes:
```
$ git clone https://github.com/kodbasen/sloop.git
$ cd sloop
$ export MASTER_IP=<sloop-master IP>
$ ./sloop-worker.sh
```

## Using `sloop.conf`

Sloop will use the latest stable version whenever you start a master or worker. You can use a `sloop.conf` file (or setting environment variables) overriding this behavior. You can set the following variables:

```
K8S_VERSION=v1.3.5
ETCD_VERSION=2.2.5
FLANNEL_VERSION=0.5.5
FLANNEL_IPMASQ=true
FLANNEL_NETWORK=10.1.0.0/16
FLANNEL_BACKEND=udp
RESTART_POLICY=unless-stopped
MASTER_IP=localhost
NET_INTERFACE=enp0s3
IP_ADDRESS=xxx.xxx.xxx.xxx
USE_CNI=false
```

## Upgrading Kubernetes

To upgrade your cluster you only have to re-run the start script and Sloop will upgrade to the latest version (or the specified version). When restarting the master be sure to keep the data in `/var/lib/kubelet` or your cluster state will be erased.
