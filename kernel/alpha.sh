arch_get_kernel_flavour () {
	echo $MACHINE
	return 0
}

arch_check_usable_kernel () {
	return 0
}

arch_get_kernel () {
	if [ "$KERNEL_MAJOR" = 2.4 ]; then
		imgbase=kernel-image
		version=2.4.27-2
	else
		imgbase=linux-image
		version=$KERNEL_MAJOR-alpha
	fi
	
	if [ -n "$NUMCPUS" ] && [ "$NUMCPUS" -gt 1 ]; then
		echo "$imgbase-$version-smp"
	fi
	
	echo "$imgbase-$version-generic"
}
