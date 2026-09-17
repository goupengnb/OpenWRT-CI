#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

PKG_PATH="$GITHUB_WORKSPACE/wrt/package/"

#=========HomeProxy 首次开机默认值=========
#HomeProxy 内核是 sing-box，来自官方 packages feed，本身不需要预置任何东西，
#但它自带的默认配置里 lan_proxy_mode='disabled'，含义是【不代理任何内网设备】：
#路由器自己走代理，你电脑和手机根本不进代理，很容易被误以为"装了没生效"。
#这里往包里塞一个 uci-defaults 脚本（luci.mk 会把包里的 root/ 整个装进固件，
#/etc/uci-defaults/ 下的脚本由首次开机由 /etc/init.d/boot 执行一次），
#把默认值改成"仅允许列表外 + 直连列表留空"，等于内网设备全部走代理。
#节点没法预设（要你自己填一个），routing_mode 保持上游默认的 bypass_mainland_china（大陆直连）。
HP_DIR=$(find "$PKG_PATH" -maxdepth 2 -type d -name "homeproxy" 2>/dev/null | head -n 1)
if [ -n "$HP_DIR" ]; then
	HP_UD_DIR="$HP_DIR/root/etc/uci-defaults"
	mkdir -p "$HP_UD_DIR"
	cat > "$HP_UD_DIR/zz-homeproxy-lan-proxy" <<'EOF'
#!/bin/sh
#内网设备全部走代理（上游默认是 disabled = 谁都不代理）
uci -q get homeproxy.control.lan_proxy_mode >/dev/null && {
	uci -q set homeproxy.control.lan_proxy_mode='except_listed'
	uci -q commit homeproxy
}
exit 0
EOF
	chmod 0755 "$HP_UD_DIR/zz-homeproxy-lan-proxy"
	echo "HomeProxy: 默认 lan_proxy_mode 已改为 except_listed（内网设备全部走代理）"
else
	echo "warning: homeproxy package not found, skip uci-defaults"
fi

#=========AdGuardHome=========
#已改用官方 packages 源的 adguardhome + luci-app-adguardhome，
#内核由官方包自己从 AdGuardTeam/AdGuardHome 拉源码编译，不需要额外预置。
echo "Handles.sh: AdGuardHome 使用官方包，无需预置内核。"
