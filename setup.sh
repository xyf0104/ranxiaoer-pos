#!/bin/bash

# ================= 配置区域 =================
# 使用 jsDelivr 极速 CDN (注意：这里直接填了你的用户名和仓库)
# 格式: https://fastly.jsdelivr.net/gh/用户名/仓库名@分支名/文件名
DOWNLOAD_URL="https://fastly.jsdelivr.net/gh/xyf0104/ranxiaoer-pos@main/ranxiaoer_secret_new.enc"
# ===========================================

# 颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}   🔐 然小二系统 · GitHub 极速恢复脚本 (CDN版)${NC}"
echo -e "${GREEN}=================================================${NC}"

# 1. 检查环境
if command -v apt-get >/dev/null; then
    apt-get update -qq && apt-get install -y openssl wget >/dev/null
elif command -v yum >/dev/null; then
    yum install -y openssl wget >/dev/null
fi

# 2. 下载 (去掉了 -q 参数，显示进度条)
echo ">> 正在从 CDN 极速拉取数据..."
rm -f /tmp/system.enc
# 这里去掉了代理前缀，因为 jsDelivr 自带国内加速
wget -O /tmp/system.enc "$DOWNLOAD_URL"

if [ ! -f /tmp/system.enc ]; then
    echo -e "${RED}❌ 下载失败！请检查 GitHub 仓库内是否有 ranxiaoer_secret_new.enc 文件。${NC}"
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

# 格式清洗并执行
sed -i 's/\r$//' ./smart_install.sh
./smart_install.sh < /dev/tty

# 5. 清理
rm -f /tmp/system.enc /tmp/system.tar.gz
rm -rf /root/install
