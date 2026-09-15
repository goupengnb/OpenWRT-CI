# OpenWRT-CI（友善 NanoPi R5C 专用）

本仓库是 [goupengnb/OpenWRT-CI](https://github.com/goupengnb/OpenWRT-CI) 的 R5C 专用版本：

- **只编译友善 NanoPi R5C 一个设备**（不编译其它任何机型）
- 源码：**OpenWrt 官方** https://github.com/openwrt/openwrt.git（`openwrt-25.12` 稳定分支）
- 插件来源规则：**官方 feeds（base / packages / luci / routing）里有的，一律用官方的；
  官方确实没有的，用原作者仍在维护的第三方仓库**（清单见下表，逐个核对过 25.12.5 官方索引）
- 每天 05:00（北京时间）自动编译，也可以在 Actions 页面手动触发

# 设备信息（NanoPi R5C）

| 项目 | 参数 | 对应的软件包 |
| --- | --- | --- |
| SoC | Rockchip RK3568B2（4×Cortex-A55） | 内核 6.12 |
| 内存 | 4GB LPDDR4X | — |
| 存储 | 32GB eMMC + microSD 卡槽 | 内核内建（MMC_DW_ROCKCHIP=y） |
| 网口 | 2× 2.5Gbps（RTL8125B） | `kmod-r8169`（官方设备定义即用内核驱动） |
| 无线 | M.2 E-Key（PCIe）插槽 | 网卡是 **MT7921**：`kmod-mt7921e` + `kmod-mt7921-firmware`；同时保留官方默认的 RTL8822CE（`kmod-rtw88-8822ce` + `rtl8822ce-firmware`）兼容原厂模块 |
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
- 默认主题：**Argon**（第三方，主题包自带 uci-defaults 会自动把默认主题设成它）；
  同时装了官方 `luci-theme-openwrt-2020` 兜底，Argon 万一异常也能进界面

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

# 插件来源

**官方 feeds 里没有、只能从第三方获取的插件**（都已确认上游作者仍在维护）：

| 插件 | 来源仓库 | 分支 | 说明 |
| --- | --- | --- | --- |
| `luci-theme-argon`、`luci-app-argon-config` | [jerrykuku/luci-theme-argon](https://github.com/jerrykuku/luci-theme-argon)、[luci-app-argon-config](https://github.com/jerrykuku/luci-app-argon-config) | `master` | Argon 主题原作者，2026-09 仍在提交；主题 2.4.7、设置面板 1.0 |
| `luci-app-openclash` | [vernesong/OpenClash](https://github.com/vernesong/OpenClash) | `dev` | 官方 feed 无；`dev` 为作者持续更新的分支（0.47.164）；编译时会把 mihomo(meta) 内核一并塞进包里 |
| `luci-app-diskman` | [sbwml/luci-app-diskman](https://github.com/sbwml/luci-app-diskman) | `main` | 官方 feed 无；作者重写的 1.0.0 版（ucode 实现，适配 25.12/apk） |
| `luci-app-ddns-go`、`ddns-go` | [sirpdboy/luci-app-ddns-go](https://github.com/sirpdboy/luci-app-ddns-go) | `main` | 官方 feed 无；原作者仍在维护 |

**其余插件全部来自 OpenWrt 官方 feeds。** 其中 AdGuard Home 官方源已经有官方维护的
`adguardhome` + `luci-app-adguardhome`，所以不再使用第三方魔改版。

# 插件清单

- **LuCI**：`luci`、`luci-ssl`(HTTPS)、`luci-compat` + `luci-lua-runtime`（OpenClash 用旧式 Lua 页面，需要这两个）、简体中文、**Argon 主题 + 设置面板（第三方）**、`luci-theme-openwrt-2020`（官方兜底）、`luci-app-firewall`、`luci-app-package-manager`、`luci-app-attendedsysupgrade` + `owut`（在线升级）、`luci-app-commands`、`luci-app-ttyd`（网页终端）、`luci-app-filemanager`（网页文件管理）、`luci-app-nlbwmon`（流量统计）、`luci-app-irqbalance`、`luci-app-hd-idle`
- **系统工具**：bash、nano、htop、curl、wget-ssl、rsync、ca-certificates、openssl-util、ip-full、ethtool、pciutils（lspci 看 M.2 网卡）、usbutils、iperf3、tcpdump、openssh-keygen、openssh-sftp-server、zoneinfo-core/asia
- **存储 / USB**：block-mount、blkid、lsblk、fdisk、sfdisk、parted、e2fsprogs、dosfstools、f2fs-tools、btrfs-progs、wipefs、xfs-mkfs、swap-utils、**DiskMan 磁盘管理面板（第三方）**、kmod-fs-vfat/exfat/ntfs3/btrfs/cifs、cifsmount、exfat-mkfs/fsck、kmod-usb-storage(+uas)、kmod-usb-net-rtl8152（USB 2.5G 网卡）、smartmontools、hdparm
- **DNS**：`dnsmasq-full`（带 DNSSEC/nftset，OpenClash 也依赖它）、AdGuard Home（`adguardhome` + `luci-app-adguardhome`，**官方源版本**）、SmartDNS、https-dns-proxy（DoH）
- **网络服务**：DDNS（官方 `luci-app-ddns` + `ddns-scripts-services` + `ddns-scripts-cloudflare`）、**ddns-go + luci-app-ddns-go（第三方）**、UPnP（`miniupnpd-nftables`）、网络唤醒（`luci-app-wol` + etherwake）、SQM 智能队列（`luci-app-sqm` + `sqm-scripts`）
- **代理 / 分流**：**OpenClash（第三方，含 mihomo/meta 内核）**、coreutils-nohup/timeout（OpenClash 的 init 脚本要用）、PBR 策略路由（官方，默认不启用）、OpenVPN、WireGuard（`luci-proto-wireguard`）、Tailscale（`tailscale` + `luci-app-tailscale-community`）
- **文件共享**：Samba4（`samba4-server` + `luci-app-samba4`）、vsftpd
- **Docker**：`luci-app-dockerman` + `dockerd` + `docker` + `docker-compose`
- **内核/网络加速**：`kmod-tcp-bbr`（BBR 拥塞控制）+ 内核打开 `sch_fq` 队列（由 `Scripts/Settings.sh` 给 rockchip 内核配置补一行，因为上游没有对应的 kmod 包）、`kmod-veth`、`kmod-br-netfilter`、`kmod-tun`、`kmod-wireguard`、`kmod-nf-nat6`、`kmod-nft-tproxy/socket/fib`、`wpad-openssl`

# 与原始配置的差异

| 项目 | 原来 | 现在 |
| --- | --- | --- |
| 源码 | immortalwrt（`immortalwrt/immortalwrt` master） | **OpenWrt 官方** `openwrt/openwrt` 的 `openwrt-25.12` 分支 |
| 编译目标 | 整个 rockchip/armv8 平台 | 只编译 `friendlyarm_nanopi-r5c` |
| 主题 | Argon（sbwml 的 fork） | Argon（**原作者 jerrykuku** 的仓库） |
| OpenClash | vernesong `dev` | 同左（保留，仍是官方 feed 没有的） |
| AdGuardHome | 魔改版 `goupengnb/luci-app-adguardhome` | 官方 `adguardhome` + `luci-app-adguardhome` |
| DiskMan | sbwml fork | sbwml 重写的 1.0.0 版（作者本人维护） |
| ddns-go | sirpdboy | 同左 |
| `autocore`、`cpufreq` | immortalwrt 专有包 | 官方源没有，删除 |
| `opkg` / `opkg-conf` | 有 | 25.12 已改用 apk，删除 |
| `kmod-r8125` | 有 | 官方 R5C 设备定义用的就是内核 `r8169`，改用 `kmod-r8169` |
| `kmod-drm-panfrost` / `kmod-drm-rockchip` | 有 | 这两个在 rockchip 内核里是内建的（不是 kmod 包），删除 |
| `kmod-nft-fullcone`、`ipv6helper`、`luci-app-appfilter` 等 | 部分有 | 官方源没有，删除 |
| 第三方包版本更新脚本（`UPDATE_VERSION`，靠 sed 改 Makefile 版本号） | 启用 | 未启用（容易把包改坏，交给上游自己更新） |
| ttyd 免密 root 登录补丁 | 有 | **移除**（等于局域网 root 后门） |

# 目录说明

- `.github/workflows` —— CI 配置（`R5C.yml` 编译入口 + `WRT-CORE.yml` 公用核心 + `Auto-Clean.yml` / `Cache-Clean.yml` 清理）
- `Config/R5C.txt` —— 设备 / 内核 / 网卡配置（只编译 R5C）
- `Config/GENERAL.txt` —— 业务插件配置
- `Scripts/Settings.sh` —— 主题、默认主机名/IP、默认 WiFi、内核 `sch_fq` 等系统级修改
- `Scripts/Packages.sh` —— 从第三方仓库拉取**官方 feed 里没有**的插件（argon / OpenClash / DiskMan / ddns-go）
- `Scripts/Handles.sh` —— 预置 OpenClash 的 mihomo(meta) 内核

# 手动编译

Actions 页面选择 **R5C** workflow → Run workflow：

- `PACKAGE`：临时追加插件包（`CONFIG_PACKAGE_xxx=y`），多个用 `\n` 分隔
- `TEST`：勾选后只输出配置文件不编译固件（**改完 Config 建议先跑一次 TEST**）

编译流程里加了一步 **Verify Key Packages**：`make defconfig` 会把依赖不满足的包**静默丢掉**，
这一步会逐个检查关键插件是否真的进了 `.config`，缺了就中止编译，避免编出一个"看着正常但少了插件"的固件。

# 说明

- 本固件由 GitHub Actions 云编译生成，本机（Windows）不需要搭建 Linux 编译环境；
  如果想本地编译，需要 Linux/WSL2（Ubuntu）或 Docker，按 [OpenWrt 官方文档](https://openwrt.org/docs/guide-developer/toolchain/install-buildsystem) 装依赖后
  先跑 `Scripts/Packages.sh` 拉第三方插件，再 `cp Config/R5C.txt Config/GENERAL.txt .config` 并 `make defconfig`。
- 安全说明：原脚本会把 ttyd 改成免密自动 root 登录（等于局域网 root 后门），本版本已移除；
  同时把 `wpad-basic-mbedtls` 换成 `wpad-openssl`，支持 WPA3-SAE / 802.11r / OWE。
- OpenClash 需要 `luci-compat` + `luci-lua-runtime`（旧式 Lua 页面），配置里已经带上；
  它的 init 脚本还会用到 `nohup` / `timeout`，上游 Makefile 没声明，这里显式补了 `coreutils-nohup` / `coreutils-timeout`。