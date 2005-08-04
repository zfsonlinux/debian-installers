arch_get_kernel_flavour () {
	return 0
}

arch_check_usable_kernel () {
	return 0
}

arch_get_kernel () {
	version=2.4.27-2

	if [ "$(cat /var/numcpus)" -gt 1 ]; then
		SMP=smp
	else
		SMP=genric
	fi
	
	echo "kernel-image-$version-$SMP"
}
