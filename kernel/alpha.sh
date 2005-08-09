arch_get_kernel_flavour () {
	return 0
}

arch_check_usable_kernel () {
	return 0
}

arch_get_kernel () {
	version=2.4.27-2
	
	if [ -n "$NUMCPUS" ] && [ "$NUMCPUS" -gt 1 ]; then
		SMP=smp
	else
		SMP=generic
	fi
	
	echo "kernel-image-$version-$SMP"
}
