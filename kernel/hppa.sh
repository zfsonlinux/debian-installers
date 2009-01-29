arch_get_kernel_flavour () {
	echo "$MACHINE"
	return 0
}

arch_check_usable_kernel () {
	if echo "$1" | grep -Eq -- "-parisc(32)?(-.*)?$"; then return 0; fi
	if [ "$2" = parisc ]; then return 1; fi
	if echo "$1" | grep -Eq -- "-parisc(64)?(-.*)?$"; then return 0; fi

	# default to usable in case of strangeness
	warning "Unknown kernel usability: $1 / $2"
	return 0
}

arch_get_kernel () {
	if [ "$NUMCPUS" ] && [ "$NUMCPUS" -gt 1 ]; then
		echo "linux-image-$KERNEL_MAJOR-$1-smp"
	fi
	echo "linux-image-$KERNEL_MAJOR-$1"
}
