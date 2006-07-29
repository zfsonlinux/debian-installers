arch_get_kernel_flavour () {
	echo "$MACHINE"
	return 0
}

arch_check_usable_kernel () {
	if expr "$1" : '.*-parisc-' >/dev/null; then return 0; fi
	if expr "$1" : '.*-parisc$' >/dev/null; then return 0; fi
	if expr "$1" : '.*-32.*' >/dev/null; then return 0; fi
	if [ "$2" = parisc ]; then return 1; fi
	if expr "$1" : '.*-parisc64.*' >/dev/null; then return 0; fi
	if expr "$1" : '.*-64.*' >/dev/null; then return 0; fi

	# default to usable in case of strangeness
	warning "Unknown kernel usability: $1 / $2"
	return 0
}

arch_get_kernel () {
	CPUS="$(grep ^processor "$CPUINFO" | tail -n 1 | cut -d: -f2)"
	if [ -z "$CPUS" ] || [ "$CPUS" -ne 0 ]; then
		echo "linux-image-$KERNEL_MAJOR-$1-smp"
	fi
	echo "linux-image-$KERNEL_MAJOR-$1"
}
