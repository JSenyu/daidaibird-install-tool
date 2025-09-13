#!/data/data/com.termux/files/usr/bin/bash
# =========================================================================
# DaidaiBird SillyTavern酒馆多功能面板 v2.36
# 作者: 呆呆鸟
# =========================================================================

# ==== 基础配色定义 ====
RED='\033[1;31m'        # 红色
GREEN='\033[1;32m'      # 绿色
YELLOW='\033[1;33m'     # 黄色
BLUE='\033[1;34m'       # 蓝色
CYAN='\033[1;36m'       # 青色
WHITE='\033[1;37m'      # 白色
NC='\033[0m'            # 重置颜色

# ==== 脚本信息 ====
SCRIPT_VERSION="8.6"
AUTHOR="呆呆鸟"
UPDATE_DATE="2025-09-10"

#主群
MAIN_GROUP="1051559725"
#新人群
NEW_GROUP="1051559725"

# ==== 路径定义 ====
SILLYTAVERN_PATH="$HOME/SillyTavern"
BACKUP_PATH="$HOME/sillytavern_backup"
UBUNTU_ROOT="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu"
TERMUX_SOURCES_LIST="/data/data/com.termux/files/usr/etc/apt/sources.list"

# ==== Termux镜像源配置 ====
declare -a TERMUX_MIRROR_URLS=(
    "https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main"
    "https://mirrors.bfsu.edu.cn/termux/apt/termux-main"
    "https://mirrors.ustc.edu.cn/termux/apt/termux-main"
    "https://mirrors.aliyun.com/termux/apt/termux-main"
    "https://packages-cf.termux.org/apt/termux-main"
)

declare -a TERMUX_MIRROR_NAMES=(
    "清华大学镜像 (推荐)"
    "北京外国语大学镜像"
    "中科大镜像"
    "阿里云镜像"
    "Termux官方源 (需要魔法)"
)

# ==== GitHub镜像源配置 ====
declare -a GITHUB_MIRRORS=(
    "https://dgithub.xyz"
    "https://github.moeyy.xyz"
    "https://gh.api.99988866.xyz"
    "https://github.com"
)

declare -a NPM_MIRRORS=(
    "https://registry.npmmirror.com/"
    "https://mirrors.cloud.tencent.com/npm/"
    "https://mirrors.huaweicloud.com/repository/npm/"
    "https://registry.npmjs.org/"
)

declare -a UBUNTU_MIRRORS=(
    "https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/"
    "https://mirrors.ustc.edu.cn/ubuntu-ports/"
    "https://mirrors.aliyun.com/ubuntu-ports/"
    "http://ports.ubuntu.com/"
)

# 镜像源名称（用于显示）
declare -a GITHUB_MIRROR_NAMES=(
    "DGithub镜像 (推荐)"
    "Moeyy镜像"
    "API镜像"
    "GitHub官方 (需要魔法)"
)

declare -a NPM_MIRROR_NAMES=(
    "淘宝镜像 (推荐)"
    "腾讯镜像"
    "华为镜像"
    "NPM官方"
)

declare -a UBUNTU_MIRROR_NAMES=(
    "清华大学镜像 (推荐)"
    "中科大镜像"
    "阿里云镜像"
    "Ubuntu官方"
)

# ==== 全局变量 ====
CURRENT_GITHUB_MIRROR=""
CURRENT_NPM_MIRROR=""
CURRENT_UBUNTU_MIRROR=""
DEPLOY_METHOD=""

# =========================================================================
# 提示函数
# =========================================================================
say_hello() {
    echo -e "${BLUE}欢迎使用 呆呆鸟 管理面板${NC}"
}

say_working() {
    echo -e "${CYAN}正在为宝子$1，请稍等片刻${NC}"
}

say_success() {
    echo -e "${GREEN}$1成功完成${NC}"
}

say_warning() {
    echo -e "${YELLOW}温馨提示：$1${NC}"
}

say_error() {
    echo -e "${RED}抱歉啾，出现了问题：$1${NC}"
    echo -e "${RED}建议解决方案：${NC}"
    echo -e "${WHITE}1. 更换网络节点${NC}"
    echo -e "${WHITE}2. 加群询问：${MAIN_GROUP}${NC}"
    echo -e "${WHITE}3. 更新脚本${NC}"
}

say_info() {
    echo -e "${BLUE}$1${NC}"
}

# =========================================================================
# Termux源修复函数（修改sources.list）
# =========================================================================
fix_termux_sources() {
    echo -e "${YELLOW}检测到Termux镜像源问题，正在尝试修复，咕咕咕...${NC}"
    echo ""

    echo -e "${CYAN}请选择Termux镜像源：${NC}"
    echo ""
    for i in "${!TERMUX_MIRROR_NAMES[@]}"; do
        echo -e "  ${BLUE}$((i+1)).${NC} ${TERMUX_MIRROR_NAMES[$i]}"
    done
    echo ""

    while true; do
        read -p "$(echo -e ${YELLOW}请选择 [1-${#TERMUX_MIRROR_URLS[@]}]: ${NC})" mirror_choice
        if [[ "$mirror_choice" =~ ^[1-${#TERMUX_MIRROR_URLS[@]}]$ ]]; then
            local selected_mirror_url="${TERMUX_MIRROR_URLS[$((mirror_choice-1))]}"
            local selected_mirror_name="${TERMUX_MIRROR_NAMES[$((mirror_choice-1))]}"

            echo -e "${WHITE}正在切换到：${selected_mirror_name}${NC}"

            # 备份原始sources.list
            if [ -f "$TERMUX_SOURCES_LIST" ]; then
                cp "$TERMUX_SOURCES_LIST" "${TERMUX_SOURCES_LIST}.bak.$(date +%Y%m%d_%H%M%S)"
                say_info "已备份原始sources.list"
            fi

            # 创建新的sources.list
            if cat > "$TERMUX_SOURCES_LIST" << EOF
# The termux repository mirror from ${selected_mirror_name}:
deb ${selected_mirror_url} stable main
EOF
            then
                say_success "Termux镜像源配置文件修改成功"

                # 清理包管理器缓存
                say_info "清理包管理器缓存"
                rm -rf "${PREFIX}/var/lib/apt/lists"/* 2>/dev/null

                # 测试新的镜像源 - 使用pkg命令
                say_info "测试新的镜像源"
                echo -e "${WHITE}正在执行: pkg update${NC}"

                local test_output
                test_output=$(pkg update 2>&1)
                local test_status=$?

                if [ $test_status -eq 0 ]; then
                    say_success "新镜像源工作正常"
                    return 0
                else
                    echo -e "${YELLOW}镜像源测试结果：${NC}"
                    echo "$test_output"

                    # 检查是否还是同样的错误
                    if echo "$test_output" | grep -q "Clearsigned file isn't valid\|not signed\|Failed to fetch\|NOSPLIT"; then
                        echo -e "${YELLOW}新镜像源可能也有问题，但已完成切换${NC}"
                        echo -e "${YELLOW}建议尝试其他镜像源或稍后重试${NC}"
                    else
                        say_success "镜像源切换成功"
                    fi
                    return 0
                fi
            else
                say_error "sources.list文件修改失败"
                return 1
            fi
            break
        else
            say_error "无效选择，请重新输入"
        fi
    done
}

# =========================================================================
# 面板界面
# =========================================================================
print_banner() {
    clear
    echo ""
	echo -e "${CYAN} ____     _     ___  ____     _     ___ ${NC}"
	echo -e "${CYAN}|  _ \   / \   |_ _||  _ \   / \   |_ _|	${NC}"
	echo -e "${CYAN}| | | | / _ \   | | | | | | / _ \   | | ${NC}"
	echo -e "${CYAN}| |_| |/ ___ \  | | | |_| |/ ___ \  | | ${NC}"
	echo -e "${CYAN}|____//_/   \_\|___||____//_/   \_\|___|${NC}"
    echo ""
    echo -e "${BLUE}       呆呆鸟SillyTavern酒馆多功能面板        ${NC}"
    echo ""
    echo -e "${WHITE}作者：${AUTHOR}    脚本版本：v${SCRIPT_VERSION}    更新日期：${UPDATE_DATE}${NC}"
    echo ""
    echo -e "${YELLOW}加入酒馆交流群获得最新模型咨询${NC}"
    echo -e "${WHITE}AI交流群，api购买Q群：${MAIN_GROUP}${NC}"
    echo ""
}

print_main_menu() {
    echo -e "${GREEN}主要功能：${NC}"
    echo ""
    echo -e "  ${BLUE}1.${NC} 一键部署 SillyTavern 酒馆"
    echo -e "  ${BLUE}2.${NC} 启动 SillyTavern 酒馆"
    echo -e "  ${BLUE}3.${NC} 更新 SillyTavern 酒馆"
    echo -e "  ${BLUE}4.${NC} 安装酒馆插件"
    echo ""
    echo -e "${GREEN}更多服务：${NC}"
    echo ""
    echo -e "  ${BLUE}5.${NC} AI交流群详情"
    echo -e "  ${BLUE}6.${NC} 获取酒馆API"
    echo ""
    echo -e "${GREEN}系统工具：${NC}"
    echo ""
    echo -e "  ${BLUE}8.${NC} 修复Termux镜像源"
    echo ""
    echo -e "  ${BLUE}0.${NC} 退出面板"
    echo ""
}

# =========================================================================
# 功能1：一键部署 SillyTavern
# =========================================================================
deploy_sillytavern() {
    print_banner
    say_hello
    echo ""

    if [ -d "$SILLYTAVERN_PATH" ]; then
        say_warning "检测到已安装 SillyTavern"
        echo ""
        read -p "$(echo -e ${YELLOW}是否重新部署？[y/N]: ${NC})" redeploy
        if [[ ! "$redeploy" =~ ^[Yy]$ ]]; then
            return 0
        fi
        rm -rf "$SILLYTAVERN_PATH"
    fi

    # 选择网络节点
    select_network_nodes

    # 选择部署方法
    select_deploy_method

    # 准备基础环境
    prepare_basic_environment

    # 执行部署
    case "$DEPLOY_METHOD" in
        "termux")
            if deploy_method_termux; then
                show_deploy_success
            else
                show_deploy_error
            fi
            ;;
        "ubuntu")
            if deploy_method_ubuntu; then
                show_deploy_success
            else
                show_deploy_error
            fi
            ;;
    esac

    read -p "$(echo -e ${YELLOW}按回车键返回主菜单...${NC})"
}

# 网络节点选择功能
select_network_nodes() {
    print_banner
    echo -e "${CYAN}网络节点配置${NC}"
    echo ""

    # 选择GitHub镜像源
    echo -e "${GREEN}请选择GitHub镜像源：${NC}"
    echo ""
    for i in "${!GITHUB_MIRROR_NAMES[@]}"; do
        echo -e "  ${BLUE}$((i+1)).${NC} ${GITHUB_MIRROR_NAMES[$i]}"
    done
    echo ""

    while true; do
        read -p "$(echo -e ${YELLOW}请选择 [1-${#GITHUB_MIRRORS[@]}]: ${NC})" github_choice
        if [[ "$github_choice" =~ ^[1-${#GITHUB_MIRRORS[@]}]$ ]]; then
            CURRENT_GITHUB_MIRROR="${GITHUB_MIRRORS[$((github_choice-1))]}"
            say_success "GitHub镜像源：${GITHUB_MIRROR_NAMES[$((github_choice-1))]}"
            break
        else
            say_error "无效选择，请重新输入"
        fi
    done

    echo ""

    # 选择NPM镜像源
    echo -e "${GREEN}请选择NPM镜像源：${NC}"
    echo ""
    for i in "${!NPM_MIRROR_NAMES[@]}"; do
        echo -e "  ${BLUE}$((i+1)).${NC} ${NPM_MIRROR_NAMES[$i]}"
    done
    echo ""

    while true; do
        read -p "$(echo -e ${YELLOW}请选择 [1-${#NPM_MIRRORS[@]}]: ${NC})" npm_choice
        if [[ "$npm_choice" =~ ^[1-${#NPM_MIRRORS[@]}]$ ]]; then
            CURRENT_NPM_MIRROR="${NPM_MIRRORS[$((npm_choice-1))]}"
            say_success "NPM镜像源：${NPM_MIRROR_NAMES[$((npm_choice-1))]}"
            break
        else
            say_error "无效选择，请重新输入"
        fi
    done

    echo ""

    # 选择Ubuntu镜像源
    echo -e "${GREEN}请选择Ubuntu镜像源：${NC}"
    echo ""
    for i in "${!UBUNTU_MIRROR_NAMES[@]}"; do
        echo -e "  ${BLUE}$((i+1)).${NC} ${UBUNTU_MIRROR_NAMES[$i]}"
    done
    echo ""

    while true; do
        read -p "$(echo -e ${YELLOW}请选择 [1-${#UBUNTU_MIRRORS[@]}]: ${NC})" ubuntu_choice
        if [[ "$ubuntu_choice" =~ ^[1-${#UBUNTU_MIRRORS[@]}]$ ]]; then
            CURRENT_UBUNTU_MIRROR="${UBUNTU_MIRRORS[$((ubuntu_choice-1))]}"
            say_success "Ubuntu镜像源：${UBUNTU_MIRROR_NAMES[$((ubuntu_choice-1))]}"
            break
        else
            say_error "无效选择，请重新输入"
        fi
    done

    echo ""
    say_info "网络节点配置完成，即将开始部署"
    echo ""
    read -p "$(echo -e ${YELLOW}按回车键继续部署...${NC})"
}

select_deploy_method() {
    print_banner
    echo -e "${GREEN}请选择部署方式：${NC}"
    echo ""
    echo -e "  ${BLUE}1.${NC} 直接在Termux中部署 ${GREEN}(推荐，简单快速)${NC}"
    echo -e "  ${BLUE}2.${NC} 在Ubuntu系统中部署 ${YELLOW}(备用方案)${NC}"
    echo ""

    while true; do
        read -p "$(echo -e ${YELLOW}请输入选择 [1-2]: ${NC})" choice
        case $choice in
            1)
                DEPLOY_METHOD="termux"
                say_info "选择：直接在Termux中部署"
                break
                ;;
            2)
                DEPLOY_METHOD="ubuntu"
                say_info "选择：在Ubuntu系统中部署"
                say_warning "Ubuntu部署可能遇到包依赖问题"
                break
                ;;
            *)
                say_error "无效选择，请输入1或2"
                ;;
        esac
    done
    echo ""
}

prepare_basic_environment() {
    say_working "准备基础环境"
    echo ""

    # 检查Termux环境
    if [ -z "$PREFIX" ] || [[ "$PREFIX" != "/data/data/com.termux/files/usr" ]]; then
        echo -e "${RED}错误：本脚本仅适用于 Termux 环境${NC}"
        say_error "环境检测失败"
        exit 1
    fi

    # 获取存储权限
    local storage_dir="$HOME/storage/shared"
    if [ ! -d "$storage_dir" ]; then
        say_info "获取存储权限"
        if command -v termux-setup-storage >/dev/null 2>&1; then
            termux-setup-storage
            sleep 2
        fi
    fi

    # 配置清华源（像原始脚本一样）
    say_info "配置Termux镜像源"
    ln -sf /data/data/com.termux/files/usr/etc/termux/mirrors/chinese_mainland/mirrors.tuna.tsinghua.edu.cn \
           /data/data/com.termux/files/usr/etc/termux/chosen_mirrors 2>/dev/null

    # 更新Termux包管理器（恢复使用pkg命令，像原始脚本一样）
    say_info "更新Termux包管理器"
    echo -e "${WHITE}正在执行: pkg update && pkg upgrade${NC}"

    local update_output
    update_output=$(pkg update && pkg upgrade -y -o Dpkg::Options::="--force-confnew" 2>&1)
    local update_status=$?

    if [ $update_status -ne 0 ]; then
        echo -e "${RED}包管理器更新失败，错误信息：${NC}"
        echo "$update_output"

        # 检查是否是镜像源问题
        if echo "$update_output" | grep -q "Clearsigned file isn't valid\|not signed\|Failed to fetch\|NOSPLIT\|bad signature\|403 Forbidden"; then
            echo ""
            echo -e "${YELLOW}检测到Termux镜像源问题${NC}"
            if fix_termux_sources; then
                # 源修复成功，继续升级
                echo -e "${WHITE}正在执行: pkg upgrade${NC}"
                if ! pkg upgrade -y -o Dpkg::Options::="--force-confnew"; then
                    echo -e "${RED}包升级失败，但不影响部署，继续进行...${NC}"
                fi
            else
                say_error "Termux源修复失败"
                return 1
            fi
        else
            say_error "包管理器更新失败"
            return 1
        fi
    fi

    say_success "基础环境准备"
    echo ""
}

# 安装基础依赖（恢复使用pkg命令）
install_basic_deps() {
    local deps=("$@")

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            say_info "安装: $dep"
            echo -e "${WHITE}正在执行: pkg install -y $dep${NC}"
            case "$dep" in
                "nodejs")
                    if ! pkg install -y nodejs-lts; then
                        echo -e "${YELLOW}nodejs-lts安装失败，尝试安装nodejs${NC}"
                        if ! pkg install -y nodejs; then
                            echo -e "${RED}nodejs安装失败，完整错误信息：${NC}"
                            pkg install -y nodejs 2>&1
                            say_error "nodejs安装失败"
                            return 1
                        fi
                    fi
                    npm config set prefix "$PREFIX"
                    ;;
                *)
                    if ! pkg install -y "$dep"; then
                        echo -e "${RED}$dep 安装失败，完整错误信息：${NC}"
                        pkg install -y "$dep" 2>&1
                        say_error "$dep 安装失败"
                        return 1
                    fi
                    ;;
            esac
        else
            echo -e "${WHITE}$dep 已安装${NC}"
        fi
    done
}

# Termux部署方法
deploy_method_termux() {
    say_working "在Termux中部署SillyTavern"
    echo ""

    # 安装需要的依赖
    if ! install_basic_deps "git" "curl" "nodejs"; then
        return 1
    fi

    cd "$HOME" || exit 1

    # 克隆SillyTavern
    say_info "克隆SillyTavern仓库"
    echo -e "${WHITE}正在执行: git clone ${CURRENT_GITHUB_MIRROR}/SillyTavern/SillyTavern${NC}"
    rm -rf "SillyTavern" 2>/dev/null
    if ! git clone "${CURRENT_GITHUB_MIRROR}/SillyTavern/SillyTavern" "SillyTavern"; then
        echo -e "${RED}SillyTavern克隆失败，完整错误信息：${NC}"
        git clone "${CURRENT_GITHUB_MIRROR}/SillyTavern/SillyTavern" "SillyTavern" 2>&1
        say_error "SillyTavern克隆失败"
        return 1
    fi

    # 安装依赖
    cd "SillyTavern" || return 1
    say_info "配置NPM镜像源并安装依赖"
    echo -e "${WHITE}正在执行: npm config set registry ${CURRENT_NPM_MIRROR}${NC}"
    npm config set registry "$CURRENT_NPM_MIRROR"
    export NODE_ENV=production

    echo -e "${WHITE}正在执行: npm install --no-audit --no-fund --loglevel=error --omit=dev${NC}"
    if ! npm install --no-audit --no-fund --loglevel=error --omit=dev; then
        echo -e "${RED}依赖安装失败，完整错误信息：${NC}"
        npm install --no-audit --no-fund --omit=dev 2>&1
        say_error "依赖安装失败"
        return 1
    fi

    return 0
}

# Ubuntu部署方法
deploy_method_ubuntu() {
    say_working "在Ubuntu系统中部署SillyTavern"
    echo ""

    # 安装proot-distro
    if ! install_basic_deps "proot-distro"; then
        return 1
    fi

    # 安装Ubuntu系统
    if ! install_ubuntu_system; then
        return 1
    fi

    # 创建部署脚本
    create_ubuntu_deploy_script

    # 创建启动脚本
    create_ubuntu_launcher

    # 进入Ubuntu执行部署
    say_info "进入Ubuntu系统继续部署"
    echo -e "${WHITE}正在执行: proot-distro login ubuntu -- bash /root/ultra_minimal_deploy.sh${NC}"
    if ! proot-distro login ubuntu -- bash /root/ultra_minimal_deploy.sh; then
        echo -e "${RED}Ubuntu内部署失败，完整错误信息：${NC}"
        proot-distro login ubuntu -- bash /root/ultra_minimal_deploy.sh 2>&1
        say_error "Ubuntu内部署失败"
        return 1
    fi

    return 0
}

install_ubuntu_system() {
    if [ ! -d "$UBUNTU_ROOT" ]; then
        say_info "安装Ubuntu系统（使用镜像加速）"
        echo -e "${WHITE}正在执行: proot-distro install ubuntu${NC}"

        export PROOT_DISTRO_MIRROR="$CURRENT_UBUNTU_MIRROR"
        if ! DEBIAN_FRONTEND=noninteractive proot-distro install ubuntu; then
            echo -e "${RED}Ubuntu系统安装失败，完整错误信息：${NC}"
            DEBIAN_FRONTEND=noninteractive proot-distro install ubuntu 2>&1
            say_error "Ubuntu系统安装失败"
            return 1
        fi

        if [ ! -d "$UBUNTU_ROOT" ]; then
            say_error "Ubuntu系统安装失败，目录不存在"
            return 1
        fi

        configure_ubuntu_sources
        say_info "更新Ubuntu包列表"
        echo -e "${WHITE}正在执行: apt update${NC}"
        if ! proot-distro login ubuntu -- bash -c "apt update"; then
            echo -e "${RED}Ubuntu包列表更新失败，完整错误信息：${NC}"
            proot-distro login ubuntu -- bash -c "apt update" 2>&1
            say_error "Ubuntu包列表更新失败"
            return 1
        fi
    else
        say_info "Ubuntu系统已存在"
        configure_ubuntu_sources
    fi
    return 0
}

configure_ubuntu_sources() {
    local sources_file="$UBUNTU_ROOT/etc/apt/sources.list"

    say_info "配置Ubuntu软件源"
    [ -f "$sources_file" ] && cp "$sources_file" "$sources_file.bak"

    local base_url="${CURRENT_UBUNTU_MIRROR%/}"

    cat > "$sources_file" << EOF
deb ${base_url} jammy main restricted universe multiverse
deb ${base_url} jammy-updates main restricted universe multiverse
deb ${base_url} jammy-backports main restricted universe multiverse
deb ${base_url} jammy-security main restricted universe multiverse
EOF
}

create_ubuntu_deploy_script() {
    local deploy_script="$UBUNTU_ROOT/root/ultra_minimal_deploy.sh"

    cat > "$deploy_script" << EOF
#!/bin/bash
set -e

echo "=== Ubuntu系统内SillyTavern部署脚本 ==="

export DEBIAN_FRONTEND=noninteractive

echo "更新包列表..."
apt update

if ! command -v curl >/dev/null 2>&1; then
    echo "安装curl..."
    apt install -y curl
fi

if ! command -v wget >/dev/null 2>&1; then
    echo "安装wget..."
    apt install -y wget
fi

echo "手动安装Node.js..."
cd /root

NODE_VERSION="v22.16.0"
NODE_ARCHIVE="node-\${NODE_VERSION}-linux-arm64.tar.xz"

if [ ! -f "\$NODE_ARCHIVE" ]; then
    echo "下载Node.js..."
    curl -O "https://nodejs.org/dist/\${NODE_VERSION}/\${NODE_ARCHIVE}"
    if [ \$? -ne 0 ]; then
        echo "错误：Node.js下载失败！"
        exit 1
    fi
fi

if ! command -v tar >/dev/null 2>&1; then
    apt install -y tar
fi

if [ ! -d "node-\${NODE_VERSION}-linux-arm64" ]; then
    echo "解压Node.js..."
    tar xf "\$NODE_ARCHIVE"
fi

echo "export PATH=\\\$PATH:/root/node-\${NODE_VERSION}-linux-arm64/bin" >> /etc/profile
export PATH=\$PATH:/root/node-\${NODE_VERSION}-linux-arm64/bin

echo "验证Node.js..."
node --version
npm --version

npm config set registry "${CURRENT_NPM_MIRROR}"

if [ ! -d "/root/SillyTavern" ]; then
    echo "下载SillyTavern源码..."
    curl -L "${CURRENT_GITHUB_MIRROR}/SillyTavern/SillyTavern/archive/refs/heads/release.tar.gz" -o sillytavern.tar.gz

    if [ \$? -eq 0 ]; then
        echo "解压SillyTavern..."
        tar xzf sillytavern.tar.gz
        mv SillyTavern-release SillyTavern
        rm sillytavern.tar.gz
    else
        echo "错误：SillyTavern下载失败！"
        exit 1
    fi
fi

cd /root/SillyTavern
echo "安装SillyTavern依赖..."
export NODE_ENV=production
npm install --no-audit --no-fund --loglevel=error --omit=dev

if [ \$? -ne 0 ]; then
    echo "错误：依赖安装失败！"
    exit 1
fi

echo "=== Ubuntu部署完成！ ==="
EOF

    chmod +x "$deploy_script"
}

create_ubuntu_launcher() {
    # Ubuntu内部启动脚本
    cat > "$UBUNTU_ROOT/root/start_sillytavern.sh" << 'EOF'
#!/bin/bash
export PATH=$PATH:/root/node-v22.16.0-linux-arm64/bin
cd /root/SillyTavern
echo "在Ubuntu中启动 SillyTavern..."
echo "访问地址: http://localhost:8000"
echo "按 Ctrl+C 停止服务"
node server.js
EOF

    chmod +x "$UBUNTU_ROOT/root/start_sillytavern.sh"
}

show_deploy_success() {
    echo ""
    say_success "SillyTavern 部署完成"
    say_info "访问地址：http://localhost:8000"
    say_info "宝子现在可以使用启动功能来运行酒馆"
    echo ""
}

show_deploy_error() {
    echo ""
    say_error "部署失败"
    echo ""
}

# =========================================================================
# 功能8：修复Termux镜像源（修改sources.list）
# =========================================================================
fix_termux_sources_menu() {
    print_banner
    echo -e "${CYAN}修复Termux镜像源${NC}"
    echo ""

    echo -e "${YELLOW}此功能将帮助宝子修复Termux镜像源问题${NC}"
    echo -e "${WHITE}常见问题：${NC}"
    echo -e "${WHITE}• Clearsigned file isn't valid${NC}"
    echo -e "${WHITE}• Repository is not signed${NC}"
    echo -e "${WHITE}• Failed to fetch${NC}"
    echo -e "${WHITE}• 403 Forbidden${NC}"
    echo ""

    # 显示当前使用的镜像源
    if [ -f "$TERMUX_SOURCES_LIST" ]; then
        echo -e "${BLUE}当前镜像源配置：${NC}"
        local current_url=$(grep -o 'https://[^[:space:]]*' "$TERMUX_SOURCES_LIST" | head -1)
        if [ -n "$current_url" ]; then
            case "$current_url" in
                *"tuna.tsinghua"*) echo -e "${WHITE}清华大学镜像${NC}" ;;
                *"bfsu"*) echo -e "${WHITE}北京外国语大学镜像${NC}" ;;
                *"ustc"*) echo -e "${WHITE}中科大镜像${NC}" ;;
                *"aliyun"*) echo -e "${WHITE}阿里云镜像${NC}" ;;
                *"packages-cf.termux.org"*) echo -e "${WHITE}Termux官方源${NC}" ;;
                *) echo -e "${WHITE}$current_url${NC}" ;;
            esac
        else
            echo -e "${YELLOW}无法识别当前源${NC}"
        fi
        echo ""
    fi

    read -p "$(echo -e ${YELLOW}是否继续修复？[y/N]: ${NC})" confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        fix_termux_sources
    fi

    read -p "$(echo -e ${YELLOW}按回车键返回主菜单...${NC})"
}

# =========================================================================
# 功能2：启动 SillyTavern
# =========================================================================
start_sillytavern() {
    print_banner
    say_hello
    echo ""

    if [ ! -d "$SILLYTAVERN_PATH" ]; then
        # 检查Ubuntu部署
        if [ -d "$UBUNTU_ROOT/root/SillyTavern" ]; then
            say_info "检测到Ubuntu部署，正在启动"
            echo -e "${WHITE}正在执行: proot-distro login ubuntu -- bash /root/start_sillytavern.sh${NC}"
            proot-distro login ubuntu -- bash /root/start_sillytavern.sh
        else
            say_error "还没有安装 SillyTavern"
            say_info "请先使用部署功能安装 SillyTavern"
            echo ""
            read -p "$(echo -e ${YELLOW}按回车键返回主菜单...${NC})"
        fi
        return 1
    fi

    say_working "启动 SillyTavern"
    echo ""

    cd "$SILLYTAVERN_PATH" || {
        echo -e "${RED}无法进入 SillyTavern 目录，完整错误信息：${NC}"
        ls -la "$HOME" 2>&1
        say_error "无法进入 SillyTavern 目录"
        return 1
    }

    say_success "SillyTavern 即将启动"
    say_info "访问地址：http://localhost:8000"
    say_info "停止服务：按 Ctrl+C"
    echo ""
    echo -e "${CYAN}尽情享受酒馆时光啾~${NC}"
    echo ""

    # 启动服务
    echo -e "${WHITE}正在执行: node server.js${NC}"
    node server.js
}

# =========================================================================
# 功能3：更新 SillyTavern
# =========================================================================
update_sillytavern() {
    print_banner
    say_working "更新 SillyTavern"
    echo ""

    local st_path=""
    local is_ubuntu=false

    if [ -d "$SILLYTAVERN_PATH" ]; then
        st_path="$SILLYTAVERN_PATH"
    elif [ -d "$UBUNTU_ROOT/root/SillyTavern" ]; then
        st_path="$UBUNTU_ROOT/root/SillyTavern"
        is_ubuntu=true
    else
        say_error "还没有安装 SillyTavern，无法更新"
        echo ""
        read -p "$(echo -e ${YELLOW}按回车键返回主菜单...${NC})"
        return 1
    fi

    # 备份当前版本
    say_working "备份当前配置"
    if [ -d "$BACKUP_PATH" ]; then
        rm -rf "$BACKUP_PATH"
    fi

    mkdir -p "$BACKUP_PATH"
    if [ -d "$st_path/data" ]; then
        cp -r "$st_path/data" "$BACKUP_PATH/"
        say_success "配置文件备份"
    fi

    if [ -d "$st_path/public" ]; then
        cp -r "$st_path/public" "$BACKUP_PATH/"
        say_success "公共文件备份"
    fi

    cd "$st_path" || return 1

    # 拉取最新代码
    say_working "拉取最新版本"
    echo -e "${WHITE}正在执行: git pull origin release${NC}"
    if git pull origin release; then
        say_success "代码更新"
    else
        echo -e "${RED}代码拉取失败，完整错误信息：${NC}"
        git pull origin release 2>&1
        say_error "代码拉取失败，尝试重新克隆"

        local parent_dir=$(dirname "$st_path")
        cd "$parent_dir" || return 1
        rm -rf "SillyTavern_new"

        echo -e "${WHITE}正在执行: git clone https://github.com/SillyTavern/SillyTavern.git SillyTavern_new${NC}"
        if git clone https://github.com/SillyTavern/SillyTavern.git SillyTavern_new; then
            rm -rf "$st_path"
            mv "SillyTavern_new" "$st_path"
            say_success "重新安装完成"
        else
            echo -e "${RED}重新克隆失败，完整错误信息：${NC}"
            git clone https://github.com/SillyTavern/SillyTavern.git SillyTavern_new 2>&1
            say_error "更新失败，请检查网络连接"
            return 1
        fi
    fi

    # 恢复备份的配置
    cd "$st_path" || return 1
    if [ -d "$BACKUP_PATH/data" ]; then
        rm -rf "data"
        cp -r "$BACKUP_PATH/data" "./"
        say_success "配置文件恢复"
    fi

    if [ -d "$BACKUP_PATH/public" ]; then
        cp -r "$BACKUP_PATH/public"/* "public/"
        say_success "公共文件恢复"
    fi

    # 更新依赖
    say_working "更新依赖包"
    export NODE_ENV=production

    if [ "$is_ubuntu" = true ]; then
        echo -e "${WHITE}正在执行: Ubuntu环境下npm install${NC}"
        if ! proot-distro login ubuntu -- bash -c "cd /root/SillyTavern && export PATH=\$PATH:/root/node-v22.16.0-linux-arm64/bin && npm install --no-audit --no-fund --loglevel=error --omit=dev"; then
            echo -e "${RED}Ubuntu环境下依赖更新失败，完整错误信息：${NC}"
            proot-distro login ubuntu -- bash -c "cd /root/SillyTavern && export PATH=\$PATH:/root/node-v22.16.0-linux-arm64/bin && npm install --no-audit --no-fund --omit=dev" 2>&1
            say_error "依赖更新失败"
            return 1
        fi
    else
        echo -e "${WHITE}正在执行: npm install --no-audit --no-fund --loglevel=error --omit=dev${NC}"
        if ! npm install --no-audit --no-fund --loglevel=error --omit=dev; then
            echo -e "${RED}依赖更新失败，完整错误信息：${NC}"
            npm install --no-audit --no-fund --omit=dev 2>&1
            say_error "依赖更新失败"
            return 1
        fi
    fi

    say_success "依赖更新完成"

    echo ""
    say_success "SillyTavern 更新完成"
    say_info "宝可以重新启动酒馆来体验新功能了"
    echo ""
    read -p "$(echo -e ${YELLOW}按回车键返回主菜单...${NC})"
}

# =========================================================================
# 功能4：安装酒馆插件
# =========================================================================
install_plugins() {
    print_banner
    say_working "准备安装插件"
    echo ""

    local st_path=""
    local is_ubuntu=false

    if [ -d "$SILLYTAVERN_PATH" ]; then
        st_path="$SILLYTAVERN_PATH"
    elif [ -d "$UBUNTU_ROOT/root/SillyTavern" ]; then
        st_path="$UBUNTU_ROOT/root/SillyTavern"
        is_ubuntu=true
    else
        say_error "还没有安装 SillyTavern，请先安装"
        echo ""
        read -p "$(echo -e ${YELLOW}按回车键返回主菜单...${NC})"
        return 1
    fi

    echo -e "${GREEN}可用插件：${NC}"
    echo ""
    echo -e "  ${BLUE}1.${NC} 酒馆助手"
    echo -e "${WHITE}     目前效果最强泛用性最强的扩展插件，美化扩展必须安装，手机界面必须安装${NC}"
    echo ""
    echo -e "  ${BLUE}2.${NC} 聊天记录管理器"
    echo -e "${WHITE}     上限极高的扩展，配置向量化重排序模型轻松玩上万楼不失忆，有一定上手难度且需要特殊模型，但依旧建议安装，加群获得最详细教程以及相关所需模型。${NC}"
    echo ""
    echo -e "  ${BLUE}0.${NC} 返回主菜单"
    echo ""

    read -p "$(echo -e ${YELLOW}请选择要安装的插件 [0-2]: ${NC})" plugin_choice

    case $plugin_choice in
        1)
            install_tavern_helper "$st_path" "$is_ubuntu"
            ;;
        2)
            install_chat_manager "$st_path" "$is_ubuntu"
            ;;
        0)
            return 0
            ;;
        *)
            say_error "无效的选择"
            sleep 2
            install_plugins
            ;;
    esac
}

# 安装酒馆助手插件
install_tavern_helper() {
    local st_path="$1"
    local is_ubuntu="$2"

    say_working "安装酒馆助手插件"

    if [ "$is_ubuntu" = true ]; then
        # Ubuntu环境下的安装
        echo -e "${WHITE}正在执行: Ubuntu环境下克隆酒馆助手插件${NC}"
        if ! proot-distro login ubuntu -- bash -c "
            mkdir -p /root/SillyTavern/public/scripts/extensions/third-party
            cd /root/SillyTavern/public/scripts/extensions/third-party
            if [ -d 'JS-Slash-Runner' ]; then
                rm -rf JS-Slash-Runner
            fi
            if git clone https://github.com/N0VI028/JS-Slash-Runner.git; then
                echo '酒馆助手插件安装成功'
            else
                echo '酒馆助手插件安装失败'
                exit 1
            fi
        "; then
            echo -e "${RED}Ubuntu环境下酒馆助手插件安装失败，完整错误信息：${NC}"
            proot-distro login ubuntu -- bash -c "
                cd /root/SillyTavern/public/scripts/extensions/third-party
                git clone https://github.com/N0VI028/JS-Slash-Runner.git
            " 2>&1
            say_error "酒馆助手插件安装失败"
        else
            say_success "酒馆助手插件安装完成"
            say_info "启动酒馆后可在扩展管理中启用"
        fi
    else
        # Termux环境下的安装
        local extensions_dir="$st_path/public/scripts/extensions/third-party"
        mkdir -p "$extensions_dir"
        cd "$extensions_dir" || return 1

        if [ -d "JS-Slash-Runner" ]; then
            rm -rf "JS-Slash-Runner"
        fi

        echo -e "${WHITE}正在执行: git clone https://github.com/N0VI028/JS-Slash-Runner.git${NC}"
        if git clone https://github.com/N0VI028/JS-Slash-Runner.git; then
            say_success "酒馆助手插件安装完成"
            say_info "启动酒馆后可在扩展管理中启用"
        else
            echo -e "${RED}酒馆助手插件安装失败，完整错误信息：${NC}"
            git clone https://github.com/N0VI028/JS-Slash-Runner.git 2>&1
            say_error "酒馆助手插件安装失败"
        fi
    fi

    echo ""
    read -p "$(echo -e ${YELLOW}按回车键返回主菜单...${NC})"
}

# 安装聊天记录管理器插件
install_chat_manager() {
    local st_path="$1"
    local is_ubuntu="$2"

    say_working "安装聊天记录管理器插件"

    if [ "$is_ubuntu" = true ]; then
        # Ubuntu环境下的安装
        echo -e "${WHITE}正在执行: Ubuntu环境下克隆聊天记录管理器插件${NC}"
        if ! proot-distro login ubuntu -- bash -c "
            mkdir -p /root/SillyTavern/public/scripts/extensions/third-party
            cd /root/SillyTavern/public/scripts/extensions/third-party
            if [ -d 'vectors-enhanced' ]; then
                rm -rf vectors-enhanced
            fi
            if git clone https://github.com/RaphllA/vectors-enhanced.git; then
                echo '聊天记录管理器插件安装成功'
            else
                echo '聊天记录管理器插件安装失败'
                exit 1
            fi
        "; then
            echo -e "${RED}Ubuntu环境下聊天记录管理器插件安装失败，完整错误信息：${NC}"
            proot-distro login ubuntu -- bash -c "
                cd /root/SillyTavern/public/scripts/extensions/third-party
                git clone https://github.com/RaphllA/vectors-enhanced.git
            " 2>&1
            say_error "聊天记录管理器插件安装失败"
        else
            say_success "聊天记录管理器插件安装完成"
            say_info "此插件可以增强聊天记录的管理功能"
        fi
    else
        # Termux环境下的安装
        local extensions_dir="$st_path/public/scripts/extensions/third-party"
        mkdir -p "$extensions_dir"
        cd "$extensions_dir" || return 1

        if [ -d "vectors-enhanced" ]; then
            rm -rf "vectors-enhanced"
        fi

        echo -e "${WHITE}正在执行: git clone https://github.com/RaphllA/vectors-enhanced.git${NC}"
        if git clone https://github.com/RaphllA/vectors-enhanced.git; then
            say_success "聊天记录管理器插件安装完成"
            say_info "此插件可以增强聊天记录的管理功能"
        else
            echo -e "${RED}聊天记录管理器插件安装失败，完整错误信息：${NC}"
            git clone https://github.com/RaphllA/vectors-enhanced.git 2>&1
            say_error "聊天记录管理器插件安装失败"
        fi
    fi

    echo ""
    read -p "$(echo -e ${YELLOW}按回车键返回主菜单...${NC})"
}

# =========================================================================
# 功能5-6：信息展示功能
# =========================================================================
show_contact_info() {
    print_banner
    echo -e "${GREEN}AI交流群详情${NC}"
    echo ""
    echo -e "${BLUE}欢迎宝子使用呆呆鸟一键脚本${NC}"
    echo -e "${WHITE}看到这里，说明宝子是一位聪明机智的酒馆爱好者${NC}"
    echo -e "${WHITE}对酒馆有着满满的热情${NC}"
    echo -e "${RED}酒馆搭建失败/卡在莫名其妙的报错上？${NC}"
    echo -e "${RED}进入酒馆两眼空空，不知道从何玩起？${NC}"
    echo -e "${WHITE}好不容易开启对话${NC}"
    echo -e "${RED}又被预设/正则/插件/角色卡搞得一头雾水？${NC}"
    echo -e "${RED}找不到好用的加速器/魔法/梯子？${NC}"
    echo -e "${RED}最后被爆红/空回/截断/道歉/重复/失忆/掉状态栏等问题折磨？${NC}"
    echo -e "${CYAN}立马添加${MAIN_GROUP}解决问题吧！${NC}"
    echo -e "${YELLOW}在这里，宝子会找到全部的答案~${NC}"
    echo ""
    read -p "$(echo -e ${YELLOW}按回车键返回主菜单...${NC})"
}

show_free_api() {
    print_banner
    echo -e "${GREEN}获取酒馆API${NC}"
    echo ""
    echo -e "${BLUE}什么是API？酒馆为什么需要API？${NC}"
    echo -e "${WHITE}假如把酒馆比作汽车，那么API就是汽油${NC}"
    echo -e "${WHITE}宝子用一键脚本部署好酒馆，相当于在工厂组装好了汽车。接下来只要给汽车加上油就可以上路啦${NC}"
    echo -e "${WHITE}无论宝子是萌新还是老司机，都需要一个好用的API才能安全上路哦（笑）${NC}"
    echo -e "${WHITE}那么如何获取便宜好用的API呢？${NC}"
    echo -e "${BLUE}欢迎加入呆呆鸟API交流群：${MAIN_GROUP}${NC}"
    echo -e "${WHITE}这里有——${NC}"
    echo -e "${YELLOW}★一块钱1块钱25次，再打八折的超便宜API${NC}"
    echo -e "${WHITE}这里有——${NC}"
    echo -e "${YELLOW}★注册即送试吃的免费API尝鲜套餐${NC}"
    echo -e "${WHITE}这里还有——${NC}"
    echo -e "${YELLOW}★满血官方直连claude 4o/4.1o${NC}"
    echo -e "${YELLOW}★超长上下文，谷歌满血gemini${NC}"
    echo -e "${YELLOW}★独家特调的高智商claude/gemini${NC}"
    echo -e "${YELLOW}★全新上市的deepseek3.1、wolfstride等最新模型${NC}"
    echo -e "${WHITE}……${NC}"
    echo -e "${WHITE}呆呆鸟大家庭等待你的加入~${NC}"
    echo ""
    read -p "$(echo -e ${YELLOW}按回车键返回主菜单...${NC})"
}

# =========================================================================
# 主菜单循环
# =========================================================================
main_menu() {
    while true; do
        print_banner
        print_main_menu

        read -p "$(echo -e ${YELLOW}请选择功能 [0-8]: ${NC})" choice

        case $choice in
            1)
                deploy_sillytavern
                ;;
            2)
                start_sillytavern
                ;;
            3)
                update_sillytavern
                ;;
            4)
                install_plugins
                ;;
            5)
                show_contact_info
                ;;
            6)
                show_free_api
                ;;
            7)
                fix_termux_sources_menu
                ;;
            0)
                print_banner
                say_info "感谢使用 呆呆鸟 管理面板"
                echo -e "${BLUE}下次见，祝宝子使用愉快${NC}"
                echo ""
                exit 0
                ;;
            *)
                say_error "选择无效，请输入0-8之间的数字"
                sleep 2
                ;;
        esac
    done
}

# =========================================================================
# 自启动配置
# =========================================================================
setup_autostart() {
    local bashrc_file="$HOME/.bashrc"
    local script_path="$HOME/daidaibird.sh"

    # 检查是否已配置自启动
    if ! grep -q "daidaibird.sh" "$bashrc_file" 2>/dev/null; then
        echo "" >> "$bashrc_file"
        echo "# DaidaiBird SillyTavern 管理面板自启动" >> "$bashrc_file"
        echo "if [ -f \"$script_path\" ]; then" >> "$bashrc_file"
        echo "    bash \"$script_path\"" >> "$bashrc_file"
        echo "fi" >> "$bashrc_file"

        say_success "自启动配置完成"
        say_info "下次打开Termux将直接显示管理面板"
    fi
}

# =========================================================================
# 脚本入口点
# =========================================================================
# 将脚本复制到用户目录
if [ "$0" != "$HOME/daidaibird.sh" ] && [ ! -f "$HOME/daidaibird.sh" ]; then
    cp "$0" "$HOME/daidaibird.sh"
    chmod +x "$HOME/daidaibird.sh"
fi

# 检查是否是首次运行，如果是则配置自启动
if [ ! -f "$HOME/.daidaibird_configured" ]; then
    setup_autostart
    touch "$HOME/.daidaibird_configured"
fi

# 启动主菜单

main_menu
