BIN = run-debootstrap
CFLAGS = -Wall -g -D_GNU_SOURCE

ifdef DEBUG
CFLAGS:=$(CFLAGS) -g3
endif

$(BIN): run-debootstrap.c
	$(CC) $(CFLAGS) -o $@ $^ -ldebconfclient -ldebian-installer

small: CFLAGS:=-Os $(CFLAGS)
small: clean $(BIN)
	strip --remove-section=.comment --remove-section=.note $(BIN)
	ls -l $(BIN)

clean:
	-rm -f $(BIN)
