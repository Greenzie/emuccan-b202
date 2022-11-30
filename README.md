# EMUC-B202 SocketCAN Driver and Uspace Tool

## Build Driver and Util

Please install kernel development packages on your machine and simply
type 'make' command in root folder of this package.

There should be two output files:
- src/emuccan.ko : kernel driver of emuc socket can
- src/emucd      : user-space tool for enabling emuc socket can

## Usage and Example

Here is an example to use emuccan socket CAN.
```
root@host# insmod emuccan.ko
root@host# emucd -s6 ttyACM0 can0 can1
root@host# ip link set can0 up
root@host# ip link set can1 up
root@host# cansend can0 5A1#11.22.33.44.55.66.77.88
root@host# candump can1
```

The detail usage of 'cansend' and 'candump', please refer to the open source
project 'can-utils' (https://github.com/linux-can/can-utils).

You can specify the CAN speed for two channels when execute 'emucd'
daemon, type 'emucd -h' for help.

```
root@host# emucd -s6 /dev/ttyACM0  (250 KBPS on both channel)
root@host# emucd -s45 /dev/ttyACM0 (100 KBPS on ch1, 125 KBPS on ch2)
```

## Trubleshooting

If the can device did not show up after 'emucd' is executed. Please check
your system log to see if there is any error message reported by emuccan
or emucd.

```
root@host# tail -n 100 /var/log/syslog (Ubuntu)
root@host# tail -n 100 /var/log/message (CentOS)
```

Or, you can try to run 'emucd' in the foreground to see if there is any error
reported.

```
root@host# emucd -F -s6 /dev/ttyACM0
```

There cannot be two EMUCD daemon running with same TTY device. You must
kill the previous one before running a new one on the same device.

## A note on /dev/tty devices

Unfortunately, emucd_64 is hardcoded(!) to use a /ttyACM[0-9] which is terrible,
so you must create a udev rule to put it at something hardcoded, in this case
we chose /dev/ttyACM9 interface. This is terrible but works for now.

## Debian and System Install

This version of the library also includes a debianization which will build
a package and install it on Ubuntu systems.

To build the library and create the repo use:

* `make clean`
* Bionic-Melodic:
  * `export KERNEL_VER=$(uname -r)` # 5.3.7nlb
* Focal-Noetic (Stock Kernel)
  * `apt install linux-headers-5.4.0-96-generic` # This can change depending on which kernel you want to build
  * `export KERNEL_VER=$(uname -r)` #stock kernel
  * `export VER_SUFFIX=greenzie` #OPTIONAL if you want to brand version
* `export KERNEL_SRC=/usr/src/linux-headers-${KERNEL_VER}/`
* `make`

This will generate two files, `emucd_64` (a userspace binary) and
`emuc2socketcan.ko` (a kernel module). The latter needs be rebuilt for each
kernel (even new configurations of the same kernel version), but the former
should be reusable.

To build the debian package, run:

* `mkdir build`
* `cd build`
* `cmake ..`
* `make`
* `cpack`

You should now have a debian called emuccan-b202_2.7.1-1.deb.

The trailing -1 is a version you can bump inside CMakeLists.txt when
rebuilding the same source for a new kernel version.
