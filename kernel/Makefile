ARCHES = alpha i386 powerpc sparc

test:
	@cd tests && \
	for x in $(ARCHES); do ./runtests "$$x"; done
