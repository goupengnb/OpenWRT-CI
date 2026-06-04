#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

PKG_PATH="$GITHUB_WORKSPACE/wrt/package/"


# ====== 1、AdGuardHome 独立区块（单独架构判断）======
if [ -d "luci-app-adguardhome" ];then
    case "${ARCH}" in
    x86_64)
        AGH_ARCH="amd64"
        ;;
    aarch64)
        AGH_ARCH="arm64"
        ;;
    *)
        echo "AdGuardHome：架构${ARCH}不支持，跳过下载"
        ;;
    esac

    if [ -n "${AGH_ARCH}" ];then
        CORE_DIR=luci-app-adguardhome/root/usr/bin/AdGuardHome
        mkdir -p ${CORE_DIR}
        cd ${CORE_DIR}
        curl -sfLO https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_${AGH_ARCH}.tar.gz
        tar -xf AdGuardHome_linux_${AGH_ARCH}.tar.gz ./AdGuardHome/AdGuardHome --strip-components=2
        chmod +x AdGuardHome
        rm -f *.tar.gz
        cd $PKG_PATH
    fi
fi

# ====== 2、OpenClash Meta 独立区块（单独架构判断）======
if [ -d "luci-app-openclash" ];then
    case "${ARCH}" in
    x86_64)
        OC_ARCH="amd64"
        ;;
    aarch64)
        OC_ARCH="arm64"
        ;;
    *)
        echo "OpenClash：架构${ARCH}不支持，跳过下载"
        ;;
    esac

    if [ -n "${OC_ARCH}" ];then
        CORE_DIR=luci-app-openclash/root/etc/openclash/core
        mkdir -p ${CORE_DIR}
        cd ${CORE_DIR}
        curl -sfLO https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-${OC_ARCH}.tar.gz
        tar -zxf clash-linux-${OC_ARCH}.tar.gz
        mv clash clash_meta
        chmod +x clash_meta
        rm -f *.tar.gz
        cd $PKG_PATH
    fi
fi



#修改mini-diskmanager菜单位置
if [ -d *"luci-app-mini-diskmanager"* ]; then
	echo " " && cd ./luci-app-mini-diskmanager/

	sed -i "s/services/system/g" ./luci-app-mini-diskmanager/root/usr/share/luci/menu.d/luci-app-mini-diskmanager.json

	cd $PKG_PATH && echo "mini-diskmanager has been fixed!"
fi

#修复TailScale配置文件冲突
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
if [ -f "$TS_FILE" ]; then
	echo " "

	sed -i '/\/files/d' $TS_FILE

	cd $PKG_PATH && echo "tailscale has been fixed!"
fi

#修复Rust编译失败
RUST_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
if [ -f "$RUST_FILE" ]; then
	echo " "

	sed -i 's/ci-llvm=true/ci-llvm=false/g' $RUST_FILE

	cd $PKG_PATH && echo "rust has been fixed!"
fi
