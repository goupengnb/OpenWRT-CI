# OpenWRT-CI（友善 NanoPi R5C 专用）

本仓库是 [goupengnb/OpenWRT-CI](https://github.com/goupengnb/OpenWRT-CI) 的 R5C 专用版本：

- **只编译友善 NanoPi R5C 一个设备**（不编译其它任何机型）
- 源码：**OpenWrt 官方** https://github.com/openwrt/openwrt.git（`openwrt-25.12` 稳定分支）
- 插件：**只用 OpenWrt 官方在维护的 feeds**（base / packages / luci / routing），不引入任何第三方插件源
- 每天 05:00（北京时间）自动编译，也可以在 Actions 页面手动触发

# 设备信息（NanoPi R5C）

| 项目 | 参数 | 对应的软件包 |
| --- | --- | --- |
| SoC | Rockchip RK3568B2（4×Cortex-A55） | 内核 6.12 |
| 内存 | 4GB LPDDR4X | — |
| 存储 | 32GB eMMC + microSD 卡槽 | 内核内建（MMC_DW_ROCKCHIP=y） |
| 网口 | 2× 2.5Gbps（RTL8125B） | `kmod-r8169`（官方设备定义即用内核驱动） |
| 无线 | M.2 E-Key（PCIe）插槽 | 你的网卡是 **MT7921**：`kmod-mt7921e` + `kmod-mt7921-firmware`；同时保留官方默认的 RTL8822CE（`kmod-rtw88-8822ce` + `rtl8822ce-firmware`）兼容原厂模块 |
| USB | 2× USB 3.2 Gen1 | 内核内建（USB_DWC3=y、USB_XHCI_HCD=y） |
| 显示 | HDMI | 内核内建（drm/panfrost 都在 rockchip 内核里，不是独立 kmod） |
| 按键/灯 | Reset 按键、lan/power/heartbeat/wan/wlan 指示灯 | `kmod-gpio-button-hotplug`（官方默认） |

> 说明：R5C **没有板载 WiFi**，无线只能来自 M.2 E-Key 插槽里插的模块，因此固件里同时带 MT7921 和 RTL8822CE 两套驱动，插哪种都能用。

# 固件说明

- 两种镜像：
  - `*-squashfs-sysupgrade.img.gz` —— 只读系统 + 可写 overlay，**日常推荐**（能一键恢复出厂）
  - `*-ext4-sysupgrade.img.gz` —— 整分区可写，方便 `resize2fs` 把剩余空间吃满
- 分区布局：`32M 对齐（u-boot idbloader+ITB）` + `boot 64M` + `rootfs 2048M`，剩余空间留给 eMMC 自己分区
- 默认参数：
  - 主机名：`狗鹏`
  - 管理地址：`192.168.1.1`
  - WiFi：`狗鹏` / `12345678`（地区 CN，`psk2+ccmp`，**首次开机即启用**）
  - 登录密码：无（买来是新机器，第一次进 LuCI 请自己设置密码）
- 主题：`luci-theme-openwrt-2020`（官方 luci 仓库，2026 年仍在维护）

# 刷机方法

1. 到本仓库 **Releases** 下载对应镜像（`nanopi-r5c` 开头的文件）。
2. **写 SD 卡**：用 BalenaEtcher / Rufus（DD 模式）/ `dd` 直接写整卡；
   **写 eMMC**：把 R5C 的 eMMC 通过 USB 读卡器（或用 Maskrom/loader 模式）
   接到电脑再 `dd`，也可以在已经能用的系统里直接 `sysupgrade`：
   ```sh
   sysupgrade -n openwrt-25.12.x-rockchip-armv8-friendlyarm_nanopi-r5c-squashfs-sysupgrade.img.gz
   ```
3. 首次开机约 1~2 分钟，网口 1（LAN）地址 `192.168.1.1`。
4. **剩余 eMMC 空间扩容**（可选，装 Docker 镜像用）：
   ```sh
   parted -s /dev/mmcblk0 mkpart primary ext4 <rootfs 结束位置> 100%
   mkfs.ext4 -L data /dev/mmcblk0p3
   # 然后在 LuCI 的「系统 - 挂载点」里把 /dev/mmcblk0p3 挂到 /mnt/data 或 /opt
   ```

# 插件清单（全部来自 OpenWrt 官方 feeds）

- **LuCI**：`luci`、`luci-ssl`(HTTPS)、`luci-compat`、简体中文、`luci-theme-openwrt-2020`、`luci-app-firewall`、`luci-app-package-manager`、`luci-app-attendedsysupgrade` + `owut`（在线升级）、`luci-app-commands`、`luci-app-ttyd`（网页终端）、`luci-app-filemanager`（网页文件管理）、`luci-app-nlbwmon`（流量统计）、`luci-app-irqbalance`、`luci-app-hd-idle`
- **系统工具**：bash、nano、htop、curl、wget-ssl、rsync、ca-certificates、openssl-util、ip-full、ethtool、pciutils（lspci 看 M.2 网卡）、usbutils、iperf3、tcpdump、openssh-keygen、openssh-sftp-server、zoneinfo-core/asia
- **存储 / USB**：block-mount、blkid、lsblk、fdisk、sfdisk、parted、e2fsprogs、dosfstools、f2fs-tools、btrfs-progs、kmod-fs-vfat/exfat/ntfs3/btrfs/cifs、cifsmount、exfat-mkfs/fsck、kmod-usb-storage(+uas)、kmod-usb-net-rtl8152（USB 2.5G 网卡）、smartmontools、hdparm
- **DNS**：`dnsmasq-full`（带 DNSSEC/nftset，替换精简版 dnsmasq）、AdGuard Home（`adguardhome` + `luci-app-adguardhome`，官方源版本）、SmartDNS、https-dns-proxy（DoH）
- **网络服务**：DDNS（`luci-app-ddns` + `ddns-scripts-services` + `ddns-scripts-cloudflare`）、UPnP（`miniupnpd-nftables`）、网络唤醒（`luci-app-wol` + etherwake）、SQM 智能队列（`luci-app-sqm` + `sqm-scripts`）
- **代理 / VPN**：v2rayA（`luci-app-v2raya` + `v2raya` + `xray-core`）、PBR 策略路由、OpenVPN、WireGuard（`luci-proto-wireguard`）、Tailscale（`tailscale` + `luci-app-tailscale-community`）
- **文件共享**：Samba4（`samba4-server` + `luci-app-samba4`）、vsftpd
- **Docker**：`luci-app-dockerman` + `dockerd` + `docker` + `docker-compose`
- **内核/网络加速**：`kmod-tcp-bbr` + `net.sch_fq`（BBR）、`kmod-veth`、`kmod-br-netfilter`、`kmod-tun`、`kmod-wireguard`、`kmod-nf-nat6`、`kmod-nft-tproxy/socket/fib`、`wpad-openssl`

# 已替换掉的第三方插件

| 原来（第三方源） | 现在（官方源） |
| --- | --- |
| argon 主题（sbwml） | `luci-theme-openwrt-2020`（官方 luci） |
| OpenClash + Meta 内核（vernesong） | `luci-app-v2raya` + `xray-core`（透明代理面板）+ `pbr`（分流） |
| luci-app-ddns-go（sirpdboy） | `luci-app-ddns` + `ddns-scripts-cloudflare`（官方 ddns-scripts） |
| luci-app-diskman（sbwml） | `block-mount` + `parted` + `e2fsprogs` + exfat/ntfs3 全套 |
| 魔改 luci-app-adguardhome（goupengnb） | 官方 `adguardhome` + `luci-app-adguardhome` |
| `CONFIG_PACKAGE_ipv6helper`（immortalwrt 专有包） | 官方源没有这个包，删除（IPv6 由 odhcp6c/odhcpd + luci-proto-ipv6 提供） |

# 目录说明

- `.github/workflows` —— CI 配置（`R5C.yml` 编译入口 + `WRT-CORE.yml` 公用核心 + `Auto-Clean.yml` / `Cache-Clean.yml` 清理）
- `Config/R5C.txt` —— 设备 / 内核 / 网卡配置（只编译 R5C）
- `Config/GENERAL.txt` —— 业务插件配置（全部官方源）
- `Scripts/Settings.sh` —— 主题、默认主机名/IP、默认 WiFi 等系统级修改
- `Scripts/Packages.sh` —— 需要时在官方仓库之间替换包版本（当前没有启用任何替换）
- `Scripts/Handles.sh` —— 预留的空实现（第三方内核预置已全部移除）

# 手动编译

Actions 页面选择 **R5C** workflow → Run workflow：

- `PACKAGE`：临时追加插件包（`CONFIG_PACKAGE_xxx=y`），多个用 `\n` 分隔
- `TEST`：勾选后只输出配置文件不编译固件（**改完 Config 建议先跑一次 TEST**）

# 说明

- 本固件由 GitHub Actions 云编译生成，本机（Windows）不需要搭建 Linux 编译环境；
  如果想本地编译，需要 Linux/WSL2（Ubuntu）或 Docker，按 [OpenWrt 官方文档](https://openwrt.org/docs/guide-developer/toolchain/install-buildsystem) 装依赖后
  `cp Config/R5C.txt Config/GENERAL.txt .config` 再 `make defconfig` 即可。
- 安全说明：原脚本会把 ttyd 改成免密自动 root 登录（等于局域网 root 后门），本版本已移除；
  同时把 `wpad-basic-mbedtls` 换成 `wpad-openssl`，支持 WPA3-SAE / 802.11r / OWE。
