arch_get_kernel_flavour () {
	case "$MACHINE" in
		parisc)		echo parisc32 ;;
		parisc64)	echo parisc64 ;;
	esac
	return 0
}

arch_check_usable_kernel () {
	if expr "$1" : '.*-32.*' >/dev/null; then return 0; fi
	if [ "$2" = parisc32 ]; then return 1; fi
	if expr "$1" : '.*-64.*' >/dev/null; then return 0; fi

	# default to usable in case of strangeness
	warning "Unknown kernel usability: $1 / $2"
	return 0
}

arch_get_kernel () {
	case "$KERNEL_MAJOR" in
		2.4)	version="$KERNEL_VERSION" ;;
		2.6)	version="$KERNEL_ABI" ;;
		*)	warning "Unknown kernel major '$KERNEL_MAJOR'." ;;
	esac
	# Don't know how to detect whether SMP is needed, but
	# apparently it's OK to assume SMP.
	case "$1" in
		parisc32)	echo "kernel-image-$version-32-smp" ;;
		parisc64)	echo "kernel-image-$version-64-smp" ;;
	esac
}
