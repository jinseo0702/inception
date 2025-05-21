FROM alpine:3.19

RUN apk update && apk upgrade \
    && apk add --no-cache nginx openssl

COPY ./tools/run.sh /home/run.sh
RUN chmod +x /home/run.sh

EXPOSE 443

ENTRYPOINT source /home/run.sh
