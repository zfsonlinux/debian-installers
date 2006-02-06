arch_get_kernel_flavour () {
	echo $MACHINE
	return 0
}

arch_check_usable_kernel () {
	case "$1" in
		*-s390-tape)
			# Bastian Blank says: "-s390-tape is only a kernel
			# image without any logic and modules".
			return 1 ;;
		*-s390x)
			# Bastian Blank says that 2.4 -s390x isn't
			# automatically installable, and 2.6 isn't currently
			# usable from d-i due to different hardware
			# configuration.
			return 1 ;;
		*)
			return 0 ;;
	esac
}

arch_get_kernel () {
	echo "kernel-image-$KERNEL_ABI-s390"
}

