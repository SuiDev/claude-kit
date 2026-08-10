FROM zenika/alpine-chrome
USER root
RUN apk add --no-cache font-noto-cjk
USER chrome
