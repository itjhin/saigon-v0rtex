all: find_gadgets

SOURCES = find_gadgets.c macho.c

HEADERS = macho.h

find_gadgets: $(SOURCES) $(HEADERS)
	$(CC) $(CFLAGS) $(SOURCES) -o $@

clean:
	rm -f -- find_gadgets
