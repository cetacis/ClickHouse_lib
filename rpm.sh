#!/usr/bin/env bash

set -e

arch=$(dpkg --print-architecture)

if [ "$arch" = "amd64" ]
then
   target="x86_64"
elif [ "$arch" = "arm64" ]
then
   target="aarch64"
else
    echo "Only support arch = amd64|arm64. Given $arch."
    exit 1
fi

cd /data/clickhouse-debs
CUR_DIR=$PWD
VERSION_FULL=$(dpkg-deb --showformat '${Version}\n' -W ./*.deb | head -1)

function deb_unpack() {
    rm -rf $PACKAGE-$VERSION_FULL
    fakeroot alien --verbose --generate --to-rpm --scripts ${PACKAGE}_${VERSION_FULL}_${ARCH}.deb
    cd $PACKAGE-$VERSION_FULL
    mv ${PACKAGE}-$VERSION_FULL-2.spec ${PACKAGE}-$VERSION_FULL-2.spec.tmp
    cat ${PACKAGE}-$VERSION_FULL-2.spec.tmp |
        grep -vF '%dir "/"' |
        grep -vF '%dir "/usr/"' |
        grep -vF '%dir "/usr/bin/"' |
        grep -vF '%dir "/usr/lib/"' |
        grep -vF '%dir "/usr/lib/debug/"' |
        grep -vF '%dir "/usr/lib/.build-id/"' |
        grep -vF '%dir "/usr/share/"' |
        grep -vF '%dir "/usr/share/doc/"' |
        grep -vF '%dir "/lib/"' |
        grep -vF '%dir "/lib/systemd/"' |
        grep -vF '%dir "/lib/systemd/system/"' |
        grep -vF '%dir "/etc/"' |
        grep -vF '%dir "/etc/security/"' |
        grep -vF '%dir "/etc/security/limits.d/"' |
        grep -vF '%dir "/etc/init.d/"' |
        grep -vF '%dir "/etc/cron.d/"' |
        grep -vF '%dir "/etc/systemd/system/"' |
        grep -vF '%dir "/etc/systemd/"' \
            >${PACKAGE}-$VERSION_FULL-2.spec
}

function rpm_pack() {
    rpmbuild --buildroot="$CUR_DIR/${PACKAGE}-$VERSION_FULL" -bb --target ${TARGET} "${PACKAGE}-$VERSION_FULL-2.spec"
    cd $CUR_DIR
}

function unpack_pack() {
    deb_unpack
    rpm_pack
}

PACKAGE=clickhouse-server
ARCH=all
TARGET=noarch
deb_unpack
mv ${PACKAGE}-$VERSION_FULL-2.spec ${PACKAGE}-$VERSION_FULL-2.spec_tmp
echo "Requires: clickhouse-common-static = $VERSION_FULL-2" >>${PACKAGE}-$VERSION_FULL-2.spec
echo "Requires: tzdata" >>${PACKAGE}-$VERSION_FULL-2.spec
echo "Requires: initscripts" >>${PACKAGE}-$VERSION_FULL-2.spec
echo "Obsoletes: clickhouse-server-common < $VERSION_FULL" >>${PACKAGE}-$VERSION_FULL-2.spec

cat ${PACKAGE}-$VERSION_FULL-2.spec_tmp >>${PACKAGE}-$VERSION_FULL-2.spec
rpm_pack

PACKAGE=clickhouse-client
ARCH=all
TARGET=noarch
deb_unpack
mv ${PACKAGE}-$VERSION_FULL-2.spec ${PACKAGE}-$VERSION_FULL-2.spec_tmp
echo "Requires: clickhouse-common-static = $VERSION_FULL-2" >>${PACKAGE}-$VERSION_FULL-2.spec
cat ${PACKAGE}-$VERSION_FULL-2.spec_tmp >>${PACKAGE}-$VERSION_FULL-2.spec
rpm_pack

PACKAGE=clickhouse-test
ARCH=all
TARGET=noarch
deb_unpack
mv ${PACKAGE}-$VERSION_FULL-2.spec ${PACKAGE}-$VERSION_FULL-2.spec_tmp
echo "Requires: python2" >>${PACKAGE}-$VERSION_FULL-2.spec
#echo "Requires: python2-termcolor" >> ${PACKAGE}-$VERSION-2.spec
cat ${PACKAGE}-$VERSION_FULL-2.spec_tmp >>${PACKAGE}-$VERSION_FULL-2.spec
rpm_pack

PACKAGE=clickhouse-common-static
ARCH=$arch
TARGET=$target
unpack_pack

PACKAGE=clickhouse-common-static-dbg
ARCH=$arch
TARGET=$target
unpack_pack
