/*
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License (the "License").
 * You may not use this file except in compliance with the License.
 *
 * You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
 * or http://www.opensolaris.org/os/licensing.
 * See the License for the specific language governing permissions
 * and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file and include the License file at usr/src/OPENSOLARIS.LICENSE.
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 */
/*
 * Copyright 2006 Ricardo Correia.
 * Use is subject to license terms.
 */

#ifndef ZFSFUSE_LISTENER_H
#define ZFSFUSE_LISTENER_H

#include <sys/types.h>
#include <sys/kmem.h>
#include <sys/vnode.h>

#include "fuse.h"

typedef struct file_info {
	vnode_t *vp;
	int flags;
} file_info_t;

extern kmem_cache_t *file_info_cache;

extern boolean_t exit_fuse_listener;

extern int zfsfuse_listener_init();
extern int zfsfuse_listener_start();
extern int zfsfuse_listener_stop();
extern void zfsfuse_listener_exit();
extern int zfsfuse_newfs(char *mntpoint, struct fuse_chan *ch);

#endif
