#!/bin/bash
# Q5：运行 launch.env 给定的启动前检查，保存 stdout/stderr、真实退出码和诊断报告。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

mkdir -p "$output"

# 读取本题参数（教师生成，可被 Bash 直接 source）
# shellcheck disable=SC1091
. "$input/launch.env"

# 用 if 承接子程序的成败：失败分支里 $? 仍是检查程序的真实退出码，
# 不会被后续命令覆盖（也不能用 || true，那会把 $? 改成 0）。
if bash "$LAUNCH_TOOL" "$MODEL_PATH" "$CAMERA_PATH" \
    >"$output/stdout.log" 2>"$output/stderr.log"; then
    code=0
else
    code=$?
fi

# 真实退出码：一个整数 + 换行
printf '%s\n' "$code" >"$output/exit-code.txt"

# 诊断映射：0->SUCCESS/NONE，10->FAILED/MODEL_MISSING，20->FAILED/CAMERA_DENIED
case "$code" in
    0)
        result=SUCCESS
        reason=NONE
        ;;
    10)
        result=FAILED
        reason=MODEL_MISSING
        ;;
    20)
        result=FAILED
        reason=CAMERA_DENIED
        ;;
    *)
        result=FAILED
        reason=NONE
        ;;
esac

# 固定三行、固定顺序
printf 'result=%s\nexit_code=%s\nreason=%s\n' \
    "$result" "$code" "$reason" >"$output/report.txt"
