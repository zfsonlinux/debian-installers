arch_get_kernel_flavour () {
	case "$SUBARCH" in
		amiga|atari|mac|bvme6000|mvme147|mvme16x|q40|sun3|sun3x)
			echo "$SUBARCH"
			return 0
		;;
		*)
			warning "Unknown $ARCH subarchitecture '$SUBARCH'."
			return 1
		;;
	esac
}

arch_check_usable_kernel () {
	# Subarchitecture must match exactly (is this right?).
	if expr "$1" : ".*-$2\$" >/dev/null; then return 0; fi
	return 1
}

arch_get_kernel () {
	case "$KERNEL_MAJOR" in
		2.4)	version=2.4.27 ;;
		2.6)	version=2.6.8 ;;
		*)	warning "Unknown kernel major '$KERNEL_MAJOR'." ;;
	esac
	echo "kernel-image-$version-$1"
}
