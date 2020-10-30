FROM alpine:3

RUN apk add --update --no-cache bash ca-certificates curl git jq openssh

COPY ["src", "/src/"]

ENTRYPOINT ["/src/main.sh"]
