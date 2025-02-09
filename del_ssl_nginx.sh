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
CERT_DIR="/root/cert/$DOMAIN"

# 1. **清理旧证书**
echo "检查并清理旧的 SSL 证书..."
~/.acme.sh/acme.sh --remove -d "$DOMAIN"
rm -rf "$CERT_DIR"
rm -f "$NGINX_CONF"

# 2. **创建 Nginx 配置文件**
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

# 3. **创建 ACME 目录**
echo "正在创建 ACME 目录..."
mkdir -p /var/www/acme

# 4. **重新加载 Nginx**
echo "正在测试并重启 Nginx..."
nginx -t && systemctl reload nginx

# 5. **申请新的 SSL 证书**
echo "正在申请 SSL 证书..."
~/.acme.sh/acme.sh --issue --nginx -d "$DOMAIN"

# 6. **安装新证书**
mkdir -p "$CERT_DIR"
echo "正在安装 SSL 证书到 $CERT_DIR ..."
~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
    --key-file "$CERT_DIR/privkey.pem" \
    --fullchain-file "$CERT_DIR/fullchain.pem" \
    --reloadcmd "systemctl reload nginx"

# 7. **更新 Nginx 配置启用 HTTPS**
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

    ssl_certificate $CERT_DIR/fullchain.pem;
    ssl_certificate_key $CERT_DIR/privkey.pem;

    location / {
        root /var/www/html;
        index index.html index.htm;
    }

    location /.well-known/acme-challenge/ {
        root /var/www/acme;
    }
}
EOF

# 8. **重新加载 Nginx 以启用 HTTPS**
echo "重新加载 Nginx 以应用 HTTPS 配置..."
nginx -t && systemctl reload nginx

# 9. **设置 acme.sh 证书自动续期任务**
echo "正在配置 SSL 证书自动续期..."
CRON_JOB="29 1 * * * \"~/.acme.sh/acme.sh\" --cron --home \"~/.acme.sh\" > /dev/null"
(crontab -l 2>/dev/null | grep -v acme.sh; echo "$CRON_JOB") | crontab -

echo "证书自动续期已设置，每天凌晨 1:29 执行一次。"
echo "SSL 配置完成！你可以通过 https://$DOMAIN 访问你的站点。"
