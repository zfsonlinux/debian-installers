INSTALL_DIR=$(DESTDIR)/usr/bin/
CFLAGS=-Wall  -Os -fomit-frame-pointer 
STRIP = strip --remove-section=.note --remove-section=.comment 
LDFLAGS=-lkdetect -ldebconf -lparted
CC=gcc

all: choose-disk powerpc-type

choose-disk: choose-disk.o
	$(CC) -o choose-disk choose-disk.o $(LDFLAGS)

choose-disk.o: choose-disk.c
	$(CC) $(CFLAGS) -c choose-disk.c

clean:
	$(RM) choose-disk choose-disk.o powerpc-type powerpc-type.o

install: all
	install -d $(DESTDIR)/usr/bin
	install -m644 choose-disk $(DESTDIR)/usr/bin
	install -m644 powerpc-type $(DESTDIR)/usr/bin

