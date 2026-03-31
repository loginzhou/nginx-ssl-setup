#!/bin/bash

# 1. 获取域名
read -p "请输入域名: " DOMAIN
CERT_SAVE_PATH="/root/cert/$DOMAIN"

# 2. 环境初始化 (安装 acme.sh)
if [ ! -d "$HOME/.acme.sh" ]; then
    curl https://get.acme.sh | sh -s email=admin@$DOMAIN
    source ~/.bashrc
fi

# 3. 极简 Nginx 验证块 (只开 80 端口用于申请，不干扰其他)
mkdir -p /var/www/html
cat <<EOF > /etc/nginx/conf.d/${DOMAIN}.conf
server {
    listen 80;
    server_name $DOMAIN;
    root /var/www/html;
}
EOF
systemctl restart nginx

# 4. 申请并安装证书
mkdir -p $CERT_SAVE_PATH
~/.acme.sh/acme.sh --issue -d $DOMAIN --nginx
~/.acme.sh/acme.sh --install-cert -d $DOMAIN \
--fullchain-file "$CERT_SAVE_PATH/fullchain.pem" \
--key-file       "$CERT_SAVE_PATH/privkey.pem" \
--reloadcmd      "systemctl restart s-ui"

echo "--------------------------------------------------"
echo "搞定！HY2 证书路径: $CERT_SAVE_PATH/fullchain.pem"
echo "以后每 3 个月，证书会自动更新并重启 s-ui，你不用再管了。"
