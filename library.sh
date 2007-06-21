#! /bin/sh

# waypoint vars
WAYPOINTS=""
NUM_STEPS=0

# progress bar vars
export PB_POSITION=0
export PB_WAYPOINT_LENGTH=0

log() {
	logger -t base-installer "$@"
}
error() {
	log "error: $*"
}
warning() {
	log "warning: $*"
}
info() {
	log "info: $*"
}

exit_error() {
	error "exiting on error $1"
	db_progress stop
	db_input critical $1 || [ $? -eq 30 ]
	db_go
	exit 1
}

waypoint () {
	WAYPOINTS="$WAYPOINTS $1:$2"
	NUM_STEPS=$(($NUM_STEPS + $1)) || true
}

run_waypoints () {
	db_progress START 0 $NUM_STEPS base-installer/progress/installing-base
	for item in $WAYPOINTS; do
		PB_WAYPOINT_LENGTH=$(echo $item | cut -d: -f 1)
		WAYPOINT=$(echo $item | cut -d: -f 2)
		# Not all of the section headers need exist.
		db_progress INFO "base-installer/section/$WAYPOINT" || true
		eval $WAYPOINT
		PB_POSITION=$(($PB_POSITION + $PB_WAYPOINT_LENGTH)) || true
		db_progress SET $PB_POSITION
	done
	db_progress STOP
}

update_progress () {
	# Updates the progress bar to a new position within the space allocated
	# for the current waypoint. 
	NW_POS=$(($PB_POSITION + $PB_WAYPOINT_LENGTH * $1 / $2))
	db_progress SET $NW_POS
}

check_target () {
	# Make sure something is mounted on the target.
	# Partconf causes the latter format.
	if ! grep -q '/target ' /proc/mounts && \
			! grep -q '/target/ ' /proc/mounts; then
		exit_error base-installer/no_target_mounted
	fi
	
	# Warn about installation over an existing unix.
	if [ -e /target/bin/sh -o -L /target/bin/sh ]; then
		db_capb ""
		db_input high base-installer/use_unclean_target || true
		db_go || exit 10
		db_capb backup
		db_get base-installer/use_unclean_target
		if [ "$RET" = false ]; then
			db_reset base-installer/use_unclean_target
			exit_error base-installer/unclean_target_cancel
		fi
		db_reset base-installer/use_unclean_target
	fi
}

create_devices () {
	# RAID
	if [ -e /proc/mdstat ] && grep -q ^md /proc/mdstat ; then
		apt-install mdadm
	fi
	# device-mapper
	if grep -q " device-mapper$" /proc/misc; then
		# Avoid warnings from lvm2 tools about open file descriptors
		export LVM_SUPPRESS_FD_WARNINGS=1

		mkdir -p /target/dev/mapper
		if [ ! -e /target/dev/mapper/control ] ; then
			major=$(grep "[0-9] misc$" /proc/devices | sed 's/[ ]\+misc//')
			minor=$(grep "[0-9] device-mapper$" /proc/misc | sed 's/[ ]\+device-mapper//')
			mknod /target/dev/mapper/control c $major $minor

			# check if root is on a dm-crypt device
			rootdev=$(mount | grep "on /target " | cut -d' ' -f1)
			rootnode=${rootdev#/dev/mapper/}
			if [ $rootdev != $rootnode ] && type dmsetup >/dev/null 2>&1 && \
			   [ "$(dmsetup table $rootnode | cut -d' ' -f3)" = crypt ]; then
				major="$(dmsetup -c --noheadings info $rootnode | cut -d':' -f2)"
				minor="$(dmsetup -c --noheadings info $rootnode | cut -d':' -f3)"
				mknod /target/dev/mapper/$rootnode b $major $minor
			fi

			# Create device nodes for fake (ata) RAID devices
			if type dmraid >/dev/null 2>&1; then
				for frdisk in $(dmraid -s -c | grep -v "No RAID disks"); do
					for frdev in $(ls /dev/mapper/$frdisk* 2>/dev/null); do
						frnode=$(basename $frdev)
						major="$(dmsetup -c --noheadings info $frnode | cut -d':' -f2)"
						minor="$(dmsetup -c --noheadings info $frnode | cut -d':' -f3)"
						mknod /target/dev/mapper/$frnode b $major $minor
					done
				done
			fi
		fi

		# We can't check the root node directly as is done above because
		# root could be on an LVM LV on top of an encrypted device
		if type dmsetup >/dev/null 2>&1 && \
		   dmsetup table | cut -d' ' -f4 | grep -q "crypt" 2>/dev/null; then
			apt-install cryptsetup
		fi

		if type dmraid >/dev/null 2>&1; then
			if [ "$(dmraid -s -c | grep -v "No RAID disks")" ]; then
				apt-install dmraid
			fi
		fi

		if pvdisplay | grep -iq "physical volume ---"; then
			apt-install lvm2
			in-target vgscan --mknodes || true
		fi
	fi
	# UML: create ubd devices
	if grep -q "model.*UML" /proc/cpuinfo; then
		chroot /target /bin/sh -c '(cd /dev; ./MAKEDEV ubd)'
	fi
}

configure_apt_preferences () {
	[ ! -d /target/etc/apt/apt.conf.d ] && mkdir -p /target/etc/apt/apt.conf.d
	
	# Make apt trust Debian CDs. This is not on by default (we think).
	# This will be left in place on the installed system.
	cat > /target/etc/apt/apt.conf.d/00trustcdrom <<EOT
APT::Authentication::TrustCDROM "true";
EOT

	# Avoid clock skew causing gpg verification issues.
	# This file will be left in place until the end of the install.
	cat > /target/etc/apt/apt.conf.d/00IgnoreTimeConflict << EOT
Acquire::gpgv::Options { "--ignore-time-conflict"; };
EOT

	if db_get debian-installer/allow_unauthenticated && [ "$RET" = true ]; then
		# This file will be left in place until the end of the install.
		cat > /target/etc/apt/apt.conf.d/00AllowUnauthenticated << EOT
APT::Get::AllowUnauthenticated "true";
Aptitude::CmdLine::Ignore-Trust-Violations "true";
EOT
	fi
}

apt_update () {
	log-output -t base-installer chroot /target apt-get update \
		|| apt_update_failed=$?
	
	if [ "$apt_update_failed" ]; then
		warning "apt update failed: $apt_update_failed"
	fi
}

install_extra () {
	info "Installing queued packages into /target/."
	
	if [ -f /var/lib/apt-install/queue ] ; then
		# We need to install these one by one in case one fails.
		PKG_COUNT=`cat /var/lib/apt-install/queue | wc -w`
		CURR_PKG=0
		for PKG in `cat /var/lib/apt-install/queue`; do
			db_subst base-installer/section/install_extra_package SUBST0 "$PKG"
			db_progress INFO base-installer/section/install_extra_package

			if ! log-output -t base-installer apt-install $PKG; then
				warning "Failed to install $PKG into /target/: $?"
			fi

			# Advance progress bar within space allocated for install_extra
			CURR_PKG=$(($CURR_PKG + 1))
			update_progress $CURR_PKG $PKG_COUNT
		done
	fi
}

pre_install_hooks () {
	partsdir="/usr/lib/base-installer.d"
	if [ -d "$partsdir" ]; then
		for script in `ls "$partsdir"/*`; do
			base=$(basename $script | sed 's/[0-9]*//')
			if ! db_progress INFO base-installer/progress/$base; then
				db_subst base-installer/progress/fallback SCRIPT "$base"
				db_progress INFO base-installer/progress/fallback
		    	fi
	
		    	if [ -x "$script" ] ; then
				# be careful to preserve exit code
				if log-output -t base-installer "$script"; then
					:
				else
			    		warning "$script returned error code $?"
				fi
		    	else
				error "Unable to execute $script"
		    	fi
		done
	fi
}

post_install_hooks () {
	partsdir="/usr/lib/post-base-installer.d"
	if [ -d "$partsdir" ]; then
		scriptcount=`ls "$partsdir"/* | wc -l`
		scriptcur=0
		for script in "$partsdir"/*; do
			base="$(basename "$script" | sed 's/[0-9]*//')"
			if ! db_progress INFO base-installer/progress/$base && \
			   ! db_progress INFO finish-install/progress/$base; then
				db_subst base-installer/progress/fallback SCRIPT "$base"
				db_progress INFO base-installer/progress/fallback
			fi

			if [ -x "$script" ]; then
				# be careful to preserve exit code
				if log-output -t base-installer "$script"; then
					:
				else
					warning "$script returned error code $?"
				fi
			else
				error "Unable to execute $script"
			fi

			scriptcur="$(($scriptcur + 1))"
			update_progress "$scriptcur" "$scriptcount"
		done
	fi
}
