# Developer guide for istio

Learn how to contribute to istio

## Table of Contents

1. [IDE](#IDE)
2. [Build-from-source](#Build-from-source)
3. [Updating old version](#Updating-old-version)
4. [Search for issues](#Search-for-issues)

### IDE

Clone the project to your gopath (%GOPATH%/src/github.com/kubernetes) & import on [goland]()

```bash
file -> open -> kubectl
file -> setting -> go -> index entire gopath
go get -v all
or
GO111MODULES=off go get -v all
```

### Build from source

build from the vm, enable folder sharing on vmware, as below,

```bash
sudo apt-get -y install open-vm-tools-desktop fuse && reboot
ps aux | grep vm
sudo mount -t fuse.vmhgfs-fuse .host:/ /mnt/hgfs -o allow_other
```

```bash
make gen-charts
make istioctl
```

target location will be `out/linux_amd64/` depending on os

Inorder to enable verbose logging, use

```bash
make istioctl VERBOSE=1
```

### Updating old version

If you making a bug fix to prev version say, 1.5.4, you need to issue the PR
to branch, `istio:release-1.5`

### Search for issues

Search for issue on github with lable `good-first' which is meant for newbies, join slack & istio community meetings.