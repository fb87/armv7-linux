CC      := ${CROSS_COMPILE}gcc
CFLAGS  := -static

BIN_DIR ?= ${shell pwd}

all: fbtest.c
	${CC} ${CFLAGS} $< -o ${BIN_DIR}/fbtest
