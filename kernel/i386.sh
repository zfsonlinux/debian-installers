arch_get_kernel_flavour () {
	VENDOR=`grep '^vendor_id' "$CPUINFO" | head -n1 | cut -d: -f2`
	FAMILY=`grep '^cpu family' "$CPUINFO" | head -n1 | cut -d: -f2`
	MODEL=`grep '^model[[:space:]]*:' "$CPUINFO" | head -n1 | cut -d: -f2`

	# Only offer bigmem is the system supports pae and the
	# installer itself is already using a bigmem kernel.
	if grep '^flags' "$CPUINFO" | grep -q pae ; then
	    case "$KERNEL_FLAVOUR" in
		686-bigmem*) BIGMEM="-bigmem" ;;
		*) ;;
	    esac
	fi

	case "$VENDOR" in
	    " AuthenticAMD"*)
		case "$FAMILY" in
		    " 15")	echo 686$BIGMEM ;;	# k8
		    " 6")				# k7
			case "$MODEL" in
			    " 0"|" 1"|" 2"|" 3"|" 4"|" 5")
				# May not have SSE support
				echo 486 ;;
			    *)	echo 686$BIGMEM ;;
			esac
			;;
		    *)		echo 486 ;;
		esac
		;;
	    " GenuineIntel")
		case "$FAMILY" in
		    " 6"|" 15")	echo 686$BIGMEM ;;
		    *)		echo 486 ;;
		esac
		;;
	    " CentaurHauls")
		# x86 VIA Nehemiah CentaurHauls does not boot with -686
		# since 2.6.22+ since they lack long NOP instructions.
		# See: http://lkml.org/lkml/2008/7/22/263
		echo 486 ;;
	    *)
		echo 486 ;;
	esac
	return 0
}

# Note: the -k7 flavor has been dropped with linux-2.6 (2.6.23-1)

arch_check_usable_kernel () {
	if echo "$1" | grep -Eq -- "-486(-.*)?$"; then return 0; fi
	if [ "$2" = 486 ]; then return 1; fi
	if echo "$1" | grep -Eq -- "-686(-.*)?$"; then return 0; fi
	if [ "$2" = 686 ] || [ "$2" = 686-bigmem ]; then return 1; fi

	# default to usable in case of strangeness
	warning "Unknown kernel usability: $1 / $2"
	return 0
}

arch_get_kernel () {
	imgbase=linux-image

	# See older versions of script for more flexible code structure
	# that allows multiple levels of fallbacks
	if [ "$1" = 686-bigmem ]; then
		echo "$imgbase-$KERNEL_MAJOR-686-bigmem"
		set 686
	fi
	if [ "$1" = 686 ]; then
		echo "$imgbase-$KERNEL_MAJOR-686"
	fi
	echo "$imgbase-$KERNEL_MAJOR-486"
}
