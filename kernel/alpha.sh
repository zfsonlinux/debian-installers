arch_get_kernel_flavour () {
	return 0
}

arch_check_usable_kernel () {
	return 0
}

arch_get_kernel () {
	version=2.4.27-1
	if dmesg | grep -q ^Processors:; then
		CPUS=`dmesg | grep ^Processors: | cut -d: -f2`
	else
		CPUS=1
	fi
	if test $CPUS -eq 1; then
		echo "kernel-image-$version-generic"
	else
		echo "kernel-image-$version-smp"
	fi
}
