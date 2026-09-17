#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

#=============================================================================
#插件来源规则
#  1. OpenWrt 官方 feeds（base / packages / luci / routing）里有的插件，一律用官方的；
#  2. 官方确实没有的，才从第三方仓库拉，且只挑【原作者仍在维护】的仓库；
#  3. 所有第三方仓库都在下面列出，改版本/换来源只需要改这里的几行。
#
#当前需要第三方的插件（官方 25.12.5 索引里逐个确认过，确实不存在）：
#  luci-theme-argon / luci-app-argon-config   jerrykuku      原作者，持续更新
#  luci-app-homeproxy                         immortalwrt    ImmortalWrt 官方团队，sing-box 内核
#  luci-app-diskman                           sbwml          1.0.0 重写版，作者本人维护
#  luci-app-ddns-go + ddns-go                 sirpdboy       原作者，持续更新
#=============================================================================

#替换/新增第三方软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local PKG_LIST=("$PKG_NAME" $5)  # 第5个参数为自定义名称列表
	local REPO_NAME=${PKG_REPO#*/}
	local CLONE_DIR="upload-${REPO_NAME}"  # 先克隆到中转目录，避免与目标目录重名时互相覆盖

	echo " "

	# 删除 feeds 里可能存在的同名软件包，避免包名冲突
	for NAME in "${PKG_LIST[@]}"; do
		echo "Search directory: $NAME"
		local FOUND_DIRS=$(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)

		if [ -n "$FOUND_DIRS" ]; then
			while read -r DIR; do
				rm -rf "$DIR"
				echo "Delete directory: $DIR"
			done <<< "$FOUND_DIRS"
		else
			echo "Not fonud directory: $NAME"
		fi
	done

	# 克隆 GitHub 仓库到中转目录
	rm -rf "$CLONE_DIR"
	if ! git clone --depth=1 --single-branch --branch "$PKG_BRANCH" "https://github.com/$PKG_REPO.git" "$CLONE_DIR"; then
		echo "ERROR: git clone failed: $PKG_REPO ($PKG_BRANCH)"
		return 1
	fi

	# 处理克隆下来的仓库
	if [[ "$PKG_SPECIAL" == "pkg" ]]; then
		#从大杂烩仓库里单独提取目标插件目录
		#-mindepth 1：排除中转目录本身（它的名字里也带目标插件名，会被 -prune 掉导致什么都没提取出来）
		find "./$CLONE_DIR" -mindepth 1 -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./ \;
	elif [[ "$PKG_SPECIAL" == "name" ]]; then
		#把仓库重命名为指定的包名
		rm -rf "$PKG_NAME"
		mv -f "$CLONE_DIR" "$PKG_NAME"
	else
		#保持仓库原名（仓库根目录本身就是插件）
		rm -rf "$REPO_NAME"
		mv -f "$CLONE_DIR" "$REPO_NAME"
	fi

	rm -rf "$CLONE_DIR"
}

# 调用格式：
# UPDATE_PACKAGE "包名" "项目地址" "项目分支" "pkg/name，可选；pkg=从大杂烩仓库里单独提取；name=重命名为包名"
#
# 注意：这里只放【官方 feeds 里没有】的插件。

#Argon 主题 + 主题设置面板（作者 jerrykuku，2026 年仍在维护）
UPDATE_PACKAGE "luci-theme-argon" "jerrykuku/luci-theme-argon" "master"
UPDATE_PACKAGE "luci-app-argon-config" "jerrykuku/luci-app-argon-config" "master"

#HomeProxy（sing-box 系代理面板，ImmortalWrt 官方团队维护；仓库根目录就是包本体）
#内核 sing-box 来自【官方 packages feed】（25.12 是 1.13.x），不需要第三方
UPDATE_PACKAGE "homeproxy" "immortalwrt/homeproxy" "master"

#DiskMan 磁盘管理（sbwml 重写的 1.0.0 版，ucode 实现，适配 25.12/apk）
UPDATE_PACKAGE "diskman" "sbwml/luci-app-diskman" "main"

#ddns-go（作者 sirpdboy；仓库里含 ddns-go 主程序和 luci-app-ddns-go 两个包）
UPDATE_PACKAGE "ddns-go" "sirpdboy/luci-app-ddns-go" "main"

#引入私有扩展脚本
if [ -f "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh" ]; then
	source "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh"
fi
