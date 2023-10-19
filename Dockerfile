FROM    ubuntu:22.04

RUN     apt update -y
RUN     DEBIAN_FRONTEND=noninteractive TZ=Asia/Ho_Chi_Minh apt install -y crossbuild-essential-armhf bison flex
RUN     DEBIAN_FRONTEND=noninteractive TZ=Asia/Ho_Chi_Minh apt install -y python3 python3-distutils python3-dev libssl-dev python3-setuptools
RUN     DEBIAN_FRONTEND=noninteractive TZ=Asia/Ho_Chi_Minh apt install -y bc cpio u-boot-tools kmod ncurses-dev swig

ENV     ARCH=arm
ENV     CROSS_COMPILE=arm-linux-gnueabihf-

CMD     [ "/bin/bash" ]
