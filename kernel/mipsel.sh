arch_get_kernel_flavour () {
	case "$SUBARCH" in
		r3k-kn02|r4k-kn04|cobalt|sb1-swarm-bn)
			echo "$SUBARCH"
			return 0
		;;
		*)
			warning "Unknown $ARCH subarchitecture '$SUBARCH'."
			return 1
		;;
	esac
}

arch_check_kernel_usable () {
	if expr "$1" : ".*-$2.*" >/dev/null; then return 0; fi
	return 1
}

arch_get_kernel () {
	# use the more generic package versioning for 2.6 ff.
	case "$KERNEL_MAJOR" in
		2.4)	version="$(uname -r | cut -d - -f 1)" ;;
		*)	version="$KERNEL_MAJOR" ;;
	esac
	echo "kernel-image-$version-$1"
}
