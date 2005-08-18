arch_get_kernel_flavour () {
	case "$SUBARCH" in
		netwinder|bast|riscpc|riscstation|lart)
			echo "$SUBARCH"
			return 0
		;;
		ads)
			# Currently no kernel in debian for ADS boards.
			echo "none"
			return 0
		;;
		*)
			warning "Unknown $ARCH subarchitecture '$SUBARCH'."
			return 1
		;;
	esac
}

arch_check_usable_kernel () {
	# Subarchitecture must match exactly.
	if expr "$1" : ".*-$2\$" >/dev/null; then return 0; fi
	return 1
}

arch_get_kernel () {
	if [ "$1" = none ]; then
		echo none
	else
		echo "kernel-image-$KERNEL_VERSION-$1"
	fi
}
