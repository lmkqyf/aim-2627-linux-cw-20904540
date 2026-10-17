#!/bin/bash
# Q8：repair 时识别并停止采集器、修复 HTTP 服务；cleanup 时停止修复后的服务。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

action=${3:-repair}

mkdir -p "$output"

# shellcheck disable=SC1091
. "$input/process.env"

# ps 的输出带前导空白，取字段时去掉
ps_pid() { ps -o pid= -p "$1" | tr -d ' \n'; }
ps_user() { ps -o user= -p "$1" | tr -d ' \n'; }
ps_state() { ps -o stat= -p "$1" | tr -d ' \n'; }
ps_cmd() { ps -ww -o args= -p "$1" | sed 's/^ *//' | tr -d '\n'; }

# 有界等待某个 PID 退出
wait_gone() {
    pid=$1
    i=0
    while [ "$i" -lt 50 ]; do
        if ! kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
        sleep 0.1
        i=$((i + 1))
    done
    return 0
}

# 有界重试直到服务返回 200，同时保存响应体与状态码
wait_http() {
    port=$1
    i=0
    while [ "$i" -lt 60 ]; do
        code=$(curl -s -o "$output/http-body.txt" -w '%{http_code}' \
            "http://127.0.0.1:$port/status" 2>/dev/null || true)
        if [ "$code" = "200" ]; then
            printf '%s\n' "$code" >"$output/http-status.txt"
            return 0
        fi
        sleep 0.1
        i=$((i + 1))
    done
    return 1
}

repair() {
    # 1) 用 ps 记录目标进程的关键属性（key=value，每行一个键）
    {
        printf 'pid=%s\n' "$(ps_pid "$TARGET_PID")"
        printf 'user=%s\n' "$(ps_user "$TARGET_PID")"
        printf 'state=%s\n' "$(ps_state "$TARGET_PID")"
        printf 'command=%s\n' "$(ps_cmd "$TARGET_PID")"
    } >"$output/process.txt"

    # 2) 保存目标采集器的日志样本（至少两条 TICK，允许含 START）
    grep -E "^(START|TICK) $TARGET_TOKEN " "$WORKER_LOG" | head -n 4 \
        >"$output/collector-sample.log" || true

    # 3) 只向目标 PID 发普通终止信号（不用 killall/宽泛 pkill），等它写出 STOP 并退出
    if kill -0 "$TARGET_PID" 2>/dev/null; then
        kill -TERM "$TARGET_PID"
        wait_gone "$TARGET_PID"
    fi

    # 4) 停掉原来那个错误的 HTTP 服务
    if kill -0 "$SERVICE_PID" 2>/dev/null; then
        kill -TERM "$SERVICE_PID"
        wait_gone "$SERVICE_PID"
    fi

    # 5) 生成正确的服务配置（三行、固定顺序）
    printf 'bind=127.0.0.1\nport=%s\nroute=/status\n' "$TARGET_PORT" \
        >"$output/server.conf"

    # 6) 用教师工具启动修复后的服务（工具只负责启动，不等就绪）
    bash "$START_TOOL" "$output/server.conf" "$output/service"

    # 7) 有界重试直到就绪，并保存真实响应（返回时服务保持运行）
    wait_http "$TARGET_PORT"
}

cleanup() {
    # 根据服务状态目录定位修复后的服务，正常停止并等待端口释放；保留已生成报告
    pidfile="$output/service/pid"
    if [ -f "$pidfile" ]; then
        pid=$(cat "$pidfile")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill -TERM "$pid"
            wait_gone "$pid"
        fi
    fi
}

case "$action" in
    repair)
        repair
        ;;
    cleanup)
        cleanup
        ;;
    *)
        printf 'unknown action: %s\n' "$action" >&2
        exit 2
        ;;
esac
