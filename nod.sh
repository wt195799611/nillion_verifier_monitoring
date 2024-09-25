#!/bin/bash

# 定义 RPC 地址数组
RPC_ENDPOINTS=(
    "https://nillion-testnet-rpc.polkachu.com"
    "https://nillion-testnet.rpc.kjnodes.com"
    "https://testnet-nillion-rpc.lavenderfive.com"
)

# 定义 Docker 容器名称
CONTAINER_NAME="nillion3"

# 获取最新区块高度
get_latest_block_height() {
    RANDOM_RPC=${RPC_ENDPOINTS[$RANDOM % ${#RPC_ENDPOINTS[@]}]}
    LATEST_BLOCK=$(curl -s "$RANDOM_RPC/block" | jq -r '.result.block.header.height')

    # 调试信息
#    echo "$(date) - 尝试从 $RANDOM_RPC 获取最新区块高度，结果: $LATEST_BLOCK"

    if [[ "$LATEST_BLOCK" =~ ^[0-9]+$ ]]; then
        echo "$LATEST_BLOCK"
    else
        echo "$(date) - 错误: 无法从响应中提取区块高度，返回值: $LATEST_BLOCK"
        return 1
    fi
}

# 定义启动容器的命令
run_container() {
    local START_BLOCK=$1
    RANDOM_RPC=${RPC_ENDPOINTS[$RANDOM % ${#RPC_ENDPOINTS[@]}]}
    echo "$(date) - 使用 RPC: $RANDOM_RPC 和启动区块号: $START_BLOCK 重启容器"

    sudo docker run -d \
        --name $CONTAINER_NAME \
        -v $HOME/nillion/accuser:/var/tmp \
        --log-opt max-size=1000m \
        --log-opt max-file=3 \
        nillion/retailtoken-accuser:v1.0.0 \
        accuse --rpc-endpoint "$RANDOM_RPC" --block-start "$START_BLOCK"
}

# 删除并重启容器
restart_container() {
    START_BLOCK=$1
    echo "$(date) - 删除并重启容器: $CONTAINER_NAME, 启动区块号: $START_BLOCK"
    sudo docker stop $CONTAINER_NAME
    sudo docker rm $CONTAINER_NAME
    run_container "$START_BLOCK"
}

# 检查容器状态
check_container_status() {
    STATUS=$(sudo docker inspect -f '{{.State.Status}}' $CONTAINER_NAME 2>/dev/null)

    if [ "$STATUS" != "running" ]; then
        echo "$(date) - 容器状态异常，重启容器"
        NEW_START_BLOCK=$(get_latest_block_height)

        # 调试信息
        echo "$(date) - 获取到的区块号: $NEW_START_BLOCK"

        # 验证 NEW_START_BLOCK 是否为空并且为数字
        if [[ -n "$NEW_START_BLOCK" && "$NEW_START_BLOCK" =~ ^[0-9]+$ ]]; then
            restart_container "$NEW_START_BLOCK"
        else
            echo "$(date) - 无法获取最新区块高度，跳过重启"
        fi
    else
        echo "$(date) - 容器状态正常"
    fi
}

# 检查容器最新日志
check_container_logs() {
    LAST_LOGS=$(sudo docker logs --tail 20 $CONTAINER_NAME 2>&1)

    ERROR_INTERNAL_CODE=$(echo "$LAST_LOGS" | grep "(code: -32603)")
    if [ ! -z "$ERROR_INTERNAL_CODE" ]; then
        LOWEST_HEIGHT=$(echo "$ERROR_INTERNAL_CODE" | grep -oP 'lowest height is \K[0-9]+' | head -n 1 | tr -d '\r\n')

        if [[ "$LOWEST_HEIGHT" =~ ^[0-9]+$ ]]; then
            NEW_START_BLOCK=$((LOWEST_HEIGHT + 1))
            echo "$(date) - 检测到错误 (code: -32603)，使用新的启动区块号: $NEW_START_BLOCK 重启容器"
            restart_container "$NEW_START_BLOCK"
            return
        else
            echo "$(date) - 检测到错误，但无法正确提取最低高度。"
        fi
    fi

    TIMEOUT_ERRORS=$(echo "$LAST_LOGS" | grep -A 1 "request or response body error: operation timed out")
    if [[ $(echo "$TIMEOUT_ERRORS" | grep -c "request or response body error: operation timed out") -ge 2 ]]; then
        NEW_START_BLOCK=$(get_latest_block_height)

        if [[ "$NEW_START_BLOCK" =~ ^[0-9]+$ ]]; then
            echo "$(date) - 检测到连续的超时错误，使用最新区块号: $NEW_START_BLOCK 重启容器"
            restart_container "$NEW_START_BLOCK"
            return
        else
            echo "$(date) - 获取最新区块高度失败。"
        fi
    fi

    echo "$(date) - RPC链接正常"
}

# 主循环，每 5 分钟检查一次
while true; do
    check_container_status
    check_container_logs
    sleep 300
done