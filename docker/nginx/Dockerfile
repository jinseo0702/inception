FROM alpine:3.19

RUN apk update && apk upgrade \
    && apk add --no-cache nginx openssl

COPY ./run.sh /home/run.sh
RUN chmod +x /home/run.sh

EXPOSE 80

ENTRYPOINT source /home/run.sh