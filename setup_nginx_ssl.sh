#!/bin/bash

# 询问用户输入域名
read -p "请输入你的域名 (如 184.174.96.124.sslip.io): " DOMAIN

# 检查是否输入了域名
if [ -z "$DOMAIN" ]; then
    echo "错误: 请输入有效的域名！"
    exit 1
fi

# 定义 Nginx 配置文件路径
NGINX_CONF="/etc/nginx/conf.d/$DOMAIN.conf"

# 1. 创建 Nginx 配置文件
echo "正在创建 Nginx 配置文件..."
cat > "$NGINX_CONF" <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location /.well-known/acme-challenge/ {
        root /var/www/acme;
    }
}
EOF

# 2. 创建 ACME 目录
echo "正在创建 ACME 目录..."
mkdir -p /var/www/acme

# 3. 重新加载 Nginx
echo "正在测试并重启 Nginx..."
nginx -t && systemctl reload nginx

# 4. 使用 acme.sh 申请 SSL 证书
echo "正在申请 SSL 证书..."
~/.acme.sh/acme.sh --issue --nginx -d "$DOMAIN"

# 5. 安装证书并配置 Nginx
echo "正在安装 SSL 证书..."
mkdir -p /etc/nginx/ssl
~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
    --key-file /etc/nginx/ssl/$DOMAIN.key \
    --fullchain-file /etc/nginx/ssl/$DOMAIN.pem \
    --reloadcmd "systemctl reload nginx"

# 6. 生成 HTTPS Nginx 配置
echo "正在更新 Nginx 配置文件以启用 HTTPS..."
cat > "$NGINX_CONF" <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/nginx/ssl/$DOMAIN.pem;
    ssl_certificate_key /etc/nginx/ssl/$DOMAIN.key;

    location / {
        root /var/www/html;
        index index.html index.htm;
    }

    location /.well-known/acme-challenge/ {
        root /var/www/acme;
    }
}
EOF

# 7. 重新加载 Nginx 以启用 HTTPS
echo "重新加载 Nginx 以应用 HTTPS 配置..."
nginx -t && systemctl reload nginx

echo "SSL 配置完成！你可以通过 https://$DOMAIN 访问你的站点。"
