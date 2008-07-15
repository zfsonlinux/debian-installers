arch_get_kernel_flavour () {
	VENDOR=`grep '^vendor_id' "$CPUINFO" | head -n1 | cut -d: -f2`
	FAMILY=`grep '^cpu family' "$CPUINFO" | head -n1 | cut -d: -f2`
	MODEL=`grep '^model[[:space:]]*:' "$CPUINFO" | head -n1 | cut -d: -f2`
	case "$VENDOR" in
	    " AuthenticAMD"*)
		case "$FAMILY" in
		    " 15")	echo 686 ;;	# k8
		    " 6")			# k7
			case "$MODEL" in
			    " 0"|" 1"|" 2"|" 3"|" 4"|" 5")
				# May not have SSE support
				echo 486 ;;
			    *)	echo 686 ;;
			esac
			;;
		    *)		echo 486 ;;
		esac
		;;
	    " GenuineIntel")
		case "$FAMILY" in
		    " 6"|" 15")	echo 686 ;;
		    *)		echo 486 ;;
		esac
		;;
	    " CentaurHauls")
		case "$FAMILY" in
		    " 6")
			case "$MODEL" in
			    " 9"|" 10")	echo 686 ;;
			    *)		echo 486 ;;
			esac
			;;
		    *)
			echo 486 ;;
		esac
		;;
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
	if [ "$2" = 686 ]; then return 1; fi

	# default to usable in case of strangeness
	warning "Unknown kernel usability: $1 / $2"
	return 0
}

arch_get_kernel () {
	imgbase=linux-image

	# See older versions of script for more flexible code structure
	# that allows multiple levels of fallbacks
	if [ "$1" = 686 ]; then
		echo "$imgbase-$KERNEL_MAJOR-686"
	fi
	echo "$imgbase-$KERNEL_MAJOR-486"
}
