FROM alpine:3.19 

RUN apk update && apk upgrade && apk add --no-cache mariadb mariadb-client

RUN mkdir -p /var/lib/mysql /var/run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld

COPY ./tools/run.sh /home/run.sh
RUN chmod +x /home/run.sh

EXPOSE 3306

ENTRYPOINT source /home/run.sh
