#!/bin/bash

# 列出所有 screen 会话
echo "当前 screen 会话列表:"
screen -ls

# 杀掉所有名为 'nillion_monitor' 的 screen 会话
echo "正在杀死所有 nillion_monitor 会话..."

# 获取所有 nillion_monitor 会话的 PID
SESSION_IDS=$(screen -ls | grep 'nillion_monitor' | awk '{print $1}' | cut -d '.' -f 1)

if [[ -n "$SESSION_IDS" ]]; then
    echo "$SESSION_IDS" | xargs kill
    echo "已杀死所有 nillion_monitor 会话。"
else
    echo "没有找到 nillion_monitor 会话。"
fi

# 下载最新版本的 node.sh
echo "正在下载最新版本的 node.sh..."
curl -O https://raw.githubusercontent.com/wt195799611/nillion_verifier_monitoring/main/node.sh

# 修改权限使脚本可执行
chmod +x node.sh

# 创建新的 screen 会话并在后台运行新脚本
echo "正在创建新的 screen 会话并运行脚本..."
screen -S nillion_monitor ./node.sh

echo "脚本已更新并在新的 screen 会话中运行。"
