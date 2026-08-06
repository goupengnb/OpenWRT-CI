#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

PKG_PATH="$GITHUB_WORKSPACE/wrt/package/"


#=========AdGuardHome 核心预置=========
if [ -d "luci-app-adguardhome" ];then
    ARCH=arm64
    CORE_DIR=luci-app-adguardhome/root/etc/AdGuardHome/core
    mkdir -p ${CORE_DIR}
    cd ${CORE_DIR}
    curl -sfLO https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_${ARCH}.tar.gz
    tar -xf AdGuardHome_linux_${ARCH}.tar.gz ./AdGuardHome/AdGuardHome --strip-components=2
    chmod +x AdGuardHome
    rm -f *.tar.gz
    cd $PKG_PATH
fi


#=========OpenClash Meta预置=========
if [ -d *"luci-app-openclash"* ];then
ARCH=arm64
CORE_DIR=luci-app-openclash/root/etc/openclash/core
mkdir -p ${CORE_DIR}
cd ${CORE_DIR}
curl -sfLO https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-${ARCH}.tar.gz
tar -zxf clash-linux-${ARCH}.tar.gz
mv clash clash_meta
chmod +x clash_meta
rm -f *.tar.gz
cd $PKG_PATH
fi
