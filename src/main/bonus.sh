#!/bin/bash
# Bonus：start 时创建分离的 tmux 会话和采集器；stop 时正常停止采集器并结束会话。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

action=${3:-start}

# shellcheck disable=SC1091
. "$input/bonus.env"

case "$action" in
    start)
        # 创建分离会话（-d），会话里只跑一个教师采集器实例；
        # 脚本立即返回，采集器继续在后台写日志。
        tmux -L "$TMUX_SOCKET" new-session -d -s "$SESSION" \
            "python3 '$WORKER_TOOL' --token '$TOKEN' --log '$output/bonus.log'"
        ;;
    stop)
        # 先让采集器收到 SIGINT 优雅退出（worker 会写出 STOP 行）
        tmux -L "$TMUX_SOCKET" send-keys -t "$SESSION" C-c 2>/dev/null || true
        i=0
        while [ "$i" -lt 50 ]; do
            if grep -q "STOP $TOKEN" "$output/bonus.log" 2>/dev/null; then
                break
            fi
            sleep 0.1
            i=$((i + 1))
        done
        # 再结束本题指定的会话，不影响其他会话
        tmux -L "$TMUX_SOCKET" kill-session -t "$SESSION" 2>/dev/null || true
        ;;
    *)
        printf 'unknown action: %s\n' "$action" >&2
        exit 2
        ;;
esac
