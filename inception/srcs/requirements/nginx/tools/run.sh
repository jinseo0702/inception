#!/bin/sh

mkdir -p /home/.oslkey

openssl genrsa -out /home/.oslkey/private.key 2048

openssl req -new -key /home/.oslkey/private.key -out /home/.oslkey/certificate.csr -subj "/CN=jinseo.42.fr" -addext "subjectAltName = DNS:jinseo.42.fr,DNS:www.jinseo.42.fr,DNS:localhost"

openssl x509 -req -days 365 -in /home/.oslkey/certificate.csr -signkey /home/.oslkey/private.key -out /home/.oslkey/certificate.crt

mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak

cat > /etc/nginx/nginx.conf <<eof

user  nginx;

worker_processes  1;

events {
    worker_connections  1024;
}

http {
    server {
        listen       443 ssl;
        root           ${NGINX_ROOT_PATH};
        server_name  ${DNS} ${DNS2} localhost;
        index index.php;
        ssl_certificate /home/.oslkey/certificate.crt;
        ssl_certificate_key /home/.oslkey/private.key;
        ssl_protocols TLSv1.3;

        port_in_redirect on;
        server_name_in_redirect on;

        location / {
            try_files \$uri \$uri/ /index.php?\$args;
        }

        location ~ \.php$ {
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass  ${WORDPRESS_HOST};
            fastcgi_index index.php;
            include       fastcgi_params;
            fastcgi_param SCRIPT_FILENAME   \$document_root\$fastcgi_script_name;
            fastcgi_param PATH_INFO \$fastcgi_path_info;
            fastcgi_param HTTP_HOST \$http_host;
        }
    }

}

eof

cat /etc/nginx/nginx.conf

chown -R nginx:nginx /var/lib/nginx
chmod 755 /var/lib/nginx

exec nginx -g 'daemon off;'
