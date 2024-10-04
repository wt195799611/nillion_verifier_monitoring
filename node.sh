#!/bin/bash

# 定义 RPC 地址数组
RPC_ENDPOINTS=(
    "https://nillion-testnet-rpc.polkachu.com"
    "https://nillion-testnet.rpc.kjnodes.com"
    "https://testnet-nillion-rpc.lavenderfive.com"
)

# 定义 Docker 容器名称
CONTAINER_NAME="nillion5"

# 定义启动容器的命令
run_container() {
    RANDOM_RPC=${RPC_ENDPOINTS[$RANDOM % ${#RPC_ENDPOINTS[@]}]}
    echo "$(date) - 使用 RPC: $RANDOM_RPC 重启容器"

    sudo docker run -d \
        --name $CONTAINER_NAME \
        -v $HOME/nillion/verifier:/var/tmp \
        --log-opt max-size=1000m \
        --log-opt max-file=3 \
        nillion/verifier:v1.0.1 \
        verify --rpc-endpoint "$RANDOM_RPC"
}

# 删除并重启容器
restart_container() {
    echo "$(date) - 删除并重启容器: $CONTAINER_NAME"
    sudo docker stop $CONTAINER_NAME
    sudo docker rm $CONTAINER_NAME
    run_container
}

# 检查容器状态
check_container_status() {
    STATUS=$(sudo docker inspect -f '{{.State.Status}}' $CONTAINER_NAME 2>/dev/null)

    if [ "$STATUS" != "running" ]; then
        echo "$(date) - 容器状态异常，重启容器"
        restart_container
    else
        echo "$(date) - 容器状态正常"
    fi
}

# 检查容器最新日志
check_container_logs() {
    LAST_LOGS=$(sudo docker logs --tail 20 $CONTAINER_NAME 2>&1)

    ERROR_INTERNAL_CODE=$(echo "$LAST_LOGS" | grep "(code: -32603)")
    if [ ! -z "$ERROR_INTERNAL_CODE" ]; then
        echo "$(date) - 检测到错误 (code: -32603)，重启容器"
        restart_container
        return
    fi

    TIMEOUT_ERRORS=$(echo "$LAST_LOGS" | grep -A 1 "operation timed out")
    if [[ $(echo "$TIMEOUT_ERRORS" | grep -c "operation timed out") -ge 2 ]]; then
        echo "$(date) - 检测到连续的超时错误，重启容器"
        restart_container
        return
    fi

    echo "$(date) - RPC链接正常"
}

# 主循环，每 5 分钟检查一次
while true; do
    check_container_status
    check_container_logs
    sleep 300
done
