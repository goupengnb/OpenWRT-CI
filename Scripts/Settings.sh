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

#==========默认队列改成 fq（配合 BBR）==========
#上面把 fq 队列编进了内核，但 OpenWrt 默认队列是 fq_codel（generic config 里是
#CONFIG_DEFAULT_FQ_CODEL=y），不设 sysctl 的话编进去的 fq 没人用。
#写进 base-files，随固件落到 /etc/sysctl.d/，开机由 /etc/init.d/sysctl 统一加载。
QDISC_CONF="./package/base-files/files/etc/sysctl.d/13-default-qdisc.conf"
mkdir -p "$(dirname "$QDISC_CONF")"
echo 'net.core.default_qdisc=fq' > "$QDISC_CONF"
echo "default qdisc: fq ($QDISC_CONF)"

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

#==========关掉 Ruby 的 YJIT（防止白白编译 3 小时 rust 编译器）==========
#官方 feeds 的 lang/ruby/Makefile 里写着：
#    PKG_BUILD_DEPENDS:=ruby/host RUBY_ENABLE_YJIT:rust/host
#    config RUBY_ENABLE_YJIT / default y if x86_64||aarch64
#R5C 是 aarch64，所以默认会把 rust 编译器(host)也拉进来从源码编译，实测 3 小时以上都跑不完，
#最后顶到 GitHub 的 6 小时上限被硬杀。上游自己都标注了 YJIT 不支持交叉编译。
#ruby 是 OpenClash 的依赖，删不掉，只能把 JIT 关掉。
echo "# CONFIG_RUBY_ENABLE_YJIT is not set" >> ./.config

#双保险：万一 Kconfig 又把 YJIT 打开，就直接把 rust 编译依赖摘掉，杜绝那 3 小时
RUBY_MAKEFILE="./feeds/packages/lang/ruby/Makefile"
if [ -f "$RUBY_MAKEFILE" ] && grep -q "RUBY_ENABLE_YJIT:rust/host" "$RUBY_MAKEFILE"; then
	sed -i "s|RUBY_ENABLE_YJIT:rust/host||g" "$RUBY_MAKEFILE"
	echo "ruby: 已摘除 rust/host 编译依赖（不会再从源码编译 rust）"
fi

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
