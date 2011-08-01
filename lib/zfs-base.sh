. /lib/partman/lib/base.sh

###############################################################################
#
# Miscellaneous utility functions
#
###############################################################################

# Converts a list of space (or newline) separated values to comma separated values
ssv_to_csv() {
	local csv value

	csv=""
	for value in $1; do
		if [ -z "$csv" ]; then
			csv="$value"
		else
			csv="$csv, $value"
		fi
	done
	echo "$csv"
}

# Converts a list of comma separated values to space separated values
csv_to_ssv() {
	echo "$1" | sed -e 's/ *, */ /g'
}

# Produces a human readable description of the current ZFS config
zfs_get_config() {
	RET="$(zfs list)"
	return 0
}

zfs_name_ok() {
	local name
	name="$1"

	if [ -z "$name" ]; then
		return 1
	fi

	if [ "$(echo -n "$name" | sed 's/[^-:_\.[:alnum:]]//g')" != "$name" ]; then
		return 1
	fi

	# 255, not 256.  See http://www.freebsd.org/cgi/query-pr.cgi?pr=159357
	if [ $(echo -n "$name" | wc -c) -gt 255 ]; then
		return 1
	fi

	return 0
}

# Would a PV be allowed on this partition?
pv_allowed () {
	local dev=$1
	local id=$2

	cd $dev

	# sparc can not have ZFS starting at 0 or it will destroy the partition table
	if [ "$(udpkg --print-architecture)" = kfreebsd-sparc ] && \
	   [ "${id%%-*}" = 0 ]; then
		return 1
	fi

	# avoid recursion
	case $(cat $dev/device) in
		/dev/zvol/*) return 1 ;;
	esac

	local zfs=no

	local fs
	open_dialog PARTITION_INFO $id
	read_line x1 x2 x3 x4 fs x6 x7
	close_dialog
	if [ "$fs" = free ]; then
		local label
		open_dialog GET_LABEL_TYPE
		read_line label
		close_dialog
		case $label in
		    amiga|bsd|dasd|gpt|mac|msdos|sun)
			# ... by creating a partition
			zfs=yes
			;;
		esac
	else
		zfs=yes
	fi

	[ $zfs = yes ]
}

pv_list_allowed () {
	partman_list_allowed pv_allowed
}

pv_list_allowed_free () {
	local line

	IFS="$NL"
	for line in $(pv_list_allowed); do
		restore_ifs
		local dev="${line%%$TAB*}"
		local rest="${line#*$TAB}"
		local id="${rest%%$TAB*}"
		if [ -e "$dev/locked" ] || [ -e "$dev/$id/locked" ]; then
			continue
		fi
		local pv="${line##*$TAB}"
		if ! zpool status | grep -q "\s$(basename $pv)\s"; then
			echo "$line"
		fi
		IFS="$NL"
	done
	restore_ifs
}

###############################################################################
#
# Physical Volume utility functions
#
###############################################################################

# Check if a device contains PVs
# If called for a disk, this will also check all partitions;
# if called for anything other, it can return false positives!
pv_on_device() {
	local device
	device="$1"
	# FIXME
	return 0
}

# Get info on a PV
pv_get_info() {
	# FIXME
	return 1
}

# Get VG for a PV
pv_get_vg() {
	# FIXME
	echo FIXME:pv_get_vg
}

# Get all PVs
pv_list() {
	# Scan the partman devices and find partitions that have zfs as method.
	# Do not rely on partition flags since it doesn't work for some partitions
	# (e.g. dm-crypt, RAID)
	local dev method

	for dev in $DEVICES/*; do
		[ -d "$dev" ] || continue
		cd $dev
		open_dialog PARTITIONS
		while { read_line num id size type fs path name; [ "$id" ]; }; do
			[ -f $id/method ] || continue
			method=$(cat $id/method)
			if [ "$method" = zfs ]; then
				echo $path
			fi
		done
		close_dialog
	done
}

# Get all unused PVs
pv_list_free() {
	local pv vg

	for pv in $(pv_list); do
		# FIXME
		if ! zpool status | grep -q "$(basename $pv)"; then
			echo "$pv"
		fi
	done
}

# Prepare a partition for use as a PV. If this returns true, then it did
# some work and a commit is necessary. Prints the new path.
pv_prepare() {
	local dev="$1"
	local id="$2"
	local size parttype fs path

	cd "$dev"
	open_dialog PARTITION_INFO "$id"
	read_line x1 id size freetype fs path x7
	close_dialog

	if [ "$fs" = free ]; then
		local newtype

		case $freetype in
		    primary)
			newtype=primary
			;;
		    logical)
			newtype=logical
			;;
		    pri/log)
			local parttype
			open_dialog PARTITIONS
			while { read_line x1 x2 x3 parttype x5 x6 x7; [ "$parttype" ]; }; do
				if [ "$parttype" = primary ]; then
					has_primary=yes
				fi
			done
			close_dialog
			if [ "$has_primary" = yes ]; then
				newtype=logical
			else
				newtype=primary
			fi
			;;
		esac

		open_dialog NEW_PARTITION $newtype ext2 $id full $size
		read_line x1 id x3 x4 x5 path x7
		close_dialog
	fi

	mkdir -p "$id"
	local method="$(cat "$id/method" 2>/dev/null || true)"
	if [ "$method" = swap ]; then
		disable_swap "$dev" "$id"
	fi
	if [ "$method" != zfs ]; then
		echo zfs >"$id/method"
		rm -f "$id/use_filesystem"
		rm -f "$id/format"
		update_partition "$dev" "$id"
		echo "$path"
		return 0
	fi

	echo "$path"
	return 1
}

###############################################################################
#
# Logical Volume utility functions
#
###############################################################################

# Get LV info
lv_get_info() {
	local info vg lv line tmplv
	vg=$1
	lv=$2

	SIZE="$(($(human2longint "$(zfs list -H -o avail "$vg/$lv")") / 1000000))"
	FS="unknown"
	# FIXME: mountpoint property or zvol mode?
	MOUNT=""
}

# List all LVs and their VGs
lv_list() {
	zfs list -r -o name -H | grep /
}

# Create a LV
lv_create() {
	local vg lv extents
	vg="$1"
	lv="$2"
	size="$3"

	log-output -t partman-zfs zfs create -V $size "$vg/$lv"
	return $?
}

# Delete a LV
lv_delete() {
	local vg lv device
	vg="$1"
	lv="$2"
	device="/dev/zvol/$vg/$lv"

	swapoff $device > /dev/null 2>&1
	umount $device > /dev/null 2>&1

	log-output -t partman-zfs zfs destroy -f "$vg/$lv"
	return $?
}

# Checks that a logical volume name is ok
lv_name_ok() {
	local lvname
	lvname="$1"

	zfs_name_ok "$lvname" || return 1

	return 0
}

###############################################################################
#
# Volume Group utility functions
#
###############################################################################

# List all VGs
vg_list() {
	zpool list -H | sed -e 's/\t.*//'
}

# List all VGs with free space
vg_list_free() {
	local vg

	for vg in $(vg_list); do
		if [ $(human2longint "$(zpool list -H -o avail $vg)") -gt 0 ]; then
			echo "$vg"
		fi
	done
}

# Get all PVs from a VG
vg_list_pvs() {
	zpool status $1 | grep "\sONLINE\s" | tail -n +2 | sed -e 's,^\s*,/dev/,;s,\s.*,,'
}

# Get all LVs from a VG
vg_list_lvs() {
	zfs list -H -o name -r "$1" | grep /
}

# Lock device(s) holding a PV
vg_lock_pvs() {
	local name pv
	name="$1"
	shift

	db_subst partman-zfs/text/in_use VG "$name"
	db_metaget partman-zfs/text/in_use description
	for pv in $*; do
		partman_lock_unit "$pv" "$RET"
	done
}

# Create a volume group
vg_create() {
	local vg pv
	vg="$1"
	shift

	# FIXME: Assuming stripe mode. We need to ask if user prefers mirror or zraid.

	log-output -t partman-zfs zpool create -f -m none -o altroot=/target "$vg" $* || return 1
	return 0
}

# Delete a volume group
vg_delete() {
	local vg
	vg="$1"

	log-output -t partman-zfs zpool destroy -f "$vg" || return 1
	return 0
}

# Checks that a volume group name is ok
vg_name_ok() {
	local vgname
	vgname="$1"

	zfs_name_ok "$vgname" || return 1

	case "$vgname" in
		mirror|raidz|spare|log|c[0-9]*) return 1 ;;
	esac

	if [ "$(echo -n "$vgname" | sed 's/^[^[:alnum:]]//')" != "$vgname" ]; then
		return 1
	fi

	return 0
}

# Get VG info
vg_get_info() {
	local info

	SIZE="$(($(human2longint "$(zpool list -H -o size $1)") / 1000000))"
	# "zpool list -o avail" doesn't count ZVOLs are used space.  I'm not
	# sure if this is a bug, but in any case "zfs list -o avail" works
	# as expected.
	FREE="$(($(human2longint "$(zfs list -H -o avail $1)") / 1000000))"
	# Reserved space.
	FREE=$(($FREE - 64))
	# Never allow $FREE below 0.  Just in case.
	if [ $FREE -lt 0 ]; then FREE=0 ; fi
	LVS=$(vg_list_lvs $1)
	PVS=$(vg_list_pvs $1)
	return 0
}
