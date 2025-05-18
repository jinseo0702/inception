FROM alpine:3.19 

RUN apk update && apk upgrade && apk add --no-cache mariadb mariadb-client

# 데이터 디렉토리 생성 및 권한 설정
RUN mkdir -p /var/lib/mysql /var/run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld

# 데이터베이스 초기화 - 이 부분이 중요합니다!
RUN mariadb-install-db --user=mysql --datadir=/var/lib/mysql

COPY ./run.sh /home/run.sh
RUN chmod +x /home/run.sh

EXPOSE 3306

# MariaDB 서버 실행 (foreground)
ENTRYPOINT source /home/run.sh
