#!/bin/bash

# Minecraft服务器管理器 - 通用函数库
# 包含错误处理、日志系统、UI增强等

# 启用严格模式
set -euo pipefail

# 日志配置
LOG_DIR="./logs"
LOG_FILE="$LOG_DIR/manager.log"
mkdir -p "$LOG_DIR"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[信息]${NC} $timestamp - $message" | tee -a "$LOG_FILE"
}

log_success() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[成功]${NC} $timestamp - $message" | tee -a "$LOG_FILE"
}

log_warning() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[警告]${NC} $timestamp - $message" | tee -a "$LOG_FILE"
}

log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[错误]${NC} $timestamp - $message" | tee -a "$LOG_FILE"
}

# 错误处理
error_exit() {
    local message="$1"
    log_error "$message"
    echo -e "${RED}程序退出${NC}"
    exit 1
}

# 陷阱设置
trap 'error_exit "脚本被中断"' INT TERM

# 进度条函数
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))

    printf "\r${CYAN}进度: [${NC}"
    for ((i=0; i<completed; i++)); do printf "="; done
    for ((i=completed; i<width; i++)); do printf " "; done
    printf "${CYAN}] %d%%${NC}" $percentage
}

# 确认函数
confirm() {
    local message="$1"
    local default=${2:-"n"}

    if [[ $default == "y" ]]; then
        read -p "$message (Y/n): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Nn]$ ]]
    else
        read -p "$message (y/N): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

# 检查命令是否存在
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        log_error "命令 '$cmd' 未找到，请安装后重试"
        return 1
    fi
    return 0
}

# 显示横幅
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║          Minecraft 服务器管理器              ║"
    echo "║             版本 2.0 - 增强版                ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 清理函数
cleanup() {
    log_info "执行清理操作..."
    # 这里可以添加临时文件清理等
}

# 注册清理陷阱
trap cleanup EXIT