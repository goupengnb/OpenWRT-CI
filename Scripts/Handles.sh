#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

PKG_PATH="$GITHUB_WORKSPACE/wrt/package/"

#=========OpenClash Meta 内核预置=========
#OpenClash 本体不带内核，首次运行需要联网下载 mihomo(meta) 内核。
#这里在编译阶段就把 arm64 的 meta 内核塞进包里，刷完机开机即可用。
#下载失败也不中断编译（OpenClash 界面里本身就有"内核更新"按钮可以补）。
OC_CORE_DIR=$(find "$PKG_PATH" -maxdepth 2 -type d -name "luci-app-openclash" 2>/dev/null | head -n 1)
if [ -n "$OC_CORE_DIR" ]; then
	CORE_DIR="$OC_CORE_DIR/root/etc/openclash/core"
	mkdir -p "$CORE_DIR"
	if curl -fsSL --retry 3 --retry-delay 3 -o /tmp/clash-meta.tar.gz \
		"https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-arm64.tar.gz"; then
		if tar -zxf /tmp/clash-meta.tar.gz -C "$CORE_DIR" 2>/dev/null && [ -f "$CORE_DIR/clash" ]; then
			mv -f "$CORE_DIR/clash" "$CORE_DIR/clash_meta"
			chmod +x "$CORE_DIR/clash_meta"
			echo "OpenClash meta core preinstalled."
		else
			echo "warning: unpack OpenClash meta core failed, skip"
		fi
	else
		echo "warning: download OpenClash meta core failed, skip (可在界面里手动更新内核)"
	fi
	rm -f /tmp/clash-meta.tar.gz
else
	echo "warning: luci-app-openclash not found, skip core preinstall"
fi

#=========AdGuardHome=========
#已改用官方 packages 源的 adguardhome + luci-app-adguardhome，
#内核由官方包自己从 AdGuardTeam/AdGuardHome 拉源码编译，不需要额外预置。
echo "Handles.sh: AdGuardHome 使用官方包，无需预置内核。"