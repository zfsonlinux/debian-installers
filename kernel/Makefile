ARCHES = alpha arm i386 powerpc s390 sparc

test:
	@cd tests && \
	for x in $(ARCHES); do ./runtests "$$x"; done
