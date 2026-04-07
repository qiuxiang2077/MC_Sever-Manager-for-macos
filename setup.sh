#!/bin/bash

# Minecraft服务器管理器 - 初始配置脚本
# 用于首次设置服务器配置

echo "========================================"
echo "  Minecraft服务器管理器 - 初始配置"
echo "========================================"
echo ""

# 默认值
DEFAULT_SERVER_PATH="$HOME/minecraft-server-1.21.11"
DEFAULT_SERVER_VERSION="1.21.11"
DEFAULT_RCON_PASSWORD="temp123"

# 询问服务器路径
echo "请输入Minecraft服务器目录路径"
echo "这应该是您存放server.jar和配置文件的地方"
read -p "路径 (默认: $DEFAULT_SERVER_PATH): " SERVER_PATH
SERVER_PATH=${SERVER_PATH:-$DEFAULT_SERVER_PATH}

# 检查路径是否存在
if [ ! -d "$SERVER_PATH" ]; then
    echo "警告: 路径 $SERVER_PATH 不存在"
    read -p "是否要创建这个目录? (y/n): " CREATE_DIR
    if [[ $CREATE_DIR =~ ^[Yy]$ ]]; then
        mkdir -p "$SERVER_PATH"
        echo "目录已创建: $SERVER_PATH"
    else
        echo "请确保路径正确后再运行配置脚本"
        exit 1
    fi
fi

# 服务器版本
echo ""
echo "请输入Minecraft服务器版本"
read -p "版本 (默认: $DEFAULT_SERVER_VERSION): " SERVER_VERSION
SERVER_VERSION=${SERVER_VERSION:-$DEFAULT_SERVER_VERSION}

# 是否是模组服务器
echo ""
echo "是否是模组服务器 (Forge/Fabric)?"
read -p "是模组服务器吗? (y/n, 默认: n): " IS_MODDED_INPUT
if [[ $IS_MODDED_INPUT =~ ^[Yy]$ ]]; then
    IS_MODDED="true"
    echo "请选择模组加载器:"
    echo "1) Forge"
    echo "2) Fabric"
    read -p "选择 (1-2, 默认: 1): " MOD_LOADER_CHOICE
    case $MOD_LOADER_CHOICE in
        1) MOD_LOADER="forge" ;;
        2) MOD_LOADER="fabric" ;;
        *) MOD_LOADER="forge" ;;
    esac
else
    IS_MODDED="false"
    MOD_LOADER="vanilla"
fi

# RCON密码
echo ""
echo "RCON (远程控制) 设置"
read -p "RCON密码 (默认: $DEFAULT_RCON_PASSWORD): " RCON_PASSWORD
RCON_PASSWORD=${RCON_PASSWORD:-$DEFAULT_RCON_PASSWORD}

# RCON端口
DEFAULT_RCON_PORT="25575"
read -p "RCON端口 (默认: $DEFAULT_RCON_PORT): " RCON_PORT
RCON_PORT=${RCON_PORT:-$DEFAULT_RCON_PORT}

# 保存配置
CONFIG_FILE="config.sh"
cat > "$CONFIG_FILE" << EOF
#!/bin/bash
# Minecraft服务器配置 - 由setup.sh生成
# 生成时间: $(date)

# 服务器基本信息
export SERVER_PATH="$SERVER_PATH"
export SERVER_VERSION="$SERVER_VERSION"
export IS_MODDED="$IS_MODDED"
export MOD_LOADER="$MOD_LOADER"

# RCON配置
export RCON_PASSWORD="$RCON_PASSWORD"
export RCON_PORT="$RCON_PORT"

# 其他路径
export PROPERTIES_FILE="\$SERVER_PATH/server.properties"
export LOGS_DIR="\$SERVER_PATH/logs"
export START_SCRIPT="\$SERVER_PATH/start.sh"
export STOP_SCRIPT="\$SERVER_PATH/stop.sh"

EOF

echo ""
echo "========================================"
echo "配置已保存到 $CONFIG_FILE"
echo ""
echo "配置摘要:"
echo "  服务器路径: $SERVER_PATH"
echo "  服务器版本: $SERVER_VERSION"
echo "  模组服务器: $IS_MODDED ($MOD_LOADER)"
echo "  RCON密码: $RCON_PASSWORD"
echo "  RCON端口: $RCON_PORT"
echo ""
echo "现在您可以运行其他管理脚本了！"
echo "========================================"