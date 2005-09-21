arch_get_kernel_flavour () {
	case "$MACHINE" in
		parisc)		echo parisc32 ;;
		parisc64)	echo parisc64 ;;
	esac
	return 0
}

arch_check_usable_kernel () {
	if expr "$1" : '.*-parisc-' >/dev/null; then return 0; fi
	if expr "$1" : '.*-parisc$' >/dev/null; then return 0; fi
	if expr "$1" : '.*-32.*' >/dev/null; then return 0; fi
	if [ "$2" = parisc32 ]; then return 1; fi
	if expr "$1" : '.*-parisc64.*' >/dev/null; then return 0; fi
	if expr "$1" : '.*-64.*' >/dev/null; then return 0; fi

	# default to usable in case of strangeness
	warning "Unknown kernel usability: $1 / $2"
	return 0
}

arch_get_kernel () {
	CPUS="$(grep ^processor "$CPUINFO" | tail -n 1 | cut -d: -f2)"
	if [ -z "$CPUS" ] || [ "$CPUS" -ne 0 ]; then
		SMP=-smp
	else
		SMP=
	fi

	case "$1" in
		parisc32)	echo "linux-image-parisc$SMP" ;;
		parisc64)	echo "linux-image-parisc64$SMP" ;;
	esac
}
