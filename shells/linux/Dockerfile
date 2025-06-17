FROM debian:sid

RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources
RUN apt-get update
RUN apt-get install -y pahole linux-headers-arm64
