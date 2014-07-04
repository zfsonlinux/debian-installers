arch_get_kernel_flavour () {
	echo "arm64"
	return 0
}

arch_check_usable_kernel () {
	return 0
}

arch_get_kernel () {
	echo "linux-image-arm64"
}
