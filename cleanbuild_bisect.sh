#!/bin/sh
set -e

par=3
while [ $# -gt 0 ]; do
	case $1 in
		-t)
			cb_toolbuild=1;
			shift;
			;;
		-k)
			cb_kernbuild=1;
			shift
			;;
		-j)
			shift
			if [ "$1" ]; then
				par=$1
				shift
			else
				par=1
			fi
			;;
		-l)
			shift
			if [ "$1" ]; then
				cb_logsuf="-$1"
				shift
			else
				cb_logsuf=-bisect
			fi
			;;
		*)
			echo "Unknown option '$1', ignoring"
			shift
			;;
	esac
done

[ "$cb_toolbuild" ] || mv obj/tooldir.Linux-3.18.9-gd1034e83-heidi-x86_64 ../
git clean -x -f -d || [ "$(git status -u -s | wc -l)" -eq 0 ]
git reset --hard HEAD

cp ../NSLU2_ALL sys/arch/evbarm/conf/
cp ../IxNpeMicrocode.dat sys/arch/arm/xscale/

#patch -p1 < ../binutils.patch
#patch -p1 < ../0001-Revert-Cleanup-arm-netbsdelf-eabi.patch
#patch -p1 < ../armbe-fix.patch
patch -p0 < ../netbsd-elf.diff || true
patch -p1 < ../crypto.inc.diff || true
#export NOGCCERROR=yes

export cb_ver=$(git describe --tags | tr '/' '_')
#export SLOPPY_FLIST=${SLOPPY_FLIST-yes}
#export MKMAN=${MKMAN-no}
#export MKDOC=${MKDOC-no}
#export MKINFO=${MKDOC-no}
#export MKNLS=${MKNLS-no}
#export MKHTML=${MKHTML-no}
#export MKCATPAGES=${MKCATPAGES-no}
export MAKEVERBOSE=${MAKEVERBOSE-4}
#export MKKDEBUG=${MKKDEBUG-yes}
#export MKDEBUG=${MKDEBUG-yes}
#export MKLINT=${MKLINT-no}
#export MKPROFILE=${MKPROFILE-no}

git diff

#(
#./build.sh -j 3 -U -m evbarm -a armeb -V NOGCCERROR=yes tools              &&
#./build.sh -j 3 -u -U -m evbarm -a armeb -V NOGCCERROR=yes build           &&
#./build.sh -j 3 -u -U -m evbarm -a armeb -V KERNEL_SETS=NSLU2_ALL release
#) 2>&1 | tee ../log-$cb_ver.txt | grep -q 'extra files in DESTDIR' && exit 0 || true
if [ "$cb_kernbuild" ]; then
	#cb_distr=release
	cb_distr=distribution
	#cb_var="-V KERNEL_SETS=NSLU2_ALL -V BUILD_KERNELS=NSLU2_ALL"
	#cb_var="-V KERNEL_SETS=NSLU2_ALL -V ALL_KERNELS=NSLU2_ALL"
	#cb_var="-V ALL_KERNELS=NSLU2_ALL"
	#cb_var="-V ALL_KERNELS=NSLU2_ALL kernel=NSLU2_ALL"
	cb_var="kernel=NSLU2_ALL"
	cb_logsuf="-kern$cb_logsuf"
else
	cb_distr=distribution
	cb_logsuf="-nokern$cb_logsuf"
fi
(
mkdir -p obj &&
(
	if [ $cb_toolbuild ]; then
		./build.sh -j 3 -u -U -m evbarm -a armeb tools ;
	else
		mv ../tooldir.Linux-3.18.9-gd1034e83-heidi-x86_64 obj/
	fi
) &&
./build.sh -j $par -u -U -m evbarm -a armeb -V NOGCCERROR=yes build          &&
./build.sh -j $par -u -U -m evbarm -a armeb $cb_var $cb_distr &&
./build.sh -j $par -u -U -m evbarm -a armeb sets
) 2>&1 | tee ../log$cb_logsuf-$cb_ver.txt || true
#) 2>&1 | tee ../log-$cb_ver.txt | grep -q 'extra files in DESTDIR' && exit 0 || true

#tail -n 1000 ../log-$cb_ver.txt | grep -q 'Successful make release' && exit 1 || exit 125
tail -n 500 ../log$cb_logsuf-$cb_ver.txt | grep -q 'Built sets to /home/eddy/usr/src/netbsd/net/src/obj/releasedir/evbarm/binary/sets' && exit 1 || exit 125

#ls -l obj/releasedir/evbarm/binary/sets
