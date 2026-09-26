# N1 ImmortalWrt 固件

本项目用于斐讯 N1 旁路由，默认 LAN 地址为 `192.168.0.240`。固件通过 ImmortalWrt ImageBuilder 或源码编译构建，并由 ophub 的 [amlogic 打包脚本](https://github.com/ophub/amlogic-s9xxx-openwrt)制作成可刷写镜像。

固件包含 LuCI、`luci-app-amlogic`、HomeProxy 和 MosDNS。HomeProxy 从 [getSomeCats/homeproxy](https://github.com/getSomeCats/homeproxy) 获取源码；MosDNS 使用 [sbwml/luci-app-mosdns](https://github.com/sbwml/luci-app-mosdns) 的 v5 包。构建时以匹配的 ImmortalWrt 版本和架构生成软件包。

首次启动的 root 密码通过 GitHub Actions Secret `N1_ROOT_PASSWORD` 设置，不再使用仓库内的固定默认密码。

## 导入现有路由器配置

构建流程会把 `armsr/armv8/N1/files/` 下的文件原样覆盖到固件根目录。因此，把正在运行的 N1 上的配置复制到以下位置后，构建就会自动带入：

```text
/etc/config/dhcp       -> armsr/armv8/N1/files/etc/config/dhcp
/etc/config/firewall   -> armsr/armv8/N1/files/etc/config/firewall
/etc/config/network    -> armsr/armv8/N1/files/etc/config/network
/etc/config/mosdns     -> armsr/armv8/N1/files/etc/config/mosdns
/etc/config/homeproxy  -> armsr/armv8/N1/files/etc/config/homeproxy
/etc/mosdns/           -> armsr/armv8/N1/files/etc/mosdns/（仅自定义文件需要）
```

当前 MosDNS 配置使用 `/var/etc/mosdns.json`，服务会根据 `/etc/config/mosdns` 自动生成运行配置，因此无需额外导出 `/etc/mosdns/`；只有使用了自定义 YAML、规则文件等内容时，才需要一并复制该目录。

在正在运行、DNS 链路正常的 N1 上，通过 SSH 执行以下命令，先打包这些文件：

```sh
mkdir -p /tmp/n1-config-export/etc/config /tmp/n1-config-export/etc/mosdns
for name in dhcp firewall network mosdns homeproxy; do
    [ ! -f "/etc/config/$name" ] || cp -a "/etc/config/$name" /tmp/n1-config-export/etc/config/
done
[ ! -d /etc/mosdns ] || cp -a /etc/mosdns/. /tmp/n1-config-export/etc/mosdns/
tar -czf /tmp/n1-config-export.tar.gz -C /tmp/n1-config-export .
```

在电脑上运行 `scp root@192.168.0.240:/tmp/n1-config-export.tar.gz .` 下载压缩包，再在项目目录用 PowerShell 解压并复制：

```powershell
New-Item -ItemType Directory -Force .\n1-config-export | Out-Null
tar -xzf .\n1-config-export.tar.gz -C .\n1-config-export
Copy-Item -Recurse -Force .\n1-config-export\etc\* .\armsr\armv8\N1\files\etc\
```

复制后检查 `armsr/armv8/N1/files/etc/config/` 和 `armsr/armv8/N1/files/etc/mosdns/`。`/etc/config/network` 也会随固件恢复，因此当前 N1 的 LAN 地址、接口和 DNS 设置会覆盖仓库原有的 network 配置；刷机前确认该配置适用于目标 N1 和当前网络环境。

HomeProxy 配置可能含节点密码、订阅链接和服务器地址。公开仓库构建出的固件及 GitHub Release 也是公开的；发布前应删除这些凭据，或只在私有仓库构建并保存固件。

## 构建选项

在 GitHub Actions 手动运行 `Build ImmortalWrt for armsr_armv8`，选择 ImmortalWrt 版本、内核和构建方式。源码编译与 ImageBuilder 两种方式都会使用 `armsr/armv8/N1/files/` 作为 rootfs 覆盖目录。

ImageBuilder 适合较快地制作镜像；Compile 会从源码构建完整固件。包管理器由 ImmortalWrt 版本决定：24.10 使用 opkg/IPK，25.12 使用 apk/APK。

## 致谢

[ImmortalWrt](https://github.com/immortalwrt/immortalwrt)、[ophub/amlogic-s9xxx-openwrt](https://github.com/ophub/amlogic-s9xxx-openwrt)、[ophub/kernel](https://github.com/ophub/kernel) 及各软件包维护者。
