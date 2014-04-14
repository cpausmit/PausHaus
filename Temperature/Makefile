# Makefile for temperature reader
CC=gcc
CFLAGS=-Wall

all: temperature

temperature: temperature.c pcsensor.c pcsensor.h
	$(CC) $(CFLAGS) temperature.c pcsensor.c -o temperature -lusb

clean:
	rm temperature

install:
	install temperature /usr/local/bin

uninstall:
	rm -f /usr/local/bin/temperature
