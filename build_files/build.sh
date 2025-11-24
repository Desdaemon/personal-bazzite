#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y \
  fuzzel gparted mako swaybg swayidle waybar xwayland-satellite \
  sway niri swaylock

# prepare gamescope-session and gamescope-session-steam

clone_and_install() {
  git clone "$1" pkgdir
  cp -rv ./pkgdir/usr /
  rm -rf pkgdir
}

clone_and_install https://github.com/ChimeraOS/gamescope-session.git
clone_and_install https://github.com/ChimeraOS/gamescope-session-steam.git

# Tobii eye tracker support
dnf5 install -y alien
curl https://s3-eu-west-1.amazonaws.com/tobiipro.eyetracker.manager/linux/TobiiProEyeTrackerManager-2.7.2.deb -o tobii.deb
alien -r tobii.deb --scripts
dnf5 install -y ./tobiiproeyetrackermanager-2.7.2-2226.x86_64.rpm
dnf5 remove -y alien
rm ./tobiiproeyetrackermanager-2.7.2-2226.x86_64.rpm ./tobii.deb
dnf5 clean all

git clone https://github.com/johngebbie/tobii_4C_for_linux.git tobii_drivers && cd tobii_drivers

ls -lah /usr/sbin
cp -rv tobii_usb_service/etc/* /etc/
ls -lah tobii_usb_service
cp -rv tobii_usb_service/usr/local/lib/* /usr/lib/
cp -rv tobii_usb_service/usr/local/sbin/* /usr/bin/
tar -xzf tobii_engine/usr/share/tobii_engine.tar.gz -C tobii_engine/usr/share/
cp -rv tobii_engine/etc/* /etc/
cp -rv tobii_engine/usr/* /usr/
# systemctl daemon-reload
systemctl enable tobiiusb.service
systemctl enable tobii_engine.service

mkdir /usr/lib/tobii
cp -pR lib/lib/x64/*.so /usr/lib/tobii/
cp ./tobii.conf /etc/ld.so.conf.d/
mkdir /usr/include/tobii
cp -R lib/include/tobii/* /usr/include/tobii
cd .. && rm -rf ./tobii_drivers

rm -rf /var/lib/dnf /var/cache/dnf

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
