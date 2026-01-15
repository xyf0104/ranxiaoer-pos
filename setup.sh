#!/bin/bash

# ================= 配置区域 =================
# 使用 GitHub Pages 链接 (无需代理，更新快，格式稳定)
# 格式: https://用户名.github.io/仓库名/文件名
DOWNLOAD_URL="https://xyf0104.github.io/ranxiaoer-pos/ranxiaoer_secret_v17.enc"
# ===========================================

# 颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}   🔐 然小二系统 · GitHub Pages 极速版${NC}"
echo -e "${GREEN}=================================================${NC}"

# 1. 检查环境
if command -v apt-get >/dev/null; then
    apt-get update -qq && apt-get install -y openssl wget >/dev/null
elif command -v yum >/dev/null; then
    yum install -y openssl wget >/dev/null
fi

# 2. 下载
echo ">> 正在拉取数据..."
rm -f /tmp/system.enc
# 尝试直连 Pages
wget -q -O /tmp/system.enc "$DOWNLOAD_URL"

# 如果 Pages 在国内被墙，尝试 ghproxy 加速 Raw 链接作为备用
if [ ! -s /tmp/system.enc ]; then
    echo ">> 直连失败，尝试加速通道..."
    wget -q -O /tmp/system.enc "https://mirror.ghproxy.com/https://raw.githubusercontent.com/xyf0104/ranxiaoer-pos/main/ranxiaoer_secret_v17.enc"
fi

if [ ! -s /tmp/system.enc ]; then
    echo -e "${RED}❌ 下载失败！请检查文件名 ranxiaoer_secret_v17.enc 是否存在。${NC}"
    exit 1
fi

# 3. 密码验证
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
    echo -e "${RED}❌ 密码错误！请确认密码是打包时设置的那个。${NC}"
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
