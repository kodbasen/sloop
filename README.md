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
