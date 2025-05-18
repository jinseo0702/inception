# https://wordpress.org/documentation/article/get-started-with-wordpress/#step-three-install-wordpress

FROM alpine:3.19 

RUN apk update && apk upgrade && apk add --no-cache php82 \
    php82-fpm \
    php82-mysqli curl \
    php82-phar \
    php82-iconv \
    php82-mbstring

RUN mkdir -p /var/www/html/

# 데이터 디렉토리 생성 및 권한 설정
RUN curl https://wordpress.org/wordpress-6.7.2.tar.gz -o wordpress.tar.gz &&\
    tar -xzvf wordpress.tar.gz -C /var/. && \
    rm -rf wordpress.tar.gz


COPY ./use_wpcli.sh /home/run_word.sh
RUN chmod +x /home/run_word.sh

EXPOSE 9000

ENTRYPOINT source /home/run_word.sh
