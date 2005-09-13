arch_get_kernel_flavour () {
	case "$MACHINE" in
		sparc)		echo sparc32 ;;
		sparc64)	echo sparc64 ;;
	esac
	return 0
}

arch_check_usable_kernel () {
	case "$2" in
	    sparc32)
		if expr "$1" : '.*-2\.6.*-sparc32-smp' >/dev/null; then
			# No working SMP yet
			return 1
		fi
		if expr "$1" : '.*-sparc32.*' >/dev/null; then return 0; fi
		return 1
		;;
	    sparc64)
		if expr "$1" : '.*-sparc64.*' >/dev/null; then return 0; fi
		return 1
		;;
	esac

	# default to usable in case of strangeness
	warning "Unknown kernel usability: $1 / $2"
	return 0
}

arch_get_kernel () {
	if [ "$KERNEL_MAJOR" = 2.4 ]; then
		imgbase=kernel-image
	else
		imgbase=linux-image
	fi
	CPUS=`grep 'ncpus probed' "$CPUINFO" | cut -d: -f2`
	if [ "$CPUS" -eq 1 ]; then
		echo "$imgbase-$KERNEL_MAJOR-$1"
	else
		if [ "$1" = sparc32 ] && [ "$KERNEL_MAJOR" = 2.6 ]; then
			# No working SMP yet
			echo "$imgbase-$KERNEL_MAJOR-$1"
		else
			echo "$imgbase-$KERNEL_MAJOR-$1-smp"
		fi
	fi
}
