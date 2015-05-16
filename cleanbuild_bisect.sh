#!/bin/sh
set -e

mv obj/tooldir.Linux-3.18.9-gd1034e83-heidi-x86_64 ../
git clean -x -f -d
git reset --hard HEAD

cp ../NSLU2_ALL sys/arch/evbarm/conf/
cp ../IxNpeMicrocode.dat sys/arch/arm/xscale/

#patch -p1 < ../binutils.patch
#patch -p1 < ../0001-Revert-Cleanup-arm-netbsdelf-eabi.patch
patch -p1 < ../armbe-fix.patch
export NOGCCERROR=yes

export ver=$(git describe --tags | tr '/' '_')
export SLOPPY_FLIST=yes
export MKMAN=no
export MKDOC=no
export MKINFO=no
export MKNLS=no
export MKHTML=no
export MKCATPAGES=no
export MAKEVERBOSE=3

git diff

#(
#./build.sh -j 3 -U -m evbarm -a armeb -V NOGCCERROR=yes tools              &&
#./build.sh -j 3 -u -U -m evbarm -a armeb -V NOGCCERROR=yes build           &&
#./build.sh -j 3 -u -U -m evbarm -a armeb -V KERNEL_SETS=NSLU2_ALL release
#) 2>&1 | tee ../log-$ver.txt | grep -q 'extra files in DESTDIR' && exit 0 || true
(
mkdir obj && mv ../tooldir.Linux-3.18.9-gd1034e83-heidi-x86_64 obj/       &&
./build.sh -j 3 -u -U -m evbarm -a armeb -V NOGCCERROR=yes build          &&
./build.sh -j 3 -u -U -m evbarm -a armeb -V SLOPPY_FLIST=yes distribution &&
./build.sh -j 3 -u -U -m evbarm -a armeb sets
) 2>&1 | tee ../log-$ver.txt || true
#) 2>&1 | tee ../log-$ver.txt | grep -q 'extra files in DESTDIR' && exit 0 || true

#tail -n 1000 ../log-$ver.txt | grep -q 'Successful make release' && exit 1 || exit 125
tail -n 1000 ../log-$ver.txt | grep -q 'Built sets to /home/eddy/usr/src/netbsd/net/src/obj/releasedir/evbarm/binary/sets' && exit 1 || exit 125

#ls -l obj/releasedir/evbarm/binary/sets
