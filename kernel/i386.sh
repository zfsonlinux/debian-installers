arch_get_kernel_flavour () {
	VENDOR=`grep '^vendor_id' "$CPUINFO" | head -n1 | cut -d: -f2`
	FAMILY=`grep '^cpu family' "$CPUINFO" | head -n1 | cut -d: -f2`
	MODEL=`grep '^model[[:space:]]*:' "$CPUINFO" | head -n1 | cut -d: -f2`
	case "$VENDOR" in
		" AuthenticAMD"*)
			case "$FAMILY" in
				" 6"|" 15")	echo k7 ;;
				*)		echo 486 ;;
			esac
			;;
		" GenuineIntel"|" GenuineTMx86"*)
			case "$FAMILY" in
				" 6"|" 15")	echo 686 ;;
				*)		echo 486 ;;
			esac
			;;
		" CentaurHauls")
			case "$FAMILY" in
				" 6")
					case "$MODEL" in
						" 9"|" 10")		echo 686 ;;
						*)		echo 486 ;;
					esac
					;;
				*)		echo 486 ;;
			esac
			;;
		*) echo 486 ;;
	esac
	return 0
}

arch_check_usable_kernel () {
	if expr "$1" : '.*-486.*' >/dev/null; then return 0; fi
	if [ "$2" = 486 ]; then return 1; fi
	if expr "$1" : '.*-686.*' >/dev/null; then return 0; fi
	if [ "$2" = 686 ]; then return 1; fi
	if [ "$2" = k7 ]; then
		if expr "$1" : '.*-k7.*' >/dev/null; then return 0; fi
		return 1
	fi

	# default to usable in case of strangeness
	warning "Unknown kernel usability: $1 / $2"
	return 0
}

arch_get_kernel () {
	imgbase=linux-image

	if [ "$1" = k7 ]; then
		echo "$imgbase-$KERNEL_MAJOR-k7"
		set 486
	fi

	if [ "$1" = 686 ]; then
		echo "$imgbase-$KERNEL_MAJOR-686"
		set 486
	fi
	echo "$imgbase-$KERNEL_MAJOR-486"
}
