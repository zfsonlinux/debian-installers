#!/bin/bash

set -x

if echo "$*" | grep -q "clean"; then
    make reallyclean
fi

# --------------------------------------------------------
# Set values for WHEEZY
LINUX_KERNEL_ABI="3.2.0-4"
DEBIAN_RELEASE="wheezy"
DEBIAN_VERSION="7 (wheezy)"
USE_UDEBS_FROM="wheezy-daily"
export LINUX_KERNEL_ABI DEBIAN_RELEASE DEBIAN_VERSION USE_UDEBS_FROM

# --------------------------------------------------------
cat <<EOF > sources.list.udeb.local
# Local udeb packages
deb [trusted=yes] copy:/usr/src/Debian/debian-installer/build/ localudebs/

# Official packages
deb http://ftp.se.debian.org/debian wheezy main main/debian-installer

# ZoL packages
deb [trusted=yes] http://archive.zfsonlinux.org/debian wheezy main
deb [trusted=yes] http://archive.zfsonlinux.org/debian wheezy-daily main main/debian-installer
EOF

# I need this for my card...
cat <<EOF > pkg-lists/local
nic-extra-modules-\${kernel:Version}
multiarch-support
EOF

make build_netboot

# --------------------------------------------------------
TMPFILE=`tempfile -d /var/tmp -m 600 -p gpg.`
for key in 201C31294D5843EA 8E234FB17DFFA34D 9A55B33CA71C1E00; do \
	gpg --ignore-time-conflict --no-options --no-default-keyring \
		--trustdb-name /etc/apt/trustdb.gpg --secret-keyring $TMPFILE \
		--keyring tmp/netboot/tree/usr/share/keyrings/debian-archive-keyring.gpg \
		--keyserver keyserver.ubuntu.com --recv-keys $key
done

# --------------------------------------------------------
echo wheezy-daily > tmp/netboot/tree/etc/udebs-source

# --------------------------------------------------------
cat <<EOF > tmp/netboot/tree/preseed.cfg
# Make sure we use a GPT label!
# One of these should work...
d-i partman-basicfilesystems/choose_label string gpt
d-i partman-basicfilesystems/default_label string gpt
d-i partman-partitioning/choose_label string gpt
d-i partman-partitioning/default_label string gpt
d-i partman/choose_label string gpt
d-i partman/default_label string gpt
partman-partitioning partman-partitioning/choose_label select gpt

# Get the debian installer components from the ZoL wheezy dailies
d-i mirror/udeb/suite string wheezy-daily
d-i mirror/udeb/components multiselect main

# Main repo
# => This is used for the first part of the installation
d-i mirror/protocol string http
d-i mirror/country string manual
d-i mirror/suite string wheezy-daily
d-i mirror/components multiselect main
d-i mirror/http/hostname string archive.zfsonlinux.org
d-i mirror/http/directory string /debian

# Additional repositories, local[0-9] available
# => Used for the later part of the installation
d-i apt-setup/local0/comment string Debian GNU/Linux Wheezy
d-i apt-setup/local0/repository string http://ftp.debian.org/debian wheezy main
d-i apt-setup/local1/comment string ZFS On Linux Wheezy Dailies
d-i apt-setup/local1/repository string http://archive.zfsonlinux.org/debian wheezy-daily main
d-i apt-setup/local1/key string http://archive.zfsonlinux.org/debian/4D5843EA.asc

# Install the Wheezy kernel (the same we're using for boot).
d-i base-installer/kernel/image string linux-image-3.2.0-4-amd64

# This is necessary because we're installing the ZoL keyring
# to late in the install process.
d-i debian-installer/allow_unauthenticated boolean true

# Maybe this should be in grub-installer instead?!
d-i pkgsel/include string spl spl-dkms zfs-dkms zfsonlinux zfs-initramfs
EOF

# --------------------------------------------------------
pushd tmp/netboot/tree
    rm lib64
    ln -s lib lib64
    cd lib
    cp /lib64/ld-linux-x86-64.so.2 ld-2.13.so
    ln -s ld-2.13.so ld-linux-x86-64.so.2

    wget http://archive.zfsonlinux.org/debian/4D5843EA.asc
popd

# --------------------------------------------------------
chroot tmp/netboot/tree /bin/ls > /dev/null 2>&1
if [ "$?" -gt 0 ]; then
    echo "ERROR: chroot broken"

    sync
    make build_netboot
fi

# --------------------------------------------------------

rm /lib/ld-linux-x86-64.so.2 # 'fuckup' by build_netboot.

#install -m 644 -D ./tmp/netboot/mini.iso dest/netboot/mini.iso
#./util/update-manifest dest/netboot/mini.iso "tiny CD image that boots the netboot installer" ./tmp/netboot/udeb.list

scp dest/netboot/mini.iso negotia:/root/mini_turbo.iso
exit 0
