#!/bin/bash

# --- 配置区 (V1.3.2 多线路) ---
GITEE_URL="https://gitee.com/ranxiaoer/model/raw/master/ranxiaoer_v1.3.2.enc"
GITHUB_URL="https://raw.githubusercontent.com/xyf0104/ranxiaoer-pos/main/ranxiaoer_secret_v132.enc"
# ---------------------------

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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

# 2. 多线路下载加密包（优先 Gitee，失败切 GitHub）
rm -f /tmp/system.enc
DOWNLOAD_OK=0

echo ">> 正在从 Gitee 拉取数据..."
wget -U "Mozilla/5.0" -q --timeout=15 -O /tmp/system.enc "$GITEE_URL" 2>/dev/null
if [ -s /tmp/system.enc ] && ! grep -q "<!DOCTYPE html>" /tmp/system.enc 2>/dev/null; then
    DOWNLOAD_OK=1
    echo -e "${GREEN}✅ Gitee 下载成功${NC}"
else
    echo -e "${YELLOW}⚠️ Gitee 不可用，切换 GitHub 线路...${NC}"
    rm -f /tmp/system.enc
    wget -U "Mozilla/5.0" -q --timeout=15 -O /tmp/system.enc "$GITHUB_URL" 2>/dev/null
    if [ -s /tmp/system.enc ] && ! grep -q "<!DOCTYPE html>" /tmp/system.enc 2>/dev/null; then
        DOWNLOAD_OK=1
        echo -e "${GREEN}✅ GitHub 下载成功${NC}"
    fi
fi

if [ "$DOWNLOAD_OK" -ne 1 ]; then
    echo -e "${RED}❌ 下载失败！Gitee 和 GitHub 均不可用。${NC}"
    echo "请检查网络或确保仓库是【公开(Public)】的！"
    rm -f /tmp/system.enc
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
