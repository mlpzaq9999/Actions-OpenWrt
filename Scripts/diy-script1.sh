#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001
# AutoBuild Actions

Diy_Core() {
Author=ZYL

Default_File=./package/base-files/files/etc/openwrt_release
Lede_Version="Life"
Openwrt_Version="$Lede_Version-`date +%Y%m%d`"
AutoUpdate_Version=`awk 'NR==6' ./package/base-files/files/bin/AutoUpdate.sh | awk -F'[="]+' '/Version/{print $2}'`
Compile_Date=`date +'%Y/%m/%d'`
Compile_Time=`date +'%Y-%m-%d %H:%M:%S'`
TARGET_PROFILE=`egrep -o "CONFIG_TARGET_.[0-9]+.[0-9]+=y" .config | sed -r 's/.*TARGET_(.*)=y/\1/'`
}

GET_TARGET_INFO() {
TARGET_BOARD=`awk -F'[="]+' '/TARGET_BOARD/{print $2}' .config`
TARGET_SUBTARGET=`awk -F'[="]+' '/TARGET_SUBTARGET/{print $2}' .config`
}

Diy-Part1() {
# Modify default IP
sed -i 's/192.168.9.1/192.168.3.1/g' package/base-files/files/bin/config_generate
sed -i 's/OpenWrt-Life/OpenWrt/g' package/base-files/files/etc/config/system
# 修改连接数
# sed -i '1c net.netfilter.nf_conntrack_max=131072' package/base-files/files/etc/sysctl.conf

}

Diy-Part2() {
git clone https://github.com/garypang13/luci-theme-edge.git ./package/luci-theme-edge
git clone https://github.com/garypang13/luci-app-eqos.git ./package/feeds/packages/luci-app-eqos
# git clone https://github.com/Hyy2001X/luci-app-autoupdate.git ./package/feeds/packages/luci-app-autoupdate
# cp $GITHUB_WORKSPACE/Customize/AutoUpdate1.sh ./package/base-files/files/bin/AutoUpdate.sh
cp -f $GITHUB_WORKSPACE/Customize/banner ./package/base-files/files/etc
cp -f $GITHUB_WORKSPACE/Customize/luci-app-ssr-plus ./package/feeds/luci/luci-app-ssr-plus/Makefile
cp -r -f $GITHUB_WORKSPACE/Customize/automount ./package/feeds/packages/automount
cp -r -f $GITHUB_WORKSPACE/Customize/antfs-mount ./package/feeds/packages/antfs-mount
cp -r -f $GITHUB_WORKSPACE/Customize/antfs ./package/feeds/packages/antfs
rm -rf ./package/feeds/luci/luci-app-upnp
rm -rf ./package/feeds/packages/net/miniupnpd
cp -r -f $GITHUB_WORKSPACE/Customize/miniupnpd ./package/feeds/packages/miniupnpd
cp -r -f $GITHUB_WORKSPACE/Customize/luci-app-upnp ./package/feeds/packages/luci-app-upnp
cp -r -f $GITHUB_WORKSPACE/Customize/ipv6-helper ./package/feeds/packages/ipv6-helper
cp -r -f $GITHUB_WORKSPACE/Customize/luci-app-gpsysupgrade ./package/feeds/packages/luci-app-gpsysupgrade
cp -f $GITHUB_WORKSPACE/Customize/config-4.14 ./target/linux/x86/config-4.14
# chmod -R 755 ./package/base-files/files/bin/AutoUpdate.sh
mv ./package/feeds/packages/luci-app-gpsysupgrade/po/zh-cn ./package/feeds/packages/luci-app-gpsysupgrade/po/zh_Hans
# sed -i 's/bash/sh/g' ./package/feeds/packages/luci-app-autoupdate/root/etc/init.d/autoupdate
# sed -i 's/"定时更新"/"系统定时更新"/g' ./package/feeds/packages/luci-app-autoupdate/po/zh-cn/autoupdate.po

echo "Author: $Author"
echo "Openwrt Version: $Openwrt_Version"
echo "AutoUpdate Version: $AutoUpdate_Version"
echo "Device: $TARGET_PROFILE"
sed -i '/DISTRIB_REVISION/d' $Default_File
echo "DISTRIB_REVISION='Life'" >> $Default_File
sed -i "s?$Lede_Version?$Lede_Version Compiled by $Author [$Compile_Date]?g" $Default_File
echo "$Openwrt_Version" > ./package/base-files/files/etc/openwrt_info
sed -i "s?Openwrt?Openwrt $Openwrt_Version / AutoUpdate $AutoUpdate_Version?g" ./package/base-files/files/etc/banner

}

Diy-Part3() {
GET_TARGET_INFO
Default_Firmware_EFI=openwrt-$TARGET_BOARD-$TARGET_SUBTARGET-combined-squashfs-efi.img.gz
AutoBuild_Firmware_EFI=AutoBuild-$TARGET_PROFILE-OpenWrt-${Openwrt_Version}-efi.img.gz
AutoBuild_Detail_EFI=AutoBuild-$TARGET_PROFILE-OpenWrt-${Openwrt_Version}-efi.detail
Default_Firmware=openwrt-$TARGET_BOARD-$TARGET_SUBTARGET-combined-squashfs.img.gz
AutoBuild_Firmware=AutoBuild-$TARGET_PROFILE-OpenWrt-${Openwrt_Version}.img.gz
AutoBuild_Detail=AutoBuild-$TARGET_PROFILE-OpenWrt-${Openwrt_Version}.detail
mkdir -p ./bin/Firmware
echo "[$(date "+%H:%M:%S")] Moving $Default_Firmware to /bin/Firmware/$AutoBuild_Firmware ..."
mv ./bin/targets/$TARGET_BOARD/$TARGET_SUBTARGET/$Default_Firmware_EFI ./bin/Firmware/$AutoBuild_Firmware_EFI
mv ./bin/targets/$TARGET_BOARD/$TARGET_SUBTARGET/$Default_Firmware ./bin/Firmware/$AutoBuild_Firmware
echo "[$(date "+%H:%M:%S")] Calculating MD5 and SHA256 ..."
EFI_Firmware_MD5=`md5sum ./bin/Firmware/$AutoBuild_Firmware_EFI | cut -d ' ' -f1`
EFI_Firmware_SHA256=`sha256sum ./bin/Firmware/$AutoBuild_Firmware_EFI | cut -d ' ' -f1`
echo "编译日期:$Compile_Time" > ./bin/Firmware/$AutoBuild_Detail_EFI
echo -e "\nMD5:$EFI_Firmware_MD5\nSHA256:$EFI_Firmware_SHA256" >> ./bin/Firmware/$AutoBuild_Detail_EFI
Firmware_MD5=`md5sum ./bin/Firmware/$AutoBuild_Firmware | cut -d ' ' -f1`
Firmware_SHA256=`sha256sum ./bin/Firmware/$AutoBuild_Firmware | cut -d ' ' -f1`
echo "编译日期:$Compile_Time" > ./bin/Firmware/$AutoBuild_Detail
echo -e "\nMD5:$Firmware_MD5\nSHA256:$Firmware_SHA256" >> ./bin/Firmware/$AutoBuild_Detail
}
