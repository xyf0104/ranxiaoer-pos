#!/bin/bash

# ================= 配置区域 =================
# 注意：这里我们只填 GitHub 的原始链接，脚本下面会自动加加速前缀
GITHUB_FILE_URL="https://github.com/xyf0104/ranxiaoer-pos/raw/refs/heads/main/ranxiaoer_secret_new.enc"
# ===========================================

# 定义加速代理 (使用 mirror.ghproxy.com 比较稳)
PROXY_PREFIX="https://mirror.ghproxy.com/"
DOWNLOAD_URL="${PROXY_PREFIX}${GITHUB_FILE_URL}"

# 颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}   🔐 然小二系统 · GitHub 极速恢复脚本 (CN版)${NC}"
echo -e "${GREEN}=================================================${NC}"

# 1. 检查环境
if command -v apt-get >/dev/null; then
    apt-get update -qq && apt-get install -y openssl wget >/dev/null
elif command -v yum >/dev/null; then
    yum install -y openssl wget >/dev/null
fi

# 2. 下载 (使用加速链)
echo ">> 正在从镜像加速节点拉取数据..."
rm -f /tmp/system.enc
wget -O /tmp/system.enc "$DOWNLOAD_URL"

# 如果加速失败，尝试直连作为备选
if [ ! -f /tmp/system.enc ] || [ ! -s /tmp/system.enc ]; then
    echo ">> 加速节点失败，尝试直连..."
    wget -O /tmp/system.enc "$GITHUB_FILE_URL"
fi

if [ ! -f /tmp/system.enc ] || [ ! -s /tmp/system.enc ]; then
    echo -e "${RED}❌ 下载失败！请检查 GitHub 链接是否正确。${NC}"
    exit 1
fi

# 3. 密码验证 (强制读取键盘 < /dev/tty)
echo ""
echo "检测到加密镜像。"
echo -n "🔑 请输入恢复密码: "
read -s PASSWORD < /dev/tty
echo ""

echo ">> 正在解密..."
openssl enc -d -aes-256-cbc -pbkdf2 -in /tmp/system.enc -out /tmp/system.tar.gz -k "$PASSWORD" 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 密码正确，解密成功！${NC}"
else
    echo -e "${RED}❌ 密码错误或文件损坏！${NC}"
    rm -f /tmp/system.enc /tmp/system.tar.gz
    exit 1
fi

# 4. 部署
echo ">> 启动安装程序..."
mkdir -p /root/install
tar -xzvf /tmp/system.tar.gz -C /root/install >/dev/null 2>&1

chmod +x /root/install/smart_install.sh
cd /root/install

# 格式清洗并执行 (再次使用 < /dev/tty 确保子脚本能交互)
sed -i 's/\r$//' ./smart_install.sh
./smart_install.sh < /dev/tty

# 5. 清理
rm -f /tmp/system.enc /tmp/system.tar.gz
rm -rf /root/install
