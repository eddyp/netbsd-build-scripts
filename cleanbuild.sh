#!/bin/sh
set -e

git clean -x -f -d
git reset --hard HEAD

cp ../NSLU2_ALL sys/arch/evbarm/conf/
cp ../IxNpeMicrocode.dat sys/arch/arm/xscale/

#patch -p1 < ../binutils.patch
export NOGCCERROR=yes

git diff

./build.sh -j 3 -U -m evbarm -a armeb -V NOGCCERROR=yes tools
./build.sh -j 3 -u -U -m evbarm -a armeb -V NOGCCERROR=yes build
./build.sh -j 3 -u -U -m evbarm -a armeb -V KERNEL_SETS=NSLU2_ALL release

ls -l obj/releasedir/evbarm/binary/sets
