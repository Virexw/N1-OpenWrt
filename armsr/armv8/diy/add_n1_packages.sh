#!/usr/bin/env bash
set -euo pipefail

# Use current upstream package definitions for the two main services.
rm -rf package/homeproxy package/mosdns package/v2ray-geodata
rm -rf package/feeds/luci/luci-app-homeproxy
rm -rf package/feeds/packages/mosdns package/feeds/packages/v2ray-geodata

git clone --depth=1 https://github.com/getSomeCats/homeproxy.git package/homeproxy
git clone --depth=1 --branch v5 https://github.com/sbwml/luci-app-mosdns.git package/mosdns
git clone --depth=1 https://github.com/sbwml/v2ray-geodata.git package/v2ray-geodata

# MosDNS v5 requires a recent Go toolchain.
rm -rf feeds/packages/lang/golang
git clone --depth=1 --branch 26.x https://github.com/sbwml/packages_lang_golang.git feeds/packages/lang/golang
