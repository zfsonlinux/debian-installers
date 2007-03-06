arch_get_kernel_flavour () {
	VENDOR=`grep '^vendor_id' "$CPUINFO" | head -n1 | cut -d: -f2`
	case "$VENDOR" in
		" AuthenticAMD"*)	echo amd64-k8 ;;
		" GenuineIntel"*)	echo em64t-p4 ;;
		*)			echo amd64-generic ;;
	esac
	return 0
}

arch_check_usable_kernel () {
	# Generic kernels can be run on any machine.
	if expr "$1" : '.*-amd64' >/dev/null; then return 0; fi

	return 1
}

arch_get_kernel () {
	echo "linux-image-$KERNEL_MAJOR-amd64"
}
