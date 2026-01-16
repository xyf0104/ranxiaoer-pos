#!/bin/bash

# ================= 配置区域 =================
# 核心文件名
FILE_NAME="ranxiaoer_secret_v22.enc"
# GitHub 仓库信息
GITHUB_USER="xyf0104"
GITHUB_REPO="ranxiaoer-pos"
GITHUB_BRANCH="main"
# ===========================================

# 线路定义
URL_PAGES="https://gh-proxy.com/https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/${FILE_NAME}"
URL_PROXY1="https://mirror.ghproxy.com/https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/${FILE_NAME}"
URL_PROXY2="https://github.moeyy.xyz/https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/${FILE_NAME}"
URL_PROXY3="https://raw.kgithub.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/${FILE_NAME}"

# 颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}  🔒 然小二 · 无风智能恢复系统 (多线路自动切换)  ${NC}"
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}======  一键下载安装  -  自动识别服务器系统  =====${NC}"
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}======        请按照系统提示操作执行        =====${NC}"
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}======      出入库系统版本v2.1  by无风      =====${NC}"
echo -e "${GREEN}=================================================${NC}"

# 1. 环境准备
if command -v apt-get >/dev/null; then
    apt-get update -qq && apt-get install -y openssl wget >/dev/null
elif command -v yum >/dev/null; then
    yum install -y openssl wget >/dev/null
fi

# 函数：尝试下载并验证
try_download() {
    local url=$1
    echo -e "${YELLOW}>> 尝试线路: $url${NC}"
    rm -f /tmp/system.enc
    wget -q -O /tmp/system.enc "$url"
    
    # 验证：文件是否存在 且 大于1KB 且 不包含 HTML 标签
    if [ -s /tmp/system.enc ] && [ $(stat -c%s /tmp/system.enc) -gt 1024 ] && ! grep -q "<!DOCTYPE" /tmp/system.enc; then
        return 0 # 成功
    else
        return 1 # 失败
    fi
}

# 2. 开始下载 (三级重试)
echo ">> 正在拉取加密镜像..."

if try_download "$URL_PAGES"; then
    echo -e "${GREEN}✅ 主线路  下载成功！${NC}"
elif try_download "$URL_PROXY1"; then
    echo -e "${GREEN}✅ 备用线路 1 下载成功！${NC}"
elif try_download "$URL_PROXY2"; then
    echo -e "${GREEN}✅ 备用线路 2 下载成功！${NC}"
elif try_download "$URL_PROXY3"; then
    echo -e "${GREEN}✅ 备用线路 3 下载成功！${NC}"    
else
    echo -e "${RED}❌ 所有线路均失败！请检查 GitHub 仓库是否有名为 ${FILE_NAME} 的文件，并确保已上传 .nojekyll 文件。${NC}"
    exit 1
fi

# 3. 密码验证
echo ""
echo "检测到加密镜像。"
echo -n "🔑 请输入恢复密码 : "
read -s PASSWORD < /dev/tty
echo ""

echo ">> 正在解密..."
# 尝试解密
openssl enc -d -aes-256-cbc -pbkdf2 -in /tmp/system.enc -out /tmp/system.tar.gz -k "$PASSWORD" 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 密码正确，解密成功！${NC}"
else
    echo -e "${RED}❌ 解密失败！可能有以下原因：${NC}"
    echo "1. 密码输入错误 (注意大小写)"
    echo "2. 文件下载不完整 (尝试重新运行)"
    rm -f /tmp/system.enc /tmp/system.tar.gz
    exit 1
fi

# 4. 部署
echo ">> 启动安装程序..."
mkdir -p /root/install
tar -xzvf /tmp/system.tar.gz -C /root/install >/dev/null 2>&1

chmod +x /root/install/smart_install.sh
cd /root/install

# 格式清洗并执行
sed -i 's/\r$//' ./smart_install.sh
./smart_install.sh < /dev/tty

# 5. 清理
rm -f /tmp/system.enc /tmp/system.tar.gz
rm -rf /root/install
