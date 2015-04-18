This is debian installer components with ZoL support.

The following branches with the remote repositories have
had changes that is related to ZoL:

    base-installer    git://anonscm.debian.org/d-i/base-installer.git
    debian-installer  git://anonscm.debian.org/d-i/debian-installer.git
    grub-installer    git://anonscm.debian.org/d-i/grub-installer.git
    partman-zfs       git://anonscm.debian.org/d-i/partman-zfs.git
    zfs-fuse          git://git.debian.org/collab-maint/zfs-fuse.git

The repo is NOT intended for casual use, it is merely intended to be
used by people wanting to help perfecting the Debian GNU/Linux installer.

Once Debian GNU/Linux have accepted ZoL into it's repository, this
repository will be deleted.


Packages needs to be created from all of these repos, then checkout
the debian-installer branch, cd into it's build directory, put the
udeb packages in the 'localudebs' directory and then issue the command
"make_d-i.sh" found in the 'master' branch of this repo.

This because we need to do some 'hacking' - the ZoL components doesn't
(yet) exists in Debian GNU/Linux, so we need to get the ZoL installer
components AND all the non-modified components from the ZoL package
archive.

This is a flaw in the debian installer, which can't have multiple sources,
so all the non-modified components ALSO needs to be in the ZoL archive.
