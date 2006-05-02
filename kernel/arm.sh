arch_get_kernel_flavour () {
	case "$SUBARCH" in
		netwinder|riscpc|nslu2)
			echo "$SUBARCH"
			return 0
		;;
		# NOTE: the following kernel is not in Debian (sarge), but
		# makes it easier to offer unofficial support from a private
		# apt-archive.
		ads)
			echo "ads"
			return 0
		;;
		*)
			warning "Unknown $ARCH subarchitecture '$SUBARCH'."
			return 1
		;;
	esac
}

arch_check_usable_kernel () {
	# Handle some packages renamed from 2.4 to 2.6
	if [ "$2" = "netwinder" ]; then
		if expr "$1" : ".*-footbridge\$" >/dev/null; then return 0; fi
	fi
	# Subarchitecture must match exactly.
	if expr "$1" : ".*-$2\$" >/dev/null; then return 0; fi
	return 1
}

arch_get_kernel () {
	case "$KERNEL_MAJOR" in
		2.4)
			echo "kernel-image-$KERNEL_VERSION-$1"
			;;
		*)
			case "$1" in
				netwinder)
					echo "linux-image-$KERNEL_MAJOR-footbridge"
					;;
				bast)
					echo "linux-image-$KERNEL_MAJOR-s3c2410"
					;;
				*)
					echo "linux-image-$KERNEL_MAJOR-$1"
					;;
			esac
		esac
}
