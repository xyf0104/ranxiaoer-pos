#!/bin/bash

# ================= 配置区域 =================
# 使用 jsDelivr 官方格式 (最稳)
DOWNLOAD_URL="https://cdn.jsdelivr.net/gh/xyf0104/ranxiaoer-pos@main/ranxiaoer_secret_v17.enc"
# ===========================================

# 颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}   🔐 然小二系统 · 极速恢复脚本 (v17 Final)${NC}"
echo -e "${GREEN}=================================================${NC}"

# 1. 检查环境
if command -v apt-get >/dev/null; then
    apt-get update -qq && apt-get install -y openssl wget >/dev/null
elif command -v yum >/dev/null; then
    yum install -y openssl wget >/dev/null
fi

# 2. 下载
echo ">> 正在从 CDN 拉取数据..."
rm -f /tmp/system.enc
wget -O /tmp/system.enc "$DOWNLOAD_URL"

# 检查文件完整性 (如果小于 1KB 肯定不对)
FILE_SIZE=$(stat -c%s "/tmp/system.enc" 2>/dev/null || echo 0)
if [ "$FILE_SIZE" -lt 1000 ]; then
    echo -e "${RED}❌ 下载失败！可能是 CDN 缓存未刷新，请稍等 1 分钟再试。${NC}"
    echo "尝试备用链接..."
    # 备用：直接连 GitHub 源站
    wget -O /tmp/system.enc "https://github.com/xyf0104/ranxiaoer-pos/raw/main/ranxiaoer_secret_v17.enc"
fi

if [ ! -s /tmp/system.enc ]; then
    echo -e "${RED}❌ 彻底失败，请检查仓库文件是否存在。${NC}"
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
