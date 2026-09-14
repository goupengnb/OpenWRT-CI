#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

#==========LuCI 主题：把 luci-light 依赖的 luci-theme-bootstrap 换成 WRT_THEME==========
COLLECTION_MAKEFILES=$(find ./feeds/luci/collections/ -type f -name "Makefile" 2>/dev/null)
if [ -n "$COLLECTION_MAKEFILES" ]; then
	sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $COLLECTION_MAKEFILES
else
	echo "warning: luci collections not found, skip theme patch"
fi

#==========LuCI 小修补（按官方 25.12 路径；找不到就跳过，不影响编译）==========
#概览/登录页显示的默认 IP
FLASH_JS=$(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js" 2>/dev/null)
if [ -n "$FLASH_JS" ]; then
	sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $FLASH_JS
else
	echo "warning: flash.js not found, skip ip patch"
fi
#页脚的编译标记
STATUS_JS=$(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js" 2>/dev/null)
if [ -n "$STATUS_JS" ]; then
	sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $STATUS_JS
else
	echo "warning: 10_system.js not found, skip version patch"
fi

#==========内核小优化：打开 fq 队列（BBR 建议的搭配）==========
#官方 generic 内核配置里是 "# CONFIG_NET_SCH_FQ is not set"，而 OpenWrt 上游并没有对应的
#kmod 包（kmod-sched-core 里不含 sch_fq），所以在 rockchip 的内核 config 里补一行。
#OpenWrt 会用 generic + subtarget 两份 config 合成内核配置，subtarget 这份后应用（优先级更高）。
#写成内置（=y）而不是模块，避免出现“编出来但没有 kmod 包收编”的模块。
for KCONF in ./target/linux/rockchip/config-* ./target/linux/rockchip/*/config-*; do
	[ -f "$KCONF" ] || continue
	if grep -q 'CONFIG_NET_SCH_FQ' "$KCONF"; then
		echo "kernel config $KCONF already mentions NET_SCH_FQ, skip"
	else
		echo 'CONFIG_NET_SCH_FQ=y' >> "$KCONF"
		echo "kernel config $KCONF: appended CONFIG_NET_SCH_FQ=y"
	fi
done
#==========无线默认值（首次开机生成 /etc/config/wireless）==========
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_UC" ]; then
	#WIFI名称
	sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" $WIFI_UC
	#WIFI密码
	sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
	#加密方式
	sed -i "s/encryption='.*'/encryption='psk2+ccmp'/g" $WIFI_UC
	#国家代码
	sed -i "s/country='.*'/country='CN'/g" $WIFI_UC
	#R5C 没有板载无线网卡，官方脚本对这类设备默认生成 disabled=1，这里改成开机即启用
	sed -i "s/disabled='.*'/disabled='0'/g" $WIFI_UC
else
	echo "warning: mac80211.uc not found, skip wifi defaults"
fi

#==========默认 IP / 主机名==========
CFG_FILE="./package/base-files/files/bin/config_generate"
if [ -f "$CFG_FILE" ]; then
	sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
	sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE
else
	echo "warning: config_generate not found, skip ip/hostname patch"
fi

#==========写入 .config（在 make defconfig 之前生效）==========
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config

#引入私有扩展配置
if [ -f "$GITHUB_WORKSPACE/Config/PRIVATE.txt" ]; then
	echo "Applying private configurations from PRIVATE.txt..."
	cat $GITHUB_WORKSPACE/Config/PRIVATE.txt >> ./.config
fi

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

#==========修改ssh登录信息==========
>package/base-files/files/etc/banner
echo -e ' ██████╗  ██████╗ ██╗   ██╗██████╗ ███████╗███╗   ██╗ ██████╗ ' >> package/base-files/files/etc/banner
echo -e '██╔════╝ ██╔═══██╗██║   ██║██╔══██╗██╔════╝████╗  ██║██╔════╝ ' >> package/base-files/files/etc/banner
echo -e '██║  ███╗██║   ██║██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║  ███╗' >> package/base-files/files/etc/banner
echo -e '██║   ██║██║   ██║██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██║   ██║' >> package/base-files/files/etc/banner
echo -e '╚██████╔╝╚██████╔╝╚██████╔╝██║     ███████╗██║ ╚████║╚██████╔╝' >> package/base-files/files/etc/banner
echo -e ' ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝ ╚═════╝ \n' >> package/base-files/files/etc/banner

#注：这里原本还会给 ttyd 打补丁改成免密自动 root 登录（/bin/login -f root），
#    那等于在局域网上开了一个 root 后门，已移除；LuCI 的「终端」页面自带登录鉴权，不受影响。
