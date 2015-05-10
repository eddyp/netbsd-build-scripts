#!/bin/sh
set -e

git clean -x -f -d
git reset --hard HEAD

cp ../NSLU2_ALL sys/arch/evbarm/conf/
cp ../IxNpeMicrocode.dat sys/arch/arm/xscale/

#patch -p1 < ../binutils.patch
export NOGCCERROR=yes

export ver=$(git describe --tags | tr '/' '_')

git diff

(
./build.sh -j 3 -U -m evbarm -a armeb -V NOGCCERROR=yes tools              &&
./build.sh -j 3 -u -U -m evbarm -a armeb -V NOGCCERROR=yes build           &&
./build.sh -j 3 -u -U -m evbarm -a armeb -V KERNEL_SETS=NSLU2_ALL release
) 2>&1 | tee ../log-$ver.txt | grep -q 'extra files in DESTDIR' && exit 0 || true

tail -n 1000 ../log-$ver.txt | grep -q 'Successful make release' && exit 1 || exit 125

#ls -l obj/releasedir/evbarm/binary/sets
