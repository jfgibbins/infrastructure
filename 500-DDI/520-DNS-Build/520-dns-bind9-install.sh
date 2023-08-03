#!/bin/bash
# File: 520-dns-bind9-install.sh
# Title: Install ISC Bind9 server
# Description:
#   Install ISC Bind9 and remove all configs from directories
#
# Prerequisites:
#
# Env variables
#   - BUILDROOT - '/' for direct installation, otherwise create 'build' subdir
#   - FILE_SETTING_PERFORM - write settings directly to file
#

BUILDROOT=/
FILE_SETTING_PERFORM=true

source ../../distro-os.sh
source ../../easy-admin-installer.sh

[ $((${DEBUG:-0} & 0x02)) -eq 1 ] && ( set -o posix; set ) > /tmp/variables.before

echo "Install ISC Bind9 server, complete with development and document packages"
echo

case $ID in
  debian|devuan|ubuntu)
    if [ ! -d /etc/bind/ ]; then
      apt install bind9 bind9-dnsutils bind9-doc -y
      echo "Installing named-checkconf Bind9 syntax checker tool..."
      apt install bind9-utils -y
      echo "Installing 'host -A mydomain' command ..."
      apt install bind9-host -y
      # Development packages requires
      # apt install libtool-bin
      # apt install libcap-dev
      # symbolic link for named-checkconf
      [ ! -f /usr/sbin/named-checkconf ] && ln -s /usr/bin/named-checkconf /usr/sbin/named-checkconf
      [ ! -f /usr/sbin/named-checkzone ] && ln -s /usr/bin/named-checkconf /usr/sbin/named-checkconf
      # adjust apparmor to allow named.pid in sub-dir
      [ -f /etc/apparmor.d/usr.sbin.named ] && sed -i 's/run\/named\/named.pid/run\/named\/{,\*\*\/}named.pid/g' /etc/apparmor.d/usr.sbin.named
    else
      echo "Bind is already installed"
    fi;;
  fedora|centos|redhat|rocky)
    dnf install bind-dnssec-doc
    dnf install bind-libs
    dnf install python3-bind
    dnf install bind
    dnf install bind-dnssec-utils
    dnf install bind-dlz-filesystem
    # build from scratch
    dnf install fstrm fstrm-devel
    dnf install protobuf-c protobuf-c-devel
    dnf install libmaxminddb
    dnf install json-c jscon-devel
    dnf install lmdb-libs lmdb-devel
    dnf install libidn2-devel libidn2
    # Some GSSAPI

    # dnf install bind-chroot
    # dnf -y install bind-doc --setopt=install_weak_deps=False
    ;;
  arch)
    pacman -S bind
    ;;
esac

echo "Stopping and disabling default service."
systemctl stop named
#systemctl disable named

echo "Purging initial DNS config"
echo

rm -rf /etc/bind/*
rm -rf /etc/systemd/system/na*
rm -rf /var/cache/bind/*
rm -rf /var/lib/bind/*
rm -rf /var/log/named/*

cp bind.keys /etc/bind/bind.keys
flex_chown bind:bind "/etc/bind/bind.keys"
flex_chmod 0640      "/etc/bind/bind.keys"

echo
echo "Done."

[ $((${DEBUG:-0} & 0x02)) -eq 1 ] && ( set -o posix; set ) > /tmp/variables.after
