#!/bin/bash
echo "call me like -m r7800vpn -f y -d y -v v18.06|v19.07|master"
###ccache
export PATH="/usr/lib/ccache:$PATH"
export CONFIG_CCACHE=y

### get opts
while getopts f:m:d:v: option
do
    case "${option}"
    in
      f) FILES=${OPTARG};;
      m) MODEL=${OPTARG};;
      d) DEBUG=${OPTARG};;
      v) VERSION=$OPTARG;;
    esac
done

##########################
### get started
### MODEL

if [[ "$MODEL" =~ ^(c7|wr1043nd|wr1043ndfire|r7800|r7800vpn|c7bernd|r7800dev)$ ]]; then
   echo "-----------------------------------------------------------------------------------"
   echo "Building $MODEL"
   echo "-----------------------------------------------------------------------------------"
else
   echo "-----------------------------------------------------------------------------------"
   echo "$MODEL is not a valid model, possible values -m are c7|wr1043nd|r7800|r7800vpn|c7bernd|r7800dev - exiting..."
   echo "-----------------------------------------------------------------------------------"
   exit 1
fi

##########################
### check VERSION

if [[ "$VERSION" =~ ^(v18.06|v19.07|master)$ ]]; then
    echo "-----------------------------------------------------------------------------------"
    echo "Choosing $VERSION"
    echo "-----------------------------------------------------------------------------------"
else
    echo "-----------------------------------------------------------------------------------"
    echo "$VERSION is not a valid version, possible values -v are v18.06.1|v19.07|master - exiting..."
    echo "-----------------------------------------------------------------------------------"
    exit 1
fi

##########################
### check FILES

if [[ "$FILES" =~ ^(y|n)$ ]]; then
    echo "-----------------------------------------------------------------------------------"
    echo "Considering backed up files"
    echo "-----------------------------------------------------------------------------------"
else
    echo "-----------------------------------------------------------------------------------"
    echo "$FILES is not a valid version, possible values -f are y|n - exiting..."
    echo "-----------------------------------------------------------------------------------"
    exit 1
fi

### debug / additional parameters
if [ ! "$DEBUG" = "" ]; then
    echo "-----------------------------------------------------------------------------------"
    echo "...V=s detailed logs, there seem to be issues..."
    echo "-----------------------------------------------------------------------------------"
    ADDFLAGS="-j 1 V=s"

else

   ADDFLAGS="-j 4 V=s"
fi

### Target definitions
TARGET="owrt1806_$MODEL"
if [ "$VERSION" = "master" ]; then
   ISMASTER="y"
   GITREPO="https://git.openwrt.org/openwrt/openwrt.git"
   TVERS="master"
elif [ "$VERSION" = "v18.06" ]; then
   GITREPO="-b openwrt-18.06 --single-branch https://git.openwrt.org/openwrt/openwrt.git"
   TVERS="18.06"
elif [ "$VERSION" = "v19.07" ]; then
   GITREPO="-b openwrt-19.07 --single-branch https://git.openwrt.org/openwrt/openwrt.git"
   TVERS="19.07"
fi
    echo "-----------------------------------------------------------------------------------"
    echo "setting GITREPO to $TVERS"
    echo "-----------------------------------------------------------------------------------"


### clean up
if [ -d $TARGET ]; then
    echo "-----------------------------------------------------------------------------------"
    echo "...cleaning up rm -rf $TARGET"
    echo "-----------------------------------------------------------------------------------"
    sudo rm -rf $TARGET
fi
 
### Prerequisites for buildroot
sudo apt-get install build-essential subversion libncurses5-dev zlib1g-dev
sudo apt-get install gawk gcc-multilib flex git-core gettext libssl-dev
#  -b openwrt-18.06 --single-branch https://git.openwrt.org/openwrt/openwrt.git
### Prerequisite on Ubuntu 17.10 as it has python3 by default
sudo apt-get install python
 
### Newly patched Ubuntu may not yet have the correct kernel headers.
# sudo apt-get install linux-headers-$(uname -r)
 
### set the preferred umask (allowed: 0000-0022)
umask 0022
 
### main directory
mkdir -p $TARGET
 
### checkout/clone and change to directory
git clone $GITREPO $TARGET
cd $TARGET
if [ "$ISMASTER" = "y" ]; then
   echo "-----------------------------------------------------------------------------------"
   echo "...checking out master..."
   echo "-----------------------------------------------------------------------------------"   
else
   #git fetch --tags
   #git checkout v18.06.2
   echo "-----------------------------------------------------------------------------------"
   echo "setting HEAD on latest $VERSION // ...checking out $VERSION (actually doin nothing)"
   echo "-----------------------------------------------------------------------------------"
fi

### copy config?
if [ "$FILES" = "y" ]; then
### possible values: bernd, holiday, firewall, vpn, home
### to be tested !!!!!!
  echo "-----------------------------------------------------------------------------------"
  echo "...config files being copied..."
  echo "-----------------------------------------------------------------------------------"
  mkdir files
  mkdir files/etc
  mkdir files/etc/config
  mkdir files/etc/openvpn
  mkdir files/etc/ddns
  mkdir files/etc/adblock

  cp -pR ../../../netgear/builds/files_$MODEL/usr/ files/
  cp -pR ../../../netgear/builds/files_$MODEL/etc/dropbear/ files/etc/
  cp -pR ../../../netgear/builds/files_$MODEL/etc/openvpn/ files/etc/
  cp -pR ../../../netgear/builds/files_$MODEL/etc/ddns/ files/etc/
  cp -p ../../../netgear/builds/files_$MODEL/etc/dnsmasq.conf files/etc/
  cp -p ../../../netgear/builds/files_$MODEL/etc/dnsmasq.hosts files/etc/
  cp -p ../../../netgear/builds/files_$MODEL/etc/resolv.conf files/etc/
  cp -p ../../../netgear/builds/files_$MODEL/etc/sysctl.conf files/etc/
  cp -p ../../../netgear/builds/files_$MODEL/etc/adblock/adblock.blacklist files/etc/adblock
  cp -p ../../../netgear/builds/files_$MODEL/etc/adblock/adblock.whitelist files/etc/adblock
  cp -p ../../../netgear/builds/files_$MODEL/usr/sbin/opkg-updater files/usr/sbin/

  cp -p ../../../netgear/builds/files_$MODEL/etc/config/system files/etc/config/
  cp -p ../../../netgear/builds/files_$MODEL/etc/config/openvpn files/etc/config/
  cp -p ../../../netgear/builds/files_$MODEL/etc/config/fstab files/etc/config/
  cp -p ../../../netgear/builds/files_$MODEL/etc/config/dhcp files/etc/config/
  cp -p ../../../netgear/builds/files_$MODEL/etc/config/firewall files/etc/config/
  cp -p ../../../netgear/builds/files_$MODEL/etc/config/network files/etc/config/
  cp -p ../../../netgear/builds/files_$MODEL/etc/config/firewall files/etc/config/
  cp -p ../../../netgear/builds/files_$MODEL/etc/config/adblock files/etc/config/
  cp -p ../../../netgear/builds/files_$MODEL/etc/config/sqm files/etc/config/
  cp -p ../../../netgear/builds/files_$MODEL/etc/config/wireless files/etc/config/
  cp -p ../../../netgear/builds/files_$MODEL/etc/config/upnpd files/etc/config/ 

else
  echo "-----------------------------------------------------------------------------------"
  echo "...no config files being copied..."
  echo "-----------------------------------------------------------------------------------"
fi


### get feeds
echo "-----------------------------------------------------------------------------------"
echo "...update feeds..."
echo "-----------------------------------------------------------------------------------"

# my feeds for updates
cp -p ../feeds.conf .
mkdir -p mypackages/update/updates
cp -p ../packagesource/Makefile mypackages/update/updates/
mkdir -p updatessrc
cp -p ../packagesource/updates.c updatessrc/


scripts/feeds update -a
scripts/feeds install -a
 
### initialise .config
echo "-----------------------------------------------------------------------------------"
echo "preparing config ../config_$MODEL.init .config"
echo "-----------------------------------------------------------------------------------"

cp ../config_$MODEL.init .config
echo "-----------------------------------------------------------------------------------"
echo "...make defconfig..."
echo "-----------------------------------------------------------------------------------"

make defconfig

echo "-----------------------------------------------------------------------------------"
echo "...download new source packages..."
echo "-----------------------------------------------------------------------------------"

make download

echo "-----------------------------------------------------------------------------------"
echo "...make image... with $ADDFLAGS"
echo "-----------------------------------------------------------------------------------"

mkdir -p logs
time make $ADDFLAGS 2>&1 | tee logs/build.log | grep -i -E "^make.*(error|[12345]...Entering dir)"
#[ ${PIPESTATUS[0]} -ne 0 ] && exit 1

### do cleanup
echo "-----------------------------------------------------------------------------------"
echo "...cleaning up..."
echo "-----------------------------------------------------------------------------------"

#make build info for r7800
#if [ "$MODEL" = "r7800" ]; then
cp -p ../createbuildinfo.sh .
./createbuildinfo.sh -m $MODEL
#fi
#createbuildinfo.sh



#cp -p $TARGET/bin/targets/ar71xx/generic/*.bin .
#rm -rf build_dir
#rm -rf staging_dir
