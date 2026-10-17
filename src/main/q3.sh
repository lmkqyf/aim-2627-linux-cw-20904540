#!/bin/bash
# Q3：复制素材、备份配置、移动草稿、删除 tmp、设定权限并直接运行 hello.sh。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

ws="$output/sentry_ws"

# 四个目标目录：mkdir -p 幂等，重复运行不报错
mkdir -p "$ws/scripts" "$ws/config" "$ws/backup" "$ws/archive"

# 脚本与配置（cp 覆盖写入，第二次运行同样成立）
cp "$input/hello.sh" "$ws/scripts/hello.sh"
cp "$input/robot.conf" "$ws/config/robot.conf"

# 正式配置的完整副本
cp "$ws/config/robot.conf" "$ws/backup/robot.conf"

# 草稿移动到归档位置并改名，原位置不再保留
cp "$input/draft.conf" "$ws/archive/draft.conf.old"

# 删除整个 tmp（包含输出目录里预置的上次运行缓存）
rm -rf "$ws/tmp"

# 权限：脚本需可执行，配置只读即可
chmod 750 "$ws/scripts/hello.sh"
chmod 640 "$ws/config/robot.conf"

# 直接执行（依赖上面设好的执行位），stdout 落到输出根目录
"$ws/scripts/hello.sh" >"$output/hello-output.txt"
