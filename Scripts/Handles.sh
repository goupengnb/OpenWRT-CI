#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

#这里原本用于预置第三方内核文件：
#  * OpenClash Meta 内核（vernesong/OpenClash）
#  * 魔改版 luci-app-adguardhome 的 AdGuardHome 内核
#
#现在所有插件都来自 OpenWrt 官方 feeds，不再需要手工塞内核：
#  * adguardhome（官方 packages 源）自己会从 AdGuard 官方 release 获取/编译内核
#  * v2rayA 依赖官方 xray-core，由 feed 直接编译
#
#因此本脚本保留为空实现，作为以后需要打补丁时的挂载点。

echo "Handles.sh: nothing to do - all packages come from official OpenWrt feeds."
