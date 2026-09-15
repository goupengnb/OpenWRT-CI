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
#  luci-app-openclash                         vernesong      dev 分支持续更新
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
		#-mindepth 1：排除中转目录本身（它的名字里也带 openclash，会被 -prune 掉导致什么都没提取出来）
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

#OpenClash（作者 vernesong，dev 分支持续更新；主程序在仓库的 luci-app-openclash 目录下）
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"

#DiskMan 磁盘管理（sbwml 重写的 1.0.0 版，ucode 实现，适配 25.12/apk）
UPDATE_PACKAGE "diskman" "sbwml/luci-app-diskman" "main"

#ddns-go（作者 sirpdboy；仓库里含 ddns-go 主程序和 luci-app-ddns-go 两个包）
UPDATE_PACKAGE "ddns-go" "sirpdboy/luci-app-ddns-go" "main"


#更新软件包版本
UPDATE_VERSION() {
	local PKG_NAME=$1
	local PKG_MARK=${2:-false}
	local PKG_FILES=$(find ./ ../feeds/packages/ -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")

	if [ -z "$PKG_FILES" ]; then
		echo "$PKG_NAME not found!"
		return
	fi

	echo -e "\n$PKG_NAME version update has started!"

	for PKG_FILE in $PKG_FILES; do
		local PKG_REPO=$(grep -Po "PKG_SOURCE_URL:=https://.*github.com/\K[^/]+/[^/]+(?=.*)" $PKG_FILE)
		local PKG_TAG=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" | jq -r "map(select(.prerelease == $PKG_MARK)) | first | .tag_name")

		local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")
		local OLD_URL=$(grep -Po "PKG_SOURCE_URL:=\K.*" "$PKG_FILE")
		local OLD_FILE=$(grep -Po "PKG_SOURCE:=\K.*" "$PKG_FILE")
		local OLD_HASH=$(grep -Po "PKG_HASH:=\K.*" "$PKG_FILE")

		local PKG_URL=$([[ "$OLD_URL" == *"releases"* ]] && echo "${OLD_URL%/}/$OLD_FILE" || echo "${OLD_URL%/}")

		local NEW_VER=$(echo $PKG_TAG | sed -E 's/[^0-9]+/\./g; s/^\.|\.$//g')
		local NEW_URL=$(echo $PKG_URL | sed "s/\$(PKG_VERSION)/$NEW_VER/g; s/\$(PKG_NAME)/$PKG_NAME/g")
		local NEW_HASH=$(curl -sL "$NEW_URL" | sha256sum | cut -d ' ' -f 1)

		echo "old version: $OLD_VER $OLD_HASH"
		echo "new version: $NEW_VER $NEW_HASH"

		if [[ "$NEW_VER" =~ ^[0-9].* ]] && dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
			sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
			sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
			echo "$PKG_FILE version has been updated!"
		else
			echo "$PKG_FILE version is already the latest!"
		fi
	done
}

#UPDATE_VERSION "软件包名" "测试版，true，可选，默认为否"

#引入私有扩展脚本
if [ -f "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh" ]; then
	source "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh"
fi