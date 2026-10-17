#!/bin/bash
# Q6：将本地 Debian 包安装到 output/sysroot，运行安装后的工具。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

root="$output/sysroot"
mkdir -p "$root"

# 用 dpkg 把包安装到 sysroot 而不是真实系统根：
#   --root=       指定安装根（数据库落在 $root/var/lib/dpkg）
#   --force-not-root  允许以普通账户安装
#   --log=/dev/null   关闭日志，避免日志路径问题
dpkg --root="$root" --force-not-root --log=/dev/null -i "$input/aim-sentry-tools.deb"

# 运行安装后的真实工具，记录它的输出（版本号来自实际包）
"$root/usr/bin/aim-sentry-info" >"$output/tool-output.txt"
