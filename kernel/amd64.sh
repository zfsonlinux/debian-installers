arch_get_kernel_flavour () {
	echo amd64
}

arch_check_usable_kernel () {
	if echo "$1" | grep -Eq -- "-amd64(-.*)?$"; then return 0; fi

	return 1
}

arch_get_kernel () {
	echo "linux-image-amd64"
}
