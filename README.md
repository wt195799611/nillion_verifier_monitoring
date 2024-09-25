nillion验证者自动检测脚本，于 Ubuntu 22.04 的 Shell 脚本，实现每 5 分钟检查一次 Docker 容器 `nillion4` 的状态和日志，如果容器状态异常或日志中连续出现RPC错误，则删除现有容器并重启，并随机选择 RPC 地址。

# ***新增了容器日志大小的限制，保留3个日志文件，每个日志文件大小1000MB。***

# ***2024年9月25日更新，可以直接运行脚本，脚本中启动verifier:v1.0.0的版本的验证者容器，脚本正常后退出会话，然后使用 `docker ps -a` 检查容器，可以看到老版本和新版本在同时运行，使用`docker stop 老版本容器名称` 停止运行老版本即可。***
使用方法
# 第一次安装脚本
curl -O https://raw.githubusercontent.com/wt195799611/nillion_verifier_monitoring/main/update_nod.sh
chmod +x update_nod.sh

# 运行脚本
./update_nod.sh

# 更新脚本
./update_nod.sh

# 查看脚本运行情况
screen -S nillion_monitor
退出脚本运行日志在键盘按 ctrl+a+d 即可。
