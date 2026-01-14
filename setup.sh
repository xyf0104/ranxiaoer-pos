#!/bin/bash

# ================= 配置区域 =================
# ⚠️ 把下面的链接换成你刚才复制的 GitHub Raw 链接
# 格式通常是: https://raw.githubusercontent.com/用户名/仓库名/main/文件名
DOWNLOAD_URL="https://github.com/xyf0104/ranxiaoer-pos/raw/refs/heads/main/ranxiaoer_secret_new.enc"
# ===========================================

# 自动使用国内加速节点 (解决 GitHub 连不上的问题)
PROXY_URL="https://ghproxy.com/"
FINAL_URL="${PROXY_URL}${DOWNLOAD_URL}"

# 颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}   🔐 然小二系统 · GitHub 极速恢复脚本${NC}"
echo -e "${GREEN}=================================================${NC}"

# 1. 检查环境
if command -v apt-get >/dev/null; then
    apt-get update -qq && apt-get install -y openssl wget >/dev/null
elif command -v yum >/dev/null; then
    yum install -y openssl wget >/dev/null
fi

# 2. 下载 (通过加速节点)
echo ">> 正在拉取数据..."
rm -f /tmp/system.enc
wget -q -O /tmp/system.enc "$FINAL_URL"

if [ ! -f /tmp/system.enc ]; then
    echo -e "${RED}❌ 下载失败，请检查 GitHub 链接是否正确。${NC}"
    exit 1
fi

# 3. 密码验证 (强制读取键盘)
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

# 强制转换格式并执行
sed -i 's/\r$//' ./smart_install.sh
./smart_install.sh < /dev/tty

# 5. 清理
rm -f /tmp/system.enc /tmp/system.tar.gz
rm -rf /root/install
