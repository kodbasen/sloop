# Install

## Setting up Odrobian

### 1. Download an flash image:

```
$ sudo dd if=ODROBIAN-*.img of=/dev/path/of/card bs=1M conv=fsync
$ sync
```

### 2. Login and change password

```
$ ssh odoid@<IP>
$ passwd ...
```

### 3. Setup Odrobian

```
$ sudo -s
$ apt-get update && apt-get install oh-utils
$ oh --gui
```

or

```
$ sudo apt-get update && apt-get upgrade
$ sudo apt-get update && sudo apt-get dist-upgrade
$ sudo apt-get upgrade linux-image-odrobian-*
$ sudo apt-get upgrade linux-headers-odrobian-*
```

```
$ apt-get install debconf
$ dpkg-reconfigure locales
```

### 4. Setup Docker
https://docs.docker.com/engine/installation/linux/debian/#/debian-jessie-80-64-bit

vi /etc/apt/sources.list.d/backports.list
add:
deb http://ftp.debian.org/debian jessie-backports main
apt-get update
apt-get install apt-transport-https ca-certificates
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
vi /etc/apt/sources.list.d/docker.list
deb https://apt.dockerproject.org/repo debian-jessie main
