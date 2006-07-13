arch_get_kernel_flavour () {
	CPU=`grep '^cpu[[:space:]]*:' "$CPUINFO" | head -n1 | cut -d: -f2 | sed 's/^ *//; s/[, ].*//' | tr A-Z a-z`
	case "$CPU" in
		power3|i-star|s-star|power4|power4+|ppc970*|power5)
			family=powerpc64
			;;
		*)
			family=powerpc
			;;
	esac
	case "$SUBARCH" in
		powermac*|prep|chrp*)	echo "$family" ;;
		amiga)			echo apus ;;
		*)
			warning "Unknown $ARCH subarchitecture '$SUBARCH'."
			return 1
		;;
	esac
	return 0
}

arch_check_usable_kernel () {
	# CPU family must match exactly.
	if [ "$2" = powerpc ]; then
		# powerpc is a substring of powerpc64, so we have to check
		# this separately.
		if expr "$1" : ".*-powerpc64.*" >/dev/null; then return 1; fi
	fi
	if expr "$1" : ".*-$2.*" >/dev/null; then return 0; fi
	return 1
}

arch_get_kernel () {
	# The APUS kernels are in a separate source package, so may
	# sometimes have a different version number.
	apusversion=2.4.27

	CPUS="$(grep -ci ^processor "$CPUINFO")" || CPUS=1
	if [ "$CPUS" ] && [ "$CPUS" -gt 1 ] && [ "$1" != "powerpc64" ]; then
		SMP=-smp
	else
		SMP=
	fi

	case "$1" in
		apus)	echo "kernel-image-$apusversion-apus" ;;
		*)
			case "$KERNEL_MAJOR" in
				2.6)
					if [ "$SMP" ]; then
						echo "linux-image-$KERNEL_MAJOR-$1$SMP"
					fi
					echo "linux-image-$KERNEL_MAJOR-$1"
					;;
				*)
					if [ "$1" = powerpc ] && [ "$SMP" ]; then
						# 2.4 only has powerpc-smp.
						echo "kernel-image-$KERNEL_MAJOR-$1$SMP"
					fi
					echo "kernel-image-$KERNEL_MAJOR-$1"
					;;
			esac
	esac
}
