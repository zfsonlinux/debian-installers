arch_get_kernel_flavour () {
	return 0
}

arch_check_usable_kernel () {
	return 0
}

arch_get_kernel () {
	version="$(uname -r)"
	echo "kernel-image-$version"
}

