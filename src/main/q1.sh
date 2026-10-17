#!/bin/bash
# Q1：定位 handover，读取隐藏编号和欢迎文本。输出 location.txt、robot-id.txt、welcome.txt。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

mkdir -p "$output"

# 1) handover/ 的真实绝对路径：参数是唯一可靠入口（路径可能含空格、cwd 不保证在仓库里）
cd "$input/handover"
pwd >"$output/location.txt"

# 2) 隐藏文件 .robot-id 的完整内容
cat "$input/handover/.robot-id" >"$output/robot-id.txt"

# 3) notes/welcome.txt 的完整内容
cat "$input/notes/welcome.txt" >"$output/welcome.txt"
