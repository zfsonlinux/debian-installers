arch_get_kernel_flavour () {
	case "$MACHINE" in
		sparc)		echo sparc32 ;;
		sparc64)	echo sparc64 ;;
	esac
	return 0
}

arch_check_usable_kernel () {
	if expr "$1" : '.*-sparc32.*' >/dev/null; then
		if expr "$1" : '.*-2\.6.*-sparc32-smp' >/dev/null; then
			# No working SMP yet
			return 1
		else
			return 0
		fi
	fi
	if [ "$2" = sparc32 ]; then return 1; fi
	if expr "$1" : '.*-sparc64.*' >/dev/null; then return 0; fi

	# default to usable in case of strangeness
	warning "Unknown kernel usability: $1 / $2"
	return 0
}

arch_get_kernel () {
	CPUS=`grep 'ncpus probed' "$CPUINFO" | cut -d: -f2`
	if [ "$CPUS" -eq 1 ]; then
		echo "kernel-image-$KERNEL_MAJOR-$1"
	else
		if [ "$1" = sparc32 ] && [ "$KERNEL_MAJOR" = 2.6 ]; then
			# No working SMP yet
			echo "kernel-image-$KERNEL_MAJOR-$1"
		else
			echo "kernel-image-$KERNEL_MAJOR-$1-smp"
		fi
	fi
}
