FROM rust:latest

ARG CONFIG_TARGET
ARG CONFIG_TRIPLET

RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources
RUN apt-get update
RUN apt-get install -y clang llvm linux-headers-arm64 libelf-dev
RUN rustup component add rustfmt
RUN ln -s "/usr/include/$CONFIG_TARGET-gnu/asm" /usr/include/asm
RUN ln -s /usr/bin/gcc "/usr/bin/${CONFIG_TRIPLET}-gcc"

# To save the build time
VOLUME /usr/local/cargo/git
VOLUME /usr/local/cargo/registry
