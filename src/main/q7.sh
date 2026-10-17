#!/bin/bash
# Q7：读取 input/remote.env，生成 ssh_config，用 SSH 和 SCP 获取远程数据。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

mkdir -p "$output/received"

# 读取远端参数（教师生成的 shell 格式文件）
# shellcheck disable=SC1091
. "$input/remote.env"

# 生成 ssh_config：别名 aim-sentry，路径一律加引号以兼容空格
cat >"$output/ssh_config" <<SSHCFG
Host aim-sentry
    HostName $HOST
    Port $PORT
    User $REMOTE_USER
    IdentityFile "$KEY_PATH"
    UserKnownHostsFile "$KNOWN_HOSTS"
    IdentitiesOnly yes
    StrictHostKeyChecking yes
    BatchMode yes
SSHCFG

# 私钥配置属于敏感信息：收紧到仅所有者可读写
chmod 600 "$output/ssh_config"

# 通过别名执行远端命令，确认连的是远端账户
ssh -F "$output/ssh_config" aim-sentry whoami >"$output/remote-user.txt"

# 用 SCP 把远端日志取回本地
scp -F "$output/ssh_config" "aim-sentry:$REMOTE_LOG" "$output/received/errors.log"
