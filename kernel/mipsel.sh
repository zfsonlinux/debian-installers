arch_get_kernel_flavour () {
	case "$SUBARCH" in
		r3k-kn02|r4k-kn04|sb1-bcm91250a|sb1a-bcm91480b)
			echo "$SUBARCH"
			return 0
		;;
		cobalt)
			echo r5k-cobalt
			return 0
		;;
		*)
			warning "Unknown $ARCH subarchitecture '$SUBARCH'."
			return 1
		;;
	esac
}

arch_check_usable_kernel () {
	# Handle some package renamed from 2.4 to 2.6
	if [ "$2" = "sb1-bcm91250a" ]; then
		if expr "$1" : ".*-sb1-swarm-bn\$" >/dev/null; then return 0; fi
	fi
	# Subarchitecture must match exactly.
	if expr "$1" : ".*-$2.*" >/dev/null; then return 0; fi
	return 1
}

arch_get_kernel () {
	# use the more generic package versioning for 2.6 ff.
	case "$KERNEL_MAJOR" in
		2.4)
			case $1 in
				sb1-bcm91250a)
					set sb1-swarm-bn
				;;
			esac
			version="$KERNEL_VERSION"
			echo "kernel-image-$version-$1"
			;;
		*)
			version="$KERNEL_MAJOR"
			echo "linux-image-$version-$1"
			;;
	esac
}
