#!/bin/bash

# ==========================================
# AIStudioBuildProxy 一键管理脚本
# ==========================================

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 定义仓库地址
REPO_URL="https://github.com/aa105132/AIStudioBuildProxy.git"
SERVER_BRANCH="server"
CLIENT_BRANCH="client"

# 定义插件路径
PLUGIN_DIR_NAME="AIStudioBuildProxy"
SERVER_PATH="plugins/$PLUGIN_DIR_NAME"
CLIENT_BASE="public/scripts/extensions/third-party"
CLIENT_PATH="$CLIENT_BASE/$PLUGIN_DIR_NAME"

# ------------------------------------------
# 工具函数
# ------------------------------------------

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Git 是否安装
check_git() {
    if ! command -v git &> /dev/null; then
        log_error "未检测到 Git！请先安装 Git 后再运行此脚本。"
        echo "Windows用户请下载: https://git-scm.com/download/win"
        exit 1
    fi
}

# ------------------------------------------
# 目录定位逻辑
# ------------------------------------------

find_root_dir() {
    log_info "正在检测酒馆根目录..."

    if [[ -f "config.yaml" && -d "plugins" ]]; then
        log_success "当前即为酒馆根目录。"
        return 0
    fi

    if [[ -f "../config.yaml" && -d "../plugins" ]]; then
        cd ..
        log_success "在上一级找到酒馆根目录，已切换。"
        return 0
    fi

    log_info "当前目录未找到，正在扫描子目录..."
    TARGET_ROOT=$(find . -maxdepth 2 -name "config.yaml" -type f -print -quit | xargs dirname 2>/dev/null)

    if [[ -n "$TARGET_ROOT" && -d "$TARGET_ROOT/plugins" ]]; then
        cd "$TARGET_ROOT"
        log_success "在子目录 [$(pwd)] 找到酒馆根目录，已切换。"
        return 0
    fi

    log_error "未找到酒馆根目录（必须包含 config.yaml 和 plugins 文件夹）。"
    log_error "请将此脚本放在 SillyTavern 的根目录或其子文件夹内运行。"
    return 1
}

# ------------------------------------------
# 核心功能
# ------------------------------------------

enable_server_plugins() {
    if [ ! -f "config.yaml" ]; then
        log_error "config.yaml 文件不存在！"
        return
    fi

    log_info "正在检查 config.yaml 设置..."
    
    if grep -q "enableServerPlugins: true" config.yaml; then
        log_success "Server Plugins 已经开启，跳过修改。"
    else
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' 's/enableServerPlugins: false/enableServerPlugins: true/g' config.yaml
        else
            sed -i 's/enableServerPlugins: false/enableServerPlugins: true/g' config.yaml
        fi
        
        if grep -q "enableServerPlugins: true" config.yaml; then
            log_success "config.yaml 修改成功：已开启 Server Plugins。"
        else
            log_warn "config.yaml 修改失败，请手动检查。"
        fi
    fi
}

install_plugins() {
    echo -e "\n------------------------------------------"
    log_info "开始安装流程..."
    
    enable_server_plugins

    echo -e "\n>>> 处理服务端插件 (Server Side)..."
    if [ -d "$SERVER_PATH" ]; then
        log_warn "发现旧的服务端插件，正在删除..."
        rm -rf "$SERVER_PATH"
    fi
    
    if [ -d "plugins" ]; then
        cd plugins
        log_info "正在克隆服务端仓库..."
        if git clone -b "$SERVER_BRANCH" "$REPO_URL"; then
            log_success "服务端插件安装成功。"
        else
            log_error "服务端插件下载失败，请检查网络或代理设置。"
            cd ..
            return 1
        fi
        cd ..
    else
        log_error "plugins 目录不存在，这是个正常的酒馆目录吗？"
        return 1
    fi

    echo -e "\n>>> 处理客户端扩展 (Client Side)..."
    
    if [ ! -d "$CLIENT_BASE" ]; then
        log_warn "未找到第三方扩展目录 ($CLIENT_BASE)。"
        log_info "尝试创建目录..."
        mkdir -p "$CLIENT_BASE"
    fi

    if [ -d "$CLIENT_PATH" ]; then
        log_warn "发现旧的客户端扩展，正在删除..."
        rm -rf "$CLIENT_PATH"
    fi

    cd "$CLIENT_BASE"
    log_info "正在克隆客户端仓库..."
    if git clone -b "$CLIENT_BRANCH" "$REPO_URL"; then
        log_success "客户端扩展安装成功。"
    else
        log_error "客户端扩展下载失败，请检查网络或代理设置。"
        cd - > /dev/null
        return 1
    fi
    
    cd - > /dev/null 2>&1

    echo -e "\n------------------------------------------"
    echo -e "${GREEN}✅ 所有操作已完成！请重启酒馆 (SillyTavern) 以生效。${NC}"
    echo -e "------------------------------------------"
}

uninstall_plugins() {
    echo -e "\n------------------------------------------"
    log_info "开始卸载流程..."

    if [ -d "$SERVER_PATH" ]; then
        rm -rf "$SERVER_PATH"
        log_success "服务端插件已删除。"
    else
        log_warn "未找到服务端插件，跳过。"
    fi

    if [ -d "$CLIENT_PATH" ]; then
        rm -rf "$CLIENT_PATH"
        log_success "客户端扩展已删除。"
    else
        log_warn "未找到客户端扩展，跳过。"
    fi

    echo -e "\n${GREEN}✅ 卸载完成。${NC}"
}

# ------------------------------------------
# 主程序
# ------------------------------------------

clear

echo -e "${CYAN}"
echo "#############################################"
echo "#       AIStudioBuildProxy 自动安装脚本     #"
echo "#       专治各种不会用，一键搞定            #"
echo "#############################################"
echo -e "${NC}"

check_git

if ! find_root_dir; then
    # 兼容管道模式的暂停
    read -n 1 -s -r -p "按任意键退出..." < /dev/tty
    exit 1
fi

while true; do
    echo -e "\n当前工作目录: $(pwd)"
    echo -e "${YELLOW}请选择操作：${NC}"
    echo "1) 安装 / 重新安装 (推荐)"
    echo "2) 卸载插件"
    echo "0) 退出"
    
    # 修复：显式从 /dev/tty 读取输入，解决管道模式下的死循环
    read -p "请输入数字 [1/2/0]: " choice < /dev/tty

    case $choice in
        1)
            install_plugins
            break
            ;;
        2)
            uninstall_plugins
            break
            ;;
        0)
            echo "再见！"
            exit 0
            ;;
        *)
            log_error "输入错误，请输入 1, 2 或 0"
            ;;
    esac
done

# 兼容管道模式的暂停
echo ""
read -n 1 -s -r -p "按任意键退出脚本..." < /dev/tty
echo ""
