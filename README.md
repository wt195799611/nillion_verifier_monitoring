# Nillion 验证者自动运维脚本

本脚本适用于 **Ubuntu 22.04**，每 5 分钟自动检查 Docker 容器 `nillion4` 的状态和日志。如果容器状态异常或日志中连续出现 RPC 错误，则删除现有容器并重启，同时随机选择一个 RPC 地址。

## 特性
- 自动监控 Nillion 验证者容器。
- 每 5 分钟检查容器状态。
- 检测到异常时自动重启容器，使用随机的 RPC 端点。
- 容器日志文件限制：保留 3 个日志文件，每个日志文件最大 1000MB。
- 使用 `verifier:v1.0.0` 版本的验证者容器。

## 更新日志
**2024 年 9 月 25 日更新**
- 新版本脚本可以直接运行验证者容器。
- 若有老版本容器同时运行，可手动停止老版本。

## 使用方法

### 第一次安装脚本
```bash
curl -O https://raw.githubusercontent.com/wt195799611/nillion_verifier_monitoring/main/update_node.sh
chmod +x update_node.sh
```

### 运行脚本，如有更新，重复运行此命令即可
```bash
./update_node.sh
```
看到日志后，按 Ctrl + A 然后按 D 即可退出会话。

### 查看脚本运行情况
```bash
screen -r nillion_monitor
```

在 `screen` 会话中查看日志，按 Ctrl + A 然后按 D 即可退出会话。
