# OpenWRT-CI（NanoPi R5C 专用）

本项目为 [goupengnb/OpenWRT-CI](https://github.com/goupengnb/OpenWRT-CI) 的 R5C 专用精简版：

- 仅编译友善 NanoPi R5C 一个设备
- 每天 05:00（北京时间）自动编译，也可在 Actions 页面手动触发
- 源码：https://github.com/immortalwrt/immortalwrt.git（master 分支）

# 设备信息（NanoPi R5C）

| 项目 | 参数 |
| --- | --- |
| SoC | Rockchip RK3568B2 |
| 内存 | 4GB LPDDR4X |
| 存储 | 32GB eMMC + microSD |
| 网口 | 2× 2.5Gbps（RTL8125，驱动 kmod-r8125） |
| WiFi | M.2 E-Key RTL8822CE（kmod-rtw88-8822ce） |
| USB | 2× USB 3.2 Gen1 |
| 显示 | HDMI 1.4/2.0（kmod-drm-panfrost / kmod-drm-rockchip） |

# 默认参数

- 主机名：狗鹏
- 管理地址：192.168.1.1
- WiFi：狗鹏 / 12345678（地区 CN，psk2+ccmp）
- 登录密码：无（仅提示，实际密码请在首次登录时自行设置）

# 目录说明

- `.github/workflows` —— CI 配置（R5C 编译入口 + 公用核心 + 自动清理）
- `Scripts` —— 自定义脚本（插件拉取 / 修补 / 系统设置）
- `Config` —— 固件配置（R5C 设备配置 + GENERAL 通用配置）

# 手动编译

Actions 页面选择 **R5C** workflow → Run workflow：

- `PACKAGE`：手动追加插件包，多个用 `\n` 分隔
- `TEST`：勾选后仅输出配置文件，不编译固件

# 精简要点

- 已删除 MTK / QCA / X86 / TEST 等其它平台的工作流与配置
- `Packages.sh` 仅保留实际使用的插件：argon 主题、openclash、ddns-go、diskman、adguardhome
- R5C 板载 WiFi 为 RTL8822CE，原配置中的 `kmod-mt7921e` 已移除
- 更多说明见 `R5C-优化说明.md`