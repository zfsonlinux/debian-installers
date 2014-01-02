arch_get_kernel_flavour () {
	case "$SUBARCH" in
	    omap|mx5|vexpress)
		echo "$SUBARCH armmp"
		return 0 ;;
	    generic)
		echo "armmp"
		return 0 ;;
	    *)
		warning "Unknown $ARCH subarchitecture '$SUBARCH'."
		return 1 ;;
	esac
}

arch_check_usable_kernel () {
        local NAME="$1"

        set -- $2
        while [ $# -ge 1 ]; do
                case "$NAME" in
                    *-"$1" | *-"$1"-*)
                        # Allow any other hyphenated suffix
                        return 0
                        ;;
                esac
                shift
        done
        return 1
}

arch_get_kernel () {
	case "$KERNEL_MAJOR" in
	    2.6|3.*)
		imgbase="linux-image"

		set -- $1
		while [ $# -ge 1 ]; do
			echo "$imgbase-$1"
			shift
		done
		;;
	    *)	warning "Unsupported kernel major '$KERNEL_MAJOR'."
		;;
	esac
}
