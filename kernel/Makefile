ARCHES = alpha arm hppa i386 ia64 m68k powerpc s390 sparc

test:
	@cd tests && \
	for x in $(ARCHES); do ./runtests "$$x"; done
	@rm -rf tests/chroot
