#!/bin/bash
# Q4：合并日志，按级别提取，保存首尾片段并统计错误行数。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

mkdir -p "$output"

# 1) 按 boot、run 的顺序完整拼接（保持原行、顺序与重复行）
cat "$input/boot.log" "$input/run.log" >"$output/all.log"

# 2) 错误行：级别字段必须等于 ERROR。用 ^ERROR  锚定行首，
#    避免把消息里出现的 "ERROR" 误判成错误行。
grep -E '^ERROR ' "$output/all.log" >"$output/errors.log" || true

# 3) 告警：级别为 WARN 或 ERROR
grep -E '^(WARN|ERROR) ' "$output/all.log" >"$output/attention.log" || true

# 4) 整体最后 5 行；不足则全部
tail -n 5 "$output/all.log" >"$output/recent.log" || true

# 5) 最前 3 条错误；不足则全部
head -n 3 "$output/errors.log" >"$output/first-errors.log" || true

# 6) 错误行数：空文件时 wc 输出 0，格式正好是"整数+换行"
wc -l <"$output/errors.log" >"$output/error-count.txt"
