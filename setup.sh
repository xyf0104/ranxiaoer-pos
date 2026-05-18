#!/bin/bash

# --- 配置区 (已指向 V1.3.2) ---
DOWNLOAD_URL="https://gitee.com/ranxiaoer/model/raw/master/ranxiaoer_secret_v132.enc"
# ---------------------------

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}  🔒 然小二 · 无风智能恢复系统 (多线路自动切换)  ${NC}"
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}======  一键下载安装  -  自动识别服务器系统  =====${NC}"
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}======        请按照系统提示操作执行        =====${NC}"
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}======      出入库系统版本v1.3.2  by无风      =====${NC}"
echo -e "${GREEN}=================================================${NC}"

# 1. 环境依赖检查与安装
echo ">> 正在检查系统环境..."
if command -v apt-get >/dev/null; then
    apt-get update -qq && apt-get install -y openssl wget >/dev/null
elif command -v yum >/dev/null; then
    yum install -y openssl wget >/dev/null
fi

# 2. 下载加密包
echo ">> 正在从 Gitee 拉取数据..."
rm -f /tmp/system.enc

# 增加 User-Agent 伪装，防止 Gitee 拦截
wget -U "Mozilla/5.0" -O /tmp/system.enc "$DOWNLOAD_URL"

# 3. 完整性检查
if grep -q "<!DOCTYPE html>" /tmp/system.enc; then
    echo -e "${RED}❌ 下载失败！Gitee 返回了网页而非文件。${NC}"
    echo "请确保仓库是【公开(Public)】的！"
    exit 1
fi

if [ ! -s /tmp/system.enc ]; then
    echo -e "${RED}❌ 下载失败！文件为空或网络不通。${NC}"
    exit 1
fi

echo ""
echo -n "🔑 请输入恢复密码 (预设: xyf159753): "
read -s PASSWORD < /dev/tty
echo ""

# 4. 解密
echo ">> 正在解密..."
openssl enc -d -aes-256-cbc -pbkdf2 -in /tmp/system.enc -out /tmp/system.tar.gz -k "$PASSWORD" 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 密码正确！正在部署...${NC}"
else
    echo -e "${RED}❌ 密码错误！请重新运行脚本。${NC}"
    rm -f /tmp/system.enc /tmp/system.tar.gz
    exit 1
fi

# 5. 安装与执行
echo ">> 启动安装程序..."
mkdir -p /root/install
tar -xzvf /tmp/system.tar.gz -C /root/install >/dev/null 2>&1

if [ -f "/root/install/smart_install.sh" ]; then
    chmod +x /root/install/smart_install.sh
    cd /root/install
    ./smart_install.sh < /dev/tty
else
    echo -e "${RED}❌ 错误：安装包内未找到 smart_install.sh。${NC}"
    echo "请手动检查 /root/install 目录。"
    exit 1
fi

# 6. 清理
rm -f /tmp/system.enc /tmp/system.tar.gz
rm -rf /root/install

echo -e "${GREEN}🎉 V1.3.2 部署完成！${NC}"
