#!/bin/bash
# Q2：创建 sentry_ws 四个子目录、两个空文件以及指定脚本和配置。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

ws="$output/sentry_ws"

# 四个子目录：mkdir -p 对已存在目录是幂等的，重复运行不会报错
mkdir -p "$ws/scripts" "$ws/config" "$ws/logs" "$ws/tmp"

# 两个空文件：touch 不会截断已有文件，重复运行稳定
touch "$ws/logs/.keep" "$ws/tmp/scratch.txt"

# 脚本与配置：用 heredoc 覆盖写入（> 语义），不用 >>，避免重复追加
cat >"$ws/scripts/hello.sh" <<'HELLO'
#!/bin/bash
echo "Hello, AIM Linux!"
HELLO

cat >"$ws/config/robot.conf" <<'CONF'
robot=sentry
mode=training
log_level=INFO
CONF
