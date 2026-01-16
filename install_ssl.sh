cat > install_ssl.sh <<'EOF'
#!/bin/bash

echo "========================================"
echo "   🔐 然小二 · 手动证书安装工具"
echo "========================================"

# 1. 检查并安装 unzip
if [ -f /etc/debian_version ]; then
    if ! command -v unzip >/dev/null; then
        apt-get update -qq && apt-get install -y unzip nginx >/dev/null
    fi
    NGINX_USER="www-data"
elif [ -f /etc/redhat-release ]; then
    if ! command -v unzip >/dev/null; then
        yum install -y unzip nginx >/dev/null
    fi
    NGINX_USER="nginx"
fi

# 2. 自动寻找 ZIP 包
ZIP_FILE=$(find . -maxdepth 1 -name "*.zip" | head -n 1)

if [ -z "$ZIP_FILE" ]; then
    echo "❌ 错误：当前目录下没有找到 .zip 证书包！"
    echo "👉 请先上传腾讯云/阿里云下载的 Nginx 证书包到当前目录。"
    exit 1
fi

echo ">> 发现证书包: $ZIP_FILE"
echo ">> 正在解压..."

# 准备临时目录
WORK_DIR="/tmp/ssl_install"
rm -rf $WORK_DIR
mkdir -p $WORK_DIR
unzip -q -o "$ZIP_FILE" -d $WORK_DIR

# 3. 智能查找
KEY_FILE=$(find $WORK_DIR -name "*.key" | head -n 1)
CERT_FILE=$(find $WORK_DIR -name "*.pem" -o -name "*.crt" -o -name "*.bundle" | head -n 1)

if [ -z "$KEY_FILE" ] || [ -z "$CERT_FILE" ]; then
    echo "❌ 错误：解压后未找到 .key 或 .pem/.crt 文件。"
    exit 1
fi

# 4. 部署证书
SSL_DIR="/etc/nginx/ssl"
mkdir -p $SSL_DIR
cp "$KEY_FILE" "$SSL_DIR/ranxiaoer.key"
cp "$CERT_FILE" "$SSL_DIR/ranxiaoer.pem"

# 5. 询问域名
echo ""
read -p "请输入你的域名 (例如 ranxiaoer.com): " DOMAIN
if [ -z "$DOMAIN" ]; then echo "域名不能为空"; exit 1; fi

# 6. Nginx 配置
echo ">> 配置 Nginx (HTTPS)..."
cat > /etc/nginx/nginx.conf <<NGINX
user $NGINX_USER;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;
include /usr/share/nginx/modules/*.conf;
events { worker_connections 1024; }
http {
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" \$status \$body_bytes_sent';
    access_log /var/log/nginx/access.log main;
    sendfile on; tcp_nopush on; tcp_nodelay on; keepalive_timeout 65; types_hash_max_size 2048;
    include /etc/nginx/mime.types; default_type application/octet-stream;

    server {
        listen 80;
        server_name $DOMAIN;
        return 301 https://\$host\$request_uri;
    }

    server {
        listen 443 ssl;
        server_name $DOMAIN;
        ssl_certificate /etc/nginx/ssl/ranxiaoer.pem;
        ssl_certificate_key /etc/nginx/ssl/ranxiaoer.key;
        ssl_session_cache shared:SSL:1m;
        ssl_session_timeout 10m;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;

        location / {
            proxy_pass http://127.0.0.1:8000;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;
        }
    }
}
NGINX

# 7. 重启
systemctl restart ranxiaoer
systemctl restart nginx
rm -rf $WORK_DIR

echo "✅ 证书安装成功！请访问 https://$DOMAIN"
EOF
