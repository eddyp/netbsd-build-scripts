#!/bin/sh

set -e

if [ $(id -u) -ne 0 ]; then
	echo 'This script should be run as uid=0 to set the correct permissions'
	exit 1
fi

srcdir=$(pwd)

#MEDIAROOT=/media/SonyExt4
MEDIAROOT=/media/Store

# my laptop-'s wifi net IP
DEVIP=$(/sbin/ifconfig eth0 | grep -E -o 'inet addr:[^ ]*' | sed 's#^.*:##')
NFSIP=$DEVIP
#NFSIP=192.168.77.250
NFSROOT=/export/netbsd-nslu2

NETBSDOUT=${MEDIAROOT}/netbsd/$(git describe --always | tr '/' '_')
NETBSDRFS=${NETBSDOUT}/root
SETSDIR=${srcdir}/obj/releasedir/evbarm/binary/sets

if [ ! -d "$MEDIAROOT" ] ; then
	echo "Media root $MEDIAROOT not found. Maybe not mounted?"
	exit 1
fi

mkdir -p ${NETBSDRFS}
mkdir -p ${NETBSDOUT}/home
mkdir -p ${NETBSDOUT}/usr
mkdir -p ${NETBSDRFS}/swap
swapf=${NETBSDOUT}/swap
touch ${swapf}
dd if=/dev/zero of=${swapf} bs=4k count=4k
chmod 600 ${swapf}
unset swapf

#cp obj/releasedir/evbarm/binary/sets/* $NETBSDOUT/

for bsdset in base etc misc modules text kern-NSLU2_ALL ; do
	tar --numeric-owner -xvpzf $SETSDIR/$bsdset.tgz -C $NETBSDOUT/root/ || [ $bsdset = "kern-NSLU2_ALL" ]
done

mknod=$srcdir/obj/tooldir.$(uname -s)-$(uname -r)-$(uname -m)/bin/nbmknod
cd $NETBSDOUT/root/dev && sh ./MAKEDEV -m $mknod all && cd -

cat <<EOHOSTS >>${NETBSDOUT}/root/etc/hosts
#192.168.77.251  kinder
192.168.0.251  kinder
192.168.77.1    toblerone
#192.168.77.250  ritter nfsserver
$NFSIP  nfsserver
EOHOSTS

cat <<EOFSTAB > ${NETBSDOUT}/root/etc/fstab
#/etc/fstab
nfsserver:$NFSROOT/swap   none  swap  sw,nfsmntpt=/swap
nfsserver:$NFSROOT/root   /     nfs   rw 0 0
#nfsserver:$NFSROOT/usr    /usr  nfs   rw 0 0
#nfsserver:$NFSROOT/home   /home nfs   rw 0 0
EOFSTAB

#echo 'inet client netmask 255.255.255.0 broadcast 192.168.77.251' > ${NETBSDRFS}/etc/ifconfig.npe0
echo 'inet client netmask 255.255.255.0 broadcast 192.168.0.251' > ${NETBSDRFS}/etc/ifconfig.npe0

sed -i 's|^#telnet|telnet|' ${NETBSDRFS}/etc/inetd.conf

export rcconf=${NETBSDRFS}/etc/rc.conf
sed -i 's@rc_configured=.*@rc_configured=YES@' $rcconf
cat <<EORCCONF >>$rcconf
sshd=YES
hostname="kinder"
#defaultroute="192.168.77.1"
defaultroute="$DEVIP"
nfs_client=YES
auto_ifconfig=NO
net_interfaces=""
EORCCONF
unset rcconf

nbnfsok=yes
[ "$NETBSDOUT" ] && [ "$NFSROOT" ] && [ -d "$NETBSDOUT" ] && [ "$NFSROOT" != '/' ] || nbnfsok=no
if [ "$nbnfsok" = "no" ]; then
	echo "Either NETBSDOUT or NFSROOT were not correctly set. This is dangerous, so we're quitting to prevent data loss!"
	exit 3
fi

# prepare copy
cat <<EOCOPY >$NETBSDOUT/copy.sh
#!/bin/sh

#NFSSRVMNT=/mnt
NFSSRVMNT=$MEDIAROOT

HASH=\$(basename "$NETBSDOUT")
rm -fr $NFSROOT
cp -ar \$NFSSRVMNT/netbsd/\${HASH} $NFSROOT
# don't copy the kernel the problem now is in userspace
KERN=$NFSROOT/root/netbsd-nfs.bin
if [ -f "$KERN" ]; then
	rm -f /srv/tftp/netbsd-nfs.bin
	cp -a $NFSROOT/root/netbsd-nfs.bin /srv/tftp/netbsd-nfs.bin
fi
EOCOPY
chmod +x $NETBSDOUT/copy.sh

echo "Changes done in ${NETBSDRFS}"
