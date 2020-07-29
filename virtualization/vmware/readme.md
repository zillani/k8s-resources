# Virtualization Guide

Guide to virtualization solutions on windows

## Table of Contents

1. [HyperV](#HyperV)
2. [Vagrant](#Vagrant)
3. [Docker Desktop](#Docker Desktop)

## HyperV

HyperV is a type-1 virtualization solution, you need to enable hyper-v on windows for this to work.
First create a virtual switch and select internal network. 
Now create the vm and select virtual switch created from above step. If you are having issue with copy-
paste, push your files to git and clone over there (current workaround).

On your guest OS, windows go to network adaptors and select the default switch -> sharing 
share with all users & select internal private network. Make sure this adapter has internet access,
if not click on diagnose & fix the issue.

### No Internet on HyperV
This usually doesn't happen, I have no issues with default switch, but in case if you have issues here,

- Turn off your Windows 10 virtual machine.
- Open the Hyper-V Manager -> click on the Virtual Switch Manager option found in the panel to your right.
- In the newly opened window -> click New virtual network switch found in the left-side panel.
- From the right-side panel -> choose External -> Create virtual switch.
- Inside the Virtual Switch Properties window -> change the name of your virtual machine.
- Under the Connection type section -> choose External network -> Realtek PCIe GBE Familly Controller.
- Check the box next to Allow management operating system to share this network adapter -> press Ok.

### IPv6 issues

If you are running docker for desktop then your vms will have ipv6 even though your adapter is set
to use ipv4. This is strange. remove docker for desktop (workaround, but not recommended)

### setting static ipaddress

[ubuntu-20](https://www.linuxtechi.com/assign-static-ip-address-ubuntu-20-04-lts/#:~:text=Assign%20Static%20IP%20Address%20on%20Ubuntu%2020.04%20LTS%20Desktop&text=Login%20to%20your%20desktop%20environment,and%20then%20choose%20wired%20settings.&text=In%20the%20next%20window%2C%20Choose,gateway%20and%20DNS%20Server%20IP.)
[ubuntu-18](https://linuxconfig.org/how-to-configure-static-ip-address-on-ubuntu-18-04-bionic-beaver-linux)
## Vagrant

## Docker Desktop

Docker for Desktop is an excellent option, it comes with single node k8s cluster which can be 
enabled while starting docker. No complex configurations.

## Vmware

I've put the VM on NAT & below is config for my master. 

vim /etc/netplan/<whatever>.yml

netplan --debug apply

```bash
network:
    ethernets:
        ens33:
          addresses:
            - 192.168.110.14/24
          gateway4: 192.168.110.2
          nameservers:
            addresses: [8.8.8.8,8.8.4.4]
          dhcp4: false
        ens38:
          dhcp4: true
    version: 2
    renderer: networkd
```

Below is for my worker node, 

```bash
network:
    ethernets:
        ens33:
          addresses:
            - 192.168.110.15/24
          gateway4: 192.168.110.2
          nameservers:
            addresses: [8.8.8.8,8.8.4.4]
          dhcp4: false
        ens38:
          dhcp4: true
    version: 2
    renderer: networkd
```
Below are n/w adapters on my host (windows),

```bash
Ethernet adapter VirtualBox Host-Only Network #2:

   Connection-specific DNS Suffix  . :
   Link-local IPv6 Address . . . . . : fe80::fd34:801e:8eff:b2e4%10
   IPv4 Address. . . . . . . . . . . : 192.168.99.1
   Subnet Mask . . . . . . . . . . . : 255.255.255.0
   Default Gateway . . . . . . . . . :

Ethernet adapter Ethernet 2:

   Connection-specific DNS Suffix  . :
   Link-local IPv6 Address . . . . . : fe80::84cf:26ef:400f:84e3%22
   IPv4 Address. . . . . . . . . . . : 192.168.56.1
   Subnet Mask . . . . . . . . . . . : 255.255.255.0
   Default Gateway . . . . . . . . . :

Ethernet adapter VMware Network Adapter VMnet8:

   Connection-specific DNS Suffix  . :
   Link-local IPv6 Address . . . . . : fe80::9d63:4df7:2d2f:c2e3%2
   IPv4 Address. . . . . . . . . . . : 192.168.110.1
   Subnet Mask . . . . . . . . . . . : 255.255.255.0
   Default Gateway . . . . . . . . . :
```

Make sure your virtual network editor vmnet1 is on bridged connection and vmnet8 is on nat
