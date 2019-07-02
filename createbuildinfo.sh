#!/bin/bash
#
# createbuildinfo  -  Create info on current config and source code changes
### get opts
while getopts m:d:v: option
do
    case "${option}"
    in
      m) MODEL=${OPTARG};;
      d) DEBUG=${OPTARG};;
      v) VERSION=$OPTARG;;
    esac
done

##########################
### get started
### MODEL

if [[ "$MODEL" =~ ^(c7|wr1043nd|r7800|r7800vpn|r7800dev)$ ]]; then
   echo "-----------------------------------------------------------------------------------"
   echo "Building $MODEL"
   echo "-----------------------------------------------------------------------------------"
else
   echo "-----------------------------------------------------------------------------------"
   echo "$MODEL is not a valid model, possible values -m are c7|wr1043nd|r7800 - exiting..."
   echo "-----------------------------------------------------------------------------------"
   exit 1
fi


case "$MODEL" in
   c7)
     theBinDir=$PWD/bin/targets/ar71xx/generic
     thePrefix=openwrt-ar71xx-tplink_c7
     ;;
   wr1043nd)
     theBinDir=$PWD/bin/targets/ar71xx/generic
     thePrefix=openwrt-ar71xx-tplink_wr1043nd
     ;;
   r7800)
     theBinDir=$PWD/bin/targets/ipq806x/generic
     thePrefix=openwrt-ipq806x-netgear_r7800
     ;;
   r7800vpn)
     theBinDir=$PWD/bin/targets/ipq806x/generic
     thePrefix=openwrt-ipq806x-netgear_r7800vpn
     ;;
   *)
     exit 1
esac



getGitInfo() {
#params: directory patchfile infofile
 echo "\n######################################################\n" >> $3
 (cd $1
  git diff HEAD > $2
  git remote -v show | grep fetch >> $3
  git branch --list >> $3
  git show --format="%cd %h %s" --abbrev=7 --date=short | head -n 1 | cut -b1-60 >> $3
  git status --porcelain >> $3
 )
}

BinDir=$theBinDir
Device=$MODEL
Prefix=$thePrefix
Branch=$VERSION

VersTime=$Branch-`scripts/getver.sh`-`date +%Y%m%d-%H%M`
TFile=$BinDir/$Device-$VersTime

echo process $Branch...

# remove unnecessary files
rm -f $BinDir/*root.img $BinDir/*vmlinux.elf

# create status info and patches
echo "$VersTime" > $TFile-status.txt
getGitInfo . $TFile-main.patch $TFile-status.txt
getGitInfo feeds/luci $TFile-luci.patch $TFile-status.txt
getGitInfo feeds/packages $TFile-packages.patch $TFile-status.txt
#getGitInfo feeds/routing $TFile-routing.patch $TFile-status.txt
sed -i -e 's/$/\r/' $TFile-status.txt

# rename manifest and firmware files
cd $BinDir
mv *.manifest $Device-$VersTime.manifest
mv $Prefix-squashfs-sysupgrade.bin $Device-$VersTime-sqfs-sysupgrade.bin
mv $Prefix-squashfs-factory.img $Device-$VersTime-sqfs-factory.img

