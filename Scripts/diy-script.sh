#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001
# AutoBuild Actions

Diy_Core() {
Author=ZYL

Default_File=./package/lean/default-settings/files/zzz-default-settings
Lede_Version=`egrep -o "R[0-9]+\.[0-9]+\.[0-9]+" $Default_File`
Openwrt_Version="$Lede_Version-`date +%Y%m%d`"
AutoUpdate_Version=`awk 'NR==6' ./package/base-files/files/bin/AutoUpdate.sh | awk -F'[="]+' '/Version/{print $2}'`
Compile_Date=`date +'%Y/%m/%d'`
Compile_Time=`date +'%Y-%m-%d %H:%M:%S'`
TARGET_PROFILE=`egrep -o "CONFIG_TARGET.*DEVICE.*=y" .config | sed -r 's/.*DEVICE_(.*)=y/\1/'`
TARGET_PROFILE1=`egrep -o "CONFIG_TARGET.*DEVICE.*=y" .config | sed -r 's/.*TARGET_(.*)_(.*)_(.*)=y/\1/'`
}

GET_TARGET_INFO() {
TARGET_BOARD=`awk -F'[="]+' '/TARGET_BOARD/{print $2}' .config`
TARGET_SUBTARGET=`awk -F'[="]+' '/TARGET_SUBTARGET/{print $2}' .config`
}

Diy-Part1() {
# Add a feed source
sed -i "s/#src-git helloworld/src-git helloworld/g" feeds.conf.default
# Modify default IP
sed -i 's/192.168.1.1/192.168.3.1/g' ./package/base-files/files/bin/config_generate
# 修改连接数
# sed -i '1c net.netfilter.nf_conntrack_max=131072' ./package/base-files/files/etc/sysctl.conf


}

Diy-Part2() {
sed -i 's/bootstrap/argon/g' ./feeds/luci/modules/luci-base/root/etc/config/luci
rm -rf ./package/lean/luci-theme-argon
git clone https://github.com/jerrykuku/luci-app-jd-dailybonus.git ./package/lean/luci-app-jd-dailybonus
git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git ./package/lean/luci-theme-argon
git clone https://github.com/jerrykuku/luci-app-argon-config.git ./package/lean/luci-app-argon-config
git clone -b 18.06 https://github.com/garypang13/luci-theme-edge.git ./package/lean/luci-theme-edge
git clone https://github.com/garypang13/luci-app-eqos.git ./package/lean/luci-app-eqos
# git clone https://github.com/Hyy2001X/luci-app-autoupdate.git ./package/lean/luci-app-autoupdate
# cp $GITHUB_WORKSPACE/Customize/AutoUpdate.sh ./package/base-files/files/bin
cp -f $GITHUB_WORKSPACE/Customize/banner ./package/base-files/files/etc
cp -r -f $GITHUB_WORKSPACE/Customize/luci-app-dockerman ./package/lean/luci-app-dockerman
cp -r -f $GITHUB_WORKSPACE/Customize/luci-app-koolproxyR ./package/lean/luci-app-koolproxyR
cp -r -f $GITHUB_WORKSPACE/Customize/koolproxy ./package/lean/koolproxy
cp -r -f $GITHUB_WORKSPACE/Customize/luci-app-gpsysupgrade ./package/lean/luci-app-gpsysupgrade
cp -f $GITHUB_WORKSPACE/Customize/config-5.4 ./target/linux/x86/config-5.4
chmod -R 755 ./package/lean/luci-app-koolproxyR
chmod -R 755 ./package/lean/koolproxy
chmod -R 755 ./package/lean/luci-app-dockerman
# chmod -R 755 ./package/base-files/files/bin/AutoUpdate.sh
mv ./package/lean/luci-app-eqos/po/zh_Hans ./package/lean/luci-app-eqos/po/zh-cn
# sed -i 's/bash/sh/g' ./package/lean/luci-app-autoupdate/root/etc/init.d/autoupdate
# sed -i 's/"定时更新"/"系统定时更新"/g' ./package/lean/luci-app-autoupdate/po/zh-cn/autoupdate.po

echo "Author: $Author"
echo "Openwrt Version: $Openwrt_Version"
echo "AutoUpdate Version: $AutoUpdate_Version"
echo "Device: $TARGET_PROFILE"
sed -i "s?$Lede_Version?$Lede_Version Compiled by $Author [$Compile_Date]?g" $Default_File
echo "$Openwrt_Version" > ./package/base-files/files/etc/openwrt_info
sed -i "s?Openwrt?Openwrt $Openwrt_Version / AutoUpdate $AutoUpdate_Version?g" ./package/base-files/files/etc/banner

}

Diy-Part3() {
GET_TARGET_INFO
Default_Firmware_EFI=openwrt-$TARGET_BOARD-$TARGET_SUBTARGET-$TARGET_PROFILE-squashfs-combined-efi.img.gz
AutoBuild_Firmware_EFI=AutoBuild-$TARGET_PROFILE1-Lede-${Openwrt_Version}-efi.img.gz
AutoBuild_Detail_EFI=AutoBuild-$TARGET_PROFILE1-Lede-${Openwrt_Version}-efi.detail
Default_Firmware=openwrt-$TARGET_BOARD-$TARGET_SUBTARGET-$TARGET_PROFILE-squashfs-combined.img.gz
AutoBuild_Firmware=AutoBuild-$TARGET_PROFILE1-Lede-${Openwrt_Version}.img.gz
AutoBuild_Detail=AutoBuild-$TARGET_PROFILE1-Lede-${Openwrt_Version}.detail
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
