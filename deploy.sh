# 文件名: deploy.sh
#!/bin/bash

# 创建目标目录（如果不存在）
sudo mkdir -p /var/www/html

# 复制文件到Nginx默认目录（假设仓库文件已在当前目录）
sudo cp -v index.html /var/www/html/

# 设置文件权限（根据你的Web服务器用户调整，这里以Nginx默认用户www-data为例）
sudo chown www-data:www-data /var/www/html/index.html
sudo chmod 644 /var/www/html/index.html

# 重启Nginx服务（可选，确保新文件生效）
sudo systemctl restart nginx

echo "部署完成！请访问 http://$(curl -s ifconfig.me)"
