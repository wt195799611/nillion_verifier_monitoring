#!/bin/bash

# 杀掉所有 screen 会话
screen -ls
screen -ls | grep -o '[0-9]*\.' | sed 's/\.//g' | xargs kill


# 下载最新版本的 node.sh
curl -O https://raw.githubusercontent.com/wt195799611/nillion_verifier_monitoring/main/node.sh

# 修改权限使脚本可执行
chmod +x node.sh

# 创建新的 screen 会话并运行新脚本
screen -S nillion_monitor ./node.sh
