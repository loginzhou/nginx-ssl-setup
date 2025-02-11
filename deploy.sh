#!/bin/bash

# 安装必要的依赖
sudo apt update
sudo apt install -y curl nginx

# 创建目标目录
sudo mkdir -p /var/www/html

# 从 GitHub 下载 index.html 文件
if ! curl -o /var/www/html/index.html https://raw.githubusercontent.com/loginzhou/nginx-ssl-setup/main/index.html; then
    echo "Failed to download index.html. Exiting..."
    exit 1
fi

# 修改文件权限
sudo chown www-data:www-data /var/www/html/index.html
sudo chmod 644 /var/www/html/index.html

# 重启 Nginx 使更改生效
sudo systemctl restart nginx

echo "Deployment completed successfully!"
