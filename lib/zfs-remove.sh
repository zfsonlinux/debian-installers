. /lib/partman/lib/zfs-base.sh

# List PVs to be removed to initialize a device
remove_zfs_find_vgs() {
	local realdev vg pvs pv disk
	realdev="$1"

	# Simply exit if there is no zfs support
	[ -f /var/lib/partman/zfs ] || exit 0

	# Check all VGs to see which PV needs removing
	# BUGME: the greps in this loop should be properly bounded so they
	#	 do not match on partial matches!
	#        Except that we want partial matches for disks...
	for vg in $(vg_list); do
		pvs="$(vg_list_pvs $vg)"

		if ! echo "$pvs" | grep -q "$realdev"; then
			continue
		fi

		echo "$vg"
	done
}

# Wipes any traces of ZFS from a disk
# Normally called from a function that initializes a device
# Note: if the device contains an empty PV, it will not be removed
device_remove_zfs() {
	local dev realdev tmpdev restart confirm
	local pvs pv vgs vg lvs lv pvtext vgtext lvtext
	dev="$1"
	cd $dev

	# Check if the device already contains any physical volumes
	realdev="$(cat $dev/device)"
	if ! pv_on_device "$realdev"; then
		return 0
	fi

	vgs="$(remove_zfs_find_vgs $realdev)" || return 1
	[ "$vgs" ] || return 0

	pvs=""
	lvs=""
	for vg in $vgs; do
		pvs="${pvs:+$pvs$NL}$(vg_list_pvs $vg)"
		lvs="${lvs:+$lvs$NL}$(vg_list_lvs $vg)"
	done

	# Ask for permission to erase ZFS volumes
	lvtext=""
	for lv in $lvs; do
		lvtext="${lvtext:+$lvtext, }$lv"
	done
	vgtext=""
	for vg in $vgs; do
		vgtext="${vgtext:+$vgtext, }$vg"
	done

	db_fget partman-zfs/device_remove_zfs seen
	if [ $RET = true ]; then
		# Answer has been preseeded
		db_get partman-zfs/device_remove_zfs
		confirm=$RET
	else
		db_subst partman-zfs/device_remove_zfs LVTARGETS "$lvtext"
		db_subst partman-zfs/device_remove_zfs VGTARGETS "$vgtext"
		db_input critical partman-zfs/device_remove_zfs
		db_go || return 1
		db_get partman-zfs/device_remove_zfs
		confirm=$RET
		db_reset partman-zfs/device_remove_zfs
	fi
	if [ "$confirm" != true ]; then
		return 255
	fi

	for vg in $vgs; do
		# Remove LVs from the VG
		for lv in $(vg_list_lvs $vg); do
			lv_delete $vg $lv
		done

		# Remove the VG
		vg_delete $vg
	done
	# Unlock the PVs
	for pv in $pvs; do
		partman_unlock_unit $pv
	done

	# Make sure that parted has no stale ZFS info
	restart=""
	for tmpdev in $DEVICES/*; do
		[ -d "$tmpdev" ] || continue

		realdev=$(cat $tmpdev/device)

		if [ -b "$realdev" ] || \
		   ! $(echo "$realdev" | grep -q "/dev/zvol/"); then
			continue
		fi

		rm -rf $tmpdev
		restart=1
	done

	if [ "$restart" ]; then
		return 99
	fi
	return 0
}
