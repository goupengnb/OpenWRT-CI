#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY




echo "====【HANDLES调试启动】当前路径:$(pwd)===="
# 测试1：判断ADG插件目录是否存在
ADG_CHECK=feeds/luci/applications/luci-app-adguardhome
if [ -d ${ADG_CHECK} ];then
    echo "✅【调试】ADG插件目录真实存在:${ADG_CHECK}"
    # 在插件root/bin生成标记文件
    TEST_DIR=${ADG_CHECK}/root/usr/bin
    mkdir -p ${TEST_DIR}
    echo "test_write_ok" > ${TEST_DIR}/debug.tag
    echo "✅【调试】已写入标记文件:${TEST_DIR}/debug.tag"
else
    echo "❌【调试】ADG插件目录不存在"
fi




PKG_PATH="$GITHUB_WORKSPACE/wrt/package/"


#=========AdGuardHome 核心预置=========
if [ -d "luci-app-adguardhome" ];then
    ARCH=arm64
    CORE_DIR=luci-app-adguardhome/luci-app-adguardhome/root/usr/bin
    mkdir -p ${CORE_DIR}
    cd ${CORE_DIR}
    curl -sfLO https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_${ARCH}.tar.gz
    tar -xf AdGuardHome_linux_${ARCH}.tar.gz AdGuardHome/AdGuardHome --strip-components=2
    chmod +x AdGuardHome
    rm -f *.tar.gz
    cd $PKG_PATH
fi




#=========OpenClash 核心预置=========
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
