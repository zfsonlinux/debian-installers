arch_get_kernel_flavour () {
	# Should we offer an amd64 kernel?
	local HAVE_LM
	if grep -q '^flags.*\blm\b' "$CPUINFO"; then
		HAVE_LM=y
	else
		HAVE_LM=n
	fi

	# Should we offer a bigmem kernel?
	local HAVE_PAE
	if grep -q '^flags.*\bpae\b' "$CPUINFO"; then
		HAVE_PAE=y
	else
		HAVE_PAE=n
	fi

	# Should we prefer a bigmem/amd64 kernel - is there RAM above 4GB?
	local WANT_PAE
	if [ -z "$RAM_END" ]; then
		local MAP MAP_END
		RAM_END=0
		for MAP in /sys/firmware/memmap/* ; do
			if [ "$(cat $MAP/type)" = "System RAM" ]; then
				MAP_END="$(cat $MAP/end)"
				if [ $(($MAP_END > $RAM_END)) = 1 ]; then
					RAM_END=$MAP_END
				fi
			fi
		done
	fi
	if [ $(($RAM_END > 0x100000000)) = 1 ]; then
		WANT_PAE=y
	else
		WANT_PAE=n
	fi
	# or is the installer running a 686-bigmem kernel?
	case "$KERNEL_FLAVOUR" in
	    686-bigmem*)
		WANT_PAE=y
		;;
	esac

	case "$HAVE_LM$HAVE_PAE$WANT_PAE" in
	    yyy)
		echo 686-bigmem amd64 686 486
		return 0
		;;
	    yyn)
		echo 686 686-bigmem amd64 486
		return 0
		;;
	    yn?)
		warning "Processor with LM but no PAE???"
		;;
	    nyy)
		echo 686-bigmem 686 486
		return 0
		;;
	    nyn)
		echo 686 686-bigmem 486
		return 0
		;;
	    nn?)
		# Need to check whether 686 is suitable
		;;
	esac

	local VENDOR FAMILY MODEL
	VENDOR=$(sed -n 's/^vendor_id\s*: //; T; p; q' "$CPUINFO")
	FAMILY=$(sed -n 's/^cpu family\s*: //; T; p; q' "$CPUINFO")
	MODEL=$(sed -n 's/^model\s*: //; T; p; q' "$CPUINFO")

	case "$VENDOR" in
	    AuthenticAMD*)
		case "$FAMILY" in
		    6|15|16|17)	echo 686 486 ;;
		    *)		echo 486 ;;
		esac
		;;
	    GenuineIntel)
		case "$FAMILY" in
		    6|15)	echo 686 486 ;;
		    *)		echo 486 ;;
		esac
		;;
	    CentaurHauls)
		case "$FAMILY" in
		    6)
			case "$MODEL" in
			    9|10|13)	echo 686 486 ;;
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

arch_check_usable_kernel () {
	local NAME="$1"

	set -- $2
	while [ $# -ge 1 ]; do
		case "$NAME" in
		    *-"$1")
			return 0;
			;;
		    *-"$1"-bigmem*)
			# Don't allow -bigmem suffix
			;;
		    *-"$1"-*)
			# Do allow any other hyphenated suffix
			return 0
			;;
		esac
		shift
	done
	return 1
}

arch_get_kernel () {
	imgbase="linux-image-$KERNEL_MAJOR"

	set -- $1
	while [ $# -ge 1 ]; do
		echo "$imgbase-$1"
		shift
	done
}
