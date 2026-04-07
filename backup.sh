#!/bin/bash

# Minecraft服务器自动备份脚本
# 支持完整备份和增量备份

# 加载通用函数库
if [ -f "common.sh" ]; then
    source common.sh
else
    echo "错误: 未找到通用函数库 common.sh"
    exit 1
fi

# 加载配置
if [ -f "config.sh" ]; then
    source config.sh
else
    log_error "未找到配置文件 config.sh"
    echo "请先运行 ./setup.sh 进行初始配置"
    exit 1
fi

# 备份配置
BACKUP_DIR="${SERVER_PATH}/backups"
mkdir -p "$BACKUP_DIR"

# 备份文件列表
BACKUP_ITEMS=(
    "world"
    "world_nether"
    "world_the_end"
    "server.properties"
    "whitelist.json"
    "ops.json"
    "banned-players.json"
    "banned-ips.json"
)

# 创建备份
create_backup() {
    local backup_type="$1"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_name="${backup_type}_${timestamp}"
    local backup_path="$BACKUP_DIR/$backup_name"

    log_info "开始创建 $backup_type 备份: $backup_name"

    # 检查服务器状态
    if check_server_running; then
        log_warning "服务器正在运行，建议在备份前停止服务器"
        if ! confirm "是否继续备份?"; then
            log_info "备份取消"
            return 1
        fi
    fi

    mkdir -p "$backup_path"

    local total_items=${#BACKUP_ITEMS[@]}
    local current_item=0

    for item in "${BACKUP_ITEMS[@]}"; do
        current_item=$((current_item + 1))
        show_progress $current_item $total_items

        if [ -e "$SERVER_PATH/$item" ]; then
            if [ -d "$SERVER_PATH/$item" ]; then
                cp -r "$SERVER_PATH/$item" "$backup_path/"
            else
                cp "$SERVER_PATH/$item" "$backup_path/"
            fi
            log_info "备份 $item 完成"
        else
            log_warning "$item 不存在，跳过"
        fi
    done

    echo # 新行

    # 创建备份信息文件
    cat > "$backup_path/backup_info.txt" << EOF
备份信息
========
备份类型: $backup_type
创建时间: $(date)
服务器版本: $SERVER_VERSION
服务器路径: $SERVER_PATH
备份项目: ${BACKUP_ITEMS[*]}
EOF

    # 压缩备份
    log_info "压缩备份文件..."
    cd "$BACKUP_DIR"
    tar -czf "${backup_name}.tar.gz" "$backup_name" 2>/dev/null

    # 清理未压缩目录
    rm -rf "$backup_name"

    log_success "备份完成: ${backup_name}.tar.gz"
    log_info "备份大小: $(du -h "${backup_name}.tar.gz" | cut -f1)"

    # 清理旧备份
    cleanup_old_backups
}

# 清理旧备份
cleanup_old_backups() {
    local max_backups=10
    local backup_files=("$BACKUP_DIR"/*.tar.gz)

    if [ ${#backup_files[@]} -gt $max_backups ]; then
        log_info "清理旧备份，保留最新的 $max_backups 个"

        # 排序并删除旧的
        ls -t "$BACKUP_DIR"/*.tar.gz | tail -n +$((max_backups + 1)) | xargs rm -f 2>/dev/null

        log_info "清理完成"
    fi
}

# 列出备份
list_backups() {
    echo -e "${CYAN}现有备份:${NC}"
    echo "===================="

    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null | while read -r line; do
            echo "$line"
        done
    else
        echo "暂无备份文件"
    fi
}

# 恢复备份
restore_backup() {
    list_backups

    echo
    read -p "请输入要恢复的备份文件名 (不含.tar.gz): " backup_name

    if [ -z "$backup_name" ]; then
        log_error "备份文件名不能为空"
        return 1
    fi

    local backup_file="$BACKUP_DIR/${backup_name}.tar.gz"

    if [ ! -f "$backup_file" ]; then
        log_error "备份文件不存在: $backup_file"
        return 1
    fi

    log_warning "这将覆盖当前服务器文件！"
    if ! confirm "确认恢复备份?"; then
        log_info "恢复取消"
        return 0
    fi

    # 停止服务器
    if check_server_running; then
        log_info "停止服务器..."
        stop_server
        sleep 5
    fi

    log_info "解压备份文件..."
    cd "$SERVER_PATH"
    tar -xzf "$backup_file" 2>/dev/null

    log_success "备份恢复完成"
    log_info "建议重新启动服务器检查"
}

# 检查服务器运行状态
check_server_running() {
    if ps aux | grep -v grep | grep "server.jar" | grep "$SERVER_DIR" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 停止服务器
stop_server() {
    if check_server_running; then
        # 这里应该调用实际的停止逻辑
        log_info "发送停止命令到服务器..."
        # 实际实现需要RCON或kill进程
    fi
}

# 主函数
main() {
    show_banner

    if [ $# -eq 0 ]; then
        echo "用法: $0 <命令>"
        echo "命令:"
        echo "  full     - 创建完整备份"
        echo "  quick    - 创建快速备份（仅世界文件）"
        echo "  list     - 列出所有备份"
        echo "  restore  - 恢复备份"
        echo "  auto     - 自动备份（用于定时任务）"
        exit 1
    fi

    case "$1" in
        "full")
            create_backup "full"
            ;;
        "quick")
            # 快速备份只备份世界
            BACKUP_ITEMS=("world" "world_nether" "world_the_end")
            create_backup "quick"
            ;;
        "list")
            list_backups
            ;;
        "restore")
            restore_backup
            ;;
        "auto")
            # 自动模式，静默备份
            create_backup "auto" >/dev/null 2>&1
            ;;
        *)
            log_error "未知命令: $1"
            exit 1
            ;;
    esac
}

main "$@"