#!/usr/bin/env bash

set -e
# set -x

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

dir=${1:-build-rel}

function finish() {
    echo exit
}

trap finish EXIT

# make sure there is something for cleaning
ln -sfT "$dir" obj-x86_64-linux-gnu

debian/rules clean

ln -sfT "$dir" obj-x86_64-linux-gnu

dir=/data/clickhouse-debs-$(git describe --always --dirty --abbrev=10 --exclude '*')-$(date +%Y-%m-%d-%H-%M-%S)

mkdir "$dir"

ln -sfT "$dir" /data/clickhouse-debs

# fakeroot debian/rules binary

function amos_dh_binary () {
   dh_testdir -O--buildsystem=cmake
   # debian/rules override_dh_update_autotools_config
   # debian/rules override_dh_auto_configure
   debian/rules override_dh_auto_build
   # debian/rules override_dh_auto_test
   dh_testroot -O--buildsystem=cmake
   dh_prep -O--buildsystem=cmake
   dh_installdirs -O--buildsystem=cmake
   debian/rules override_dh_auto_install
   debian/rules override_dh_install
   dh_installdocs -O--buildsystem=cmake
   dh_installchangelogs -O--buildsystem=cmake
   dh_installexamples -O--buildsystem=cmake
   dh_installman -O--buildsystem=cmake
   dh_installcatalogs -O--buildsystem=cmake
   dh_installcron -O--buildsystem=cmake
   dh_installdebconf -O--buildsystem=cmake
   dh_installemacsen -O--buildsystem=cmake
   dh_installifupdown -O--buildsystem=cmake
   dh_installinfo -O--buildsystem=cmake
   dh_installinit -O--buildsystem=cmake
   dh_installmenu -O--buildsystem=cmake
   dh_installmime -O--buildsystem=cmake
   dh_installmodules -O--buildsystem=cmake
   dh_installlogcheck -O--buildsystem=cmake
   dh_installlogrotate -O--buildsystem=cmake
   dh_installpam -O--buildsystem=cmake
   dh_installppp -O--buildsystem=cmake
   dh_installudev -O--buildsystem=cmake
   dh_installgsettings -O--buildsystem=cmake
   dh_bugfiles -O--buildsystem=cmake
   dh_ucf -O--buildsystem=cmake
   dh_lintian -O--buildsystem=cmake
   dh_gconf -O--buildsystem=cmake
   dh_icons -O--buildsystem=cmake
   dh_perl -O--buildsystem=cmake
   dh_usrlocal -O--buildsystem=cmake
   dh_link -O--buildsystem=cmake
   dh_installwm -O--buildsystem=cmake
   dh_installxfonts -O--buildsystem=cmake
   # debian/rules override_dh_strip_nondeterminism
   dh_compress -O--buildsystem=cmake
   dh_fixperms -O--buildsystem=cmake
   dh_missing -O--buildsystem=cmake
   debian/rules override_dh_strip
   dh_makeshlibs -O--buildsystem=cmake
   debian/rules override_dh_shlibdeps
   dh_installdeb -O--buildsystem=cmake
   dh_gencontrol -O--buildsystem=cmake
   dh_md5sums -O--buildsystem=cmake
   # debian/rules override_dh_builddeb
   dh_builddeb --destdir /data/clickhouse-debs -- -Z gzip # Older systems don't have "xz", so use "gzip" instead.
}

fakeroot bash -c "$(declare -f amos_dh_binary) && amos_dh_binary"

cd "$dir"

# dpkg-scanpackages . >Packages

# if [ -n "$1" ]
# then
#     tar cf - ./* | ssh s5 'cd debs; rm *; tar xf -'
# fi
#
# tar cf - clickhouse-client_*_all.deb clickhouse-server_*_all.deb clickhouse-common-static_*_amd64.deb | ssh s5 'cd debs; rm *; tar xf -; dpkg-scanpackages . > Packages'
